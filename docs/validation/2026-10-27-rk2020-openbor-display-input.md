# RK2020 OpenBOR display and input

Date: 2026-10-27  
Device: RK2020 at `192.168.10.110`  
Source commit: `e05c7a3`

## Physical failure and diagnosis

The operator reported that OpenBOR was sideways and that the controller was
generally incorrect. A direct KMS capture confirmed that OpenBOR copied its
landscape game texture into the panel-native 320x480 target without the final
quarter-turn. The physical-view capture is SHA-256
`00060d042e1037f5b56ea06bd24720249c2ea8257ab1ed7fdfa27f5413f83e05`.

The `GO-Advance Gamepad` was open as a raw SDL joystick with 2 axes, 16
buttons, and no hats. OpenBOR packs those 16 button bits first and the four
axis-direction bits afterward. The original RK2020 patch assumed the reverse,
so its defaults mapped D-pad directions onto SELECT/L2/Function/R2 and mapped
START onto an analog direction.

## Correction

The corrected button contract is:

```text
D-pad: b6/b7/b8/b9
A/B/X/Y: b1/b0/b2/b3
L1/R1: b4/b5
SELECT/START: b10/b15
Function screenshot: b12
```

`ABS_X` and `ABS_Y` are thresholded using OpenBOR's existing dead zone and
mirrored onto the same four D-pad button bits, so both the physical D-pad and
the single analog stick control movement. The loader also recognizes and
replaces the exact broken mapping written by the earlier RK2020 build.

A dedicated SDL renderer adapter presents OpenBOR's unchanged 480x320 logical
surface to the native 320x480 KMS target with a 270-degree final turn. The
launcher uses the GLES2 renderer and preloads only this OpenBOR adapter.
OpenBOR's `Saves`, `Logs`, and `ScreenShots` paths now link to its mutable
state directory instead of being discarded with the temporary PAK workdir.

## Build and live deployment

The focused emulator contract, clean upstream `git apply --check`, and the
app-layer script suite passed. The targeted ARM64 artifacts are:

```text
fc28dbbbceb289be7b602586764c063081b1e7e40d943a4e9a61cf3355d8ee61  standalone/openbor/bin/OpenBOR
09f91f080c8fdba055fdd0bb3f08524952feef655321ea14bb54f4df714b6ea8  standalone/openbor/lib/libplumos-openbor-sdl-rotate.so
9febce73b8b076d7bbf0546ae103e071923ee2579aeaab153fa26b7028b87686  standalone/openbor/build-manifest.json
```

The live update used a nine-file standalone managed delta. Its staged bundle,
seven-file old live subset, and nine-file post-update live state all passed
the targeted verifier. The resulting metadata hashes are:

```text
86805a2d288b56f6c67e20e43cd0f852f56ed54ab16e4c071fc138d049b66bb5  components/standalone/checksums.sha256
ec4b7a20f68aad99eb9c9d112befba65703acf9bed8d566ce75fa7fac88de2e7  components/standalone/manifest.json
d3076f5468906d46365226511e3608cb563ca588a1dc75ce04f79149fbd916d6  manifest.json
c5ee3f6a83885983ab4dc056f092ff2a91d893ee69a80a662c1a651a9c89086c  checksums.sha256
```

The prior managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-openbor-e05c7a3/before.tar
SHA-256 6a8f61b3e37d56bbd0992ec304bcb20572e886818ef61864deecea08539a5129
```

The backup's `previously-absent.txt` records that the new rotation adapter and
OpenBOR build manifest did not exist before this update.

## Runtime evidence and remaining gate

The deployed OpenBOR started Crisis Evil 1 as PID 17701. Its executable hash
matched the rebuilt artifact, the dedicated rotation adapter appeared in its
memory map, `/dev/input/event2` was open, persistent state symlinks resolved to
`/mnt/plumos/state/standalone/openbor/data`, and the recent kernel tail had no
fault signature.

The corrected direct scanout is SHA-256
`9abd75672d97136cdef78823f57dbcd226ecfd26e1d10e1c47ccd91ef826209e`.
It shows a correctly oriented 480x320 frame with readable horizontal text.
The game remains running for physical D-pad, analog, ABXY, shoulder, START,
and SELECT acceptance. The frontend is resumed automatically when it exits.
