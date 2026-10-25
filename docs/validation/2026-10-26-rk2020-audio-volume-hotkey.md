# RK2020 audio route and volume hotkey validation (2026-10-26)

## Scope

Restore audible output on the stock Linux 4.4.189 RK2020 and match the stockOS
volume-control contract on hardware without dedicated volume buttons.  The
work was deployed to the live plumOS SD installation without rebuilding the
full image or interrupting the running NES process.

## Read-only stockOS evidence

The inspected EmuELEC 4.8 image has SHA-256:

```text
00f83164472c093c1272b9385a57a28113a59d14d28d11a0bf21e81445d45b58
```

Its `oga_events.py` uses evdev code 708 (F5) as a modifier:

- F5 + Up/Down changes volume;
- F5 + Left/Right changes brightness.

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

Commit `75e420a` restores the stock hotkey contract in the managed RK2020 input
daemon: F5 + Up/Down controls volume, and F5 + Left/Right controls brightness.

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
- F5 + Up/Down changes the displayed/audible volume: **PENDING physical input**.
- F5 + Left/Right changes brightness: **PENDING physical input**.

The pending hotkey checks do not require a reboot or a new SD image.  They can
be performed while the current NES session remains active.
