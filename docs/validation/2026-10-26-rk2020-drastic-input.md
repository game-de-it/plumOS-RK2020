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
neutral drift cannot produce a direction. A subsequent physical retest still
showed the same delayed, apparently random cursor movement with both the
digital D-pad and analog stick, proving that neutral drift was not the menu
presentation failure.

The same symptom had already been corrected on plumOS-XU20 in commit
`e497bab`. DraStic redraws its menu only when its state changes, while the
Rockchip display runner alternates front and back buffers. Presenting only the
newly changed buffer therefore made the visible cursor alternate between old
and new positions. Commit `c5dd815` ports that established fix to RK2020: while
the 640x480 menu surface is active, the runner redraws the cached complete menu
frame and presents it at approximately 60 Hz. Gameplay surfaces retain their
existing producer-driven presentation.

## Input contract

The source-built SDL2 integration now uses the observed RK2020 evdev contract:

| Physical input | Raw event | DraStic action |
| --- | --- | --- |
| D-pad | 544/545/546/547 | DS D-pad and menu navigation |
| Analog stick | `ABS_X` / `ABS_Y` | DS directions/menu navigation, or touch cursor in touch mode |
| A/B/X/Y | 305/304/307/308 | DS face buttons |
| L/R | 310/311 | DS shoulder buttons |
| L2 | 706 | hotkey modifier; not sent as a DS button |
| R2 | 707 | swap the two DS screens |
| START/SELECT | 709/704 | DS START/SELECT |

The user-facing combinations are:

- `L2 + START`: open the steward-fu integration menu;
- `L2 + SELECT`: open the native DraStic menu;
- `L2 + X`: toggle normal controls and touch mode;
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

In touch mode, the analog stick or D-pad moves the visible DS stylus cursor,
`A` presses/releases the touchscreen, and `R` slows cursor movement for fine
positioning. Repeating `L2 + X` returns to normal DS controls. The transition
calls DraStic's input-release path so neither a touch nor a game button can
remain logically held across the mode change. Commit `7fa625f` implements this
without changing the persistent user configuration.

This route deliberately bypasses DraStic's SDL joystick table.  The persistent
user configuration remains untouched; on the test unit it still records menu
fallback 1032 and no joystick screen-swap binding (65535).  The raw integration
implements the RK2020 controls outside those mutable settings.

## Menu presentation contract

The display runner recognizes DraStic's 640x480 menu flush separately from its
256x192 and 512x384 gameplay surfaces. While the menu is active it keeps the
last complete background and foreground textures cached, swaps the display,
and redraws that complete frame every 16 ms. This keeps both swapchain buffers
at the same cursor position without inventing input repeats or changing the
input mapping. Returning to a gameplay-sized surface disables the timed
presentation loop.

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
e84fb979d3a38f1bf727dce0794683fc3cf040879b2691b184ff0bd9b4141907  patches/drastic/steward-fu-nds-rk2020-menu-present.patch
e31d39f3ac15c12008d58699162e24a6ac82ff70610582906c64f16f2a7b7d80  standalone/drastic/lib/libSDL2-2.0.so.0
b01148b146bf231589ea6212f97f6f25a7b661acf101d1ac327e39c86ec20845  standalone/drastic/bin/runner
bce96caf0a8d8748795faed192a8a996cec13180c0244c250e4b8c902a09024f  standalone/drastic/build-manifest.json
```

The touch-mode update produced these additional/current hashes:

```text
b475bc3e169b71583ca97578cd2a08fb89772ce3e45997feb1f51a55e4502e27  patches/drastic/steward-fu-nds-rk2020-touch-mode.patch
248ddbbe5eb7c093d57bb74df303566268ad1fed3714701a00cb1efd40c9c778  standalone/drastic/lib/libSDL2-2.0.so.0
3d0d9d59f2dad25b35f234f659ed8bced3c89f4ce04ed2b89915880ff90a8a5f  standalone/drastic/build-manifest.json
```

## Live deployment and smoke test

The live app-layer passed all 636 standalone component checks and all 11,284
root checks before and after the menu-present update. Deployment was limited
to the new runner, its build manifest, and five corresponding metadata files;
the unchanged input library and reproducibly rebuilt but unrelated standalone
files were not deployed. The final metadata identifies source `c5dd815`.

The deployed hybrid checksum files retain the hashes of every untouched live
file and have these hashes:

```text
ec2d327a290b8ce7ae6da681e0addf2e554ac4c0e8fe5968e580606fea4a14d4  components/standalone/checksums.sha256
e10b9d9cf6e5046013f2cab6eecb6d24a40fa19018e5df345740bc9a2b3911d4  checksums.sha256
```

The previous seven managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-input-c7bf94c/before.tar
SHA-256 f4dd90490aa73903de3e209b893677964917d4589093a29df52e1807712b0605
```

The seven files replaced by the menu-present update are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-menu-c5dd815/before.tar
SHA-256 5e40fd522573fbc1d4aedcdef15608622875823006225fe23a5493c7af18db9f
```

No reboot was needed.  A live smoke test launched the representative ROM
`NDS/99のなみだ バンダイナムコゲームス.nds`, reached the
runner's first-frame ready marker, and showed the new SDL2 integration mapped
in the ARMHF DraStic process.  `plumos-standalone-stop drastic` terminated the
core, no runner remained, and the frontend restarted as PID 20727. The current
kernel log had no panic, Oops, BUG, internal error, or trace end.

After the menu-present deployment, the same smoke route reached first-frame
ready with runner PID 22397 and core PID 22443. The running runner matched
`b01148...0845`, the ARMHF core mapped the expected managed SDL2 library,
bounded stop removed both processes, and the frontend restarted as PID 22598.
The current kernel tail again contained no panic, Oops, BUG, internal error, or
trace end.

The `7fa625f` touch-mode deployment replaced the SDL input integration, its
build manifest, and five corresponding metadata files. All 636 standalone and
11,284 root checksum entries passed before and after deployment. The deployed
hybrid metadata hashes are:

```text
f81edb9bd521b81f0c6fb87242869f6e2aa296ed5a1039c164da184f84f43b32  components/standalone/checksums.sha256
b76a466ad84e448b128f9c20f13303085864e84a000f5ff7d73074ead5fa02c6  checksums.sha256
```

The previous seven managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-touch-7fa625f/before.tar
SHA-256 888ec5797aa450d0e086bac56d987596d14e65a19fb46e6f164ebc3d2541c67e
```

The post-deployment smoke test reached first-frame ready with runner PID 24624
and core PID 24674. The running ARMHF core mapped the new SDL2 integration with
hash `248ddbbe...c778`, bounded stop removed both processes, and the frontend
restarted as PID 24836. The kernel tail had no fault signature.

## Remaining physical gate

The smoke test proves loading, first-frame presentation, managed-library use,
bounded termination, and frontend restoration. The operator accepted stable
menu navigation with both D-pad and analog input after the menu-present update.
D-pad/game controls, dead-zone-corrected analog directions, `R2` screen swap,
the remaining L2 combinations, and return to the frontend remain part of the
physical-input gate. The visible cursor, movement, touch press, slow movement,
and return to normal controls through the new `L2 + X` touch mode also require
direct operator acceptance.
