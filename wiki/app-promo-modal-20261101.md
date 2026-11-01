# TASK 15 — 모바일 웹 앱 홍보 모달 (legendstudy.com) · 2026-11-01

상태: **CODE COMPLETE / OWNER DEPLOYMENT PENDING**
담당: Claude(UI/UX·지원 코딩). 대상: `legendstudy.com`(**티스토리 스킨**).
산출물: `assets/marketing/promo-modal/` — [`legendstudy-app-promo-modal.html`](../assets/marketing/promo-modal/legendstudy-app-promo-modal.html)(드롭인 코드), [`README.md`](../assets/marketing/promo-modal/README.md)(적용 가이드).

> Owner가 실제 모바일 웹에 적용하고 정상 작동을 확인한 **이후에만** TASK 15 완료 처리. 운영 스킨은 Claude가 직접 수정하지 않음.

## 1. 목적 / 범위
- 모바일 웹 방문자(약 10,000명/일)에게 레전드스터디+ 앱 설치 전환 유도.
- 작업 대상: 티스토리 스킨 HTML에 **드롭인 블록 1개** 추가(스킨 HTML + 인라인 style/script).
- **변경 금지**: Flutter APP, LAB WEB, Supabase, Worker, Credit, 결제, 기존 게시글 본문, 기존 CSS 전체. Codex TASK 14-B/C와 영역 분리.

## 2. 플랫폼 실측(근거)
- legendstudy.com = 티스토리(daumcdn/tistory, jQuery 1.11.0). 본문 래퍼 `div#jbContainer`.
- GA4 `G-295EQHYTCK`(gtag.js, dataLayer 존재). `window.gtag`가 항상 전역은 아니어서 전송 헬퍼는 **gtag 우선, 없으면 dataLayer.push(['event',…]) 폴백**.
- 메인 슬라이더 `.ls-slider` 존재, 페이지 내 최대 z-index=10000 → 모달 z-index **2147483000**(광고·슬라이더 위).

## 3. 확정 문구 (Owner 승인 2026-11-01, 원문 유지)
```
LegendStudy+
가능성을 좀 더 선명하게.

모의고사·수능 기출부터
내신 준비, 논술 첨삭까지.

레전드스터디+에서
나만의 학습을 시작하세요.

논술 첨삭은 지원 대학에 한해 제공됩니다.
```
CTA "앱 다운로드하기 →" / 보조 "오늘은 그만 보기" / 닫기 "X".
- **"논술 첨삭은 지원 대학에 한해 제공됩니다." 유지**: Codex가 개발 중인 지원/미지원 대학 구분·순차 제공 정책을 반영한 정확한 안내. 임의 삭제·변경 금지(문구 변경은 Owner 지시만).
- 색: Orange `#FFAC14`, Navy `#192B49`, 화이트 배경, 부드러운 모서리, 절제된 그림자.

## 4. 노출/숨김 정책 (Owner 수정 2026-11-01)
| 조건 | 동작 | 저장 |
|---|---|---|
| 노출 대상 | 모바일 웹만(PC·인앱 WebView 미노출) | — |
| 노출 시점 | 진입 **5초 후** (세션 1회 제한 없음 — 새로고침/재접속마다 노출) | — |
| X / 배경 / ESC | **지속 숨김 없음** — 닫아도 재접속/새로고침 시 다시 노출 | 기록 안 함 |
| 오늘은 그만 보기 | 당일(자정까지) 숨김 | `localStorage ls_appmodal_hide_until` |
| 앱 다운로드하기 | **15일** 숨김 후 스토어 이동 | 동일 키 |
| PDF 뷰어 중 / 키보드 입력 중 | 미노출(입력 종료 후 1회 재시도) | — |
- 전용 네임스페이스 `ls_appmodal_*` → 기존 숨김 정책과 충돌 없음. 세션 1회 제한(sessionStorage/쿠키)은 Owner 지시로 **제거**(새로고침/재접속 시 재노출 보장).
- 스토리지 접근 실패 시 try/catch로 무오류(메모리 폴백). 숨김 기록 실패 시 노출 쪽으로 동작(과억제 방지).
- 이력: 초기 안(6초·세션1회·X 24h·다운로드 30일) → Owner 수정(5초·세션제한 없음·X 지속숨김 없음·다운로드 15일). 동시에 올려주신 코드의 CTA `+` 구문오류(NaN)·누락된 안내문구 복원.

## 5. 기기별 링크(공식 URL, 변경 금지)
- iOS: `https://apps.apple.com/us/app/%EB%A0%88%EC%A0%84%EB%93%9C%EC%8A%A4%ED%84%B0%EB%94%94/id6820826957`
- Android/기타: `https://play.google.com/store/apps/details?id=com.legendstudy.app`
- UA 자동 판별(iPhone/iPad/iPod + iPadOS data desktop 보정 → App Store, 그 외 → Google Play).

## 6. 분석 이벤트(GA4, 신규·비충돌)
`app_promo_impression` / `app_promo_click` / `app_promo_dismiss` / `app_promo_snooze`.
파라미터: `platform`(ios/android), `placement`(mobile_web), `store`(appstore/googleplay), `reason`.
기존 GA4 이벤트명과 중복 없음. GA4 미설정이어도 무오류.

## 7. UX 안전성 / 접근성
- 배경 스크롤 잠금(position:fixed + top offset) → 닫을 때 스크롤 위치 복원.
- `role="dialog"` `aria-modal="true"` `aria-labelledby`/`aria-describedby`, 포커스 트랩, ESC 닫기, 닫은 뒤 이전 포커스 복원.
- `prefers-reduced-motion` 존중, 애니메이션 최소(페이드/슬라이드 ~0.2s).

## 8. 충돌/보존 검증(실측 2026-11-01)
- 라이브 스캔: `lsapm` 클래스/ID 0건, 전역 `__lsAppPromoInit` 미존재, `ls_appmodal_*` 스토리지 키 미사용, 겹치는 fixed/sticky 오버레이 없음.
- 보존 확인: 홈 슬라이더(.ls-slider)·AdSense(ins.adsbygoogle)·검색 정상. 헤더·게시글·카테고리·인기글·댓글·PDF 다운로드·게시글 내부 배너·기존 앱 홍보 배너 **미변경**(이 블록은 독립 추가).
- JS `node --check` 통과. 실제 모바일(375px) 라이브 렌더 확인(레이아웃·가독성·z-index 정상, 텍스트 잘림 없음).
- 전역 1회 가드 `__lsAppPromoInit` + vanilla JS(기존 jQuery 1.11 비의존) → Codex TASK 14-B/C와 간섭 없음.

## 9. Owner 적용 순서(요약 — 상세는 README)
1. (권장) 현재 스킨 HTML 전체 백업.
2. 티스토리 관리 → 꾸미기 → 스킨 편집 → html 편집.
3. 맨 아래 `</body>` 바로 앞에 `legendstudy-app-promo-modal.html` 전체 붙여넣기(블록 1개).
4. 적용(저장) → §검증 체크리스트 수행.
5. 롤백: `<!-- LS-APP-PROMO-MODAL:START -->`~`<!-- LS-APP-PROMO-MODAL:END -->` 블록 전체 삭제.

## 10. 미결(Owner)
- 실제 티스토리 스킨 수정 권한·배포 수행(Claude 권한 없음 → 코드·위치 제공으로 대체).
- 적용 후 iPhone Safari/Chrome·Android Chrome·삼성인터넷·PC 교차 검증.
- 정상 작동 확인 후 TASK 15 완료 처리.
