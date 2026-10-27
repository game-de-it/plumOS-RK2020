# RK2020 audio route and volume hotkey validation (2026-10-26)

## Scope

Restore audible output on the stock Linux 4.4.189 RK2020 and match the stockOS
volume-control contract on hardware without dedicated volume buttons.  The
work was deployed to the live plumOS SD installation without rebuilding the
full image or interrupting the running NES process.

## StockOS evidence and correction

The inspected EmuELEC 4.8 image has SHA-256:

```text
00f83164472c093c1272b9385a57a28113a59d14d28d11a0bf21e81445d45b58
```

The first static inspection found the generic OGA F5 branch in
`oga_events.py` and incorrectly treated evdev code 708 as an available RK2020
button. The RK2020 has no physical OGA F5/Plus button. The operator then
confirmed the actual EmuELEC behavior on this unit:

- L2 + Up/Down changes volume;
- L2 + Left/Right changes brightness.

The live device tree and evdev scan order identify physical L2 as code 706
(`BTN_TRIGGER_HAPPY3`, compact udev button 12) and R2 as code 707 (compact
button 13). Codes 705/F2 and 708/F5 occupy scan-order slots but have no
corresponding physical RK2020 button.

Stock volume changes execute `amixer set Playback <percent>%`.  Stock route
selection reads GPIO 86 and sets the RK817 `Playback Path` control to `HP`
when the GPIO is high or `SPK` otherwise.  The live RK2020 reported GPIO 86 as
zero, so its correct built-in-speaker route is `SPK`.

## Failure and fix

The running RetroArch process owned an active PCM stream, but read-only mixer
inspection showed:

```text
Playback: Front Left/Right 245 [103%]
Playback Path: OFF
```

The open PCM stream therefore did not prove audible output.  Setting
`Playback Path` to `SPK` immediately restored sound while the same NES process
continued running.  The operator confirmed audible output on the device.

Commit `307bdbf` adds permanent RK817 initialization.  At frontend startup it:

1. detects the speaker/headphone route through GPIO 86;
2. selects `SPK` or `HP` through the RK817 mixer helper;
3. initializes the hardware Playback control to maximum;
4. retains the existing plumOS 0..20 software-volume scale for per-sample
   volume control.

Commit `75e420a` initially reproduced the unusable generic F5 mapping. It is
superseded by `04ec7a4`, which uses physical L2: L2 + Up/Down controls volume,
and L2 + Left/Right controls brightness.

## Build and live deployment

The AArch64 C syntax checks, focused volume-control test, full frontend build,
and generated frontend component checksum manifest passed.  The broader
`test-app-layer-scripts.sh` run reaches an unrelated stale frontend-layout
assertion for `tile_width, tile_height`; it is not counted as a full-suite
pass.

The live originals and candidate files are retained under:

```text
/mnt/plumos-user/Backups/rk2020-live-audio-hotkeys-75e420a
```

The live top-level and frontend manifests report source ref `75e420a`.  The
full deployed frontend component checksum manifest passed.  Relevant deployed
hashes are:

```text
46af8e4512c03da867a61d862f95c83d9c323d536c0e5e077fa513933b237cea  bin/plumos-rk817-resume
d6eaa0a5e75a45c8129c4a384849e8fd988ab34abc72662026f44c6ffcf7e2ab  bin/plumos-volume-control
4c2a0147418ce4598a481b9fe8025d5789a9196de0ecd218d94d9c9e6c1cd830  bin/plumos-hardware-keys
9c6523ed77207fd38b42a82d65061873fedfaf4b8753cd6b547dd4298f9ff38e  config/system/input-map.env
624b3fdd2b9f1a37e587f8aa66286336f268930127c5bce570a30ad50e31a9e8  config/system/input-map.json
```

After deployment, live mixer inspection showed Playback at 100% and
`Playback Path` at `SPK`.  RetroArch retained ownership of the PCM stream in
the `RUNNING` state, and the hardware-key daemon restarted against the
GO-Advance gamepad with modifier code 708.

## Device result and remaining gate

- Audible output through the built-in speaker: **PASS** (operator confirmed).
- Route initialization deployed to the live installation: **PASS**.
- Active NES audio stream remained running through the route change: **PASS**.
- L2 + Up/Down changes the displayed/audible volume: **PASS** (operator
  confirmed).
- L2 + Left/Right changes brightness: **PASS** (operator confirmed).

## Low-volume curve follow-up

The operator confirmed that volume control worked but reported that the first
step above mute was too loud. At the observed saved/runtime level 1, the old
linear scale applied 5% software gain before the configured +15 dB internal
speaker boost. The resulting effective gain was approximately 28%, explaining
the abrupt 0-to-1 transition.

Commit `8c28ac6` replaces the linear amplitude mapping with 2 dB perceptual
steps from -38 dB at level 1 through unity gain at level 20. The UI and stored
range remain 0..20, mute and maximum output remain unchanged, and level 1 with
the existing speaker boost is approximately 7% full scale.

The AArch64 and ARMHF ALSA plugins were rebuilt and atomically deployed while
the active PCM stream remained `RUNNING`. The previous managed files are kept
under:

```text
/mnt/plumos-user/Backups/rk2020-volume-curve-8c28ac6
```

Post-deployment audio-component and complete app-layer checksum verification
passed, and the live manifest reports source ref `8c28ac6`. An already-running
emulator keeps the old shared object mapped; the new curve takes effect after
exiting and relaunching a game.

- New 0-to-1 transition after game relaunch: **PASS**.
- Progressive response across the low and middle levels: **PASS**.

The operator reported that the revised low-volume curve felt appropriately
progressive after relaunch.

## Headphone hotplug follow-up

Inserting headphones during an active NES game initially left the RK817 route
at `SPK`, so sound continued through the built-in speaker.  Live inspection
showed that the hardware state itself was correct:

```text
gpio86=1
rockchip,rk817-codec Headphones -> /dev/input/event1
```

Manually applying `plumos-rk817-resume route-headphone` moved the same active
game stream to the headphones and silenced the speaker.  This isolated the
failure to missing hotplug monitoring rather than the codec, PCM stream, or
headphone output path.

Commit `7df2b4b` adds the RK817 headphone evdev source to the existing
hardware-key daemon.  The first live revision exposed that the kernel switch
ioctl reported an inserted initial state as zero on this unit.  Commit
`9f3a4c8` therefore uses the board-verified GPIO 86 level as the route source
of truth while retaining `SW_HEADPHONE_INSERT` as the immediate change
notification:

- GPIO 86 High: `route-headphone` / `HP`;
- GPIO 86 Low: `route-speaker` / `SPK`.

The final managed delta changed only `bin/plumos-hardware-keys` and the
frontend metadata dependency closure.  Its deployed binary SHA-256 is:

```text
3bf1f383e57da0f9dec5ccc1203b17729816c640c67c219f7ddff8da000213d2
```

Post-deployment verification passed:

```text
source_ref=9f3a4c8
frontend_ok=202 failed=0
root_ok=11290 failed=0
```

The previous managed state is recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-headphone-gpio-9f3a4c8-before/before.tar
```

The daemon log recorded both directions repeatedly with successful RK817
route application:

```text
hardware-keys: event=headphone connected=1 route=headphone rc=0
hardware-keys: event=headphone connected=0 route=speaker rc=0
```

The operator tested several games and confirmed that insertion moves audio to
the headphones with the speaker silent, and removal returns audio to the
speaker.  Headphone hotplug is physically accepted.
