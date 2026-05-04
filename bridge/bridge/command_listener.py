"""Subscribes to bridge_commands for this bridge and queues incoming
commands for the main loop to drain.

Why a queue (and not direct execution): the device socket is single-
threaded — the main loop owns it for sync, so commands need to wait
their turn. The Firestore snapshot listener runs in its own thread
inside firebase-admin's gRPC stub; we just enqueue and let the main
loop pop between sync iterations.
"""

from __future__ import annotations

import logging
import queue
import threading
from typing import Tuple

log = logging.getLogger(__name__)


class BridgeCommandListener:
    """Thin wrapper around firestore.collection.on_snapshot()."""

    def __init__(
        self,
        db,
        bridge_id: str,
        cmd_queue: "queue.Queue[Tuple[object, dict]]",
    ) -> None:
        self._db = db
        self._bridge_id = bridge_id
        self._queue = cmd_queue
        self._watch = None
        self._lock = threading.Lock()

    def start(self) -> None:
        """Subscribes to pending commands targeted at this bridge."""
        col = (
            self._db.collection("bridge_commands")
            .where("bridgeId", "==", self._bridge_id)
            .where("status", "==", "pending")
        )

        def on_snapshot(docs, changes, _read_time):
            for change in changes:
                if change.type.name in ("ADDED", "MODIFIED"):
                    doc = change.document
                    self._queue.put((doc.reference, doc.to_dict()))

        with self._lock:
            self._watch = col.on_snapshot(on_snapshot)
        log.info(
            "command listener started (bridge=%s)", self._bridge_id
        )

    def stop(self) -> None:
        with self._lock:
            if self._watch is not None:
                try:
                    self._watch.unsubscribe()
                except Exception as e:
                    log.warning("watch unsubscribe failed: %s", e)
                self._watch = None
