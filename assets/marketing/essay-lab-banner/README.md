# 논술 LAB 홍보 배너 — 적용 가이드 (게시글 삽입용)

대상: `legendstudy.com`(티스토리) 대학별 논술 기출 게시글. 운영 반영은 **Owner 수동**(기존 게시글 자동 수정·배포 금지). 코드 제작 = Claude.

파일: [`essay-lab-banner-template.html`](essay-lab-banner-template.html) — 공통 템플릿 1종. **대학별로 새로 만들지 않고 `{{토큰}}`만 치환**.

## 0. ⚠️ 적용 전 반드시 — "공개 대학" 확정은 Owner/Codex
- **실제 '첨삭 서비스 공개(available)' 여부는 Backend 런타임/인증 신호**(`essay_web_runtime_status()`, 트랙별 `evaluationReady`, `servicePreparingUniversityIds`)로만 판정됨. Claude(비인증 MCP)로는 확정 불가 — 라이브 LAB도 비로그인 시 전 대학 "일시적으로 확인할 수 없습니다"로 표시됨.
- **미공개 대학·시험·계열을 이용 가능한 것처럼 홍보 금지.** 배너는 **Owner/Codex가 '공개'로 확정한 대학·계열에만** 인스턴스화.
- **베타 범위·기한**: 라이브 LAB 공지상 무료 첨삭은 **인문논술 중심**, **베타 2026-11-10 23:59 종료**. 수리(자연)·수리형 트랙은 `math_evaluations_enabled` 킬스위치에 종속(미확인) → **자연/수리 계열 배너는 Owner가 활성 확인 전까지 보류**. "무료" 문구는 베타 기한 때문에 템플릿 기본 CTA에 넣지 않음(필요 시 Owner가 추가).

## 1. 토큰
| 토큰 | 의미 | 예 |
|---|---|---|
| `{{UNIV_NAME}}` | 대학명 | 한양대학교 |
| `{{HEADLINE}}` | 핵심 1줄(≤2줄) | 한양대 논술, 내 답안은 어느 수준일까? |
| `{{SUBCOPY}}` | 보조 1줄 | 대학별 평가 기준으로 첨삭받고 부족한 부분을 확인하세요. |
| `{{CTA_LABEL}}` | 버튼 | 한양대 논술 첨삭받기 → |
| `{{LAB_URL}}` | 진입 URL(딥링크 우선) | https://lab.legendstudy.com/essay-lab/universities/hanyang/ |
| `{{UNIV_ID}}` | slug/ID | hanyang |
| `{{TRACK}}` | 계열 | 인문계열 |
| `{{POST_ID}}` | 게시글 식별자 | hy-2025-humanities |
| `{{CAMPAIGN_ID}}` | 캠페인 | essaylab_2026 |

## 2. 계열별 문구 프레임워크 (금지: "AI" 상품명/제목, 합격 보장·확률, 과장)
공통 질문 톤: **"논술, 내 답안에서 부족한 것은 무엇일까?"**

| 계열 | HEADLINE | SUBCOPY |
|---|---|---|
| 인문·사회 | `{대학} 논술, 내 답안은 어느 수준일까?` | 대학별 평가 기준으로 첨삭받고 부족한 부분을 확인하세요. |
| 상경(인문논술 트랙) | `{대학} 상경논술, 제시문 분석은 충분할까?` | 제시문 해석부터 논증 전개까지 평가 기준으로 점검하세요. |
| 자연·수리 ※Owner 확인 후 | `{대학} 자연논술, 풀이 과정은 정확할까?` | 풀이 과정의 논리와 오류를 평가 기준으로 확인하세요. |

- CTA 기본: `{대학} 논술 첨삭받기 →` (공개 확정 시). 안전형: `{대학} 논술 LAB 바로가기 →`.
- 게시글의 시험/계열이 **미공개**인데 대학은 공개면 → 오인 방지: CTA를 `{대학} 논술 LAB 바로가기 →`로 두고 대학 LAB 홈으로 연결(해당 시험 첨삭 가능처럼 쓰지 않음).

## 3. 삽입 위치 (티스토리 HTML 편집)
- 게시글 **제목·도입부 아래**, **기출 PDF(문제지/해설지) 안내 "위"**. 다운로드·자료 열람을 가리지 않음.
- 한 게시글에 **배너 1개만**(중복 삽입 금지). 모바일에서 과도한 높이 차지 금지(템플릿은 1카드, 모바일 세로 스택).
- `LS-ESSAY-BANNER:START ~ END` 블록 전체를 붙여넣기. 롤백 = 블록 삭제.

## 4. LAB 연결 / 딥링크
- 확인된 진입 URL: `https://lab.legendstudy.com/essay-lab/`(42개 대학 목록). 대학 상세 패턴(관찰): `…/essay-lab/universities/{slug}/`.
- **딥링크(대학·시험·계열 선택 화면) 지원 여부는 Owner/Codex 확인 후 사용.** 미지원이면 대학 상세 또는 `/essay-lab/` 홈으로. 임의 딥링크 생성 금지.
- UTM은 템플릿 CTA에 내장(`utm_source=tistory&utm_medium=post_banner&utm_campaign&utm_content={univ}_{post}`) → GA4 미발화 환경에서도 유입 추적.

## 5. GA4 이벤트 계약 (신규·비충돌)
- `lab_banner_impression` — 배너가 화면에 실제 노출(IntersectionObserver 0.5, 1회).
- `lab_banner_click` — CTA 클릭.
- 파라미터: `university_id, track, post_id, placement(post_top_above_pdf), campaign_id`, `send_to:G-295EQHYTCK`.
- 전송: gtag 우선 → dataLayer(arguments) 폴백, GA4 미설정 시 무오류. **기존 `app_promo_*` 이벤트명과 비충돌.**
- **검증**: 운영 적용 후 GA4 Realtime/DebugView에서 두 이벤트 실수신 확인 전에는 "분석 완료"로 보고하지 않음.

## 6. Owner 확정 체크리스트 (이게 채워져야 인스턴스화 가능)
- [ ] **공개(available) 대학 목록** — Codex/Owner가 인증 런타임(`essay_web_runtime_status` + 트랙별 `evaluationReady` + `servicePreparingUniversityIds`)으로 확정.
- [ ] 대학별 **공개 계열**(인문/사회/상경/자연·수리) — 수리 트랙은 `math_evaluations_enabled` 확인.
- [ ] 홍보 대상 **게시글 URL + 대학/학년도/계열** 매핑.
- [ ] 대학별 **LAB 진입 URL / 딥링크** 지원 여부.
- [ ] 베타 기한(2026-11-10) 이후 운영 정책 — "무료" 문구 사용 여부.
- [ ] 대학 로고 사용 가부·공식 자산(미확정 시 로고 없이 대학명 텍스트만).
