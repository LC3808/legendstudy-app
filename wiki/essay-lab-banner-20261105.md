# 대학별 논술 LAB 홍보 배너 (게시글 삽입) — 2026-11-05

상태: **템플릿 v2·프레임워크 완료 / Codex STEP1(공개 대학 목록) 대기**. 담당: Claude(디자인·코드·검증설계), 데이터검증=Codex, 승인·삽입=Owner. 대상: `legendstudy.com`(티스토리) 대학별 논술 기출 게시글. 운영 반영·게시글 수정 = Owner 수동.

> 2026-11-05 최종 통합 지시 반영: 홍보 훅 = **"온라인 무료 논술 첨삭" + "신규가입 무료 첨삭 3회"(상시정책, 베타와 구분)** + 웹·앱 공통. 역할분담 = Codex가 공개대학 추출(STEP1) → Claude가 매핑·문구·HTML·검증(STEP2~7) → Owner 승인·삽입. 템플릿 v2: 혜택 pill 내장, 서비스상태 분류(AVAILABLE/PARTIAL/PREPARING/BLOCKED) 중 AVAILABLE·PARTIAL만 배너화.
> 2026-11-05(2) **계열 미구분**(Owner): 게시글이 대학별·회차별이라 배너는 **대학 단위 1종**. 계열 chip·계열별 문구 제거, 대학 LAB 홈으로 연결(사용자가 공개 시험 선택 → 계열 오인 없음). GA4 `track` 파라미터 제거. 템플릿 토큰에서 `{{TRACK}}` 삭제.
산출물: `assets/marketing/essay-lab-banner/` — [`essay-lab-banner-template.html`](../assets/marketing/essay-lab-banner/essay-lab-banner-template.html), [`README.md`](../assets/marketing/essay-lab-banner/README.md).

## 1. Phase 1 — 실제 공개 레지스트리 확인 (읽기전용 실측)
핵심 결론: **"첨삭 서비스 공개(available)" 집합은 Claude가 단독 확정 불가 → Owner/Codex 소관.** 근거:
- `essay_web_runtime_status()` = **인증 필요**(`math_private.require_active(auth.uid())`)라 비인증 MCP로 호출 시 `insufficient_privilege`. 수리 킬스위치(`math_evaluations_enabled`) 값 미확인.
- `essay_browse_catalog('hanyang')`는 호출되나 **전 시험 `evaluationReady:false`**(비인증 컨텍스트). `evaluationReady`가 런타임/유저 베타 상태에 종속 → 익명 컨텍스트에선 공개 여부 판정 불가.
- 라이브 LAB `https://lab.legendstudy.com/essay-lab/` = **42개 대학**, 비로그인 시 **전 대학 "일시적으로 확인할 수 없습니다 · 다시 시도"**(상태 API 인증/장애 fallback). 익명 방문자는 공개 집합을 볼 수 없음. (essay-support-status-ux-20261101 §F와 일치)
- 테이블 플래그는 진실원천 아님: `essay_questions.is_published`가 전 대학 **0건**이고, `essay_exams.is_active`로 거른 2025+ 활성 대학은 {경희, 성균관, 연세, 숙명, 한양} 5곳뿐이라 "15 대학/202 시험" 운영연결 수치와도 불일치. 진실원천 = Backend RPC/런타임.
- **베타 범위·기한(라이브 공지)**: 무료 첨삭 = **인문논술 중심**, **베타 2026-11-10 23:59 종료**(작성일 기준 5일 뒤). 수리/자연은 킬스위치 종속.

후보 계열(활성 2025+ 테이블 기준, 참고용 — 공개 확정 아님):
| 대학 | 계열(field_or_division) |
|---|---|
| 경희대 | 사회계, 의·약학계, 인문·체육계, 자연계 |
| 성균관대 | 언어 논술/언어형, 수리 논술/수리형 |
| 연세대 | 인문계열, 자연계열(수학) |
| 숙명여대 | 인문계열 |
| 한양대 | 인문계열(+ 카탈로그엔 상경·자연 포함) |

> 지시서가 "현재 대화 확인"으로 든 5곳(한양·중앙·인하·서강·건국) 중 중앙·인하는 위 활성셋에 없고, 서강·건국은 essay-support-status 문서상 **지원상태 미확정(게이트 대기)**. → **공개 목록은 Owner/Codex 확정 필수.**

