#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
image=${PLUMOS_RK2020_TOOLS_IMAGE:-plumos-rk2020-tools:dev}
if [ "${1:-}" != --inside ]; then
    exec docker run --rm --platform linux/arm64 \
        -v "$repo_root:/work" -w /work "$image" \
        ./tests/test-rk2020-picoarch-launch.sh --inside
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
root=$tmp/plumos
user_root=$tmp/user
runtime=$tmp/run
mkdir -p "$root/bin" "$root/picoarch/bin" "$root/picoarch/lib" \
    "$root/cores" "$root/share/picoarch" "$user_root/bios" "$runtime"
cp package/picoarch-rk2020/plumos/bin/plumos-picoarch-launch \
    "$root/bin/plumos-picoarch-launch"
cp package/picoarch-rk2020/plumos/share/picoarch/rgb565-byte-order.tsv \
    "$root/share/picoarch/rgb565-byte-order.tsv"
cp package/picoarch-rk2020/plumos/share/picoarch/rgb565-route-overrides.tsv \
    "$root/share/picoarch/rgb565-route-overrides.tsv"
: >"$root/cores/picodrive_libretro.so"
for library in libSDL-1.2.so.0 libSDL2-2.0.so.0 libpng16.so.16 libz.so.1; do
    : >"$root/picoarch/lib/$library"
done

cat >"$root/bin/plumos-audio-output" <<'EOF'
#!/bin/sh
printf '%s\n' 'result=ok'
EOF
cat >"$root/picoarch/bin/picoarch" <<'EOF'
#!/bin/sh
set -eu
: "${TEST_TRACE:?}"
printf '%s\n' "${PLUMOS_PICOARCH_RGB565_BYTESWAP:-unset}" >"$TEST_TRACE.rgb565"
exit 0
EOF
chmod 0755 "$root/bin/plumos-picoarch-launch" \
    "$root/bin/plumos-audio-output" "$root/picoarch/bin/picoarch"

run_route() {
    system_id=$1
    expected_order=$2
    expected_swap=$3
    evidence=$4
    rom="$tmp/$system_id.rom"
    trace="$tmp/$system_id"
    : >"$rom"
    TEST_TRACE=$trace PLUMOS_ROOT=$root PLUMOS_USER_ROOT=$user_root \
    PLUMOS_RUNTIME_ROOT=$runtime PLUMOS_PICOARCH_SYSTEM=$system_id \
        "$root/bin/plumos-picoarch-launch" picodrive "$rom"
    test "$(cat "$trace.rgb565")" = "$expected_swap"
    grep -Fq "pixel_format=rgb565 byte_order=$expected_order classification_scope=system-override evidence=$evidence" \
        "$root/logs/picoarch/$system_id-picodrive.log"
}

run_route megadrive byteswap 1 rk2020-physical-bare-knuckle
run_route mastersystem native 0 bubble-wonder-boy-iii-180f
run_route gamegear byteswap 1 bubble-pengo-180f
run_route sega32x byteswap 1 rk2020-physical-bc-racers
run_route segacd native 0 bubble-fatal-fury-special-300f

# A malformed table must stop the launch rather than silently falling back to
# the core-wide default. This also exercises the duplicate-row failure path.
cat >>"$root/share/picoarch/rgb565-route-overrides.tsv" <<'EOF'
sega32x	picodrive	rgb565	native	frontend	invalid-duplicate
EOF
: >"$tmp/duplicate.rom"
set +e
TEST_TRACE=$tmp/duplicate PLUMOS_ROOT=$root PLUMOS_USER_ROOT=$user_root \
PLUMOS_RUNTIME_ROOT=$runtime PLUMOS_PICOARCH_SYSTEM=sega32x \
    "$root/bin/plumos-picoarch-launch" picodrive "$tmp/duplicate.rom" \
    >"$tmp/duplicate.stdout" 2>"$tmp/duplicate.stderr"
duplicate_rc=$?
set -e
test "$duplicate_rc" -eq 1
test ! -e "$tmp/duplicate.rgb565"
grep -Fq 'invalid RGB565 route classification table: sega32x/picodrive' \
    "$tmp/duplicate.stderr"

printf '%s\n' 'rk2020_picoarch_launcher_test=result-ok routes=5 busybox_awk=ok malformed_table=rejected'
