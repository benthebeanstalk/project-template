set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
# Linux CI runners: pwsh is preinstalled, so the PowerShell recipes below run unchanged.
set shell := ["pwsh", "-NoLogo", "-Command"]

default:
    @just --list

# Install deps and create .env if missing
setup:
    if (Test-Path pyproject.toml) { uv sync }
    if (Test-Path package.json) { pnpm install }
    if (-not (Test-Path .env)) { Copy-Item .env.example .env }
    -pre-commit install

dev:
    @echo "Define the dev command for this project"

test:
    if (Test-Path pyproject.toml) { uv run pytest }
    if (Test-Path package.json) { pnpm test }

# Coverage report (not a CI gate). Needs pytest-cov / @vitest/coverage-v8 in the project.
coverage:
    if (Test-Path pyproject.toml) { uv run pytest --cov --cov-report=term-missing }
    if (Test-Path package.json) { pnpm exec vitest run --coverage }

lint:
    if (Test-Path pyproject.toml) { uv run ruff check .; uv run ruff format --check . }
    if (Test-Path package.json) { pnpm lint }

fmt:
    if (Test-Path pyproject.toml) { uv run ruff format .; uv run ruff check --fix . }
    if (Test-Path package.json) { pnpm exec prettier --write . }

# Quiet test run: prints only failures and a one-line summary. Full log: .logs/test.log
test-quiet:
    @& ./scripts/quiet.ps1 -Name test -Commands 'if (Test-Path pyproject.toml) { uv run pytest -q --tb=short }','if (Test-Path package.json) { pnpm test }'; exit $LASTEXITCODE

# Quiet lint run: prints only findings and a one-line summary. Full log: .logs/lint.log
lint-quiet:
    @& ./scripts/quiet.ps1 -Name lint -Commands 'if (Test-Path pyproject.toml) { uv run ruff check . --output-format=concise }','if (Test-Path pyproject.toml) { uv run ruff format --check . }','if (Test-Path package.json) { pnpm lint --quiet }'; exit $LASTEXITCODE

# Self-test for the quiet recipes (a failing command must fail the run)
quiet-selftest:
    @& ./scripts/quiet-selftest.ps1; exit $LASTEXITCODE

# Check docs links, `just` names and paths in the Markdown files (read only, no network). Allow-list: docs/.docs-check-ignore
docs-check:
    uv run --no-project python scripts/docs_check.py
