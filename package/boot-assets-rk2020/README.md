# plumOS RK2020 boot splash

`bootlogo.png` is the editable plumOS artwork shared with the
other plumOS handheld ports. `oemsplash-1080.png` is the RK2020 boot-ready
320x480 RGB PNG.

The RK2020 panel is exposed to the retained stock initramfs in portrait memory
orientation. The artwork is fitted to a 480x320 landscape canvas and rotated
90 degrees counter-clockwise for the 320x480 scanout:

```sh
magick bootlogo.png -resize 480x320 -background black -gravity center \
  -extent 480x320 -alpha remove -alpha off -colorspace sRGB \
  -type TrueColor -rotate -90 -strip \
  PNG24:oemsplash-1080.png
```

The retained stock initramfs lists `/flash/oemsplash-1080.png` before its
embedded `/splash/splash-1080.png`, but calls `load_splash()` before it mounts
`/flash`. The SD image builder installs this file at the root of `PLUMOS_BOOT`;
its `post-flash.sh` hook redraws it immediately after the boot volume is
mounted. No kernel or initramfs modification is required.

Validate the boot-ready file with:

```sh
python3 scripts/verify-rk2020-boot-splash.py \
  package/boot-assets-rk2020/oemsplash-1080.png
```
