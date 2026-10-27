# RK2020 in-game power overlay DRM handoff

## Scope

The reported foreground failure was corrected from PPSSPP to RetroArch: while
a RetroArch game owned the DRM display, the power-menu frontend started but its
plane remained behind the game.  The same ownership conflict can affect other
direct-DRM application routes, so the fix is shared rather than emulator
specific.

The display handoff preload is enabled for RetroArch, PicoArch, standalone
emulators, DraStic's AArch64 display runner, PICO-8, PortMaster, Pyxel,
NextCommander, and Music Player.  DraStic's ARMHF game process explicitly
removes the AArch64 preload while its display runner retains it.

## Implementation

The stock Linux 4.4 kernel returns `ENOSYS` for `pidfd_getfd`, so the hardware
daemon cannot duplicate a game's DRM descriptor that way.  The new
`libplumos-display-handoff.so` preload instead exposes the owning process's
exact `/dev/dri/card0` descriptor over a per-process Unix socket and validates
the requester with `SO_PEERCRED`.

For the power overlay, the hardware daemon now:

1. obtains the DRM descriptor through the broker, with the pidfd path retained
   as a fallback;
2. stops the display owner and saves the connector/CRTC/mode/framebuffer plus
   its active planes, then disables those planes;
3. drops DRM master and runs the overlay frontend;
4. reacquires DRM master, restores the connector/CRTC mode and DPMS state,
   restores the saved planes, and resumes the owner.

The framebuffer frontend also requests DRM master explicitly during renderer
initialization.

## Build and host verification

Commit `b50a7f5` contains the implementation.  The following checks passed:

- frontend component build;
- AArch64 broker descriptor-transfer test in the Linux build container;
- `tests/test-rk2020-power-menu-sleep.sh`;
- `tests/test-app-layer-scripts.sh`;
- shell syntax checks for every changed launcher;
- rebuilt frontend, PicoArch, standalone, Pyxel, NextCommander, Music Player,
  and PortMaster components;
- complete app-layer checksum and license audit.

## Live RetroArch evidence

RetroArch/PicoDrive PID 15647 exposed
`/run/plumos/display-handoff/15647.sock`.  Triggering the same daemon action as
the physical power key produced:

```text
hardware-keys: drm-master=broker owner=15647 fd=6 rc=0
hardware-keys: drm-planes=suspend owner=15647 count=2
hardware-keys: drm-master=drop owner=15647 fd=6 rc=0
```

The game was stopped while the overlay ran.  Cancelling the overlay produced:

```text
hardware-keys: drm-master=restore owner=15647 rc=0
hardware-keys: drm-planes=restore owner=15647 count=2 rc=0
hardware-keys: display-owner=resume owner=15647
```

RetroArch returned to a sleeping/runnable process state rather than remaining
stopped.  This proves descriptor handoff and restoration, but a human-visible
check that the menu is physically in front remains a separate acceptance gate.

## Managed live deployment

The frontend binary, daemon, preload library, and RetroArch launchers were
deployed first with their frontend metadata.  The remaining shared routes were
then deployed as seven launcher changes with component manifests, their
license-manifest mirrors, component checksum indexes, and the root manifest
and checksum index.  Rebuilt emulator/application binaries with unrelated or
non-deterministic differences were deliberately not deployed.

All six affected non-frontend component checksum sets and the complete live
app-layer checksum set passed after activation.  The root manifest now reports
source ref `b50a7f5`.  The pre-route-deployment state is recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-power-overlay-b50a7f5-routes-before/before.tar
SHA-256 1f9fcf1ae9c944cd64ec9422263104a0f18c675f7aaad200faa09df1388920fa
```

The direct test game was terminated after verification and the frontend was
restored successfully as PID 16843.

## PPSSPP Cancel regression and output restore

On 2026-10-27, opening the power menu over PPSSPP and cancelling with B left
both the panel and audible output absent.  PPSSPP PID 24763 was still runnable,
the ALSA playback stream remained `RUNNING`, and its hardware pointer advanced.
A direct capture also contained the game frame.  The externally visible fault
was instead:

```text
/sys/class/drm/card0-DSI-1/enabled=disabled
/sys/class/drm/card0-DSI-1/dpms=Off
/sys/class/backlight/backlight/bl_power=0
```

The earlier plane-only handback therefore restored framebuffer contents but
not the connector/CRTC state disabled during overlay shutdown.  Commit
`3ca6a2f` snapshots the active output before handoff, calls `drmModeSetCrtc`
after reacquiring DRM master, and forces the connector DPMS property to On
before restoring the planes.

The managed seven-file frontend delta passed its component checksum and the
complete live app-layer checksum.  The root manifest reports source ref
`3ca6a2f`.  Its prior state is recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-drm-output-3ca6a2f-before/before.tar
SHA-256 586da0a4a5371051b0fdfcd26dbb775a6a717267c6bee183b5c3a70c38ff2711
```

