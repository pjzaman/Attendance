# Apon Attendance

Standalone Windows desktop app for pulling attendance data off the Apon
office ZKTeco UFace800 biometric reader, deriving check-in/out from raw
timestamps, and storing everything locally.

Built in Flutter so the codebase is consistent with the main Apon ERP.
Intentionally decoupled from the ERP — runs without Firebase, without
Python, without any backend. Future ERP integration is a single
service-layer swap.

## Status

| Piece | Status |
|---|---|
| ZKTeco TCP protocol (Dart, port of pyzk) | scaffolded — verify on hardware |
| SQLite schema (mirrors Python service) | done |
| Punch derivation (port of `derive.py`) | done |
| UI: Connect / Sync / Employees / Punches / Daily / Export | done |
| Firestore push to Apon ERP | stubbed — wire up later |

## Architecture

```
lib/
├── main.dart                  Entry point, sets up sqflite_ffi + Provider
├── app.dart                   MaterialApp shell, routes
├── config.dart                Device IP/port/comm-key (reads .env)
├── shared/
│   └── app_theme.dart         Theme + AppColors / AppSpacing
├── services/
│   ├── zkteco/
│   │   ├── zk_protocol.dart   Raw packet builder/parser (port of pyzk)
│   │   ├── zk_client.dart     High-level: connect / users / punches
│   │   └── zk_models.dart     ZkUser, ZkPunch (data classes)
│   ├── db/
│   │   ├── database.dart      sqflite_common_ffi setup, migrations
│   │   └── attendance_dao.dart  CRUD for users/punches/daily
│   ├── derive_service.dart    Punch list → DailySummary (no device status field)
│   ├── sync_service.dart      Orchestrates: connect → pull → SQLite → derive
│   ├── export_service.dart    CSV + XLSX export
│   └── sync/
│       └── firestore_sync.dart   STUB — future ERP integration point
├── models/
│   ├── employee.dart
│   ├── punch.dart
│   └── daily_summary.dart
├── providers/
│   └── app_state.dart         Provider: connection state, last sync, errors
├── screens/
│   ├── home_screen.dart
│   ├── employees_screen.dart
│   ├── punches_screen.dart
│   ├── daily_screen.dart
│   └── export_screen.dart
└── widgets/
    └── status_card.dart
```

## Why pure Dart for the ZK protocol

Two alternatives were considered and rejected:

1. **Shell out to the existing Python `attendance-service`** — works
   immediately but ties the GUI to a Python install, makes packaging
   for the Microsoft Store messier, and gives the user a worse error
   experience when Python's missing.
2. **Wrap a vendor DLL via FFI** — ZKTeco does ship `zkemkeeper.dll`, but
   it requires registration via `regsvr32`, only works on Windows, and
   adds a non-Flutter native build step.

A native Dart implementation is ~400 lines, has no runtime dependencies
beyond `dart:io` sockets, and gives us first-class error handling. The
protocol itself is well-documented (the `pyzk` source is the
authoritative reference; we ported the bits we need).

## Where to look first

- `lib/services/zkteco/zk_client.dart` — the public API. Everything else
  hangs off this.
- `lib/services/derive_service.dart` — the rules that turn raw punches
  into a daily check-in/out, ignoring the device's broken status field.
- `lib/providers/app_state.dart` — single source of truth for connection
  status, sync progress, and errors.

See `SETUP.md` for the run instructions.
