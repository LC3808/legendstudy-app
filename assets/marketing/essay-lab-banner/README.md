# 논술 LAB 홍보 배너 — 적용 가이드 (게시글 삽입용)

대상: `legendstudy.com`(티스토리) 대학별 논술 기출 게시글. 운영 반영은 **Owner 수동**(기존 게시글 자동 수정·배포 금지). 코드 제작 = Claude.

파일: [`essay-lab-banner-template.html`](essay-lab-banner-template.html) — 공통 템플릿 1종. **대학별로 새로 만들지 않고 `{{토큰}}`만 치환**.

## 0. ⚠️ 적용 전 반드시 — "공개 대학" 확정은 Owner/Codex
- **실제 '첨삭 서비스 공개(available)' 여부는 Backend 런타임/인증 신호**(`essay_web_runtime_status()`, 트랙별 `evaluationReady`, `servicePreparingUniversityIds`)로만 판정됨. Claude(비인증 MCP)로는 확정 불가 — 라이브 LAB도 비로그인 시 전 대학 "일시적으로 확인할 수 없습니다"로 표시됨.
- **미공개 대학·시험·계열을 이용 가능한 것처럼 홍보 금지.** 배너는 **Owner/Codex가 '공개'로 확정한 대학·계열에만** 인스턴스화.
- **무료 훅(상시정책, Owner 확정 2026-11-05)**: 배너의 무료 강조는 **"신규가입 무료 첨삭 3회"**(베타 종료 후에도 유지되는 기존 정책)에 근거 → 템플릿에 상시 혜택 pill로 내장("신규가입 무료 첨삭 3회 · 웹·앱 모두 이용"). **베타 매일 1회 무료(2026-11-11 00:00 종료)와는 구분** — 배너는 소멸하는 베타 혜택을 쓰지 않는다. "3회"로 무료 **횟수 제한**을 명시.
- **웹·앱 공통**: 논술 LAB은 웹·앱 모두 이용 가능 → 혜택 pill에 명시. 기본 CTA는 WEB LAB으로 연결.
- **계열별 공개 종속**: 자연·수리 트랙은 `math_evaluations_enabled` 킬스위치에 종속 → 해당 계열 배너는 Codex가 AVAILABLE 확인한 대학에만.
- **서비스 상태 분류**(Codex 판정): AVAILABLE(현재 첨삭 가능) / PARTIAL(일부 시험·계열만) / PREPARING(준비 중) / BLOCKED(정책 차단). **AVAILABLE·PARTIAL의 공개 계열만** 배너화.

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
공통 훅: **"온라인 무료 논술 첨삭"** + 상시 혜택 pill **"신규가입 무료 첨삭 3회 · 웹·앱 모두 이용"**(템플릿 내장·전 대학 공통). HEADLINE은 대학별, SUBCOPY는 간결 1줄.

| 계열 | HEADLINE | SUBCOPY |
|---|---|---|
| 인문·사회 | `{대학} 논술, 온라인에서 무료로 첨삭받으세요.` | 대학별 평가 기준으로 내 답안의 부족한 부분을 확인하세요. |
| 상경(인문논술 트랙) | `{대학} 상경논술, 계산부터 논증까지 점검하세요.` | 제시문 해석·수식 논증을 평가 기준으로 온라인에서 첨삭받으세요. |
| 자연·수리 ※AVAILABLE 확인 후 | `{대학} 자연논술, 풀이 과정까지 첨삭받으세요.` | 풀이 과정의 논리와 오류를 평가 기준으로 확인하세요. |

- CTA 기본: `{대학} 논술 첨삭받기 →`(공개 확정 시). 안전형: `{대학} 논술 LAB 바로가기 →`.
- 게시글의 시험/계열이 **미공개**인데 대학은 공개면 → 오인 방지: CTA를 `{대학} 논술 LAB 바로가기 →`로 두고 대학 LAB 홈으로 연결(해당 시험 첨삭 가능처럼 쓰지 않음). 동일 대학의 **다른 공개 시험**으로 연결 시 그 사실을 SUBCOPY에 명시.
- "온라인에서 바로 · 대면/학원 방문 불필요"는 필요 시 SUBCOPY에 1회만(과장·반복 금지).

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

## 7. Codex 전달용 데이터 포맷 (STEP 1 산출 — 이 표가 오면 즉시 인스턴스화)
인증된 일반(베타) 사용자 기준으로 `essay_web_runtime_status()` + 대학별 `essay_browse_catalog()`의 `evaluationReady` + `servicePreparingUniversityIds` + Essay/Math 평가 활성화를 **조회만으로** 확인(실제 평가 실행 없이). 비로그인 `evaluationReady:false`만으로 미공개 단정 금지.

대학·계열 단위로 한 행씩:

| 대학명 | 대학ID/slug | 학년도 | 시험명 | 시험ID | 계열 | 문항수 | 평가자료연결 | 서비스상태 | LAB URL | 딥링크지원 | 배너제작가능 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| (예)한양대 | hanyang | 2025 | 수시논술 인문 | … | 인문계열 | 1 | 연결됨 | AVAILABLE | …/essay-lab/universities/hanyang/ | Y/N | Y |

추가로 두 요약 목록:
- **A. 현재 실제 첨삭 가능(AVAILABLE/PARTIAL) 대학** — 배너 대상.
- **B. 등록되었으나 첨삭 불가(PREPARING/BLOCKED) 대학** — 배너 제외(또는 "준비 중" 비노출).
- 기존 운영연결 15개 대학 + 후보 5곳(한양·중앙·인하·서강·건국)의 상태를 **빠짐없이** 명시(추측 금지).
