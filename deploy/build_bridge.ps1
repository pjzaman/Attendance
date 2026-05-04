# Build a deployable bundle of the Python bridge.
#
# Run on the dev laptop (this machine). Produces:
#     deploy\out\apon-bridge-bundle\
#         apon-bridge.exe        ← single-file PyInstaller exe
#         install\
#             install.ps1
#             uninstall.ps1
#         .env.example
#     deploy\out\apon-bridge-bundle.zip  ← zip of the above for transport
#
# The target-machine operator unzips, edits .env (rename from
# .env.example), drops their firebase-sa.json next to the exe, then
# right-click → Run as Administrator on install\install.ps1.

$ErrorActionPreference = 'Stop'

$RepoRoot   = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BridgeDir  = Join-Path $RepoRoot 'bridge'
$DeployOut  = Join-Path $RepoRoot 'deploy\out'
$BundleDir  = Join-Path $DeployOut 'apon-bridge-bundle'
$BundleZip  = Join-Path $DeployOut 'apon-bridge-bundle.zip'

# Run a native command and check its exit code, while temporarily
# letting stderr output through without tripping ErrorActionPreference
# = Stop. (PowerShell 5.1 treats native-command stderr as an error
# record, which would abort the whole script even on warnings.)
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

Write-Host "Building bridge from: $BridgeDir" -ForegroundColor Cyan

# ── 1. Resolve venv. If bridge\.venv doesn't exist, create it. ──
$VenvDir = Join-Path $BridgeDir '.venv'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

if (-not (Test-Path $VenvPython)) {
    Write-Host "Creating venv at $VenvDir"
    Invoke-Native { python -m venv $VenvDir } -Description "venv create"
}

Write-Host "Installing bridge + build deps into venv"
Invoke-Native { & $VenvPython -m pip install --quiet --upgrade pip } `
    -Description "pip upgrade"
Invoke-Native { & $VenvPython -m pip install --quiet -e "$BridgeDir[build]" } `
    -Description "pip install bridge"

# ── 2. Run PyInstaller ───────────────────────────────────────────
Write-Host "Running PyInstaller..."
Push-Location $BridgeDir
try {
    Invoke-Native {
        & $VenvPython -m PyInstaller --clean --noconfirm apon-bridge.spec
    } -Description "PyInstaller"
} finally {
    Pop-Location
}

$BuiltExe = Join-Path $BridgeDir 'dist\apon-bridge.exe'
if (-not (Test-Path $BuiltExe)) {
    Write-Error "PyInstaller did not produce $BuiltExe"
    exit 1
}

# ── 3. Assemble the bundle ───────────────────────────────────────
Write-Host "Assembling bundle: $BundleDir"
if (Test-Path $BundleDir) { Remove-Item -Recurse -Force $BundleDir }
New-Item -ItemType Directory -Force -Path $BundleDir | Out-Null

Copy-Item $BuiltExe                            $BundleDir
Copy-Item (Join-Path $BridgeDir '.env.example') $BundleDir
Copy-Item -Recurse (Join-Path $BridgeDir 'install') $BundleDir

# ── 4. Zip it ────────────────────────────────────────────────────
if (Test-Path $BundleZip) { Remove-Item -Force $BundleZip }
Compress-Archive -Path "$BundleDir\*" -DestinationPath $BundleZip

$exeBytes = (Get-Item $BuiltExe).Length
$zipBytes = (Get-Item $BundleZip).Length
Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  Exe:    $BuiltExe ($([math]::Round($exeBytes/1MB,1)) MB)"
Write-Host "  Bundle: $BundleDir"
Write-Host "  Zip:    $BundleZip ($([math]::Round($zipBytes/1MB,1)) MB)"
Write-Host ""
Write-Host "Ship apon-bridge-bundle.zip to the device-PC. The operator there:" -ForegroundColor Cyan
Write-Host "  1. Unzip"
Write-Host "  2. Rename .env.example → .env, edit DEVICE_IP / BRIDGE_ID / etc."
Write-Host "  3. Drop firebase-sa.json next to apon-bridge.exe"
Write-Host "  4. Right-click install\install.ps1 → Run as Administrator"
