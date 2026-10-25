#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PATCH="$ROOT_DIR/docker/rk2020-tools/patches/gw-libretro-soft-first-frame-geometry.patch"
BUILDER="$ROOT_DIR/scripts/build-libretro-cores.sh"
CATALOG="$ROOT_DIR/scripts/build-libretro-core-catalog-rk2020.sh"

test -s "$PATCH"
grep -q 'RETRO_ENVIRONMENT_SET_SYSTEM_AV_INFO' "$PATCH"
grep -q 'RETRO_ENVIRONMENT_SET_GEOMETRY, &info.geometry' "$PATCH"
grep -q 'gw-libretro-soft-first-frame-geometry.patch' "$BUILDER"
grep -q 'required Game & Watch first-frame geometry patch does not apply' "$BUILDER"
grep -q 'gw-libretro-soft-first-frame-geometry.patch' "$CATALOG"

printf '%s\n' 'rk2020_gw_core_geometry=result-ok'
