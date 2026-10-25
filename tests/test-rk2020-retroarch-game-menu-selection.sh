#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

docker run --rm --platform linux/arm64 \
    -v "$ROOT_DIR:/work:ro" busybox:latest sh -euc '
root=/tmp/plumos
user=/tmp/plumos-user
mkdir -p "$root/bin" "$root/cores" "$root/config/retroarch" \
    "$root/factory-defaults/retroarch" "$user/roms/nes"
touch "$root/cores/quicknes_libretro.so" \
    "$root/cores/flycast_libretro.so" "$user/roms/nes/game.nes"

cat >"$root/bin/retroarch" <<"EOF"
#!/bin/sh
append=
: >"$PLUMOS_TEST_ARGS"
while [ "$#" -gt 0 ]; do
    printf "%s\n" "$1" >>"$PLUMOS_TEST_ARGS"
    case "$1" in
        --appendconfig) append=$2; shift 2 ;;
        *) shift ;;
    esac
done
cp "$append" "$PLUMOS_TEST_APPEND"
printf "%s\n" "${PLUMOS_GL_MENU_ROTATION:-unset}" >"$PLUMOS_TEST_ROTATION"
EOF
chmod 0755 "$root/bin/retroarch"

run_case() {
    name=$1
    menu=$2
    core=$3
    expected_video=$4
    expected_rotation=$5
    printf "menu_driver = \"%s\"\n" "$menu" >"$root/config/retroarch/retroarch.cfg"
    cp "$root/config/retroarch/retroarch.cfg" \
        "$root/factory-defaults/retroarch/retroarch.cfg"
    PLUMOS_ROOT=$root \
    PLUMOS_ROM_ROOT=$user/roms \
    PLUMOS_SDCARD_ROOT=$user \
    PLUMOS_RUNTIME_ROOT=/tmp/run-$name \
    PLUMOS_TEST_APPEND=/tmp/$name-append.cfg \
    PLUMOS_TEST_ROTATION=/tmp/$name-rotation \
    PLUMOS_TEST_ARGS=/tmp/$name-args \
        /work/package/app-layer-rk2020/bin/plumos-retroarch-launch \
            --system nes --core "$root/cores/$core" \
            --rom "$user/roms/nes/game.nes"
    grep -q "^video_driver = \"$expected_video\"$" /tmp/$name-append.cfg
    [ "$(cat /tmp/$name-rotation)" = "$expected_rotation" ]
}

run_case rgui rgui quicknes_libretro.so drm unset
run_case ozone ozone quicknes_libretro.so gl display
run_case xmb xmb quicknes_libretro.so gl display
run_case glui glui quicknes_libretro.so gl display
run_case hw-rgui rgui flycast_libretro.so gl content
run_case hw-ozone ozone flycast_libretro.so gl display

mkdir -p "$user/.plumos-validation/matrix"
PLUMOS_ROOT=$root \
PLUMOS_ROM_ROOT=$user/roms \
PLUMOS_SDCARD_ROOT=$user \
PLUMOS_RUNTIME_ROOT=/tmp/run-validation \
PLUMOS_TEST_APPEND=/tmp/validation-append.cfg \
PLUMOS_TEST_ROTATION=/tmp/validation-rotation \
PLUMOS_TEST_ARGS=/tmp/validation-args \
PLUMOS_RETROARCH_VALIDATION_MAX_FRAMES=120 \
PLUMOS_RETROARCH_VALIDATION_SCREENSHOT="$user/.plumos-validation/matrix/nes.png" \
    /work/package/app-layer-rk2020/bin/plumos-retroarch-launch \
        --system nes --core "$root/cores/quicknes_libretro.so" \
        --rom "$user/roms/nes/game.nes"
grep -Fqx -- "--max-frames=120" /tmp/validation-args
grep -Fqx -- "--max-frames-ss" /tmp/validation-args
grep -Fqx -- "--max-frames-ss-path=$user/.plumos-validation/matrix/nes.png" \
    /tmp/validation-args

if PLUMOS_ROOT=$root \
    PLUMOS_ROM_ROOT=$user/roms \
    PLUMOS_SDCARD_ROOT=$user \
    PLUMOS_RUNTIME_ROOT=/tmp/run-invalid-validation \
    PLUMOS_TEST_APPEND=/tmp/invalid-validation-append.cfg \
    PLUMOS_TEST_ROTATION=/tmp/invalid-validation-rotation \
    PLUMOS_TEST_ARGS=/tmp/invalid-validation-args \
    PLUMOS_RETROARCH_VALIDATION_MAX_FRAMES=120 \
    PLUMOS_RETROARCH_VALIDATION_SCREENSHOT=/tmp/outside.png \
        /work/package/app-layer-rk2020/bin/plumos-retroarch-launch \
            --system nes --core "$root/cores/quicknes_libretro.so" \
            --rom "$user/roms/nes/game.nes" >/dev/null 2>&1; then
    printf "outside validation screenshot path was accepted\n" >&2
    exit 1
fi
'

printf 'test-rk2020-retroarch-game-menu-selection: PASS\n'
