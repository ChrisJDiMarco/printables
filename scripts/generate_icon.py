#!/usr/bin/env python3
"""Generate the Printables app icon as a 1024x1024 PNG."""

import math
import os
import random
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    print("PIL/Pillow is required: pip install Pillow")
    sys.exit(1)


CREAM = (255, 247, 219)
CREAM_DEEP = (252, 240, 200)
CORAL = (232, 92, 92)
SKY = (52, 152, 211)
SUN = (255, 209, 81)
INK = (32, 33, 46)


def draw_icon(size: int = 1024) -> Image.Image:
    img = Image.new("RGB", (size, size), CREAM)
    draw = ImageDraw.Draw(img, "RGBA")

    # Soft cream radial backdrop
    backdrop = Image.new("RGB", (size, size), CREAM)
    bdraw = ImageDraw.Draw(backdrop)
    bdraw.ellipse(
        [size * 0.05, size * 0.05, size * 0.95, size * 0.95],
        fill=CREAM_DEEP,
    )
    backdrop = backdrop.filter(ImageFilter.GaussianBlur(80))
    img.paste(backdrop, (0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    # Decorative dots
    random.seed(42)
    palette = [
        (*SUN, 200),
        (*CORAL, 140),
        (*SKY, 180),
    ]
    for _ in range(60):
        radius = random.randint(8, 26)
        x = random.randint(20, size - 20)
        y = random.randint(20, size - 20)
        color = random.choice(palette)
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)

    # Central worksheet shape (white card)
    margin = int(size * 0.18)
    card_rect = [margin, margin, size - margin, size - margin]
    card_radius = 110
    draw_rounded(draw, card_rect, card_radius, (255, 255, 255, 255))

    # Card shadow
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    sdraw.rounded_rectangle(
        [card_rect[0], card_rect[1] + 16, card_rect[2], card_rect[3] + 16],
        radius=card_radius,
        fill=(0, 0, 0, 60),
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(28))
    img = Image.alpha_composite(img.convert("RGBA"), shadow_layer)
    draw = ImageDraw.Draw(img, "RGBA")
    draw_rounded(draw, card_rect, card_radius, (255, 255, 255, 255))

    # Top stripe + dots imitating a worksheet
    stripe_rect = [card_rect[0] + 60, card_rect[1] + 80, card_rect[2] - 60, card_rect[1] + 130]
    draw_rounded(draw, stripe_rect, 25, (*SUN, 255))

    # Big "P" with crayon vibe
    letter_size = int(size * 0.46)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", letter_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", letter_size)
        except (OSError, IOError):
            font = ImageFont.load_default()

    text = "P"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) / 2 - bbox[0]
    ty = (size - th) / 2 - bbox[1] + 20

    # Shadow letter
    draw.text((tx + 8, ty + 12), text, font=font, fill=(*INK, 35))
    # Coral letter
    draw.text((tx, ty), text, font=font, fill=CORAL)

    # Small sparkle dot on top-right
    sparkle_center = (card_rect[2] - 110, card_rect[1] + 110)
    draw_sparkle(draw, sparkle_center, 36, SUN)

    # Small blue dot bottom-left
    blue_center = (card_rect[0] + 110, card_rect[3] - 130)
    draw.ellipse(
        [blue_center[0] - 28, blue_center[1] - 28, blue_center[0] + 28, blue_center[1] + 28],
        fill=SKY,
    )

    return img.convert("RGB")


def draw_rounded(draw, rect, radius, fill):
    draw.rounded_rectangle(rect, radius=radius, fill=fill)


def draw_sparkle(draw, center, radius, color):
    cx, cy = center
    points = []
    for i in range(8):
        angle = (math.pi / 4) * i
        r = radius if i % 2 == 0 else radius * 0.4
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=color)


def main():
    out = Path(__file__).resolve().parent.parent / "Printables" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "icon-1024.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img = draw_icon(1024)
    img.save(out, "PNG", optimize=True)
    print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
