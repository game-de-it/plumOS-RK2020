# Updating plumOS RK2020

[日本語](updates.ja.md) | [User manual](README.md)

The current RK2020 release uses manual SD-image updates. The System Update
screen is informational; do not install an update package made for another
plumOS device.

## Recommended procedure

1. Read the release notes and confirm that the image explicitly targets
   RK2020.
2. Back up the FAT user volume, especially ROMs, BIOS files, saves, states,
   screenshots, PortMaster data, and the licensed PICO-8 runtime.
3. Verify the downloaded checksum when one is supplied.
4. Shut down from the plumOS power menu and remove the card only after the
   screen and LEDs settle.
5. Write the new image as described in [Installation](install.md).
6. Complete first boot and re-check display, controls, audio, Wi-Fi, sleep,
   and one representative game before restoring anything else.

Old FAT data can sometimes remain readable when the new image has the same
partition placement. Treat that only as a convenience; never skip the backup.

PortMaster has a separate updater at `START -> Apps -> Update PortMaster`.
It updates PortMaster components, not plumOS itself.
