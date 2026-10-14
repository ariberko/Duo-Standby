"""Turns raw simulator screenshots into App Store images.

Usage: python3 scripts/make_store_screenshots.py RAW_DIR OUT_DIR
RAW_DIR has iphone/*.png and ipad/*.png from the Screenshots workflow.
Shots taken with -screenshotLandscape are drawn sideways; this script turns them back.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT_DIRS = ["/usr/share/fonts/opentype/inter", "/usr/share/fonts/truetype/dejavu"]
SIZES = {"iphone": (1320, 2868), "ipad": (2064, 2752)}


def font(names, size):
    for d in FONT_DIRS:
        for n in names:
            path = os.path.join(d, n)
            if os.path.exists(path):
                return ImageFont.truetype(path, int(size))
    return ImageFont.load_default()


def black(size):
    return font(["InterDisplay-Black.otf", "InterDisplay-ExtraBold.otf", "DejaVuSans-Bold.ttf"], size)


def medium(size):
    return font(["InterDisplay-Medium.otf", "Inter-Medium.otf", "DejaVuSans.ttf"], size)


def semibold(size):
    return font(["Inter-SemiBold.otf", "InterDisplay-SemiBold.otf", "DejaVuSans-Bold.ttf"], size)


# kind: portrait (app screen), landscape (one sideways shot), pair (two sideways shots), tent (name tag on a folded phone).
# Words between *stars* in the headline get the accent color.
SLIDES = [
    dict(kind="pair", shots=["standby-flip", "standby-synthwave"], eyebrow="STANDBY",
         headline="Your StandBy,\n*upgraded*", sub="15 clock styles for your nightstand",
         bg=((34, 12, 64), (6, 4, 14)), accent=(255, 159, 10), blobs=[(255, 120, 20), (255, 60, 160)]),
    dict(kind="tent", shots=["nametag"], eyebrow="TENT MODE",
         headline="Fold it.\n*Say it.*", sub="Name tags and signs for your desk",
         bg=((70, 10, 14), (12, 3, 4)), accent=(255, 90, 80), blobs=[(255, 40, 40), (255, 140, 40)]),
    dict(kind="landscape", shots=["dvd"], eyebrow="LIVE SCENES",
         headline="Wait for\nthe *corner*", sub="The 90s DVD bounce, live on your desk",
         chips=["DVD", "Matrix", "Starfield", "Mystify"],
         bg=((44, 8, 80), (8, 4, 24)), accent=(190, 110, 255), blobs=[(150, 60, 255), (40, 120, 255)]),
    dict(kind="portrait", shots=["clocks"], eyebrow="WIDGETS",
         headline="Every style is\na *widget*", sub="Small, medium, large and Lock Screen",
         bg=((14, 26, 66), (4, 6, 18)), accent=(90, 170, 255), blobs=[(40, 120, 255), (0, 200, 200)]),
    dict(kind="pair", shots=["fireplace", "lava"], eyebrow="COZY",
         headline="Cozy\n*mode*", sub="Fireplace, candle and lava lamp",
         bg=((64, 22, 4), (12, 4, 0)), accent=(255, 140, 40), blobs=[(255, 110, 20), (230, 40, 120)]),
    dict(kind="pair", shots=["matrix", "mystify"], eyebrow="SCREENSAVERS",
         headline="Screensavers\nare *back*", sub="Matrix, Starfield and Mystify",
         bg=((0, 40, 22), (0, 8, 5)), accent=(60, 255, 140), blobs=[(30, 220, 110), (60, 90, 255)]),
    dict(kind="landscape", shots=["led"], eyebrow="SMART SIGNS",
         headline="Your desk,\n*in lights*", sub="Scroll any message like a real LED sign",
         chips=["LED Scroller", "Talk Timer", "Now Serving"],
         bg=((60, 6, 12), (10, 2, 4)), accent=(255, 70, 60), blobs=[(255, 40, 40), (255, 160, 40)]),
    dict(kind="portrait", shots=["nametag-editor"], eyebrow="NAME TAG",
         headline="Make it\n*yours*", sub="16 presets, your colors, your saved tags",
         bg=((60, 34, 4), (12, 7, 1)), accent=(255, 170, 40), blobs=[(255, 150, 20), (255, 80, 60)]),
    dict(kind="portrait", shots=["widgets"], eyebrow="MORE WIDGETS",
         headline="Widgets for\n*everything*", sub="Calendar, Moon, Countdown, Quote, Photo",
         bg=((28, 18, 70), (7, 5, 20)), accent=(160, 120, 255), blobs=[(130, 90, 255), (255, 90, 200)]),
    dict(kind="portrait", shots=["store"], eyebrow="NO SUBSCRIPTIONS",
         headline="Pay once.\n*Keep forever.*", sub="Lots of styles free. No ads. No tracking.",
         bg=((56, 38, 8), (11, 8, 2)), accent=(255, 200, 60), blobs=[(255, 180, 40), (255, 110, 40)]),
]


# ---------- background ----------

def background(size, top, bottom, blobs, rng):
    w, h = size
    t = np.linspace(0, 1, h)[:, None, None]
    img = np.array(top, float) * (1 - t) + np.array(bottom, float) * t
    img = np.repeat(img, w, axis=1)

    # Two big soft color blobs.
    for i, color in enumerate(blobs):
        cx, cy = (w * 0.15, h * 0.42) if i == 0 else (w * 0.9, h * 0.78)
        r = w * 0.75
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r
        a = np.clip(1 - d, 0, 1) ** 2 * 0.55
        img = img * (1 - a[..., None]) + np.array(color, float) * a[..., None]

    # Vignette and film grain.
    yy, xx = np.mgrid[0:h, 0:w]
    v = np.sqrt(((xx - w / 2) / (w * 0.75)) ** 2 + ((yy - h / 2) / (h * 0.75)) ** 2)
    img *= np.clip(1.15 - v * 0.45, 0.55, 1)[..., None]
    img += rng.normal(0, 3.5, (h, w, 1))
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


# ---------- text ----------

def text_width(draw, s, f):
    b = draw.textbbox((0, 0), s, font=f)
    return b[2] - b[0]


def draw_header(canvas, slide, s):
    w, _ = canvas.size
    draw = ImageDraw.Draw(canvas)
    accent = slide["accent"]

    # Eyebrow pill.
    ef = semibold(30 * s)
    label = slide["eyebrow"]
    spacing = 6 * s
    lw = sum(text_width(draw, c, ef) + spacing for c in label) - spacing
    ph, pw = 64 * s, lw + 64 * s
    px, py = (w - pw) / 2, 150 * s
    pill = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    pd = ImageDraw.Draw(pill)
    pd.rounded_rectangle([px, py, px + pw, py + ph], radius=ph / 2, fill=accent + (46,), outline=accent + (150,), width=max(2, int(2 * s)))
    canvas.alpha_composite(pill)
    x = px + 32 * s
    for c in label:
        draw.text((x, py + ph / 2), c, font=ef, fill=accent, anchor="lm")
        x += text_width(draw, c, ef) + spacing

    # Headline with accent words.
    size = 128 * s
    hf = black(size)
    y = py + ph + 60 * s
    for line in slide["headline"].split("\n"):
        parts = [(p, i % 2 == 1) for i, p in enumerate(line.split("*")) if p]
        total = sum(text_width(draw, p, hf) for p, _ in parts)
        x = (w - total) / 2
        for p, hot in parts:
            if hot:
                glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
                ImageDraw.Draw(glow).text((x, y), p, font=hf, fill=accent + (200,))
                canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(28 * s)))
            draw.text((x, y), p, font=hf, fill=accent if hot else (255, 255, 255))
            x += text_width(draw, p, hf)
        y += size * 1.08

    sf = medium(46 * s)
    y += 24 * s
    draw.text((w / 2, y), slide["sub"], font=sf, fill=(255, 255, 255, 190), anchor="ma")
    return y + 46 * s + 70 * s


def draw_chips(canvas, chips, y, accent, s):
    draw = ImageDraw.Draw(canvas)
    f = semibold(36 * s)
    pad, gap, ch = 34 * s, 18 * s, 78 * s
    widths = [text_width(draw, c, f) + pad * 2 for c in chips]
    x = (canvas.width - sum(widths) - gap * (len(chips) - 1)) / 2
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for c, cw in zip(chips, widths):
        ld.rounded_rectangle([x, y, x + cw, y + ch], radius=ch / 2, fill=(255, 255, 255, 26), outline=(255, 255, 255, 70), width=2)
        ld.text((x + cw / 2, y + ch / 2), c, font=f, fill=(255, 255, 255, 235), anchor="mm")
        x += cw + gap
    canvas.alpha_composite(layer)


# ---------- devices ----------

def load_shot(path, sideways):
    shot = Image.open(path).convert("RGB")
    return shot.rotate(90, expand=True) if sideways else shot


def rounded_mask(size, radius, corners=None):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255, corners=corners)
    return m


def device(screen, ipad, hinge_top=False):
    """Frames a screen in a titanium phone or iPad body. Returns RGBA.
    hinge_top squares the top corners, like the folded edge of the Duo."""
    corners = (False, False, True, True) if hinge_top else None
    short = min(screen.size)
    bezel = int(short * (0.045 if ipad else 0.05))
    ring = max(4, int(short * 0.012))
    radius = int(short * (0.075 if ipad else 0.2))
    size = (screen.width + 2 * bezel, screen.height + 2 * bezel)
    body = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=(122, 122, 132, 255), corners=corners)
    d.rounded_rectangle([ring // 3, ring // 3, size[0] - 1 - ring // 3, size[1] - 1 - ring // 3], radius=radius, fill=(70, 70, 78, 255), corners=corners)
    d.rounded_rectangle([ring, ring, size[0] - 1 - ring, size[1] - 1 - ring], radius=radius - ring, fill=(8, 8, 10, 255), corners=corners)
    body.paste(screen, (bezel, bezel), rounded_mask(screen.size, max(radius - bezel, 8), corners))
    # Soft glass shine on the top left.
    shine = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shine).polygon([(0, 0), (size[0] * 0.55, 0), (0, size[1] * 0.55)], fill=(255, 255, 255, 14))
    body.alpha_composite(Image.composite(shine, Image.new("RGBA", size, (0, 0, 0, 0)), rounded_mask(size, radius, corners)))
    return body


def place(canvas, img, center, angle, glow_color, s):
    """Drops a device on the canvas with a shadow and a colored glow."""
    if angle:
        img = img.rotate(angle, resample=Image.BICUBIC, expand=True)
    x = int(center[0] - img.width / 2)
    y = int(center[1] - img.height / 2)
    alpha = img.getchannel("A")

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    glow.paste(Image.new("RGBA", img.size, glow_color + (120,)), (x, y), alpha)
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90 * s)))

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", img.size, (0, 0, 0, 170)), (x, int(y + 40 * s)), alpha)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(40 * s)))
    canvas.alpha_composite(img, (x, y))


def perspective_coeffs(src, dst):
    """Coefficients for Image.transform that map dst quad points back to src points."""
    rows, rhs = [], []
    for (x, y), (u, v) in zip(dst, src):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); rhs.append(u)
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y]); rhs.append(v)
    return np.linalg.solve(np.array(rows, float), np.array(rhs, float)).tolist()


def warp(img, quad, size):
    w, h = img.size
    coeffs = perspective_coeffs([(0, 0), (w, 0), (w, h), (0, h)], quad)
    return img.transform(size, Image.PERSPECTIVE, coeffs, Image.BICUBIC)


def draw_tent(canvas, screen, top, slide, s, ipad):
    """The phone folded like a tent, sign facing us, on a desk."""
    w, h = canvas.size
    accent = slide["accent"]
    panel = device(screen, ipad, hinge_top=True)
    pw = w * (0.84 if not ipad else 0.70)
    ph = pw * panel.height / panel.width * 0.82      # leaning back looks a bit shorter
    cx = w / 2 - pw * 0.06
    bottom = top + (h - top) * 0.6
    ridge = bottom - ph
    shift, narrow = pw * 0.04, 0.9

    bl, br = (cx - pw / 2, bottom), (cx + pw / 2, bottom)
    tl = (cx - pw / 2 * narrow + shift, ridge)
    tr = (cx + pw / 2 * narrow + shift, ridge)
    back = (br[0] + pw * 0.13, bottom - ph * 0.3)   # far foot of the back half

    # Desk: a lighter floor below the horizon with the sign's light spilling on it.
    floor = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(floor)
    horizon = bottom - ph * 0.3
    for i in range(int(h - horizon)):
        a = int(70 * min(1, i / (h - horizon) * 2.2))
        fd.line([(0, horizon + i), (w, horizon + i)], fill=(255, 255, 255, a // 5))
    canvas.alpha_composite(floor)
    spill = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(spill).ellipse([cx - pw * 0.6, bottom - 40 * s, cx + pw * 0.6, bottom + ph * 0.75], fill=accent + (80,))
    canvas.alpha_composite(spill.filter(ImageFilter.GaussianBlur(70 * s)))

    # Contact shadow.
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon([bl, br, (back[0], back[1] + 10 * s), (back[0] - pw, back[1] + 10 * s)], fill=(0, 0, 0, 200))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(26 * s)))

    # Back half seen from the side: a dark triangle with a titanium edge.
    side = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(side)
    sd.polygon([tr, br, back], fill=(34, 34, 40, 255))
    sd.line([tr, back], fill=(150, 150, 162, 255), width=int(7 * s))
    sd.line([back, br], fill=(90, 90, 100, 255), width=int(4 * s))
    canvas.alpha_composite(side)

    # Front half with the sign, warped to lean back.
    front = warp(panel, [tl, tr, br, bl], canvas.size)
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    glow.paste(Image.new("RGBA", canvas.size, accent + (140,)), (0, 0), front.getchannel("A"))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(80 * s)))
    canvas.alpha_composite(front)

    # Hinge along the ridge.
    ImageDraw.Draw(canvas).line([tl, tr], fill=(170, 170, 182, 255), width=int(10 * s))


def compose(raw_dir, slide, out_path, size, ipad, rng):
    w, h = size
    s = 1.0 if not ipad else 1.3
    canvas = background(size, *slide["bg"], slide["blobs"], rng)
    top = draw_header(canvas, slide, s)
    shots = [os.path.join(raw_dir, n + ".png") for n in slide["shots"]]
    kind = slide["kind"]
    accent = slide["accent"]
    blobs = slide["blobs"]

    if kind == "portrait":
        screen = load_shot(shots[0], False)
        dw = w * (0.80 if not ipad else 0.70)
        screen = screen.resize((int(dw), int(screen.height * dw / screen.width)), Image.LANCZOS)
        body = device(screen, ipad)
        place(canvas, body, (w / 2, top + body.height / 2), 0, accent, s)
    elif kind == "landscape":
        screen = load_shot(shots[0], True)
        dw = w * (0.98 if not ipad else 0.84)
        screen = screen.resize((int(dw), int(screen.height * dw / screen.width)), Image.LANCZOS)
        body = device(screen, ipad)
        region = h - top
        cy = top + region * 0.30
        # Glossy desk: a faded mirror image under the device.
        mirror = body.transpose(Image.FLIP_TOP_BOTTOM)
        fade = np.linspace(0.32, 0, mirror.height)[:, None] * np.ones((1, mirror.width))
        mirror.putalpha(Image.fromarray((np.array(mirror.getchannel("A")) * fade).astype(np.uint8)))
        canvas.alpha_composite(mirror, (int(w / 2 - mirror.width / 2), int(cy + body.height / 2 + 24 * s)))
        place(canvas, body, (w / 2, cy), 0, accent, s)
        draw_chips(canvas, slide["chips"], cy + body.height * 1.2 + 40 * s, accent, s)
    elif kind == "pair":
        region = h - top
        dw = w * (0.92 if not ipad else 0.66)
        spots = [((w * 0.43, top + region * 0.27), blobs[0]), ((w * 0.57, top + region * 0.70), blobs[1])]
        for path, (center, color) in zip(shots, spots):
            screen = load_shot(path, True)
            screen = screen.resize((int(dw), int(screen.height * dw / screen.width)), Image.LANCZOS)
            place(canvas, device(screen, ipad), center, 6, color, s)
    elif kind == "tent":
        screen = load_shot(shots[0], True)
        draw_tent(canvas, screen, top, slide, s, ipad)

    canvas.convert("RGB").save(out_path, "PNG")


def main():
    raw_root, out_dir = sys.argv[1], sys.argv[2]
    rng = np.random.default_rng(7)
    for name, size in SIZES.items():
        raw_dir = os.path.join(raw_root, name)
        os.makedirs(os.path.join(out_dir, name), exist_ok=True)
        n = 0
        for slide in SLIDES:
            missing = [x for x in slide["shots"] if not os.path.exists(os.path.join(raw_dir, x + ".png"))]
            if missing:
                print("missing", name, missing)
                continue
            n += 1
            out = os.path.join(out_dir, name, f"{n:02d}-{slide['shots'][0]}.png")
            compose(raw_dir, slide, out, size, name == "ipad", rng)
            print("saved", out)


if __name__ == "__main__":
    main()
