#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE="$ROOT_DIR/package/audio-router-rk2020/plumos_hotplug.c"

gains_text="$({
    sed -n '/static const int volume_gain\[\] = {/,/};/p' "$SOURCE" |
        sed '1d;$d' |
        tr ', ' '\n\n' |
        sed '/^$/d'
} | tr '\n' ' ')"
read -r -a gains <<<"$gains_text"

[ "${#gains[@]}" -eq 21 ]
[ "${gains[0]}" -eq 0 ]
[ "${gains[1]}" -eq 126 ]
[ "${gains[20]}" -eq 10000 ]

previous=-1
for gain in "${gains[@]}"; do
    [ "$gain" -gt "$previous" ]
    previous="$gain"
done

# Default +15 dB speaker boost must leave level 1 below 10% full scale.
[ $((gains[1] * 5623 / 1000)) -lt 1000 ]

grep -q 'sample \* volume_gain\[volume\]' "$SOURCE"
grep -q 'divisor = VOLUME_GAIN_DENOMINATOR' "$SOURCE"

printf 'rk2020_volume_curve=result-ok level1_gain=%s level20_gain=%s\n' \
    "${gains[1]}" "${gains[20]}"
