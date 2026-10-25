#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
capture=${1:-$root_dir/artifacts/vendor/rk2020-stock}
expected=$root_dir/configs/rk2020-stock.expected.sha256
system_expected=$root_dir/configs/rk2020-stock-system.expected.sha256
manifest=$capture/manifest.tsv

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

while read -r wanted relative; do
    [ -n "$wanted" ] || continue
    path=$capture/$relative
    [ -f "$path" ] || {
        printf 'error: captured artifact missing: %s\n' "$relative" >&2
        exit 2
    }
    actual=$(sha256_file "$path")
    [ "$actual" = "$wanted" ] || {
        printf 'error: captured artifact mismatch: %s\n' "$relative" >&2
        exit 2
    }
done <"$expected"

[ "$(stat -f '%z' "$capture/rockchip-boot-prefix.bin" 2>/dev/null || \
    stat -c '%s' "$capture/rockchip-boot-prefix.bin")" -eq 16777216 ]
[ -d "$capture/kernel/extracted/lib/modules/4.4.189" ]
[ -f "$capture/kernel/extracted/lib/modules/4.4.189/kernel/drivers/net/wireless/rtl8821cu/8821cu.ko" ]
[ -d "$capture/kernel/extracted/lib/firmware" ]
[ -f "$capture/runtime/stock-system.sha256" ]
[ "$(sed -n '1p' "$capture/runtime/stock-system.sha256")" = \
    "$(sed -n '1p' "$system_expected")" ]
[ ! -e "$capture/SYSTEM" ]
[ -f "$manifest" ]
grep -q $'^stock_system_policy\tanalysis-only-not-copied$' "$manifest"

files=0
while IFS=$'\t' read -r kind relative size wanted; do
    [ "$kind" = file ] || continue
    path=$capture/$relative
    [ -f "$path" ]
    [ "$(stat -f '%z' "$path" 2>/dev/null || stat -c '%s' "$path")" = "$size" ]
    [ "$(sha256_file "$path")" = "$wanted" ]
    files=$((files + 1))
done <"$manifest"
[ "$files" -gt 800 ] || {
    printf 'error: incomplete RK2020 vendor capture: files=%s\n' "$files" >&2
    exit 2
}

printf 'rk2020_vendor_capture=result-ok files=%s kernel=4.4.189 system=analysis-only\n' "$files"
