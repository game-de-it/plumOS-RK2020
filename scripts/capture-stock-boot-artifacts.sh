#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
printf '%s\n' \
    'note: capture-stock-boot-artifacts.sh is a compatibility entry point;' \
    'using the RK2020 read-only SSH capture.' >&2
exec "$root_dir/scripts/capture-rk2020-stock-over-ssh.sh" "$@"
