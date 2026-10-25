#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONTROL="$ROOT_DIR/package/app-layer-rk2020/bin/plumos-volume-control"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/plumos-volume-test.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT

export PLUMOS_ROOT="$TASK_TMP/plumos"
export PLUMOS_SYSTEM_SETTINGS_JSON="$TASK_TMP/plumos/config/system/settings.json"
export PLUMOS_VOLUME_RUNTIME_STATE="$TASK_TMP/run/volume/current"
export PLUMOS_SPEAKER_BOOST_RUNTIME_STATE="$TASK_TMP/run/volume/speaker-boost-step"
export PLUMOS_SPEAKER_BOOST_SAVED_STATE="$TASK_TMP/plumos/config/system/speaker-boost-step"
export PLUMOS_VOLUME_LOG="$TASK_TMP/run/volume/last-apply.log"
export PLUMOS_RK817_CARD_ID_PATH="$TASK_TMP/proc/asound/card0/id"
export PLUMOS_RK817_MIXER_HELPER="$TASK_TMP/bin/plumos-rk817-resume"
export PLUMOS_TEST_MIXER_CALLS="$TASK_TMP/run/mixer-calls"

mkdir -p "${PLUMOS_RK817_CARD_ID_PATH%/*}" "${PLUMOS_RK817_MIXER_HELPER%/*}"
printf 'rockchiprk817co\n' >"$PLUMOS_RK817_CARD_ID_PATH"
cat >"$PLUMOS_RK817_MIXER_HELPER" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$PLUMOS_TEST_MIXER_CALLS"
EOF
chmod 0755 "$PLUMOS_RK817_MIXER_HELPER"

[ "$($CONTROL speaker-boost get)" = "15.0" ]

$CONTROL speaker-boost apply 4.5
[ "$(cat "$PLUMOS_SPEAKER_BOOST_RUNTIME_STATE")" = "9" ]
[ "$(cat "$PLUMOS_SPEAKER_BOOST_SAVED_STATE")" = "9" ]
[ "$($CONTROL speaker-boost get)" = "4.5" ]

$CONTROL speaker-boost runtime 5.5
[ "$(cat "$PLUMOS_SPEAKER_BOOST_RUNTIME_STATE")" = "11" ]
[ "$(cat "$PLUMOS_SPEAKER_BOOST_SAVED_STATE")" = "9" ]

$CONTROL speaker-boost runtime 15
[ "$(cat "$PLUMOS_SPEAKER_BOOST_RUNTIME_STATE")" = "30" ]
[ "$($CONTROL speaker-boost get)" = "15.0" ]

rm -f "$PLUMOS_SPEAKER_BOOST_RUNTIME_STATE"
$CONTROL apply 8
[ "$(cat "$PLUMOS_SPEAKER_BOOST_RUNTIME_STATE")" = "9" ]
grep -qx 'init' "$PLUMOS_TEST_MIXER_CALLS"
grep -q '^backend=rk2020-hotplug-software-volume$' "$PLUMOS_VOLUME_LOG"
grep -q '^rk817_route=initialized$' "$PLUMOS_VOLUME_LOG"
$CONTROL runtime-up
[ "$(cat "$PLUMOS_VOLUME_RUNTIME_STATE")" = "9" ]
[ "$(grep -cx 'init' "$PLUMOS_TEST_MIXER_CALLS")" = "2" ]

if $CONTROL speaker-boost apply 4.2 >/dev/null 2>&1; then
  printf 'invalid boost value was accepted\n' >&2
  exit 1
fi
if $CONTROL speaker-boost apply 15.5 >/dev/null 2>&1; then
  printf 'out-of-range boost value was accepted\n' >&2
  exit 1
fi

printf 'rk2020_volume_control=result-ok\n'
