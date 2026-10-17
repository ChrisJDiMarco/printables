#!/usr/bin/env python3
"""Generate a centered launch-screen image: white card with a coral P."""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("PIL/Pillow is required: pip install Pillow")
    sys.exit(1)

CORAL = (232, 92, 92, 255)
SUN = (255, 209, 81, 255)


def main():
    size = 600
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    radius = 110
    card_rect = (60, 60, size - 60, size - 60)
    draw.rounded_rectangle(card_rect, radius=radius, fill=(255, 255, 255, 255))

    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 320)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", 320)
        except (OSError, IOError):
            font = ImageFont.load_default()

    text = "P"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) / 2 - bbox[0]
    ty = (size - th) / 2 - bbox[1] + 18
    draw.text((tx, ty), text, font=font, fill=CORAL)

    sparkle_size = 90
    cx, cy = size - 130, 150
    radius = sparkle_size // 2
    points = []
    import math
    for i in range(8):
        angle = (math.pi / 4) * i
        r = radius if i % 2 == 0 else radius * 0.4
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=SUN)

    out = Path(__file__).resolve().parent.parent / "Printables" / "Resources" / "Assets.xcassets" / "LaunchMark.imageset" / "launch-mark.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
