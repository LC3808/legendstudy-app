# TASK 15 — 모바일 웹 앱 홍보 모달 (legendstudy.com) · 2026-11-01

상태: **CONFIRMED (Owner, 2026-11-02)** — 최종 디자인·배지 폰 확인 후 확정. 운영 스킨 반영은 Owner 수행.
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

## 3. 확정 문구 (Owner 승인, 2026-11-02 개정)
```
레전드스터디⁺ 앱 출시!        (상단 "+"는 윗첨자·네이비 통일)
가능성을 좀 더 선명하게.

모의고사·수능 기출부터          (딥그린 #1E7A4D 볼드 강조)
내신 준비, 논술 첨삭까지.

레전드스터디+ 앱에서
나의 성공을 만들어가세요.        (네이비 볼드)
```
CTA "앱 다운로드하기 →" / 보조 "오늘은 그만 보기" / 닫기 "X".
- **제한/단서 문구 미표시(Owner 지시)**: "논술 첨삭은 지원 대학에 한해…" 류 문구는 모달에 넣지 않음(Owner가 의도적으로 삭제). 지원/미지원 대학 구분은 Codex 기능·LAB 화면에서 처리. 카피 변경은 Owner 명시 지시만.
- 색: 배경 화이트, 텍스트 네이비 `#192B49`, 강조 라인 딥그린 `#1E7A4D` 볼드, CTA 블랙 `#1A1D21`. 로고 "+"는 윗첨자+네이비로 통일(주황 제거).
- **CTA 버튼 = 블랙 솔리드(#1A1D21) + 흰 글자**(Owner 확정 2026-11-02). 초기 주황 버튼이 앱 톤 대비 과해 교체(네이비 시안 검토 후 블랙으로 확정).
- **CTA 아래 공식 스토어 배지(옵션1)**: App Store(SVG)·Google Play(PNG) 공식 배지를 **인라인 data URI**(높이 30px)로 삽입. 각각 iOS/Android 스토어 URL로 이동, 클릭 시 15일 숨김·`app_promo_click` 기록. 공식 앱 신뢰 신호. 원본: `assets/marketing/handover/`.

## 4. 노출/숨김 정책 (Owner 수정 2026-11-01)
| 조건 | 동작 | 저장 |
|---|---|---|
| 노출 대상 | 모바일 웹만(PC·인앱 WebView 미노출) | — |
| 노출 시점 | 진입 **5초 후**, **세션(탭)당 최대 3회**(`maxPerSession`) | `sessionStorage ls_appmodal_count` |
| X / 배경 / ESC | **지속 숨김 없음** — 닫아도 재접속/새로고침 시 다시 노출 | 기록 안 함 |
| 오늘은 그만 보기 | 당일(자정까지) 숨김 | `localStorage ls_appmodal_hide_until` |
| 앱 다운로드하기 | **15일** 숨김 후 스토어 이동 | 동일 키 |
| PDF 뷰어 중 / 키보드 입력 중 | 미노출(입력 종료 후 1회 재시도) | — |
- 전용 네임스페이스 `ls_appmodal_*` → 기존 숨김 정책과 충돌 없음. 세션(탭)당 **최대 3회** 캡(`maxPerSession`, sessionStorage 카운터)으로 과노출·광고 피로 방지. 탭 닫으면 리셋(새 세션).
- **테스트 우회**: URL에 `?lsapm=test`(또는 `?promo=1`) → 빈도·숨김 전부 무시하고 매번 노출(운영자 검증용). 일반 사용자는 캡 적용.
- 스토리지 접근 실패 시 try/catch로 무오류(메모리 폴백). 숨김 기록 실패 시 노출 쪽으로 동작(과억제 방지).
- 이력: 초기 안(6초·세션1회·X 24h·다운로드 30일) → Owner 수정(5초·세션제한 없음·X 지속숨김 없음·다운로드 15일). 올려주신 코드의 CTA `+` 구문오류(NaN) 수정. "논술 첨삭은 지원 대학에 한해…" 문구는 Owner 지시로 **미표시**.

## 5. 기기별 링크(공식 URL, 변경 금지)
- iOS: `https://apps.apple.com/us/app/%EB%A0%88%EC%A0%84%EB%93%9C%EC%8A%A4%ED%84%B0%EB%94%94/id6820826957`
- Android/기타: `https://play.google.com/store/apps/details?id=com.legendstudy.app`
- UA 자동 판별(iPhone/iPad/iPod + iPadOS data desktop 보정 → App Store, 그 외 → Google Play).

## 6. 분석 이벤트(GA4, 신규·비충돌)
`app_promo_impression` / `app_promo_click` / `app_promo_dismiss` / `app_promo_snooze`.
파라미터: `platform`(ios/android), `placement`(mobile_web), `store`(appstore/googleplay), `reason`.
기존 GA4 이벤트명과 중복 없음. GA4 미설정이어도 무오류.
- 2026-11-03 `track()` 교체(Codex analytics-phase1, Claude 검수): 파라미터 화이트리스트 + `send_to: G-295EQHYTCK` 명시 + `dataLayer.push(arguments)`(정석 gtag) + 이름당 1회 dedup. 호환성 위해 `catch(e)` 유지. 이벤트별 발화·세션 3회 노출 정책 불변 검증. CTA는 80ms 지연 후 이동(비콘 여유), 배지는 sendBeacon 의존(수신 확정은 GA4 Realtime). 전제: 페이지에 gtag.js로 G-295EQHYTCK 설정돼 있어야 함.

## 7. UX 안전성 / 접근성
- 배경 스크롤 잠금(position:fixed + top offset) → 닫을 때 스크롤 위치 복원.
- `role="dialog"` `aria-modal="true"` `aria-labelledby`/`aria-describedby`, 포커스 트랩, ESC 닫기, 닫은 뒤 이전 포커스 복원.
- `prefers-reduced-motion` 존중, 애니메이션 최소(페이드/슬라이드 ~0.2s).
- CTA는 `<button>`으로 구현(링크 `<a>`의 스킨 링크색·밑줄 오염 방지 — 이동은 JS `location.assign`). 모달 오픈 시 포커스는 CTA가 아닌 다이얼로그 컨테이너(tabindex=-1)에 둬 자동 포커스 외곽선(파란 링) 미노출.

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
- 2026-11-02 Owner 폰 확인 후 최종 디자인 **확정**. 운영 반영/교차검증 결과는 Owner가 최종 확인.
- 후속(별건): 모달 전환율(app_promo_click/impression) 관찰 → 노출 타이밍·빈도 A/B, 가입→논술 체험→결제 퍼널 개선.
