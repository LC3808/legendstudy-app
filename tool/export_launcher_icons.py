#!/usr/bin/env python3
"""Check (default) or export (--write) the approved launcher icon. Requires Pillow.
Never alters the Owner master. No network, credentials or runtime dependency.

Owner-approved 2026-10-08 — CANONICAL APP ICON MASTER:
    assets/brand/source/legendstudy_app_icon_master.png  (sha256 asserted below)
A rounded-square ORANGE-GRADIENT icon with a WHITE notebook + **WHITE pencil body**
(orange negative-space detail inside the pencil/notebook). The attached master IS
the visual authority: we do NOT redraw, re-swap or re-scale it. Platform exports
are produced directly FROM this master.

This supersedes the 2026-09-29 75% white-canvas design (commit 9af9667) and the
2026-10-08 full-orange figure/ground swap (commit 8cb7b24) — both kept in git
history. That swap wrongly rendered the pencil body orange; this master restores
the white pencil body.

Export treatment (technical only, visible result == master):
- iOS AppIcon + Android legacy mipmaps: the master made full-bleed (the 4 white
  corner cutouts are filled with the master's own edge gradient so the OS mask
  produces a clean rounded icon), opaque RGB (App Store: no alpha).
- Android adaptive: background = the master's vertical orange gradient (a
  <shape> drawable); foreground = the WHITE symbol extracted from the master
  (white on transparent), sized into the 66dp safe circle. The pencil body stays
  white; the orange negative space shows the gradient background through.
- Splash (LaunchImage / ic_brand_symbol / legendstudy_symbol.png) and the Flutter
  cold-start brand frame are NOT touched here (Owner: splash stays white + orange
  symbol, separate from the app icon).
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / 'assets/brand/source/legendstudy_app_icon_master.png'
SHA256 = 'e37afa18ceaf9e27ab275c1cb460b512697baa3d745689ed741c871ce079abfe'

# Vertical gradient sampled from the master (top lighter -> bottom deeper).
GRAD_TOP = (253, 178, 21)      # ~#FDB215
GRAD_BOTTOM = (251, 147, 2)    # ~#FB9302
# Android adaptive foreground: white symbol farthest point as a fraction of the
# 108dp canvas radius. ~0.70 -> ~31dp, filling the 33dp (66dp diameter) safe circle.
ADAPTIVE_RADIUS_FRAC = 0.70

ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'''

# Adaptive background = the master's vertical orange gradient (angle 270 = top->bottom).
BG_DRAWABLE = ('<?xml version="1.0" encoding="utf-8"?>\n'
               '<!-- Launcher adaptive-icon background: master orange gradient (top #FDB215 -> bottom #FB9302). -->\n'
               '<shape xmlns:android="http://schemas.android.com/apk/res/android">\n'
               '    <gradient android:type="linear" android:angle="270"\n'
               '        android:startColor="#FFFDB215" android:endColor="#FFFB9302" />\n'
               '</shape>\n')


def vertical_gradient(w, h):
    col = Image.new('RGB', (1, h))
    px = col.load()
    for y in range(h):
        t = y / (h - 1)
        px[0, y] = tuple(round(GRAD_TOP[i] + (GRAD_BOTTOM[i] - GRAD_TOP[i]) * t) for i in range(3))
    return col.resize((w, h), Image.Resampling.LANCZOS)


def corner_mask(master):
    """255 where the white corner cutouts are (border-connected white), dilated to
    absorb the anti-aliased ring."""
    w, h = master.size
    flood = master.copy()
    for seed in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        ImageDraw.floodfill(flood, seed, (255, 0, 255), thresh=45)
    r, g, b = flood.split()
    rm = r.point(lambda v: 255 if v == 255 else 0)
    gm = g.point(lambda v: 255 if v == 0 else 0)
    bm = b.point(lambda v: 255 if v == 255 else 0)
    cm = ImageChops.multiply(ImageChops.multiply(rm, gm), bm)
    return cm.filter(ImageFilter.MaxFilter(21))


def symbol_alpha(master, corner):
    """Alpha of the WHITE symbol: min(G,B) whiteness, excluding corners and a thin
    outer border ring (orange margin between the symbol and the square edge)."""
    w, h = master.size
    _, g, b = master.split()
    min_gb = ImageChops.darker(g, b)
    lut = [max(0, min(255, round((v - 150) * 255 / (245 - 150)))) for v in range(256)]
    alpha = min_gb.point(lut)
    alpha.paste(0, mask=corner)  # drop corner white
    inset = Image.new('L', (w, h), 0)
    ImageDraw.Draw(inset).rounded_rectangle([70, 70, w - 71, h - 71], radius=180, fill=255)
    alpha.paste(0, mask=ImageChops.invert(inset))  # drop outer border artifacts
    return alpha


def full_bleed(master, corner, grad):
    """Master with the white corner cutouts replaced by the gradient, so the OS
    mask yields a clean rounded icon. Opaque RGB."""
    return Image.composite(master, grad, ImageChops.invert(corner))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--write', action='store_true')
    args = ap.parse_args()
    assert hashlib.sha256(MASTER.read_bytes()).hexdigest() == SHA256, 'master sha256 mismatch'
    with Image.open(MASTER) as src:
        src.verify()
    master = Image.open(MASTER).convert('RGB')
    w, h = master.size
    grad = vertical_gradient(w, h)
    corner = corner_mask(master)
    image = full_bleed(master, corner, grad)      # opaque RGB, full-bleed
    alpha = symbol_alpha(master, corner)

    outputs = {}
    appicon = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((appicon / 'Contents.json').read_text())['images']:
        n = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
        outputs[appicon / entry['filename']] = image.resize((n, n), Image.Resampling.LANCZOS)
    res = ROOT / 'android/app/src/main/res'
    for density, n in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        outputs[res / f'mipmap-{density}/ic_launcher.png'] = image.resize((n, n), Image.Resampling.LANCZOS)

    for path, expected in outputs.items():
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path)
        with Image.open(path) as actual:
            assert actual.format == 'PNG' and actual.mode == 'RGB', path   # no alpha (App Store)
            assert actual.size == expected.size, path
            assert ImageChops.difference(actual, expected).getbbox() is None, path

    # Android adaptive foreground: white symbol on transparent, sized to ~31dp.
    bbox = alpha.point(lambda v: 255 if v > 128 else 0).getbbox()
    x0, y0, x1, y1 = bbox
    far = max(((x - w / 2) ** 2 + (y - h / 2) ** 2) ** 0.5
              for x, y in [(x0, y0), (x1, y0), (x0, y1), (x1, y1)])
    C = 432
    want = ADAPTIVE_RADIUS_FRAC * (C / 2)
    inner = round(want * 2 / (far / (w / 2)))
    off = (C - inner) // 2
    sym = Image.new('RGBA', (w, h), (255, 255, 255, 255))
    sym.putalpha(alpha)
    fg = Image.new('RGBA', (C, C), (255, 255, 255, 0))
    fg.paste(sym.resize((inner, inner), Image.Resampling.LANCZOS), (off, off))
    fg_path = res / 'drawable-xxxhdpi/ic_launcher_foreground.png'
    if args.write:
        fg_path.parent.mkdir(parents=True, exist_ok=True)
        fg.save(fg_path)
    with Image.open(fg_path) as actual:
        assert actual.format == 'PNG' and actual.mode == 'RGBA', fg_path
        assert actual.size == (C, C), fg_path
        assert ImageChops.difference(actual, fg).getbbox() is None, fg_path

    xml = res / 'mipmap-anydpi-v26/ic_launcher.xml'
    bg = res / 'drawable/ic_launcher_background.xml'
    if args.write:
        xml.parent.mkdir(parents=True, exist_ok=True)
        xml.write_text(ADAPTIVE_XML)
        bg.parent.mkdir(parents=True, exist_ok=True)
        bg.write_text(BG_DRAWABLE)
    assert xml.read_text() == ADAPTIVE_XML
    assert bg.read_text() == BG_DRAWABLE

    # Safety: the white foreground sits inside the 66dp safe circle (132px of 432).
    px = fg.load()
    radii = [((x - 215.5) ** 2 + (y - 215.5) ** 2) ** 0.5
             for y in range(C) for x in range(C) if px[x, y][3] > 40]
    assert radii and max(radii) < 132, f'adaptive foreground exceeds 66dp safe circle: {max(radii)/4:.2f}dp'
    print(f'Launcher icon PASS: {len(outputs)} PNGs from master (full-bleed, white pencil preserved); '
          f'adaptive fg safe radius {max(radii)/4:.2f}dp < 33dp. Splash untouched.')


if __name__ == '__main__':
    main()
