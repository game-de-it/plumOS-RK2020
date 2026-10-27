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

## Initial investigation

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
controlled by GPIO0-15.  This led to the initial hypothesis that the GPIO had
to be lowered before kernel power-off.

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

## Initial implementation

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

The production-path test used the frontend Shutdown action with
`ac/online=1`, battery status `Full`, Wi-Fi active, and the charging cable left
connected.  After shutdown the operator confirmed:

- Wi-Fi LED: off;
- charge LED: off;
- display: off;
- no reboot or automatic charge-screen transition.

The charger-connected shutdown gate matched the observed stockOS terminal
state.  The cable-disconnected gate did not: screen and network stopped, but
the Wi-Fi LED remained continuously lit.

## Cable-disconnected counter-evidence

Three controlled cable-disconnected tests disproved the GPIO-only diagnosis:

1. DWC2 unbound, GPIO0-15 Low, RK817 boost disabled, then normal kernel
   power-off: Wi-Fi LED remained lit.
2. DWC2 unbound, GPIO0-15 Low, then direct RK817 DEV_OFF: Wi-Fi LED remained
   lit.
3. While Linux was still running, DWC2 was unbound, GPIO0-15 was Low, and
   boost was disabled for ten seconds: Wi-Fi LED remained lit. Restoring all
   three returned Wi-Fi normally.

The observed register transitions succeeded, so repeating those same rail
operations is not a useful next experiment.

## Read-only stockOS comparison

Stock EmuELEC 4.8 was inspected while running from the original stock SD; no
files or services were changed. With the cable disconnected, its normal
Shutdown was physically confirmed to turn the Wi-Fi LED off.

The stock power-key handler only runs `systemctl poweroff`. No RK2020-specific
systemd stop unit, udev rule, or final shutdown hook manipulates `vcc_host`,
RK817 boost, or the DWC2 binding. Immediately before stock shutdown:

```text
ff300000.usb -> dwc2 (bound)
1-1:1.0      -> btusb
1-1:1.1      -> btusb
1-1:1.2      -> rtl8821cu
vcc_host     state=enabled
boost        state=enabled
gpio-15      vcc_host out hi
```

The running stock kernel exports all three relevant shutdown symbols:

```text
usb_hcd_platform_shutdown
dwc2_driver_shutdown
rtw_dev_shutdown [8821cu]
```

This reveals the material difference: plumOS unbound DWC2 before invoking the
kernel power-off syscall, while stock leaves the USB host and Wi-Fi interfaces
bound for the kernel `device_shutdown()` pass. Lowering `vcc_host` before that
pass can likewise prevent the Realtek device from completing its orderly
power-down.

## Revised candidate

The host-side shutdown candidate now matches stock's device lifetime:

1. stop display/frontend owners and unmount writable content as before;
2. do not release or unbind DWC2;
3. do not lower GPIO0-15 before kernel shutdown;
4. call the normal kernel power-off path with the Realtek interface still
   bound, allowing `rtw_dev_shutdown` and the remaining device callbacks to
   run.

Commit `6004700` implements this revised path.  A six-file managed delta was
deployed without replacing unrelated live component versions:

```text
bin/plumos-safe-shutdown
components/frontend/checksums.sha256
components/frontend/manifest.json
licenses/component-manifests/frontend.json
manifest.json
checksums.sha256
```

The deployed script SHA-256 is
`4fe96d589ea134b48d7787025e941168bbe14e6a41591e127dfb4147c4db56f2`.
Pre-shutdown verification passed:

```text
source_ref=6004700
frontend_ok=202 failed=0
root_ok=11290 failed=0
```

The previous six-file state is recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-usb-shutdown-6004700-before/before.tar
```

## Revised physical result

With the charging cable disconnected, the live device reported
`ac=0`, `usb=0`, battery `Discharging`, DWC2 bound, and the Wi-Fi interface
bound to `rtl8821cu`.  The operator then selected frontend Shutdown and
confirmed that the display and all LEDs turned off.

The cable-disconnected gate is accepted.

For the separate cable-connected retest, the live pre-shutdown state was:

```text
ac=1
usb=0
battery=Charging
current=401000
dwc2=bound
wifi=rtl8821cu
script=4fe96d589ea134b48d7787025e941168bbe14e6a41591e127dfb4147c4db56f2
```

The operator selected frontend Shutdown while leaving the cable connected and
confirmed that the display, Wi-Fi LED, and charge LED all turned off.  There
was no reboot or charge-screen transition.

Both cable-disconnected and cable-connected Shutdown gates are accepted.  The
final behavior matches the observed stockOS terminal state without pre-emptive
DWC2 unbind, RK817 boost writes, or `vcc_host` GPIO manipulation.
