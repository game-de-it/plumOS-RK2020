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

The first physical touch-mode test then found cursor travel noticeably laggy
even though emulation remained at 100%. Inspection showed that the upstream
1.0x pen-speed formula truncates to two DS coordinates per update (and one
with R held), and the analog path intentionally exposes a held direction
rather than analog magnitude. Commit `ca2d1c8` keeps the saved `PEN SPEED`
multiplier effective but gives RK2020 five coordinates per update at 1.0x and
two with R held. This changes only RK2020 touch mode; normal-mode R screen
swap, emulation timing, presentation, and other devices retain their prior
paths.

The next physical test distinguished speed from latency: briefly nudging the
stick continued moving the cursor for about one second and covered roughly
half the screen. The RK2020 raw-input thread read only one event every 10 ms,
including ignored `EV_SYN` records. A burst of analog reports therefore left
the neutral/release report queued behind older values. Commit `7efaf7c` drains
up to 64 records per pass in arrival order and polls at 1 ms. It runs hotkey
handling after each meaningful record, so button chords retain their event
ordering while a stick release becomes current immediately.

The operator retest confirmed a substantial improvement and no longer saw a
brief stick nudge produce a half-screen delayed jump. Analog cursor travel is
still visibly stepped rather than smooth, so smoothing remains open separately
from the resolved input-queue latency.

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

## RK2020 aspect contract

The RK2020 runner rotates a logical 640x480 surface onto a native portrait
320x480 framebuffer. Filling the complete framebuffer gives unequal scale
factors after rotation and stretches the effective landscape output to
480x320. Commit `2b84b70` instead uses a centered 320x427 portrait viewport,
which becomes approximately 427x320 after rotation and preserves the source
4:3 ratio to within one physical pixel. The remaining 26/27 pixel margins
become left/right black bars on the handheld. Both swapchain paths clear the
complete buffer before redrawing so those bars cannot retain old menu or game
pixels.

After the operator still perceived a full-screen image, the active KMS
framebuffer was captured directly rather than relying on `/dev/fb0` (which is
black while the DRM runner owns scanout). CRTC 60 was scanning framebuffer 70
as XR24 at 320x480 with a 1280-byte pitch. After rotating the capture into the
handheld's physical landscape orientation, columns 0--25 and 453--479 were
black while game content occupied columns 26--452. The measured content area
is therefore 427x320 (1.334), confirming the 4:3 viewport within one pixel.
The evidence image is
`captures/2026-10-26-rk2020-drastic-aspect-2b84b70.png`, SHA-256
`36f6b3688484c845e0079b292fcb186669870a0bc48399e5b02912bc0c7b3032`.
The operator then confirmed that the physical display was correct, accepting
the RK2020 DraStic aspect-ratio gate.

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

The touch-speed update produced these current hashes:

```text
54d518552f3e07ecdea2c5a2db9333629adb73f7c33a22eb3536a5751b34c618  patches/drastic/steward-fu-nds-rk2020-touch-speed.patch
2cd7018a08d76d42cbf229c4fcc97789f32caab83345af920bba7bc3b3c7d6fd  standalone/drastic/lib/libSDL2-2.0.so.0
56986b784394ce47b89c7c438b484f67d1cd55ea2234bdfc73c33ec2b8af3fcc  standalone/drastic/build-manifest.json
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

The `ca2d1c8` touch-speed deployment again replaced only the SDL input
integration, its build manifest, and five corresponding metadata files. A
one-time full pre-deployment baseline verified all 636 standalone entries and
all 11,284 root entries. The assembled host tree passed strict verification
and the 169-license/110-core audit. The deployed hybrid metadata preserves the
live hashes of unrelated standalone binaries and has these hashes:

```text
4bda3466a3b374091a82f160c1616bbf2495233223ad1e173fbe185e40830961  components/standalone/checksums.sha256
776c0f5abf0e81438258c5211e00947b2091ffbe238677f889c29d219a194967  checksums.sha256
```

The previous seven managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-touch-speed-ca2d1c8/before.tar
SHA-256 b10b93002b59afabb2fd52876ba1bcf48ea4efb033f5e79d2d4ec83e6b455a95
```

The live smoke test reached first frame with runner PID 1450 and core PID
1467. The core mapped the expected `2cd7018a...d6fd` SDL2 library, bounded
stop removed both processes, the frontend restarted as PID 1693, and the
recent kernel tail contained no fault signature. The seven-file targeted
check passed after FE restoration.

Commit `8f05e60` adds `verify-rk2020-managed-delta.sh`. Live iterations now
hash only the explicitly changed files plus the component-to-root metadata
chain. Full 636/11,284-file verification and license audit remain image,
release, and periodic-baseline gates rather than requirements for every live
delta.

The input-drain and aspect update was deployed as an eight-file managed delta;
no full-tree hash pass was repeated. The targeted pre/post checks both passed.
Current hashes are:

```text
9e2af87f1c6538490afc0f3362fd3861425dcd28b3978a9438d39f0d534eebc8  patches/drastic/steward-fu-nds-rk2020-input-drain.patch
7435bf6762c9487aa148a1bda951323cf3feac9fa068fb22cb55e9bd1a4002bb  patches/drastic/steward-fu-nds-rk2020-runner-aspect.patch
de77075c0c0800df7fd7b698d12769bd1b520d1ed9d2f28193fe21fbb9fc0150  standalone/drastic/lib/libSDL2-2.0.so.0
ab1e0fd2e7f6203296e74146ef6dd10198122023eaf00ab4122a892c8383dd4d  standalone/drastic/bin/runner
08a9addd929c91e0b11eaf6c732dfdae44a821087089a093b1b79013124b9978  standalone/drastic/build-manifest.json
b609d355fa3024394de94008d38817ad66e401721129be81434617e4bc108ffc  components/standalone/checksums.sha256
0e19442886e3f4ab6b00c1cdc516c6f1a17af39e8bb1611314e337f14630b032  checksums.sha256
```

The previous eight managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drastic-latency-aspect-2b84b70/before.tar
SHA-256 8aa81a5452e2e9d24d4516d91149b2db267151a2acd606fec96d7f2d360f37ce
```

The live smoke route reached first frame with runner PID 4038 and core PID
4053. The running processes mapped the expected runner and SDL2 hashes, and
the recent kernel tail contained no fault signature. The game was left running
for direct cursor-release and aspect-ratio acceptance.

## Remaining physical gate

The smoke test proves loading, first-frame presentation, managed-library use,
bounded termination, and frontend restoration. The operator accepted stable
menu navigation with both D-pad and analog input after the menu-present update.
D-pad/game controls, dead-zone-corrected analog directions, `R2` screen swap,
the remaining L2 combinations, and return to the frontend remain part of the
physical-input gate. The queue-drained cursor release and 4:3 viewport are
accepted. Smooth analog cursor motion, touch press, R precision movement, and
return to normal controls through `L2 + X` remain direct operator gates.
