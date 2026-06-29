param(
  [Parameter(Mandatory = $true)]
  [string]$UrlsFile,

  [string]$OutputDir = "",
  [int]$Timeout = 30,
  [int]$MaxAttempts = 6,
  [string[]]$Selector = @(),
  [switch]$NoPlaywright
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$py = Join-Path $repo '.venv\Scripts\python.exe'
$engineDir = Join-Path $repo 'skills\insane-search'

if (-not (Test-Path -LiteralPath $py)) {
  throw "venv missing. Run scripts\bootstrap.ps1 first."
}

if (-not (Test-Path -LiteralPath $UrlsFile)) {
  throw "URL file not found: $UrlsFile"
}

if (-not $OutputDir) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $OutputDir = Join-Path $repo "test-artifacts\research-run-$stamp"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONPATH = $engineDir
$env:PATH = "$(Join-Path $repo '.venv\Scripts');$env:PATH"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

$urls = Get-Content -LiteralPath $UrlsFile |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -and -not $_.StartsWith('#') }

$results = New-Object System.Collections.Generic.List[object]
$i = 0

Push-Location $engineDir
try {
  foreach ($url in $urls) {
    $i += 1
    $prefix = '{0:D3}' -f $i
    $stdoutPath = Join-Path $OutputDir "$prefix.stdout.json"
    $stderrPath = Join-Path $OutputDir "$prefix.stderr.txt"

    $argsList = @(
      '-m', 'engine',
      $url,
      '--timeout', [string]$Timeout,
      '--json'
    )

    if ($MaxAttempts -gt 0) {
      $argsList += @('--max-attempts', [string]$MaxAttempts)
    }
    if ($NoPlaywright) {
      $argsList += '--no-playwright'
    }
    foreach ($s in $Selector) {
      $argsList += @('--selector', $s)
    }

    Write-Host "[$prefix/$($urls.Count)] $url"
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
      $stdout = & $py @argsList 2> $stderrPath
      $exitCode = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $oldErrorActionPreference
    }
    $stdout | Set-Content -LiteralPath $stdoutPath -Encoding UTF8

    $ok = $false
    $verdict = $null
    $profile = $null
    $summary = $null
    try {
      $parsed = ($stdout -join "`n") | ConvertFrom-Json
      $ok = [bool]$parsed.ok
      $verdict = $parsed.verdict
      $profile = $parsed.profile_used
      $summary = $parsed.summary
    } catch {
      $summary = "stdout was not valid JSON"
    }

    $results.Add([pscustomobject]@{
      index = $i
      url = $url
      exitCode = $exitCode
      ok = $ok
      verdict = $verdict
      profileUsed = $profile
      summary = $summary
      stdout = $stdoutPath
      stderr = $stderrPath
    })
  }
} finally {
  Pop-Location
}

$summaryPath = Join-Path $OutputDir 'summary.json'
[pscustomobject]@{
  urlsFile = (Resolve-Path -LiteralPath $UrlsFile).Path
  outputDir = (Resolve-Path -LiteralPath $OutputDir).Path
  total = $results.Count
  ok = @($results | Where-Object { $_.ok }).Count
  failed = @($results | Where-Object { -not $_.ok }).Count
  results = $results
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host "summary: $summaryPath"
Write-Host "output: $OutputDir"

if (@($results | Where-Object { -not $_.ok }).Count -gt 0) {
  exit 1
}
exit 0
