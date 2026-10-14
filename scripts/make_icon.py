"""Draws the StandBy Studio app icon (1024x1024, no transparency).

An iPhone Duo folded into tent mode, its outer screen showing StandBy
(a flip clock and an analog clock), with a warm glow behind it.
Run: python3 scripts/make_icon.py
"""
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 4096  # draw big, then shrink for smooth edges
OUT = sys.argv[1] if len(sys.argv) > 1 else "App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
ORANGE = (255, 159, 10)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / max(h - 1, 1)))
    return img


def p(x, y):
    """Fractions of the canvas to pixels."""
    return (x * S, y * S)


def standby_screen(w, h):
    """The flat StandBy picture: flip clock on the left, analog clock on the right."""
    img = Image.new("RGB", (w, h), (4, 4, 6))
    d = ImageDraw.Draw(img)
    gap = h * 0.07
    tile = min(h - 2 * gap, (w - 3 * gap) / 2)
    tiles_left = (w - 2 * tile - gap) / 2
    tiles_top = (h - tile) / 2
    radius = tile * 0.2

    # Flip clock.
    x0, y0 = tiles_left, tiles_top
    d.rounded_rectangle([x0, y0, x0 + tile, y0 + tile], radius=radius, fill=(24, 24, 28))
    card_gap = tile * 0.05
    card_w = (tile - tile * 0.12 - card_gap) / 2
    card_h = tile * 0.7
    cy0 = y0 + (tile - card_h) / 2
    size = int(card_h * 0.72)
    font = ImageFont.truetype(FONT, size)
    while d.textlength("00", font=font) > card_w * 0.9:
        size -= 4
        font = ImageFont.truetype(FONT, size)
    for i, digits in enumerate(["10", "09"]):
        cx0 = x0 + tile * 0.06 + i * (card_w + card_gap)
        card = vertical_gradient((int(card_w), int(card_h)), (70, 70, 76), (36, 36, 40))
        mask = Image.new("L", card.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, card.size[0] - 1, card.size[1] - 1], radius=card_w * 0.14, fill=255)
        img.paste(card, (int(cx0), int(cy0)), mask)
        box = d.textbbox((0, 0), digits, font=font)
        tw, th = box[2] - box[0], box[3] - box[1]
        d.text((cx0 + (card_w - tw) / 2 - box[0], cy0 + (card_h - th) / 2 - box[1]), digits, font=font, fill=(245, 245, 245))
        d.rectangle([cx0, cy0 + card_h / 2 - h * 0.004, cx0 + card_w, cy0 + card_h / 2 + h * 0.004], fill=(4, 4, 6))

    # Analog clock.
    x1 = tiles_left + tile + gap
    d.rounded_rectangle([x1, y0, x1 + tile, y0 + tile], radius=radius, fill=(24, 24, 28))
    cx, cy, r = x1 + tile / 2, y0 + tile / 2, tile * 0.4
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(14, 14, 16), outline=(80, 80, 88), width=int(h * 0.01))
    for i in range(12):
        a = math.radians(i * 30)
        r1, r2 = r * (0.72 if i % 3 == 0 else 0.8), r * 0.9
        d.line([(cx + r1 * math.sin(a), cy - r1 * math.cos(a)), (cx + r2 * math.sin(a), cy - r2 * math.cos(a))],
               fill=(235, 235, 235), width=int(h * (0.02 if i % 3 == 0 else 0.011)))

    def hand(deg, length, width, color):
        a = math.radians(deg)
        end = (cx + length * math.sin(a), cy - length * math.cos(a))
        d.line([(cx, cy), end], fill=color, width=int(width))
        d.ellipse([end[0] - width / 2, end[1] - width / 2, end[0] + width / 2, end[1] + width / 2], fill=color)

    hand(10 * 30 + 4.5, r * 0.5, h * 0.032, (245, 245, 245))
    hand(9 * 6, r * 0.74, h * 0.022, (245, 245, 245))
    hand(30 * 6, r * 0.8, h * 0.009, ORANGE)
    dot = h * 0.028
    d.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=ORANGE)
    return img


