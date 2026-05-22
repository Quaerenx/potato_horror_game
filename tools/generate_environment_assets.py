#!/usr/bin/env python3
"""Generate deterministic environment sprite sheets for the Godot project."""
from __future__ import annotations

import hashlib
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "source" / "environment"
MANIFEST_PATH = OUT_DIR / "environment_asset_manifest.json"

RNG = random.Random(4269)


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return color[0], color[1], color[2], alpha


def jittered_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    width: int = 2,
    jitter: int = 2,
) -> None:
    x0, y0, x1, y1 = box
    points = [
        (x0 + RNG.randint(-jitter, jitter), y0 + RNG.randint(-jitter, jitter)),
        (x1 + RNG.randint(-jitter, jitter), y0 + RNG.randint(-jitter, jitter)),
        (x1 + RNG.randint(-jitter, jitter), y1 + RNG.randint(-jitter, jitter)),
        (x0 + RNG.randint(-jitter, jitter), y1 + RNG.randint(-jitter, jitter)),
    ]
    draw.polygon(points, fill=fill)
    if outline is not None:
        draw.line(points + [points[0]], fill=outline, width=width, joint="curve")


def draw_stroked_ellipse(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    width: int = 2,
) -> None:
    draw.ellipse(box, fill=fill)
    if outline is not None:
        draw.ellipse(box, outline=outline, width=width)


def draw_grass_blades(
    draw: ImageDraw.ImageDraw,
    origin: tuple[int, int],
    width: int,
    height: int,
    count: int,
    bright: bool = False,
) -> None:
    ox, oy = origin
    for _ in range(count):
        x = ox + RNG.randrange(width)
        y = oy + RNG.randrange(height)
        blade_h = RNG.randint(7, 20)
        lean = RNG.randint(-7, 7)
        green = RNG.choice([(24, 84, 38), (35, 112, 48), (17, 66, 31), (55, 136, 57)])
        if bright and RNG.random() < 0.45:
            green = RNG.choice([(142, 192, 92), (118, 172, 74), (184, 196, 106)])
        draw.line((x, y, x + lean, y - blade_h), fill=rgba(green, RNG.randint(120, 210)), width=RNG.randint(1, 3))


def draw_cell_frame(draw: ImageDraw.ImageDraw, x: int, y: int, cell: int) -> None:
    draw.rectangle((x, y, x + cell - 1, y + cell - 1), outline=(255, 255, 255, 0))


