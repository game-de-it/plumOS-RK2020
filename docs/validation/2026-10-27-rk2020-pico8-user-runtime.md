# RK2020 user-supplied PICO-8 runtime validation

Date: 2026-10-27

Device: RK2020 at `192.168.10.110`

Runtime source: `/Volumes/public/02/motoki/emu/ROM/rom2/pico-8/aarch64`

## Scope and ownership boundary

The supplied directory contains the official PICO-8 0.2.7 Raspberry Pi/Linux
runtime. `pico8_64` is an ELF64 AArch64 executable using
`/lib/ld-linux-aarch64.so.1`; its direct dynamic dependencies are
`libSDL2-2.0.so.0`, `libm.so.6`, and `libc.so.6`.

Only the files needed to run and retain the accompanying notices were copied to
the device's user-owned ROM tree:

`/mnt/plumos-user/roms/PICO8/aarch64`

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `pico8_64` | 1,640,888 | `ad56e8ed1ad812cab57a7e2679b6731eba367cdd626cbf40a12b514060b597aa` |
| `pico8.dat` | 11,243,101 | `91212d55b540ef2abf9d5df7bb46fb87f41c35f3e9d108ebd8680debab020be2` |
| `license.txt` | 4,869 | `905a56b8679aa4a76f4bb2f49f3113828ffb5844b3da9a2b4493856546f33f44` |
| `readme_raspi.txt` | 939 | `1ee2830682a83427443baa338a09d1c289ac8966bc3f79e14cbd603676b547a8` |
| `readme_linux.txt` | 1,540 | `21497d9b4c9df25c3150c4ee027abadf45d2962ffa3f518f2a7b2ba780e7af93` |

Source and device hashes matched. The source volume was not modified. These
proprietary files are deliberately absent from Git, the managed app layer, and
release images; the existing release-content audit remains responsible for
enforcing that boundary.

## Controlled live launch

The representative cart `/mnt/plumos-user/roms/PICO8/51752.p8` was launched
through `/mnt/plumos/bin/plumos-standalone-launch pico8`. The live process:

- executed the copied `pico8_64` rather than a fallback binary;
- acquired `/dev/dri/card0`;
- loaded the managed SDL2 library and the stock Mali library;
- loaded `libplumos-pico8-download.so` and
  `libplumos-pico8-sdl-rotate.so`;
- selected the `rk817_stereo` audio route; and
- logged `PICO-8 SDL rotation: 480x320 -> 320x480 @ 270`.

The ALSA control probe emitted a non-fatal `Invalid CTL hw:0` warning before
the audio router selected `rk817_stereo`; the process continued running.

## Display evidence

A direct DRM scanout capture reported plane 58, CRTC 60, framebuffer 70,
320x480, pitch 1280, 32 bpp, and depth 24. After applying the panel's physical
clockwise orientation, the frame showed upright game content, readable UI, and
a centered 4:3 image with black side bars.

The Git-ignored local evidence files are under
`output/live/2026-10-27-rk2020-pico8-runtime/`:

- `pico8-scanout.xrgb8888`: `e4690302679652f631943d701bd4489b75ee1d40f5921b115337717b4375b0ea`
- `pico8-scanout.log`: `cdc97333c8748f1046dd78d9e1c96ee999815d3dd2bb4fa23fc4a2def3f6e48b`
- `pico8-scanout-view-cw.png`: `07d3497308f97aafe10c0ed72de87de6193f669737458db90216bd8bd920d710`

## Cleanup and result

`plumos-standalone-stop pico8` terminated PID 11406. The PICO-8 PID file and
process were absent afterward. `plumos-frontend-launch` started FE as PID 11567
and it remained alive. Temporary capture files were removed from `/tmp`.

The supplied runtime is therefore compatible with the existing RK2020 PICO-8
route. Runtime discovery, AArch64 execution, dependencies, adapters, rotation,
aspect ratio, controlled stop, and FE restoration pass.

## Physical acceptance follow-up

The operator subsequently reported that both the screen and controls work
correctly during PICO-8 gameplay. This accepts the physical display and control
gates without inferring unreported behavior. Audible output and the handheld
hotkey exit were not separately observed in this focused test. The operator's
subsequent project-level emulator acceptance closes the route as a blocker
without turning those unobserved sub-features into individual measured passes.
