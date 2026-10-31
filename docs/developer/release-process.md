# Release Process

[日本語](release-process.ja.md)

This is the publication contract for a plumOS RK2020 release. The first formal
version is **0.1.0**. A successful host build is only a candidate; publication
requires acceptance of the exact compressed image on physical RK2020 hardware.

## Preconditions

- Work from a clean, committed tree at the commit intended for publication.
- Keep the registered stock RK2020 boot prefix and runtime inputs under
  `artifacts/`; they are local build inputs and are not added to the source
  archive.
- Confirm that ROMs, user BIOS files, saves, credentials, proprietary PICO-8
  runtime files, and mutable user state are absent from release inputs.
- Pass version `0.1.0` without a `v` prefix. The release metadata records the
  intended Git tag as `v0.1.0`.
- Before creating that tag, verify that no existing `v0.1.0` tag points to a
  different project or commit. This checkout currently contains historical
  Pixel2 tags inherited from its local base remote; never move a published tag
  silently.

## Build and Local Gate

Run from the repository root:

```sh
./scripts/prepare-rk2020-release.sh --version 0.1.0
```

The command rebuilds the release image, runs the source, implementation,
content, license, app-layer, System, and image gates, compares two consecutive
SD-image assemblies for identical SHA-256 values, and then builds and verifies
the release bundle. It does not create a tag or publish files.

The output names follow the other plumOS device releases:

```text
dist/plumOS-RK2020-v0.1.0/
  plumOS-RK2020-v0.1.0-sd-image.7z
  plumOS-RK2020-v0.1.0-source.tar.gz
  LICENSE
  NOTICE.md
  THIRD_PARTY_NOTICES.md
  THIRD_PARTY_NOTICES.ja.md
  RELEASE_NOTES.md
  RELEASE_MANIFEST.json
  SHA256SUMS
```

`LICENSE` applies only to plumOS-authored material. Vendor-derived stock boot
files and every third-party component retain their respective terms. Their
boundaries and packaged evidence are described by the notice files and by the
license bundles inside the image.

Re-run the non-mutating bundle verifier with:

```sh
./scripts/verify-rk2020-release-bundle.py dist/plumOS-RK2020-v0.1.0
```

## Physical Release Acceptance

Write the exact `.img` streamed from the release `.7z` to a separate SD card,
record its SHA-256, and confirm the release acceptance matrix on the device:

- cold boot, first setup, partition expansion, and second boot;
- FE navigation, POWER menu, shutdown, reboot, sleep, and resume;
- display geometry/color, controls, speaker/headphone audio, volume, and
  brightness hotkeys;
- USB Wi-Fi, DHCP, reconnect after resume, SSH, and SFTP;
- representative RetroArch, PicoArch, standalone emulator, and App routes;
- booted charging and cable-connected/cable-free shutdown behavior.

Writer completion, a host verifier, or one successful frontend boot does not
replace physical acceptance of the exact release asset.

## Publication Boundary

Only after exact-image acceptance, create `v0.1.0` at the
`RELEASE_MANIFEST.json` `source_ref` and upload every file listed in
`SHA256SUMS` plus `SHA256SUMS` itself. Do not rebuild any asset after tagging.
After upload, re-download and verify the stored assets with
`verify-rk2020-release-bundle.py --download-base URL`.
