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

Commit `9990891` corrects the later physical clipping report. The RK2020
renderer exposes a 480x320 logical surface after panel rotation, but
NextCommander had hard-coded a 640x480 software surface. The right 160 columns
and lower 160 rows were therefore outside the scanout. NextCommander now sizes
its software surface from the renderer's logical width and height.

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
| Scraping | Physical functional pass | The operator completed scraping successfully. |
| File Manager | Physical functional pass | The corrected 480x320 layout keeps both panels and the footer on screen. The operator accepted display, navigation, and a real file copy; NextCommander then exited and FE restarted cleanly. |
| Music Player | Physical functional pass | DRM, controller input, RK817 ALSA output at 48 kHz stereo, media discovery, representative playback, and clean return to FE are accepted by the operator. Commit `e6a9c9f` prevents the Music Player from treating L2 alone as exit, preserving the global L2 plus D-pad volume controls. |
| RetroArch | Pass | The contentless menu opened DRM, RK817 ALSA, RK2020 input, and libmali, then returned to FE. Earlier physical testing accepted its menu and exit controls. |
| Pyxel Setup | Ready for physical install | Packaged Pyxel 2.9.3, Pygame 2.6.1, NumPy 2.4.6, and Pillow 12.3.0 import successfully. `/roms/pyxel/requirements.txt` now contains the reviewed baseline request and status resolves it as `requirements_source=project`. The confirmed install action remains pending. |
| PortMaster | Physical GUI pass | The operator accepted the PortMaster application. Adapter 55 prepared its complete reviewed library projection, cleanup removed all mounts/processes, and FE restarted. Installed-port display fitting is tracked separately in `2026-10-27-rk2020-portmaster-game-fit.md`. |
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

- execute and physically accept the prepared Pyxel Setup project-requirements
  install;
- the forced-power-off FAT dirty bit was subsequently repaired and verified by
  the live-unmount procedure recorded in
  `2026-10-26-rk2020-live-fat-fsck.md`;
- keep Pyxel environment installation and PortMaster network update as
  separately authorized, potentially mutating tests.

## 2026-10-27 physical follow-up

The clipping diagnosis and deployment are recorded in
`2026-10-27-rk2020-nextcommander-display.md`. The operator accepted File
Manager display, controls, and file copying, and separately reported scraping
as working. The operator subsequently accepted Music Player operation, the
PortMaster GUI, Apotris, and the other installed port-game displays. These
application gates are closed. Pyxel installation and PortMaster update remain
independent.
