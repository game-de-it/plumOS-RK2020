# RK2020 existing user-volume reuse after reimage

Date: 2026-10-31

## Observation

The operator flashed the release image built from `80bdc31` and completed the
visible first-boot and Wi-Fi setup. Before transferring ROMs to this freshly
booted installation, the frontend displayed an existing library.

Read-only inspection of the running device at `192.168.10.110` established:

- `/mnt/plumos-user/roms` contained 227 files and used 428000 KiB;
- `/roms` was the bind mount of the same p3 FAT32 volume;
- the frontend index named those real paths under
  `/mnt/plumos-user/roms`, rather than showing host-side cached entries;
- the first-boot log expanded p2 to 8 GiB and recreated p3 from sector
  17858560 through the end of the card; and
- the log proceeded directly from `resize-system-ext4` to
  `seed-user-directories`, with no `format-user-fat32` stage.

The ROMs were therefore real files on the physical SD. They were neither a
FileZilla directory-list cache nor content embedded in the release image.

## Cause

The compact release image contains p1 and the initial p2 only. Writing it
replaced the MBR and the image-covered sectors but did not overwrite the old
p3 FAT32 structures beyond the image boundary. First-boot provisioning
recreated p3 at the same fixed start sector. It then detected `TYPE=vfat` and
`LABEL=PLUMOS_USER`, skipped formatting, and reused the existing filesystem.

This behavior follows the non-destructive branch in
`rootfs/rk2020/usr/sbin/plumos-first-boot-provision`. It explains the observed
result but is not a recovery guarantee: writer behavior, geometry changes,
filesystem damage, or physical media failure can still destroy or hide the
data.

The device was inspected read-only for this diagnosis. No ROM, save, setting,
partition, or live metadata was changed.