## 2. 디자인 (Phase 2·4)
- 공통 템플릿 1종. 브랜드: Orange `#FFAC14`, Navy `#1F3A5F`(지시서 지정값), 배경 화이트. 좌측 4px 오렌지 액센트 + 대학 칩 + 헤드라인(≤2줄) + 보조 1줄 + 오렌지 CTA.
- 스킨 충돌 차단: 래퍼 `all:initial`, 전용 네임스페이스 `lseb-*`, 전역 가드 `__lsebInit`. 반응형(≤560px 세로 스택). 접근성(role=complementary, CTA focus-visible, 색만으로 전달 아님).
- 대학별 색 과변경 없음(통일). 로고는 공식 자산·사용가부 확인 후(미확정 시 텍스트 대학명).

## 3. 문구 (Phase 5) — README §2
공통 톤 "내 답안에서 부족한 것은?". 계열별(인문·사회/상경/자연·수리) HEADLINE·SUBCOPY 표준화. **금지**: 상품명/제목에 "AI", 합격 보장·확률, 과장. 미공개 시험은 대학 LAB 홈 연결(오인 방지).

## 4. 연결·GA4 (Phase 6·9)
- 진입 URL `…/essay-lab/`(확인), 대학 상세 `…/essay-lab/universities/{slug}/`(관찰). **딥링크 지원은 Owner 확인 후.** UTM 내장(미발화 환경 백업).
- GA4 신규 이벤트 `lab_banner_impression`/`lab_banner_click`(params: university_id, track, post_id, placement, campaign_id; send_to=G-295EQHYTCK). gtag→dataLayer 폴백. **실수신(Realtime) 검증 전 분석완료 보고 안 함.**

## 5. 미결(Owner/Codex) — 인스턴스화 전 필요
- 공개(available) 대학·계열 **확정 목록**(인증 런타임 기준) + 수리 킬스위치 상태.
- 홍보 대상 게시글 URL↔대학/학년도/계열 매핑, 대학별 LAB URL/딥링크 지원.
- 베타(11-10) 이후 "무료" 문구 정책, 대학 로고 사용 가부.
- 위 확정 후: Claude가 템플릿을 대학별로 치환해 최종 코드 패키지 + PC/모바일 검증 + GA4 실수신 검증.

## 6. 확정 공개 대학 15 (2026-11-05, Owner 로그인 LAB 화면 근거 — 전 대학 "첨삭 시작하기")
정렬 "서비스 가능 대학 우선" 상위 = 첨삭 시작하기 노출 15개. 운영연결 "15개 대학" 수치와 일치. **테이블 `is_active`는 비신뢰**(swu·kau는 false이나 로그인 화면 첨삭 가능) → 라이브 로그인 상태가 진실원천.
산출물: [`essay-lab-banners-package.html`](../assets/marketing/essay-lab-banner/essay-lab-banners-package.html) — 대학별 블록 15개(복사·붙여넣기용). LAB URL = `…/essay-lab/universities/{slug}/`.

| 대학 | slug | 대학 LAB URL | 상태 |
|---|---|---|---|
| 한양대학교 | hanyang | /essay-lab/universities/hanyang/ | 첨삭 시작하기 |
| 고려대학교 | korea | …/korea/ | 첨삭 시작하기 |
| 성균관대학교 | sungkyunkwan | …/sungkyunkwan/ | 첨삭 시작하기 |
| 서강대학교 | sogang | …/sogang/ | 첨삭 시작하기 |
| 중앙대학교 | chungang | …/chungang/ | 첨삭 시작하기 |
| 경희대학교 | kyunghee | …/kyunghee/ | 첨삭 시작하기 |
| 건국대학교 | konkuk | …/konkuk/ | 첨삭 시작하기 |
| 인하대학교 | inha | …/inha/ | 첨삭 시작하기 |
| 동국대학교 | dongguk | …/dongguk/ | 첨삭 시작하기 |
| 숭실대학교 | soongsil | …/soongsil/ | 첨삭 시작하기 |
| 광운대학교 | kwangwoon | …/kwangwoon/ | 첨삭 시작하기 |
| 한국외국어대학교 | hufs | …/hufs/ | 첨삭 시작하기 |
| 숙명여자대학교 | sookmyung | …/sookmyung/ | 첨삭 시작하기 |
| 서울여자대학교 | swu | …/swu/ | 첨삭 시작하기(table inactive) |
| 한국항공대학교 | kau | …/kau/ | 첨삭 시작하기(table inactive) |

> 미확인: LAB 목록 3~4페이지(미열람)에 "첨삭 시작하기"가 더 있는지 → 있으면 Owner 확인 후 동일 방식 추가. 딥링크(대학·시험 선택) 지원 여부 → 미지원 시 base `/essay-lab/`로. GA4 `lab_banner_impression/click` 실수신은 운영 적용 후 Realtime 검증 필요.
