#!/usr/bin/env bash
set -euo pipefail

echo "=== WHOAMI CHECK ==="
echo "User:      $(whoami)"
echo "ID:        $(id)"
echo "Host:      $(hostname 2>/dev/null || uname -n)"
echo "Shell:     ${SHELL:-unknown}"
echo "Home:      ${HOME:-unknown}"
echo "CWD:       $(pwd)"
echo "OS/Kernel: $(uname -srm)"
