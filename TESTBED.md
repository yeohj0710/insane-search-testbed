# Insane Search Testbed

Local testbed for `fivetaku/insane-search`.

## Bootstrap

```powershell
.\scripts\bootstrap.ps1
```

Creates `.venv`, installs Python runtime dependencies, and installs local Node dependencies for the Playwright templates.

## Run

```powershell
.\scripts\run-tests.ps1
```

Runs:

- `engine/bias_check.py`
- deterministic engine regression tests
- online smoke checks against benign public endpoints
- CLI fetch checks for `example.com` and the requested YouTube link
- core live route battery for YouTube, Hacker News, arXiv, and Naver
- headless Playwright template check against `example.com`

Logs are written to `test-artifacts/`.
