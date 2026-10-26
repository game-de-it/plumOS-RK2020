# RK2020 full system device matrix

Date: 2026-10-26  
Device: RK2020 at `192.168.10.110`  
Managed live source: `17636f8`

## Method

`scripts/run-rk2020-system-matrix.py` launched one representative through the
frontend's default profile for every content-backed enabled system. Each run
used isolated RetroArch/standalone configuration, state, save, and cache bind
mounts. The probe sampled display ownership, ALSA PCM state/progress, Mali or
software GL mappings, exit status, and process cleanup. RetroArch routes also
saved a bounded core framebuffer screenshot.

The first uninterrupted sweep used 600 frames. Slow-starting or ambiguous
systems were rerun at 1200 to 2400 frames. Route corrections were rebuilt,
deployed with matching component/root manifests and checksums, and rerun using
the corrected defaults rather than profile overrides.

## Result

The enabled catalog has 88 systems:

| Result | Count | Meaning |
| --- | ---: | --- |
| clean launch/display/cleanup | 70 | Representative reached display ownership; normal probe and cleanup completed |
| content runs, core unload fails | 2 | Game & Watch aborts with `double free or corruption`; TI-83 exits with SIGSEGV after its screenshot |
| external runtime missing | 1 | PICO-8 cart exists, but proprietary `pico8.dat` is not supplied |
| no representative content | 15 | Fourteen emulator systems plus the separate PortMaster gate |

Thus 72 of the 73 content-backed systems reached a rendered screen. The only
content-backed route that did not start was PICO-8 because the commercial
runtime is absent. Game & Watch and TI-83 render, but their clean-exit defects
remain open rather than being counted as clean passes.

The 15 no-content systems are `ngp`, `wonderswancolor`, `ports`, `x68000`,
`tic80`, `vectrex`, `sg1000`, `sharpx1`, `vmu`, `wolf3d`, `zx81`, `arduboy`,
`megaduck`, `puzzlescript`, and `superbroswar`.

## Corrections proved on device

- N64, PSP, OpenBOR, and Jaguar initially exposed probe timing or zombie
  accounting defects. Retrying command planning, ignoring already-dead zombie
  group members, and allowing a longer bounded observation window changed all
  four to clean passes without changing their runtime routes.
- Arcade's first `1942a.zip` copy did not match MAME2003-Plus. `nemesis.zip`
  reached gameplay with PCM progress.
- The first FBNeo selection was a clone missing parent files. `bchopper.zip`
  reached gameplay with PCM progress.
- The supplied CPS2 files predate FBNeo's `.key` requirement. The proven
  pairing is `pgear.zip` with the already bundled FBA2012 core; it reached the
  system check and subsequent rendered content without corruption.
- Atari 5200 previously used the general Atari800 core and stopped at Memo
  Pad. The bundled `a5200` core reached the Millipede title with sound.
- Atari 8-bit previously used the Atari800 core's original 400/800 default.
  The 800XL/64K default and the raw disk's `.xfd` identity reached the YOOMP!
  title at 2400 frames with PCM progress.

## Display and color audit

There are 68 RetroArch core-frame PNGs under the local, Git-ignored
`artifacts/device-validation/2026-10-26-rk2020-system-screenshots/` tree.
`scripts/analyze-rk2020-system-screenshots.py` checks black/white/flat frames,
RGB ranges, missing channels, and suspicious channel suppression, then creates
four labeled review sheets.

After the corrected reruns there were three automatic flags, all expected:

- C64: a flat-color boot field;
- N64: a blue-dominant startup logo;
- Virtual Boy: the hardware's red monochrome palette.

Manual review found no cross-system RGB swap, missing channel, or persistent
black frame. The Amiga sample's HAM screen is blue and visually unusual, but
its UI neutrals and accent colors are intact; no second supplied Amiga title
exists to establish whether the picture content itself is correct. That item
remains a content-specific visual review, not evidence of a global scanout
color defect.

Core-frame screenshots validate emulator output before final panel scanout.
They do not independently prove LCD channel order for the four standalone
routes (PSP, NDS, OpenBOR, and Pyxel), so a short human view of those routes is
still the final physical color gate.

## Audio notes

PCM progress was observed on the corrected Atari routes and the arcade
replacements. J2ME did not advance PCM during the bounded title interval, and
TI-83 is not expected to produce continuous audio. These are recorded as
`not_observed`, not audio failures. The earlier physical hotkey/audio test
remains the output-path acceptance evidence.

## Live deployment integrity

The route fix updated the frontend catalog and RetroArch factory core options
with the frontend/RetroArch component manifests, component checksums,
component-manifest copies, root manifest, and root checksums in one managed
unit. Before replacement, the exact managed files were archived at:

`/mnt/plumos-user/Backups/rk2020-route-fix-17636f8/managed-files-before.tar`

Device verification passed the full frontend, RetroArch, and app-layer
checksum lists. The final probe found zero validation bind mounts and only the
frontend owning `/dev/fb0`; the frontend catalog reports CPS2/FBA2012 and Atari
5200/a5200, while active core options contain `atari800_system = "800XL (64K)"`.

## Reproducibility commits

- `a3b4f9c` adds the full-system device matrix.
- `faf8bec` isolates standalone cleanup by process group.
- `c40f747` adds retry, zombie-safe cleanup, profile/ROM overrides, and longer observation windows.
- `17636f8` corrects CPS2 and Atari defaults plus representative selection.
- `389fd91` and `4d24eb1` add and repair the screenshot color audit.

ROM-derived screenshots and contact sheets are deliberately excluded from Git;
the analyzer and this evidence record are versioned instead.

## 2026-10-27 physical follow-up

Later physical testing supersedes two interpretations from the automated
matrix. Game & Watch exited normally back to FE, so its `double free` remains
specific to the bounded screenshot harness/core-unload path rather than the
normal user exit path.

The TI-83 screenshot was not calculator content. It was Numero's 640x480,
small-font missing-firmware screen requesting `ti83se.rom`, `ti83plus.rom`, or
`ti83.rom`. No matching filename or known firmware MD5 was present in either
the source ROM-set BIOS tree or the live device BIOS tree. TI-83 therefore
remains firmware-blocked and must not be counted as a gameplay pass. Commit
`b5733de` prevents that unreadable core screen from taking over the display and
reports the missing BIOS through FE instead.

A different Amiga game was then viewed on the physical RK2020 and its color was
normal. This closes the color-specific ambiguity raised by the unusually blue
HAM sample; it does not by itself replace unrelated Amiga gameplay, input,
audio, save, or exit checks.

The user later supplied a licensed PICO-8 0.2.7 AArch64 runtime. The managed
`standalone:pico8` route launched `51752.p8`, loaded both plumOS adapters, and
produced an upright centered 4:3 direct KMS scanout. Programmatic stop returned
cleanly to FE. This removes the missing-runtime blocker, while physical control,
audible-output, color, and hotkey-exit acceptance remain open.
