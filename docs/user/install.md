# Installation and first boot

[日本語](install.ja.md) | [User manual](README.md)

## What you need

- an RK2020 handheld;
- a reliable microSD card;
- a card reader and Raspberry Pi Imager or another raw-image writer;
- an optional compatible USB Wi-Fi adapter.

Back up every file you need from the target card. Writing an image replaces
its partition table and system areas.

## Write the image

1. Decompress the distributed image if necessary.
2. Select the plumOS RK2020 image in the writer.
3. Select the microSD card by its capacity and device name. Do not select a
   computer or backup disk.
4. Write and verify the image, then eject the card safely.
5. Insert the card into the powered-off RK2020 and turn it on.

Raspberry Pi Imager, `dd`, Balena Etcher, and similar raw writers normally
behave alike: they overwrite the sectors contained in the image, not
necessarily every later sector on a larger card.

## First boot

The first boot prepares the writable partitions and displays the setup screen.
This can take longer on a slow card. Keep the device powered and do not remove
the card until the frontend appears.

Complete Wi-Fi setup only when using a compatible USB adapter. A missing or
unsupported adapter is shown as `MISSING`; this does not prevent offline use.

## Existing files after reimaging

If a new image uses the same FAT user-volume position and does not reformat
that region, old ROMs may appear again. This is a consequence of partial raw
overwriting, not a backup or recovery guarantee. Partition layout changes,
formatting, writer options, card faults, or a larger future image can destroy
those files. Always keep a separate backup. See
[SD storage and reimaging](storage-and-reimaging.md).
