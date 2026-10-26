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
representative. It does not by itself establish the title's intended cadence,
so a known 60-frame N64 workload is still required before treating 30 fps as a
global standalone cap or applying speculative performance settings.

## Diagnostic cleanup

The temporary `ShowFPS` change was restored byte-for-byte. The final live
configuration hash is:

```text
f7c1e3d9a91e030cb8863f503204094bc6429cea5576eb7a3cfd3e6b08d98c11
```

`ShowFPS = False`, no Mupen64Plus process remains, and the frontend is running.
No managed app-layer file was changed during this diagnostic.
