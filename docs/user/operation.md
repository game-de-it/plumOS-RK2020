# RK2020 controls, power, and emulator hotkeys

[日本語](operation.ja.md) | [User manual](README.md)

The RK2020 has no volume buttons and no clickable analogue stick. `L2` is also
the plumOS Function modifier. Do not apply another handheld's button guide to
this device.

## Frontend controls

| Button | Action |
| --- | --- |
| D-pad or analogue stick | Move the cursor |
| A | Confirm, open, or launch |
| B | Back or cancel |
| X | Switch between the ROM list and gallery |
| Y | Add or remove a favourite where supported |
| START | Open the START menu |
| SELECT | Choose a launch profile/core for the selected game |
| L2 / Function | Save a frontend screenshot to `Screenshots/` |
| Power | Open the power menu |

Choose graphic or text UI from `START -> UI Settings`. Gallery is available
from a system's ROM screen with X.

## System hotkeys

These combinations work in the frontend and while a game is running.

| Combination | Action |
| --- | --- |
| L2 + D-pad Up / Down | Volume up / down |
| L2 + D-pad Left / Right | Brightness down / up |

The first audible volume step is intentionally small. The headphone jack
automatically mutes the speaker and restores it when the plug is removed.

## Power and sleep

Press Power briefly to open the plumOS power menu. A confirms and B cancels.
Use this menu for Sleep, Restart, and Shutdown; do not remove power or the SD
card while a save or shutdown is in progress. Press Power again to resume from
sleep. Wi-Fi may take about ten seconds to reconnect after the display returns.

USB power changes the RK2020's charging-screen behavior. Wait for the screen
and LEDs to settle before unplugging the cable after shutdown.

## Emulator menu and exit map

“L2 / Function” below means the physical L2 button. A menu operation is not
the same as a clean exit: use the menu's Quit/Exit item when shown.

| Launch route | Open menu / special operation | Return to frontend |
| --- | --- | --- |
| RetroArch | SELECT + B toggles Quick Menu | START + SELECT |
| PicoArch | L2 + START | Choose Quit in the PicoArch menu |
| PCSX-ReARMed standalone | L2 + START | Choose Exit in the emulator menu |
| PPSSPP standalone | L2 opens the pause menu | Use Exit to menu, then Exit |
| Mupen64Plus standalone | Short L2 press toggles analogue-stick / N64 D-pad mode | Hold L2 for 1.5 seconds |
| DraStic standalone | L2 + START opens the integration menu; L2 + SELECT opens the native menu | Choose Exit from either menu |
| OpenBOR standalone | L2 opens/backtracks through the OpenBOR menu | Choose Exit from the menu |
| PICO-8 runtime | START opens the PICO-8 pause menu | Choose the runtime's Exit/Quit item |

For other standalone programs, use their own menu's Exit item. Never force
power off merely because a game menu is unfamiliar; first open the power menu
with Power and cancel with B if you only need to return to the game.

## DraStic touch and screen controls

| Combination | Action |
| --- | --- |
| R2 | Swap the two DS screens in normal mode |
| L2 + A | Alternate DS screen layout |
| L2 + X | Toggle normal controls / touch-cursor mode |
| Analogue stick or D-pad | Move the stylus cursor in touch mode |
| A | Touch the selected point |
| Hold R while moving | Fine cursor movement |

Repeat L2 + X to leave touch mode. L2 + D-pad remains reserved for system
volume and brightness, even in DraStic.

## RetroArch shortcuts

| Combination | Action |
| --- | --- |
| SELECT + B | Open/close Quick Menu |
| START + SELECT | Cleanly exit to the frontend |
| SELECT + L / R | Load / save state |
| SELECT + D-pad Left / Right | Previous / next state slot |
| SELECT + X | Screenshot |
| SELECT + Y | Toggle FPS display |
| SELECT + L2 / R2 | Toggle slow motion / fast-forward |

See [RetroArch saves and hotkeys](retroarch-saves-and-hotkeys.md) for paths and
button numbers.
