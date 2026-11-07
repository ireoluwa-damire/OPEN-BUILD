# QA: checks that every resource URL in app/assets/disciplines.json resolves.
# YouTube links are checked through the public oEmbed endpoint (404 = missing).
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$data = Get-Content -Raw (Join-Path $root 'app\assets\disciplines.json') | ConvertFrom-Json
$failed = 0
foreach ($track in $data.tracks) {
  foreach ($r in $track.resources) {
    $url = if ($r.canonical_url) { $r.canonical_url } else { $r.url }
    $probe = $url
    if ($url -match 'youtube\.com|youtu\.be') {
      $probe = 'https://www.youtube.com/oembed?format=json&url=' + [uri]::EscapeDataString($url)
    }
    try {
      $resp = Invoke-WebRequest -Uri $probe -Method Get -UseBasicParsing -TimeoutSec 20
      $status = [int]$resp.StatusCode
      $title = ''
      if ($probe -ne $url) { $title = ($resp.Content | ConvertFrom-Json).title }
      Write-Output "OK   $status $($r.id) $url $title"
    } catch {
      $code = $_.Exception.Response.StatusCode.value__
      Write-Output "FAIL $code $($r.id) $url"
      $failed++
    }
  }
}
Write-Output "Failed: $failed"
exit $failed
