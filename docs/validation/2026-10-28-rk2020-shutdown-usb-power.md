# RK2020 charger-connected shutdown and USB host power

Date: 2026-10-28

## Scope

With the charging cable connected, plumOS initially darkened the screen but
left the external USB Wi-Fi dongle LED continuously lit.  Removing the cable
after shutdown did not clear that LED.  The charge LED was off and the network
was unreachable, so this was residual USB-host power rather than a running OS.

Stock EmuELEC was tested with the same cable-connected shutdown condition and
left the Wi-Fi LED, charge LED, and screen off.  It did not maintain charging
after shutdown.  A short Power press from the faulty plumOS off-state entered
the bootloader charge screen and then darkened again, further distinguishing
the powered dongle rail from an OS reboot.

## Investigation

The deployed frontend path was confirmed in the persistent power log:

```text
power=charger-detected source=power-supply path=/sys/class/power_supply/ac/online value=1
power=prepare-start action=shutdown
power=usb-host-unbound device=ff300000.usb
power=prepare-end action=shutdown
power=charge-mode-disabled action=kernel-poweroff
power=shutdown-method method=kernel-poweroff command=busybox-poweroff-f
```

The live regulator and GPIO state identified two distinct parts of the USB
power path:

```text
vcc_host   state=enabled  num_users=0
boost      state=enabled  num_users=0
otg_switch state=disabled num_users=0
gpio-15    vcc_host       out hi
GPIO0_DR=0x0004a000
```

The stock DT declares `/vcc_host` as a fixed 5 V `regulator-always-on` supply
controlled by GPIO0-15.  The kernel power-off path stops the RK817 side but did
not lower this fixed-regulator GPIO, allowing the Wi-Fi dongle to remain lit
after the SoC stopped.

## Controlled physical proof

The normal plumOS shutdown preparation was run with the cable connected.  Only
after display owners, the frontend, the DWC2 host, and writable filesystems had
been stopped, GPIO0-15 was changed from High to Low:

```text
before=0x0004a000
after=0x00042000
```

The kernel power-off syscall then stopped the unit.  The operator observed all
three outputs off: Wi-Fi LED, charge LED, and display.  This one-time test made
no persistent configuration change; boot restored GPIO0-15 High and normal
Wi-Fi operation.

## Implementation

Commit `83fa361` adds the verified sequence to
`plumos-safe-shutdown`:

1. complete the existing display, service, USB-host, filesystem, and sync
   preparation;
2. read GPIO0 DR at `0xff040000`;
3. clear only the GPIO0-15 mask `0x8000`;
4. read the register back and require that the bit is Low;
5. request the stock kernel's full power-off sequence.

If the GPIO operation is unavailable or readback fails, the failure is logged
and the existing kernel power-off fallback remains available.  Terminal-only
tests do not modify the GPIO.

The focused regression test covers the exact
`0x0004a000 -> 0x00042000` transition, readback, ordering before power-off, and
the terminal-test exclusion.  Shell syntax and the focused power-menu/sleep
test pass.

## Managed deployment

Only the changed frontend payload and its metadata dependency closure were
deployed:

```text
bin/plumos-safe-shutdown
components/frontend/checksums.sha256
components/frontend/manifest.json
licenses/component-manifests/frontend.json
manifest.json
checksums.sha256
```

The hybrid root checksum index preserved the other live component versions
instead of replacing unrelated binaries from the host build.  Post-deployment
verification passed:

```text
source_ref=83fa361
frontend_ok=202
root_ok=11290
failed=0
```

The prior six-file state is recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-vcc-host-83fa361-before/before.tar
```

## Physical result

The final production-path test used the frontend Shutdown action with
`ac/online=1`, battery status `Full`, Wi-Fi active, and the charging cable left
connected.  After shutdown the operator confirmed:

- Wi-Fi LED: off;
- charge LED: off;
- display: off;
- no reboot or automatic charge-screen transition.

The charger-connected shutdown gate now matches the observed stockOS terminal
state.  Cable-disconnected shutdown remains a separate post-change regression
gate because the same final GPIO transition is shared by both conditions.
