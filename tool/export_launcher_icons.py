#!/usr/bin/env python3
"""Check (default) or export (--write) approved launcher assets. Requires Pillow.
Never alters the Owner source. No network, credentials or runtime dependency.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/brand/source/legendstudy_app_iocon_1024.png'
SHA256 = '7f37ed2c16a43f739cfcb618190bacedaaacdb7877dcf000578f8b6611e25a68'
# Owner-approved 2026-09-29: reduce the symbol footprint to 75% inside the SAME
# 1024 canvas (add white margin) so the rotated document no longer crowds the
# mask. No recolor, redraw, crop or new symbol — the source is only scaled and
# centred on white. A padded runtime symbol (transparent) is also exported for
# the Flutter cold-start brand frame.
SCALE = 0.75
ADAPTIVE = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/white" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'''


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
        # Alpha is entirely opaque. Preserve every RGB value, no color transform.
        source_rgb = source.convert('RGB')
        source_rgba = source.copy()
    # Composite the source at SCALE onto a white 1024 canvas. No pixel of the
    # symbol is recoloured or redrawn — only scaled (LANCZOS) and centred.
    inner = round(1024 * SCALE)
    offset = (1024 - inner) // 2
    scaled_rgb = source_rgb.resize((inner, inner), Image.Resampling.LANCZOS)
    image = Image.new('RGB', (1024, 1024), 'white')
    image.paste(scaled_rgb, (offset, offset))
    # A transparent, padded symbol for the Flutter runtime brand frame (bundled).
    symbol = Image.new('RGBA', (1024, 1024), (255, 255, 255, 0))
    symbol.paste(source_rgba.resize((inner, inner), Image.Resampling.LANCZOS), (offset, offset))
    outputs = {}
    appicon = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((appicon / 'Contents.json').read_text())['images']:
        n = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
        outputs[appicon / entry['filename']] = image.resize((n, n), Image.Resampling.LANCZOS)
    res = ROOT / 'android/app/src/main/res'
    for density, n in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        outputs[res / f'mipmap-{density}/ic_launcher.png'] = image.resize((n, n), Image.Resampling.LANCZOS)
    # 108dp @4x canvas. The square source previously sat at 60dp (240px); at 75%
    # it sits at 45dp (180px), centred, so the adaptive symbol footprint matches
    # the iOS/legacy 75% reduction. Uses the source directly (not the already
    # white-padded `image`) to avoid double padding.
    adaptive_inner = round(240 * SCALE)
    adaptive_off = (432 - adaptive_inner) // 2
    layer = Image.new('RGB', (432, 432), 'white')
    layer.paste(source_rgb.resize((adaptive_inner, adaptive_inner), Image.Resampling.LANCZOS),
                (adaptive_off, adaptive_off))
    outputs[res / 'drawable-xxxhdpi/ic_launcher_foreground.png'] = layer
    for path, expected in outputs.items():
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path)
        with Image.open(path) as actual:
            assert actual.format == 'PNG' and actual.mode == 'RGB', path
            assert actual.size == expected.size, path
            assert ImageChops.difference(actual, expected).getbbox() is None, path
    xml = res / 'mipmap-anydpi-v26/ic_launcher.xml'
    if args.write:
        xml.parent.mkdir(parents=True, exist_ok=True)
        xml.write_text(ADAPTIVE)
    assert xml.read_text() == ADAPTIVE
    # Runtime brand symbol (transparent, same 75% footprint) for the Flutter
    # cold-start brand frame and the iOS launch image. Kept separate from the
    # opaque RGB launcher outputs above.
    symbol_out = symbol.resize((512, 512), Image.Resampling.LANCZOS)
    symbol_path = ROOT / 'assets/brand/generated/legendstudy_symbol.png'
    ios_launch = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    # 180pt square (transparent) → visible mark ~135pt, centred on the white
    # LaunchScreen. Matches the Flutter brand-frame symbol size/position.
    launch_sizes = {'LaunchImage.png': 180, 'LaunchImage@2x.png': 360, 'LaunchImage@3x.png': 540}
    rgba_targets = {symbol_path: symbol_out}
    for name, px in launch_sizes.items():
        rgba_targets[ios_launch / name] = symbol.resize((px, px), Image.Resampling.LANCZOS)
    for path, expected in rgba_targets.items():
        if args.write:
            path.parent.mkdir(parents=True, exist_ok=True)
            expected.save(path)
        with Image.open(path) as actual:
            assert actual.format == 'PNG' and actual.mode == 'RGBA', path
            assert actual.size == expected.size, path
            assert ImageChops.difference(actual, expected).getbbox() is None, path
    # Check all saturated orange mark pixels against the guaranteed 66dp circle,
    # stricter than the normal 72dp visible circle/squircle viewport.
    pixels = layer.load()
    radii = [((x - 215.5)**2 + (y - 215.5)**2)**.5
             for y in range(432) for x in range(432)
             if pixels[x, y][0] > 200 and pixels[x, y][1] < 220 and pixels[x, y][2] < 100]
    assert radii and max(radii) < 132
    print(f'Launcher assets PASS: {len(outputs)} PNGs; alpha removed; safe radius {max(radii)/4:.2f}dp < 33dp')


if __name__ == '__main__':
    main()
