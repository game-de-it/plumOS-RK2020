# plumOS RK2020

[日本語](README.ja.md) | [Porting plan](docs/rk2020-porting-plan.md) |
[SD storage and reimaging](docs/user/storage-and-reimaging.md) | [TODO](TODO.md)

This repository ports the plumOS family to the RK3326-based RK2020. It starts
from the mature plumOS Pixel2 implementation because both devices use RK3326,
but RK2020 evidence is tracked independently. Historical Pixel2 documents are
kept under `docs/reference/pixel2/` and do not count as RK2020 validation.

## Current phase

The port is in initial bring-up. Read-only inspection of the stock EmuELEC 4.8
installation established this ownership boundary:

- retain the Rockchip boot prefix, stock `KERNEL`, stock DTB, and matching
  4.4.189 modules/firmware as the hardware compatibility layer;
- use the stock `SYSTEM` only as an analysis input and never copy it into a
  generated plumOS image;
- let plumOS own PID 1, services, frontend, emulators, and updates after the
  stock initramfs mounts and hands off to `SYSTEM`;
- never modify the original stock SD; perform boot tests on a separate card.

A host build or checksum pass does not prove device boot, 320x480 display,
controls, RK817 audio, charging and power behavior, USB Wi-Fi, or emulator
routes.

## License

plumOS-authored material is [MIT licensed](LICENSE). Stock/vendor boot material
and third-party components retain their original terms. Vendor binaries stay
outside Git under the local `artifacts/vendor/` tree.
