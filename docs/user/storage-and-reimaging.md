# SD card storage and reimaging

[日本語](storage-and-reimaging.ja.md)

## Partition layout

The RK2020 release image is a compact seed. It contains only `PLUMOS_BOOT` and
the initial `PLUMOS_SYS`. First-boot provisioning expands `PLUMOS_SYS` to
8 GiB and prepares the remaining space as the FAT32 `PLUMOS_USER` volume.

`PLUMOS_USER` stores user content such as ROMs, BIOS files, artwork, music, and
saves.

## Why old files can reappear after reimaging

ROMs that were not copied after flashing a new compact image can sometimes
appear again on `PLUMOS_USER`. This is not a host file-list cache and does not
mean that the release image contains ROMs.

A compact image is shorter than the complete SD card and normally does not
overwrite sectors beyond the end of the image. If the previous
`PLUMOS_USER` FAT32 filesystem remains there and the new p3 begins at the same
sector, plumOS can recognize that filesystem. When its type is `vfat` and its
label is `PLUMOS_USER`, first-boot provisioning skips formatting, adds any
missing standard directories, and reuses the existing contents.

The partition table is a map of storage offsets and lengths. Replacing that
map does not itself erase a FAT, directory entries, or file data located beyond
the written image. Recreating p3 at the same starting offset can therefore make
the old filesystem visible again.

Other plumOS devices can show the same behavior when they use the same compact
seed layout, fixed user-partition offset, and existing-FAT preservation policy.
Partition geometry and provisioning behavior are device- and release-specific,
so this is not a family-wide guarantee.

## This is not a data-retention feature

Do not treat this behavior as a backup or recovery guarantee. `PLUMOS_USER`
may be unavailable or lost when:

- the imaging tool erases, discards, or zero-fills the complete card;
- the new image overwrites the previous `PLUMOS_USER` area;
- a release changes the user-partition offset or filesystem format;
- the FAT32 filesystem is damaged; or
- the SD card itself fails.

Reimaging also replaces `PLUMOS_SYS`. Runtime state and settings stored there
are not covered by the possible preservation of `PLUMOS_USER`.

Keep separate backups of important ROMs, saves, BIOS files, and settings. A
fully clean-card test requires explicitly erasing the complete card before
flashing. A full-card erase is destructive, so verify the target device first.
