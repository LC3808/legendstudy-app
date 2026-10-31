# 레전드스터디+ 베타 출시 마케팅 & 논술 LAB 정비 — 마스터 (§A/§B/§G/§H/§17) — 2026-11-01, Claude

Claude 역할 = 기획·디자인·자료 분석·구조화·검토. 실제 WEB/APP 구현·DB·배포는 Codex/Owner. **기존 서비스 코드(APP·평가 엔진·Credit·결제·운영 DB·Registry) 미수정.** 별도 Claude 작업 브랜치(`claude/relaxed-stonebraker-027081`), Codex 개발 브랜치 **덮어쓰기 금지**.

## 분할 문서 (이 마스터가 인덱스)
- §5/§C 메인 슬라이더 수정: [web-main-slider-fix-20261101.md](web-main-slider-fix-20261101.md)
- §8/§11 지원상태 불일치·UX: [essay-support-status-ux-20261101.md](essay-support-status-ux-20261101.md)
- §7/§12 논술 일정 입력·검증: [essay-schedule-intake-20261101.md](essay-schedule-intake-20261101.md)
- §9/§13 마케팅 Analytics: [marketing-analytics-events-20261101.md](marketing-analytics-events-20261101.md)
- §A/§B 배너 자산: `assets/marketing/banners/` (+ `README.md`)
- 기존 Analytics v1(재사용): [analytics-v1-implementation-20261030.md](analytics-v1-implementation-20261030.md)

## 플랫폼 지도 (실측 2026-11-01)
- `legendstudy.com` = **티스토리 블로그**(skin HTML/CSS/JS, jQuery). 자료실 게시글·메인 `.ls-slider`·배너 삽입 대상. **APP 저장소 아님**. 자체 GA4 `G-295EQHYTCK`.
- `lab.legendstudy.com` = **커스텀 LAB 웹**. 라우팅: `/essay-lab/`(논술, live), `/score-analysis/`(내신), `/exam-analysis/`(수능), 대학 상세 `/essay-lab/universities/{sourceUniversityId}/`.
- APP(Flutter, 이 저장소군) = 논술 LAB 포함. 상태 배지 `LabStatusBadge`, 준비중 `lab_coming_soon_page.dart`.

---

## §A. 마케팅 배너 3종 — 디자인 시안 + 최적화 이미지 자산
실제 적용 가능한 **WebP 자산(PC·모바일·Retina @2x) + PNG 폴백 + 편집용 SVG**를 `assets/marketing/banners/`에 생성 완료(단순 텍스트 설명 아님). 상세·파일표는 배너 `README.md`.

디자인 시안(공통): 흰/웜 배경 + 브랜드 오렌지 포인트(과도한 오렌지 지양, design-system 원칙), 좌측 텍스트 블록(eyebrow 칩 → 굵은 제목 → 서브 → 오렌지 CTA pill[화살표]), 우측 브랜드 카드(공식 메모+연필 심볼 + `레전드스터디+`). 모바일은 세로 스택(브랜드마크 상단 → eyebrow → 제목 줄바꿈 → 서브 → CTA). **모바일 텍스트 잘림/버튼 가림 없음**(320–430 검수).

| # | key | 카피 | CTA | URL(변경 금지) |
|---|---|---|---|---|
| 1 | `ios-launch` | 레전드스터디+, 이제 아이폰에서도 만나보세요. | App Store에서 다운로드 → | apps.apple.com/.../id6820826957 |
| 2 | `android-launch` | 레전드스터디+, 안드로이드 앱 출시! | Google Play에서 다운로드 → | play.google.com/store/apps/details?id=com.legendstudy.app&hl=ko |
| 3 | `lab-beta` | 논술, 내 글에서 부족한 것이 무엇일까? | 논술 LAB 시작하기 → | lab.legendstudy.com |

규격: PC 1024×256(@2x 2048×512), 모바일 640×360(@2x 1280×720). WebP q86(PC @1x ~15KB/@2x ~32KB). `App Store`/`Google Play`는 텍스트 워드마크만(로고 미사용, 상표 안전). 3번 서브카피 "인문논술 LAB 베타 오픈 · 매일 무료 첨삭 1회"는 §G 정책과 정합.

---

