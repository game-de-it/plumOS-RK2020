#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HELPER="$ROOT_DIR/package/audio-router-rk2020/plumos/bin/plumos-audio-output"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/plumos-rk2020-audio-id.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

mkdir -p \
    "$tmp/sys/class/sound/card0" "$tmp/proc/asound/card0" \
    "$tmp/dev/snd" "$tmp/plumos/factory-defaults/alsa" "$tmp/run"
printf 'rockchiprk817co\n' >"$tmp/sys/class/sound/card0/id"
printf 'rockchiprk817co\n' >"$tmp/proc/asound/card0/id"
printf '00-00: ff070000.i2s-rk817-hifi rk817-hifi-0 :  : playback 1 : capture 1\n' \
    >"$tmp/proc/asound/pcm"
: >"$tmp/dev/snd/pcmC0D0p"
: >"$tmp/plugin.so"
: >"$tmp/plumos/factory-defaults/alsa/alsa.conf"

env \
    PLUMOS_ROOT="$tmp/plumos" \
    PLUMOS_RUNTIME_ROOT="$tmp/run" \
    PLUMOS_AUDIO_PLUGIN="$tmp/plugin.so" \
    PLUMOS_SOUND_SYS_CLASS="$tmp/sys/class/sound" \
    PLUMOS_ASOUND_PROC_ROOT="$tmp/proc/asound" \
    PLUMOS_DEV_SND_ROOT="$tmp/dev/snd" \
    "$HELPER" prepare >"$tmp/result"

grep -q '^mode=rk817_stereo$' "$tmp/result"
grep -q '^card=0$' "$tmp/result"
grep -q '^card_id=rockchiprk817co$' "$tmp/result"
grep -q 'strcmp(id, "rockchiprk817co") == 0' \
    "$ROOT_DIR/package/audio-router-rk2020/plumos_hotplug.c"

printf 'rk2020_audio_card_id=result-ok\n'
