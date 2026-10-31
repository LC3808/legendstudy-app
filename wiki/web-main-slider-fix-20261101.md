# WEB 메인 슬라이더 UI/UX 수정안 (§5 / §C) — 2026-11-01, Claude

역할: Claude = UI/UX 분석·명세. 실제 스킨 편집·배포는 Codex/Owner. 이 문서는 **Codex가 재기획 없이 바로 스킨을 수정**할 수 있는 수준의 원인·대상·수정 방법·검수 기준이다.

## 0. 전제 — 슬라이더가 사는 곳

`legendstudy.com`은 **티스토리 기반**이다(런타임 검증: `edge.daumcdn.net/tistory/...`, `t1.daumcdn.net/tistory_admin/...` 스크립트, jQuery 3.5.1 로드 확인). 메인 슬라이더는 티스토리 스킨에 **직접 삽입된 커스텀 위젯**이며 Flutter/APP 저장소에는 존재하지 않는다. 따라서 수정 대상은 **티스토리 관리 → 꾸미기 → 스킨 편집(HTML/CSS)** 안의 `.ls-slider` 마크업·스타일·인라인 스크립트다. 저장소 코드 변경 아님.

> 이 때문에 §5는 APP 저장소 빌드/테스트로 검증할 수 없다. 검수는 실제 `legendstudy.com`(PC/모바일) 또는 티스토리 미리보기에서 수행한다.

## 1. 현재 구현 (런타임 실측 2026-11-01)

구조:
```
.ls-slider#slider            overflow:hidden, position:relative, width:720px(PC)/375(모바일), height:182px(고정), border 1px 추정
 └ .ls-slider__track          display:flex, transform:translateX(0%), transition:transform .5s
     └ .ls-slide.ls-slide--text  width:718px(="100%"), box-sizing:border-box, padding:24px, display:grid, align-items:center
     └ .ls-slide.ls-slide--text  (두 번째 슬라이드)
 └ .ls-arrow--prev / --next   position:absolute (좌 12 / 우 668)
 └ .ls-dots                   position:absolute
```

슬라이드 CSS(실측): `flex-grow:0; flex-shrink:1; flex-basis:auto; min-width:100%; width:718px`. 높이: `.ls-slider{height:182px}` / `.ls-slide{height:180px}` **고정 px**.

내비게이션 인라인 스크립트(실측 발췌):
```js
function go(n){ i=(n+slides.length)%slides.length;
  track.style.transform='translateX('+(-i*100)+'%)';   // ← 퍼센트, 트랙 자신의 폭 기준
  dots.forEach((d,k)=>d.classList.toggle('is-on',k===i)); }
function next(){go(i+1);} function prev(){go(i-1);}
function start(){ if(reduce) return; timer=setInterval(next,5000); } // 5초 자동전환
slider.addEventListener('mouseenter',stop); slider.addEventListener('mouseleave',start);
track.addEventListener('touchstart',…); track.addEventListener('touchend', … dx>40 → next/prev);
go(0); start();
```
`prefers-reduced-motion`이면 자동전환 중지(`reduce`). 리사이즈 핸들러는 없음(퍼센트 이동이라 리사이즈 자체는 허용).

## 2. 원인 분석 — "콘텐츠 잘림 / 다음 슬라이드 부분 노출"

현재 1줄짜리 텍스트 슬라이드에서는 정지 상태가 거의 정상이지만, 다음 3가지 구조적 결함이 **새 마케팅 배너(§A, 이미지·CTA 포함)를 올리는 순간** 바로 증상으로 드러난다.

### 원인 A — 고정 px 높이 + `overflow:hidden` (→ 세로 콘텐츠 잘림)
`.ls-slider`/`.ls-slide` 높이가 182/180px로 **고정**이고 슬라이더가 `overflow:hidden`이다. 슬라이드 콘텐츠가 이 높이를 넘으면 **아래가 잘린다**. 유발 조건:
- 모바일(≤430px)에서 제목이 2~3줄로 줄바꿈될 때.
- 새 배너처럼 eyebrow+title+sub+**CTA 버튼**(또는 이미지)이 함께 들어가 세로가 커질 때.
- 사용자 글자 크기 확대/다른 폰트 환경.
→ "콘텐츠 잘림"의 직접 원인.