After a clean PPSSPP relaunch, automatic Cancel through the production
hardware-daemon path produced:

```text
hardware-keys: drm-output=snapshot owner=28191 rc=0
hardware-keys: drm-master=drop owner=28191 fd=9 rc=0
hardware-keys: drm-master=restore owner=28191 rc=0
hardware-keys: drm-output=restore owner=28191 rc=0
hardware-keys: drm-planes=restore owner=28191 count=1 rc=0
hardware-keys: display-owner=resume owner=28191
```

The connector remained `enabled` with DPMS `On`, the same PPSSPP process
survived, and ALSA stayed `RUNNING`.  The operator then repeated the real
Power-menu/B sequence and confirmed that PPSSPP returned with both display and
audio normal.

## Cross-emulator Cancel matrix

Commit `21db8c5` adds a focused regression matrix which invokes the production
hardware daemon and replaces only the physical B selection with an automatic
Cancel.  It avoids repeating every core while covering each distinct display
runtime family requested by the operator.  The final device run passed:

| runtime family | route | output snapshot/restore | connector | same process | scanout | audio |
|---|---|---:|---:|---:|---:|---:|
| RetroArch | `retroarch:fceumm` | PASS | PASS | PASS | PASS | PASS |
| PicoArch/fbdev | `picoarch:quicknes` | N/A | PASS | PASS | PASS | PASS |
| Mupen64Plus standalone | `standalone:mupen64plus` | PASS | PASS | PASS | PASS | PASS |
| DraStic split runner | `standalone:drastic` | PASS | PASS | PASS | PASS | PASS |
| OpenBOR standalone | `standalone:openbor` | PASS | PASS | PASS | PASS | PASS |

PicoArch does not expose a direct DRM owner on this route, so connector/CRTC
handoff is not applicable; its game process, connector, scanout, and audio
still survived Cancel.  The legacy capture path exposes an active
panel-sized plane but GPU framebuffer readback can be black, so the scanout
column proves active KMS state rather than pixel colors.  PPSSPP supplies the
separate physical visible/audible acceptance.

Evidence is retained in the ignored validation output at:

```text
output/validation/rk2020-power-cancel-2026-10-27-final/
```

The test ended with no emulator process left behind, the production hardware
daemon running as PID 12004, FE restored as PID 12126, and DSI
`enabled`/DPMS `On`.

## Remaining focused gate

- A PortMaster game uses the same shared handoff preload but remains a separate
  application-route check.  It is not needed to close the requested
  cross-emulator Cancel regression.

The five emulator checks cover the changed display-handoff dependency
boundary; the full 73-system matrix does not need to be repeated.

## RetroArch in-game Sleep acceptance

The first two physical attempts did not enter suspend.  The live overlay log
reported `selection=cancel`, the power log had no new `sleep=enter`, game audio
continued, and the backlight remained at `bl_power=4`.  The overlay had not
loaded `config/system/input-map.env`, so the RK2020 physical A button
(`BTN_EAST`) was interpreted as B/Cancel instead of the configured
`east-confirm` action.  Closing the overlay could also leave the panel blank
even though the game continued.

Commit `748864f` runs the overlay frontend through
`plumos-run-with-input-map`, distinguishes a present selection file in the
log, and explicitly unblanks the RK2020 backlight after the parent daemon
restores the game's DRM planes.  Its frontend component and complete live
app-layer checksum sets passed after managed deployment.

The subsequent physical run reported:

- the Wi-Fi dongle LED turned off after selecting Sleep;
- Power woke the same session;
- the resumed RetroArch game accepted controls; and
- the game then exited normally.

The corresponding live evidence is:

```text
menu end rc=0 selection_file=present selection=sleep
sleep=enter backend=mem
sleep=resume backend=mem
sleep=display-unblank brightness=14 bl_power=0 saved_bl_power=4
hardware-keys: drm-master=restore owner=20274 rc=0
hardware-keys: drm-planes=restore owner=20274 count=2 rc=0
hardware-keys: display-unblank owner=20274 rc=0
hardware-keys: display-owner=resume owner=20274
```

The frontend did not return after this particular run because the validation
launcher had intentionally stopped FE and started RetroArch directly over SSH;
there was no suspended frontend process to resume.  This is a test-harness
artifact rather than evidence against the normal FE-owned launch route.  FE
was restored afterward as PID 24221.  A normal FE launch/exit remains the
focused confirmation for frontend return; repeating the suspend cycle is not
required for that check.

The pre-deployment state for the input-map/backlight correction is recoverable
from:

```text
/mnt/plumos-user/Backups/rk2020-power-overlay-input-748864f-before/before.tar
SHA-256 d776358845b066a2205f8b5bcbb3583327fe768b5441907d43fecdc6273498f8
```
