"""Turns raw simulator screenshots into App Store images: gradient, headline and a device frame.

Usage: python3 scripts/make_store_screenshots.py RAW_DIR OUT_DIR
RAW_DIR has iphone/*.png and ipad/*.png from the Screenshots workflow.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT_DIRS = ["/usr/share/fonts/opentype/inter", "/usr/share/fonts/truetype/dejavu"]


def font(names, size):
    for d in FONT_DIRS:
        for n in names:
            path = os.path.join(d, n)
            if os.path.exists(path):
                return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def bold(size):
    return font(["InterDisplay-ExtraBold.otf", "InterDisplay-Bold.otf", "DejaVuSans-Bold.ttf"], size)


def medium(size):
    return font(["InterDisplay-Medium.otf", "Inter-Medium.otf", "DejaVuSans.ttf"], size)


# (raw name, headline, subline, top color, bottom color, glow color)
SLIDES = [
    ("standby-flip", "Your StandBy,\nupgraded", "15 clock styles for your nightstand",
     (40, 14, 70), (8, 5, 16), (255, 140, 20)),
    ("dvd", "Wait for\nthe corner", "The classic DVD bounce, live",
     (60, 10, 90), (10, 5, 30), (180, 60, 255)),
    ("nametag", "Tent mode\nsigns", "Name tags, Do Not Disturb and more",
     (110, 20, 20), (20, 5, 5), (255, 60, 50)),
    ("clocks", "Every style is\na widget", "Small, medium and large",
     (20, 30, 70), (5, 8, 20), (60, 140, 255)),
    ("fireplace", "Cozy mode", "Fireplace, candle and lava lamp",
     (80, 30, 5), (15, 5, 0), (255, 120, 20)),
    ("standby-synthwave", "Retro\nvibes", "Neon, LCD, Terminal, Synthwave",
     (70, 10, 70), (15, 0, 25), (255, 60, 160)),
    ("matrix", "Screensavers\nare back", "Matrix, Starfield, Mystify",
     (0, 50, 20), (0, 10, 5), (40, 255, 120)),
    ("widgets", "Widgets for\neverything", "Calendar, Moon, Countdown, Photo",
     (30, 20, 70), (8, 5, 20), (150, 100, 255)),
    ("store", "Pay once.\nKeep forever.", "No subscriptions. No ads. No tracking.",
     (60, 40, 10), (12, 8, 2), (255, 180, 40)),
]

SIZES = {"iphone": (1320, 2868), "ipad": (2064, 2752)}


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def compose(raw_path, out_path, size, headline, subline, top, bottom, glow_color, ipad):
    w, h = size
    canvas = gradient(size, top, bottom)

    # Soft glow behind the device.
    glow = Image.new("RGB", size, (0, 0, 0))
    ImageDraw.Draw(glow).ellipse([w * 0.05, h * 0.35, w * 0.95, h * 1.05], fill=glow_color)
    glow = glow.filter(ImageFilter.GaussianBlur(w * 0.12))
    canvas = Image.blend(canvas, Image.composite(glow, canvas, glow.convert("L")), 0.55)

    draw = ImageDraw.Draw(canvas)
    margin = w * 0.08
    title_size = int(w * (0.085 if not ipad else 0.07))
    title_font = bold(title_size)
    y = h * 0.055
    for line in headline.split("\n"):
        box = draw.textbbox((0, 0), line, font=title_font)
        draw.text(((w - (box[2] - box[0])) / 2 - box[0], y), line, font=title_font, fill=(255, 255, 255))
        y += title_size * 1.12
    sub_font = medium(int(title_size * 0.42))
    box = draw.textbbox((0, 0), subline, font=sub_font)
    draw.text(((w - (box[2] - box[0])) / 2 - box[0], y + title_size * 0.25), subline, font=sub_font, fill=(255, 255, 255, 200))
    text_bottom = y + title_size * 0.25 + (box[3] - box[1]) + h * 0.035

    # Device frame with the screenshot, running off the bottom edge.
    shot = Image.open(raw_path).convert("RGB")
    device_w = int(w * (0.80 if not ipad else 0.82))
    scale = device_w / shot.width
    screen = shot.resize((device_w, int(shot.height * scale)), Image.LANCZOS)
    bezel = int(device_w * (0.035 if not ipad else 0.025))
    radius = int(device_w * (0.13 if not ipad else 0.05))
    frame_size = (screen.width + bezel * 2, screen.height + bezel * 2)
    fx = (w - frame_size[0]) // 2
    fy = int(text_bottom)

    shadow = Image.new("L", size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle([fx, fy + 30, fx + frame_size[0], fy + frame_size[1] + 30], radius=radius, fill=200)
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    canvas.paste((0, 0, 0), (0, 0), shadow)

    frame = Image.new("RGB", frame_size, (18, 18, 20))
    frame_mask = rounded_mask(frame_size, radius)
    canvas.paste(frame, (fx, fy), frame_mask)
    edge = ImageDraw.Draw(canvas)
    edge.rounded_rectangle([fx, fy, fx + frame_size[0] - 1, fy + frame_size[1] - 1], radius=radius, outline=(90, 90, 100), width=4)
    canvas.paste(screen, (fx + bezel, fy + bezel), rounded_mask(screen.size, max(radius - bezel, 8)))

    canvas.save(out_path, "PNG")


def main():
    raw_dir, out_dir = sys.argv[1], sys.argv[2]
    for device, size in SIZES.items():
        os.makedirs(os.path.join(out_dir, device), exist_ok=True)
        n = 0
        for name, headline, subline, top, bottom, glow in SLIDES:
            raw = os.path.join(raw_dir, device, name + ".png")
            if not os.path.exists(raw):
                print("missing", raw)
                continue
            n += 1
            out = os.path.join(out_dir, device, f"{n:02d}-{name}.png")
            compose(raw, out, size, headline, subline, top, bottom, glow, device == "ipad")
            print("saved", out)


if __name__ == "__main__":
    main()
