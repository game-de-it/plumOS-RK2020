# RK2020 stockOS suspend path comparison

## Scope

This is a read-only inspection of the running EmuELEC 4.8 stockOS.  It records
the configured suspend and wake path before a physical sleep/resume test.  No
suspend request or stock SD modification was made during this inspection.

## Active stockOS path

`odroidgoa-hotkeys.service` runs `/usr/bin/oga_events.py`.  On a normal RK817
Power-key event, the daemon executes:

```text
/bin/systemctl suspend
```

Holding the configured F5 modifier changes the action to poweroff.  The daemon
sets `need_to_swallow_pwr_key` before entering suspend, so the Power-key event
which resumes the machine is consumed instead of immediately suspending it a
second time.

The installed EmulationStation binary also contains a `SUSPEND SYSTEM` action
which references `/usr/bin/pm-is-supported --suspend` and
`/usr/sbin/pm-suspend`.  Both helpers are absent on this image.  Therefore the
physical Power-key/systemd path is the installed, testable suspend contract;
the compiled menu path should not be treated as evidence that pm-utils sleep
is available.

## systemd and kernel contract

The effective systemd configuration includes
`/storage/.config/sleep.conf.d/sleep.conf` with:

```ini
[Sleep]
AllowSuspend=yes
SuspendState=mem standby freeze
```

The kernel advertises `freeze mem disk`.  systemd therefore selects `mem`
first and writes it to `/sys/power/state` through
`systemd-suspend.service`/`systemd-sleep`.

The RK817 Power key is `/dev/input/event0` and its parent PMIC device reports
`power/wakeup=enabled`.  The live wakeup counter was readable, and the wakeup
source table did not show an active Wi-Fi suspend blocker at inspection time.
This establishes configuration, not a completed resume test.

## Stock pre/post hook

`/usr/lib/systemd/system-sleep/sleep` performs the device-specific work:

Before suspend:

1. unload `esp8089` on the v1.1 variant;
2. save ALSA state to `/tmp/asound.state`;
3. unload `dwc2` as a documented controller workaround;
4. stop `odroidgoa-headphones.service`.

After resume:

1. restore ALSA state;
2. remove any remaining `dwc2` instance and load `dwc2` again;
3. reload `esp8089` on the v1.1 variant;
4. restart the headphone service, which reapplies audio, brightness, and
   headphone state.

On the inspected RK2020, `dwc2`, `8821cu`, and `btusb` were loaded and the
USB `0bda:c820` Wi-Fi dongle was attached to that host controller.  Recreating
the USB host after resume is therefore directly relevant to Wi-Fi recovery.

## Difference from current plumOS

Current plumOS writes `mem` directly after arming the RK817 helper, RTC wake,
display blanking, and a post-resume Wi-Fi recovery guard.  It does not detach
or unload `dwc2` before the kernel suspend request.  The stock hook identifies
that missing pre-suspend USB-host quiesce as a concrete comparison point.

Do not copy the stock script verbatim.  A plumOS change must preserve its
single-display-owner and power-overlay contracts, avoid overwriting user
configuration, and make the USB-host transition bounded and recoverable.

## Physical validation result

The user performed a stockOS suspend and wake cycle on the physical RK2020.
The display returned after the wake action, so the visible suspend/resume path
passed without an observed reboot or boot screen.

The network side did not recover automatically during the immediate
observation window.
Starting just after the reported wake, the Mac polled `192.168.10.110` 24 times
for about 90 seconds.  Every ICMP probe failed and SSH never became reachable.
The Mac retained the pre-suspend ARP entry `40:ed:00:3b:42:84`, but the route
was marked `REJECT`; this is not evidence that the dongle re-enumerated.

The user then switched networking off and on in EmulationStation.  Wi-Fi
associated about six seconds later and `192.168.10.110` became reachable
again.  The boot ID remained
`dd8d6712-d5c5-452c-9d8e-7ea8412a6dc3`, EmulationStation remained PID 1279,
and `oga_events.py` remained PID 378.  This confirms a resume of the same OS
and frontend session rather than a reboot.

The recovered journal shows the complete failure sequence:

1. the stock pre-sleep hook removed `dwc2`, disconnected USB device `0bda:c820`,
   and removed `wlan0`;
2. the kernel completed `mem` suspend and resume without an Oops;
3. the post-sleep hook loaded `dwc2` and the dongle re-enumerated successfully;
4. the Realtek driver recreated `wlan0`, but reported
   `rtw_halmac_txfifo_wait_empty` followed by `rtw_hal_init: fail`;
5. the interface consequently stayed down and unassociated;
6. the ES off/on action ran ConnMan's Wi-Fi disable/enable path, after which
   authentication, association, WPA key negotiation, IPv4 restoration, and an
   external ping all succeeded.

The observed result must therefore be recorded as separate gates:

- display suspend and visible resume: pass;
- same kernel and frontend session after resume: pass;
- DWC2 and USB-device re-enumeration: pass;
- automatic USB Wi-Fi association and SSH recovery: fail;
- manual ES network off/on recovery: pass.

This makes the stock `dwc2` reload hook relevant but not sufficient evidence
for this particular `0bda:c820` dongle.  A plumOS implementation should use a
bounded USB-host reset followed by an explicit Wi-Fi rebind/reassociation
check rather than assuming that reloading `dwc2` restores networking.  The
current plumOS resume worker already performs a bounded interface/IP check and
calls its Wi-Fi recovery path, which restarts the local WPA/DHCP stack.  That
existing automatic equivalent of the successful ES toggle should be tested on
hardware before adding another forced controller reset.

## Physical validation still required

On stockOS, finish the unobserved gates without repeating the successful
display-only conclusion:

1. verify controls, audio, and brightness after wake;
2. compare a suspend cycle without external USB power.

On plumOS, verify that the existing post-resume Wi-Fi recovery worker restores
this dongle without an ES off/on action, and capture the power, USB-host, Wi-Fi
recovery, and network-control logs if it does not.

Repeat powered and unpowered cases separately.  The powered stock result is
now captured; the next step is a plumOS live-device test of its existing
recovery path.  A full SD-image rebuild is not needed for this iteration.
