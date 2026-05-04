# Apon Attendance Bridge — interactive installer
#
# Run as Administrator on the PC physically wired to the ZKTeco.
# Just right-click → Run as Administrator. The script asks two
# questions, then sets everything up:
#
#   1. What should this bridge be called? (default: front-gate)
#   2. Where's your Firebase service-account JSON?
#      (defaults to firebase-sa.json next to this script)
#
# Then HR opens the Flutter app and sets the device IP from
# Settings → Integrations → Devices. The bridge picks it up
# automatically.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundleDir   = Split-Path -Parent $ScriptDir
$InstallDir  = "C:\Program Files\ApponBridge"
$TaskName    = "ApponBridge"

Write-Host ""
Write-Host "Apon Attendance Bridge installer" -ForegroundColor Cyan
Write-Host "─────────────────────────────────"
Write-Host ""

# ── 0. Check the exe is here ─────────────────────────────────────
if (-not (Test-Path "$BundleDir\apon-bridge.exe")) {
    Write-Error "apon-bridge.exe is missing from $BundleDir.`nDid you unzip the full bundle?"
    exit 1
}

# ── 1. Bridge ID ─────────────────────────────────────────────────
$DefaultBridgeId = "front-gate"
$BridgeId = Read-Host "Bridge ID (press Enter for '$DefaultBridgeId')"
if ([string]::IsNullOrWhiteSpace($BridgeId)) { $BridgeId = $DefaultBridgeId }
$BridgeId = $BridgeId.Trim()

# ── 2. Service-account JSON ──────────────────────────────────────
$DefaultSaPath = "$BundleDir\firebase-sa.json"
$SaPath = $DefaultSaPath
if (-not (Test-Path $DefaultSaPath)) {
    Write-Host ""
    Write-Host "Need a Firebase service-account JSON." -ForegroundColor Yellow
    Write-Host "  Get it from: Firebase Console → Project settings →"
    Write-Host "    Service accounts → Generate new private key"
    Write-Host ""
    while ($true) {
        $entered = Read-Host "Path to firebase-sa.json"
        $entered = $entered.Trim('"').Trim()
        if (Test-Path $entered) {
            $SaPath = (Resolve-Path $entered).Path
            break
        }
        Write-Host "  Not found at: $entered" -ForegroundColor Red
    }
}

# ── 3. Read project_id out of the SA JSON ────────────────────────
try {
    $sa = Get-Content -Raw $SaPath | ConvertFrom-Json
    $ProjectId = $sa.project_id
    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "project_id missing"
    }
} catch {
    Write-Error "Couldn't read project_id from the service-account JSON: $_"
    exit 1
}

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Bridge ID:        $BridgeId"
Write-Host "  Firebase project: $ProjectId"
Write-Host "  Service account:  $SaPath"
Write-Host ""

# ── 4. Copy files ────────────────────────────────────────────────
Write-Host "Installing to: $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Copy-Item -Force "$BundleDir\apon-bridge.exe" $InstallDir
Copy-Item -Force $SaPath "$InstallDir\firebase-sa.json"

# ── 5. Generate .env ─────────────────────────────────────────────
# Only regenerate on a fresh install. If an .env already exists
# (operator may have customized poll interval, etc.) leave it alone
# and just refresh the BRIDGE_ID line.
$EnvPath = "$InstallDir\.env"
if (Test-Path $EnvPath) {
    Write-Host "  Keeping existing .env (only updating BRIDGE_ID)" -ForegroundColor Yellow
    $existing = Get-Content $EnvPath -Raw
    if ($existing -match '(?m)^BRIDGE_ID=.*$') {
        $existing = $existing -replace '(?m)^BRIDGE_ID=.*$', "BRIDGE_ID=$BridgeId"
    } else {
        $existing += "`nBRIDGE_ID=$BridgeId`n"
    }
    $existing | Out-File -FilePath $EnvPath -Encoding utf8 -NoNewline
} else {
    @"
GOOGLE_APPLICATION_CREDENTIALS=./firebase-sa.json
FIREBASE_PROJECT_ID=$ProjectId
BRIDGE_ID=$BridgeId
POLL_INTERVAL_SECONDS=30
HEARTBEAT_INTERVAL_SECONDS=300
STATE_DB_PATH=./bridge_state.sqlite
"@ | Out-File -FilePath $EnvPath -Encoding utf8
}

# ── 6. Register the scheduled task ───────────────────────────────
Write-Host "Registering scheduled task: $TaskName"

$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$action = New-ScheduledTaskAction `
    -Execute "$InstallDir\apon-bridge.exe" `
    -WorkingDirectory $InstallDir
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Apon Attendance ZKTeco-to-Firestore bridge" | Out-Null

# ── 7. Start it ──────────────────────────────────────────────────
Write-Host "Starting bridge..."
Start-ScheduledTask -TaskName $TaskName

Start-Sleep -Seconds 3
$task = Get-ScheduledTask -TaskName $TaskName
$info = Get-ScheduledTaskInfo -TaskName $TaskName

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  State:        $($task.State)"
Write-Host "  Last result:  $($info.LastTaskResult)"
Write-Host "  Install dir:  $InstallDir"
Write-Host ""
Write-Host "Next step:" -ForegroundColor Cyan
Write-Host "  1. Open the Apon Attendance app on any PC."
Write-Host "  2. Sign in."
Write-Host "  3. Go to Settings → Integrations → Devices."
Write-Host "  4. You'll see a device named '$BridgeId' with placeholder IP 0.0.0.0."
Write-Host "  5. Click it, set the real IP / port / comm-key of your ZKTeco, save."
Write-Host ""
Write-Host "Within ~1 minute the bridge will pick up the new IP, connect, and"
Write-Host "start syncing. The 'Bridge services' panel on the same screen will"
Write-Host "flip to green."
