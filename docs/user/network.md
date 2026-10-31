# Wi-Fi, SFTP, and time

[日本語](network.ja.md) | [User manual](README.md)

RK2020 has no internal Wi-Fi. Connect a compatible USB Wi-Fi adapter before
opening `START -> Network Settings`.

## Wi-Fi setup

1. Turn Wi-Fi on.
2. Scan for networks and select the SSID.
3. Enter the password and connect.
4. Confirm that the top bar shows Wi-Fi and an IP address is available in
   Network Settings.

`MISSING` means no supported network interface is present. A dongle that works
in stock EmuELEC is not automatically supported by plumOS; chipset and driver
support must match. Try reseating the adapter while the device is off, then
boot again. Do not repeatedly remove the adapter during a write or sleep
transition.

Wi-Fi is powered down during sleep and restored after resume. The adapter LED
can remain dark for roughly ten seconds while recovery completes.

## SFTP file transfer

Use an SFTP client such as FileZilla:

```text
Protocol: SFTP
Host:     the IP shown by plumOS
Port:     22
User:     root
Password: plumos
```

The password is lower-case and case-sensitive. Store ROMs under `/mnt/plumos-user/roms/`, BIOS
files under `/mnt/plumos-user/bios/`, and update inputs only where the release
instructions specify. Do not modify `/mnt/plumos/` runtime files through SFTP.

The default root password is intended for a trusted local network. Do not
forward port 22 from the Internet.

## Time

When Automatic Time is enabled, plumOS synchronizes after the network becomes
available and also updates the hardware clock. Without a network, set the date,
time, and timezone manually in System Settings.
