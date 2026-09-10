$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$venvPath   = Join-Path $PSScriptRoot ".venv"
$venvExe    = Join-Path $venvPath "Scripts\whichllm.exe"
$venvPython = Join-Path $venvPath "Scripts\python.exe"

# -- Path A: .venv already exists -> run directly, no internet, no tools needed -
if (Test-Path -LiteralPath $venvExe) {
    Write-Host "[INFO] Using existing virtual environment." -ForegroundColor Green
    & $venvExe @args
    exit $LASTEXITCODE
}

# -- Path B: no .venv -> need to create one. Try uv first, then system Python ---

# B1. Try uv (standalone, fetches Python + deps automatically, needs internet)
function Find-Uv {
    foreach ($dir in @("$env:USERPROFILE\.local\bin", "$env:USERPROFILE\.cargo\bin")) {
        $exe = Join-Path $dir "uv.exe"
        if (Test-Path -LiteralPath $exe) { $env:PATH = "$dir;$env:PATH"; return $exe }
    }
    try { return (Get-Command uv -ErrorAction Stop).Source } catch { return $null }
}

$uvExe = Find-Uv
if (-not $uvExe) {
    Write-Host "[SETUP] Installing uv (no Python required)..." -ForegroundColor Cyan
    $installScript = Join-Path $env:TEMP "uv-install.ps1"
    try {
        Invoke-WebRequest -Uri "https://astral.sh/uv/install.ps1" -OutFile $installScript -ErrorAction Stop
    } catch {
        try { & curl.exe -fsSL "https://astral.sh/uv/install.ps1" -o $installScript } catch {}
    }
    if (Test-Path -LiteralPath $installScript) {
        & $installScript
        if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] uv installer failed." -ForegroundColor Red; exit 1 }
        $uvExe = Find-Uv
    }
}

if ($uvExe) {
    Write-Host "[SETUP] Creating virtual environment with uv..." -ForegroundColor Cyan
    & $uvExe sync --dev
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SETUP] Ready!" -ForegroundColor Green
        & $uvExe run whichllm @args
        exit $LASTEXITCODE
    }
    Write-Host "[WARN] uv sync failed, trying system Python..." -ForegroundColor Yellow
}

# B2. Fall back to system Python 3.11+ with pip (needs internet for packages)
$pythonCmd = $null
foreach ($name in @("python", "python3")) {
    try {
        $ver = & $name -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
        if ($ver -and [version]$ver -ge [version]"3.11") { $pythonCmd = $name; break }
    } catch {}
}

if ($pythonCmd) {
    Write-Host "[SETUP] Creating virtual environment with system $pythonCmd..." -ForegroundColor Cyan
    & $pythonCmd -m venv $venvPath
    if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] venv creation failed." -ForegroundColor Red; exit 1 }
    & $venvPython -m pip install -e ".[dev]" --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SETUP] Ready!" -ForegroundColor Green
        & $venvExe @args
        exit $LASTEXITCODE
    }
    Write-Host "[WARN] pip install failed." -ForegroundColor Yellow
}

# -- Everything failed ---------------------------------------------------------
Write-Host "[ERROR] Cannot set up environment." -ForegroundColor Red
Write-Host ""
Write-Host "This project needs packages downloaded from the internet ONCE." -ForegroundColor Yellow
Write-Host "How to prepare for an offline machine:" -ForegroundColor Yellow
Write-Host "  1. On an internet-connected PC, run this script in the project folder." -ForegroundColor White
Write-Host "     It will download everything into the .venv folder." -ForegroundColor White
Write-Host "  2. Copy the WHOLE project folder (including .venv) to the offline PC." -ForegroundColor White
Write-Host "  3. Run this script again -- it will use .venv directly, no internet needed." -ForegroundColor White
exit 1
