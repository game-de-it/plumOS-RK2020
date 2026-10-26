# RK2020 live-unmount FAT filesystem repair

## Reason

After the frontend hang was recovered with a long power-button hold, the next
boot logged:

```text
FAT-fs (mmcblk0p3): Volume was not properly unmounted. Some data may be corrupt. Please run fsck.
```

The `PLUMOS_USER` FAT32 partition is mounted at `/mnt/plumos-user`, with its
`roms` directory bind-mounted at `/roms`. Both mountpoints must be detached
before a meaningful repair.

## Live maintenance boundary

The device remained reachable over SSH because Dropbear, its host key, the
Wi-Fi configuration, BusyBox, and `fsck.fat` are outside the user FAT volume.
Before unmounting, FTP, SFTP, and Samba were confirmed stopped and `/proc`
showed no process working directory or open descriptor below
`/mnt/plumos-user` or `/roms`.

For each check the managed frontend and hardware-key service were stopped,
all pending writes were synced, `/roms` was unmounted first, and
`/mnt/plumos-user` second. A recovery trap restored the FAT mount, the bind
mount, the hardware-key service, and the frontend even if a check failed.

## Check and repair result

The first unmounted read-only check used `fsck.fat 4.2 -n -v` and found:

- 5,422 files;
- 80,872 of 3,496,041 clusters in use;
- no cross-linked files, lost chains, or free-cluster-summary damage;
- only the FAT dirty bit from the forced power-off.

The repair pass used `fsck.fat -a -v`. It cleared the dirty bit and wrote the
change. An immediate second `fsck.fat -n -v`, while the partition was still
unmounted, returned status 0 and reported no differences or errors.

The partition was then mounted with its original options:

```text
rw,relatime,fmask=0022,dmask=0022,codepage=936,iocharset=utf8,shortname=mixed,errors=remount-ro
```

`/roms` was restored as the bind mount. The final mount produced only the
existing `utf8 is not a recommended IO charset` advisory; it did not repeat
the dirty-volume warning. Wi-Fi and SSH stayed up, and the hardware-key and
frontend services restarted successfully with one frontend process owning
the display.

Device-side logs are retained on the ext4 app layer at:

- `/mnt/plumos/logs/fsck-plumos-user-readonly-20261026.log`;
- `/mnt/plumos/logs/fsck-plumos-user-repair-20261026.log`;
- `/mnt/plumos/logs/fsck-plumos-user-verify-20261026.log`.
