#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ROOTFS_DIR="${1:-}"
STOCK_KERNEL_ROOT="$ROOT_DIR/artifacts/vendor/rk2020-stock"
MODULES_SRC="$STOCK_KERNEL_ROOT/kernel/extracted/lib/modules"
FIRMWARE_SRC="$STOCK_KERNEL_ROOT/kernel/extracted/lib/firmware"
MALI_SRC="$STOCK_KERNEL_ROOT/runtime/libmali.so"

[ -d "$ROOTFS_DIR" ] || {
    printf 'usage: %s ROOTFS_DIR\n' "$0" >&2
    exit 2
}
[ -f "$STOCK_KERNEL_ROOT/boot/KERNEL" ] && \
    [ -f "$STOCK_KERNEL_ROOT/boot/rk3326-odroidgo2-linux.dtb" ] && \
    [ -d "$MODULES_SRC" ] || {
    printf 'error: captured RK2020 stock kernel artifacts missing; run ./scripts/capture-rk2020-stock-over-ssh.sh first\n' >&2
    exit 2
}
[ -d "$FIRMWARE_SRC" ] || {
    printf 'error: captured stock firmware missing; run ./scripts/capture-rk2020-stock-over-ssh.sh first\n' >&2
    exit 2
}
[ -f "$MALI_SRC" ] || {
    printf 'error: captured stock Mali userspace driver missing; run ./scripts/capture-rk2020-stock-over-ssh.sh first\n' >&2
    exit 2
}

mapfile -t releases < <(find "$MODULES_SRC" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
[ "${#releases[@]}" -eq 1 ] || {
    printf 'error: expected exactly one kernel module release\n' >&2
    exit 2
}
release=${releases[0]}
case "$release" in
    4.4.189) ;;
    *) printf 'error: unexpected kernel module ABI: %s\n' "$release" >&2; exit 2 ;;
esac

mkdir -p "$ROOTFS_DIR/lib/modules" "$ROOTFS_DIR/lib/firmware"
cp -a "$MODULES_SRC/$release" "$ROOTFS_DIR/lib/modules/"
cp -a "$FIRMWARE_SRC/." "$ROOTFS_DIR/lib/firmware/"

install -m 0644 "$MALI_SRC" "$ROOTFS_DIR/usr/lib/libmali.so"
for library in \
    libEGL.so libEGL.so.1 \
    libGLES_CM.so.1 libGLESv1_CM.so.1 \
    libGLESv2.so libGLESv2.so.2 \
    libGLESv3.so libGLESv3.so.3 \
    libgbm.so libgbm.so.1; do
    rm -f "$ROOTFS_DIR/usr/lib/$library"
    ln -s libmali.so "$ROOTFS_DIR/usr/lib/$library"
done

depmod -b "$ROOTFS_DIR" "$release"

MANIFEST="$ROOTFS_DIR/usr/lib/plumos/kernel-runtime.sha256"
(
    cd "$ROOTFS_DIR"
    find "lib/modules/$release" lib/firmware usr/lib/libmali.so -type f -print0 | \
        LC_ALL=C sort -z | xargs -0 sha256sum
) >"$MANIFEST"
printf 'kernel-runtime=result-ok release=%s firmware_source=stock-kernel-overlay gpu_userspace=stock-libmali boot_substrate=stock\n' \
    "$release"
