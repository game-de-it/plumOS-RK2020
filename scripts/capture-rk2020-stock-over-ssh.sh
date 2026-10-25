#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
target=${PLUMOS_RK2020_SSH_TARGET:-root@192.168.10.107}
password=${PLUMOS_RK2020_SSH_PASSWORD:-}
out=${PLUMOS_RK2020_VENDOR_OUT:-$root_dir/artifacts/vendor/rk2020-stock}
incoming=$out.incoming
expected=$root_dir/configs/rk2020-stock.expected.sha256
system_expected=$root_dir/configs/rk2020-stock-system.expected.sha256
known_hosts=$(mktemp)
trap 'rm -f "$known_hosts"' EXIT

ssh_opts=(
    -o ConnectTimeout=8
    -o NumberOfPasswordPrompts=1
    -o PreferredAuthentications=password,keyboard-interactive
    -o PubkeyAuthentication=no
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile="$known_hosts"
)

remote() {
    if [ -n "$password" ]; then
        SSHPASS=$password sshpass -e ssh "${ssh_opts[@]}" "$target" "$@"
    else
        ssh "${ssh_opts[@]}" "$target" "$@"
    fi
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

[ -f "$expected" ] || {
    printf 'error: expected-hash registry missing: %s\n' "$expected" >&2
    exit 2
}
[ ! -e "$out" ] && [ ! -e "$incoming" ] || {
    printf 'error: refusing to overwrite an existing capture: %s\n' "$out" >&2
    exit 2
}

identity=$(remote '
    printf "%s|" "$(uname -r)"
    sed -n "s/^ID=//p" /etc/os-release | tr -d "\"\n"
    printf "|"
    tr -d "\000" </sys/firmware/devicetree/base/model
    printf "|"
    awk '\''$2 == "/flash" { printf "%s", $4 }'\'' /proc/mounts
')
case "$identity" in
    '4.4.189|emuelec|Hardkernel ODROID-GO2|ro,'*) ;;
    *) printf 'error: unexpected RK2020 stock identity: %q\n' "$identity" >&2; exit 2 ;;
esac

mkdir -p "$incoming/boot" "$incoming/kernel/extracted" "$incoming/runtime"

remote '
    flash_source=$(awk '\''$2 == "/flash" { print $1 }'\'' /proc/mounts)
    case "$flash_source" in
        /dev/mmcblk*p1) stock_disk=${flash_source%p1} ;;
        *) exit 2 ;;
    esac
    dd if="$stock_disk" bs=1048576 count=16 2>/dev/null
' >"$incoming/rockchip-boot-prefix.bin"

remote '
    cd /flash
    tar -cf - KERNEL boot.ini rk3326-odroidgo2-linux.dtb extlinux
' | tar -C "$incoming/boot" -xf -

remote 'cat /sys/firmware/fdt' >"$incoming/runtime/active.dtb"
remote '
    tar -C /usr/lib/kernel-overlays/base -czf - lib/modules lib/firmware
' >"$incoming/kernel/runtime.tar.gz"
tar -C "$incoming/kernel/extracted" -xzf "$incoming/kernel/runtime.tar.gz"

remote 'sha256sum /flash/SYSTEM' | awk '{print $1 "  SYSTEM-analysis-only"}' \
    >"$incoming/runtime/stock-system.sha256"
remote 'sed -n "1p" /flash/SYSTEM.md5' \
    >"$incoming/runtime/stock-system.md5"
cmp "$system_expected" "$incoming/runtime/stock-system.sha256"

while read -r wanted relative; do
    [ -n "$wanted" ] || continue
    path=$incoming/$relative
    [ -f "$path" ] || {
        printf 'error: captured artifact missing: %s\n' "$relative" >&2
        exit 2
    }
    actual=$(sha256_file "$path")
    [ "$actual" = "$wanted" ] || {
        printf 'error: stock hash mismatch: %s\nexpected=%s\nactual=%s\n' \
            "$relative" "$wanted" "$actual" >&2
        exit 2
    }
done <"$expected"

"$root_dir/scripts/register-rk2020-stock-artifacts.sh" "$incoming"
mv "$incoming" "$out"
"$root_dir/scripts/verify-rk2020-stock-artifacts.sh" "$out"
printf 'rk2020_stock_capture=result-ok target=%s output=%s\n' "$target" "$out"
