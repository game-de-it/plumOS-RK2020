# RK2020 frontend application validation

## Scope

This pass validates the seven entries exposed by the RK2020 frontend Apps
menu separately from emulator-route validation. It followed a reported
frontend hang with the Wi-Fi dongle LED off. The unit was recovered with a
long-press power cycle. Because that power cycle removed the volatile process
and kernel logs, it does not prove a kernel or driver root cause. The earlier
test harness had left an old framebuffer frontend process and used a watchdog
whose process match included its own command line, so subsequent application
checks use one foreground application at a time and identify processes by
their executable or managed PID file.

The recovered boot contains no pstore/ramoops record and no new kernel panic,
Oops, hung-task, watchdog, ext4, or I/O error. It does repeat the FAT warning
that the user volume was not properly unmounted, so that volume still requires
an offline filesystem check.

## Corrections

Commit `0c2e36c` corrects NextCommander's compiled primary-font path from the
FAT user volume to `/mnt/plumos/apps/nextcommander/res/font1.ttf`. The rebuilt
binary contains only the system-layer path. Its latest device log opens the
RK2020 controller and resource directory without the previous font-open
error.

Commit `6c66a08` bundles `libopusfile.so.0` with the PortMaster adapter,
registers its copyright, adds the adapter fallback to the isolated runtime,
and advances the adapter contract to version 55. On the device, runtime
preparation resolves:

- `libopusfile.so.0` to the PortMaster adapter;
- `libopus.so.0` and `libogg.so.0` to registered plumOS libraries.

The PortMaster GUI then ran for the bounded 15-second test. Its bootstrap
reached HarbourMaster configuration with no missing-library error. SIGTERM
from the test timeout produced the expected status 143, removed all temporary
bind mounts and child processes, and restored one managed frontend process.

## Build and deployment integrity

The rebuilt NextCommander and PortMaster component checksum sets passed. The
strict app-layer build passed the complete checksum verification and license
audit with 169 license files and 110 libretro cores.

The live update was limited to 14 managed files: the changed NextCommander
binary, PortMaster runtime/adapter files, their component manifests and
checksums, the two component-manifest license copies, the new opusfile license,
and the top-level app-layer manifest/checksum. Mutable PortMaster data, user
settings, ROMs, saves, and media were not replaced. The pre-update files are
recoverable from
`/mnt/plumos/state/backups/fe-apps-6c66a08-before.tar`.

The transferred staging set passed SHA-256 verification before activation.
After activation, the full NextCommander component, full PortMaster component,
and complete app layer passed device-side checksum verification. The live
top-level manifest reports source ref `6c66a08`, and the PortMaster manifest
reports adapter version 55.

## Application matrix

| Frontend entry | Result | Evidence and boundary |
| --- | --- | --- |
| Scraping | Route pass | Scraping screen loaded 26 targets and 27 discovered ROMs. A full artwork write was not started. |
| File Manager | Pass | NextCommander opened DRM and the RK2020 controller, loaded the system resource path without a font error, exited cleanly, and returned to FE. |
| Music Player | Route pass | DRM, controller input, RK817 ALSA output at 48 kHz stereo, and all media-root scans initialized. No music files are present, so decode/playback remains untested. |
| RetroArch | Pass | The contentless menu opened DRM, RK817 ALSA, RK2020 input, and libmali, then returned to FE. Earlier physical testing accepted its menu and exit controls. |
| Pyxel Setup | Status pass | Packaged Pyxel 2.9.3, Pygame 2.6.1, NumPy 2.4.6, and Pillow 12.3.0 import successfully. The destructive install action requires a second A press; installation was not run. An empty staging directory left by the interrupted earlier test was verified empty and removed. |
| PortMaster | Pass | Adapter 55 prepared its complete reviewed library projection, the GUI bootstrap ran, cleanup removed all mounts/processes, and FE restarted. No port installation was performed. |
| Update PortMaster | Guard pass | The action requires a second A press within five seconds. The network update was intentionally not executed. |

Internal Apps, UI Settings, System Settings, Network Settings, Help, and Power
screens also opened through the text renderer. These checks prove route and
runtime initialization; physical visual inspection remains the authority for
clipping, color, and readability.

## Post-test stability and remaining gates

After the final external-app test the device had one frontend process, that
process alone held `/dev/dri/card0`, `wlan0` remained `UP,LOWER_UP`, and no
NextCommander, PortMaster, Music Player, or RetroArch process remained. The
reported hang has not recurred in the corrected single-application sequence.

The following gates remain:

- visually inspect File Manager, Music Player, RetroArch, and PortMaster on the
  physical panel for clipping, color, and input response;
- add a representative music file and confirm decode, playback, seeking, and
  clean return to FE;
- optionally run one bounded scrape and verify downloaded artwork;
- run an offline FAT filesystem check because the forced power-off previously
  produced an unclean-volume kernel warning;
- keep Pyxel environment installation and PortMaster network update as
  separately authorized, potentially mutating tests.
