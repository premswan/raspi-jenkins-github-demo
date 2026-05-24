#!/usr/bin/env bash
set -euo pipefail
RASPI_HOST="${1:-192.168.1.2}"
RASPI_USER="${2:-pi}"
SSH_KEY="${3:-$HOME/.ssh/jenkins_raspi}"

echo "Checking ping to ${RASPI_HOST}"
ping -c 3 "${RASPI_HOST}"

echo "Checking SSH command execution"
ssh -i "${SSH_KEY}" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${RASPI_USER}@${RASPI_HOST}" 'hostname; uname -a; df -h /; free -m; python3 --version'
