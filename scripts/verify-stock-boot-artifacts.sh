#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
exec "$root_dir/scripts/verify-rk2020-stock-artifacts.sh" "$@"
