"""Bridge orchestrator.

Outer loop:
  1. Fetch device target from Firestore (devices/{targetDeviceId})
  2. If no IP set yet, write an "awaiting_config" heartbeat and wait
  3. Connect to the device with backoff
  4. Run the sync inner loop until the device drops or we shut down

Inner loop (while connected):
  - Pull new punches from device → Firestore (idempotent)
  - Drain any queued bridge_commands and execute them
  - Stamp the device record's last_sync_at
  - Heartbeat
  - Sleep poll_interval_s

Config changes (HR edits the device IP via the Flutter app) propagate
on the next reconnect cycle, since `RemoteConfigStore.fetch()` runs
at the top of every outer iteration.
"""

from __future__ import annotations

import logging
import queue
import signal
import sys
import time
from datetime import datetime, timezone
from typing import Optional

from .command_executor import CommandExecutor
from .command_listener import BridgeCommandListener
from .config import BridgeConfig
from .device import DeviceConnection, connect_with_backoff
from .firestore_writer import FirestoreWriter
from .heartbeat import HeartbeatPublisher
from .remote_config import DeviceTarget, RemoteConfigStore
from .state import BridgeState

log = logging.getLogger(__name__)


class _StopFlag:
    def __init__(self) -> None:
        self.stop = False

    def install(self) -> None:
        signal.signal(signal.SIGINT, self._handle)
        signal.signal(signal.SIGTERM, self._handle)

    def _handle(self, *_) -> None:
        log.info("shutdown signal received; finishing in-flight work")
        self.stop = True


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)-7s %(name)s: %(message)s",
    )
    log.info("apon-attendance-bridge starting")

    cfg = BridgeConfig.load()
    state = BridgeState(cfg.state_db_path)
    writer = FirestoreWriter(
        cfg.firebase_credentials_path,
        cfg.firebase_project_id,
    )
    remote = RemoteConfigStore(writer.db, cfg.bridge_id)
    heartbeat = HeartbeatPublisher(writer, cfg.bridge_id, cfg.bridge_id)
    stop = _StopFlag()
    stop.install()

    # Commands queued by Firestore snapshot listener; drained by the
    # main loop between sync iterations so we never touch the device
    # socket from two threads at once.
    cmd_queue: "queue.Queue" = queue.Queue()
    cmd_listener = BridgeCommandListener(writer.db, cfg.bridge_id, cmd_queue)
    cmd_listener.start()

    last_sync_at: Optional[datetime] = None
    last_error: Optional[str] = None

    # Cost-control: throttle heartbeats and config fetches.
    # - Heartbeats: only on state change OR after `heartbeat_interval_s`
    #   of steady-state. The Flutter UI flips to "Stale" after 2 min;
    #   defaulting to 5 min keeps the panel honest while writing 1/10
    #   the docs of the per-iteration approach.
    # - Config fetch: cached for 60s. Operator IP changes still
    #   propagate within 1 min instead of 30 s.
    last_hb_at: float = 0.0
    last_hb_status: Optional[str] = None
    last_hb_connected: Optional[bool] = None
    last_cfg_fetch_at: float = 0.0
    cached_cfg: Optional[DeviceTarget] = None
    CFG_CACHE_S = 60.0

    def hb(*, status, device_id, device_connected, last_error):
        nonlocal last_hb_at, last_hb_status, last_hb_connected
        now = time.monotonic()
        changed = (status != last_hb_status
                   or device_connected != last_hb_connected)
        if changed or (now - last_hb_at) >= cfg.heartbeat_interval_s:
            _safe_heartbeat(
                heartbeat,
                bridge_id=cfg.bridge_id,
                device_id=device_id,
                status=status,
                device_connected=device_connected,
                last_sync_at=last_sync_at,
                last_error=last_error,
            )
            last_hb_at = now
            last_hb_status = status
            last_hb_connected = device_connected

    def get_target(force: bool = False) -> Optional[DeviceTarget]:
        nonlocal last_cfg_fetch_at, cached_cfg
        now = time.monotonic()
        if force or cached_cfg is None or (now - last_cfg_fetch_at) >= CFG_CACHE_S:
            cached_cfg = remote.fetch()
            last_cfg_fetch_at = now
        return cached_cfg

    while not stop.stop:
        target = get_target(force=True)
        if target is None:
            # Device record exists but the IP is still the placeholder.
            # Idle, heartbeat (throttled), retry — HR will set the IP
            # from the app.
            hb(
                status="awaiting_config",
                device_id=cfg.bridge_id,
                device_connected=False,
                last_error="Set the device IP from the Flutter app "
                "under Settings → Integrations → Devices.",
            )
            _interruptible_sleep(15, stop)
            continue

        device = connect_with_backoff(
            lambda t=target: DeviceConnection(
                ip=t.ip,
                port=t.port,
                password=t.password,
                timeout=t.timeout_s,
                force_udp=False,
            ),
            stop_check=lambda: stop.stop,
        )
        if device is None:
            break  # shutdown requested while still trying to connect

        executor = CommandExecutor(
            device, writer, state, cfg.bridge_id, target.device_id,
        )

        # Auto-sync users on every fresh connect. Firestore writes are
        # batched (one round-trip regardless of headcount), so even
        # large user lists land cheap. No-op for installs whose users
        # haven't changed — set() with the same data is idempotent.
        try:
            result = executor.sync_users()
            log.info("synced %d user(s) on connect", result.get("synced", 0))
        except Exception as e:
            log.warning("user sync on connect failed (non-fatal): %s", e)

        # State-transition heartbeat: connect → online.
        hb(
            status="online",
            device_id=target.device_id,
            device_connected=True,
            last_error=None,
        )

        # Track which target we're currently connected to. If the
        # device record changes while we're running, we drop and
        # reconnect on the next iteration.
        connected_target = target

        while not stop.stop:
            try:
                # Pick up config changes (cached for 60s — operator
                # changes still propagate within ~1 min).
                latest = get_target()
                if latest is None or latest != connected_target:
                    log.info(
                        "device config changed (or was cleared); "
                        "reconnecting"
                    )
                    device.disconnect()
                    break

                high_water = state.get_high_water()
                new_records, new_high_water = _read_new_punches(
                    device, high_water
                )
                if new_records:
                    n = writer.write_punches(
                        device_id=target.device_id,
                        bridge_id=cfg.bridge_id,
                        records=new_records,
                    )
                    state.set_high_water(new_high_water)
                    log.info(
                        "synced %d new punch(es); high_water=%d",
                        n,
                        new_high_water,
                    )

                # Drain any queued commands.
                while True:
                    try:
                        ref, data = cmd_queue.get_nowait()
                    except queue.Empty:
                        break
                    try:
                        executor.execute(ref, data)
                    except Exception as e:
                        log.exception("command execute crashed: %s", e)

                last_sync_at = datetime.now(timezone.utc)
                last_error = None
                # Heartbeat is throttled — most iterations are no-ops.
                # The bridge's lastSyncAt is on the heartbeat doc, so
                # we don't separately stamp the device record (saves
                # 1 write per cycle).
                hb(
                    status="online",
                    device_id=target.device_id,
                    device_connected=True,
                    last_error=None,
                )
            except Exception as e:
                last_error = f"{type(e).__name__}: {e}"
                log.exception("sync iteration failed: %s", e)
                # State change (online → degraded) writes immediately.
                hb(
                    status="degraded",
                    device_id=target.device_id,
                    device_connected=False,
                    last_error=last_error,
                )
                device.disconnect()
                _interruptible_sleep(2, stop)
                break  # back to outer loop → reconnect

            _interruptible_sleep(cfg.poll_interval_s, stop)

        device.disconnect()

    cmd_listener.stop()

    # Final state-transition heartbeat — write directly, bypassing
    # throttle, because we're about to exit.
    _safe_heartbeat(
        heartbeat,
        bridge_id=cfg.bridge_id,
        device_id=cfg.bridge_id,
        status="offline",
        device_connected=False,
        last_sync_at=last_sync_at,
        last_error=None,
    )
    log.info("apon-attendance-bridge stopped")
    return 0


def _read_new_punches(device: DeviceConnection, high_water: int):
    with device.disable_during():
        records = device.get_attendance()
    if not records:
        return [], high_water
    new = [r for r in records if int(getattr(r, "uid", 0) or 0) > high_water]
    if not new:
        return [], high_water
    new_high_water = max(int(r.uid or 0) for r in new)
    return new, max(high_water, new_high_water)


def _safe_heartbeat(
    heartbeat: HeartbeatPublisher,
    *,
    bridge_id: str,
    device_id: str,
    status: str,
    device_connected: bool,
    last_sync_at: Optional[datetime],
    last_error: Optional[str],
) -> None:
    try:
        heartbeat.write_with_device(
            bridge_id=bridge_id,
            device_id=device_id,
            status=status,
            device_connected=device_connected,
            last_sync_at=last_sync_at,
            last_error=last_error,
        )
    except Exception as e:
        log.warning("heartbeat write failed: %s", e)


def _interruptible_sleep(seconds: float, stop: _StopFlag) -> None:
    end = time.monotonic() + seconds
    while not stop.stop and time.monotonic() < end:
        time.sleep(min(0.5, end - time.monotonic()))


if __name__ == "__main__":
    sys.exit(main())
