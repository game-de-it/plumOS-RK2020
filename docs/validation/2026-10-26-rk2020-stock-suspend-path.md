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

## Physical validation still required

On stockOS:

1. short-press Power and confirm the display and backlight turn off;
2. wait at least five seconds and short-press Power again;
3. confirm the same EmulationStation session returns without a reboot;
4. verify controls, audio, brightness, Wi-Fi association, and SSH after wake;
5. capture the systemd sleep journal and `dwc2`/USB re-enumeration messages.

Repeat powered and unpowered cases separately.  Only after the stock result is
captured should the minimum plumOS live patch be selected and tested; a full
SD-image rebuild is not needed for this iteration.
