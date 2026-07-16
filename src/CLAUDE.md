# VM Environment Guide for Claude

You are running on an AWS EC2 instance managed by SkyPilot. This file tells you everything you need to know to get started.

## Environment Variables

All secrets and config are in `~/.env`, sourced automatically in every shell session.

Available variables:
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT` — Cloudflare R2 storage credentials
- `AIC_SDK_LICENSE`, `AIC_LICENSE_KEY` — ai-coustics SDK license
- `HF_TOKEN` — Hugging Face token (write access, ai-coustics org). This is the canonical and only HF variable; `huggingface_hub` reads it automatically once the env is sourced. `HF_API_KEY` and `HF_TOKEN_WRITE` are retired aliases — if you see them referenced anywhere, it's stale; use `HF_TOKEN`.

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

## Preflight checks

This file is auto-loaded by Claude Code when launched from `~/sky_workdir/`. Before starting work, run these checks and report any failures:

1. `gh auth status` — confirm GitHub token auth (uses `GH_TOKEN` from `~/.env`)
2. `echo $R2_ACCOUNT_ID` — confirm env vars are loaded
3. `aws sts get-caller-identity` — if it fails, run `aws sso login --profile=default`

Then ask the user what they'd like to work on.

## Git: prefer rebase over merge

When integrating upstream changes (e.g. bringing `main` into a feature branch), always use `git rebase`, never `git merge`. This applies whether the user asks to "merge in main", "sync with main", "update from main", or similar — interpret these as rebase requests. When a rebase has conflicts, resolve them, `git add`, and `git rebase --continue` — do NOT abort and fall back to `git merge`.

Rationale: keeps branch history linear and the eventual squash-merge clean; `git log --oneline main..HEAD` keeps showing only this branch's actual work.

## File naming: think globally, not just locally

When creating new files (reports, analyses, scripts, plots), pick a name that's clear *outside* the current task — filenames travel into PR descriptions, memory entries, grep results, and R2 buckets long after the parent directory's context is gone.

- Avoid generic names like `REPORT.md`, `findings.md`, `output.csv`, `script.py` even when the directory makes them locally unambiguous.
- Encode the *topic* in the name, not just the file's role: `silero_vad_calibration.py` beats `calibrate.py`; `wer_el_sweep_dawn_chorus.png` beats `plot.png`.
- Before settling on a name, ask: "if I saw only this filename in a search result a year from now, would I know what it is?" If not, rename.

## Code Quality

Before considering any task done, you MUST run the following checks and fix all errors:

```sh
uv run ruff check --fix . && uv run ruff format .
uv run ruff check .
uv run mypy .
```

No task is complete while any of these commands report errors.

The project uses [pre-commit](../.pre-commit-config.yaml) to enforce code quality on every commit (ruff format, ruff lint, mypy, uv-sort, uv-lock). It runs automatically during `git commit`.
