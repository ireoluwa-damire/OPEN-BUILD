# GOV-01: fails (exit 1) if third-party or generated material is tracked by git.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$tracked = git ls-files
$bad = $tracked | Where-Object {
  $_ -match '\.(apk|aab|riv)$' -or
  ($_ -match '(?i)duolingo' -and $_ -notmatch '\.md$') -or
  $_ -match '^research/(captures|live-reference-[^/]+/frames)/' -or
  $_ -match '^research/animation-reference/(media|runtime)/' -or
  ($_ -match '^research/.*\.(png|jpg|gif|mp4|webm)$') -or
  $_ -match '^tools/jadx' -or
  $_ -match '^(OPEN-BUILD-reference-pack\.zip|Mascot concepts)$'
}
if ($bad) { Write-Host 'Tracked third-party/generated files:'; $bad; exit 1 }
Write-Host 'Repository hygiene OK'; exit 0
