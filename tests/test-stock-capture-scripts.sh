#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

for script in \
    scripts/capture-rk2020-stock-over-ssh.sh \
    scripts/register-rk2020-stock-artifacts.sh \
    scripts/verify-rk2020-stock-artifacts.sh \
    scripts/capture-stock-boot-artifacts.sh \
    scripts/verify-stock-boot-artifacts.sh; do
    bash -n "$ROOT_DIR/$script"
done

capture="$ROOT_DIR/scripts/capture-rk2020-stock-over-ssh.sh"
grep -q 'Hardkernel ODROID-GO2' "$capture"
grep -q 'ro,' "$capture"
grep -q 'bs=1048576 count=16' "$capture"
grep -q '/usr/lib/kernel-overlays/base' "$capture"
grep -q '/usr/lib/libmali.so' "$capture"
grep -q 'stock-system.sha256' "$capture"
! grep -Eq '(cat|cp|dd).*SYSTEM[^.]' "$capture"
grep -q 'exec.*capture-rk2020-stock-over-ssh.sh' \
    "$ROOT_DIR/scripts/capture-stock-boot-artifacts.sh"
grep -q 'exec.*verify-rk2020-stock-artifacts.sh' \
    "$ROOT_DIR/scripts/verify-stock-boot-artifacts.sh"
grep -q 'runtime/libmali.so' "$ROOT_DIR/configs/rk2020-stock.expected.sha256"

if [ -d "$ROOT_DIR/artifacts/vendor/rk2020-stock" ]; then
    "$ROOT_DIR/scripts/verify-rk2020-stock-artifacts.sh" \
        "$ROOT_DIR/artifacts/vendor/rk2020-stock"
fi

printf 'stock_capture_scripts=result-ok\n'
