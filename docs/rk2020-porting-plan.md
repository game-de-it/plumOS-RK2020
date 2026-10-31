# RK2020 porting plan

[日本語](rk2020-porting-plan.ja.md)

Date: 2026-10-25

## Source baseline

The code baseline is plumOS Pixel2 because it is the closest maintained RK3326
port. Its update, storage, frontend, emulator, and service designs are reusable;
its Pixel2 DTB, kernel ABI, panel geometry, controller identity, power results,
and device acceptance are not.

The original Pixel2 documentation is retained without rewriting under
`docs/reference/pixel2/` for provenance.

## Work units and commit policy

1. Retarget the reusable code and names to RK2020 without claiming hardware
   acceptance.
2. Capture and register read-only stock boot/runtime evidence.
3. Replace the boot and kernel-runtime contracts with RK2020 artifacts.
4. Adapt display, input, audio, network, storage, and power policy.
5. Build and host-verify the seed image.
6. Validate each physical subsystem on a separate SD and record the results.

Each unit is committed separately. Vendor binaries, source SD images, secrets,
ROMs, BIOS files, saves, and generated images remain outside Git.

## Safety boundary

The live stock card is evidence, not a development target. `/flash` is expected
to remain read-only. Any command that changes the device is deferred until a
separate test SD exists and a rollback path has been recorded.
