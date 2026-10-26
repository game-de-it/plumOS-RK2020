# RK2020 frontend PicoArch catalog boundary

Date: 2026-10-27  
Implementation commit: `619a997`  
Device: RK2020 at `192.168.10.110`

## Problem

The frontend core-selection helper was cloning almost every declared
`retroarch:` profile into a `picoarch:` companion at runtime. This bypassed
the per-system catalog in `config/frontend/systems.json`. For Game Boy it
therefore exposed `PICO: mgba_modern`, even though the RK2020 PicoArch launch
route did not classify or support that candidate. Aretha failed when that
generated profile was selected.

## Resolution

Runtime companion generation was removed. `systems.json` is now the sole
source of selectable PicoArch profiles, so adding a new candidate requires an
explicit per-system declaration and the existing PicoArch route/color gates.

The clean frontend build executes the generated `plumos-text-ui` against the
packaged catalog and asserts both sides of the boundary:

- GB retains the declared PicoArch profiles `gambatte`, `gearboy`, and `vbam`.
- GB does not synthesize `mgba`, `mgba_modern`, or `tgbdual` PicoArch profiles.
- GBA retains the declared PicoArch profiles `gpsp` and `mgba`.
- GBA does not synthesize `mgba_modern`, `mednafen_gba`, `meteor`, or
  `vba_next` PicoArch profiles.

The app-layer source test also rejects any return of the removed runtime
generation function.

## Verification

The app-layer test suite passed:

```text
app_layer_scripts=result-ok
```

The clean AArch64 frontend component build passed its generated checksum
catalog and the new functional profile assertions:

```text
frontend_component=result-ok output=/work/output/frontend/rk2020/plumos
```

Only the following managed payload entries changed on the device:

```text
bin/plumos-text-ui
components/frontend/manifest.json
components/frontend/checksums.sha256
licenses/component-manifests/frontend.json
manifest.json
checksums.sha256
```

After deployment, the device reported exactly nine GB profiles: six
RetroArch profiles followed by the three declared PicoArch profiles. It
reported exactly eight GBA profiles: six RetroArch profiles followed by
`picoarch:gpsp` and `picoarch:mgba`. No generated PicoArch candidate remained.

The frontend process was running as PID 9062. The component manifest and its
license mirror matched, its `source_ref` was `619a997`, and the full root
`sha256sum -c checksums.sha256` verification completed successfully.

Aretha's per-ROM override remained absent. Its GB system override and recent
entry both remained `picoarch:gearboy`, confirming that the managed update did
not overwrite user selection state.

## Recovery

The recoverable pre-update archive is:

```text
/mnt/plumos-user/Backups/rk2020-frontend-core-catalog-619a997/before.tar
SHA-256 5718b4eec7aa88a1acd4af9fb70754ebcd7fbf293f2dd3e868dd8d7e485e9181
```

Temporary deployment files were removed after verification. The backup and
user state were retained.
