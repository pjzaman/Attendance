# Apon Attendance Bridge — uninstaller
#
# Run as Administrator. Removes the scheduled task and the install
# directory. Does NOT delete bridge_state.sqlite by default — pass
# -PurgeState if you want a clean wipe.

#Requires -RunAsAdministrator

param(
    [switch]$PurgeState
)

$ErrorActionPreference = 'Stop'

$InstallDir = "C:\Program Files\ApponBridge"
$TaskName   = "ApponBridge"

Write-Host "Stopping and unregistering scheduled task..."
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  removed task: $TaskName"
} else {
    Write-Host "  no scheduled task named $TaskName (already gone)"
}

# Give the process a moment to release file handles before deleting.
Start-Sleep -Seconds 2

if (Test-Path $InstallDir) {
    if ($PurgeState) {
        Write-Host "Removing install directory (with state): $InstallDir"
        Remove-Item -Recurse -Force $InstallDir
    } else {
        Write-Host "Removing install directory (preserving state): $InstallDir"
        Get-ChildItem $InstallDir -Force | ForEach-Object {
            if ($_.Name -ne 'bridge_state.sqlite') {
                Remove-Item -Recurse -Force $_.FullName
            }
        }
        Write-Host "  (bridge_state.sqlite preserved — pass -PurgeState to remove it too)"
    }
} else {
    Write-Host "  install dir was already absent: $InstallDir"
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Green
