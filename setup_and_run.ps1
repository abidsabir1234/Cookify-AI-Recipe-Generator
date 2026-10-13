$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Cookify Model Server - Setup & Run" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$python312 = $null

try {
    $ver = & py -3.12 --version 2>&1
    if ($ver -match "3\.12") { $python312 = "py -3.12" }
}
catch { }

if (-not $python312) {
    $candidates = @(
        "C:\Python312\python.exe",
        "C:\Program Files\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:USERPROFILE\AppData\Local\Programs\Python\Python312\python.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $ver = & $c --version 2>&1
            if ($ver -match "3\.12") { $python312 = $c; break }
        }
    }
}

if (-not $python312) {
    Write-Host "Python 3.12 not found! Please install it." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found Python 3.12: $python312" -ForegroundColor Green

$VenvDir = Join-Path $ProjectDir "venv312"
if (-not (Test-Path $VenvDir)) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    if ($python312 -eq "py -3.12") { & py -3.12 -m venv venv312 }
    else { & $python312 -m venv venv312 }
}

$ActivateScript = Join-Path $VenvDir "Scripts\Activate.ps1"
if (-not (Test-Path $ActivateScript)) {
    Write-Host "Cannot find venv activation script!" -ForegroundColor Red
    exit 1
}
. $ActivateScript

Write-Host "Checking dependencies..." -ForegroundColor Yellow
python -m pip install --upgrade pip --quiet
pip install fastapi uvicorn onnxruntime opencv-python-headless numpy python-multipart ultralytics torch --quiet

if (Test-Path "best.pt") {
    Write-Host "Model file best.pt found (PyTorch)." -ForegroundColor Green
} else {
    Write-Host "CRITICAL: best.pt not found! Please place your trained model in this folder." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$portProcess = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($portProcess) {
    Write-Host "Warning: Port 8000 is already in use. Attempting to start regardless..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Starting Cookify API Server on port 8000" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

uvicorn app:app --host 0.0.0.0 --port 8000 --reload
