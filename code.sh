#!/usr/bin/env bash
# Open VSCode connected to the VM, directly in ~/sky_workdir — no manual
# "Open Folder" navigation. Requires the Remote-SSH extension and a running
# cluster (SkyPilot maintains the SSH host alias).
# Usage: ./code.sh [cluster]   (default: joschkas-clowd)
set -euo pipefail

CLUSTER=${1:-joschkas-clowd}
exec code --remote "ssh-remote+${CLUSTER}" /home/ubuntu/sky_workdir
