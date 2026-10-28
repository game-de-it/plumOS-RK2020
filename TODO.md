# RK2020 port TODO

## Boot provenance

- [x] Identify the live stock OS, kernel, SoC, partition layout, active DTB,
  display mode, input device, audio device, storage speed, and USB Wi-Fi path.
- [x] Preserve the Pixel2 implementation history as the RK3326 starting point.
- [ ] Register and verify the RK2020 boot prefix, KERNEL, DTB, boot config,
  module tree, firmware tree, and stock SYSTEM analysis hash.
- [ ] Build a plumOS `SYSTEM` accepted by the stock 4.4.189 initramfs.
- [ ] Assemble and verify a reproducible RK2020 seed image.

## Physical bring-up gates

- [ ] Boot from a separate test SD and prove the active root is plumOS.
- [x] Confirm the frontend at native 320x480/60 Hz with correct orientation.
  The operator reviewed the formal display evidence and confirmed this gate on
  2026-10-28. Frontend layout, orientation, and the corrected application and
  emulator presentation remain recorded as separate physical observations.
- [x] Confirm all RK2020 buttons and both analogue axes. The operator confirmed
  the input set through gameplay on 2026-10-28, after the route-specific input
  work and physical tests documented under `docs/validation/`.
- [x] Confirm speaker, headphone switching, volume, and mute through RK817.
  Speaker output, the perceptual 0..20 volume curve, mute at zero, and L2 +
  Up/Down control are physically accepted.  Commits `7df2b4b` and `9f3a4c8`
  add RK817 jack-event monitoring: GPIO 86 selects `HP` when inserted and
  `SPK` when removed.  Automatic switching passed across multiple games.
- [x] Confirm brightness range and suspend/resume behavior. Frontend suspend,
  powered wake, delayed Wi-Fi recovery, and RetroArch in-game suspend/resume
  are physically accepted. The in-game route now applies the RK2020
  east-confirm input map to its power overlay, enters kernel `mem`, restores
  the DRM planes/backlight, and resumes the same controllable game. On the
  clean SD, Game Boy initially resumed with a right-shifted image because the
  shared handoff reconstructed rotated plane geometry from framebuffer size.
  Commit `7a27673` restores the eight exact atomic CRTC/source properties; a
  repeated Game Boy sleep/wake returned at the correct position without an RA
  menu refresh. The shared fix covers all direct-DRM handoff clients, while
  physical acceptance remains explicitly the reported Game Boy route.
- [x] Confirm cold boot, reboot, shutdown, and charging-state behavior.
  Read-only stockOS analysis found that stock keeps DWC2 and `8821cu` bound
  through kernel shutdown, where `rtw_dev_shutdown` remains available.  Commit
  `6004700` preserves that path.  Frontend Shutdown now physically turns the
  display, charge LED, and external Wi-Fi LED off both with the charging cable
  disconnected and with `ac=1`/battery `Charging`; it does not reboot or enter
  the charge screen.  Cold boot and cable-connected/disconnected reboot paths
  were also physically accepted.
- [x] Confirm RTL8821CU Wi-Fi, SSH, reconnect, removal, and charging fallback.
  The operator confirmed the complete Wi-Fi gate on 2026-10-28. This includes
  normal connected operation and the previously exercised resume/recovery and
  cable-state paths; it is independent of the separate shutdown LED gate.
