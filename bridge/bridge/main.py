"""Bridge orchestrator.

Outer loop: stay connected to the device, recover from drops.
Inner loop (while connected):
    1. Pull new punches from device → Firestore
    2. Write heartbeat
    3. Sleep poll_interval

On any error inside the inner loop, log + write a degraded heartbeat,
disconnect, and let the outer loop reconnect with backoff.
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
    heartbeat = HeartbeatPublisher(writer, cfg.bridge_id, cfg.device_id)
    stop = _StopFlag()
    stop.install()

    # Commands queued by Firestore snapshot listener; drained by the
    # main loop between sync iterations so we never touch the device
    # socket from two threads at once.
    cmd_queue: "queue.Queue" = queue.Queue()
    cmd_listener = BridgeCommandListener(writer.db, cfg.bridge_id, cmd_queue)
    cmd_listener.start()

    def device_factory() -> DeviceConnection:
        return DeviceConnection(
            ip=cfg.device_ip,
            port=cfg.device_port,
            password=cfg.device_password,
            timeout=cfg.device_timeout,
            force_udp=cfg.device_force_udp,
        )

    last_sync_at: Optional[datetime] = None
    last_error: Optional[str] = None

    while not stop.stop:
        device = connect_with_backoff(
            device_factory,
            stop_check=lambda: stop.stop,
        )
        if device is None:
            break  # shutdown requested while still trying to connect

        executor = CommandExecutor(
            device, writer, state, cfg.bridge_id, cfg.device_id,
        )

        _safe_heartbeat(
            heartbeat,
            status="online",
            device_connected=True,
            last_sync_at=last_sync_at,
            last_error=None,
        )

        while not stop.stop:
            try:
                high_water = state.get_high_water()
                new_records, new_high_water = _read_new_punches(
                    device, high_water
                )
                if new_records:
                    n = writer.write_punches(
                        device_id=cfg.device_id,
                        bridge_id=cfg.bridge_id,
                        records=new_records,
                    )
                    state.set_high_water(new_high_water)
                    log.info(
                        "synced %d new punch(es); high_water=%d",
                        n,
                        new_high_water,
                    )

                # Drain any queued commands the listener stashed
                # while we were polling. Each command runs against
                # the same device connection, so they're naturally
                # serialized.
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
                _safe_heartbeat(
                    heartbeat,
                    status="online",
                    device_connected=True,
                    last_sync_at=last_sync_at,
                    last_error=None,
                )
            except Exception as e:
                last_error = f"{type(e).__name__}: {e}"
                log.exception("sync iteration failed: %s", e)
                _safe_heartbeat(
                    heartbeat,
                    status="degraded",
                    device_connected=False,
                    last_sync_at=last_sync_at,
                    last_error=last_error,
                )
                device.disconnect()
                _interruptible_sleep(2, stop)
                break  # back to outer loop → reconnect

            _interruptible_sleep(cfg.poll_interval_s, stop)

        device.disconnect()

    cmd_listener.stop()

    _safe_heartbeat(
        heartbeat,
        status="offline",
        device_connected=False,
        last_sync_at=last_sync_at,
        last_error=None,
    )
    log.info("apon-attendance-bridge stopped")
    return 0


def _read_new_punches(device: DeviceConnection, high_water: int):
    """Pull all attendance records, return only those whose device-uid
    is greater than the high-water mark, plus the new high-water.

    Why uid not timestamp: ZK records have a monotonically-increasing
    `uid` per record. Using uid is unambiguous even when two punches
    fall on the same second.
    """
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
    status: str,
    device_connected: bool,
    last_sync_at: Optional[datetime],
    last_error: Optional[str],
) -> None:
    """A failed heartbeat should never crash the sync loop — log it
    and move on. The next iteration will retry.
    """
    try:
        heartbeat.write(
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
