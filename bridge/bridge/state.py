"""Local SQLite storage for the bridge's persistent state.

Holds:
  - high_water: the largest device-uid we've already pushed to
    Firestore from the device's attendance log. The poll loop pulls
    the device's full log, then filters to records > high_water.
  - processed_commands: command-doc IDs already executed, so a
    restart mid-execution doesn't double-fire the action.
"""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from pathlib import Path


class BridgeState:
    def __init__(self, db_path: Path) -> None:
        self._db_path = db_path
        db_path.parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as c:
            c.execute(
                "CREATE TABLE IF NOT EXISTS kv ("
                " key TEXT PRIMARY KEY,"
                " value TEXT NOT NULL)"
            )
            c.execute(
                "CREATE TABLE IF NOT EXISTS processed_commands ("
                " command_id TEXT PRIMARY KEY,"
                " processed_at TEXT NOT NULL)"
            )

    @contextmanager
    def _connect(self):
        con = sqlite3.connect(self._db_path)
        try:
            yield con
            con.commit()
        finally:
            con.close()

    def get_high_water(self) -> int:
        with self._connect() as c:
            row = c.execute(
                "SELECT value FROM kv WHERE key='high_water'"
            ).fetchone()
            return int(row[0]) if row else 0

    def set_high_water(self, value: int) -> None:
        with self._connect() as c:
            c.execute(
                "INSERT OR REPLACE INTO kv (key, value) VALUES ('high_water', ?)",
                (str(value),),
            )

    def has_processed(self, command_id: str) -> bool:
        with self._connect() as c:
            row = c.execute(
                "SELECT 1 FROM processed_commands WHERE command_id = ?",
                (command_id,),
            ).fetchone()
            return row is not None

    def mark_processed(self, command_id: str, when: str) -> None:
        with self._connect() as c:
            c.execute(
                "INSERT OR IGNORE INTO processed_commands "
                "(command_id, processed_at) VALUES (?, ?)",
                (command_id, when),
            )
