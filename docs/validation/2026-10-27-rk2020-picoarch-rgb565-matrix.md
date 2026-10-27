# RK2020 PicoArch RGB565 classification

Date: 2026-10-27  
Initial implementation commit: `af210a8`<br>
RK2020 route correction commit: `3dc5064`<br>
Device: RK2020 at `192.168.10.110`

## Purpose

Do not require a person to discover every predictable PicoArch colour failure
one game at a time. The launcher now classifies every PicoArch core exposed by
the RK2020 frontend and applies the known RGB565 byte-order correction before
the common scaler.

The starting evidence was the 40-run Bubble PicoArch comparison against
RetroArch reference frames. RK2020-specific physical evidence supersedes that
portable matrix where necessary: Genesis Plus GX requires byte swapping on the
RK2020 final fbdev-to-XRGB8888 presentation path and was already accepted by
the operator after correction.

## Classification

The 22 exposed cores are exhaustively listed in
`share/picoarch/rgb565-byte-order.tsv`. The seven core defaults requiring a
swap are:

```text
gambatte
gearboy
gearsystem
genesis_plus_gx
mednafen_supafaust
mednafen_supergrafx
vbam
```

PicoDrive is hardware-dependent. Its Mega Drive, Master System and Sega CD
paths are native RGB565, while its Game Gear and RK2020 32X paths require byte
swapping. The 32X exception supersedes the Bubble result: the RK2020 operator
physically accepted BC Racers only with the byte swap enabled. These five
routes are recorded separately in
`share/picoarch/rgb565-route-overrides.tsv`.

FCEUmm and Nestopia use XRGB8888. The remaining RGB565 cores use native-endian
words. The two additional RK2020 PC-98 routes, Neko Project II and NP2kai,
were classified from their pinned source: their 16-bit render paths construct
native-endian RGB565 values directly. NP2kai's optional XRGB8888 mode is also
safe because the PicoArch conversion selects behavior from the pixel format
reported at runtime and only byte-swaps RGB565.

## Regression boundary

`tests/test-rk2020-picoarch-rgb565-matrix.sh` compares the table against every
unique `picoarch:` profile in `systems.json`. A missing or duplicate core, an
invalid format/order, a changed correction set, or an incomplete PicoDrive
route table fails the source gate.

```text
rk2020_picoarch_rgb565_matrix=result-ok routes=22 rgb565=20 core_byteswap=7 route_overrides=5 route_byteswap=2 xrgb8888=2
```

The launcher refuses an unclassified core rather than silently selecting an
untested color path. It logs the reported format class, byte order, scope and
evidence for later device diagnosis. An explicit `0` or `1` environment
override remains available for a bounded investigation.

`tests/test-rk2020-picoarch-launch.sh` also runs the actual launcher under the
AArch64 BusyBox build container. This caught an RK2020-only integration bug:
the route lookup passed `system` as an awk variable, but BusyBox awk reserves
that name for its `system()` function. Stderr suppression and `|| true` then
silently changed all five routes back to the core default. The launcher now
uses `system_id`, rejects malformed or duplicate classification rows, and the
test executes all five PicoDrive route decisions plus the rejection path.

```text
rk2020_picoarch_launcher_test=result-ok routes=5 busybox_awk=ok malformed_table=rejected
```

## Build and live deployment

The clean PicoArch component build passed its generated checksum catalog. The
PicoArch executable remained byte-identical to the previously accepted build;
the intended payload delta was the launcher, two tables and metadata.

The first live component verification caught a regenerated SDL1 checksum that
did not match the unchanged accepted device library. No library or PicoArch
binary had been deployed. The component catalog was rebuilt from the
pre-update live catalog, replacing only the changed entries and adding the two
new table entries. This preserves the existing device payload instead of
forcing an unrelated library replacement.

Final verification passed all 13 PicoArch component entries and all 11,289
app-layer entries. The final managed hashes are:

