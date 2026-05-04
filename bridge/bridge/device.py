"""Wraps pyzk's ZK client with reconnect-on-failure semantics.

The actual TCP socket lives inside `self._conn`. We expose a tiny
surface to the rest of the bridge: connect, disconnect,
get_attendance, and a `disable_during` context manager that follows
ZK's recommended "disable, read, enable" pattern to prevent races
with simultaneous live punches.
"""

from __future__ import annotations

import logging
import time
from contextlib import contextmanager
from typing import Callable, List

from zk import ZK
from zk.exception import ZKErrorResponse, ZKNetworkError

log = logging.getLogger(__name__)


class DeviceConnection:
    def __init__(
        self,
        ip: str,
        port: int,
        password: int,
        timeout: int,
        force_udp: bool,
    ) -> None:
        self._zk = ZK(
            ip,
            port=port,
            timeout=timeout,
            password=password,
            force_udp=force_udp,
            ommit_ping=True,
        )
        self._conn = None

    def connect(self) -> None:
        if self._conn is not None:
            return
        self._conn = self._zk.connect()
        log.info("device connected: serial=%s", self._safe_serial())

    def disconnect(self) -> None:
        if self._conn is None:
            return
        try:
            self._conn.disconnect()
        except Exception:
            pass
        self._conn = None

    def _safe_serial(self) -> str:
        try:
            return self._conn.get_serialnumber()
        except Exception:
            return "unknown"

    def get_attendance(self) -> List:
        if self._conn is None:
            raise RuntimeError("not connected")
        return self._conn.get_attendance()

    @contextmanager
    def disable_during(self):
        if self._conn is None:
            raise RuntimeError("not connected")
        self._conn.disable_device()
        try:
            yield
        finally:
            try:
                self._conn.enable_device()
            except Exception:
                pass


def connect_with_backoff(
    factory: Callable[[], DeviceConnection],
    *,
    initial_delay_s: float = 1.0,
    max_delay_s: float = 60.0,
    stop_check: Callable[[], bool] = lambda: False,
) -> DeviceConnection | None:
    """Keep trying to open a connection until success.

    Returns the connected DeviceConnection, or None if `stop_check()`
    becomes True before a connection succeeds.
    """
    delay = initial_delay_s
    while not stop_check():
        conn = factory()
        try:
            conn.connect()
            return conn
        except (ZKNetworkError, ZKErrorResponse, OSError) as e:
            log.warning(
                "device connect failed (%s); retrying in %.1fs",
                e,
                delay,
            )
            conn.disconnect()
            _interruptible_sleep(delay, stop_check)
            delay = min(delay * 2, max_delay_s)
    return None


def _interruptible_sleep(
    seconds: float,
    stop_check: Callable[[], bool],
) -> None:
    end = time.monotonic() + seconds
    while not stop_check() and time.monotonic() < end:
        time.sleep(min(0.5, end - time.monotonic()))
