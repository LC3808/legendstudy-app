# 논술 LAB 첨삭 지원상태 불일치 검토 & 지원상태 UX 명세 (§8 / §11 / §D) — 2026-11-01, Claude

역할: Claude = 분석·UX 명세·검증 설계. 실제 Registry/Backend 판정·DB·운영 배포는 Codex/Owner. **새 상태 필드·테이블 추가 금지**(기존 Backend/Registry 계약 우선). 이 문서는 "지원 확정"을 내리지 않는다 — **검증 게이트**를 통과해야 상태를 바꾼다.

## A. 서강대 2026 수시 인문(경제경영) — WEB=지원 / APP=미지원 (§8)

### A-1. 실측 사실 (2026-11-01)
- **WEB(`lab.legendstudy.com`)**: `/essay-lab/universities/sogang/` 의 **등록 계열**에 다음이 노출됨(런타임 실측):
  `인문계열 · 1회차`, `자연계열 · 9회차`, **`인문계열(경제경영) · 11회차`**, `인문계열(인문사회) · 11회차`.
  학년도·시험 목록에 **`2026학년도 수시논술`** 존재. 공식 출처 링크 = `https://admission.sogang.ac.kr/enter/html/rolling/data.asp`.
  즉 WEB은 **경제경영을 "인문계열" 트랙으로, 11회차의 평가 데이터와 함께 등록**해 두었다.
- **APP(Flutter)**: `lib/features/essay/university_catalog.dart`에 sogang은 `sourceUniversityId:"sogang"`, `universityId:"816c1cb8-…"`로 **대학 단위 등록**은 되어 있으나, 트랙(계열) 단위 노출은 서버 Registry 조회 결과에 의존한다. Owner 보고상 APP은 **경제경영·상경 계열을 미지원으로 표시**.

### A-2. 유형 판정 (계열명으로 수리논술 단정 금지)
- 서강대 인문논술(경제경영 포함)은 **제시문 기반 서술형 논술**이다. "경제경영"이라는 **명칭** 때문에 수리논술로 오판하면 안 된다(지시서 §8 명시 제약). 실제 서강대 경제경영 문항은 **인문논술 엔진 적용 대상**이다.
- WEB이 이미 **인문계열(경제경영) 11회차**를 보유 → 해당 트랙에 대한 **평가 실행 이력/자료가 존재한다는 강한 정황**. (단 "11회차"가 실제 완료 평가인지, 자료 등록 회차인지는 A-4에서 확인.)

### A-3. 불일치 원인 가설 (확인 필요, 택1 또는 복합)
1. **APP 카탈로그/Registry 조회 범위 차이**: APP이 읽는 서버 뷰/필터가 경제경영·상경 트랙을 제외(스테일 필터 또는 `servicePreparingUniversityIds`와 무관한 트랙 레벨 숨김). ※ `service_availability.dart`의 `servicePreparingUniversityIds`에 sogang은 **없음** → 대학 단위로는 "준비중"이 아님. 따라서 미지원은 **트랙 레벨 필터** 문제일 가능성이 높다.
2. **계열 명칭 하드코딩 제외**: APP 측에서 "경제경영/상경"을 수리/미지원으로 간주하는 레거시 분기.
3. **문항 유형 메타 차이**: 같은 트랙이 WEB은 humanities로, APP은 미분류/수리로 매핑.

### A-4. 해소 경로 (단일 진실원천 = Backend Registry)
1. **진실원천 고정**: 트랙별 지원 여부는 **Backend/Registry**가 유일 기준(새 필드 추가 없이). WEB·APP 모두 동일 Registry 조회 결과를 렌더해야 한다.
2. **검증 게이트(지원 확정 전 필수, §8 제약)**: 서강대 2026 수시 경제경영 실제 문항 1건으로 **인문논술 엔진이 유효한 평가 결과를 산출**하는지 확인(기준 매핑·채점 산출). WEB의 "11회차"가 실제 완료 평가(run)인지 SELECT로 확인.
3. **정합**: 게이트 PASS면 APP의 트랙 레벨 숨김/필터를 제거해 WEB과 동일하게 노출. 게이트 FAIL/미확인이면 **COMING_SOON**(아래 B)으로 **양 플랫폼 통일**(WEB의 "지원"을 내리거나 APP의 미지원을 올리는 임의 결정 금지 — Registry 기준으로 한쪽으로 통일).
4. **상경 계열**: 서강대 모집단위 명칭상 "상경"이 경제경영과 동일 인문논술 트랙에 매핑되는지 Registry에서 확인. 다른 트랙이면 별도 등록 여부·회차 확인.

