# VM Environment Guide for Claude

You are running on an AWS EC2 instance managed by SkyPilot. This file tells you everything you need to know to get started.

## Environment Variables

All secrets and config are in `~/.env`, sourced automatically in every shell session.

Available variables:
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT` — Cloudflare R2 storage credentials
- `AIC_SDK_LICENSE`, `AIC_LICENSE_KEY` — ai-coustics SDK license
- `HF_API_KEY` — Hugging Face API key

To verify they are loaded:
```bash
echo $R2_ACCOUNT_ID
```

If they are empty, source manually:
```bash
source ~/.env
```

## GitHub Access

Your SSH key is at `~/.ssh/id_rsa` and has access to private GitHub repositories.

Git is configured to use it automatically. To verify:
```bash
ssh -T git@github.com
```

For creating pull requests, `gh` CLI is installed. Authenticate once with:
```bash
gh auth login
```
Choose "GitHub.com" → "SSH" → use existing key at `~/.ssh/id_rsa`.

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

1. `ssh -T git@github.com` — confirm GitHub SSH access
2. `echo $R2_ACCOUNT_ID` — confirm env vars are loaded
3. `gh auth status` — if not authenticated, run `gh auth login` (GitHub.com → SSH → existing key)
4. `aws sts get-caller-identity` — if it fails, run `aws sso login --profile=default`

Then ask the user what they'd like to work on.