```text
9fc64fd7c5b646896720778610e38c08eac5f767e2fa665d6c071ba660feea29  bin/plumos-picoarch-launch
01a15fa007f15aee036105a69657f37acb505404d4a5a7e491c49c211538f5e0  share/picoarch/rgb565-byte-order.tsv
2c3a40e758aab96f99a3e9cbf81ece671a18e190f9aa4d6c929bda0b68920442  share/picoarch/rgb565-route-overrides.tsv
3a45e2fbe9769ea73e075a19475878c7418a540ab40a41394ec6f47a01eebea8  components/picoarch/manifest.json
ea02b15fa15837834f25a8e786516a650894ad2c21f8c2977abbfd602cf03119  components/picoarch/checksums.sha256
3a45e2fbe9769ea73e075a19475878c7418a540ab40a41394ec6f47a01eebea8  licenses/component-manifests/picoarch.json
5ac99e2995ba5559cd37f481cb69ac5ae79f8da645670a43369416e9ef5e1f36  manifest.json
b5a419b99733136570fbfc87845b33107c944f2ffd9760270bb03116f662aaf5  checksums.sha256
```

The recoverable pre-update archive is:

```text
/mnt/plumos-user/Backups/rk2020-picoarch-rgb565-af210a8/before.tar
SHA-256 7313c427f4f141bfe6cd4ee0fad43678116c17bb5fb11911336f8811f63cb0e5
```

This closes the predictable PicoArch byte-order class. It does not replace
physical acceptance for unrelated palette emulation, shaders, final panel
calibration, or a future core that changes its reported/output format.

## RK2020 route correction and device matrix

The correction was rebuilt as PicoArch component source ref `3dc5064`. The
strict app-layer verification and license audit passed. A seven-file hybrid
managed delta preserved every unchanged live PicoArch payload hash, then
atomically updated the launcher, route table, component metadata pair and root
metadata pair. On-device verification passed all 13 PicoArch entries and all
11,290 app-layer entries.

```text
070a618a3a71f8f89261cc215e32521c7665953dcd5561466135d3c42684a298  bin/plumos-picoarch-launch
5f8433ff2eb5f6e71cab445a6acccf05c9d193147ea5056e5173465081fda033  share/picoarch/rgb565-route-overrides.tsv
3a45e2fbe9769ea73e075a19475878c7418a540ab40a41394ec6f47a01eebea8  components/picoarch/manifest.json
a368bf6ebac0a44fd40c5d4706a50f786ae1fb15f2218460e28a703c9dd5e484  components/picoarch/checksums.sha256
3a45e2fbe9769ea73e075a19475878c7418a540ab40a41394ec6f47a01eebea8  licenses/component-manifests/picoarch.json
72cd4f722080f7644450018286f9b6559e30fbba6838f349178a8cdcad96315b  manifest.json
b5e8c4556562b055862d476986ffb80628d519a2e1b1af65dfbeba714ac54384  checksums.sha256
```

The five declared PicoDrive routes were then launched on the RK2020 with their
representative ROMs. Each real PicoArch process produced a framebuffer, held
the ALSA playback stream in `RUNNING`, logged `classification_scope=system-override`,
and stopped without leaving its runtime PID file:

| Route | Applied order | Device result |
| --- | --- | --- |
| Mega Drive / Bare Knuckle | native | launch, scanout, audio, stop pass |
| Master System / Frontier Force | native | launch, scanout, audio, stop pass |
| Game Gear / Columns | byte swap | launch, scanout, audio, stop pass |
| 32X / BC Racers | byte swap | launch, scanout, audio, stop pass; physical colour and motion accepted during the bounded override test |
| Sega CD / Fatal Fury Special demo | native | launch, scanout, audio, stop pass |

The captured logical framebuffer set is under
`output/live/2026-10-27-rk2020-picoarch-route-fix/device-matrix/`. The frontend
was restored after the matrix as PID 14940. A short physical check of one route
whose behaviour changed from the previously deployed launcher (Game Gear) and
one retained-native route (Mega Drive or Master System) remains the final
panel-level regression gate.

The recoverable pre-correction archive is:

```text
/mnt/plumos-user/Backups/rk2020-picoarch-color-3dc5064-before/before.tar
SHA-256 7c4d1efb79929de6078dbcf77f1158c5acc5374eea914c062e9a10da453c3ec8
```