def make_bush_maze_tileset() -> Path:
    cell = 64
    img = Image.new("RGBA", (cell * 8, cell * 8), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    base_path = (42, 72, 55)
    dark_leaf = (7, 42, 20)
    mid_leaf = (18, 78, 34)
    lit_leaf = (120, 164, 74)
    dirt = (86, 77, 58)

    for row in range(8):
        for col in range(8):
            x, y = col * cell, row * cell
            kind = col
            if kind == 0:
                jittered_rect(draw, (x + 1, y + 1, x + 63, y + 63), rgba(base_path, 255), rgba((21, 43, 31), 180), 2, 1)
                for _ in range(26):
                    px = x + RNG.randrange(4, 60)
                    py = y + RNG.randrange(4, 60)
                    draw.line((px, py, px + RNG.randint(-12, 12), py + RNG.randint(-4, 4)), fill=rgba((74, 96, 63), 85), width=1)
                if row % 2 == 0:
                    draw.polygon([(x + 2, y + 48), (x + 62, y + 33), (x + 62, y + 63), (x + 2, y + 63)], fill=rgba((22, 45, 31), 90))
            elif kind == 1:
                jittered_rect(draw, (x + 1, y + 1, x + 63, y + 63), rgba((74, 101, 63), 235), rgba((92, 124, 72), 140), 2, 1)
                draw.ellipse((x + 8, y + 18, x + 56, y + 48), fill=rgba((178, 190, 102), 38))
                draw_grass_blades(draw, (x + 2, y + 4), 60, 56, 34, True)
            elif kind == 2:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba(dark_leaf, 255))
                for _ in range(18):
                    cx = x + RNG.randrange(4, 60)
                    cy = y + RNG.randrange(6, 58)
                    r = RNG.randrange(7, 15)
                    draw_stroked_ellipse(draw, (cx - r, cy - r // 2, cx + r, cy + r // 2), rgba(mid_leaf, 225), rgba((4, 25, 14), 100), 1)
                draw_grass_blades(draw, (x, y), 64, 64, 30)
            elif kind == 3:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba((4, 28, 15), 255))
                for offset in range(0, 64, 9):
                    draw.line((x + offset, y + 64, x + offset + RNG.randint(-16, 16), y + RNG.randint(0, 18)), fill=rgba((34, 108, 43), 170), width=3)
                draw.rectangle((x, y + 50, x + 64, y + 64), fill=rgba((1, 15, 9), 115))
            elif kind == 4:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba((13, 64, 31), 255))
                draw.polygon([(x + 3, y + 30), (x + 61, y + 14), (x + 61, y + 50), (x + 3, y + 63)], fill=rgba((194, 202, 118), 70))
                draw_grass_blades(draw, (x + 1, y + 1), 62, 62, 44, True)
            elif kind == 5:
                jittered_rect(draw, (x + 1, y + 1, x + 63, y + 63), rgba((50, 75, 48), 245), rgba((26, 48, 33), 155), 2, 1)
                for step in range(4):
                    fx = x + 18 + step * 9 + (step % 2) * 10
                    fy = y + 12 + step * 11
                    draw.ellipse((fx - 4, fy - 7, fx + 5, fy + 8), fill=rgba((20, 16, 13), 85))
            elif kind == 6:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba((16, 58, 31), 255))
                for _ in range(8):
                    sx = x + RNG.randrange(4, 56)
                    sy = y + RNG.randrange(8, 58)
                    draw.line((sx, sy, sx + RNG.randrange(18, 42), sy - RNG.randrange(8, 24)), fill=rgba((77, 48, 24), 150), width=2)
                draw_grass_blades(draw, (x, y), 64, 64, 24)
            else:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba((22, 74, 42), 190))
                draw.ellipse((x + 5, y + 12, x + 59, y + 52), fill=rgba((210, 230, 185), 28))
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba((180, 210, 190), 18))
            draw_cell_frame(draw, x, y, cell)

    path = OUT_DIR / "bush-maze-tileset.png"
    img.save(path)
    return path


