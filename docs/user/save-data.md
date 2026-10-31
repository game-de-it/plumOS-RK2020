# Save data and backups

[日本語](save-data.ja.md) | [User manual](README.md)

Save data is written to the FAT user volume. RetroArch normally stores save
RAM and states in a ROM-folder/core-specific directory; standalone emulators
use their own directories under the same user storage.

## Safe saving

- Exit through the emulator's normal Quit/Exit operation.
- After an in-game save, wait several seconds before shutting down.
- Use the plumOS power menu for shutdown; never remove the card while an LED
  or progress screen indicates activity.
- Do not rename only one member of a multi-file disc game.

RetroArch flushes save RAM every ten seconds and writes an automatic state at
normal exit. That state is not automatically loaded at the next launch.

## Backup

Back up at least `roms/`, `bios/`, save/state directories, screenshots, and any
PortMaster or PICO-8 user files from the FAT volume. A whole-volume copy is
easier to restore than selecting files one by one.

Reimaging can sometimes leave the old FAT data readable, but this is not a
backup mechanism. See [SD storage and reimaging](storage-and-reimaging.md).
