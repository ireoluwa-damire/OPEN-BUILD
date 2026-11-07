param([Parameter(ValueFromRemainingArguments=$true)][string[]]$TestArguments)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = Join-Path $projectRoot '.tooling\flutter'
$dartExecutable = Join-Path $sdkRoot 'bin\cache\dart-sdk\bin\dart.exe'
$toolPackages = Join-Path $sdkRoot 'packages\flutter_tools\.dart_tool\package_config.json'
if (!(Test-Path -LiteralPath $toolPackages)) {
  throw 'This UI-only adapter requires the workspace Flutter 3.47.8 SDK. Use flutter test with your regular SDK instead.'
}
$previousFlutterRoot = $env:FLUTTER_ROOT
$env:FLUTTER_ROOT = $sdkRoot
$env:CI = 'true'
Push-Location -LiteralPath (Join-Path $projectRoot 'app')
try {
  & $dartExecutable "--packages=$toolPackages" (Join-Path $PSScriptRoot 'ui-test-runner.dart') @TestArguments
  $testExitCode = $LASTEXITCODE
} finally {
  Pop-Location
  $env:FLUTTER_ROOT = $previousFlutterRoot
}
exit $testExitCode
