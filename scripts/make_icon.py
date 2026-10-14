"""Draws the StandBy Studio app icon (1024x1024, no transparency).

A phone lying sideways in StandBy, showing a flip clock and an analog clock,
with a warm glow behind it. Run: python3 scripts/make_icon.py
"""
import math
import sys

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
    px = ImageDraw.Draw(img)
    for y in range(h):
        px.line([(0, y), (w, y)], fill=lerp(top, bottom, y / (h - 1)))
    return img


# Background: deep purple to near black.
icon = vertical_gradient((S, S), (46, 16, 82), (8, 5, 16))

# Warm glow behind the phone.
glow = Image.new("RGB", (S, S), (0, 0, 0))
ImageDraw.Draw(glow).ellipse([S * 0.12, S * 0.3, S * 0.88, S * 0.86], fill=(255, 120, 20))
glow = glow.filter(ImageFilter.GaussianBlur(S * 0.09))
icon = Image.blend(icon, Image.composite(glow, icon, glow.convert("L")), 0.8)

draw = ImageDraw.Draw(icon)

# The phone, sideways.
pw, ph = S * 0.8, S * 0.46
px0, py0 = (S - pw) / 2, (S - ph) / 2 + S * 0.02
radius = S * 0.075
draw.rounded_rectangle([px0, py0, px0 + pw, py0 + ph], radius=radius, fill=(58, 58, 64))
inset = S * 0.018
draw.rounded_rectangle(
    [px0 + inset, py0 + inset, px0 + pw - inset, py0 + ph - inset],
    radius=radius - inset, fill=(4, 4, 6),
)

# Two widget tiles inside.
gap = S * 0.03
tile = ph - 2 * inset - 2 * gap
tx_left = S / 2 - gap / 2 - tile
tx_right = S / 2 + gap / 2
ty = py0 + inset + gap
tile_radius = tile * 0.2

# Left tile: flip clock.
draw.rounded_rectangle([tx_left, ty, tx_left + tile, ty + tile], radius=tile_radius, fill=(22, 22, 26))
card_gap = tile * 0.05
card_w = (tile - tile * 0.12 - card_gap) / 2
card_h = tile * 0.7
cy0 = ty + (tile - card_h) / 2
size = int(card_h * 0.72)
font = ImageFont.truetype(FONT, size)
while draw.textlength("00", font=font) > card_w * 0.9:
    size -= 8
    font = ImageFont.truetype(FONT, size)
for i, digits in enumerate(["10", "09"]):
    cx0 = tx_left + tile * 0.06 + i * (card_w + card_gap)
    card = vertical_gradient((int(card_w), int(card_h)), (66, 66, 72), (34, 34, 38))
    mask = Image.new("L", card.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, card.size[0] - 1, card.size[1] - 1], radius=card_w * 0.14, fill=255)
    icon.paste(card, (int(cx0), int(cy0)), mask)
    box = draw.textbbox((0, 0), digits, font=font)
    tw, th = box[2] - box[0], box[3] - box[1]
    draw.text(
        (cx0 + (card_w - tw) / 2 - box[0], cy0 + (card_h - th) / 2 - box[1]),
        digits, font=font, fill=(245, 245, 245),
    )
    draw.rectangle([cx0, cy0 + card_h / 2 - S * 0.003, cx0 + card_w, cy0 + card_h / 2 + S * 0.003], fill=(4, 4, 6))

# Right tile: analog clock with an orange accent.
draw.rounded_rectangle([tx_right, ty, tx_right + tile, ty + tile], radius=tile_radius, fill=(22, 22, 26))
ccx, ccy = tx_right + tile / 2, ty + tile / 2
r = tile * 0.4
draw.ellipse([ccx - r, ccy - r, ccx + r, ccy + r], fill=(14, 14, 16), outline=(70, 70, 78), width=int(S * 0.006))
for i in range(12):
    a = math.radians(i * 30)
    r1, r2 = r * (0.74 if i % 3 == 0 else 0.82), r * 0.9
    draw.line(
        [(ccx + r1 * math.sin(a), ccy - r1 * math.cos(a)), (ccx + r2 * math.sin(a), ccy - r2 * math.cos(a))],
        fill=(235, 235, 235), width=int(S * (0.011 if i % 3 == 0 else 0.006)),
    )


def hand(angle_deg, length, width, color):
    a = math.radians(angle_deg)
    draw.line([(ccx, ccy), (ccx + length * math.sin(a), ccy - length * math.cos(a))], fill=color, width=int(width))
    end = (ccx + length * math.sin(a), ccy - length * math.cos(a))
    draw.ellipse([end[0] - width / 2, end[1] - width / 2, end[0] + width / 2, end[1] + width / 2], fill=color)


hand(10 * 30 + 4.5, r * 0.5, S * 0.018, (245, 245, 245))   # 10:09 hour hand
hand(9 * 6, r * 0.74, S * 0.012, (245, 245, 245))          # minute hand
hand(30 * 6, r * 0.8, S * 0.005, ORANGE)                   # second hand
dot = S * 0.016
draw.ellipse([ccx - dot, ccy - dot, ccx + dot, ccy + dot], fill=ORANGE)

icon.resize((1024, 1024), Image.LANCZOS).save(OUT, "PNG")
print("Saved", OUT)
