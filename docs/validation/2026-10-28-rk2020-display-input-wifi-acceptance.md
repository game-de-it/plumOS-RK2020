# RK2020 display, input, and Wi-Fi acceptance rollup

Date: 2026-10-28

## Scope

Before producing a fresh SD image, the operator explicitly confirmed that the
existing physical checks for Wi-Fi, game input, and display had been completed.
This note closes the three still-open rollup entries in `TODO.md`; it does not
replace their subsystem-specific evidence or infer results for a newly written
SD card.

## Accepted gates

- **Display:** the operator reviewed the formal display acceptance record and
  confirmed the native 320x480/60 Hz panel orientation and frontend result.
  Application and emulator display corrections remain covered by their own
  validation notes.
- **Input:** gameplay checks confirmed the RK2020 controls, including the
  digital controls and the two axes of its single analogue stick. Emulator-
  specific mappings remain separately documented because they do not all use
  the same input backend.
- **Wi-Fi:** the operator confirmed the complete RTL8821CU Wi-Fi set, including
  normal connection/SSH use, recovery and reconnect behavior, device removal
  handling, and the tested external-power fallback paths. Shutdown indicator
  behavior remains a separate power acceptance result.

## Fresh-image boundary

These are acceptance results for the current live, incrementally deployed
system. The next seed image must reproduce the committed managed files and pass
host image verification first. Booting that image from a separate SD remains a
new physical gate: first-boot partition setup, active root identity, frontend,
Wi-Fi, controls, audio, suspend, reboot, and shutdown must not be assumed from
this rollup.