## §B. 대학별 자료실 게시글 공통 홍보 배너 (티스토리)
### B-1. 카피/CTA
지시서 §6-1의 정확한 카피/서브/CTA 원문은 이 세션에 전달되지 않았다 → **플레이스홀더로 제안**하고 Owner 원문으로 치환 대기(아래 "미완료"). 제안 템플릿(지원상태별, §D 4-state와 정합):
- **AVAILABLE(지원)**: 제목 "{대학} 논술, 내 답안의 부족한 점을 바로 확인하세요." / 서브 "대학별 평가 기준 AI 첨삭 · 베타 매일 무료 1회" / CTA **"{대학} 논술 첨삭받기 →"** → `/essay-lab/universities/{id}/`
- **COMING_SOON(준비중)**: 제목 "{대학} 논술 자료, 지금 바로 확인해 보세요." / 서브 "첨삭 지원은 준비 중 · 공식 기출·자료를 먼저 확인" / CTA **"{대학} 논술 자료 확인하기 →"** → 대학 LAB 또는 officialSourceUrl
자산: `assets/marketing/banners/univ-post-sogang*`(지원 예시), `univ-post-comingsoon*`(준비중 템플릿).

### B-2. 라우팅(실측) — URL 임의 생성 금지
대학 LAB 페이지 = **`https://lab.legendstudy.com/essay-lab/universities/{sourceUniversityId}/`** (실측 확인: sogang/konkuk/korea/kyunghee/… 모두 이 패턴). `{sourceUniversityId}`는 `lib/features/essay/university_catalog.dart`의 `sourceUniversityId` 값. 예: 서강대→`/essay-lab/universities/sogang/`, 건국대→`/essay-lab/universities/konkuk/`.

**URL 매핑 규칙**: 게시글의 대학명 → `university_catalog`의 name→sourceUniversityId 매핑 → 위 URL. 42개 대학 매핑표는 catalog가 진실원천(별도 하드코딩 금지, catalog에서 생성).

### B-3. 티스토리 삽입 방식 비교 → 권장
| 방식 | 장점 | 단점 | 적합도 |
|---|---|---|---|
| (1) 개별 게시글 HTML 삽입 | 대학별 정확 연결 | 게시글마다 수작업·유지보수 폭증 | 낮음 |
| (2) 스킨 공통 고정 | 1회 작업, 전 페이지 노출 | 대학별 타겟팅 불가(단일 LAB 링크만) | 보조 |
| (3) 카테고리 단위 | "논술 기출 자료" 카테고리에만 노출 | 대학 자동 구분은 여전히 수동 | 보조 |
| (4) **스킨 공통 + JS 자동 매핑** | 1회 작업 + 게시글의 대학 자동 감지→해당 LAB URL·상태별 CTA | 초기 JS·매핑표·상태맵 필요 | **권장** |

**권장안 (4)**: 티스토리 스킨에 배너 템플릿(HTML/CSS) 1개 + 경량 JS를 넣어, 게시글 제목/카테고리/태그에서 대학을 감지 → `university_catalog` 기반 name→slug 매핑으로 `destination_url` 설정 → **정적 availability 맵**으로 CTA(지원=첨삭받기 / 준비중=자료 확인하기) 선택. 티스토리에서 LAB 상태 API 실시간 호출은 CORS/인증 제약이 있으므로, **보수적 정적 맵**(릴리스 시 갱신, 기본값=자료 확인하기)으로 하고 "지원"은 확정 대학만. 기존 `.ls-slider` 스크립트가 이미 카테고리 매핑(`CAT.essay` 등)을 하므로 동일 패턴 재사용. 배너 자산은 §A `univ-post-*` 반응형 `<picture>` 사용.

### B-4. Analytics
배너 노출/클릭은 `banner_impression`/`banner_click`, `banner_type=univ_post`, `university_code={slug}`, `source(_page)=web_univ_post`(§F). 티스토리 GA4(G-295EQHYTCK)로 송신, LAB 퍼널과는 크로스도메인 설정 시 연결.

---

## §G. 베타 운영 정책 반영 (출시 문구)
권위 출처: [essay-beta-daily-v2.md](essay-beta-daily-v2.md), [admin-beta-operations.md](admin-beta-operations.md)(Owner 확정 2026-10-31).
- **매일 무료 첨삭 1회**(인문논술 시험 단위), **00:00 KST 갱신, 이월 없음**.
- **베타 종료: 2026-11-11 00:00 KST(= 11월 10일까지 이용).** 종료 전 접수 요청은 종료 후 완료 가능(경계 배타적). ⚠️ 지시서 본문의 "종료 목표 2026-11-10"과 권위 문서의 "11/10까지·11/11 00:00 종료"는 **같은 의미**(10일까지 사용). **정확한 종료 시각 화면 문구는 Owner 최종 운영 설정 확인 후 확정**(현재 `starts_on` placeholder, 종료만 확정).
- 무료 재첨삭: 베타 원본 포함 재첨삭 1회만, **min(최초 완료+14일, 캠페인 종료)** 이내·종료 초과 불가.
- 신규가입 **3 Credit**, 유료 Credit 유지. **WEB·APP 동일 Backend/계정** 공유. 종료 후 혜택 자동 종료·기록 보존.

