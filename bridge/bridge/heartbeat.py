"""Heartbeat publisher.

Writes a single doc to bridges/{bridge_id} so the Flutter app's
Devices page can show whether the bridge is alive and how recently
it talked to the device.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from .firestore_writer import FirestoreWriter


class HeartbeatPublisher:
    def __init__(
        self,
        writer: FirestoreWriter,
        bridge_id: str,
        device_id: str,
    ) -> None:
        self._writer = writer
        self._bridge_id = bridge_id
        self._device_id = device_id

    def write(
        self,
        *,
        status: str,
        device_connected: bool,
        last_sync_at: Optional[datetime],
        last_error: Optional[str] = None,
    ) -> None:
        self.write_with_device(
            bridge_id=self._bridge_id,
            device_id=self._device_id,
            status=status,
            device_connected=device_connected,
            last_sync_at=last_sync_at,
            last_error=last_error,
        )

    def write_with_device(
        self,
        *,
        bridge_id: str,
        device_id: str,
        status: str,
        device_connected: bool,
        last_sync_at: Optional[datetime],
        last_error: Optional[str] = None,
    ) -> None:
        ref = self._writer.db.collection("bridges").document(bridge_id)
        ref.set(
            {
                "bridgeId": bridge_id,
                "deviceId": device_id,
                "status": status,
                "deviceConnected": device_connected,
                "lastSyncAt": last_sync_at,
                "lastError": last_error,
                "updatedAt": datetime.now(timezone.utc),
            },
            merge=True,
        )
