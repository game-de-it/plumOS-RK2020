# RK2020 DraStic input integration

Date: 2026-10-26

## Scope

The stock RK2020 controller has fewer dedicated buttons than the handhelds
targeted by the original `steward-fu/nds` integration.  The existing RK2020
build also inherited Pixel2 raw-input constants even though the RK2020 exposes
one non-clickable analog stick as `ABS_X` / `ABS_Y` in addition to its digital
D-pad. Consequently DraStic reported no SDL joystick, the analog stick was not
translated by the raw evdev path, and the handheld had no usable documented
menu or screen-swap contract.

Commit `86345f1` adds an RK2020-specific integration patch and records its hash
in the DraStic build manifest. The first physical menu test then showed that
the patch had incorrectly retained generic START/SELECT codes 315/314. Commit
`492e7e2` corrects them to the observed RK2020 codes 709/704 and records that
the single analog stick has no click input. The next physical test opened the
menu but showed delayed and apparently random cursor movement from both the
D-pad and stick. Live `EVIOCGABS` inspection measured a nominal range of
-900..899 but a released state of X=-9 and Y=+120. The original sign-only
conversion therefore held DOWN whenever Y rested at +120 and fought the
digital D-pad. Commit `c7bf94c` adds press/release hysteresis at 450/250 so the
neutral drift cannot produce a direction.

## Input contract

The source-built SDL2 integration now uses the observed RK2020 evdev contract:

| Physical input | Raw event | DraStic action |
| --- | --- | --- |
| D-pad | 544/545/546/547 | DS D-pad and menu navigation |
| Analog stick | `ABS_X` / `ABS_Y` | DS directions and menu navigation |
| A/B/X/Y | 305/304/307/308 | DS face buttons |
| L/R | 310/311 | DS shoulder buttons |
| L2 | 706 | hotkey modifier; not sent as a DS button |
| R2 | 707 | swap the two DS screens |
| START/SELECT | 709/704 | DS START/SELECT |

The user-facing combinations are:

- `L2 + START`: open the steward-fu integration menu;
- `L2 + SELECT`: open the native DraStic menu;
- `R2`: swap the two DS screens;
- `L2 + A`: switch to the alternate screen layout.

`L2 + D-pad` remains owned exclusively by plumOS for volume and brightness.
The DraStic integration consumes those combinations without also changing its
microphone, hinge, or layout state.

The analog stick is converted to digital directions only after crossing
plus/minus 450. Once held, it stays held until the axis returns within
plus/minus 250. Separate press and release thresholds prevent jitter around a
single boundary while leaving half of the measured travel available on each
side.

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
d6c41a0e88ac7e72d34b98bf0e50b155ca0f7a4b15eedd30f8ada49b6931a7fb  patches/drastic/steward-fu-nds-rk2020-input.patch
e31d39f3ac15c12008d58699162e24a6ac82ff70610582906c64f16f2a7b7d80  standalone/drastic/lib/libSDL2-2.0.so.0
3fc5bd69e8447d6954c003d4053bbba489c38f50765f79efb3544ba81c18df7b  standalone/drastic/build-manifest.json
```

## Live deployment and smoke test

The live app-layer passed all 636 standalone component checks and all 11,284
root checks both around the update as applicable.  Deployment was limited to
the two managed DraStic files and their five corresponding metadata files;
reproducibly rebuilt but unrelated PCSX-ReARMed, PPSSPP, OpenBOR, and Mupen64
differences were not deployed.  The final metadata identifies source
`c7bf94c`.

The previous seven managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-input-c7bf94c/before.tar
SHA-256 f4dd90490aa73903de3e209b893677964917d4589093a29df52e1807712b0605
```

No reboot was needed.  A live smoke test launched the representative ROM
`NDS/99のなみだ バンダイナムコゲームス.nds`, reached the
runner's first-frame ready marker, and showed the new SDL2 integration mapped
in the ARMHF DraStic process.  `plumos-standalone-stop drastic` terminated the
core, no runner remained, and the frontend restarted as PID 20727. The current
kernel log had no panic, Oops, BUG, internal error, or trace end.

## Remaining physical gate

The smoke test proves loading, first-frame presentation, managed-library use,
bounded termination, and frontend restoration.  Direct operator input is
still required to accept D-pad/game controls, dead-zone-corrected analog
directions, `R2` screen swap, corrected `L2 + START` and `L2 + SELECT`
combinations, deterministic menu navigation, and return to the frontend.