def make_factory_tileset() -> Path:
    cell = 64
    img = Image.new("RGBA", (cell * 8, cell * 8), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    concrete = (86, 84, 78)
    dark = (38, 39, 42)
    rust = (126, 72, 38)
    steel = (76, 83, 86)

    for row in range(8):
        for col in range(8):
            x, y = col * cell, row * cell
            idx = row * 8 + col
            if row == 0:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba(concrete, 255))
                for _ in range(11):
                    px = x + RNG.randrange(6, 60)
                    py = y + RNG.randrange(6, 60)
                    draw.line((px, py, px + RNG.randint(-20, 20), py + RNG.randint(-9, 9)), fill=rgba((32, 33, 35), 80), width=1)
                if col in {1, 5}:
                    draw.ellipse((x + 9, y + 19, x + 55, y + 48), fill=rgba((22, 22, 24), 110))
                if col in {2, 6}:
                    for s in range(-20, 80, 18):
                        draw.line((x + s, y + 62, x + s + 28, y + 2), fill=rgba((206, 157, 49), 155), width=5)
                        draw.line((x + s + 9, y + 62, x + s + 37, y + 2), fill=rgba((31, 31, 32), 155), width=5)
                if col in {3, 7}:
                    for gx in range(8, 64, 12):
                        draw.line((x + gx, y + 4, x + gx, y + 60), fill=rgba((38, 43, 46), 150), width=2)
                    for gy in range(8, 64, 12):
                        draw.line((x + 4, y + gy, x + 60, y + gy), fill=rgba((38, 43, 46), 130), width=2)
            elif row == 1:
                jittered_rect(draw, (x + 7, y + 12, x + 58, y + 50), rgba(steel, 255), rgba((24, 25, 27), 220), 2, 2)
                draw.rectangle((x + 12, y + 17, x + 53, y + 27), fill=rgba((32, 37, 40), 235))
                draw.rectangle((x + 14, y + 34, x + 50, y + 42), fill=rgba((21, 24, 27), 210))
                draw.ellipse((x + 45, y + 14, x + 55, y + 24), fill=rgba((195, 50, 35), 220))
            elif row == 2:
                jittered_rect(draw, (x + 8, y + 13, x + 56, y + 52), rgba((116, 70, 36), 255), rgba((53, 31, 20), 220), 2, 2)
                draw.line((x + 10, y + 32, x + 56, y + 27), fill=rgba((62, 37, 20), 135), width=3)
                draw.line((x + 31, y + 14, x + 29, y + 52), fill=rgba((57, 34, 18), 135), width=3)
            elif row == 3:
                draw.rounded_rectangle((x + 6, y + 20, x + 58, y + 45), radius=8, fill=rgba((56, 61, 65), 255), outline=rgba((24, 25, 27), 210), width=2)
                for k in range(4):
                    draw.rectangle((x + 14 + k * 10, y + 17, x + 20 + k * 10, y + 48), fill=rgba((24, 25, 28), 120))
                draw.ellipse((x + 10, y + 42, x + 22, y + 54), fill=rgba((18, 18, 19), 210))
                draw.ellipse((x + 42, y + 42, x + 54, y + 54), fill=rgba((18, 18, 19), 210))
            elif row == 4:
                draw.rectangle((x + 8, y + 12, x + 56, y + 50), fill=rgba((58, 48, 38), 240), outline=rgba((26, 22, 19), 210), width=2)
                for level in range(3):
                    yy = y + 18 + level * 11
                    draw.line((x + 10, yy, x + 54, yy), fill=rgba((136, 109, 72), 150), width=3)
                    if level != 1:
                        draw.rectangle((x + 14, yy + 2, x + 24, yy + 8), fill=rgba((102, 64, 34), 180))
            elif row == 5:
                draw.ellipse((x + 16, y + 8, x + 48, y + 26), fill=rgba((75, 88, 92), 255), outline=rgba((27, 31, 34), 230), width=2)
                draw.rectangle((x + 16, y + 17, x + 48, y + 52), fill=rgba((68, 81, 84), 255))
                draw.ellipse((x + 16, y + 43, x + 48, y + 60), fill=rgba((35, 42, 44), 230))
                draw.line((x + 19, y + 33, x + 46, y + 29), fill=rgba(rust, 135), width=4)
            elif row == 6:
                draw.rectangle((x + 10, y + 15, x + 54, y + 50), fill=rgba((91, 60, 30), 235), outline=rgba((38, 25, 14), 210), width=2)
                for slat in range(4):
                    draw.line((x + 12, y + 20 + slat * 8, x + 52, y + 15 + slat * 8), fill=rgba((150, 94, 42), 120), width=3)
            else:
                draw.rectangle((x + 6, y + 7, x + 58, y + 55), fill=rgba(dark, 80))
                for _ in range(5):
                    sx = x + RNG.randrange(12, 54)
                    sy = y + RNG.randrange(12, 54)
                    draw.line((sx, sy, sx + RNG.randrange(-18, 19), sy + RNG.randrange(-18, 19)), fill=rgba((230, 155, 60), 140), width=2)
            draw_cell_frame(draw, x, y, cell)

    path = OUT_DIR / "factory-tileset-obstacles.png"
    img.save(path)
    return path


