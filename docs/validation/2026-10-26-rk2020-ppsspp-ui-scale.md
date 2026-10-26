# RK2020 PPSSPP menu scale

Date: 2026-10-26  
Device: RK2020 at `192.168.10.110`  
Source commit: `67d45eb`

## Failure and direct capture

The physical PPSSPP pause menu used `UIScaleFactor = -2`. Its right-side
`Create game config` and `Display layout & effects` labels reached or crossed
the 480x320 display edge, and the five save-state rows consumed nearly the
complete height.

PPSSPP owns a GLES/KMS primary plane, so `/dev/fb0` is not evidence of its
current frame. The stock 4.4 kernel also rejects `drmModeGetFB2`; a temporary
diagnostic therefore queried the active plane with legacy `drmModeGetFB` and
mapped its linear dumb buffer. The captured plane was:

```text
plane=58 crtc=60 fb=70 width=320 height=480
pitch=1280 bpp=32 depth=24 handle=1
```

The native portrait XRGB8888 buffer was rotated into the physical 480x320
view. The original capture is
`captures/2026-10-26-rk2020-ppsspp-menu-before.png`, SHA-256
`634ffe176e604742b9c01c8061a56f32b5d376ccbbf46715d1957dc3310dffd0`.

## Correction

PPSSPP 1.20.4 converts the integer setting to
`2^(UIScaleFactor/8)`. The previous `-2` value gives a 0.841 multiplier and
the RK2020 presenter reported a logical UI area of only 571x381 dp. The new
RK2020 default is `-6`, a 0.595 multiplier and an 807x538 dp UI area. This
reduces UI elements without changing the 480x320 game surface or its 9/16
pre-rotation aspect correction.

The launcher migrates only the exact `-8` and `-2` values shipped by earlier
RK2020 packages. Any other user-selected UI scale and every unrelated PPSSPP
setting, save, state, and game-specific configuration remain untouched.

The final managed-launch trace was:

```text
ui_scale=0.595 pixel=321x481 dp=807x538
dpi=2.515x1.119 dpi_real=1.495x0.665
```

The direct final-plane capture is
`captures/2026-10-26-rk2020-ppsspp-menu-after.png`, SHA-256
`f7c493c99a0bd8c87dcaf40e44c4aacf0b8ffd3a43a030a4e92ca775ad84396a`.
It contains all five save-state rows, every right-side menu label, and both
bottom actions within the 480x320 frame.

## Checks and live deployment

The focused emulator-menu contract and the app-layer script suite passed. The
complete host app layer also passed its 11,284-file verifier and the 169-file,
110-core license audit.

The live update changed only the launcher, two managed factory copies, the
standalone/component manifest pair, and their component/root checksum chain.
Comparison against the live checksum inventory rejected ten unrelated rebuilt
standalone artifacts; none of those files were deployed. Both the pre-update
and post-update eight-file managed-delta checks passed.

Current important hashes are:

```text
154853e75d1ffe6bbaa67767f003b05d31cf767eb44c0fe4ffee60a355322adb  bin/plumos-standalone-launch
c7bb0afb35f28e4f158960af85c13b5a46e807ae525c914f894c8b108d6cb002  factory-defaults/standalone/ppsspp/PSP/SYSTEM/ppsspp.ini
4e47e875baccbc0a7ae392e9344b2643fdd129cd8569fece32fc2001825322f9  components/standalone/manifest.json
6c2c035a21191143bd959bbc001384ebefe0e7a7729e0581e019e59fa46f5dba  components/standalone/checksums.sha256
01d63a78d4655ef3bf81a7d6d49203314a5c818e760983030da0a29504ec222d  manifest.json
4eaab0d96e5b56ee214b1bcc5545f1054d68cbbf5966d3c7e13f9b09af73e4cb  checksums.sha256
```

The previous managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-ppsspp-ui-67d45eb/before.tar
SHA-256 d15d9d13448a466b866a2111b3691746bc46d509b04ce07a072a06a74a0deb95
```

PPSSPP is left running on the corrected pause menu for direct physical
readability and control acceptance.
