# Apon Bridge - diagnostic script
#
# Run as Administrator on the device PC. Captures everything relevant
# to debugging "the bridge isn't writing to Firestore" (install dir
# contents, sanitized .env, scheduled task state, 25s of foreground
# bridge output) into a single log file on the Desktop. Send the log
# back to the dev session for analysis.
#
# Secrets are redacted: the firebase-sa.json's private_key is never
# printed; only safe identifying fields (project_id, client_email)
# are.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'

$LogPath    = "$env:USERPROFILE\Desktop\apon-bridge-diagnostic.log"
$InstallDir = "C:\Program Files\ApponBridge"

Start-Transcript -Path $LogPath -Force | Out-Null

function Section([string]$name) {
    Write-Host ""
    Write-Host "========== $name ==========" -ForegroundColor Cyan
}

Write-Host "Apon Bridge diagnostic - $(Get-Date)"
Write-Host "Host:        $env:COMPUTERNAME"
Write-Host "User:        $env:USERNAME"
Write-Host "PowerShell:  $($PSVersionTable.PSVersion)"
Write-Host "Windows:     $((Get-CimInstance Win32_OperatingSystem).Caption)"

# Install directory
Section "Install directory"
if (Test-Path $InstallDir) {
    Write-Host "Path exists: $InstallDir"
    Get-ChildItem $InstallDir -Force |
        Select-Object Name, Length, LastWriteTime |
        Format-Table -AutoSize
} else {
    Write-Host "Path does NOT exist: $InstallDir" -ForegroundColor Red
}

# .env (sanitized)
Section ".env (secrets redacted)"
$EnvFile = "$InstallDir\.env"
if (Test-Path $EnvFile) {
    $allowed = @(
        'GOOGLE_APPLICATION_CREDENTIALS','FIREBASE_PROJECT_ID',
        'BRIDGE_ID','POLL_INTERVAL_SECONDS','HEARTBEAT_INTERVAL_SECONDS',
        'STATE_DB_PATH','DEVICE_IP','DEVICE_PORT','DEVICE_TIMEOUT',
        'DEVICE_FORCE_UDP','DEVICE_ID'
    )
    Get-Content $EnvFile | ForEach-Object {
        $line = $_
        if ($line -match '^([A-Z_]+)=(.*)$') {
            $key = $Matches[1]; $value = $Matches[2]
            if ($allowed -contains $key) {
                Write-Host "$key=$value"
            } else {
                Write-Host "$key=<redacted>"
            }
        } elseif ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line)) {
            Write-Host $line
        }
    }
} else {
    Write-Host "ENV file does NOT exist: $EnvFile" -ForegroundColor Red
}

# firebase-sa.json (private key never printed)
Section "firebase-sa.json (private key not printed)"
$SaFile = "$InstallDir\firebase-sa.json"
if (Test-Path $SaFile) {
    Write-Host "Path: $SaFile"
    Write-Host "Size: $((Get-Item $SaFile).Length) bytes"
    try {
        $sa = Get-Content $SaFile -Raw | ConvertFrom-Json
        Write-Host "type:                  $($sa.type)"
        Write-Host "project_id:            $($sa.project_id)"
        Write-Host "client_email:          $($sa.client_email)"
        $hasPK = if ($sa.private_key) { 'present' } else { 'MISSING' }
        Write-Host "private_key:           <redacted, $hasPK>"
        $hasId = if ($sa.private_key_id) { 'present' } else { 'MISSING' }
        Write-Host "private_key_id:        <redacted, $hasId>"
    } catch {
        Write-Host "Could not parse JSON: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "File does NOT exist: $SaFile" -ForegroundColor Red
}

# Scheduled task
Section "Scheduled task"
$task = Get-ScheduledTask -TaskName ApponBridge -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "State:              $($task.State)"
    $info = Get-ScheduledTaskInfo -TaskName ApponBridge
    Write-Host "LastRunTime:        $($info.LastRunTime)"
    Write-Host "LastTaskResult:     0x$('{0:X}' -f $info.LastTaskResult) ($($info.LastTaskResult))"
    Write-Host "NumberOfMissedRuns: $($info.NumberOfMissedRuns)"
    Write-Host "NextRunTime:        $($info.NextRunTime)"
} else {
    Write-Host "Task 'ApponBridge' does NOT exist" -ForegroundColor Red
}

# Network reachability
Section "Network reachability"
$endpoints = @('firestore.googleapis.com','firebase.google.com')
foreach ($endpoint in $endpoints) {
    try {
        $r = Test-NetConnection -ComputerName $endpoint -Port 443 `
                                -InformationLevel Quiet `
                                -WarningAction SilentlyContinue
        if ($r) {
            Write-Host "$endpoint`:443 - reachable"
        } else {
            Write-Host "$endpoint`:443 - NOT reachable"
        }
    } catch {
        Write-Host "$endpoint`:443 - error: $($_.Exception.Message)"
    }
}

# Foreground bridge run
Section "Bridge foreground run (up to 25s)"
$BridgeExe = "$InstallDir\apon-bridge.exe"
if (Test-Path $BridgeExe) {
    Stop-ScheduledTask -TaskName ApponBridge -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    $stdoutFile = "$env:TEMP\apon-bridge-stdout.log"
    $stderrFile = "$env:TEMP\apon-bridge-stderr.log"
    Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue

    Push-Location $InstallDir
    try {
        $proc = Start-Process -FilePath $BridgeExe `
                              -WorkingDirectory $InstallDir `
                              -RedirectStandardOutput $stdoutFile `
                              -RedirectStandardError $stderrFile `
                              -PassThru -NoNewWindow
        $exited = $proc.WaitForExit(25000)
        if (-not $exited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "[killed after 25s - bridge was still running, which is normal]"
        } else {
            Write-Host "[bridge exited with code $($proc.ExitCode) within 25s]"
        }
    } finally {
        Pop-Location
    }

    Write-Host ""
    Write-Host "--- bridge stdout ---"
    if (Test-Path $stdoutFile) { Get-Content $stdoutFile }
    Write-Host ""
    Write-Host "--- bridge stderr ---"
    if (Test-Path $stderrFile) { Get-Content $stderrFile }
} else {
    Write-Host "Bridge exe does NOT exist at $BridgeExe" -ForegroundColor Red
}

# Restart scheduled task
Section "Restarting scheduled task"
try {
    Start-ScheduledTask -TaskName ApponBridge -ErrorAction Stop
    Write-Host "Task restarted"
} catch {
    Write-Host "Could not start task: $($_.Exception.Message)" -ForegroundColor Yellow
}

Stop-Transcript | Out-Null

Write-Host ""
Write-Host "Diagnostic log written to:" -ForegroundColor Green
Write-Host "  $LogPath" -ForegroundColor Green
Write-Host ""
Write-Host "Send this file back to the dev session." -ForegroundColor Cyan
