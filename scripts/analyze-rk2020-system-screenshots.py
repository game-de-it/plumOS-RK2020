#!/usr/bin/env python3
"""Analyze RK2020 system screenshots and render labeled review sheets."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat


def pixels(image: Image.Image):
    """Use Pillow's non-deprecated flat iterator when it is available."""
    flattened = getattr(image, "get_flattened_data", None)
    return flattened() if flattened else image.getdata()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--contact-sheet-dir", type=Path, required=True)
    parser.add_argument("--columns", type=int, default=4)
    parser.add_argument("--rows", type=int, default=5)
    return parser.parse_args()


def analyze(path: Path) -> dict:
    payload = path.read_bytes()
    with Image.open(path) as source:
        image = source.convert("RGB")
    width, height = image.size
    pixels = width * height
    stat = ImageStat.Stat(image)
    extrema = image.getextrema()
    histogram = image.histogram()
    black_pixels = sum(
        1 for red, green, blue in pixels(image)
        if red <= 8 and green <= 8 and blue <= 8
    )
    white_pixels = sum(
        1 for red, green, blue in pixels(image)
        if red >= 247 and green >= 247 and blue >= 247
    )
    sample = image.copy()
    sample.thumbnail((320, 240), Image.Resampling.NEAREST)
    unique_sample_colors = len(set(pixels(sample)))
    channel_ranges = [maximum - minimum for minimum, maximum in extrema]
    flags = []
    if black_pixels / pixels >= 0.995:
        flags.append("near_black_frame")
    if white_pixels / pixels >= 0.995:
        flags.append("near_white_frame")
    if max(channel_ranges) <= 2:
        flags.append("flat_frame")
    for index, name in enumerate(("red", "green", "blue")):
        other_ranges = channel_ranges[:index] + channel_ranges[index + 1:]
        if extrema[index][1] <= 5 and max(other_ranges) >= 80:
            flags.append(f"{name}_channel_missing")
    mean = list(stat.mean)
    stddev = list(stat.stddev)
    active_mean = max(mean)
    if active_mean >= 40:
        for index, name in enumerate(("red", "green", "blue")):
            if mean[index] <= active_mean * 0.08 and stddev[index] <= 5:
                flags.append(f"{name}_channel_suspicious")
    return {
        "system": path.stem,
        "file": str(path),
        "sha256": hashlib.sha256(payload).hexdigest(),
        "width": width,
        "height": height,
        "mean_rgb": [round(value, 3) for value in mean],
        "stddev_rgb": [round(value, 3) for value in stddev],
        "range_rgb": channel_ranges,
        "near_black_fraction": round(black_pixels / pixels, 6),
        "near_white_fraction": round(white_pixels / pixels, 6),
        "unique_sample_colors": unique_sample_colors,
        "flags": flags,
        "histogram_bins": len(histogram),
    }


def render_sheet(paths: list[Path], destination: Path, columns: int, rows: int) -> None:
    cell_width, cell_height = 300, 250
    label_height = 28
    sheet = Image.new("RGB", (cell_width * columns, cell_height * rows), (24, 24, 28))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)
    for index, path in enumerate(paths):
        column, row = index % columns, index // columns
        left, top = column * cell_width, row * cell_height
        with Image.open(path) as source:
            image = source.convert("RGB")
        image.thumbnail(
            (cell_width - 12, cell_height - label_height - 12),
            Image.Resampling.NEAREST,
        )
        image_left = left + (cell_width - image.width) // 2
        image_top = top + label_height + (cell_height - label_height - image.height) // 2
        sheet.paste(image, (image_left, image_top))
        draw.rectangle((left, top, left + cell_width - 1, top + cell_height - 1), outline=(72, 72, 82))
        draw.text((left + 8, top + 5), path.stem, fill=(235, 235, 240), font=font)
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, optimize=True)


def main() -> int:
    args = parse_args()
    if args.columns < 1 or args.rows < 1:
        raise SystemExit("--columns and --rows must be positive")
    paths = sorted(args.input.glob("*.png"))
    if not paths:
        raise SystemExit(f"no PNG screenshots found in {args.input}")
    records = [analyze(path) for path in paths]
    page_size = args.columns * args.rows
    args.contact_sheet_dir.mkdir(parents=True, exist_ok=True)
    sheets = []
    for page, offset in enumerate(range(0, len(paths), page_size), 1):
        destination = args.contact_sheet_dir / f"rk2020-systems-{page:02d}.png"
        render_sheet(paths[offset:offset + page_size], destination, args.columns, args.rows)
        sheets.append(str(destination))
    report = {
        "schema": 1,
        "device": "RK2020",
        "screenshot_count": len(records),
        "flagged_count": sum(bool(record["flags"]) for record in records),
        "flagged_systems": [
            {"system": record["system"], "flags": record["flags"]}
            for record in records if record["flags"]
        ],
        "contact_sheets": sheets,
        "records": records,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({
        "screenshots": len(records),
        "flagged": report["flagged_count"],
        "sheets": math.ceil(len(paths) / page_size),
    }, sort_keys=True))
    return 1 if report["flagged_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
