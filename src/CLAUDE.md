# VM Environment Guide for Claude

You are running on an AWS EC2 instance managed by SkyPilot. This file tells you everything you need to know to get started.

## Environment Variables

All secrets and config are in `~/.env`, sourced automatically in every shell session.

Available variables:
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT` — Cloudflare R2 storage credentials
- `AIC_SDK_LICENSE`, `AIC_LICENSE_KEY` — ai-coustics SDK license
- `HF_TOKEN`, `HF_TOKEN_WRITE` — Hugging Face token (write access, ai-coustics org). `huggingface_hub` reads `HF_TOKEN` automatically once the env is sourced. `HF_API_KEY` is dead — if you see it referenced anywhere, it's stale.

To verify they are loaded:
```bash
echo $R2_ACCOUNT_ID
```

If they are empty, source manually:
```bash
source ~/.env
```

## GitHub Access

Auth is token-based: `GH_TOKEN` (a fine-grained PAT) is in `~/.env`, sourced in every shell. There are **no SSH keys on this VM** — always clone over HTTPS (`https://github.com/...`), never `git@github.com:...`. The `gh` CLI picks up `GH_TOKEN` automatically, and git's HTTPS credentials are routed through `gh` (configured via `gh auth setup-git` at VM setup), so plain `git push`/`git pull` work on HTTPS clones.

To verify:
```bash
gh auth status
```

The token is scoped to selected repos — if a clone/push fails with 403/404 on a repo you can see on github.com, the token likely doesn't cover that repo; tell the user rather than retrying.

## Shared Memory

Your `~/.claude/` directory is mounted from the R2 bucket `joschkas-clowd/claude-memory/`. All memory files (`.md`) you write there are shared across all Claude instances and persist after this VM shuts down.

## Installed Tools

- `uv` — fast Python package manager (`~/.local/bin/uv`)
- `gh` — GitHub CLI for PRs and issues
- `rclone` — R2/S3 file sync
- `claude` — Claude Code CLI (`~/.claude/local/claude`)

## Working Directory

Always store files on the VM — cloned repositories, downloaded assets, processed outputs, temporary files — in `~/sky_workdir/`. This is the default working directory for the Sky Claude instance and is the expected location for all work artifacts.

```bash
cd ~/sky_workdir
```

## Shared Data Bucket

The R2 bucket `joschkas-clowd` is mounted read-write at `/bucket_data`.

## Code Execution Service

A FastAPI service runs on port 8080 serving code execution via MCP. It is started automatically by SkyPilot.

---

## Preflight checks

This file is auto-loaded by Claude Code when launched from `~/sky_workdir/`. Before starting work, run these checks and report any failures:

1. `gh auth status` — confirm GitHub token auth (uses `GH_TOKEN` from `~/.env`)
2. `echo $R2_ACCOUNT_ID` — confirm env vars are loaded
3. `aws sts get-caller-identity` — if it fails, run `aws sso login --profile=default`

Then ask the user what they'd like to work on.

## Code Quality

Before considering any task done, you MUST run the following checks and fix all errors:

```sh
uv run ruff check --fix . && uv run ruff format .
uv run ruff check .
uv run mypy .
```

No task is complete while any of these commands report errors.

The project uses [pre-commit](../.pre-commit-config.yaml) to enforce code quality on every commit (ruff format, ruff lint, mypy, uv-sort, uv-lock). It runs automatically during `git commit`.
