# RK2020 quiet boot and 480x320 frontend correction

## Physical report

The RK2020 booted the previous development image and reached the frontend.
The operator then reported two remaining display defects:

- stock initramfs and userspace console messages appeared in front of the
  plumOS splash;
- frontend layouts still behaved as though a 640x480 canvas were available,
  causing oversized or clipped text in settings, the Wi-Fi password keyboard,
  and footer explanations.

The corrected build was subsequently installed as a bounded live update and
booted on the same unit. Visual acceptance still requires the operator checks
listed below.

## Boot-console correction

Commit `536baab` removes only the framebuffer console token `console=tty0`
from every generated extlinux configuration. The serial diagnostic console
`console=ttyFIQ0`, stock kernel, exact stock DTBs, and `fbcon=rotate:3` remain
unchanged. Generated configurations also use `loglevel=3` and
`vt.global_cursor_default=0`.

The SD-image verifier now rejects any generated extlinux configuration that
still contains `console=tty0`, or that loses the serial console and quiet-boot
parameters.

## Frontend layout correction

Commit `c79024a` makes the fbdev renderer use its logical dimensions after the
RK2020's counter-clockwise rotation: physical 320x480 becomes logical 480x320.
The same compact layout metrics now drive both the controller's list-window
size and the renderer.

The 480x320 contract is:

- generic/settings text scale: 1 (12-pixel FreeType size where available);
- list line height: 22 pixels;
- footer: 58 pixels with two independently clipped explanation lines;
- settings capacity with footer: 9 visible rows;
- Wi-Fi keyboard: all 7 rows remain above the footer;
- Wi-Fi password display: masked before entering the render buffer;
- graphic ROM list: 7 emitted and drawable rows instead of 10 emitted rows
  with only the first 6 visible;
- TOP grid: 3 columns by 2 rows, 146x118-pixel cards, 8-pixel gaps, and
  13/12-pixel horizontal/bottom margins;
- TOP labels: consistent compact FreeType sizing and clipping within each
  card.

`tests/test-rk2020-fbdev-layout.c` fixes these dimensions in an executable
host test. Commit `bdb3c52` additionally provides a safe screenshot trigger:
`SIGUSR1` only sets a `sig_atomic_t` request, and the existing frontend process
writes its own framebuffer shadow to PNG from the normal event loop. No second
frontend or external framebuffer mmap is required.

The first live screenshot exposed a separate RK2020 path assumption: deriving
the media root from `/mnt/plumos` produced `/mnt/Screenshots`, which is not the
writable user partition. Commit `74f9e93` uses the already configured
`PLUMOS_SDCARD_ROOT` (`/mnt/plumos-user`) instead. The running frontend then
saved its PNG successfully without opening a second framebuffer owner.

## Host validation

The following gates passed:

- frontend AArch64 cross-build;
- RK2020 fbdev layout test:
  `logical=480x320 settings_rows=9 top=3x2@146x118`;
- app-layer strict checksum verification;
- app-layer license audit (168 license files, 110 libretro cores);
- frontend component and app-layer manifests both identify source
  `b129e75` in the final rebuilt image;
- rebuilt System A/B rootfs and fixed dispatcher verification;
- complete SD-image verification, including FAT/ext4 checks, stock boot-prefix
  comparison, exact stock kernel/DTB comparison, SYSTEM slot verification,
  app-layer verification, and first-boot partition simulation.

Generated image:

- path: `output/image/rk2020/plumOS-RK2020-0.1.0-dev.img`;
- size: `2701131776` bytes;
- SHA-256: `015a498bf4d7750ac7eae0e2cb81773eb808cf14086abfc343ea882eb776507c`;
- source ref: `b129e75`.

## Live deployment evidence

The RK2020 was reached at `192.168.10.110`. Before replacement, all 11,280
entries in the installed app-layer checksum set passed. The live update was
limited to the frontend binary, frontend component manifest and checksum,
the manifest's license copy, and the app-layer manifest and checksum. User
settings, ROMs, BIOS files, saves, and PortMaster content were not replaced.

The four installed extlinux configurations were transformed in place after a
backup: `console=tty0` was removed, while `console=ttyFIQ0` was retained and
`loglevel=3 vt.global_cursor_default=0` was added. `/flash` was returned to a
read-only mount. The installed app layer then passed 201/201 frontend checks
and 11,280/11,280 global checks before restart.

Post-boot evidence:

- `/proc/cmdline` contains the corrected quiet-boot tokens and no
  `console=tty0`;
- frontend source and app-layer source identify `74f9e93`;
- the running executable SHA-256 is
  `6c7944f78664524c7b037a038f094c538282ccd33e97feaf9804d5de3dd134e2`;
- one frontend process owns the display;
- the current kernel log has no Oops, BUG, panic, internal error, or trace end;
- `SIGUSR1` saved
  `/mnt/plumos-user/Screenshots/plumos-fe-20261025-234120-3159-1.png`;
- the captured TOP page is within 480x320 and all three visible labels remain
  inside their card bounds.

Recoverable backups were saved under:

- `/mnt/plumos-user/Backups/rk2020-live-20261025-143402`;
- `/mnt/plumos-user/Backups/rk2020-live-20261025-143959`.

The safe reboot request did not immediately boot the OS while external power
was present; the unit showed its charging screen until the operator pressed
the power button. Treat reboot-under-charge as a separate, still-open power
lifecycle defect. No further reboot was used for the screenshot-only update.

The remaining physical acceptance gates are:

1. no console text is drawn over the plumOS splash;
2. TOP cards and labels remain inside their bounds;
3. Settings, Help, and all two-line footer explanations fit 480x320;
4. SSID selection, all seven password-keyboard rows, masked password, and
   connection result fit and remain operable;
5. ROM lists keep the selected row visible at every scroll position;
6. input, Wi-Fi, audio, shutdown, and the already separate subsystem gates
   remain functional.
