param([Parameter(ValueFromRemainingArguments=$true)][string[]]$FlutterArguments)
# PowerShell reserves -d for its Debug switch; use Flutter's --device-id here.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = Join-Path $projectRoot '.tooling\flutter'
$dartExecutable = Join-Path $sdkRoot 'bin\cache\dart-sdk\bin\dart.exe'
$toolSnapshot = Join-Path $sdkRoot 'bin\cache\flutter_tools.snapshot'
$env:CI = 'true'
Push-Location -LiteralPath (Join-Path $projectRoot 'app')
try {
  if ((Test-Path -LiteralPath $dartExecutable) -and (Test-Path -LiteralPath $toolSnapshot)) {
    & $dartExecutable $toolSnapshot --no-version-check @FlutterArguments
  } else {
    & flutter @FlutterArguments
  }
  $flutterExitCode = $LASTEXITCODE
} finally {
  Pop-Location
}
exit $flutterExitCode
