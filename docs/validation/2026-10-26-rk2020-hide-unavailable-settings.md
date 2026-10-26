# RK2020 unavailable frontend-setting suppression

## Scope

The RK2020 System Settings screen exposed hardware controls whose runtime
backend was absent. In particular, `Lumination` appeared as `< N/A >`, and
the Display Color summary could be composed entirely from unavailable
contrast, hue, and saturation values. Other settings and information screens
could also retain unavailable RTC, battery, temperature, or factory-reset
values.

## Implementation

Commit `6e74dd9` makes an unavailable value a reason to omit the complete
setting row instead of rendering `N/A` or `Unavailable`. The Display Color
submenu is added only when at least one of its three runtime controls is
available. RK2020 battery and temperature rows are likewise added only after
their complete sysfs values have been read successfully.

Supported values and user settings are unchanged. The change does not add a
fallback control for hardware that lacks a runtime backend.

## Host verification

The following checks passed:

- `tests/test-app-layer-scripts.sh` (`app_layer_scripts=result-ok`);
- frontend build and 480x320 layout check
  (`rk2020_fbdev_layout=result-ok`, `frontend_component=result-ok`);
- strict app-layer checksum verification and license audit
  (`app_layer=result-ok`, 169 license files, 110 libretro cores);
- an ARM64 text-renderer run that navigated to System Settings and found no
  `N/A`, `Unavailable`, `Lumination`, or `Display Color` row.

## Live deployment and validation

The live update was limited to the frontend binary, frontend component
manifest/checksum, its component-manifest license copy, and the top-level
manifest/checksum. Mutable settings, ROMs, saves, media, and application data
were not replaced. The previous six files are recoverable from:

```text
/mnt/plumos/state/backups/hide-na-6e74dd9-before.tar
```

The staging files passed individual SHA-256 verification before activation.
After activation, the complete frontend component and the complete app layer
passed device-side checksum verification. Both live manifests report source
ref `6e74dd9`.

The updated binary was then run on the RK2020 with the text renderer and
navigated to System Settings. The resulting eight rows were Volume,
Brightness, Time Settings, Language, System Update, Factory Reset, Storage
Check, and INFORMATION. No unavailable marker or unsupported Lumination or
Display Color row was present. The evidence is retained at:

```text
/mnt/plumos/logs/frontend-hide-na-6e74dd9-text.log
/mnt/plumos/logs/deploy-hide-na-6e74dd9-verify.log
```

The managed graphical frontend restarted with exactly one process, the
hardware-key service remained running, and `wlan0` remained `UP,LOWER_UP` at
`192.168.10.110`. Physical-panel inspection remains the final authority for
the visual result.
