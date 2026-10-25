# RK2020 stock read-only inventory

Date: 2026-10-25

Source: live stock system at `root@192.168.10.107`

Write policy: no command in this inventory changed the device or remounted
`/flash`; the stock SD remains the recovery source.

## Identity

- EmuELEC 4.8, build ID `5a3e0877546318dd70cd001563e57bfb78328a6b`
- Linux `4.4.189`, AArch64, RK3326
- DT model `Hardkernel ODROID-GO2`
- compatible `rockchip,rk3326-odroidgo2-linux`, `rockchip,rk3326`
- `MemTotal: 913716 kB` after kernel reservations

## SD and boot sequence

The 124,383,133,696-byte stock SD is `/dev/mmcblk0`. Its 512-byte-sector MBR
layout is:

| Region | Start LBA | Sectors | Observed role |
| --- | ---: | ---: | --- |
| Rockchip prefix | 0 | 32,768 | loader/U-Boot payload and MBR |
| p1 | 32,768 | 4,194,304 | FAT32 `EMUELEC`, mounted `/flash` read-only |
| p2 | 4,227,072 | 12,550,144 | ext4 `STORAGE`, mounted `/storage` read-write |
| p3 | 16,777,216 | 226,158,592 | FAT32 `EEROMS`, mounted at `/storage/roms` |

`boot.ini` selects an extlinux stanza from the U-Boot `hwrev`. The observed
runtime command line matches the default `rk3326-odroidgo2-linux.dtb` stanza:

1. U-Boot loads `/KERNEL` and `/rk3326-odroidgo2-linux.dtb` from p1.
2. The uncompressed ARM64 kernel contains a gzip initramfs at byte 15,373,488.
3. The initramfs runs `mount_flash`, which mounts p1 at `/flash` and sources
   the optional `/flash/post-flash.sh` hook.
4. It then runs `mount_sysroot`, loop-mounts `/flash/SYSTEM` at `/sysroot`, and
   sources `/flash/post-sysroot.sh` before any persistent storage is mounted.
5. Only after both flash hooks return does it run `mount_storage` for p2 at
   `/storage`, followed by `mount_roms` for the partition labelled `EEROMS` at
   `/storage/roms`.
6. It moves `/dev`, `/proc`, `/sys`, and `/run`, runs `kernel-overlays-setup`,
   then executes `switch_root /sysroot /usr/lib/systemd/systemd`.

The stock initramfs therefore provides the same controlled `SYSTEM` replacement
boundary used by the Pixel2-derived plumOS architecture. The stock `SYSTEM`
remains an analysis input and is not copied into the repository or target image.

## Registered boot identities

| Artifact | SHA-256 |
| --- | --- |
| first 16 MiB | `4f9ca6fc40e6d267ec9ff03d55ccdc144e0de892c6fa47c33065e1790e40bfa6` |
| `KERNEL` | `bad7390891755bb0b80d332edbaeb1945b926b5da2ec90fcdf3f2964cba660a3` |
| active source DTB | `ec3d18451e08b2b978097ff1fa2110b93274ba74678d55b2779e773dc1199e9b` |
| runtime FDT after U-Boot fixups | `7ce72a08ed2e7f19c7a417e56fe845d6c0caaf590505ad3a1a95c1811516e731` |
| stock `SYSTEM` analysis input | `ab1e1cd2f1921c5a74a6a33d179692c64abcac91285b1ada25eb29afe916da83` |

The runtime FDT differs only in expected boot-time fixups observed in the
decompiled comparison: serial number, memory ranges, boot arguments, reserved
memory, and DRM loader-logo address.

## Hardware contract

- panel: Elida KD35T133, one-lane MIPI-DSI, native 320x480, observed 60 Hz;
- display rotation: kernel command line uses `fbcon=rotate:3`;
- GPU: PX30/RK3326 Mali Bifrost path with Rockchip 4.4 driver;
- input: `GO-Advance Gamepad`, vendor `0x484b`, product `0x1000`, version
  `0x0100`, 16 buttons and two ADC axes;
- audio: `rockchip,rk817-codec`, card 0, GPIO headphone detect;
- backlight: PWM, 256 levels, observed maximum 255;
- power: RK817 battery/charger and `rk8xx_pwrkey`;
- storage: SD card negotiated SDR104 at 150 MHz;
- network: external USB `0bda:c811`, stock `8821cu` module version
  `v5.4.1_28754.20180921_COEX20180712-3232`, vermagic
  `4.4.189 SMP mod_unload aarch64`;
- suspend interface advertises `freeze mem disk`; advertisement is not a
  suspend/resume acceptance result.

## Porting boundary and remaining gates

The exact 4.4.189 kernel, DTB, kernel module tree, and firmware tree must remain
a matched set. Pixel2's 5.10.198 modules and its panel/controller assumptions
are rejected. Host-side capture and hash checks are only provenance evidence;
boot, display, controls, speaker/headphones, power transitions, Wi-Fi, storage,
and emulator routes still require separate tests on a non-stock SD.
