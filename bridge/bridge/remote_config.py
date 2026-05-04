"""Reads the bridge's connection config from Firestore.

The bridge no longer hard-codes device IP / port / comm-key in .env.
Instead it pulls those from a `devices/{deviceId}` doc that HR can
edit from the Flutter app — so a non-technical operator can change
the device's network address without touching the device PC.

Discovery flow on first run:
  1. The bridge looks at `bridges/{bridgeId}` for `targetDeviceId`.
  2. If it's missing, the bridge auto-creates a placeholder
     `devices/{bridgeId}` doc with IP `0.0.0.0` and links to it.
  3. The bridge enters "awaiting_config" mode (heartbeat only) until
     HR edits the IP via the app.
  4. On every reconnect cycle the bridge re-reads the device doc, so
     a config change propagates within ~1 minute.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class DeviceTarget:
    device_id: str
    ip: str
    port: int
    password: int
    connect_timeout_ms: int
    recv_timeout_ms: int

    @property
    def is_configured(self) -> bool:
        """True once HR has set a real IP. The placeholder we drop on
        first run is `0.0.0.0`, which we treat as unconfigured."""
        return self.ip not in ("", "0.0.0.0")

    @property
    def timeout_s(self) -> int:
        # pyzk uses a single seconds-granularity timeout for both;
        # honour the longer of the two.
        return max(
            (self.connect_timeout_ms + 999) // 1000,
            (self.recv_timeout_ms + 999) // 1000,
            5,
        )


class RemoteConfigStore:
    """Wraps the two Firestore docs the bridge depends on.

    Service-account writes bypass security rules, so this works even
    when the rules-deployed clients can't write to these docs.
    """

    def __init__(self, db, bridge_id: str) -> None:
        self._db = db
        self._bridge_id = bridge_id

    # ── Bridge doc ────────────────────────────────────────────

    def _bridge_ref(self):
        return self._db.collection("bridges").document(self._bridge_id)

    def _ensure_bridge_doc(self) -> dict:
        ref = self._bridge_ref()
        snap = ref.get()
        if snap.exists:
            return snap.to_dict() or {}
        log.info("creating bridges/%s (first run)", self._bridge_id)
        seed = {
            "bridgeId": self._bridge_id,
            "createdAt": datetime.now(timezone.utc),
            "status": "awaiting_config",
            "deviceConnected": False,
            "targetDeviceId": self._bridge_id,
        }
        ref.set(seed)
        return seed

    # ── Device doc ────────────────────────────────────────────

    def _device_ref(self, device_id: str):
        return self._db.collection("devices").document(device_id)

    def _ensure_device_doc(self, device_id: str) -> dict:
        ref = self._device_ref(device_id)
        snap = ref.get()
        if snap.exists:
            return snap.to_dict() or {}
        log.info("creating devices/%s (placeholder)", device_id)
        seed = {
            "id": device_id,
            "name": device_id,
            "brand": "ZKTeco",
            "model": "UFace800",
            "ip_address": "0.0.0.0",
            "port": 4370,
            "comm_key": 0,
            "connect_timeout_ms": 5000,
            "recv_timeout_ms": 10000,
            "is_active": 1,
            "office_location": None,
            "serial_number": None,
            "notes":
                "Auto-created by the bridge on first run. Set the IP "
                "address from the Flutter app under Settings → Devices.",
        }
        ref.set(seed)
        return seed

    # ── Public API ───────────────────────────────────────────

    def fetch(self) -> Optional[DeviceTarget]:
        """Returns the resolved target, or None if the device record
        exists but has a placeholder IP (caller should idle).
        """
        bridge = self._ensure_bridge_doc()
        device_id = (bridge.get("targetDeviceId") or "").strip()
        if not device_id:
            device_id = self._bridge_id
            self._bridge_ref().update({"targetDeviceId": device_id})

        device = self._ensure_device_doc(device_id)

        target = DeviceTarget(
            device_id=device_id,
            ip=str(device.get("ip_address") or "0.0.0.0").strip(),
            port=int(device.get("port") or 4370),
            password=int(device.get("comm_key") or 0),
            connect_timeout_ms=int(device.get("connect_timeout_ms") or 5000),
            recv_timeout_ms=int(device.get("recv_timeout_ms") or 10000),
        )
        if not target.is_configured:
            log.info(
                "devices/%s has no real IP yet — waiting for HR to "
                "configure it via the Flutter app",
                device_id,
            )
            return None
        return target

    def stamp_last_sync(self, device_id: str) -> None:
        """Bumps the device record's last_sync_at after a successful
        sync iteration. Fires-and-forgets — failures are non-fatal.
        """
        try:
            self._device_ref(device_id).update({
                "last_sync_at":
                    datetime.now(timezone.utc).isoformat(),
                "last_connected_at":
                    datetime.now(timezone.utc).isoformat(),
            })
        except Exception as e:
            log.warning("could not stamp device last_sync_at: %s", e)
