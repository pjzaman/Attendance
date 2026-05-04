# Apon Attendance — Setup

Three workflows depending on what you're doing:

1. [**Dev laptop**](#1-dev-laptop) — make code changes, hot-reload locally
2. [**Ship the Flutter app**](#2-ship-the-flutter-app) to HR/manager laptops
3. [**Ship the bridge**](#3-ship-the-bridge) to the PC wired to the ZKTeco

Each workflow lists prerequisites and exact commands.

---

## 1. Dev laptop

### Prerequisites

- Windows 10/11 with Visual Studio 2022 (Desktop C++ workload — needed by Flutter
  Windows builds)
- Flutter SDK 3.4 or newer on `PATH`
- Python 3.10+ on `PATH` (for the bridge)
- Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project (the one this repo points at is `attendance-app-apon`)

### One-time

```powershell
git clone https://github.com/pjzaman/Attendance.git
cd Attendance

# Pull Flutter deps
flutter pub get

# (If using your own Firebase project, regenerate firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure
```

Enable the auth providers you want in the
[Firebase Console](https://console.firebase.google.com) →
Authentication → Sign-in method:

- **Email/Password** (required)
- **Google** (optional; for HR signing in via their Google account)

Create at least one user under Authentication → Users. That's your test login.

Deploy the Firestore security rules:

```powershell
firebase deploy --only firestore:rules
```

### Run the Flutter app

```powershell
flutter run -d windows
```

First launch takes a few minutes (CMake compiles the Windows embedder).
Subsequent runs hot-restart in seconds.

### Run the bridge against a real device

```powershell
cd bridge

# Create a venv + install deps
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e .

# Configure
copy .env.example .env
# Edit .env: set DEVICE_IP to the ZKTeco's LAN address, BRIDGE_ID to
# anything stable (e.g. "dev-laptop"), and point GOOGLE_APPLICATION_CREDENTIALS
# at a service-account JSON.

# Service-account JSON: Firebase Console → Project settings →
# Service accounts → Generate new private key. Save next to .env (or
# anywhere; .env points at it).

# Run
python -m bridge.main
```

You should see logs every ~30s:

```
2026-05-03 17:42:01 INFO    bridge.main: apon-attendance-bridge starting
2026-05-03 17:42:01 INFO    bridge.device: device connected: serial=ABC1234567
2026-05-03 17:42:31 INFO    bridge.main: synced 12 new punch(es); high_water=2847
```

Check Firestore for `punches/*` and `bridges/<your BRIDGE_ID>` docs ticking.

---

## 2. Ship the Flutter app

The deployable artifact is a zip of the Windows Release folder. HR/manager
unzip it and double-click the exe — no installer, no admin rights, no
Python needed.

### On the dev laptop

```powershell
.\deploy\build_app.ps1
```

Outputs:
- `deploy\out\apon-attendance-app\` — unzipped Release folder
- `deploy\out\apon-attendance-app.zip` — 15 MB, ready to transport

Email or USB the zip.

### On the user's machine

1. Unzip anywhere (Desktop, Documents, wherever)
2. Double-click `apon_attendance.exe`
3. Sign in with the Firebase Auth account HR provisioned for them
4. (Optional) right-click → Pin to Start menu

The whole folder needs to stay together — the exe depends on DLLs alongside
it. Users can move/rename the folder freely; they just can't extract a
single file.

> **First-run note:** Windows SmartScreen may warn about an unsigned exe.
> "More info → Run anyway." A code-signing certificate would remove the
> warning; deferred until external distribution is needed.

---

## 3. Ship the bridge

### On the dev laptop

```powershell
.\deploy\build_bridge.ps1
```

Outputs:
- `deploy\out\apon-bridge-bundle\apon-bridge.exe` — single self-contained exe
  (~23 MB, includes Python interpreter + all deps)
- `deploy\out\apon-bridge-bundle\install\install.ps1` + `uninstall.ps1`
- `deploy\out\apon-bridge-bundle\.env.example`
- `deploy\out\apon-bridge-bundle.zip` — same, zipped for transport

### On the device-PC (the one wired to the ZKTeco)

1. **Unzip** `apon-bridge-bundle.zip` somewhere temporary (e.g. Desktop)
2. **Configure**: rename `.env.example` → `.env`, edit:
   - `DEVICE_IP` — ZKTeco's LAN address
   - `BRIDGE_ID` — stable name (e.g. `front-gate`)
   - `DEVICE_ID` — logical device name (e.g. `uface800-front`)
   - `GOOGLE_APPLICATION_CREDENTIALS` — path to the service-account JSON
     (recommend keeping it `./firebase-sa.json` and dropping the file
     next to the exe; the install script copies it into Program Files)
3. **Drop the service-account JSON** next to `apon-bridge.exe`. Get it
   from Firebase Console → Project settings → Service accounts →
   Generate new private key. Save as `firebase-sa.json`.
4. **Right-click** `install\install.ps1` → **Run as Administrator**.

The installer:
- Validates the bundle has all 3 required files
- Copies them to `C:\Program Files\ApponBridge\`
- Registers a Windows scheduled task (`ApponBridge`) that:
  - Runs as `SYSTEM`
  - Auto-starts at boot
  - Restarts every 1 minute on failure (up to 999 retries)
  - Survives user logouts
- Starts the bridge immediately

To verify: open the Firebase Console, look at `bridges/<your BRIDGE_ID>` —
the `updatedAt` field should tick every 30s.

### Updating an existing install

Build a fresh bundle and run `install.ps1` again. It overwrites
`apon-bridge.exe` and `firebase-sa.json` but **preserves your `.env`** so
operator config doesn't get reset.

### Uninstalling

```powershell
# Right-click → Run as Administrator
.\install\uninstall.ps1

# Add -PurgeState to also wipe the high-water-mark sqlite
.\install\uninstall.ps1 -PurgeState
```

---

## Troubleshooting

### Flutter app

**Login screen accepts credentials but immediately bounces back to login** —
your Firebase Auth user exists but Firestore rules are rejecting the read.
Run `firebase deploy --only firestore:rules` to push the latest rules.

**Empty dashboard after login** — Firestore is empty. Either let the seeders
run (they fire automatically on first launch with admin rights) or seed via
the Firebase Console.

**SmartScreen blocks the exe on first run** — "More info → Run anyway."

### Bridge

**`Missing required env var: GOOGLE_APPLICATION_CREDENTIALS`** — `.env` is
not next to `apon-bridge.exe`, or the file path it points at doesn't
exist. The error message includes the expected `.env` location.

**Device unreachable on startup** — bridge logs `device connect failed,
retrying in 60s` indefinitely. Sanity check from a terminal on the same
PC: `Test-NetConnection -ComputerName 192.168.0.150 -Port 4370`.

**`bridges/{id}` doc isn't updating in Firestore** — check Task Scheduler:
*Win + R → `taskschd.msc` → Task Scheduler Library → ApponBridge*. Look
at "Last run result" (`0x0` = ok). If non-zero, click "History" tab for
the actual exception.

**Bridge runs but nothing pushes to `punches/`** — check the high-water-
mark in `C:\Program Files\ApponBridge\bridge_state.sqlite`. If it's
already at the device's max attendance UID, the device just doesn't
have new records.

### Cloud

**Rules deploy fails with `MISSING_REQUIRED_API`** — Firebase will
auto-enable the API on first deploy. Wait 30s and retry.

**`firebase deploy` says "no project active"** — `cd` to the repo root
and confirm `.firebaserc` is present.

---

## Project layout cross-reference

For where to look when extending or debugging:

| Job | File |
|---|---|
| Add a new Firestore collection | `lib/services/firestore/firestore_repo.dart` + subscription in `lib/providers/app_state.dart` |
| Add a new screen | `lib/screens/<x>_screen.dart`, register in `lib/screens/home_screen.dart` |
| Add a bridge command | dispatcher in `bridge/bridge/command_executor.py` |
| Tighten Firestore rules per role | `firestore.rules`, then `firebase deploy --only firestore:rules` |
| Change first-launch defaults | corresponding `lib/services/*_seed.dart` |
| Theme tweaks | `lib/shared/app_theme.dart` |
