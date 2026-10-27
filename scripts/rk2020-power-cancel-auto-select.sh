#!/bin/sh
set -eu

# Test-only selector for validate-rk2020-power-cancel-matrix.py.  The real
# hardware daemon still owns the DRM handoff; only the physical B selection is
# replaced so every runtime family can be checked without operator timing.
[ -n "${PLUMOS_POWER_MENU_SELECTION:-}" ] || exit 2
printf 'action=cancel\n' >"$PLUMOS_POWER_MENU_SELECTION"
