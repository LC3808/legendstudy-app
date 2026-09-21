# Provider button provenance

Downloaded 2026-09-21 from official provider resources; bundled locally, no CDN.

- Google: https://developers.google.com/identity/branding-guidelines
  and https://developers.google.com/static/identity/images/signin-assets.zip
  Android + Web / PNG @4x / Light / Show text=No / Square. Export is the 88×88
  symbol area at x=36,y=36 of the 160×160 original; no recoloring, redrawing,
  aspect-ratio change or smoothing. Current official gradient multicolor G.
- Kakao: https://developers.kakao.com/docs/en/kakaologin/design-guide
  and https://developers.kakao.com/tool/resource/static/img/button/login/kakao_login_original.psd
  The first `Shape 5` vector layer (bbox 592,1145,632,1182) supplies the exact
  Bézier anchors/control points. Exported on canvas x=590,y=1143,w=44,h=41 at 3×
  to 132×123 PNG, black symbol on #FEE500. No traced/redrawn geometry or color
  change. This replaces the insufficient-resolution button-PNG crop.
- Apple: exported AppleLogoPainter from sign_in_with_apple 8.2.0, unchanged.
  The package button's fixed font was unsuitable for Korean widget rendering;
  the package mark is reused with the app's accessible text style instead.
  https://pub.dev/packages/sign_in_with_apple
  https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple

These are provider marks, not LegendStudy-owned artwork. Use only for the relevant
sign-in buttons and retain provider rules. No source ZIP/large asset bundle.
Owner-requested labels are Google/Kakao/Apple로 계속하기. Kakao's published guide
lists 카카오 로그인/로그인; the custom requested label requires provider-brand
review before release and is not claimed officially approved. Current Google
custom-button typography also needs final provider review. No store approval is
claimed by local render tests.
