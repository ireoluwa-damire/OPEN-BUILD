param([int]$Port = 8765, [string]$BindAddress = '127.0.0.1')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$pythonExecutable = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonExecutable)) { throw 'Create .venv and install backend dependencies first. See README.md.' }
& $pythonExecutable -m uvicorn backend.main:app --host $BindAddress --port $Port
