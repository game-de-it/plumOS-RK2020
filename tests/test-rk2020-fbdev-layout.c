#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../vendor/plumos-frontend/src/plumos_fbdev_renderer.h"

static void expect_equal(const char *name, int actual, int expected) {
  if (actual == expected) {
    return;
  }
  fprintf(stderr, "layout mismatch: %s actual=%d expected=%d\n", name,
          actual, expected);
  exit(1);
}

int main(void) {
  struct plumos_fbdev_renderer renderer;
  struct plumos_fbdev_generic_layout layout;
  struct plumos_fbdev_motion motion;
  int columns;
  int rows;
  int grid_x;
  int grid_y;
  int tile_width;
  int tile_height;
  int gap;
  int visible_rows;

  memset(&renderer, 0, sizeof(renderer));
  renderer.physical_xres = 320;
  renderer.physical_yres = 480;
  renderer.var.xres = 320;
  renderer.var.yres = 480;
  renderer.rotation = 3;

  expect_equal("logical width", plumos_fbdev_logical_width(&renderer), 480);
  expect_equal("logical height", plumos_fbdev_logical_height(&renderer), 320);

  plumos_fbdev_generic_layout_metrics(&renderer, 1, 0, 1, 1, &layout);
  expect_equal("compact", layout.compact, 1);
  expect_equal("title y", layout.title_y, 44);
  expect_equal("first entry y", layout.first_entry_y, 72);
  expect_equal("entry scale", layout.entry_scale, 1);
  expect_equal("line height", layout.line_height, 22);
  expect_equal("footer height", layout.footer_height, 58);
  expect_equal("content bottom", layout.content_bottom_y, 252);
  visible_rows =
      (layout.content_bottom_y - layout.first_entry_y) / layout.line_height + 1;
  expect_equal("settings rows", visible_rows, 9);

  renderer.var.xres = 480;
  renderer.var.yres = 320;
  memset(&motion, 0, sizeof(motion));
  plumos_fbdev_graphic_top_layout_metrics(
      &renderer, &motion, &columns, &rows, &grid_x, &grid_y, &tile_width,
      &tile_height, &gap);
  expect_equal("top columns", columns, 3);
  expect_equal("top rows", rows, 2);
  expect_equal("top grid x", grid_x, 13);
  expect_equal("top grid y", grid_y, 64);
  expect_equal("top tile width", tile_width, 146);
  expect_equal("top tile height", tile_height, 118);
  expect_equal("top gap", gap, 8);
  expect_equal("top right edge",
               grid_x + columns * tile_width + (columns - 1) * gap, 467);
  expect_equal("top bottom edge",
               grid_y + rows * tile_height + (rows - 1) * gap, 308);

  puts("rk2020_fbdev_layout=result-ok logical=480x320 settings_rows=9 "
       "top=3x2@146x118");
  return 0;
}
