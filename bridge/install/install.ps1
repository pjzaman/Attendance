# Apon Attendance Bridge — installer
#
# Run as Administrator on the PC physically wired to the ZKTeco.
# Usage:
#     .\install.ps1
#
# What this does:
#   1. Copies the bundled apon-bridge.exe + .env + firebase-sa.json
#      into "C:\Program Files\ApponBridge\"
#   2. Registers a scheduled task that runs the bridge as SYSTEM at
#      boot, restarts on failure, and survives user logout.
#
# What it does NOT do:
#   - Edit your .env file. You must do that BEFORE running this
#     script (set DEVICE_IP, BRIDGE_ID, etc.) or after (then run
#     `Restart-ScheduledTask -TaskName ApponBridge`).

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundleDir   = Split-Path -Parent $ScriptDir
$InstallDir  = "C:\Program Files\ApponBridge"
$TaskName    = "ApponBridge"

function Require-File([string]$path, [string]$reason) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required file: $path`n$reason"
        exit 1
    }
}

Write-Host "Apon Attendance Bridge installer" -ForegroundColor Cyan
Write-Host "─────────────────────────────────"
Write-Host ""

# ── 1. Validate the bundle has everything we need ────────────────
Require-File "$BundleDir\apon-bridge.exe" `
    "Run deploy\build_bridge.ps1 first to produce the exe."
Require-File "$BundleDir\.env" `
    "Copy .env.example to .env and fill in DEVICE_IP, BRIDGE_ID, etc."
Require-File "$BundleDir\firebase-sa.json" `
    "Download a service-account JSON from Firebase Console > Project Settings > Service Accounts > Generate new private key, save it as firebase-sa.json next to this script."

# ── 2. Copy files into Program Files ─────────────────────────────
Write-Host "Installing to: $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Copy-Item -Force "$BundleDir\apon-bridge.exe" $InstallDir
Copy-Item -Force "$BundleDir\firebase-sa.json" $InstallDir

# Don't clobber an existing .env — operator may have customized it.
if (-not (Test-Path "$InstallDir\.env")) {
    Copy-Item "$BundleDir\.env" $InstallDir
} else {
    Write-Host "  Keeping existing .env (not overwriting)" -ForegroundColor Yellow
}

# ── 3. Register the scheduled task ───────────────────────────────
Write-Host "Registering scheduled task: $TaskName"

# Remove any existing version cleanly.
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
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

# Auto-restart on failure: 1 minute delay, up to 999 retries.
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

# ── 4. Start it now ──────────────────────────────────────────────
Write-Host "Starting bridge..."
Start-ScheduledTask -TaskName $TaskName

Start-Sleep -Seconds 2
$task = Get-ScheduledTask -TaskName $TaskName
$info = Get-ScheduledTaskInfo -TaskName $TaskName

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  State:        $($task.State)"
Write-Host "  Last result:  $($info.LastTaskResult)"
Write-Host "  Install dir:  $InstallDir"
Write-Host ""
Write-Host "To view logs (the bridge prints to stdout):" -ForegroundColor Cyan
Write-Host "  Get-EventLog -LogName Application -Source ApponBridge -Newest 50"
Write-Host ""
Write-Host "To check Firestore: open the Firebase console and look at the"
Write-Host "  bridges/<your BRIDGE_ID> document. updatedAt should tick"
Write-Host "  every $($env:HEARTBEAT_INTERVAL_SECONDS) seconds (default 30s)."