def make_store_prop_sheet() -> Path:
    cell = 64
    img = Image.new("RGBA", (cell * 8, cell * 8), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    for row in range(8):
        for col in range(8):
            x, y = col * cell, row * cell
            idx = row * 8 + col
            if idx == 0:
                jittered_rect(draw, (x + 8, y + 26, x + 56, y + 46), rgba((55, 35, 25), 235), rgba((25, 16, 12), 190), 2, 2)
                for stripe in range(4):
                    draw.line((x + 12, y + 30 + stripe * 4, x + 52, y + 30 + stripe * 4), fill=rgba((86, 54, 35), 120), width=1)
            elif idx == 1:
                jittered_rect(draw, (x + 12, y + 18, x + 52, y + 44), rgba((145, 38, 28), 240), rgba((58, 20, 18), 210), 2, 2)
                draw.arc((x + 18, y + 5, x + 46, y + 34), 180, 360, fill=rgba((178, 55, 38), 210), width=4)
            elif idx == 2:
                draw.line((x + 10, y + 20, x + 53, y + 20), fill=rgba((170, 175, 166), 215), width=3)
                draw.line((x + 15, y + 20, x + 9, y + 46), fill=rgba((150, 157, 150), 200), width=3)
                draw.line((x + 49, y + 20, x + 55, y + 46), fill=rgba((150, 157, 150), 200), width=3)
                draw.line((x + 12, y + 34, x + 52, y + 34), fill=rgba((160, 165, 158), 170), width=2)
                draw.ellipse((x + 15, y + 45, x + 21, y + 51), fill=rgba((20, 20, 22), 220))
                draw.ellipse((x + 44, y + 45, x + 50, y + 51), fill=rgba((20, 20, 22), 220))
            elif idx == 3:
                draw.rectangle((x + 8, y + 18, x + 56, y + 44), fill=rgba((35, 42, 47), 255), outline=rgba((10, 12, 14), 210), width=2)
                draw.ellipse((x + 35, y + 23, x + 49, y + 37), fill=rgba((7, 10, 12), 240))
                draw.rectangle((x + 14, y + 22, x + 31, y + 39), fill=rgba((80, 90, 90), 140))
            elif idx == 4:
                draw.rectangle((x + 8, y + 16, x + 56, y + 48), fill=rgba((34, 48, 61), 220), outline=rgba((12, 16, 20), 220), width=2)
                for shelf in range(3):
                    yy = y + 22 + shelf * 8
                    draw.line((x + 11, yy, x + 53, yy), fill=rgba((196, 160, 72), 105), width=2)
                    for item in range(4):
                        draw.rectangle((x + 14 + item * 9, yy - 5, x + 19 + item * 9, yy - 1), fill=rgba(RNG.choice([(160, 50, 40), (40, 95, 150), (200, 170, 60)]), 180))
            elif idx == 5:
                draw.rectangle((x + 8, y + 26, x + 56, y + 46), fill=rgba((43, 39, 35), 245), outline=rgba((18, 15, 12), 220), width=2)
                draw.rectangle((x + 12, y + 14, x + 52, y + 27), fill=rgba((78, 96, 105), 160), outline=rgba((24, 27, 30), 170), width=1)
            elif idx == 6:
                draw.rectangle((x + 6, y + 24, x + 58, y + 39), fill=rgba((242, 186, 58), 115))
                draw.rectangle((x + 14, y + 29, x + 29, y + 33), fill=rgba((20, 18, 16), 170))
                draw.rectangle((x + 39, y + 29, x + 52, y + 33), fill=rgba((20, 18, 16), 150))
            elif idx == 7:
                jittered_rect(draw, (x + 18, y + 16, x + 46, y + 52), rgba((34, 78, 105), 245), rgba((12, 22, 30), 220), 2, 2)
                draw.rectangle((x + 22, y + 20, x + 42, y + 34), fill=rgba((120, 180, 200), 80))
                draw.ellipse((x + 24, y + 39, x + 32, y + 50), fill=rgba((14, 16, 18), 220))
            elif row == 1:
                draw.rectangle((x, y, x + 64, y + 64), fill=rgba((255, 210, 95), 0))
                draw.ellipse((x + 6, y + 18, x + 58, y + 46), fill=rgba((255, 216, 101), 42))
                draw.rectangle((x + 16, y + 28, x + 48, y + 36), fill=rgba((255, 228, 128), 95))
            else:
                for _ in range(9):
                    cx = x + RNG.randrange(8, 58)
                    cy = y + RNG.randrange(10, 54)
                    draw.rectangle((cx - 5, cy - 3, cx + 5, cy + 3), fill=rgba(RNG.choice([(180, 42, 36), (38, 96, 145), (222, 185, 65), (78, 88, 92)]), RNG.randint(100, 190)))
            draw_cell_frame(draw, x, y, cell)

    path = OUT_DIR / "convenience-store-prop-sheet.png"
    img.save(path)
    return path


def make_door_cutscene_sheet() -> Path:
    cell = 256
    img = Image.new("RGBA", (cell * 4, cell), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    for col in range(4):
        x = col * cell
        draw.ellipse((x + 28, 172, x + 228, 226), fill=rgba((0, 0, 0), 55))
        if col == 0:
            jittered_rect(draw, (x + 78, 42, x + 178, 184), rgba((42, 58, 65), 235), rgba((8, 12, 16), 220), 4, 3)
            draw.rectangle((x + 92, 60, x + 164, 126), fill=rgba((86, 146, 176), 80), outline=rgba((130, 190, 210), 100), width=2)
            draw.rectangle((x + 114, 132, x + 143, 164), fill=rgba((13, 16, 18), 220))
            draw.ellipse((x + 138, 147, x + 148, 157), fill=rgba((230, 160, 70), 220))
            draw.arc((x + 104, 112, x + 154, 170), 200, 340, fill=rgba((230, 170, 70), 210), width=7)
        elif col == 1:
            draw.ellipse((x + 66, 118, x + 190, 184), fill=rgba((35, 24, 20), 80))
            draw.line((x + 82, 112, x + 148, 164), fill=rgba((210, 172, 80), 255), width=8)
            draw.ellipse((x + 72, 100, x + 104, 132), outline=rgba((220, 185, 92), 240), width=7)
            draw.rectangle((x + 145, 158, x + 180, 170), fill=rgba((210, 172, 80), 230))
            draw.line((x + 86, 58, x + 174, 146), fill=rgba((240, 65, 45), 210), width=11)
            draw.line((x + 174, 58, x + 86, 146), fill=rgba((240, 65, 45), 210), width=11)
        elif col == 2:
            draw.rectangle((x + 92, 42, x + 164, 188), fill=rgba((20, 24, 27), 230), outline=rgba((80, 104, 110), 120), width=3)
            for scratch in range(5):
                sx = x + 92 + scratch * 12
                draw.line((sx, 70, sx + RNG.randint(18, 42), 160), fill=rgba((245, 245, 222), 150), width=3)
            draw.polygon([(x + 64, 184), (x + 126, 70), (x + 200, 184)], fill=rgba((3, 3, 5), 145))
            draw.ellipse((x + 114, 89, x + 142, 118), fill=rgba((230, 230, 210), 72))
        else:
            draw.polygon([(x + 10, 98), (x + 188, 40), (x + 246, 82), (x + 62, 162)], fill=rgba((255, 236, 144), 130))
            draw.polygon([(x + 0, 146), (x + 196, 80), (x + 256, 122), (x + 70, 218)], fill=rgba((255, 223, 118), 80))
            for _ in range(35):
                px = x + RNG.randrange(40, 228)
                py = RNG.randrange(92, 210)
                r = RNG.randrange(2, 8)
                draw.ellipse((px - r, py - r, px + r, py + r), fill=rgba((196, 176, 128), RNG.randrange(45, 110)))
            draw.rectangle((x + 124, 112, x + 210, 146), fill=rgba((40, 44, 48), 210), outline=rgba((12, 14, 16), 200), width=2)

    path = OUT_DIR / "store-reversal-cutscene-sheet.png"
    img.save(path)
    return path


def draw_cat_frame(draw: ImageDraw.ImageDraw, x: int, y: int, pose: int) -> None:
    body_offsets = [(0, 0), (-5, 0), (-1, -3), (4, 0), (0, 2)]
    head_offsets = [(20, -18), (16, -20), (22, -18), (18, -24), (13, -16)]
    tail_angles = [1.0, 0.55, 1.35, 0.8, 1.7]
    ox, oy = body_offsets[pose]
    hx, hy = head_offsets[pose]
    center = (x + 59 + ox, y + 72 + oy)

    draw.ellipse((x + 30, y + 90, x + 98, y + 110), fill=rgba((0, 0, 0), 60))
    draw.ellipse((center[0] - 30, center[1] - 20, center[0] + 26, center[1] + 20), fill=rgba((223, 211, 184), 255), outline=rgba((78, 61, 48), 210), width=3)
    head = (x + 59 + hx, y + 72 + hy)
    draw.polygon([(head[0] - 19, head[1] - 11), (head[0] - 9, head[1] - 31), (head[0] - 2, head[1] - 9)], fill=rgba((221, 207, 180), 255), outline=rgba((78, 61, 48), 210))
    draw.polygon([(head[0] + 3, head[1] - 10), (head[0] + 12, head[1] - 31), (head[0] + 21, head[1] - 9)], fill=rgba((221, 207, 180), 255), outline=rgba((78, 61, 48), 210))
    draw.ellipse((head[0] - 20, head[1] - 19, head[0] + 22, head[1] + 19), fill=rgba((229, 216, 190), 255), outline=rgba((78, 61, 48), 220), width=3)
    draw.ellipse((head[0] - 9, head[1] - 3, head[0] - 4, head[1] + 3), fill=rgba((20, 24, 20), 230))
    draw.ellipse((head[0] + 6, head[1] - 3, head[0] + 11, head[1] + 3), fill=rgba((20, 24, 20), 230))
    draw.arc((head[0] - 4, head[1] + 4, head[0] + 9, head[1] + 14), 15, 165, fill=rgba((95, 61, 53), 160), width=2)

    tail_base = (center[0] - 27, center[1] - 5)
    tail_tip = (
        int(tail_base[0] - math.cos(tail_angles[pose]) * 34),
        int(tail_base[1] - math.sin(tail_angles[pose]) * 28),
    )
    draw.line((tail_base[0], tail_base[1], tail_tip[0], tail_tip[1]), fill=rgba((213, 198, 169), 255), width=11)
    draw.line((tail_base[0], tail_base[1], tail_tip[0], tail_tip[1]), fill=rgba((78, 61, 48), 190), width=2)

    for leg_x in (-16, 8):
        draw.line((center[0] + leg_x, center[1] + 12, center[0] + leg_x - 4, center[1] + 29), fill=rgba((201, 187, 160), 255), width=6)
    draw.arc((head[0] - 20, head[1] + 14, head[0] + 22, head[1] + 44), 205, 335, fill=rgba((80, 54, 46), 210), width=4)
    key_x = head[0] + 8
    key_y = head[1] + 31
    draw.ellipse((key_x - 8, key_y - 8, key_x + 8, key_y + 8), outline=rgba((244, 194, 70), 240), width=3)
    draw.line((key_x + 8, key_y, key_x + 22, key_y + 9), fill=rgba((244, 194, 70), 240), width=4)
    draw.rectangle((key_x + 20, key_y + 7, key_x + 30, key_y + 11), fill=rgba((244, 194, 70), 230))


def make_key_cat_spritesheet() -> Path:
    cell = 128
    img = Image.new("RGBA", (cell * 5, cell), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for pose in range(5):
        draw_cat_frame(draw, pose * cell, 0, pose)
    path = OUT_DIR / "key-cat-animation-spritesheet.png"
    img.save(path)
    return path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_manifest(paths: list[Path]) -> None:
    assets = []
    for path in paths:
        with Image.open(path) as image:
            assets.append(
                {
                    "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                    "sha256": sha256(path),
                    "bytes": path.stat().st_size,
                    "width": image.width,
                    "height": image.height,
                    "mode": image.mode,
                    "format": image.format,
                }
            )
    manifest = {
        "asset_pack": "environment-polish",
        "version": 1,
        "purpose": "Deterministic project-local visual sheets for bush maze, factory, store reversal, key-cat animation, and store prop dressing.",
        "assets": assets,
        "grids": {
            "bush-maze-tileset.png": {"columns": 8, "rows": 8, "cell_width": 64, "cell_height": 64},
            "factory-tileset-obstacles.png": {"columns": 8, "rows": 8, "cell_width": 64, "cell_height": 64},
            "convenience-store-prop-sheet.png": {"columns": 8, "rows": 8, "cell_width": 64, "cell_height": 64},
            "store-reversal-cutscene-sheet.png": {"columns": 4, "rows": 1, "cell_width": 256, "cell_height": 256},
            "key-cat-animation-spritesheet.png": {"columns": 5, "rows": 1, "cell_width": 128, "cell_height": 128},
        },
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    paths = [
        make_bush_maze_tileset(),
        make_factory_tileset(),
        make_door_cutscene_sheet(),
        make_key_cat_spritesheet(),
        make_store_prop_sheet(),
    ]
    write_manifest(paths)
    print("ENVIRONMENT_ASSETS_OK")
    for path in paths:
        print(path.relative_to(ROOT).as_posix())
    print(MANIFEST_PATH.relative_to(ROOT).as_posix())


if __name__ == "__main__":
    main()
