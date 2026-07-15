#!/usr/bin/env bash
# Launch the VM with a hardware profile:
#   ./launch.sh claude   Mac-class box for Claude Code (~M4 Pro)       (c8i.4xlarge, 16 vCPU/32 GB, ~$0.75/h)
#   ./launch.sh data     many CPUs + high network for data engineering (any_of list in run.yaml)
#   ./launch.sh gpu      A10G for whisper/parakeet etc.                (g5.xlarge,   ~$1.01/h)
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
  claude) OVERRIDES=(--instance-type c8i.4xlarge) ;;
  data)   OVERRIDES=() ;;  # uses the any_of list in run.yaml
  # NOTE: no custom --image-id here. SkyPilot's default AWS GPU image is
  # Ubuntu-based with NVIDIA drivers; the once-suggested DLAMI
  # ami-0f4d5ef8f66860703 is Amazon Linux 2023, which breaks the apt-based
  # setup script in run.yaml (no claude, no ~/.claude, nothing).
  gpu)    OVERRIDES=(--instance-type g5.xlarge --gpus A10G:1) ;;
  *) echo "usage: $0 {claude|data|gpu} [extra sky launch args]" >&2; exit 1 ;;
esac

exec sky launch -c "$CLUSTER" src/run.yaml "${OVERRIDES[@]}" "$@"
