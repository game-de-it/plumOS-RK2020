#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
capture=${1:-$root_dir/artifacts/vendor/rk2020-stock}
manifest=$capture/manifest.tsv

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

[ -d "$capture" ] || {
    printf 'error: capture root missing: %s\n' "$capture" >&2
    exit 2
}
[ ! -e "$capture/SYSTEM" ] || {
    printf 'error: stock SYSTEM must remain analysis-only\n' >&2
    exit 2
}
[ -f "$capture/runtime/stock-system.sha256" ]

source_ref=$(git -C "$root_dir" rev-parse --short HEAD 2>/dev/null || printf unknown)
{
    printf 'format\tplumos-rk2020-stock-v1\n'
    printf 'device\trk2020\n'
    printf 'architecture\taarch64\n'
    printf 'kernel_release\t4.4.189\n'
    printf 'source_ref\t%s\n' "$source_ref"
    printf 'stock_system_policy\tanalysis-only-not-copied\n'
    find "$capture" -type f ! -name manifest.tsv -print | LC_ALL=C sort | \
        while IFS= read -r path; do
            relative=${path#"$capture"/}
            size=$(stat -f '%z' "$path" 2>/dev/null || stat -c '%s' "$path")
            printf 'file\t%s\t%s\t%s\n' "$relative" "$size" "$(sha256_file "$path")"
        done
} >"$manifest"

printf 'rk2020_stock_register=result-ok manifest=%s\n' "$manifest"
