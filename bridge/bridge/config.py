"""Environment-driven configuration for the bridge.

Loaded once at startup; missing required vars fail fast so a
misconfiguration surfaces immediately rather than at first device read.
"""

from __future__ import annotations

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
    device_ip: str
    device_port: int
    device_password: int
    device_timeout: int
    device_force_udp: bool
    device_id: str
    poll_interval_s: int
    heartbeat_interval_s: int
    state_db_path: Path

    @classmethod
    def load(cls) -> "BridgeConfig":
        # Load .env from the runtime dir explicitly; otherwise the
        # frozen exe wouldn't find it when launched from C:\Windows
        # (e.g. by Task Scheduler running as SYSTEM).
        env_path = _runtime_dir() / ".env"
        if env_path.is_file():
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
            device_ip=req("DEVICE_IP"),
            device_port=int(os.environ.get("DEVICE_PORT", "4370")),
            device_password=int(os.environ.get("DEVICE_PASSWORD", "0")),
            device_timeout=int(os.environ.get("DEVICE_TIMEOUT", "10")),
            device_force_udp=os.environ.get("DEVICE_FORCE_UDP", "false").lower()
            == "true",
            device_id=req("DEVICE_ID"),
            poll_interval_s=int(os.environ.get("POLL_INTERVAL_SECONDS", "30")),
            heartbeat_interval_s=int(
                os.environ.get("HEARTBEAT_INTERVAL_SECONDS", "30")
            ),
            state_db_path=_resolve(
                os.environ.get("STATE_DB_PATH", "./bridge_state.sqlite")
            ),
        )
