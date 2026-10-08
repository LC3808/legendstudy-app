#!/usr/bin/env python3
"""Check (default) or export (--write) approved launcher + splash assets. Requires Pillow.
Never alters the Owner source. No network, credentials or runtime dependency.

Owner-approved 2026-10-08 — FULL-ORANGE launcher icon:
    background = brand orange (#FFA300, = AppTokens.primary / AppTokens.brand)
    foreground = the white notebook+pencil symbol.
No white outer canvas, no border, no text, no wordmark.

The symbol geometry is the Owner's canonical source
(assets/brand/source/legendstudy_app_iocon_1024.png, sha256 below): an orange
mark on white. We do NOT redraw it. We derive a per-pixel symbol-coverage map
`t` from the source (white background -> 0, orange ink -> 1, with the source's
own anti-aliasing preserved) and recolour by figure/ground swap:
    launcher pixel = t*WHITE + (1-t)*ORANGE   (white symbol on orange)
    splash  symbol = orange where t, transparent elsewhere (for the white splash)

This supersedes the 2026-09-29 75% white-canvas design (commit 9af9667), kept in
git history. The source bytes are untouched.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/brand/source/legendstudy_app_iocon_1024.png'
SHA256 = '7f37ed2c16a43f739cfcb618190bacedaaacdb7877dcf000578f8b6611e25a68'

# Brand orange = AppTokens.primary / AppTokens.brand (lib/core/theme/app_theme.dart = 0xFFFFA300).
ORANGE = (255, 163, 0)
# iOS + Android legacy full square: white symbol footprint inside the (squircle) mask.
FULL_SCALE = 0.78
# Android adaptive foreground: the symbol's farthest point as a fraction of the
# 108dp canvas radius (canvas/2 = 216px = 54dp). The rotated-document corners
# sit inside the bbox, so the real farthest ink is < this nominal radius; 0.72
# yields ~31.4dp measured, filling the 33dp (66dp diameter) safe circle.
ADAPTIVE_RADIUS_FRAC = 0.72
# Splash orange symbol: larger for presence on the white splash (iOS LaunchScreen
# is unmasked; Android 12 splash icon circle is generous). ~0.62 of the radius.
SPLASH_RADIUS_FRAC = 0.62

ADAPTIVE = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'''

COLORS = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Launcher adaptive-icon background: LegendStudy brand orange (AppTokens.primary). -->
<resources>
    <color name="ic_launcher_background">#FFFFA300</color>
</resources>
'''


def coverage_map(source_rgb):
    """Symbol coverage t in [0,255] from the blue channel: white bg(blue~254)->0,
    orange ink(blue~0)->255. Preserves the source's own edge anti-aliasing."""
    blue = source_rgb.getchannel('B')
    lut = [max(0, min(255, round((254 - b) * 255 / 254))) for b in range(256)]
    return blue.point(lut)  # 'L' image, 255 = full symbol


def farthest_symbol_radius(t):
    """Farthest symbol pixel (t>0.5) distance from centre, in source px."""
    x0, y0, x1, y1 = t.point(lambda v: 255 if v > 128 else 0).getbbox()
    cx = cy = t.size[0] / 2
    corners = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)]
    return max(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 for x, y in corners)


def white_on_orange(t, scale, canvas=1024):
    """Opaque RGB: white symbol (scaled, centred) on a full orange canvas."""
    inner = round(canvas * scale)
    off = (canvas - inner) // 2
    full_t = Image.new('L', (canvas, canvas), 0)
    full_t.paste(t.resize((inner, inner), Image.Resampling.LANCZOS), (off, off))
    bg = Image.new('RGB', (canvas, canvas), ORANGE)
    white = Image.new('RGB', (canvas, canvas), (255, 255, 255))
    return Image.composite(white, bg, full_t)


