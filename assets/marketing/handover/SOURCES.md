# 배너 인계 — 확정 재료(자산 출처) · 2026-11-01

마누스가 바로 쓸 수 있는 **확정 재료**. 저장소에 실물 포함. 전체 인계 맥락은 `wiki/banner-handover-manus-20261101.md`.

## 1. 공식 앱 아이콘 (새로 만들지 말 것)
- 저장소 실물: `assets/marketing/handover/official-app-icon-1024.png` (1024×1024).
- 정본 위치: 브랜치 `codex/essay-evaluation-stability-p0-20261029` →
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`.
  Owner 승인 2026-09-29(아이콘 75%·레전드스터디⁺). App Store `artworkUrl512`와 동일.
- ⚠️ `main`/현재 작업 브랜치의 AppIcon은 **구 placeholder**(해시 상이). 반드시 위 essay 브랜치본/handover 실물을 쓸 것. Android 런처: 같은 브랜치 `android/app/src/main/res/mipmap-*/ic_launcher.png`.

## 2. 공식 스토어 다운로드 배지 (앱 출시 배너 우측)
- Apple: `assets/marketing/handover/appstore-badge-official.svg` (공식 "Download on the App Store", black).
  재취득: `https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=500x166`
- Google: `assets/marketing/handover/googleplay-badge-official.png` (공식 "Get it on Google Play", generic).
  재취득: `https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png`
- 배지는 Apple/Google이 **앱 홍보용으로 배포하는 공식 아트워크**만 사용(자체 제작·변형 금지, 가이드라인 준수).

## 3. 실제 앱 화면 (필요 시 · 가상 화면/점수 생성 금지)
Owner App Store 등록 스크린샷(실제 서비스 화면). 저장소 실물 포함:
- `real-app-home.png` — 앱 홈 (01_home)
- `real-essay-lab.png` — 논술 LAB 대학 목록 (05_essay_lab)
- `real-essay-feedback.png` — 실제 첨삭 결과 UI (06_essay_feedback)
- 출처 API: `https://itunes.apple.com/lookup?id=6820826957` → `screenshotUrls`. 고해상: URL 끝 `/320x480bb.jpg` → `/1000x0w.png`.

## 4. 공식 스토어 URL (변경 금지)
- iOS: `https://apps.apple.com/us/app/%EB%A0%88%EC%A0%84%EB%93%9C%EC%8A%A4%ED%84%B0%EB%94%94/id6820826957`
- Android: `https://play.google.com/store/apps/details?id=com.legendstudy.app&hl=ko`
- 논술 LAB: `https://lab.legendstudy.com`
- 대학별 LAB(동적): `https://lab.legendstudy.com/essay-lab/universities/{sourceUniversityId}/`
  (sourceUniversityId = `lib/features/essay/university_catalog.dart`. 예: 서강=sogang, 건국=konkuk)

## 5. 브랜드 토큰
- Primary `#FFAC14`(강조만), Dark `#E99500`, Soft `#FFF3DC`, Ink `#1A1D21`/`#202124`, Sub `#5B6066`, Line `#E8EAED`, 배경 White/Light.
- 로크업(레퍼런스): `LegendStudy⁺`(라틴, superscript +) + 소형 공식 아이콘. 한글 본문은 Apple SD Gothic Neo.

## 6. 확정 카피(현재 안) · CTA · 사이즈
- 상세는 `wiki/banner-handover-manus-20261101.md` §3·§4. §6-1 대학 배너 원문은 Owner 대기(플레이스홀더).
</content>
