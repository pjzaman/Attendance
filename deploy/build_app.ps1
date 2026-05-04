# Build a deployable Windows release of the Flutter app.
#
# Run on the dev laptop. Produces:
#     deploy\out\apon-attendance-app\        ← unzipped Release folder
#     deploy\out\apon-attendance-app.zip     ← zipped, ready to ship
#
# The target-machine user (HR, manager, etc.) unzips and runs
# apon_attendance.exe inside the unzipped folder. No installer
# needed; no admin rights needed; the .exe alone won't run because
# it depends on the DLLs in the same folder, so they must keep the
# whole folder together.

$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DeployOut = Join-Path $RepoRoot 'deploy\out'
$BundleDir = Join-Path $DeployOut 'apon-attendance-app'
$BundleZip = Join-Path $DeployOut 'apon-attendance-app.zip'

function Invoke-Native {
    param([scriptblock]$Block, [string]$Description)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Block
        if ($LASTEXITCODE -ne 0) {
            throw "$Description failed (exit $LASTEXITCODE)"
        }
    } finally {
        $ErrorActionPreference = $prev
    }
}

Write-Host "Building Flutter Windows release..." -ForegroundColor Cyan

Push-Location $RepoRoot
try {
    Invoke-Native { flutter pub get } -Description "flutter pub get"
    Invoke-Native { flutter build windows --release } -Description "flutter build"
} finally {
    Pop-Location
}

$ReleaseDir = Join-Path $RepoRoot 'build\windows\x64\runner\Release'
if (-not (Test-Path $ReleaseDir)) {
    Write-Error "Flutter build did not produce $ReleaseDir"
    exit 1
}

# ── Assemble the bundle ──────────────────────────────────────────
if (Test-Path $BundleDir) { Remove-Item -Recurse -Force $BundleDir }
New-Item -ItemType Directory -Force -Path $BundleDir | Out-Null

Copy-Item -Recurse "$ReleaseDir\*" $BundleDir

# ── Zip it ───────────────────────────────────────────────────────
if (Test-Path $BundleZip) { Remove-Item -Force $BundleZip }
Compress-Archive -Path "$BundleDir\*" -DestinationPath $BundleZip

$exe = Join-Path $BundleDir 'apon_attendance.exe'
$zipBytes = (Get-Item $BundleZip).Length

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  App folder: $BundleDir"
Write-Host "  Zip:        $BundleZip ($([math]::Round($zipBytes/1MB,1)) MB)"
Write-Host ""
Write-Host "Ship apon-attendance-app.zip to the user. They:" -ForegroundColor Cyan
Write-Host "  1. Unzip anywhere (e.g. Desktop or Documents)"
Write-Host "  2. Double-click apon_attendance.exe"
Write-Host "  3. Sign in with the Firebase Auth account you provisioned"
Write-Host ""
Write-Host "Optional: pin apon_attendance.exe to the Start menu."