def coloured_symbol(t, far, radius_frac, colour, canvas):
    """RGBA symbol of `colour` on transparent, sized so the farthest symbol
    point sits at radius_frac of the canvas radius (canvas/2) from the centre."""
    want_px = radius_frac * (canvas / 2)
    inner = round(want_px * 2 / (far / (t.size[0] / 2)))
    off = (canvas - inner) // 2
    full_t = Image.new('L', (canvas, canvas), 0)
    full_t.paste(t.resize((inner, inner), Image.Resampling.LANCZOS), (off, off))
    sym = Image.new('RGBA', (canvas, canvas), colour + (0,))
    solid = Image.new('RGBA', (canvas, canvas), colour + (255,))
    sym.paste(solid, (0, 0), full_t)
    return sym


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == SHA256
    with Image.open(SOURCE) as source:
        source.verify()
    with Image.open(SOURCE) as source:
        assert source.format == 'PNG' and source.size == (1024, 1024)
        assert source.mode == 'RGBA' and source.getchannel('A').getextrema() == (255, 255)
        source_rgb = source.convert('RGB')

    t = coverage_map(source_rgb)
    far = farthest_symbol_radius(t)

    # Full orange launcher image (white symbol @ FULL_SCALE), opaque RGB.
    image = white_on_orange(t, FULL_SCALE)

    outputs = {}
    appicon = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((appicon / 'Contents.json').read_text())['images']:
        n = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
        outputs[appicon / entry['filename']] = image.resize((n, n), Image.Resampling.LANCZOS)
    res = ROOT / 'android/app/src/main/res'
    for density, n in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        outputs[res / f'mipmap-{density}/ic_launcher.png'] = image.resize((n, n), Image.Resampling.LANCZOS)

    # Android adaptive foreground: WHITE symbol on transparent, 108dp @4x = 432.
    adaptive_fg = coloured_symbol(t, far, ADAPTIVE_RADIUS_FRAC, (255, 255, 255), 432)

    for path, expected in outputs.items():
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path)
        with Image.open(path) as actual:
            assert actual.format == 'PNG' and actual.mode == 'RGB', path   # no alpha (App Store)
            assert actual.size == expected.size, path
            assert ImageChops.difference(actual, expected).getbbox() is None, path

    # Adaptive foreground PNG (RGBA white) + adaptive xml + colors.xml.
    fg_path = res / 'drawable-xxxhdpi/ic_launcher_foreground.png'
    if args.write:
        fg_path.parent.mkdir(parents=True, exist_ok=True)
        adaptive_fg.save(fg_path)
    with Image.open(fg_path) as actual:
        assert actual.format == 'PNG' and actual.mode == 'RGBA', fg_path
        assert actual.size == (432, 432), fg_path
        assert ImageChops.difference(actual, adaptive_fg).getbbox() is None, fg_path

    xml = res / 'mipmap-anydpi-v26/ic_launcher.xml'
    colors = res / 'values/colors.xml'
    if args.write:
        xml.parent.mkdir(parents=True, exist_ok=True)
        xml.write_text(ADAPTIVE)
        colors.parent.mkdir(parents=True, exist_ok=True)
        colors.write_text(COLORS)
    assert xml.read_text() == ADAPTIVE
    assert colors.read_text() == COLORS

    # Splash orange symbol (transparent) for: Flutter cold-start brand frame,
    # iOS LaunchImage, Android pre-12 + API31 splash. White splash, orange mark.
    symbol_path = ROOT / 'assets/brand/generated/legendstudy_symbol.png'
    ios_launch = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    android_splash = res / 'drawable-xxxhdpi/ic_brand_symbol.png'
    base_symbol = coloured_symbol(t, far, SPLASH_RADIUS_FRAC, ORANGE, 1024)
    rgba_targets = {
        symbol_path: base_symbol.resize((512, 512), Image.Resampling.LANCZOS),
        android_splash: base_symbol.resize((432, 432), Image.Resampling.LANCZOS),
        ios_launch / 'LaunchImage.png': base_symbol.resize((180, 180), Image.Resampling.LANCZOS),
        ios_launch / 'LaunchImage@2x.png': base_symbol.resize((360, 360), Image.Resampling.LANCZOS),
        ios_launch / 'LaunchImage@3x.png': base_symbol.resize((540, 540), Image.Resampling.LANCZOS),
    }
    for path, expected in rgba_targets.items():
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path)
        with Image.open(path) as actual:
            assert actual.format == 'PNG' and actual.mode == 'RGBA', path
            assert actual.size == expected.size, path
            assert ImageChops.difference(actual, expected).getbbox() is None, path

    # Safety: every white foreground pixel must sit inside the 66dp safe circle
    # (radius 132px on the 432 canvas), stricter than the 72dp visible viewport.
    px = adaptive_fg.load()
    radii = [((x - 215.5) ** 2 + (y - 215.5) ** 2) ** 0.5
             for y in range(432) for x in range(432) if px[x, y][3] > 40]
    assert radii and max(radii) < 132, f'adaptive foreground exceeds 66dp safe circle: {max(radii)/4:.2f}dp'
    print(f'Launcher+splash assets PASS: {len(outputs)} launcher PNGs (orange bg, white symbol @ {int(FULL_SCALE*100)}%), '
          f'adaptive fg safe radius {max(radii)/4:.2f}dp < 33dp, {len(rgba_targets)} splash symbols.')


if __name__ == '__main__':
    main()