### 원인 B — 프레임과 슬라이드 폭 불일치 (→ 다음 슬라이드 1~2px 노출)
`.ls-slider` 프레임은 375px인데 `.ls-slider__track`/`.ls-slide`는 373px로 렌더된다(실측: track.left=1 → 좌우 각 1px, 합 2px 차이. `.ls-slider`의 1px border로 추정). 슬라이드 폭을 **프레임이 아니라 `min-width:100%`(=트랙 폭 373)** 기준으로 잡기 때문에, 각 슬라이드가 프레임보다 2px 좁다 → 정지 상태에서도 다음 슬라이드의 **좌측 가장자리 1~2px 띠**가 프레임 우측에 보인다. → "다음 슬라이드 부분 노출"의 직접 원인(현 상태에서 이미 미세하게 존재).

### 원인 C — 취약한 flex/translate 결합 (→ 배너 추가 시 정렬 붕괴)
`flex-shrink:1`인데 `min-width:100%`로 수축을 막는 안티패턴이다. 그리고 `translateX(-i*100%)`는 **트랜스폼 대상(트랙) 자신의 폭 기준**이므로, "모든 슬라이드 = 정확히 프레임 1장 폭"이 **항상 참일 때만** -100%가 한 장과 일치한다. 이미지 배너(고유 폭)·다른 패딩·`min-width:100%`가 다른 컨테이닝 블록으로 해석되는 브라우저 등에서 슬라이드 폭이 프레임과 어긋나면, N번째 슬라이드가 어긋나 보이고 다음 슬라이드가 **크게 부분 노출**된다. 슬라이드 수가 2→3개 이상으로 늘면 오차가 누적된다.

## 3. 수정안 (기존 컴포넌트 유지 — 새 라이브러리 미사용)

새 캐러셀 라이브러리(slick/swiper 등) 도입은 **최후 대안**. 아래는 기존 `.ls-slider` 구조를 유지한 CSS/소폭 JS 수정으로 세 원인을 모두 제거한다.

### 3.1 CSS (스킨 편집의 `.ls-slider` 규칙 교체/추가)
```css
/* 프레임: 높이 고정 금지. 종횡비 + 최소높이로 반응형. */
.ls-slider{
  position:relative; width:100%; max-width:720px; margin:0 auto;
  overflow:hidden; border-radius:16px; box-sizing:border-box;
  border:0;                         /* 1px border 제거(또는 box-shadow/outline으로 대체) → 프레임=트랙 폭 */
  aspect-ratio: 1024 / 240;         /* PC 배너 비율. 콘텐츠가 더 크면 아래 min-height가 받쳐줌 */
}
.ls-slider__track{
  display:flex; width:100%;
  transition:transform .5s cubic-bezier(.4,.1,.2,1);
  will-change:transform;
}
/* 슬라이드: 프레임 1장 = 정확히 100%. 수축 금지, min-width 0. */
.ls-slide{
  flex:0 0 100%; width:100%; min-width:0;
  box-sizing:border-box; padding:24px;
  display:grid; align-content:center; gap:8px;
  overflow:hidden;                  /* 가로만 클립; 세로는 프레임이 콘텐츠에 맞춰 커지므로 잘리지 않음 */
}
/* 모바일: 더 세로로. */
@media (max-width:480px){
  .ls-slider{ aspect-ratio:auto; min-height:200px; }  /* 텍스트 줄바꿈을 높이로 흡수 */
  .ls-slide{ padding:20px; }
}
/* 이미지 배너를 쓸 경우(권장 §A WebP) */
.ls-slide--image{ padding:0; }
.ls-slide--image img, .ls-slide--image picture{ width:100%; height:100%; object-fit:cover; display:block; }
```
핵심:
- `flex:0 0 100%` + `min-width:0` → 원인 B/C 제거(슬라이드 = 프레임 폭, `translateX(-i*100%)` 정확 일치).
- `border:0`(또는 outline) → 프레임/트랙 2px 불일치 제거(부분 노출 소멸).
- `aspect-ratio` + 모바일 `min-height` → 원인 A 제거(세로 잘림 방지). 모든 슬라이드가 `align-content:center`로 세로 중앙 정렬.

