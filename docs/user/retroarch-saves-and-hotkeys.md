# RK2020 RetroArch saves and hotkeys

[日本語](retroarch-saves-and-hotkeys.ja.md) | [Controls](operation.md)

## System hotkeys

| Physical buttons | Action |
| --- | --- |
| L2 + D-pad Up / Down | Volume up / down |
| L2 + D-pad Left / Right | Brightness down / up |

RK2020 has no physical OGA F2/Minus or F5/Plus buttons.

## RetroArch hotkeys

SELECT is the hotkey modifier while a RetroArch game is running.

| Physical buttons | Action |
| --- | --- |
| SELECT + B | Toggle RetroArch Quick Menu |
| START + SELECT | Exit RetroArch and return to the frontend |
| SELECT + L | Load state |
| SELECT + R | Save state |
| SELECT + D-pad Left / Right | Previous / next state slot |
| SELECT + X | Screenshot |
| SELECT + Y | Toggle FPS display |
| SELECT + L2 | Toggle slow motion |
| SELECT + R2 | Toggle fast-forward |

START + SELECT uses RetroArch's normal exit path and waits for save RAM and the
automatic exit state to be written.

## RK2020 RetroArch button numbers

| Physical button | evdev code | RetroArch udev button |
| --- | ---: | ---: |
| B | 304 | 0 |
| A | 305 | 1 |
| X | 307 | 2 |
| Y | 308 | 3 |
| L | 310 | 4 |
| R | 311 | 5 |
| D-pad Up / Down / Left / Right | 544 / 545 / 546 / 547 | 6 / 7 / 8 / 9 |
| SELECT | 704 (F1) | 10 |
| L2 | 706 (F3) | 12 |
| R2 | 707 (F4) | 13 |
| START | 709 (F6) | 15 |

Buttons 11 (F2) and 14 (F5) exist in the scan order but do not correspond to
physical RK2020 buttons.

## Save locations

Save RAM and save states are stored by ROM folder and core. A ROM such as:

```text
roms/FC/Akumajou Densetsu.nes
```

normally uses a layout similar to:

```text
roms/FC/FC/QuickNES/
  Akumajou Densetsu.srm
  Akumajou Densetsu.state.auto
  Akumajou Densetsu.state.auto.png
```

Save RAM is flushed every ten seconds. State slots auto-increment and keep up
to 20 generations with thumbnails. An automatic state is written at exit but
is not loaded automatically on the next launch.
