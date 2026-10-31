# Systems and emulators

[日本語](emulators.ja.md) | [User manual](README.md)

## Launching a game

1. Choose a system on TOP.
2. Choose a game in the ROM list or gallery.
3. Press A.

Press SELECT before launch to choose an available profile. plumOS only lists
profiles supported for that system; it does not offer every installed core for
every ROM. An incompatible forced profile can fail before the first frame.

## Launch-route types

- **RetroArch (RA)** covers the broadest set of systems and provides Quick
  Menu, save states, shaders, and per-core settings.
- **PicoArch (PICO)** is a lightweight route for selected cores.
- **Standalone (SA)** uses a dedicated program such as PPSSPP, DraStic,
  PCSX-ReARMed, Mupen64Plus, OpenBOR, or PICO-8.

Menu and exit buttons differ by route. Keep the
[emulator hotkey table](operation.md#emulator-menu-and-exit-map) available.

## ROMs and BIOS files

Place games in the system folders under `roms/`. Keep cue sheets, tracks,
playlists, and their subdirectories together for multi-file games. BIOS files
belong under `bios/` and must use the exact filename and letter case expected
by the emulator. Arcade cores require matching ROM sets.

The commercial PICO-8 runtime is not distributed. If licensed, place its
AArch64 files under:

```text
roms/pico-8/aarch64/
```

The directory must contain `pico8.dat` and a supported AArch64 executable such
as `pico8_64`.

## Performance and configuration

Some PSP, Nintendo 64, Dreamcast, arcade, or software-rendered titles exceed
RK2020 performance. A low frame rate is not always a configuration fault.
Change one setting at a time and test the same scene.

Use `START -> System Settings -> Factory Reset` to restore RA, PicoArch, or
standalone defaults. plumOS backs up the replaced configuration first. This
does not delete ROMs or normal save data.
