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
2. stops the display owner and saves/disables its active planes;
3. drops DRM master and runs the overlay frontend;
4. reacquires DRM master, restores the saved planes, and resumes the owner.

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

## Remaining physical gates

- Launch a RetroArch game, short-press Power, confirm that the menu is in
  front, cancel it, and confirm that the same game resumes visibly.
- Repeat the focused foreground/cancel check with one standalone direct-DRM
  route and one PortMaster game.
- Check DraStic separately because its ARMHF game and AArch64 display runner
  are split processes.

These focused checks cover the changed display-handoff dependency boundary;
the full emulator matrix does not need to be repeated unless one of them
reveals a shared regression.
