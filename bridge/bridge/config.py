"""Environment-driven configuration for the bridge.

Loaded once at startup; missing required vars fail fast so a
misconfiguration surfaces immediately rather than at first device read.

The bridge no longer reads device IP / port / comm-key from the
environment — those live in Firestore (`devices/{targetDeviceId}`)
so HR can edit them from the Flutter app without touching the
device PC. See `remote_config.py`.
"""

from __future__ import annotations

import io
import os
import sys
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


def _runtime_dir() -> Path:
    """Directory the bridge should treat as its working root.

    For a PyInstaller-bundled exe, that's the folder containing the
    exe itself — so .env, firebase-sa.json, and bridge_state.sqlite
    sit alongside the binary regardless of which CWD the service was
    launched from. For a normal `python -m bridge.main` run, that's
    the current working directory.
    """
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path.cwd()


def _resolve(path_str: str) -> Path:
    """Expand ~ and resolve relative paths against the runtime dir."""
    p = Path(path_str).expanduser()
    if not p.is_absolute():
        p = _runtime_dir() / p
    return p


@dataclass(frozen=True)
class BridgeConfig:
    firebase_credentials_path: Path
    firebase_project_id: str
    bridge_id: str
    poll_interval_s: int
    heartbeat_interval_s: int
    state_db_path: Path

    @classmethod
    def load(cls) -> "BridgeConfig":
        env_path = _runtime_dir() / ".env"
        if env_path.is_file():
            # Read with utf-8-sig so a leading BOM (which Windows
            # PowerShell 5.1 writes by default with `Out-File -Encoding
            # utf8`) gets stripped — otherwise python-dotenv treats it
            # as part of the first variable name and the entire .env
            # appears blank to os.environ.get().
            try:
                text = env_path.read_text(encoding="utf-8-sig")
                load_dotenv(stream=io.StringIO(text))
            except UnicodeDecodeError:
                # Fallback: maybe it's some other encoding. Let
                # python-dotenv try its own decoding heuristics.
                load_dotenv(env_path)

        def req(name: str) -> str:
            v = os.environ.get(name)
            if not v:
                raise SystemExit(
                    f"Missing required env var: {name}.\n"
                    f"Expected .env at: {env_path}\n"
                    "Copy .env.example to .env and fill it in."
                )
            return v

        creds = _resolve(req("GOOGLE_APPLICATION_CREDENTIALS"))
        if not creds.is_file():
            raise SystemExit(
                "GOOGLE_APPLICATION_CREDENTIALS points to a missing file:\n"
                f"  {creds}"
            )

        return cls(
            firebase_credentials_path=creds,
            firebase_project_id=req("FIREBASE_PROJECT_ID"),
            bridge_id=req("BRIDGE_ID"),
            poll_interval_s=int(os.environ.get("POLL_INTERVAL_SECONDS", "30")),
            heartbeat_interval_s=int(
                os.environ.get("HEARTBEAT_INTERVAL_SECONDS", "30")
            ),
            state_db_path=_resolve(
                os.environ.get("STATE_DB_PATH", "./bridge_state.sqlite")
            ),
        )
