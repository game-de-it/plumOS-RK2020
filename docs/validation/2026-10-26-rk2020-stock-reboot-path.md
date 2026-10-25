# RK2020 stockOS reboot path comparison

## Scope

The operator reported that plumOS reboots normally with the external USB
cable removed, but stops at the charging screen when the cable is connected.
The same RK2020 reboots into stockOS while externally powered.  This inspection
was read-only and did not request a reboot or modify the stock SD card.

## Observed stockOS

- OS: EmuELEC 4.8, build
  `5a3e0877546318dd70cd001563e57bfb78328a6b`;
- kernel: Linux 4.4.189;
- PID 1: systemd 252.6;
- frontend: `/usr/bin/emulationstation`, SHA-256
  `4c9c928daecb66d1d5ebbe20d8fe86147ed30b7045dfb4e32d351538c47503c2`;
- frontend unit: `emustation.service`;
- live external-power state during inspection: `ac/online=1`, battery status
  `Full`, capacity `100`;
- live Wi-Fi dongle: USB `0bda:c820`, driven by `rtl8821cu` and `btusb`.

## Stock reboot chain

The EmulationStation binary contains the `RESTART SYSTEM` action and the exact
command string `systemctl reboot`.  Its combined-event contract emits
`quit reboot` before the terminal action, but the installed example event
script only logs the event and does not perform the reboot.

The resulting stock path is:

1. EmulationStation requests `systemctl reboot`.
2. systemd PID 1 isolates `reboot.target`.
3. `systemd-reboot.service` requires `shutdown.target`, `umount.target`, and
   `final.target`.
4. `systemd-shutdown` synchronizes filesystems and block devices, unmounts the
   remaining filesystems, and performs its normal reboot operation.

The stock `reboot`, `poweroff`, and `shutdown` commands are all symlinks to
`/usr/bin/systemctl`.  No stock script or unit using `/proc/sysrq-trigger`,
`reboot -f`, `restart2`, or a charge-mode reboot helper was found.  There are
also no installed `system-shutdown` hooks that replace the final reboot.

## Difference from current plumOS

`plumos-safe-shutdown --reboot` already stops display owners, unmounts the ROM
and user filesystems, and calls `sync`.  Its final action differs from stock:
when `/proc/sysrq-trigger` is writable it writes `b`, which invokes the
kernel's emergency restart immediately.  BusyBox `reboot -f` is only the
unreachable fallback after that write.

The physical results line up with that distinction:

- plumOS emergency restart: boots normally without external power, but the
  reported externally powered case entered the charging screen;
- stockOS orderly systemd reboot: the operator reports that it returns to the
  OS even while externally powered.

This is strong evidence that plumOS should stop preferring SysRq `b` and use a
normal reboot syscall after its existing cleanup.  It is not yet a completed
A/B proof: the stock reboot was not triggered during this read-only session,
and the proposed plumOS path has not yet been deployed or tested in both
powered and unpowered states.

## Next validation

Apply the smallest live change to the plumOS reboot branch only, preserving
the current stop/unmount/sync sequence.  Then test these as separate gates:

1. Reboot with the external USB cable removed.
2. Reboot with external power present and `ac/online=1`.
3. Confirm that both return directly to plumOS without a power-button press.
4. Confirm that Shutdown still powers off correctly in its powered and
   unpowered cases.

Do not rebuild the full SD image until this live A/B result and the remaining
frontend layout checks have converged.
