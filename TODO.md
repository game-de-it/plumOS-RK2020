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

## Release gates

- [ ] Complete the license and vendor-boundary audit.
- [ ] Complete host reproducibility and release-content checks.
- [ ] Complete SD readback verification and the full physical acceptance matrix.
