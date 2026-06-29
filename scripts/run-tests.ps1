param(
  [switch]$SkipCoverage,
  [switch]$SkipBrowser
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
$py = Join-Path $repo '.venv\Scripts\python.exe'
$artifacts = Join-Path $repo 'test-artifacts'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $artifacts "test-run-$stamp.log"
$summary = Join-Path $artifacts "summary-$stamp.json"

if (-not (Test-Path -LiteralPath $py)) {
  throw "venv missing. Run scripts\bootstrap.ps1 first."
}

New-Item -ItemType Directory -Force -Path $artifacts | Out-Null
Set-Location $repo

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONPATH = Join-Path $repo 'skills\insane-search'
$venvScripts = Join-Path $repo '.venv\Scripts'
$env:PATH = "$venvScripts;$env:PATH"

$results = New-Object System.Collections.Generic.List[object]

function Invoke-TestStep {
  param(
    [string]$Name,
    [scriptblock]$Command
  )

  $start = Get-Date
  "===== $Name =====" | Tee-Object -FilePath $log -Append
  try {
    & $Command 2>&1 | Tee-Object -FilePath $log -Append
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
  } catch {
    $_ | Out-String | Tee-Object -FilePath $log -Append
    $code = 1
  }
  $elapsed = [Math]::Round(((Get-Date) - $start).TotalSeconds, 2)
  "EXIT=$code ELAPSED=${elapsed}s" | Tee-Object -FilePath $log -Append
  "" | Tee-Object -FilePath $log -Append
  $results.Add([pscustomobject]@{
    name = $Name
    exitCode = $code
    elapsedSeconds = $elapsed
  })
}

Invoke-TestStep 'bias_check' {
  & $py 'skills\insane-search\engine\bias_check.py'
}

foreach ($test in @('test_u1.py', 'test_u4.py', 'test_u5.py', 'test_u7.py', 'test_u8.py', 'test_smoke.py')) {
  Invoke-TestStep "engine_tests/$test" {
    & $py "skills\insane-search\engine\tests\$test"
  }
}

Invoke-TestStep 'cli_example_json' {
  Push-Location (Join-Path $repo 'skills\insane-search')
  try {
    & $py -m engine 'https://example.com/' --selector h1 --selector p --timeout 15 --max-attempts 3 --no-playwright --json
  } finally {
    Pop-Location
  }
}

Invoke-TestStep 'cli_youtube_metadata' {
  Push-Location (Join-Path $repo 'skills\insane-search')
  try {
    & $py -m engine 'https://youtu.be/vjSZIyYd0NI?si=4HCubGogjOOxnfBc' --timeout 30 --max-attempts 3 --no-playwright --json
  } finally {
    Pop-Location
  }
}

if (-not $SkipCoverage) {
  Invoke-TestStep 'coverage_battery_core' {
    & $py 'skills\insane-search\tests\coverage_battery.py' youtube hn arxiv naver --json
  }
}

if (-not $SkipBrowser) {
  Invoke-TestStep 'playwright_template_example' {
    $templates = Join-Path $repo 'skills\insane-search\engine\templates'
    $payload = @{
      url = 'https://example.com/'
      profileDir = (Join-Path $artifacts 'pw-profile')
      waitSelector = 'h1'
      timeout = 30000
      headless = $true
    } | ConvertTo-Json -Compress
    Push-Location $templates
    try {
      $payload | node 'playwright_real_chrome.js'
    } finally {
      Pop-Location
    }
  }
}

$failed = @($results | Where-Object { $_.exitCode -ne 0 })
$payload = [pscustomobject]@{
  startedAt = $stamp
  log = $log
  results = $results
  failed = $failed
  ok = ($failed.Count -eq 0)
}
$payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summary -Encoding UTF8

Write-Host "summary: $summary"
Write-Host "log: $log"

if ($failed.Count -gt 0) {
  exit 1
}
exit 0
