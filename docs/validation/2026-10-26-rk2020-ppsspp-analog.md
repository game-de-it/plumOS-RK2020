# RK2020 PPSSPP analog stick

Date: 2026-10-26  
Device: RK2020 at `192.168.10.110`  
Source commits: `14cd0e7`, `0c0e54b`

## Failure and cause

The physical D-pad and buttons worked in PPSSPP, but its analog stick did not.
The RK2020 `GO-Advance Gamepad` exposes `ABS_X` and `ABS_Y`; its evdev absolute
capability mask is `3`, corresponding to SDL axes 0 and 1. The existing
RK2020-specific PPSSPP `SDL_GameController` mapping described all 16 buttons
but no axes. PPSSPP therefore never received the stick through its controller
axis path even though the mutable controls file already included the standard
`10-4000` through `10-4003` analog bindings.

The controller mapping now includes:

```text
leftx:a0,lefty:a1
```

No mutable PPSSPP configuration, save data, state, or game-specific setting
was replaced.

## Build and checks

The focused emulator-menu contract passed and now asserts the analog mapping.
The patch was also applied with `git apply --check` to the clean pinned PPSSPP
1.20.4 source before the targeted ARM64 rebuild. The rebuilt binary is:

```text
425b4c1304ab6f1ca2a502e5fffd5856ca045c639217a2c85b033960204c4152  standalone/ppsspp/bin/PPSSPPSDL
d9f323e320bd2cb5fa0397f38c32dffdeeb550dcc8629dbcba1e0ca9f8c188e9  standalone/ppsspp/build-manifest.json
```

The rebuilt ELF contains the complete
`leftx:a0,lefty:a1,platform:Linux` mapping string.

## Live deployment

The update used a seven-file standalone managed delta: the PPSSPP binary and
build manifest, the standalone manifest pair, and their component/root
checksum chain. Both the live pre-update inventory and staged bundle passed
the targeted verifier; the live post-update inventory passed again after the
atomic per-file replacements.

```text
e80be13caa3eedadcefa4bfc59f8d8816006dc7bc1fda82a4706cf5e7eaa8e4f  components/standalone/manifest.json
b2c3d3a0ddd37eac83febe3f115462a8275f780cf0c6c7b3bf6fb5eba24f1f19  components/standalone/checksums.sha256
78a24185ae868e9102e80e79f5fc7210ba838dbfb1c749bf6d72465ce9c236c4  manifest.json
17fe59baf114248cc8821aa1ae5a2de06d077c94bcaf491849ce358afe6796b0  checksums.sha256
```

The previous seven managed files are recoverable from:

```text
/mnt/plumos-user/Backups/rk2020-ppsspp-analog-0c0e54b/before.tar
SHA-256 4398cbb797494b9b4425b4346c0714b6edfbf675c51e9acf407ac8d31d518a66
```

## Runtime and remaining physical gate

The deployed binary started Ridge Racer as PID 15820. Its running executable
hash matched the rebuilt artifact, it opened `/dev/input/event2`, and the
recent kernel tail contained no panic, Oops, internal error, unhandled fault,
or segfault signature. The frontend is intentionally stopped while the game
owns display/input; the diagnostic wrapper resumes frontend PID 10227 when
PPSSPP exits.

The game is left running for direct stick confirmation. Host and runtime
evidence prove delivery of the corrected binary and mapping, but do not by
themselves prove the physical stick moves the vehicle; that remains the only
acceptance gate for this change.
