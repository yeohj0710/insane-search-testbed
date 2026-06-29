param(
  [switch]$SkipNode
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$venv = Join-Path $repo '.venv'
$py = Join-Path $venv 'Scripts\python.exe'

Set-Location $repo

if (-not (Test-Path -LiteralPath $venv)) {
  python -m venv $venv
}

& $py -m pip install --upgrade pip
& $py -m pip install -r (Join-Path $repo 'requirements-test.txt')

if (-not $SkipNode) {
  $templates = Join-Path $repo 'skills\insane-search\engine\templates'
  Push-Location $templates
  try {
    npm install --no-package-lock
  } finally {
    Pop-Location
  }
}

Write-Host "bootstrap complete"
Write-Host "python: $py"
