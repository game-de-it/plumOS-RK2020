# RK2020 third-pass evidence and consolidated correction

Date: 2026-10-25

## Hardware result

The card written from source ref `d5a1124` reached the plumOS framebuffer
frontend and cursor input worked. The third physical pass found:

- the stock-initramfs warning and 60-second startup countdown still appeared
  over the plumOS logo;
- some top-card labels crossed their card boundary;
- Wi-Fi remained `MISSING` with the RTL8811CU dongle inserted;
- no first-boot storage screen was perceptible;
- Shutdown powered the RK2020 off successfully.

The Mac readback showed that first-boot provisioning had in fact completed:
the system partition was 8 GiB, `PLUMOS_USER` occupied the remaining card
space, and `.plumos-ready` was dated 2026-10-25 13:22:42. Therefore the
missing storage screen was a visibility defect, not a partitioning failure.

Before further work, the mounted BOOT and USER evidence was copied without
modification to
`output/device-backups/2026-10-25-rk2020-third-pass`. Every copied file is
covered by `evidence.sha256`.

## Root causes and corrections

### Stock-initramfs countdown

The stock initramfs performs its compatibility check against the small fixed
`/flash/SYSTEM` dispatcher before that dispatcher selects
`system-a.squashfs`. Commit `b42f34f` had put the required
`usr/lib/kernel-overlays/base/lib/modules/4.4.189` sentinel in the slot only,
so the earlier hardware acceptance claim was incorrect.

Commit `a40da90` now puts the sentinel in both the dispatcher and slot and
makes dispatcher verification reject an image without it. The final
dispatcher was independently listed after construction and contains the
`4.4.189` directory.

### First-use Wi-Fi

The captured logs made the startup deadlock explicit:

- `usb-wifi.log`: `result=disabled reason=config-missing`;
- `usb-host-reenumerate.log`: `result=skipped reason=wifi-not-requested`;
- no USB Wi-Fi interface or driver load was recorded.

The frontend needs a detected interface before it can create the first Wi-Fi
configuration, while the service previously refused to probe hardware until
that configuration existed. Commit `8451416` removes that circular condition.
With no saved credentials, service `20-usb-wifi` now synchronously invokes the
bounded hardware-only network-control path before the frontend starts. That
path retains the V90S-derived, device-specific sequence: detect only
`0bda:1a2b`, eject its Realtek driver disk, wait for `0bda:c811`, resolve the
stock `8821cu` dependency tree, and expose `wlan0`. It does not start WPA until
credentials exist.

### Frontend card labels

Commit `434bc2d` measures each top-card title. A title that does not fit at
scale 2 falls back to scale 1, is centered, and is clipped to the inner card
bounds. This covers `FAVORITES` and future long system labels without relying
on a title-specific special case.

### First-boot display and evidence

Provisioning logs were being written to `/dev/console` immediately after a
raw progress frame was drawn, allowing text to replace the frame before it
could be perceived. Commit `bc6b1e2` sends those diagnostics to `/dev/kmsg`,
holds each successfully drawn stage for one second, and copies the completed
`first-boot.log` to `PLUMOS_USER/plumos-logs`.

The generated native 320x480 framebuffer frame was converted back to its
logical 480x320 orientation and visually checked: the title, `PREPARING
STORAGE`, safety message, and progress bar are all legible and within bounds.

### Shutdown

No new power correction was required. The hardware pass and captured
`power.log` confirm that the shutdown request ran cleanup, unmounted `/roms`,
and powered the unit off. This passes the tested shutdown case; externally
powered and unplugged cases remain distinct gates if both were not covered.

## Verification

The following checks passed after all four corrections:

- frontend component rebuild;
- strict app-layer and licensing verification;
- release implementation audit with zero blockers;
- RK2020 network-control and USB host re-enumeration tests;
- power-menu and sleep regression test;
- system-rootfs and dispatcher tests;
- first-boot partition fixture on a 16,000,000,000-byte virtual card,
  including its reboot boundary, ext4 growth, FAT32 creation, ready marker,
  and no-change repeat boot;
- A/B system-rootfs construction and verification;
- complete SD-image construction, extraction checks, first-boot fixture, and
  SHA-256 verification.

Final image pending write to the user's replacement high-speed SD card:

- file: `output/image/rk2020/plumOS-RK2020-0.1.0-dev.img`;
- size: 2,701,131,776 bytes;
- source ref: `bc6b1e2`;
- SHA-256: `060e4beec2383ecd7a40a719ca2c946130d56b54c7884c6612ac3f9d3669d747`.

`output/image/rk2020/checksums.sha256` validates both the image and its
manifest. SD writing is intentionally paused until the replacement card is
connected and re-identified.

## One final hardware pass

After the replacement card is written and readback-verified, check these
independently:

1. the storage preparation frames appear and the expected one-time automatic
   reboot completes;
2. the `NEVER TOUCH boot=` warning and 60-second countdown are absent;
3. all top-card artwork and labels stay visually balanced and within bounds;
4. the dongle leaves driver-disk mode, `wlan0` appears, and Wi-Fi scanning can
   open before any credentials are saved;
5. association and DHCP work after entering credentials;
6. Shutdown remains off and Reboot remains a separate working action;
7. `PLUMOS_USER/plumos-logs` contains `first-boot.log`, network-control logs,
   and the normal boot diagnostics.

Audio, each emulator route, sleep/resume, and application network access
remain separate acceptance gates from this correction pass.
