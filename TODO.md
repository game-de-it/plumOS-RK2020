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
- [ ] Confirm the frontend at native 320x480/60 Hz with correct orientation.
- [ ] Confirm all RK2020 buttons and both analogue axes.
- [ ] Confirm speaker, headphone switching, volume, and mute through RK817.
- [ ] Confirm brightness range and suspend/resume behavior.
- [ ] Confirm cold boot, reboot, shutdown, and charging-state behavior.
- [ ] Confirm RTL8821CU Wi-Fi, SSH, reconnect, removal, and charging fallback.
- [ ] Run representative no-input and gameplay tests for every emulator route.
  Automated no-input evidence now covers all 73 content-backed systems: 70
  clean passes, two core-unload failures, and one missing proprietary PICO-8
  runtime. Fifteen catalog systems still lack representative content; manual
  gameplay, standalone final-scanout color, and the Amiga sample remain open.
  DraStic now has an RK2020 raw-input mapping and passed a first-frame live
  smoke test. Its display runner now keeps both 640x480 menu buffers current
  using the XU20-proven timed presentation fix; deterministic D-pad/analog
  menu navigation is accepted. `L2 + X` now toggles a stylus mode with
  analog/D-pad movement, A touch, and R fine movement. The RK2020-specific
  cursor step was raised from 2 to 5 coordinates per update, with R retaining
  a 2-coordinate precision step; cursor speed/precision, R2 screen swap, the
  remaining L2 combinations, and menu exit remain a direct physical-input
  gate.
- [ ] Complete physical frontend-application acceptance. File Manager,
  RetroArch, and PortMaster routes now pass; Music Player initializes display,
  input, and RK817 audio but still needs representative music playback.
  Scraping, Pyxel installation, and PortMaster update remain separate mutating
  gates.
- [x] Unmount both live aliases of `PLUMOS_USER`, repair the forced-power-off
  FAT dirty bit, verify the unmounted filesystem clean, and restore FE/input.

## Release gates

- [ ] Complete the license and vendor-boundary audit.
- [ ] Complete host reproducibility and release-content checks.
- [ ] Complete SD readback verification and the full physical acceptance matrix.