- [x] Run representative no-input and gameplay tests for every emulator route.
  Automated no-input evidence now covers all 73 content-backed systems: 70
  clean passes, one Game & Watch harness-exit failure later superseded by a
  normal physical FE exit, one TI-83 route blocked by missing calculator BIOS,
  and one PICO-8 route that was initially missing its proprietary runtime.
  The user-supplied PICO-8 0.2.7 AArch64 runtime now launches a representative
  cart through the managed standalone route; process, dependency, rotation,
  direct-scanout, clean-stop, and FE-return checks pass. Physical screen and
  control operation are also accepted. Fifteen catalog systems still lack
  representative content; manual gameplay, standalone final-scanout color,
  and unobserved sub-features remain documented coverage limitations rather
  than blockers after the final emulator-scope acceptance. A second Amiga
  title was
  physically viewed with normal color, closing the earlier HAM-sample color
  ambiguity. TI-83 remains in the frontend catalog but now rejects launch before
  taking the display when none of `ti83se.rom`, `ti83plus.rom`, or `ti83.rom`
  is present and reports the missing BIOS legibly in FE. TI-83 gameplay remains
  unavailable until user-supplied calculator firmware is installed, and is an
  accepted external-content dependency rather than an OS failure.
  DraStic now has an RK2020 raw-input mapping and passed a first-frame live
  smoke test. Its display runner now keeps both 640x480 menu buffers current
  using the XU20-proven timed presentation fix; deterministic D-pad/analog
  menu navigation is accepted. `L2 + X` now toggles a stylus mode with
  analog/D-pad movement, A touch, and R fine movement. The RK2020-specific
  cursor step was raised from 2 to 5 coordinates per update, with R retaining
  a 2-coordinate precision step. The raw event path now drains batches of 64
  events at 1 ms intervals so the analog-release event cannot sit behind an
  ABS/SYN backlog. DraStic now renders its rotated 4:3 surface in a centered
  320x427 viewport instead of stretching it across 320x480. Cursor release,
  R precision, R2 screen swap, the remaining L2 combinations, and menu exit
  remain direct physical-input gates. The runaway cursor is fixed, but analog
  cursor motion still needs smoothing. Direct KMS capture and the subsequent
  physical retest accept the centered 4:3 viewport. PPSSPP's inherited `-2`
  UI scale clipped pause-menu labels at 480x320; the managed `-6` correction
  now fits all rows and actions in a direct KMS capture, with final physical
  readability and control acceptance still pending. PPSSPP's RK2020 SDL
  controller mapping omitted the measured `ABS_X`/`ABS_Y` axes even though
  the saved controls already reference SDL controller axes. The live binary
  now maps them as `leftx:a0,lefty:a1`; direct Ridge Racer gameplay confirms
  that the physical analog stick works in PPSSPP. OpenBOR previously rendered
  its landscape frame directly into the portrait KMS target and treated its
  16 buttons as though two axes came first. Its live route now applies the
  RK2020 final quarter-turn, maps the measured D-pad/ABXY/shoulder/START/SELECT
  indices, mirrors the analog stick onto directions, and persists settings.
  All PAKs now default to Button 1 for Jump and Button 2 for Attack 1 while
  preserving non-default user mappings; direct physical control acceptance
  is pending. Mupen64Plus standalone has physically accepted orientation and
  controls; holding Function/L2 for 1500 ms exits cleanly. AeroGauge produced
  a stable 29.6 display-list frames/second, but both it and Super Mario 64 had
  uneven scrolling with Rice VSync disabled. The VSync-on default and one-time
  existing-state migration are deployed; Super Mario 64 pacing is physically
  accepted. PicoArch now has an exhaustive 22-core RGB565/XRGB8888 byte-order
  table plus five system-scoped PicoDrive routes. Seven core defaults plus the
  Mega Drive, Game Gear and RK2020 32X PicoDrive routes receive the known byte swap
  automatically; catalog drift fails the source gate. A BusyBox awk reserved
  variable had caused all five system overrides to be silently ignored; the
  launcher now rejects lookup failures, and an execution test covers all five
  decisions. The post-deploy device matrix passes launch, scanout, audio and
  stop for all five routes. BC Racers colour and motion, Columns colour and
  controls, and Bare Knuckle colour and controls are physically accepted.
  Bare Knuckle was also relaunched after deployment without a forced override
  and selected the expected route automatically. The frontend now exposes only the PicoArch
  profiles declared for each system in `systems.json`; it no longer clones
  every RetroArch profile into an unvalidated PicoArch candidate. Device-side
  GB/GBA catalog checks and the full app-layer checksum pass. Genesis Plus GX
  retains its RK2020 physical acceptance, while this predictive correction
  does not claim physical color acceptance for every game or palette.
  On 2026-10-27 the operator accepted the emulator-related verification as
  complete at project scope. This closes the emulator gate while retaining the
  granular evidence limits and external-content dependencies above.
- [x] Complete physical frontend-application acceptance. File Manager,
  Scraping, RetroArch, Music Player, and the PortMaster GUI now pass. The
  shared PortMaster game runner presents a 640x480 logical canvas and fits it
  into the RK2020 landscape view without stretching. The Apotris-specific
  content offset is isolated from other ports; the operator physically accepts
  Apotris and the other installed port games. A project requirements file is
  staged for Pyxel Setup and resolves as `requirements_source=project`. The
  physical FE action installed and import-verified the requested Pyxel,
  Pygame, NumPy, and Pillow versions. The first run blanked the panel while FE
  waited for pip; the corrected maintenance-action renderer lifecycle then
  passed an exact physical progress-screen rerun. PortMaster Update completed
  physically and reported the stable channel current at `2026.06.23-0015`.
- [x] Unmount both live aliases of `PLUMOS_USER`, repair the forced-power-off
  FAT dirty bit, verify the unmounted filesystem clean, and restore FE/input.

## Release gates

- [ ] Complete the license and vendor-boundary audit.
- [ ] Complete host reproducibility and release-content checks.
- [ ] Complete SD readback verification and the full physical acceptance matrix.
