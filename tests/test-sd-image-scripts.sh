#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
bash -n "$ROOT_DIR/scripts/build-sd-image.sh"
bash -n "$ROOT_DIR/scripts/verify-sd-image.sh"
bash -n "$ROOT_DIR/rootfs/rk2020/usr/sbin/plumos-first-boot-provision"
bash -n "$ROOT_DIR/tests/test-rk2020-first-boot-provision.sh"
python3 "$ROOT_DIR/scripts/verify-rk2020-boot-splash.py" \
    "$ROOT_DIR/package/boot-assets-rk2020/oemsplash-1080.png"
grep -q 'BOOT_START=32768' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'refusing\|boot prefix missing' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'cmp.*image-prefix' "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q 'rk2020-stock.expected.sha256' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'PLUMOS_SYS' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'normalize_ext4_timestamps' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'TOTAL_SECTORS=5275648' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'plumos-user-absent' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'test-rk2020-first-boot-provision.sh' "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q 'set_inode_field' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'faketime.*debugfs' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'faketime -f.*x0.*debugfs' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'verify-app-layer.sh' "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q 'STOCK_BOOT_DIR/KERNEL' \
    "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q 'rk3326-odroidgo2-linux.dtb' \
    "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q 'runtime_dtb_policy=exact-stock' \
    "$ROOT_DIR/scripts/build-sd-image.sh"
! grep -q 'build-rk2020-boot-dtb' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'STOCK_BOOT_DIR' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'boot_substrate=stock-rk2020' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'post-sysroot.sh' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'stock_initramfs_hooks' "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q 'oemsplash-1080.png' "$ROOT_DIR/scripts/build-sd-image.sh"
grep -q 'verify-rk2020-boot-splash.py' "$ROOT_DIR/scripts/verify-sd-image.sh"
grep -q '/usr/bin/splash-image /flash/oemsplash-1080.png' \
    "$ROOT_DIR/boot-hooks/rk2020/post-flash.sh"
grep -q 'boot-splash result=plumos' \
    "$ROOT_DIR/boot-hooks/rk2020/post-flash.sh"
printf 'sd_image_scripts=result-ok\n'
