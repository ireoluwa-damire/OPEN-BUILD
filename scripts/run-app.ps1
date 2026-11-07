param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$flutterHelper = Join-Path $PSScriptRoot 'flutter.ps1'
if ($Device -eq 'web-server') {
  & $flutterHelper run --device-id web-server --web-hostname 127.0.0.1 --web-port 5173
} else {
  & $flutterHelper run --device-id $Device
}