### A-5. Owner 승인 필요
- 경제경영/상경 트랙을 "지원"으로 확정하려면 A-4의 검증 게이트 결과 + Registry 반영을 Owner가 승인해야 한다. **Claude는 지원 확정을 하지 않는다.**

## B. 건국대 2026 수시 통합논술(수학) — WEB 버튼 미표시 + '준비 중' 불명확 (§11)

### B-1. 실측 사실 (2026-11-01)
- **WEB**: `/essay-lab/universities/konkuk/` 등록 계열 = `인문·2회차`, `자연·5회차`, **`통합·2회차`**, `인문사회Ⅰ·6`, `인문사회Ⅱ·6`, `자유전공·2`, `자연 A·1`, `자연 B·1`. 학년도에 `2026학년도 수시논술` 존재.
- 건국대 **통합논술은 수학(수리) 문항 포함**. 수리 채점은 인문논술 엔진이 아닌 **수리/Math 평가 엔진(MATH-2E)** 소관.
- **Backend 킬스위치 존재**: 마이그레이션 `20261008001000_essay_web_runtime_status.sql`의 `public.essay_web_runtime_status()`가 `math_evaluations_enabled`(boolean)를 반환하는 **수리 평가 런타임 킬스위치**다. `wiki/current-status`(essay 브랜치)상 MATH-2E는 "installed, live Web activation **unverified**". 베타 정책상 **"승인된 인문/non-math scope만" 무료 첨삭 사용 가능**.
- 결론: 건국 통합(수학)은 **수리 평가가 런타임 OFF/미검증**이라 WEB에서 첨삭 버튼이 숨겨지거나 '준비 중' 처리되는데, 그 **상태·문구가 불명확**한 것이 §11의 문제다.

### B-2. 핵심 원칙
- **상태는 기존 Backend에서**: 수리 지원 여부 = `essay_web_runtime_status().math_evaluations_enabled`. **새 상태 필드/테이블 금지.** 인문 트랙 지원 여부 = Registry 등록 + 엔진 적용 가능.
- **버튼을 숨기지 말 것**: '준비 중'을 빈 화면/사라진 버튼으로 두지 않고 **명시적 상태 칩 + 안내 문구 + 대체 행동(공식 자료 확인)**을 제공(APP `lab_coming_soon_page.dart`가 이미 이 철학: "never a dead disabled card"). WEB도 동일 적용.

## C. 지원상태 UX 명세 — 4-state (AVAILABLE / COMING_SOON / UNAVAILABLE / ERROR)

APP·WEB 공통 상태 모델. **기존 Backend 값에 매핑만 하고 새 필드를 만들지 않는다.**

### C-1. 상태 → Backend 매핑 (단일 진실원천)
| 상태 | 판정 근거(기존 계약) | 의미 |
|---|---|---|
| **AVAILABLE** | 해당 대학·계열·학년도 트랙이 Registry에 등록 + (수리 트랙이면 `math_evaluations_enabled=true`) + 엔진 적용 가능 | 첨삭 접수 가능 |
| **COMING_SOON** | 트랙은 존재하나 평가 비활성: 수리 트랙 & `math_evaluations_enabled=false`, 또는 `servicePreparingUniversityIds` 포함 대학, 또는 Registry "준비" 표식 | 준비 중(곧 제공) |
| **UNAVAILABLE** | 해당 학년도/계열에 등록 트랙·자료 없음 | 미제공(자료 없음) |
| **ERROR** | 상태 조회 API 실패/타임아웃 | 일시적 오류 |

> ERROR 상태는 실존한다: 2026-11-01 `/essay-lab/` 대학 목록의 상태 배지가 전 대학 **"일시적으로 확인할 수 없습니다 · 다시 시도"**(= ERROR fallback)로 표시됨. 즉 WEB에 이미 ERROR copy가 있다.