### 문구 규칙(오인 금지)
- **메인 배너**(§A lab-beta)에는 **"인문논술 LAB 베타 오픈" + "매일 무료 첨삭 1회"만**. 상세(재첨삭 14일·종료일·범위)는 **LAB 베타 안내/공지**에서.
- 종료 후에도 혜택이 계속되는 듯한 문구 **금지**. "매일 무료"는 베타 기간 한정임을 공지에서 명확히.
- 과장된 AI 성능 표현 금지(합격 예측/점수 보장 등). "부족한 점 점검·다시 쓰기" 톤 유지(기존 `lab_coming_soon_page` 카피 철학).
- 미제공 기능 홍보 금지(내신/수능 LAB은 "준비 중").

---

## §H. Codex 인수인계 패키지
### 수정 대상(표면별)
| 영역 | 대상 | 저장소 여부 |
|---|---|---|
| §5 슬라이더 | 티스토리 스킨 `.ls-slider` HTML/CSS/인라인 JS | 아니오(티스토리) |
| §A/§B 배너 | 티스토리 스킨에 `<picture>` 삽입 + 자산 업로드; §B는 스킨 JS 자동 매핑 | 자산은 저장소, 삽입은 티스토리 |
| §D 지원상태 | WEB 4-state 컴포넌트 신설; APP 기존 `LabStatusBadge`/coming-soon 문구 정합; 트랙 레벨 필터 제거(Registry 단일 기준) | LAB web + APP |
| §E 일정 | staging CSV/검증기(저장소); 운영 테이블은 Owner 승인 후 | 저장소(staging만) |
| §F Analytics | `analytics_events.dart` 상수/allowlist 추가 + 배너/퍼널 log() | APP + LAB web + 티스토리 gtag |

### 구현 우선순위
1. (P0) §5 슬라이더 수정(배너 올리기 전 필수 — 안 하면 새 배너가 잘림/노출됨).
2. (P0) §A/§B 배너 삽입 + §F `banner_*` 계측.
3. (P1) §D 지원상태 통일(서강 검증 게이트, 건국 수리 상태 문구).
4. (P1) §G 베타 공지/안내 문구 정합(종료 시각 Owner 확정 후).
5. (P2) §E 일정: Owner 자료 도착분부터 입력·검증(순차).

### 기능별 완료 조건 / 회귀 테스트
- 각 분할 문서의 "검수 기준" 체크리스트 사용. 회귀: 슬라이더(320–1280 뷰포트 잘림/노출), 배너(모바일 잘림·Retina·링크), 지원상태(WEB↔APP 동일·color-only 아님·새 필드 0), Analytics(이벤트명 충돌 0·allowlist drop·설치≠완료), 일정(validate.py 0 errors·미제공 UNKNOWN 유지).

### Owner 승인 필요
- 서강 경제경영/상경 "지원" 확정(검증 게이트 결과), 수리 평가 활성화 시점(건국 통합), 베타 종료 시각 화면 문구, §B 카피 §6-1 원문, §E 운영 테이블 설계·데이터 반영, `source` vs `source_page` 택1, GA4 크로스도메인·Firebase 설정.

### TASK 01~07 중복 방지
- TASK01 공지 시스템: §G 베타 상세는 **공지 단일 저장소** 사용(새 공지 저장소 금지).
- TASK02 베타 v2 / TASK04 관리자: 정책·종료·재첨삭은 그 계약 **재사용**(본 작업은 **문구·배너**만, 정책 로직 미변경).
- TASK03 Analytics: §F는 **기존 계약 확장**(신규 이벤트 2개·키 매핑만, 중복 금지).
- TASK05 피드백/신고, TASK06/07(운영/배포)은 본 작업 범위 밖. 평가 엔진·Worker·Credit·결제·Registry·OCR·PDF **미변경**.

---

