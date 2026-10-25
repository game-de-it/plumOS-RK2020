# RK2020 representative ROM deployment

Date: 2026-10-26

## Scope

The operator-provided ROM collection at
`/Volumes/public/02/motoki/emu/ROM/rom2` was used read-only. Representative
content was selected for every enabled RK2020 emulator system for which the
collection contains a compatible file. ROM and BIOS content remains outside
Git and outside the plumOS app-layer/release image.

The non-emulator `ports` route was not staged. Its automatically discovered
sample was a nested Windows `run.sh` and was not a complete PortMaster package.
PortMaster content remains a separate acceptance gate.

## Selection corrections

The route inventory originally selected two files that were unsuitable as
visible frontend entries:

- Atari 8-bit selected the firmware-like `ATARIBAS.ROM`, and a provisional
  `Yoomp.dsk` replacement was not in this target's advertised extension set.
  The persistent sample is now the supported game image
  `BountyBobStrikesBack.rom`.
- Sega CD selected track 1 instead of the launch descriptor. The persistent
  sample is now the complete demo's CUE plus all eight referenced tracks.

`scripts/validate-romset-routes.py` now names both runnable samples explicitly,
so later inventories reproduce the device layout.

Descriptor-backed media copied every local file referenced by CUE/GDI/M3U
content. EasyRPG, ScummVM, Cannonball, Cave Story, and Dinothawr copied the
complete parent tree required by their engines. Cannonball and ScummVM also
received their generated launch marker files.

## BIOS preparation

`scripts/prepare-rk2020-bios.py` derived firmware requirements from all enabled
launch profiles and staged only matching operator-provided files:

```text
requirements=231
files=488
bytes=116305687
missing_required=2
missing_optional=41
```

The two missing required declarations are `ecwolf.pk3` (no supplied Wolf3D
content) and `kick34005.CDTV` (CDTV firmware; the selected Amiga A500 disk does
not use it). The Channel F minimum firmware pair was available.

## Persistent deployment

The final device plan contains:

```text
emulator systems=73
ROM/descriptor/tree files=1452
BIOS/BIOS-manifest files=490
verified files=1942
bytes=2286858977
```

Content was first streamed to
`/mnt/plumos-user/.plumos-validation/representative-media-20261026`. All files
were checked there before promotion. The existing `/mnt/plumos-user/roms` and
`/mnt/plumos-user/bios` trees contained zero files, so promotion had no
conflicts and overwrote nothing. The provisional `Yoomp.dsk` is retained in
the validation directory's `replaced` subdirectory rather than deleted.

The persistent manifest and checksum list are:

- `/mnt/plumos-user/.plumos-validation/representative-media-20261026/.plumos-manifest/manifest.json`
- `/mnt/plumos-user/.plumos-validation/representative-media-20261026/.plumos-manifest/checksums.sha256`

Both staging-path and final-path verification reported:

```text
ok=1942
bad=0
```

The resulting user volume uses 2.2 GiB and retains 104.5 GiB free.

## Frontend result

A full library refresh completed with 73 content-backed emulator systems. The
Atari 8-bit correction increased the visible set from 72 to 73. The running
frontend was stopped through `plumos-frontend-stop` and restarted through
`plumos-frontend-launch`; PID changed from 1032 to 15623, the scan completed in
193 ms, and exactly one frontend process remained.

The supplied set has no matching content for these 14 enabled systems:

`ngp`, `wonderswancolor`, `x68000`, `tic80`, `vectrex`, `sg1000`, `sharpx1`,
`vmu`, `wolf3d`, `zx81`, `arduboy`, `megaduck`, `puzzlescript`, and
`superbroswar`.

This deployment proves selection, complete transfer, checksum identity, and FE
discovery. Game startup, display, controls, audio, menu/exit, saves, and each
alternate core remain separate physical-device gates.

## Post-deployment execution corrections

The full device matrix found that several lexically first samples were not
valid representatives of their default route. The source ROM collection was
kept read-only. Copies on the user partition were replaced as follows after
device execution and screenshot review:

| System | Retired sample | Proven sample | Default route |
| --- | --- | --- | --- |
| Arcade | `1942a.zip` | `nemesis.zip` | `retroarch:mame2003_plus` |
| FBNeo | `airduelm72.zip` | `bchopper.zip` | `retroarch:fbneo` |
| CPS2 | `ssf2u.zip` | `pgear.zip` | `retroarch:fbalpha2012` |
| Atari 5200 | `BountyBobStrikesBack.a52` | `Millipede.a52` | `retroarch:a5200` |
| Atari 8-bit | `BountyBobStrikesBack.rom` | raw `Yoomp.dsk`, installed as `Yoomp.xfd` | `retroarch:atari800` with 800XL/64K |

The raw 90 KiB Atari disk has no ATR header and is an XFD-layout image; only
its installed filename was normalized. All retired and comparison copies were
moved to
`/mnt/plumos-user/Backups/rk2020-representative-roms-20261026/`, whose
`retired-checksums.sha256` records them. Nothing was removed from the supplied
Mac-side collection.
