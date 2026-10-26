# RK2020 DraStic input integration

Date: 2026-10-26

## Scope

The stock RK2020 controller has fewer dedicated buttons than the handhelds
targeted by the original `steward-fu/nds` integration.  The existing RK2020
build also inherited Pixel2 raw-input constants even though the RK2020 exposes
its D-pad as `ABS_X` / `ABS_Y`.  Consequently DraStic reported no SDL joystick,
the D-pad was not translated by the raw evdev path, and the handheld had no
usable documented menu or screen-swap contract.

Commit `86345f1` adds an RK2020-specific integration patch and records its hash
in the DraStic build manifest.

## Input contract

The source-built SDL2 integration now uses the observed RK2020 evdev contract:

| Physical input | Raw event | DraStic action |
| --- | --- | --- |
| D-pad | `ABS_X` / `ABS_Y` | DS D-pad and menu navigation |
| A/B/X/Y | 305/304/307/308 | DS face buttons |
| L/R | 310/311 | DS shoulder buttons |
| L2 | 706 | hotkey modifier; not sent as a DS button |
| R2 | 707 | swap the two DS screens |
| START/SELECT | 315/314 | DS START/SELECT |

The user-facing combinations are:

- `L2 + START`: open the steward-fu integration menu;
- `L2 + SELECT`: open the native DraStic menu;
- `R2`: swap the two DS screens;
- `L2 + A`: switch to the alternate screen layout.

`L2 + D-pad` remains owned exclusively by plumOS for volume and brightness.
The DraStic integration consumes those combinations without also changing its
microphone, hinge, or layout state.

This route deliberately bypasses DraStic's SDL joystick table.  The persistent
user configuration remains untouched; on the test unit it still records menu
fallback 1032 and no joystick screen-swap binding (65535).  The raw integration
implements the RK2020 controls outside those mutable settings.

## Host build and checks

The following checks passed:

- `tests/test-rk2020-emulator-menu-contract.sh`;
- `tests/test-app-layer-scripts.sh`;
- full `standalone` build containing all six packaged standalone routes;
- strict app-layer verification;
- license audit with 169 license files and 110 libretro cores.

Relevant generated hashes are:

```text
b91cb7da38d35807eba44d76ecb203fa1e363a785426fd3d855cd01ef378f821  patches/drastic/steward-fu-nds-rk2020-input.patch
e70cc6dbb783e2fa5827788d734b06bd246c06579ac5c0476604c8c00a2f020f  standalone/drastic/lib/libSDL2-2.0.so.0
3193a1d113fdf073d6bac6aab5da033265ea35ce0f4eeae30120d5a411d67836  standalone/drastic/build-manifest.json
```

## Live deployment and smoke test

The live app-layer passed all 636 standalone component checks and all 11,284
root checks both around the update as applicable.  Deployment was limited to
the two managed DraStic files and their five corresponding metadata files;
reproducibly rebuilt but unrelated PCSX-ReARMed, PPSSPP, OpenBOR, and Mupen64
differences were not deployed.  The final metadata identifies source
`86345f1`.

The previous seven managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-input-86345f1/before.tar
SHA-256 ad8da3019960ee1d2859f3011108b7eded768158ca58e3a40540170b33d8e1ae
```

No reboot was needed.  A live smoke test launched the representative ROM
`NDS/99のなみだ バンダイナムコゲームス.nds`, reached the
runner's first-frame ready marker, and showed the new SDL2 integration mapped
in the ARMHF DraStic process.  `plumos-standalone-stop drastic` terminated the
core, no runner remained, and the frontend restarted as PID 16101.

## Remaining physical gate

The smoke test proves loading, first-frame presentation, managed-library use,
bounded termination, and frontend restoration.  Direct operator input is
still required to accept D-pad/game controls, `R2` screen swap, both menu
combinations, menu navigation, and return to the frontend.
