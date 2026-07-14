#!/usr/bin/env bash
# Launch the VM with a hardware profile:
#   ./launch.sh claude   cheap box, enough for Claude Code + the API   (m6i.large,  ~$0.10/h)
#   ./launch.sh data     many CPUs + high network for data engineering (any_of list in run.yaml)
#   ./launch.sh gpu      A10G for whisper/parakeet etc.                (g5.xlarge,  ~$1.01/h)
#
# Extra args are passed through to `sky launch` (e.g. -y, --use-spot).
# Cluster name defaults to joschkas-clowd; override with CLUSTER=<name>.
#
# NOTE: switching profile means switching hardware — `sky down $CLUSTER` first
# (or launch under a different CLUSTER name). All state that matters lives in
# R2 (~/.claude, /bucket_data); ~/sky_workdir is ephemeral anyway.
set -euo pipefail

PROFILE=${1:-}
[ $# -gt 0 ] && shift
CLUSTER=${CLUSTER:-joschkas-clowd}

case "$PROFILE" in
  claude) OVERRIDES=(--instance-type m6i.large) ;;
  data)   OVERRIDES=() ;;  # uses the any_of list in run.yaml
  gpu)    OVERRIDES=(--instance-type g5.xlarge --gpus A10G:1 --image-id ami-0f4d5ef8f66860703) ;;
  *) echo "usage: $0 {claude|data|gpu} [extra sky launch args]" >&2; exit 1 ;;
esac

: "${AUTH_TOKEN:?export AUTH_TOKEN first (any random string)}"

exec uv run sky launch -c "$CLUSTER" src/run.yaml "${OVERRIDES[@]}" \
  --env AUTH_TOKEN="$AUTH_TOKEN" \
  --env WANDB_API_KEY="${WANDB_API_KEY:-}" \
  --env HF_TOKEN_WRITE="${HF_TOKEN_WRITE:-}" \
  "$@"
