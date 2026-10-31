# Troubleshooting

[日本語](troubleshooting.ja.md) | [User manual](README.md)

## Wi-Fi says `MISSING`

Power off, connect the USB adapter firmly, and boot again. If it remains
missing, the chipset may not have a matching plumOS driver even if stock
EmuELEC supports it. Try a known-compatible adapter. After resume, wait about
ten seconds before deciding that recovery failed.

## ROMs do not appear

Confirm the system folder and extension, then refresh TOP from UI Settings or
restart the frontend. Multi-file games need their cue/playlist and tracks.
Empty systems are hidden by default.

## A game returns immediately to the frontend

Try the default launch profile. Check required BIOS filenames and arcade ROM
set compatibility. Do not select a PicoArch or standalone profile merely
because it is installed; the route must support that system and content.

## Menu or exit controls are unclear

Use the [per-emulator table](operation.md#emulator-menu-and-exit-map). The
RK2020 has no clickable stick and no dedicated volume keys. L2 is Function and
also modifies the D-pad for system volume/brightness.

## Black screen after sleep or power-menu cancel

Wait several seconds for the display owner and Wi-Fi to resume, then press
Power once. Do not repeatedly press buttons or hold Power while storage is
active. If the screen remains black but sound continues, record the emulator,
USB-cable state, audio state, and LED state; these are separate diagnostic
signals.

## No audio or wrong output

Raise volume with L2 + D-pad Up. Remove and reinsert headphones once; the
speaker should mute only while the plug is present. Test frontend and game
audio separately.

## Shutdown and USB power

Charging-screen and LED behavior depends on whether USB power is attached.
Always use the power menu and wait for the final state. If shutdown appears to
enter the charge screen, press Power briefly rather than forcing a reset.

## Suspected SD corruption

Shut down cleanly and back up the FAT volume on another computer before repair.
Do not run a repair tool against a mounted, in-use volume. Keep a fresh image
and a separate user-data backup so system recovery does not depend on old
sectors surviving a rewrite.

## Resetting emulator settings

Use `START -> System Settings -> Factory Reset` and choose RA, PicoArch,
standalone, or all. The replaced configuration is backed up. This is safer
than deleting runtime files manually.