## §17. 최종 보고 (21개 항목)
1. **작업 브랜치**: `claude/relaxed-stonebraker-027081`(main 기반). Codex 브랜치 미변경.
2. **최종 SHA**: 커밋/푸시 후 기록(본 문서 하단 갱신 + 보고 메시지).
3. **배너 4종 자산**: `assets/marketing/banners/`에 5키(ios-launch, android-launch, lab-beta, univ-post-sogang[지원], univ-post-comingsoon[준비중]) × {pc/mobile}×{@1x webp, @2x webp} + png 폴백 + svg 소스. ✅
4. **PC/모바일 디자인 명세**: §A + 배너 README(규격·토큰·반응형 `<picture>`). ✅
5. **슬라이더 개선안**: [web-main-slider-fix](web-main-slider-fix-20261101.md) — 원인(고정높이+overflow, 프레임/트랙 2px, flex/translate 취약) + CSS/JS 수정 + 검수. ✅
6. **서강대 검토**: §D-A — WEB 경제경영=인문 11회차 등록, APP 트랙 필터로 미지원. 계열명 수리 오판 금지, 검증 게이트 후 Registry 단일 기준 통일. ✅
7. **건국대 검토**: §D-B — 통합(수학) = 수리 런타임 킬스위치(`math_evaluations_enabled`) 기반 COMING_SOON, 버튼 숨김 금지·명시 안내. ✅
8. **APP·WEB 지원상태 통일 명세**: §D-C/D — 4-state(AVAILABLE/COMING_SOON/UNAVAILABLE/ERROR) + 문구/위치/CTA, 기존 Backend 매핑, 새 필드 금지. ✅
9. **일정 데이터 입력 양식**: §E — CSV 템플릿/JSON Schema/검증기(`assets/essay-schedule/`), validate.py 0 errors. ✅
10. **Analytics 이벤트 명세**: §F — 기존 재사용 + `banner_impression`/`banner_click`만 신규, `university_code`/`exam_code` 매핑, 설치≠완료. ✅
11. **Codex 인수인계 문서**: §H(본 문서). ✅
12. **생성 파일 경로**: 아래 "생성 파일" 목록. ✅
13. **테스트/검토 결과**: 배너 렌더 PASS(잘림 0, 320–1024 시각 확인), validate.py PASS(2 rows 0 invalid), 슬라이더/라우팅/지원상태 런타임 실측. Flutter/WEB 빌드·테스트는 본 작업이 서비스 코드 미변경이므로 해당 없음.
14. **미완료 항목**: §B 카피 §6-1 원문 대기; §E 대학별 실제 일정 Owner 자료 순차 대기; 서강 검증 게이트 실행(DB SELECT/실평가); GA4 크로스도메인·Firebase 실수신; 베타 종료 시각 화면 문구 확정; 실제 티스토리 스킨 편집/배포.
15. **Owner 승인 필요**: §H "Owner 승인 필요" 목록.
16. **Wiki 현행화**: 분할 문서 5 + 마스터 + log.md/index.md 포인터. 경쟁 status 문서 미생성(current-status.md 미개편).
17. **브랜드/제약 준수**: #FFAC14·기존 디자인 시스템, 새 브랜드 시스템 미도입, 모바일 잘림/가림 0, 공식 스토어 URL만, 미제공 기능 홍보 금지, 과장 AI 표현 금지.
18. **기존 서비스 코드 미수정**: APP/엔진/Credit/결제/운영 DB/Registry 변경 0(문서·자산·staging만).
19. **브랜치 격리**: Codex 개발 브랜치 미접근·미덮어쓰기, 별도 Claude 브랜치만.
20. **운영 DB 미반영**: SQL/마이그레이션 적용 0, staging CSV만.
21. **보고**: commit/push(Claude 브랜치만) 후 Owner 보고.

### 생성 파일
- `wiki/beta-launch-marketing-20261101.md`(본 문서), `wiki/web-main-slider-fix-20261101.md`, `wiki/essay-support-status-ux-20261101.md`, `wiki/essay-schedule-intake-20261101.md`, `wiki/marketing-analytics-events-20261101.md`
- `assets/marketing/banners/`: `*.webp`(20) `*.png`(10) `svg/*.svg`(10) `gen.py` `README.md`
- `assets/essay-schedule/`: `schedule-template.csv` `schedule.schema.json` `validate.py`
- `wiki/log.md`·`wiki/index.md` 포인터 갱신.