### 3.2 JS (최소 변경, 선택)
- 현 `translateX(-i*100%)` 유지 가능(슬라이드가 100%로 정확해졌으므로). **추가 수정 불필요.**
- 권장 보강(견고성): 슬라이드 수 1개면 화살표·dots·자동전환 숨김(이미 `if(... ) e.style.display='none'; return;` 분기 존재 → 유지). 접근성: 프레임에 `role="region" aria-roledescription="carousel" aria-label="메인 배너"` 유지, 각 슬라이드 `aria-roledescription="slide"` 추가, `aria-live="polite"`는 자동전환 중 과다 알림 방지를 위해 넣지 않음.
- 자동전환 5초 유지. `prefers-reduced-motion` 중지 로직 유지(현재 OK).

### 3.3 이미지 배너를 쓸 때(§A 자산 연동, 권장 반응형 교체)
```html
<div class="ls-slide ls-slide--image">
  <a href="https://lab.legendstudy.com" aria-label="논술 LAB 베타 시작하기">
    <picture>
      <source media="(max-width:480px)" type="image/webp"
              srcset="…/lab-beta-mobile.webp 1x, …/lab-beta-mobile@2x.webp 2x">
      <source type="image/webp"
              srcset="…/lab-beta-pc.webp 1x, …/lab-beta-pc@2x.webp 2x">
      <img src="…/lab-beta-pc@1x.png" alt="논술, 내 글에서 부족한 것이 무엇일까? 논술 LAB 베타" loading="lazy" decoding="async">
    </picture>
  </a>
</div>
```
`@2x`가 Retina, `media(max-width:480px)`가 모바일 자산을 선택. `aspect-ratio`와 `object-fit:cover`로 어떤 뷰포트에서도 잘림 없이 채운다.

## 4. 수정 대상 파일 / 위치
- 티스토리 스킨 편집: `.ls-slider` 관련 **CSS 블록**(스킨 `style.css` 또는 `<style>`), 슬라이더 **HTML(`#slider`)**, 슬라이더 **인라인 `<script>`**. 모두 티스토리 관리자 내부. **APP 저장소 변경 없음.**
- 자산: `assets/marketing/banners/*.webp`(이 저장소에 포함)를 티스토리 이미지 업로드 또는 외부 CDN에 올린 뒤 위 `<picture>`의 URL로 연결.

## 5. Codex 작업 명세 (요약)
1. 스킨 백업(현재 HTML/CSS 저장) 후 §3.1 CSS로 `.ls-slider*` 규칙 교체.
2. 프레임 1px border 제거(또는 inset box-shadow로 대체).
3. 슬라이드 `flex:0 0 100%; min-width:0` 적용 확인.
4. (선택) 텍스트 슬라이드를 §3.3 이미지 배너로 교체 시 `<picture>` + §A 자산 연결.
5. `translateX(-i*100%)` 로직은 유지. 슬라이드 수 변동 시 dots 자동 생성 로직(기존) 재확인.

## 6. 검수 기준 (acceptance)
- [ ] 뷰포트 320 / 360 / 390 / 430(모바일) 및 768 / 1024 / 1280(PC)에서 **정지 상태에 다음 슬라이드 띠가 보이지 않음**(0px).
- [ ] 각 뷰포트에서 현재 슬라이드의 **제목·서브·CTA가 잘리지 않음**(세로/가로).
- [ ] 화살표/dot/스와이프/자동전환(5초) 모두 동작, 전환 후에도 정렬 어긋남 없음.
- [ ] `prefers-reduced-motion: reduce`에서 자동전환 정지.
- [ ] 2줄→3줄 줄바꿈이 일어나는 모바일에서 프레임 높이가 콘텐츠에 맞춰 늘어나고 잘림 없음.
- [ ] 이미지 배너 사용 시 Retina(@2x) 선택, `object-fit:cover`로 잘림 없이 채움, `loading`/`alt` 설정.
- [ ] 슬라이드 1개만 남으면 화살표·dots·자동전환 숨김.

## 7. 한계 / 미검증
- 실제 스킨 원본 CSS 전문은 열람하지 않았다(런타임 computed 값·인라인 스크립트로 역설계). border 1px은 2px 프레임/트랙 차이로부터의 **추정**이며, 스킨 편집 시 실제 규칙을 확인해 제거 대상(border/margin/padding 중 무엇인지)을 특정할 것.
- 자동전환/스와이프/reduced-motion은 코드상 확인했으나 실제 기기 터치 검수는 Owner/Codex 몫.