### C-2. 문구·위치·CTA (양 플랫폼 공통 — 과장/오인 금지)
| 상태 | 배지(칩) | 보조 문구 | 1차 CTA | 비고 |
|---|---|---|---|---|
| AVAILABLE | `첨삭 지원` (브랜드 소프트 배경/오렌지 잉크) | — | **`{대학} 논술 첨삭받기 →`** (오렌지 채움) | 로그인 시 크레딧 표시 |
| COMING_SOON | `준비 중` (중립 배경/보조색) | 수리 트랙: `수리논술 채점은 준비 중이에요.` / 대학 단위: `해당 대학 첨삭은 준비 중이에요.` | **`{대학} 공식 자료 확인하기 →`** (아웃라인) | 공식 출처 링크(officialSourceUrl)로 연결. 죽은 버튼 금지 |
| UNAVAILABLE | `자료 준비 중` (중립) | `이 학년도·계열은 아직 등록된 자료가 없어요.` | `다른 학년도·계열 보기` | 빈 상태를 정직히 표기 |
| ERROR | `확인 불가` (경고 톤) | `일시적으로 확인할 수 없습니다.` | **`다시 시도`** | 색만으로 전달 금지(텍스트 라벨 필수) |

위치: 대학 목록 카드의 좌하단(대학명 아래 1줄), 대학 상세의 계열 선택 영역 상단. APP은 기존 `LabStatusBadge`(이용 가능/준비 중, 텍스트가 상태를 전달 — color-only 금지)와 `lab_coming_soon_page.dart` 패턴을 재사용. WEB은 동일 4-state를 컴포넌트화.

### C-3. 상태별 규칙
- **색만으로 상태 전달 금지**(접근성): 모든 배지는 텍스트 라벨을 가진다(기존 `LabStatusBadge.label` 철학 유지).
- **COMING_SOON ≠ 빈 화면/숨김 버튼**: 반드시 안내 + 공식 자료 CTA 제공(§11 "'준비 중' 안내 불명확" 해소).
- **AVAILABLE 확정은 검증 게이트 통과 후에만**: 미확인 평가 가능 트랙을 AVAILABLE로 올리지 않는다(서강 경제경영은 A-4 게이트 전까지 현행 Registry 값 유지).
- **수리 트랙**은 항상 `math_evaluations_enabled`를 함께 확인해 AVAILABLE↔COMING_SOON 전환(건국 통합 포함).

## D. APP·WEB 통일 명세 (요약)
1. 트랙별 지원상태는 **동일 Registry/Backend 조회 결과**를 렌더(WEB·APP 공통). APP의 트랙 레벨 임의 필터 제거.
2. 수리 트랙은 `essay_web_runtime_status().math_evaluations_enabled` 반영.
3. 4-state 컴포넌트를 WEB에 신설(APP은 기존 `LabStatusBadge`/coming-soon 패턴 재사용·문구 정합).
4. 서강 경제경영/상경: A-4 검증 게이트 → PASS 시 양쪽 AVAILABLE, 미확인 시 양쪽 COMING_SOON. **한쪽만 노출/숨김 금지.**
5. 건국 통합(수학): 수리 활성 전까지 양쪽 COMING_SOON + 공식 자료 CTA.

## E. 검증 기준 (acceptance)
- [ ] 같은 대학·계열·학년도에 대해 WEB·APP 상태가 **동일**(스크린샷 대조).
- [ ] 서강 경제경영: 인문논술 엔진 실제 평가 1건 산출 확인 결과를 근거로 상태 결정(게이트 로그 기록).
- [ ] 건국 통합(수학): `math_evaluations_enabled=false`에서 COMING_SOON + 안내 + 공식 자료 CTA 노출(버튼 사라짐 아님).
- [ ] 4-state 모두 텍스트 라벨 존재(색만으로 전달 아님), ERROR에서 재시도 동작.
- [ ] 새 상태 컬럼/테이블이 추가되지 않았음(마이그레이션 diff 0).

## F. Owner 승인 필요 / 미확인
- 서강 경제경영·상경 "지원" 확정(A-4 게이트 결과 승인).
- 수리 평가 런타임 활성화 시점(건국 통합 AVAILABLE 전환) — Owner/운영.
- WEB 대학 목록 상태 배지 ERROR fallback의 원인(상태 API 장애/인증 필요 여부)은 운영 확인 필요(2026-11-01 전 대학 ERROR 관찰).
- "11회차" 등 회차 수가 실제 완료 평가인지 자료 등록 수인지 Backend SELECT로 확인(Claude 미실행).
