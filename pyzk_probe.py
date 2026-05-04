"""Standalone pyzk connectivity probe.

Run this on the PC connected to the office LAN to verify the UFace800
speaks the standard ZK protocol with comm key 0. If this works, my Dart
implementation has a bug. If it also fails, the device's auth/encryption
settings have changed.

Usage:
    pip install pyzk
    python pyzk_probe.py

Tries comm key 0 first; if that fails with 'unauthenticated', loops
through a few common alternates so we get a quick yes/no on whether the
device requires auth.
"""

from __future__ import annotations

import sys
import traceback

from zk import ZK  # pip install pyzk

DEVICE_IP = "192.168.0.150"
DEVICE_PORT = 4370
KEYS_TO_TRY = [0, 12345, 1, 1234]


def probe(comm_key: int) -> bool:
    print(f"\n--- Trying comm key={comm_key} ---")
    z = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=5, password=comm_key,
           force_udp=False, ommit_ping=False)
    try:
        conn = z.connect()
    except Exception as e:
        print(f"  connect() raised: {type(e).__name__}: {e}")
        traceback.print_exc()
        return False

    if conn is None:
        print("  connect() returned None — device rejected handshake")
        return False

    try:
        firmware = conn.get_firmware_version()
        device_name = conn.get_device_name()
        serial = conn.get_serialnumber()
        users = conn.get_users()
        att = conn.get_attendance()
        print(f"  ✓ connected")
        print(f"    firmware:   {firmware}")
        print(f"    device:     {device_name}")
        print(f"    serial:     {serial}")
        print(f"    users:      {len(users)}")
        print(f"    attendance: {len(att)}")
        return True
    except Exception as e:
        print(f"  post-connect call failed: {type(e).__name__}: {e}")
        traceback.print_exc()
        return False
    finally:
        try:
            conn.disconnect()
        except Exception:
            pass


def main() -> int:
    print(f"Probing {DEVICE_IP}:{DEVICE_PORT} ...")
    for key in KEYS_TO_TRY:
        if probe(key):
            print(f"\n✓✓✓  SUCCESS with comm key {key}")
            return 0
    print("\n✗  All comm keys failed. Either the device speaks a non-standard")
    print("   protocol now (push/encrypted SDK), or there is a firewall/VPN")
    print("   layer still blocking TCP.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
