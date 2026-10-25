# RK2020 boot-behavior correction and SD reflash

Date: 2026-10-25

## Hardware evidence

The second plumOS hardware pass reached the framebuffer frontend and accepted
cursor input, but showed four regressions:

- stock-initramfs diagnostic text remained visible over the plumOS splash;
- the three frontend top-card images remained visually unbalanced;
- the RTL8811CU dongle status remained `MISSING`;
- frontend Shutdown returned to the running system instead of staying off.

The card did complete first-boot provisioning even though the device did not
make that transition sufficiently obvious. On the Mac it contained an 8 GiB
Linux system partition, a 53.4 GB `PLUMOS_USER` partition, and a zero-byte
`.plumos-ready` marker dated 2026-10-25 11:04:58.

## Root causes and corrections

1. The previously staged boot-FAT runtime hotfix was never installed. The
   stock initramfs sources `post-sysroot.sh` before mounting `/storage`, so its
   runtime targets were unavailable. The frontend and Wi-Fi changes are now
   built into a complete image instead of relying on that hook.
2. The stock `prepare_sysroot` test requires
   `/usr/lib/kernel-overlays/base/lib/modules/$(uname -r)`. plumOS carried the
   real matched modules under `/lib/modules/4.4.189` but omitted that stock
   compatibility directory, causing the `NEVER TOUCH boot=` warning and a
   60-second delay. Commit `b42f34f` creates and verifies the sentinel and
   removes boot-hook `/dev/console` diagnostics.
3. Commit `11b466a` centers artwork when a top card has no detail footer.
4. Commit `e536b78` resolves the stock RK2020 module name `8821cu` through its
   `modules.dep` tree while retaining the V90S-derived `0bda:1a2b` USB
   driver-disk ejection sequence.
5. The Pixel2-derived charger path used `restart2("charge")`, which returns to
   the OS on RK2020. Commit `9b2fb53` disables charge-mode reboot by default
   and proceeds to the RK817 DEV_OFF power-off path. The old behavior remains
   an explicit environment opt-in for future hardware validation.
6. Commit `d5a1124` mirrors boot, Wi-Fi, and power diagnostics into
   `PLUMOS_USER/plumos-logs` so the next result can be inspected on macOS.

## Build and host verification

The affected frontend, app layer, release audit, system rootfs, and complete SD
image were rebuilt. The following checks passed:

- strict app-layer verification and licensing audit;
- implementation release audit with zero blockers;
- system-rootfs construction and A/B slot verification;
- stock-initramfs compatibility-sentinel verification;
- first-boot partition fixture for a 16,000,000,000-byte test disk;
- RK2020 network-control, application-layer, power-menu/sleep, system-rootfs,
  and SD-image script test suites;
- complete image SHA-256 verification.

Final image:

- file: `plumOS-RK2020-0.1.0-dev.img`;
- size: 2,701,131,776 bytes;
- source ref: `d5a1124`;
- SHA-256: `586adc025345b4c97a5d7e458a1e34bcefcd17bb4cbe51755bb592c104e30416`.

## Media backup and reflash

Before reflashing, `/dev/disk5` was re-identified as the removable 62.5 GB
built-in SDXC-reader medium with `PLUMOS_BOOT`, Linux system, and
`PLUMOS_USER` partitions. Its Mac-readable user area was copied to
`output/device-backups/2026-10-25-before-rk2020-reflash/PLUMOS_USER`. It
contained only the provisioned directories and the zero-byte ready marker; no
user payload files were present.

Raspberry Pi Imager 2.0.0 wrote the final image to `Apple SDXC Reader Media`
and completed its full-device readback verification successfully. The slow
card sustained approximately 2.5-3.3 MB/s while writing and approximately
25 MB/s while verifying. Imager then auto-ejected the medium. Because the
device disappeared from `diskutil` after auto-eject, no additional mounted
filesystem readback was performed; the completed full-device Imager verify is
the write/readback acceptance evidence for this pass.

## Remaining hardware gates

The rewritten card still requires a physical RK2020 pass. Verify each item
independently:

1. first boot displays the plumOS provisioning frames, expands/creates the
   partitions, and performs its one expected automatic reboot;
2. the `NEVER TOUCH boot=` 60-second warning and plumOS hook diagnostics no
   longer appear over the splash;
3. the three frontend top-card images are visually balanced and cursor input
   remains functional;
4. the dongle changes from `0bda:1a2b` to `0bda:c811`, `8821cu` loads, `wlan0`
   appears, and Wi-Fi scanning works;
5. Shutdown stays powered off, while Reboot remains a distinct working action;
6. unplugged and externally powered shutdown are checked separately;
7. after the pass, inspect `PLUMOS_USER/plumos-logs` before drawing conclusions
   about boot, power, or Wi-Fi failures.

Association, DHCP, SSH, application-network access, audio, emulator routes,
sleep/resume, and power behavior remain separate physical acceptance gates.
