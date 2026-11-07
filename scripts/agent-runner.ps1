# Local verification runner for the implementation agent.
# Start it yourself:  powershell -ExecutionPolicy Bypass -File .\scripts\agent-runner.ps1
# It watches .tooling\agent-queue for *.job files and runs ONLY these verbs:
#   analyze | test [test-paths...] | pubget | build-apk | check-links
# Arguments are restricted to relative test paths. Output goes to <job>.log and
# the exit code to <job>.done. Stop it with Ctrl+C or by closing the window.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$queue = Join-Path $root '.tooling\agent-queue'
$flutter = Join-Path $PSScriptRoot 'flutter.ps1'
$testUi = Join-Path $PSScriptRoot 'test-ui.ps1'
New-Item -ItemType Directory -Force -Path $queue | Out-Null
Write-Host "Sumi agent runner watching $queue (Ctrl+C to stop)"
function Invoke-Child([string]$script, [string[]]$arguments, [string]$log) {
  $argText = ($arguments | ForEach-Object { $_ }) -join ' '
  $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$script`" $argText > `"$log`" 2>&1"
  cmd.exe /c $cmd
  return $LASTEXITCODE
}
while ($true) {
  try {
    $jobs = Get-ChildItem -LiteralPath $queue -Filter '*.job' -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($job in $jobs) {
      $id = [IO.Path]::GetFileNameWithoutExtension($job.Name)
      $log = Join-Path $queue "$id.log"
      $done = Join-Path $queue "$id.done"
      $line = (Get-Content -LiteralPath $job.FullName -Raw).Trim()
      Remove-Item -LiteralPath $job.FullName -Force
      $parts = @($line -split '\s+' | Where-Object { $_ -ne '' })
      $verb = $parts[0]
      $rest = @(); if ($parts.Count -gt 1) { $rest = $parts[1..($parts.Count-1)] }
      $bad = $rest | Where-Object { $_ -notmatch '^[A-Za-z0-9_./=-]+$' -or $_ -match '\.\.' }
      Write-Host "[$(Get-Date -Format HH:mm:ss)] $id : $line"
      $code = 99
      try {
        if ($bad) { "Rejected argument(s): $bad" | Out-File $log -Encoding ascii }
        else {
          switch ($verb) {
            'analyze'   { $code = Invoke-Child $flutter @('analyze') $log }
            'test'      { $code = Invoke-Child $testUi $rest $log }
            'pubget'    { $code = Invoke-Child $flutter @('pub','get') $log }
            'check-links' { $code = Invoke-Child (Join-Path $PSScriptRoot 'check_links.ps1') @() $log }
            'build-apk' { $code = Invoke-Child $flutter @('build','apk','--debug','--target-platform','android-arm64,android-x64') $log }
            default     { "Unknown verb: $verb" | Out-File $log -Encoding ascii }
          }
        }
      } catch { "Runner error: $_" | Out-File $log -Append -Encoding ascii; $code = 98 }
      "$code" | Out-File $done -Encoding ascii
      Write-Host "  -> exit $code"
    }
  } catch { Write-Host "Loop error: $_" }
  Start-Sleep -Seconds 2
}
