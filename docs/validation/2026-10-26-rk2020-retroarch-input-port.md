# RK2020 RetroArch input port validation (2026-10-26)

## Scope

Correct the RK2020 physical input conversion while retaining the shared
plumOS RetroArch configuration, and deploy it to the live SD installation
without rebuilding the full image.

The requested physical contract is:

- L2 + Up/Down: system volume;
- L2 + Left/Right: display brightness;
- SELECT + B: RetroArch Quick Menu.

## Source comparison

The RK2020 factory config and the current plumOS Pixel2 factory config each
contain the same 3,376 unique RetroArch keys. There are no missing or extra
keys. Their 13 differing values are all device input conversions: D-pad,
SELECT/START, L2/R2, menu, exit, slow motion, and fast forward.

The shared configuration therefore already includes the plumOS save layout,
automatic save state, 20-state retention, screenshots, logging, menu assets,
core options, remaps, and persistent settings. Copying another device's file
again would overwrite RK2020 paths, rotation, audio, or input values. This
change keeps the common 3,376-key contract and corrects only RK2020 mappings.

## Corrected physical map

Live device-tree labels and kernel evdev ordering establish:

```text
SELECT = code 704 / udev 10
L2     = code 706 / udev 12
R2     = code 707 / udev 13
START  = code 709 / udev 15
B      = code 304 / udev 0
D-pad  = codes 544..547 / udev 6..9
```

F2/udev 11 and F5/udev 14 occupy generic OGA scan-order slots but are not
physical buttons on the RK2020. The prior port incorrectly used those two
slots for L2/R2 and also overwrote the game-launch D-pad with Pixel2 udev
buttons 10..13.

Commit `04ec7a4` corrects all affected layers:

- hardware service modifier: F5/code 708 -> physical L2/code 706;
- L2/R2: udev 11/14 -> udev 12/13;
- game-launch D-pad: Pixel2 10..13 -> RK2020 6..9;
- RetroArch menu: SELECT modifier 10 + physical B button 0;
- slow motion/fast forward: physical L2/R2 buttons 12/13;
- factory config, autoconfig, launch append config, and contentless menu append
  now use the same mapping.

The config merger recognizes the previous factory hash
`a538afc5cd9b3e6aec70234d59e8c4cee03e30590e0f98ca7dcae2dad2f5fc85`.
An untouched config is replaced atomically; a user-edited config migrates only
the five obsolete hotkey/trigger values plus any four Pixel2 D-pad values saved
from the old launch append, while preserving unrelated settings.

## Host validation

The following passed:

- shell syntax checks for all changed launch/config scripts;
- RK2020 emulator menu contract test;
- RetroArch game-menu selection test;
- old-factory replacement and user-setting-preserving migration test;
- AArch64 frontend build at source ref `04ec7a4`;
- AArch64 RetroArch build at source ref `04ec7a4`;
- strict component checksums for frontend and RetroArch;
- integrated app-layer verification and license audit.

## Live deployment

The managed-file backup is:

```text
/mnt/plumos-user/Backups/rk2020-live-input-04ec7a4
```

The running NES/QuickNES process was not stopped. The hardware-key service was
restarted and reports `volume_modifier=706`. PCM playback remained `RUNNING`.

The first top-level metadata copy stopped on a path-handling error after the
component files had been copied. No ROM, save, or active user config was
modified. The two top-level files and four duplicated metadata files were then
completed from the checksum-verified staging directory. Final verification:

```text
frontend component checksum: PASS
RetroArch component checksum: PASS
app-layer checksum: PASS (11,282 files)
```

## Physical results

The active NES process loaded the prior RetroArch configuration before
deployment. System L2 hotkeys can be tested immediately. To test SELECT+B,
exit once with SELECT+START, relaunch the NES game, and then open the Quick
Menu with SELECT+B.

- L2 + Up/Down volume response: **PASS** (operator confirmed).
- L2 + Left/Right brightness response: **PASS** (operator confirmed).
- Relaunched RetroArch SELECT+B menu: **PASS** (operator confirmed).
- SELECT+START exit: **PASS** (operator confirmed).
- Relaunched game D-pad and L2/R2 gameplay mapping: **PENDING operator test**.
