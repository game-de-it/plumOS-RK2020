# Supported systems, ROM directories, extensions, and emulators

[日本語](supported-systems.ja.md) | [User manual](README.md)

This table lists every system currently enabled in plumOS for RK2020.
Place ROMs below `roms/` on the FAT user volume. The first directory is
recommended. Other names are recognized aliases, but multiple aliases for one
system can create duplicate entries.

Extensions are case-insensitive. Recognition does not guarantee compatibility:
a correct BIOS, ROM set, disc layout, or game-specific support may still be
required. Prefer `.cue`, `.gdi`, or `.m3u` for multi-file discs.

RA means RetroArch, PICO means PicoArch, and SA means Standalone. Press SELECT
on a game to choose another launch method listed in its row.

## Supported systems (88)

| System | ROM directories (first recommended) | Extensions | Launch methods, emulators, and cores |
| --- | --- | --- | --- |
| NES | `roms/FC/`<br>`roms/nes/`<br>`roms/famicom/` | `.nes`, `.unf`, `.unif`, `.zip`, `.7z` | **Default:** RA `quicknes`<br>RA: `fceumm`, `nestopia`<br>PICO: `quicknes`, `fceumm`, `nestopia` |
| FDS | `roms/FDS/`<br>`roms/FC/`<br>`roms/fds/` | `.fds`, `.zip`, `.7z` | **Default:** RA `fceumm`<br>RA: `nestopia`<br>PICO: `fceumm`, `nestopia` |
| SFC | `roms/SFC/`<br>`roms/sfc/`<br>`roms/snes/` | `.sfc`, `.smc`, `.fig`, `.bs`, `.swc`, `.zip`, `.7z` | **Default:** RA `snes9x2005`<br>RA: `snes9x`, `chimerasnes`, `mednafen_supafaust`, `snes9x2002`, `snes9x2005_plus`, `snes9x2010`<br>PICO: `snes9x2005`, `snes9x`, `chimerasnes`, `mednafen_supafaust`, `snes9x2002`, `snes9x2005_plus`, `snes9x2010` |
| GB | `roms/GB/`<br>`roms/gb/` | `.gb`, `.zip`, `.7z` | **Default:** RA `gambatte`<br>RA: `mgba`, `mgba_modern`, `gearboy`, `tgbdual`, `vbam`<br>PICO: `gambatte`, `gearboy`, `vbam` |
| GBC | `roms/GBC/`<br>`roms/GB/`<br>`roms/gbc/` | `.gbc`, `.zip`, `.7z` | **Default:** RA `gambatte`<br>RA: `mgba`, `mgba_modern`, `gearboy`, `tgbdual`, `vbam`<br>PICO: `gambatte`, `gearboy`, `vbam` |
| GBA | `roms/GBA/`<br>`roms/gba/` | `.gba`, `.zip`, `.7z` | **Default:** RA `gpsp`<br>RA: `mgba`, `mgba_modern`, `mednafen_gba`, `meteor`, `vba_next`<br>PICO: `gpsp`, `mgba` |
| Mega Drive | `roms/MD/`<br>`roms/megadrive/`<br>`roms/genesis/` | `.gen`, `.md`, `.smd`, `.bin`, `.zip`, `.7z` | **Default:** RA `genesis_plus_gx`<br>RA: `picodrive`<br>PICO: `genesis_plus_gx`, `picodrive` |
| Master System | `roms/MS/`<br>`roms/MD/`<br>`roms/mastersystem/` | `.sms`, `.bin`, `.zip`, `.7z` | **Default:** RA `genesis_plus_gx`<br>RA: `picodrive`, `gearsystem`<br>PICO: `genesis_plus_gx`, `picodrive`, `gearsystem` |
| Game Gear | `roms/GG/`<br>`roms/GameGear/`<br>`roms/MD/`<br>`roms/gamegear/` | `.gg`, `.zip`, `.7z` | **Default:** RA `genesis_plus_gx`<br>RA: `picodrive`, `gearsystem`<br>PICO: `genesis_plus_gx`, `picodrive`, `gearsystem` |
| 32X | `roms/THIRTYTWOX/`<br>`roms/MD/`<br>`roms/sega32x/` | `.32x`, `.bin`, `.zip`, `.7z` | **Default:** RA `picodrive`<br>PICO: `picodrive` |
| Sega CD | `roms/SEGACD/`<br>`roms/segacd/`<br>`roms/megacd/` | `.cue`, `.chd`, `.iso`, `.m3u`, `.bin` | **Default:** RA `genesis_plus_gx`<br>RA: `picodrive`<br>PICO: `genesis_plus_gx`, `picodrive` |
| PC Engine | `roms/PCE/`<br>`roms/pcengine/`<br>`roms/tg16/` | `.pce`, `.sgx`, `.zip`, `.7z` | **Default:** RA `mednafen_pce_fast`<br>RA: `mednafen_pce`, `mednafen_supergrafx`<br>PICO: `mednafen_pce_fast`, `mednafen_supergrafx` |
| SuperGrafx | `roms/SGX/`<br>`roms/PCE/`<br>`roms/supergrafx/` | `.sgx`, `.pce`, `.zip`, `.7z` | **Default:** RA `mednafen_supergrafx`<br>RA: `mednafen_pce_fast`<br>PICO: `mednafen_supergrafx`, `mednafen_pce_fast` |
| PC Engine CD | `roms/PCECD/`<br>`roms/pcenginecd/`<br>`roms/tg16cd/` | `.cue`, `.chd`, `.iso`, `.m3u` | **Default:** RA `mednafen_pce_fast`<br>PICO: `mednafen_pce_fast` |
| PlayStation | `roms/PS/`<br>`roms/PSX/`<br>`roms/psx/` | `.cue`, `.chd`, `.pbp`, `.m3u`, `.iso`, `.img`, `.bin` | **Default:** RA `pcsx_rearmed`<br>RA: `km_duckswanstation_xtreme_amped`<br>SA: `pcsx_rearmed` |
| PSP | `roms/PSP/`<br>`roms/PPSSPP/`<br>`roms/psp/` | `.iso`, `.cso`, `.pbp` | **Default:** SA `ppsspp` |
| Nintendo DS | `roms/NDS/`<br>`roms/nds/` | `.nds` | **Default:** SA `drastic` |
| N64 | `roms/N64/`<br>`roms/n64/` | `.z64`, `.n64`, `.v64`, `.zip`, `.7z` | **Default:** RA `parallel_n64`<br>SA: `mupen64plus` |
| Dreamcast | `roms/DC/`<br>`roms/dreamcast/` | `.chd`, `.cdi`, `.gdi`, `.m3u` | **Default:** RA `flycast_xtreme`<br>RA: `flycast` |
| Neo Geo | `roms/NEOGEO/`<br>`roms/neogeo/` | `.zip`, `.7z` | **Default:** RA `fbneo`<br>RA: `fbalpha2012`, `fbalpha2012_neogeo` |
| Neo Geo CD | `roms/NEOCD/`<br>`roms/neogeocd/` | `.cue`, `.chd` | **Default:** RA `neocd` |
| NGP | `roms/NGP/`<br>`roms/ngp/` | `.ngp`, `.zip`, `.7z` | **Default:** RA `mednafen_ngp` |
| NGPC | `roms/NGPC/`<br>`roms/NGP/`<br>`roms/ngpc/` | `.ngc`, `.ngpc`, `.zip`, `.7z` | **Default:** RA `mednafen_ngp` |
| WonderSwan | `roms/WS/`<br>`roms/WSC/`<br>`roms/wonderswan/` | `.ws`, `.zip`, `.7z` | **Default:** RA `mednafen_wswan` |
| WonderSwan Color | `roms/WSC/`<br>`roms/wonderswancolor/` | `.wsc`, `.zip`, `.7z` | **Default:** RA `mednafen_wswan` |
| Atari Lynx | `roms/LYNX/`<br>`roms/lynx/` | `.lnx`, `.lyx`, `.bll`, `.o`, `.zip`, `.7z` | **Default:** RA `mednafen_lynx`<br>RA: `handy` |
| Virtual Boy | `roms/VB/`<br>`roms/virtualboy/` | `.vb`, `.vboy`, `.bin`, `.zip`, `.7z` | **Default:** RA `mednafen_vb` |
| Arcade | `roms/ARCADE/`<br>`roms/arcade/` | `.zip`, `.7z` | **Default:** RA `mame2003_plus`<br>RA: `km_mame2003_xtreme`, `fbneo`, `fbalpha2012`, `mame2000`, `mba_mini` |
| FBNeo | `roms/FBNEO/`<br>`roms/ARCADE/`<br>`roms/fbneo/` | `.zip`, `.7z` | **Default:** RA `fbneo` |
| CPS1 | `roms/CPS1/`<br>`roms/ARCADE/`<br>`roms/cps1/` | `.zip`, `.7z` | **Default:** RA `fbneo`<br>RA: `fbalpha2012` |
| CPS2 | `roms/CPS2/`<br>`roms/ARCADE/`<br>`roms/cps2/` | `.zip`, `.7z` | **Default:** RA `fbalpha2012`<br>RA: `fbneo` |
| CPS3 | `roms/CPS3/`<br>`roms/ARCADE/`<br>`roms/cps3/` | `.zip`, `.7z` | **Default:** RA `fbneo`<br>RA: `fbalpha2012`, `fbalpha2012_cps3` |
| DOS | `roms/DOS/`<br>`roms/pc/` | `.dosz`, `.conf`, `.exe`, `.bat`, `.zip` | **Default:** RA `dosbox_pure`<br>RA: `dosbox_pure_0.9.7` |
| EasyRPG | `roms/EASYRPG/`<br>`roms/easyrpg/` | `.easyrpg`, `.ldb`, `.zip` | **Default:** RA `easyrpg` |
| PICO-8 | `roms/PICO8/`<br>`roms/PICO/`<br>`roms/pico-8/`<br>`roms/pico8/` | `.p8`, `.png` | **Default:** SA `pico8`<br>RA: `fake08`, `retro8` |
| ScummVM | `roms/SCUMMVM/`<br>`roms/scummvm/` | `.scummvm`, `.svm` | **Default:** RA `scummvm` |
| OpenBOR | `roms/OPENBOR/`<br>`roms/openbor/` | `.pak` | **Default:** SA `openbor` |
| Ports | `roms/PORTS/`<br>`roms/ports/` | `.sh` | **Default:** External `port` |
| MSX | `roms/MSX/`<br>`roms/msx/` | `.rom`, `.mx1`, `.mx2`, `.dsk`, `.cas`, `.zip`, `.7z` | **Default:** RA `bluemsx`<br>RA: `fmsx` |
| PC-88 | `roms/PC88/`<br>`roms/pc-8800/` | `.d88`, `.u88`, `.m3u`, `.zip` | **Default:** RA `quasi88` |
| PC-98 | `roms/PC98/`<br>`roms/pc-9800/` | `.d88`, `.fdi`, `.hdi`, `.fdd`, `.nhd`, `.hdd`, `.m3u`, `.zip` | **Default:** RA `np2kai`<br>RA: `nekop2`<br>PICO: `np2kai`, `nekop2` |
| X68000 | `roms/X68000/`<br>`roms/x68000/` | `.dim`, `.hdf`, `.xdf`, `.m3u`, `.zip`, `.7z` | **Default:** RA `px68k` |
| TIC-80 | `roms/TIC/`<br>`roms/tic-80/` | `.tic` | **Default:** RA `tic80` |
| Atari 2600 | `roms/ATARI2600/`<br>`roms/atari2600/` | `.a26`, `.bin`, `.zip`, `.7z` | **Default:** RA `stella2014` |
| Atari 7800 | `roms/ATARI7800/`<br>`roms/atari7800/` | `.a78`, `.bin`, `.cdf`, `.zip`, `.7z` | **Default:** RA `prosystem` |
| Vectrex | `roms/VECTREX/`<br>`roms/vectrex/` | `.vec`, `.bin`, `.zip`, `.7z` | **Default:** RA `vecx` |
| Supervision | `roms/SUPERVISION/`<br>`roms/supervision/` | `.sv`, `.bin`, `.zip`, `.7z` | **Default:** RA `potator` |
| Odyssey2 | `roms/ODYSSEY2/`<br>`roms/VIDEOPAC/`<br>`roms/odyssey2/` | `.bin`, `.zip`, `.7z` | **Default:** RA `o2em` |
| Game & Watch | `roms/GW/`<br>`roms/GAMEANDWATCH/`<br>`roms/gameandwatch/` | `.mgw`, `.zip` | **Default:** RA `gw` |
| Pokemon Mini | `roms/POKEMINI/`<br>`roms/pokemini/` | `.min`, `.zip`, `.7z` | **Default:** RA `pokemini` |
| Doom | `roms/DOOM/`<br>`roms/doom/` | `.wad`, `.iwad`, `.pwad`, `.zip` | **Default:** RA `prboom` |
| Pyxel | `roms/pyxel/`<br>`roms/PYXEL/` | `.pyxapp`, `.py` | **Default:** Pyxel `rk2020` |
| 3DO | `roms/PANASONIC/`<br>`roms/3do/` | `.iso`, `.chd`, `.bin`, `.cue` | **Default:** RA `opera` |
| Amiga | `roms/AMIGA/`<br>`roms/amiga/` | `.adf`, `.adz`, `.dms`, `.fdi`, `.ipf`, `.hdf`, `.hdz`, `.lha`, `.slave`, `.info`, `.cue`, `.ccd`, `.nrg`, `.mds`, `.iso`, `.chd`, `.uae`, `.m3u`, `.zip`, `.7z`, `.rp9` | **Default:** RA `puae`<br>RA: `puae2021`, `uae4arm`, `km_puae_xtreme_amped` |
| Atari 5200 | `roms/FIFTYTWOHUNDRED/`<br>`roms/atari5200/` | `.a52`, `.bin`, `.zip`, `.7z` | **Default:** RA `a5200`<br>RA: `atari800` |
| Atari 8-bit | `roms/EIGHTHUNDRED/`<br>`roms/atari800/` | `.atr`, `.xfd`, `.dcm`, `.cas`, `.bin`, `.atx`, `.car`, `.rom`, `.com`, `.xex`, `.m3u`, `.zip`, `.7z` | **Default:** RA `atari800` |
| Atari ST | `roms/ATARIST/`<br>`roms/atarist/` | `.st`, `.msa`, `.zip`, `.stx`, `.dim`, `.ipf`, `.vhd`, `.gem`, `.ide`, `.m3u` | **Default:** RA `hatari` |
| Commodore 64 | `roms/COMMODORE/`<br>`roms/c64/` | `.d64`, `.d71`, `.d80`, `.d81`, `.d82`, `.g64`, `.g41`, `.x64`, `.t64`, `.tap`, `.prg`, `.p00`, `.crt`, `.bin`, `.zip`, `.gz`, `.m3u` | **Default:** RA `vice_x64`<br>RA: `frodo` |
| Cannonball | `roms/CANNONBALL/`<br>`roms/cannonball/` | `.game`, `.88` | **Default:** RA `cannonball` |
| Cave Story | `roms/CAVESTORY/`<br>`roms/cavestory/` | `.exe` | **Default:** RA `nxengine` |
| ChaiLove | `roms/CHAILOVE/`<br>`roms/chailove/` | `.chai`, `.chailove` | **Default:** RA `chailove` |
| Fairchild Channel F | `roms/FAIRCHILD/`<br>`roms/channelf/` | `.bin`, `.chf`, `.rom`, `.zip` | **Default:** RA `freechaf` |
| ColecoVision | `roms/COLECO/`<br>`roms/coleco/` | `.rom`, `.ri`, `.mx1`, `.mx2`, `.col`, `.dsk`, `.cas`, `.sg`, `.sc`, `.m3u`, `.zip`, `.7z` | **Default:** RA `bluemsx` |
| Amstrad CPC | `roms/CPC/`<br>`roms/amstradcpc/` | `.dsk`, `.sna`, `.zip`, `.tap`, `.cdt`, `.voc`, `.cpr`, `.m3u`, `.kcr` | **Default:** RA `crocods`<br>RA: `cap32` |
| Dinothawr | `roms/DINOTHAWR/`<br>`roms/dinothawr/` | `.game` | **Default:** RA `dinothawr` |
| Intellivision | `roms/INTELLIVISION/`<br>`roms/intellivision/` | `.int`, `.bin`, `.rom`, `.zip`, `.7z` | **Default:** RA `freeintv` |
| Java ME | `roms/J2ME/`<br>`roms/j2me/` | `.jar`, `.sqc`, `.jam`, `.jad`, `.kjx`, `.adf`, `.sec`, `.sto`, `.sp`, `.sp0`, `.sp1`, `.sp2`, `.sp3`, `.sp4`, `.sp5`, `.sp6`, `.sp7`, `.sp8`, `.sp9` | **Default:** RA `squirreljme` |
| Atari Jaguar | `roms/JAGUAR/`<br>`roms/atarijaguar/` | `.j64`, `.jag`, `.rom`, `.abs`, `.cof`, `.bin`, `.prg` | **Default:** RA `virtualjaguar` |
| LowRes NX | `roms/LOWRESNX/`<br>`roms/lowresnx/` | `.nx` | **Default:** RA `lowresnx` |
| Lutro | `roms/LUTRO/`<br>`roms/lutro/` | `.lutro`, `.love`, `.lua` | **Default:** RA `lutro` |
| MicroW8 | `roms/MICROW8/`<br>`roms/microw8/` | `.uw8`, `.wasm` | **Default:** RA `uw8` |
| Game Music Emu | `roms/MUSIC/`<br>`roms/music/` | `.ay`, `.gbs`, `.gym`, `.hes`, `.kss`, `.nsf`, `.nsfe`, `.sap`, `.spc`, `.vgm`, `.vgz`, `.zip` | **Default:** RA `gme` |
| PC-FX | `roms/PCFX/`<br>`roms/pcfx/` | `.cue`, `.ccd`, `.toc`, `.chd` | **Default:** RA `mednafen_pcfx` |
| Quake | `roms/QUAKE/`<br>`roms/quake/` | `.pak` | **Default:** RA `tyrquake` |
| SG-1000 | `roms/SEGASGONE/`<br>`roms/sg-1000/` | `.sg`, `.mv`, `.bin`, `.rom`, `.sms`, `.gg` | **Default:** RA `gearsystem`<br>RA: `bluemsx`, `genesis_plus_gx`, `picodrive` |
| Sharp X1 | `roms/XONE/`<br>`roms/x1/` | `.dx1`, `.zip`, `.2d`, `.2hd`, `.tfd`, `.d88`, `.88d`, `.hdm`, `.xdf`, `.dup`, `.tap`, `.cmd` | **Default:** RA `x1` |
| Thomson MO/TO | `roms/THOMSON/`<br>`roms/moto/` | `.fd`, `.sap`, `.k7`, `.m7`, `.m5`, `.rom` | **Default:** RA `theodore` |
| TI-83 | `roms/TI83/`<br>`roms/ti83/` | `.8xp`, `.8xk`, `.8xg` | **Default:** RA `numero` |
| Uzebox | `roms/UZEBOX/`<br>`roms/uzebox/` | `.uze` | **Default:** RA `uzem` |
| Commodore VIC-20 | `roms/VIC20/`<br>`roms/vic20/` | `.d64`, `.d6z`, `.d71`, `.d7z`, `.d80`, `.d81`, `.d82`, `.d8z`, `.g64`, `.g6z`, `.g41`, `.g4z`, `.x64`, `.x6z`, `.nib`, `.nbz`, `.d2m`, `.d4m`, `.t64`, `.tap`, `.tcrt`, `.prg`, `.p00`, `.crt`, `.bin`, `.cmd`, `.m3u`, `.vfl`, `.vsf`, `.zip`, `.7z`, `.gz`, `.20`, `.40`, `.60`, `.a0`, `.b0`, `.rom` | **Default:** RA `vice_xvic` |
| Dreamcast VMU | `roms/VMU/`<br>`roms/vmu/` | `.vms`, `.dci`, `.bin` | **Default:** RA `vemulator` |
| Wolfenstein 3D | `roms/WOLF3D/`<br>`roms/wolf3d/` | `.wl6`, `.n3d`, `.sod`, `.sdm`, `.wl1`, `.pk3`, `.exe` | **Default:** RA `ecwolf` |
| ZX-81 | `roms/ZXEIGHTYONE/`<br>`roms/zx81/` | `.p`, `.tzx`, `.t81`, `.zip` | **Default:** RA `81` |
| ZX Spectrum | `roms/ZXS/`<br>`roms/zxspectrum/` | `.tzx`, `.tap`, `.z80`, `.rzx`, `.scl`, `.trd`, `.dsk`, `.dck`, `.sna`, `.szx`, `.zip`, `.gz`, `.udi`, `.mgt`, `.img` | **Default:** RA `fuse` |
| Arduboy | `roms/ARDUBOY/`<br>`roms/arduboy/` | `.hex` | **Default:** RA `arduous` |
| Mega Duck | `roms/MEGADUCK/`<br>`roms/megaduck/` | `.bin`, `.duck` | **Default:** RA `sameduck` |
| PuzzleScript | `roms/PUZZLESCRIPT/`<br>`roms/puzzlescript/` | `.pz`, `.pzp` | **Default:** RA `puzzlescript` |
| Super Bros War | `roms/SUPERBROSWAR/`<br>`roms/superbroswar/` | `.game` | **Default:** RA `km_superbroswar` |

## Currently disabled systems

These entries remain in the internal catalog but are not exposed as supported on
RK2020 and do not normally appear on TOP.

| System | Internal ID |
| --- | --- |
| Saturn | `saturn` |
| MAME 2003+ | `mame2003plus` |
| 2048 | `2048` |
| Elektronika BK | `bk` |
| Daphne | `daphne` |
| Flashback | `flashback` |
| Mr.Boom | `mrboom` |
| Palm OS | `palm` |
| Rick Dangerous | `rickdangerous` |

## Related topics

- [Emulators and in-game controls](emulators.md)
- [SD storage and reimaging](storage-and-reimaging.md)
- [BIOS files, saves, and screenshots](save-data.md)

This file is generated from `package/frontend-rk2020/systems.json` by
`scripts/generate-rk2020-supported-systems-doc.py`.
