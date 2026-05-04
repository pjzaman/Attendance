"""Firestore client wrapper. All writes from the bridge go through
this module so doc paths and field shapes stay consistent.

Idempotency: punch doc IDs are derived from a hash of (deviceId,
userId, timestamp, rawPunch, rawStatus). Re-pulling the same record
produces the same doc ID, so a retry is a no-op overwrite instead of
a duplicate row.
"""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

import firebase_admin
from firebase_admin import credentials, firestore


def _doc_id(
    device_id: str,
    user_id: str,
    ts: datetime,
    raw_punch: int,
    raw_status: int,
) -> str:
    key = f"{device_id}|{user_id}|{ts.isoformat()}|{raw_punch}|{raw_status}"
    return hashlib.sha1(key.encode("utf-8")).hexdigest()[:20]


def _ensure_aware(ts: datetime) -> datetime:
    """ZKTeco timestamps come without tzinfo. Assume the device clock
    matches the bridge PC's local timezone (which is the standard
    setup for an on-prem device wired to that PC) and tag with the
    local tz so Firestore stores a real point-in-time.
    """
    if ts.tzinfo is None:
        return ts.astimezone()
    return ts


class FirestoreWriter:
    def __init__(self, credentials_path: Path, project_id: str) -> None:
        if not firebase_admin._apps:
            cred = credentials.Certificate(str(credentials_path))
            firebase_admin.initialize_app(cred, {"projectId": project_id})
        self._db = firestore.client()

    @property
    def db(self):
        return self._db

    def write_punches(
        self,
        *,
        device_id: str,
        bridge_id: str,
        records: Iterable,
    ) -> int:
        """Write a batch of pyzk Attendance records to Firestore.

        Returns the number of records written.
        """
        records = list(records)
        if not records:
            return 0
        batch = self._db.batch()
        now = datetime.now(timezone.utc)
        for r in records:
            ts = _ensure_aware(r.timestamp)
            doc_id = _doc_id(
                device_id, str(r.user_id), ts, r.punch, r.status
            )
            ref = self._db.collection("punches").document(doc_id)
            batch.set(
                ref,
                {
                    "userId": str(r.user_id),
                    "timestamp": ts,
                    "rawStatus": int(r.status),
                    "rawPunch": int(r.punch),
                    "deviceId": device_id,
                    "bridgeId": bridge_id,
                    "deviceUid": getattr(r, "uid", None),
                    "syncedAt": now,
                },
            )
        batch.commit()
        return len(records)
