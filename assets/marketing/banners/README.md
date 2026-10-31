# 마케팅 배너 자산 (§A / §B)

레전드스터디+ 베타 출시 마케팅 배너. 브랜드 토큰: Primary `#FFAC14`, Dark `#E99500`, Soft `#FFF3DC`, SurfaceWarm `#FFFDF9`, Text `#202124`, Secondary `#5B5F66`. 한글 폰트: Apple SD Gothic Neo / NanumSquare 계열. 공식 심볼(메모+연필)은 `assets/brand/source/legendstudy_square_logo_source.png`에서 `.com` 텍스트 윗부분만 크롭해 임베드.

## 파일 구성
각 배너 키별로:
- `{key}-pc.webp` (1024×256, @1x) / `{key}-pc@2x.webp` (2048×512, Retina)
- `{key}-mobile.webp` (640×360, @1x) / `{key}-mobile@2x.webp` (1280×720, Retina)
- `{key}-pc@1x.png` / `{key}-mobile@1x.png` (WebP 미지원 폴백)
- `svg/{key}-pc.svg` / `svg/{key}-mobile.svg` (편집 가능한 소스)

| key | 용도 | 카피 | CTA | 링크 |
|---|---|---|---|---|
| `ios-launch` | iOS 앱 출시 | 레전드스터디+, 이제 아이폰에서도 만나보세요. | App Store에서 다운로드 → | `https://apps.apple.com/us/app/%EB%A0%88%EC%A0%84%EB%93%9C%EC%8A%A4%ED%84%B0%EB%94%94/id6820826957` |
| `android-launch` | Android 앱 출시 | 레전드스터디+, 안드로이드 앱 출시! | Google Play에서 다운로드 → | `https://play.google.com/store/apps/details?id=com.legendstudy.app&hl=ko` |
| `lab-beta` | 논술 LAB 베타 | 논술, 내 글에서 부족한 것이 무엇일까? (서브: 인문논술 LAB 베타 오픈 · 매일 무료 첨삭 1회) | 논술 LAB 시작하기 → | `https://lab.legendstudy.com` |
| `univ-post-sogang` | §B 대학 게시글 배너(AVAILABLE 예시) | 서강대 논술, 내 답안의 부족한 점을… | 서강대 논술 첨삭받기 → | `https://lab.legendstudy.com/essay-lab/universities/sogang/` |
| `univ-post-comingsoon` | §B 대학 게시글 배너(COMING_SOON 템플릿) | ○○대 논술 자료, 지금 바로 확인해 보세요. | ○○대 논술 자료 확인하기 → | officialSourceUrl 또는 대학 LAB |

- 공식 스토어 URL은 **변경 금지**(지시서 제약). `App Store`/`Google Play`는 워드마크(텍스트)만 사용, 로고 미사용.
- `univ-post-*`는 **템플릿**: `○○대`/`{university}`를 대학명으로 치환, CTA는 지원상태(§D)에 따라 선택.

## 재생성
```bash
python3 assets/marketing/banners/gen.py           # svg/ 재생성 (brand 심볼 자동 임베드)
# 렌더(예): rsvg-convert svg/lab-beta-pc.svg -w 1024 -h 256 -o x.png && cwebp -q 86 x.png -o lab-beta-pc.webp
```
렌더 요구: `rsvg-convert`(librsvg), `cwebp`(webp). 한글 폰트 설치 필요.

## 반응형 삽입(권장, §5 슬라이더 doc 참조)
```html
<picture>
  <source media="(max-width:480px)" type="image/webp" srcset="lab-beta-mobile.webp 1x, lab-beta-mobile@2x.webp 2x">
  <source type="image/webp" srcset="lab-beta-pc.webp 1x, lab-beta-pc@2x.webp 2x">
  <img src="lab-beta-pc@1x.png" alt="논술 LAB 베타" loading="lazy" decoding="async">
</picture>
```