def perspective_coeffs(dst, src):
    """Coefficients for Image.transform that map the flat image (src corners) onto dst corners."""
    rows = []
    for (x, y), (u, v) in zip(dst, src):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y])
    a = np.array(rows, dtype=float)
    b = np.array(src, dtype=float).reshape(8)
    return np.linalg.solve(a, b).tolist()


def paste_quad(canvas, picture, quad):
    """Warps `picture` (RGBA) onto the 4 corners in `quad` (TL, TR, BR, BL), keeping its transparency."""
    w, h = picture.size
    coeffs = perspective_coeffs(quad, [(0, 0), (w, 0), (w, h), (0, h)])
    warped = picture.transform(canvas.size, Image.PERSPECTIVE, coeffs, Image.BICUBIC)
    canvas.paste(warped, (0, 0), warped)


def panel(w, h, frame_top, frame_bottom, screen=None):
    """A flat phone half with rounded corners: metal frame, optional screen inside."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    frame = vertical_gradient((w, h), frame_top, frame_bottom).convert("RGBA")
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=h * 0.13, fill=255)
    img.paste(frame, (0, 0), mask)
    if screen is not None:
        border = h * 0.045
        sw, sh = int(w - 2 * border), int(h - 2 * border)
        smask = Image.new("L", (sw, sh), 0)
        ImageDraw.Draw(smask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=h * 0.1, fill=255)
        img.paste(screen.resize((sw, sh), Image.LANCZOS), (int(border), int(border)), smask)
    return img


# Background: deep purple to near black, with a warm glow behind the phone.
icon = vertical_gradient((S, S), (46, 16, 82), (8, 5, 16))
glow = Image.new("RGB", (S, S), (0, 0, 0))
ImageDraw.Draw(glow).ellipse([S * 0.1, S * 0.25, S * 0.9, S * 0.85], fill=(255, 120, 20))
glow = glow.filter(ImageFilter.GaussianBlur(S * 0.09))
icon = Image.blend(icon, Image.composite(glow, icon, glow.convert("L")), 0.8)

# Shadow on the table.
shadow = Image.new("L", (S, S), 0)
ImageDraw.Draw(shadow).ellipse([S * 0.08, S * 0.74, S * 0.98, S * 0.86], fill=200)
shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.025))
icon.paste((0, 0, 0), (0, 0), shadow)

# Tent mode, seen from the front and a little to the left.
# The hinge runs along the top. The back half slopes away to the right.
hinge_l, hinge_r = p(0.21, 0.252), p(0.79, 0.234)
front = [p(0.15, 0.25), p(0.85, 0.23), p(0.9, 0.77), p(0.06, 0.8)]
back = [p(0.15, 0.25), p(0.85, 0.23), p(0.98, 0.66), p(0.3, 0.68)]

PW, PH = 2400, 1500  # flat size of one half; the screen keeps this shape

# Back half (mostly hidden, darker).
paste_quad(icon, panel(PW, PH, (40, 40, 46), (22, 22, 26)), back)

# Front half: rounded metal frame with the StandBy screen.
screen = standby_screen(int(PW * 0.92), int(PH * 0.91))
paste_quad(icon, panel(PW, PH, (120, 120, 130), (60, 60, 68), screen), front)

# Hinge.
draw = ImageDraw.Draw(icon)
draw.line([hinge_l, hinge_r], fill=(120, 120, 130), width=int(S * 0.022))
draw.line([(hinge_l[0], hinge_l[1] - S * 0.006), (hinge_r[0], hinge_r[1] - S * 0.006)], fill=(170, 170, 180), width=int(S * 0.006))

icon.resize((1024, 1024), Image.LANCZOS).save(OUT, "PNG")
print("Saved", OUT)
