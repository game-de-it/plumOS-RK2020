# RK2020 TI-83 firmware gate

Date: 2026-10-27  
Implementation commit: `b5733de`  
Device: RK2020 at `192.168.10.110`

## Finding

The physically observed tiny text was not TI-83 game output. The previously
captured Numero framebuffer showed its missing-firmware page:

```text
Please add one of the following rom files to your System Directory
ti83se.rom (recommended)
ti83plus.rom
ti83.rom
```

The core renders that message with its fixed small font inside a 640x480
surface. Scaling that error page would improve only the symptom; no calculator
or game can run without one compatible TI ROM.

The ROM-set BIOS tree and `/mnt/plumos-user/bios` were checked first by exact
filename and then against Numero's three published core-info MD5 values. No
candidate was found. Proprietary calculator firmware was not downloaded or
substituted.

## Resolution

The RetroArch launcher now checks for at least one of the three accepted files
before initializing RetroArch. A missing set exits with status 78 and logs the
exact accepted filenames and BIOS directory.

The graphical FE performs the same check before releasing its renderer. It
keeps the ROM list visible and displays this readable status instead of showing
Numero's small-font page:

```text
TI-83 BIOS missing: add ti83se.rom to BIOS
```

This does not claim TI-83 compatibility. Gameplay, controls, display and clean
exit remain open until user-supplied firmware is placed in the BIOS directory.
TI-83 remains enabled and visible in the frontend catalog so it can be tested
without another catalog update once that firmware is supplied.

## Verification

- `tests/test-app-layer-scripts.sh`: `app_layer_scripts=result-ok`
- Clean AArch64 frontend build: `frontend_component=result-ok`
- Managed frontend delta verification: seven files passed
- Live frontend component checksum catalog: all entries passed
- Direct firmware-free launch: status 78 with the expected message
- Post-check RetroArch process count: zero
- FE resumed and remained running
- Full app-layer `sha256sum -c checksums.sha256`: passed

The live component and root manifests report source ref `b5733de`. The
recoverable pre-update archive is:

```text
/mnt/plumos-user/Backups/rk2020-ti83-bios-gate-b5733de/before.tar
SHA-256 b064e9370af1655f0f8df692a1830f479cd0131cfafa559fa717b79c7ebbc15b
```

Temporary deployment files were removed after verification.
