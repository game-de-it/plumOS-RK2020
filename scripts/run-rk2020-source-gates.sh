#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

git diff --check

shell_tests=(
    tests/test-app-layer-scripts.sh
    tests/test-system-rootfs-scripts.sh
    tests/test-sd-image-scripts.sh
    tests/test-stock-capture-scripts.sh
    tests/test-implementation-audit.sh
    tests/test-rk2020-emulator-menu-contract.sh
    tests/test-rk2020-picoarch-rgb565-matrix.sh
    tests/test-rk2020-pico8-wget.sh
    tests/test-rk2020-gw-core-geometry.sh
    tests/test-rk2020-license-bundle.sh
    tests/test-rk2020-release-content.sh
    tests/test-rk2020-release-bundle.sh
)

for test_script in "${shell_tests[@]}"; do
    printf 'source-gate: RUN %s\n' "$test_script"
    "$ROOT_DIR/$test_script"
done

python3 "$ROOT_DIR/tests/test_pyxel_rk2020_geometry.py"
python3 -m py_compile \
    "$ROOT_DIR/scripts/audit-rk2020-implementation.py" \
    "$ROOT_DIR/scripts/audit-rk2020-release-content.py" \
    "$ROOT_DIR/scripts/build-rk2020-audit-fixture.py" \
    "$ROOT_DIR/scripts/build-rk2020-release-bundle.py" \
    "$ROOT_DIR/scripts/verify-rk2020-release-bundle.py"

printf 'rk2020_source_gates=result-ok tests=%s\n' "$(( ${#shell_tests[@]} + 1 ))"
