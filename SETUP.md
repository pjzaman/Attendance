# Apon Attendance — Setup

Standalone Windows desktop Flutter app that talks directly to the office
ZKTeco UFace800 (`192.168.0.150:4370`), pulls users + punches, derives
check-in/out from raw timestamps, and stores everything locally in SQLite.

No Firebase. No ERP integration. No Python runtime required at runtime.
Designed to be folded into Apon ERP later — schema and derivation rules
are bit-identical to the existing Python `attendance-service`.

---

## One-time setup (on the office PC that can reach 192.168.0.150)

Run these in order from a terminal in `C:\Users\Kairi\Documents\Claude\Projects\Attendance Program\`.

### 1. Bootstrap the Flutter project

```cmd
flutter create --org com.apon --platforms windows apon_attendance
cd apon_attendance
```

### 2. Copy the staged source files in

The `lib\`, `pubspec.yaml`, `analysis_options.yaml`, `.env`, and
`assets\` files in this folder (one level up from the `apon_attendance`
folder you just created) are the actual app code. Copy them in,
overwriting Flutter's defaults:

```cmd
xcopy /E /Y "..\lib" ".\lib\"
copy /Y "..\pubspec.yaml" ".\pubspec.yaml"
copy /Y "..\analysis_options.yaml" ".\analysis_options.yaml"
copy /Y "..\.env" ".\.env"
xcopy /E /Y /I "..\assets" ".\assets"
```

(Or just drag-and-drop in Explorer — whichever feels less fragile.)

### 3. Pull dependencies

```cmd
flutter pub get
```

### 4. Run it

```cmd
flutter run -d windows
```

The first run will compile the C++ side of the Windows embedder, which
takes a few minutes. After that, hot-restart is instant.

---

## What you should see

1. Home screen — big status card showing the device IP and a **Connect**
   button.
2. Hit Connect → it opens a TCP socket to `192.168.0.150:4370`, sends
   `CMD_CONNECT`, and gets back a session ID. Status flips to green.
3. Hit **Sync** → it disables the device (so nobody scans mid-pull),
   downloads users + all punches, re-enables, and writes everything to
   `apon_attendance.db` in your app data folder.
4. Tabs: **Employees** (raw user list from device), **Punches** (raw scan
   log, sortable), **Daily** (derived check-in/out summary using the
   same rules as `derive.py`), **Export** (CSV / XLSX dump for handing
   to anyone who wants the data).

---

## Where the database lives

Windows: `%APPDATA%\com.apon\apon_attendance\apon_attendance.db`

It's a plain SQLite file. Same schema as the Python service's
`data\zkteco.db` so you can swap them around or query both with the
same SQL.

---

## When you want to integrate with Apon ERP

The dart-side Firestore writes are intentionally not built yet. The
hooks are there — `lib\services\sync\firestore_sync.dart` is a stub
that takes the same `DailySummary` objects the UI shows and would push
to the `attendance` and `zkteco_punches` collections. Wire it up when
the ERP is ready; nothing else in the standalone app needs to change.

---

## Troubleshooting

**"Connect failed: SocketException"** — you're not on the office LAN, or
the device is off. Sanity check:
```cmd
ping 192.168.0.150
```

**"Connect failed: bad checksum"** — there's a bug in the protocol
implementation. Drop the failing packet hex into the chat and we'll
fix `lib\services\zkteco\zk_protocol.dart` together.

**Empty users / empty punches but device clearly has data** — the device
might be using comm key ≠ 0. Edit `.env`:
```
ZK_COMM_KEY=12345
```
and the AUTH handshake will run before commands.

**App data folder not where you expect** — `path_provider` returns the
real path on first run; check the debug console. You can override it
in `lib\config.dart` with `kOverrideDbPath`.
