# RK2020 NextCommander display correction

Date: 2026-10-27

Device: RK2020 at `192.168.10.110`

## Report and diagnosis

The physical File Manager view used oversized content extending beyond the
screen. A direct pre-change scanout showed the divider at x=320 on a 480-pixel
landscape frame, leaving only 160 pixels of the right panel visible and hiding
the lower part of the 640x480 software surface.

The RK2020 DRM renderer reports a 480x320 logical surface after its quarter
turn. The NextCommander port instead called `setPhysicalResolution(640, 480)`
and allocated a 640x480 SDL surface. Commit `9990891` replaces both constants
with `plumos_fbdev_logical_width()` and `plumos_fbdev_logical_height()` so the
application layout and scanout use the same dimensions.

## Build and targeted checks

- the patched upstream source rebuilt successfully for AArch64;
- the NextCommander component checksum set passed;
- `tests/test-app-layer-scripts.sh` passed;
- the strict app-layer build and license audit passed; and
- a regression assertion rejects the former hard-coded 640x480 resolution.

The corrected binary is:

```text
14cc1d40331d62f37b09bbeaef4cf6e1393c1da8d6ff71109bc51ea055392dea  apps/nextcommander/bin/NextCommander
```

## Managed live deployment

The live update was limited to six managed files: the NextCommander binary,
its component checksum and manifest pair, the component-manifest license copy,
and the root manifest/checksum pair. The transferred bundle and managed delta
passed SHA-256 verification before activation. After activation, the full
NextCommander component and full app layer passed device-side checksum
verification. The root manifest reports source ref `9990891`.

The prior six files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-nextcommander-9990891-before/before.tar
SHA-256 97c1faf6fbf937b6fbaf85ced90d9e7750db07092585ae445eb5a7af7192ee20
```

User settings and user files were not overwritten. The temporary live-deploy
stage and capture tools were removed after verification.

## Display and physical acceptance

The Git-ignored evidence directory is
`output/live/2026-10-27-rk2020-nextcommander-ui/`. The corrected renderer PNG
shows the complete 480x320 view with two equal-width panels and the footer:

```text
0a26923d0d1abee99bae026ff32c24b77c6a8512362afb4bbb92e91b55ff7934  nextcommander-after.png
```

The operator accepted the corrected File Manager display and controls, then
successfully copied a file. NextCommander was terminated, FE started as PID
13113, and the FE executable remained alive. File Manager is therefore a
physical functional pass, including its mutating copy path.

The operator also reported that scraping works. Scraping is recorded as a
separate physical functional pass rather than inferred from the File Manager
result.
