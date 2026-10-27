# RK2020 PortMaster game display fit

Date: 2026-10-27

Device: RK2020 at `192.168.10.110`

## Report and scope

The operator accepted the PortMaster frontend application but reported that a
ports game did not fit inside the RK2020 screen. Apotris is the only installed
port and is therefore the representative physical route. This work changes the
shared PortMaster game launcher and SDL/OpenGL compatibility layer, so future
ports using that managed launcher inherit the same logical-canvas policy.

It does not assert that every upstream port has been installed or physically
played. Per-game rendering outside SDL/OpenGL or a game that deliberately
clips content remains a separate compatibility case.

## Diagnosis and correction

The panel exposes a portrait 320x480 DRM mode while PortMaster games expect a
landscape mode. The former adapter exposed 480x320 directly. Apotris therefore
created a 480x320 window even though the PortMaster build and supplied artwork
target the standard 640x480 landscape canvas.

Commit `7f40b1d` added aspect-preserving final scaling and shared SDL/OpenGL
logical-size propagation. Direct capture showed that this first correction was
insufficient because the application had already laid itself out on the smaller
480x320 canvas.

Commit `9e6047d` advances the adapter to version 57 and completes the shared
policy:

- games see a 640x480 logical display by default;
- the real SDL/KMS window remains 480x320 so no unsupported connector mode is
  selected;
- an explicitly requested game resolution replaces the default;
- SDL renderer output is aspect-fitted, centered, and quarter-turned into the
  320x480 scanout; and
- the OpenGL route consumes the same logical-size contract.

The current Apotris source confirms that its PortMaster build uses
`SDL_GetCurrentDisplayMode()` for layout and creates its window at that size.
The source also explains why the animated title artwork can touch or cross its
own logical edge: its internal 360x360 surface is scaled from display height.
That game-owned title composition is distinct from losing part of the 640x480
canvas in the OS adapter.

## Build and targeted checks

The following checks pass:

- `tests/test-portmaster-rk2020-runtime.sh`;
- `tests/test-portmaster-rk2020-exec-guard.sh`;
- `tests/test-portmaster-rk2020-rockbox.sh` on the first shared-layer revision;
- AArch64 compilation of the SDL interposer with `-Wall -Wextra -Werror`;
- the generated PortMaster component checksum set; and
- managed-delta verification before both live activations.

## Managed live deployment

The final v57 update changed nine managed files: the SDL interposer, launcher,
adapter version metadata, PortMaster component metadata/checksum, its license
manifest mirror, and the root manifest/checksum. ROMs, installed-port payloads,
Apotris saves, user settings, and PortMaster mutable state were not replaced.

The immediately prior v56 state is recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-portmaster-fit-9e6047d-before/before.tar
SHA-256 4cc9224763c917339095d630add4534d2c103443a099b20aeed24c4962a17575
```

The earlier pre-v56 state is separately preserved at:

```text
/mnt/plumos-user/Backups/rk2020-portmaster-fit-7f40b1d-before/before.tar
SHA-256 f78f24d882215547f726e588b198a8924776774cfd660d8e299e077f61c53c08
```

After v57 activation, the full PortMaster component and full app layer passed
device-side checksum verification. The live root manifest reports source ref
`9e6047d` and the component reports adapter version 57.

## Direct display evidence and remaining gate

Evidence is stored in the Git-ignored directory
`output/live/2026-10-27-rk2020-portmaster-fit/`. The corrected run logs:

```text
[plumOS] PortMaster SDL fit: requested=640x480
[plumOS] PortMaster SDL rotation: logical=640x480 -> 320x480 @ 270
```

The converted direct-scanout capture is:

```text
6556fdf9100ccd7e3e86c67c4519b04b83d7165e905551bd549407d8a3731da4  apotris-v57.png
```

It shows the complete 4:3 game canvas centered in the RK2020 landscape output,
with 26-pixel pillarbox margins on each side rather than stretching or clipping
the adapter surface. A diagnostic run also observed Apotris terminate during
its unattended title sequence after about 17 seconds.

## Physical follow-up

The first physical menu check showed that Apotris content remained left-biased
inside its complete 640x480 canvas. Source inspection found that the PortMaster
build uses a 360-pixel internal width while the inherited menu coordinates are
centered around x=120 from the older 240-pixel layout. This is application
composition, not loss of the outer canvas.

Commit `abd70d7` advances the adapter to version 58. It adds a bounded SDL
content-offset facility and enables a 160-pixel horizontal offset only for
`Apotris.sh`; every other port has the offset unset. The managed update passed
the component and full app-layer checksum gates. Its prior v57 state is
recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-portmaster-abd70d7-before/before.tar
SHA-256 04a460c8b1d6dca72920935a88152886d63e4611d2f3953ce5b756d7fdbbbe17
```

The operator then physically accepted both Apotris and the other installed
port-game displays. The shared fit and the isolated Apotris correction are
therefore physical display passes. This does not infer compatibility for an
uninstalled upstream port or a non-SDL/non-OpenGL renderer.
