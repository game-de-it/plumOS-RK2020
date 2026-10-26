# RK2020 Mupen64Plus standalone device check

Date: 2026-10-27  
Device: RK2020 at `192.168.10.110`  
Representative: `AeroGauge [V1.1].z64`

## Physical result

The standalone Mupen64Plus route reached gameplay with the correct panel
orientation and accepted controller input. The user accepted both the picture
and controls. Holding the physical Function/L2 button for 1500 ms exercised
the RK2020 hotkey helper's orderly `SIGTERM` path and returned to the frontend.
A short Function/L2 press remains the analog-stick/N64-D-pad mode toggle.

## Frame-rate diagnosis

The user reported that motion looked as though the route was not reaching its
expected frame rate. Rice's `ShowFPS = True` option did not draw an overlay:
this Rice revision updates only the SDL window caption every five seconds, and
the RK2020 fullscreen KMS path has no visible window decoration.

The deployed core has the same build ID as the retained unstripped build, so
the running core's internal display-list frame counter was sampled read-only
from `/proc/PID/mem`. Nine one-second samples were:

```text
547 577 607 635 666 695 724 754 784
```

That is 237 frames over 8.004 seconds, or 29.6 frames/second, with one-second
intervals ranging from 28 to 31. A separate five-second sample attributed 467
CPU ticks to Mupen64Plus, approximately 93% of one CPU core; CPU frequency was
1.2 GHz at the end of the sample. The GPU load reported 2-6% at 400 MHz and the
SoC temperature was about 52 C.

This proves a stable approximately-30-frame display-list cadence for this
representative, but it did not explain the uneven scrolling. Super Mario 64
showed the same visible stutter. Temporarily changing the CPU governor from
`ondemand` at 1.008 GHz to `performance` at the 1.296 GHz maximum produced no
visible improvement, which ruled out frequency scaling as the primary cause.

Rice had saved `VerticalSync = False`. Changing only that value to `True` made
both camera motion and scrolling visibly smoother, and the operator described
the improvement as obvious. Commit `56667fe` therefore changes Rice's RK2020
build default to VSync on and adds a one-time launcher migration. The marker
`state/standalone/mupen64plus/.rk2020-vsync-default-v1` prevents subsequent
launches from overwriting an intentional user change.

## Diagnostic cleanup

The temporary `ShowFPS` change was restored byte-for-byte. The final live
configuration hash is:

```text
f7c1e3d9a91e030cb8863f503204094bc6429cea5576eb7a3cfd3e6b08d98c11
```

`ShowFPS = False`, no Mupen64Plus process remains, and the frontend is running.
No managed app-layer file was changed during this diagnostic.

## Managed deployment and acceptance

The `56667fe` targeted build changed three payload files: the standalone
launcher, Rice plugin, and Mupen64Plus build manifest. They were deployed with
the standalone component manifest/checksum, its published manifest copy, and
the root manifest/checksum as one eight-file managed update. The latest live
metadata was used as the base so the newer PCSX-ReARMed payload and hashes were
not rolled back.

The first generated root checksum list incorrectly reconstructed unchanged
lines containing spaces. Post-update verification detected the truncated path
before any reboot. The list was regenerated from the byte-preserved pre-update
copy while replacing only the seven intended entries. Component and root
checksum verification then passed in full. The recoverable pre-update archive
is:

```text
/mnt/plumos-user/Backups/rk2020-mupen-vsync-56667fe/before.tar
SHA-256 314f5666b4c98b00777f1853f65bb50114fef8e4a31391db939d8e6df6ff7c8b
```

Final managed hashes are:

```text
be875fceea2c6622281c75382c496301c4891b3c283214050f41a44af100c470  bin/plumos-standalone-launch
eb7f9cd5c8ad339739b4bd5ebe287d058defd4698bfcbcd9d5268c5a198b7e8b  standalone/mupen64plus/build-manifest.json
4365e95f41de030bbc5b90214471067455b3ce3f68315f96b9fba3eea13c15ae  standalone/mupen64plus/lib/mupen64plus/mupen64plus-video-rice.so
02a8c10e4d57020c32c1c7f6bd24c609868b3151bd2c10389c5d07325b7a1999  components/standalone/manifest.json
69e02bd07ef50578d83f1ec3bbf14c69d58a17d4dc0239c0b5b3a743ac0657b4  components/standalone/checksums.sha256
02a8c10e4d57020c32c1c7f6bd24c609868b3151bd2c10389c5d07325b7a1999  licenses/component-manifests/standalone.json
64aa4efc7ad4f16517dac3a697ea73af0165c95d87330844b45d8aeb3b6a4c46  manifest.json
aada957fe7f921d6c64cd3d0213bde9182077ec0f6c112f395713535f23a0097  checksums.sha256
```

The operator relaunched Super Mario 64 through the frontend after deployment
and accepted the result. PID 9631 mapped the deployed Rice plugin with hash
`4365e95...`, the migration marker existed, `VerticalSync = True` remained
saved, component verification passed, and the recent kernel tail contained no
panic, Oops, internal error, unhandled fault, or segfault signature.
