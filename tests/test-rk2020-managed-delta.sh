#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
VERIFY="$ROOT_DIR/scripts/verify-rk2020-managed-delta.sh"
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/rk2020-managed-delta.XXXXXX")"
trap 'find "$FIXTURE" -depth -delete' EXIT

mkdir -p \
    "$FIXTURE/components/demo" \
    "$FIXTURE/licenses/component-manifests" \
    "$FIXTURE/payload"
printf '%s\n' '{"source_ref":"test"}' >"$FIXTURE/components/demo/manifest.json"
cp "$FIXTURE/components/demo/manifest.json" \
    "$FIXTURE/licenses/component-manifests/demo.json"
printf '%s\n' managed >"$FIXTURE/payload/changed.bin"
printf '%s\n' deliberately-unchecked >"$FIXTURE/payload/unrelated.bin"

(
    cd "$FIXTURE"
    sha256sum components/demo/manifest.json payload/changed.bin \
        >components/demo/checksums.sha256
    sha256sum components/demo/checksums.sha256 \
        components/demo/manifest.json \
        licenses/component-manifests/demo.json \
        payload/changed.bin payload/unrelated.bin >checksums.sha256
)

printf '%s\n' changed-without-delta-scope >"$FIXTURE/payload/unrelated.bin"
"$VERIFY" "$FIXTURE" demo \
    payload/changed.bin \
    components/demo/manifest.json \
    licenses/component-manifests/demo.json \
    checksums.sha256

printf '%s\n' broken >"$FIXTURE/payload/changed.bin"
if "$VERIFY" "$FIXTURE" demo payload/changed.bin >/dev/null 2>&1; then
    printf 'FAIL: changed managed payload was not rejected\n' >&2
    exit 1
fi

printf 'PASS: RK2020 managed delta verifier\n'
