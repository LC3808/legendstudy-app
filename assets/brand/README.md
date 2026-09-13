# Official LegendStudy brand assets

Owner-supplied canonical originals, received 2026-09-13 on codex/day-5-ui-shell:

- `source/legendstudy_app_icon_source.png` (72×72): launcher icon canonical source.
- `source/legendstudy_square_logo_source.png` (150×150): square website logo.
- `source/legendstudy_wordmark_source.png` (1100×156): original website banner.

Source bytes are preserved without alteration. SHA-256:

- `legendstudy_app_icon_source.png`: `03aeee4f7f524b1d07a6c30017666f66a11b42ba94d1c7634f03f023ad29cb60`
- `legendstudy_square_logo_source.png`: `353e35d3429d1a94a77ca45c15f7d8ddf911cb05ccb94bb228aa541c1803e583`
- `legendstudy_wordmark_source.png`: `697023da6d49db39bca6a232b3b539f4904ca95277181a4e766fa1061d81ac62`

`generated/legendstudy_wordmark_header.png` is a lossless 312×55 crop of the
wordmark source: Pillow crop box `(718, 64, 1030, 119)` (left/top inclusive,
right/bottom exclusive). It retains the Korean “레전드스터디 닷컴” artwork;
the URL, separate ornament and horizontal rules outside the crop are omitted.
No redrawing, recoloring or replacement typography. Reproduce with Pillow:

```python
from PIL import Image
Image.open('assets/brand/source/legendstudy_wordmark_source.png').crop(
    (718, 64, 1030, 119)
).save('assets/brand/generated/legendstudy_wordmark_header.png')
```

Home renders the crop at up to 280 logical pixels wide, respecting available
width and aspect ratio. Only this derived asset is in the runtime Flutter bundle.
General-purpose icons and Text widgets must not impersonate the official logo.
Body typography and existing orange theme tokens remain unchanged.

Platform launcher icons remain Flutter placeholders. The supplied 72×72 icon is
the canonical source, but a higher-resolution official original is required before
producing a satisfactory 1024×1024 iOS icon. Do not invent detail by redrawing it.
