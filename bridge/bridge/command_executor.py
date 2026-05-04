"""Runs queued bridge_commands against the device.

Idempotent: command IDs are recorded in the local state DB after
execution, so a snapshot replay (e.g. on reconnect) won't re-run a
finished command. Each command writes its terminal status (`done` /
`failed`) back to the Firestore doc with a result or error message.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict

from .device import DeviceConnection
from .firestore_writer import FirestoreWriter
from .state import BridgeState

log = logging.getLogger(__name__)


class CommandExecutor:
    def __init__(
        self,
        device: DeviceConnection,
        writer: FirestoreWriter,
        state: BridgeState,
        bridge_id: str,
        device_id: str,
    ) -> None:
        self._device = device
        self._writer = writer
        self._state = state
        self._bridge_id = bridge_id
        self._device_id = device_id

    def execute(self, ref, data: Dict[str, Any]) -> None:
        cmd_id = ref.id
        if self._state.has_processed(cmd_id):
            log.info("skipping already-processed command %s", cmd_id)
            return

        action = (data.get("action") or "").strip()
        params = data.get("params") or {}
        log.info("executing command %s: action=%s", cmd_id, action)

        # Mark running so duplicate listeners don't fire on the same
        # doc. (We still rely on the local processed_commands table
        # for absolute idempotency across restarts.)
        try:
            ref.update({
                "status": "running",
                "startedAt": datetime.now(timezone.utc),
            })
        except Exception as e:
            log.warning("could not mark command running: %s", e)

        try:
            result = self._dispatch(action, params)
            ref.update({
                "status": "done",
                "finishedAt": datetime.now(timezone.utc),
                "result": result,
                "error": None,
            })
            log.info("command %s done", cmd_id)
        except Exception as e:
            log.exception("command %s failed: %s", cmd_id, e)
            ref.update({
                "status": "failed",
                "finishedAt": datetime.now(timezone.utc),
                "error": f"{type(e).__name__}: {e}",
            })
        finally:
            self._state.mark_processed(
                cmd_id,
                datetime.now(timezone.utc).isoformat(),
            )

    # ─── Dispatcher ──────────────────────────────────────────────

    def _dispatch(self, action: str, params: Dict[str, Any]) -> Any:
        if action == "manual_sync":
            return self._manual_sync()
        if action == "clear_log":
            return self._clear_log()
        if action == "sync_time":
            return self._sync_time()
        if action == "enroll_user":
            return self._enroll_user(params)
        if action == "delete_user":
            return self._delete_user(params)
        raise ValueError(f"Unknown action: {action!r}")

    # ─── Action handlers ─────────────────────────────────────────

    def _manual_sync(self) -> Dict[str, Any]:
        high_water = self._state.get_high_water()
        with self._device.disable_during():
            records = self._device.get_attendance()
        new = [
            r for r in records
            if int(getattr(r, "uid", 0) or 0) > high_water
        ]
        if new:
            self._writer.write_punches(
                device_id=self._device_id,
                bridge_id=self._bridge_id,
                records=new,
            )
            new_hw = max(int(r.uid or 0) for r in new)
            self._state.set_high_water(max(high_water, new_hw))
        return {"synced": len(new), "high_water": self._state.get_high_water()}

    def _clear_log(self) -> Dict[str, Any]:
        # pyzk's underlying client lives on `_device._conn`. We expose
        # only what the bridge needs; reach into the raw client here.
        if self._device._conn is None:
            raise RuntimeError("device not connected")
        self._device._conn.clear_attendance()
        return {"cleared": True}

    def _sync_time(self) -> Dict[str, Any]:
        if self._device._conn is None:
            raise RuntimeError("device not connected")
        now = datetime.now()
        self._device._conn.set_time(now)
        return {"setTo": now.isoformat()}

    def _enroll_user(self, params: Dict[str, Any]) -> Dict[str, Any]:
        if self._device._conn is None:
            raise RuntimeError("device not connected")
        user_id = str(params.get("userId") or "").strip()
        name = str(params.get("name") or "").strip()
        if not user_id or not name:
            raise ValueError("enroll_user requires userId and name")
        privilege = int(params.get("privilege") or 0)
        password = str(params.get("password") or "")
        card_no = int(params.get("cardNo") or 0)
        uid = int(params.get("uid") or 0)
        self._device._conn.set_user(
            uid=uid,
            name=name,
            privilege=privilege,
            password=password,
            user_id=user_id,
            card=card_no,
        )
        return {"enrolled": user_id}

    def _delete_user(self, params: Dict[str, Any]) -> Dict[str, Any]:
        if self._device._conn is None:
            raise RuntimeError("device not connected")
        user_id = params.get("userId")
        uid = params.get("uid")
        if user_id is None and uid is None:
            raise ValueError("delete_user requires userId or uid")
        # pyzk supports delete_user(uid=...) or delete_user(user_id=...).
        if uid is not None:
            self._device._conn.delete_user(uid=int(uid))
        else:
            self._device._conn.delete_user(user_id=str(user_id))
        return {"deleted": user_id or uid}
