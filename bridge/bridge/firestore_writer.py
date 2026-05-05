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

    def write_employees(self, *, users: Iterable) -> int:
        """Batch-write pyzk User objects to employees/{user_id}.

        Doc shape matches lib/models/employee.dart's `fromFirestore`:
        camelCase fields, doc_id == device user_id.
        """
        users = list(users)
        if not users:
            return 0
        batch = self._db.batch()
        now = datetime.now(timezone.utc).isoformat()
        written = 0
        for u in users:
            user_id = str(getattr(u, "user_id", "") or "").strip()
            if not user_id:
                # Devices sometimes have rows with empty user_id —
                # internal slots, blank enrollments. Skip them.
                continue
            ref = self._db.collection("employees").document(user_id)
            card_raw = getattr(u, "card", 0) or 0
            card_str = str(card_raw) if card_raw not in (0, "0") else ""
            batch.set(ref, {
                "uid": int(getattr(u, "uid", 0) or 0),
                "name": str(getattr(u, "name", "") or ""),
                "privilege": int(getattr(u, "privilege", 0) or 0),
                "cardNo": card_str,
                "groupId": str(getattr(u, "group_id", "") or ""),
                "updatedAt": now,
            })
            written += 1
        batch.commit()
        return written

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
