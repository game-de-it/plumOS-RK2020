# RK2020 plumOS suspend/resume validation

## Scope

This records two powered `mem` suspend/resume cycles on the physical RK2020
running the stock Linux 4.4.189 kernel with the plumOS app layer.  The USB
`0bda:c820` Wi-Fi dongle and external power remained connected.  The test used
the frontend Sleep action and a physical Power-key wake.

## First cycle: black backlight

The first cycle returned to the same kernel and frontend session, and Wi-Fi
recovered automatically, but the display remained black.  SSH showed:

- unchanged boot ID `8bcc5785-eda7-4607-b6bd-51cc21dffeea`;
- unchanged frontend PID 1032 and hardware-key PID 887;
- active VOP/DRM mode and a live frontend `/dev/dri/card0` descriptor;
- restored brightness 28, but `bl_power=4`.

The power log showed that the pre-sleep value was already `bl_power=4` while
the panel was visibly active.  The old resume code saved that stale value and
wrote it back after wake, turning the PWM backlight off after DRM had resumed.
Writing `0` to `bl_power` immediately restored the visible frontend without
restarting it.

Commit `75aeacf` changes wake handling to request `FB_BLANK_UNBLANK` (`0`)
unconditionally while restoring brightness separately.  The updated
`plumos-safe-shutdown`, app-layer checksum, and manifest source reference were
applied atomically to the test SD and verified by SHA-256 before the second
cycle.

## Second cycle: pass

The second powered cycle visibly resumed.  The user confirmed that the screen
lit normally after pressing Power.  Remote checks then confirmed:

- the same boot ID, frontend PID, and hardware-key PID;
- brightness and actual brightness both 28;
- `bl_power=0`;
- no kernel panic, Oops, or call trace;
- the same Wi-Fi SSID and `192.168.10.110` address after automatic recovery.

The kernel reported 5.443 seconds in suspend.  The plumOS USB recovery worker
then forced DWC2 host mode, rebound `ff300000.usb`, and re-enumerated the
`0bda:c820` dongle about 13 seconds after kernel resume.  The user observed the
dongle LED begin flashing after roughly 10 seconds, consistent with that
sequence.  WPA/DHCP recovery succeeded on the third bounded attempt; IPv4 was
available about 24 seconds after kernel resume.  No manual network toggle or
physical dongle reinsertion was required.

## Remaining sleep gates

Display and automatic Wi-Fi recovery now pass in the externally powered case.
The sleep log independently shows that `plumos-rk817-resume` does not yet match
the RK2020 mixer control layout, so audible output after wake remains a
separate unresolved gate.  Controls, an active game/emulator session, and an
unpowered suspend cycle also require physical validation.
