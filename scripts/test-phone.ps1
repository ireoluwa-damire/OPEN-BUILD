param([Parameter(Mandatory=$true)][string]$Device)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterScript = Join-Path $PSScriptRoot 'flutter.ps1'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$testApk = Join-Path $projectRoot '.tooling\phone-suite.apk'
$regularApk = Join-Path $projectRoot 'dist\sumi-v0.2.0-android-arm64.apk'
if (!(Test-Path -LiteralPath $regularApk)) {
  throw 'Build and save the regular APK in dist before starting the phone suite.'
}
& $flutterScript build apk --debug --target-platform android-arm64 --target integration_test/phone_suite_test.dart
if ($LASTEXITCODE -ne 0) { throw 'Phone test build failed.' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'app\build\app\outputs\flutter-apk\app-debug.apk') -Destination $testApk -Force

# Never use Flutter's installer fallback: it may uninstall after a failed update.
& $adb -s $Device install --no-streaming -t -r $testApk
if ($LASTEXITCODE -ne 0) {
  throw 'Android rejected installation. Approve the phone prompt / Install via USB, then retry. Existing app data was not cleared.'
}
& $adb -s $Device shell am force-stop com.example.sumi
& $adb -s $Device shell am start -n com.example.sumi/.MainActivity --ez enable-checked-mode true
if ($LASTEXITCODE -ne 0) { throw 'The test app could not be started.' }
$serviceUri = $null
for ($attempt = 0; $attempt -lt 40; $attempt++) {
  $testProcessId = (& $adb -s $Device shell pidof com.example.sumi).Trim()
  if ($testProcessId -match '^\d+$') {
    $appLog = (& $adb -s $Device logcat -d --pid=$testProcessId -v raw) -join [Environment]::NewLine
    if ($appLog -match 'The Dart VM service is listening on (http://127\.0\.0\.1:\d+/\S+)') {
      $serviceUri = [uri]$Matches[1]
      break
    }
  }
  Start-Sleep -Milliseconds 500
}
if ($null -eq $serviceUri) {
  throw 'No Dart service was found. Keep the phone unlocked; the test app may still be starting.'
}
$forwardedPort = (& $adb -s $Device forward tcp:0 "tcp:$($serviceUri.Port)").Trim()
if ($LASTEXITCODE -ne 0 -or $forwardedPort -notmatch '^\d+$') { throw 'ADB forwarding failed.' }
$localService = "http://127.0.0.1:$forwardedPort$($serviceUri.AbsolutePath)"
try {
  & $flutterScript drive --driver test_driver/phone_driver.dart --target integration_test/phone_suite_test.dart --device-id $Device "--use-existing-app=$localService" --keep-app-running --no-pub
  $suiteExitCode = $LASTEXITCODE
  $report = & $adb -s $Device exec-out run-as com.example.sumi cat files/phone-models/on-device-smoke.json
  if ($LASTEXITCODE -eq 0) {
    $report | Set-Content -LiteralPath (Join-Path $projectRoot 'research\on-device-smoke.json') -Encoding utf8
  }
} finally {
  & $adb -s $Device forward --remove "tcp:$forwardedPort"
}
Write-Host 'Restoring the regular app; approve its update prompt on the phone.'
& $adb -s $Device install --no-streaming -r $regularApk
if ($LASTEXITCODE -ne 0) { throw 'Restore was blocked. Install the regular APK from dist with adb install --no-streaming -r; do not uninstall or clear storage.' }
& $adb -s $Device shell am start -n com.example.sumi/.MainActivity
exit $suiteExitCode
