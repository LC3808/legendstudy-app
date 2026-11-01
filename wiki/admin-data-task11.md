# TASK 11 — 관리자 메뉴·학습 데이터 통합

Status: implementation / isolated verification in progress; no production deployment.

## Preservation review (seven questions)

1. 발생 시각과 기록 시각을 구분한다. Study interval은 발생 시각, target/bookmark/application은 현재 projection의 created_at, recent_view는 최신 viewed_at이다. 수정 시각을 과거 발생으로 해석하지 않는다.
2. 원본 row/Package/run을 변경하지 않고 읽기 전용 파생 집계를 반환한다. 과거 삭제/변경 이력을 복원했다고 주장하지 않는다.
3. 신규 UPDATE/삭제 없음. target 변경 추이와 저장 취소 이력은 현재 projection만으로 재구성하지 않는다.
4. 기존 auth.users/profiles UUID를 유지하고 별도 학생 identity/warehouse를 만들지 않는다.
5. 공부/저장은 Learning, 희망 대학은 Decision, 실제 지원은 별도 자기보고 Decision이다. 합격/등록 Outcome으로 변환하지 않는다.
6. 기존 admin_operator + account_private.allowed를 적용한다. 탈퇴/비활성 계정 제외. 일반 집계에 이메일/답안/성적 상세 없음. 5명 미만 숨김은 내부 후보 guard이며 차분 공격/기간 조합 재식별을 완전히 방지하지 않는다. 운영 공개 전 목적/보존/통계 공개 정책 검토 필요.
7. 파생 집계는 원본 사실을 대체하지 않는다. 조회 시각·기간·출처·현재 projection 제한을 표시한다.

## Reuse / source evidence

TEST `kpqbedylxlyntrrfybpn` read-only catalog confirmed: profiles, bookmarks, recent_views, student_target_universities, student_applications, study_sessions. Existing `admin_student360` uses `student_private.study_summary`, applications and essay_summary; academic_performance is null. Existing study_summary unions active_segments per learner. New candidate uses the same overlap-union definition over a bounded requested period.

Existing Analytics v1, feedback, beta, notices, operations, Owner review and member/Student360 components reused. 31 events / 14 attributes unchanged. No new telemetry collection or education fact table.

## Candidate

`supabase/candidates/admin_learning_task11/install.sql`: read-only admin RPC, no source mutation, 8s statement timeout, max 400-day window, top 10 with >=5 unique users. Current projection semantics documented in WEB `learningDefinitions`.

`local_test.sql`: EMPTY local database only. Tests auth denial, anonymous/service-role execution denial, invalid dates, EMPTY, distinct learners, overlapping sessions, clipping, suppression, grant rollback and original profiles preserved. Do not run fixture against shared TEST or production.

Rollback: revoke authenticated execute using rollback.sql; keep source facts untouched. WEB revert task commits / redeploy previous private preview. No production apply authorized.

## Known gaps (not complete)

- GA4 legacy property 396674471; LAB measurement ID/Firebase/Data API credentials and real reception remain NOT_TESTED/NOT_CONFIGURED. Two property users are never summed as unique users.
- Score distributions, grade stratification, admissions outcomes and target change history require source/permission contracts. No inferred academic facts.
- Insight DRAFT is a preview only; persistent approval/audit and automatic delivery are NOT_IMPLEMENTED/OFF.
- TEST lacks several legacy admin Analytics/operations RPCs. Existing error taxonomy must distinguish NOT_INSTALLED from EMPTY.
- Provider evaluation, live payment, production Credit, deployment and store submission not executed.

Related: [Longitudinal strategy](longitudinal-learning-admissions-data-strategy.md), [TASK10](admin-integrated-analytics-task10.md), [Student foundation](my-shared-foundation.md).

## 2026-11-01 verification / handoff

Final recommendation: **PARTIAL / HOLD**. Menu wiring and bounded read-only learning aggregation are reviewable; this is not completion of all TASK11 analytics requirements.

### Implementation inventory

| Feature | State | Evidence |
|---|---|---|
| Existing admin / beta / notices / feedback | IMPLEMENTED_CONNECTED | Existing components/routes retained under grouped navigation; existing TEST RPCs reused |
| Analytics v1 reports | PARTIAL | Existing UI/contract reused; TEST reporting RPCs absent |
| Study Timer / Saved / targets / applications | IMPLEMENTED_CONNECTED | New read-only aggregate candidate over existing sources; remote TEST returns EMPTY |
| Member / Student 360 | IMPLEMENTED_CONNECTED | Existing member/detail component and RPC; Owner 200, student 403, anon 401 |
| Academic score distributions | NOT_IMPLEMENTED | Current Student360 academic_performance null; no student score source in inspected TEST public schema |
| Admissions outcomes | PARTIAL | Self-reported application counts available; no inferred acceptance/enrollment |
| Insight preview | PARTIAL | DRAFT text only from thresholded stored-material rows; persistent approval/audit not implemented |
| GA4 / Firebase reporting | BLOCKED | No confirmed LAB measurement ID / read credentials / native receiver setup |
| Owner answer review / quality | PARTIAL | Existing links and separate permission preserved; private TEST route/prod-only transport not widened |

### URLs / routing

Private Preview: https://task11.legendstudy-task09.pages.dev/admin/

Existing URLs retained: `/admin/`, `/admin/members/`, `/admin/credit/`, `/admin/payment/`, `/admin/operations/`, `/admin/inquiries/`, `/ql/`, `/admin/materials/`, `/admin/analytics/`, `/admin/beta/`, `/admin/beta/usage/`, `/admin/beta/failures/`, `/admin/essay-feedback/`, `/admin/notices/`.

New focused/reused screens under `/admin/data/<section>/`:
`overview`, `visitors`, `conversion`, `installs`, `learning`, `universities`, `materials-data`, `study`, `scores`, `applications`, `students`, `insights`, `essay-usage`, `samples`, `satisfaction`, `verification`.

Menu registry WEB `src/lib/admin/navigation.ts` is the complete 30-entry inventory. Six groups, active route, old paths preserved. Existing reports are reused with focus selection, not a second reporting engine. Dashboard shortcuts remain available even when the legacy dashboard RPC is missing.

### Checks

- Flutter analyze: 0 issues; full tests **1306 PASS / 7 SKIP**. No APP source changes or new native build.
- WEB full tests **1517 PASS / 4 SKIP**; after final presentation changes, admin regression **155 PASS**, TS/build pass; lint 0 errors / 5 existing warnings.
- Analytics contract **31 event names / 14 parameters match**.
- Isolated PG17 `task11_learning_c`: authorization, period bounds, distinct students, overlapping interval union, interval clipping, >=5 suppression, revoke rollback passed. No source write in reporting function.
- Shared TEST only: installed `admin_learning_analytics_task11`. Owner RPC 200 EMPTY; student 403; anonymous 401. Existing Student360 same role results. Production schema unchanged.
- Chrome verified private gate rendering; authenticated PC/mobile rendering, menu click/back/refresh interactions are **NOT_TESTED**. Static export/HTTP deep links are distinct evidence, not browser E2E.
- Actual GA4/Firebase reception, Provider evaluation, OCR, real payment, native device flows **NOT_TESTED**. No claim of full regression E2E.

### Access / owner checklist

Use existing private access code at local `~/.codex/legendstudy-task09-test/preview-access-key.txt`, then synthetic TEST credentials `test-accounts.json` in the same folder. Do not paste credentials into Git/Wiki. Real production account credentials do not apply to this separate TEST project.

1. Open Preview; unlock private gate; login TEST owner.
2. Check six menu groups, direct routes, back/reload and mobile width.
3. Learning reports should show EMPTY on the current TEST source, not fabricated rankings. Score route explicitly NOT_IMPLEMENTED.
4. Member detail reuses Student360. Anonymous/student must not see admin data.
5. Check beta, notice, feedback and operations. Missing RPC must display connection-needed state.
6. Existing APP build33 remains unchanged; no new APP build/install required for WEB navigation. APP device regression not performed here.

### Operational boundary / rollback

Only shared TEST received one read-only RPC and private TEST project received a separate branch Preview/access secret. TEST main config was compared unchanged. No production DB/Worker/Provider/Credit/payment/WEB/APP/store changes; no evaluation execution.

Before any production approval: review aggregate privacy (small cohort differencing), existing SQL package dependencies, production schema precheck, statement budget and performance; resolve missing RPCs and score/insight contracts. `rollback.sql` revokes RPC access without deleting facts. Revert WEB commit for menu rollback. Preview alias can be redeployed from prior artifact; production was never replaced.

HTTP handoff verified: five unauthenticated private routes/assets/API paths returned 401; private access form returned 200 with TEST banner; all 16 new deep links returned 200; no-store header confirmed. This does not substitute for authenticated browser layout/click/back tests. WEB source commit `4b963ae418f72c7f8b81bb91db5f4cbaff071e41`; both task branches pushed and local/remote equality confirmed.

## TASK11-F final integration — 2026-11-01

이 절은 위 TASK11 초기 미검증 상태를 갱신한다. **PARTIAL / HOLD**: 코드·TEST 조회 연결과 브라우저 검증 완료 범위를 아래에 명시하며, 운영 가능 또는 출시 준비 완료로 판정하지 않는다.

### 기준·수정·Preview

- APP 시작 `4782a8b`, WEB 시작 `4b963ae`; 두 저장소 `codex/admin-data-task11-20261101`. 미커밋 변경 없음에서 시작. 기존 APP/Analytics 계약 보존.
- WEB `1d520984c3b6cc88d1884cef7e9b8680a36609c6`: Student360을 legacy member-detail 성공 조건에서 분리. 기존 서버 권한은 각각 유지. 모바일 beta usage 표가 grid 최소폭을 확장하던 문제를 `minmax(0,1fr)`로 수정.
- TEST Preview: https://task11.legendstudy-task09.pages.dev/admin/ ; immutable deployment https://4cd1e45b.legendstudy-task09.pages.dev . 운영 도메인 미배포.
- 기존 private access code 및 `~/.codex/legendstudy-task09-test/test-accounts.json`의 별도 TEST owner/student 재사용. 비밀정보 Git 미포함.

### 메뉴별 실제 브라우저 결과

Chrome PC / 390×844: 6개 그룹·30개 링크 확인. 일반 관리자 페이지 28개는 메뉴 클릭→정확한 URL→조회 완료/오류 상태까지 확인. 별도 검수 2개는 권한 거절 화면 확인. 일반 사용자 및 비로그인 직접 URL 차단 **각 30/30**. 차단 성공과 관리자 기능 성공을 혼동하지 않는다. 모든 행의 UI는 TESTED이며, 데이터 연결 상태는 별도 열이다. HTTP 200만으로 PASS 처리하지 않았다.

| 메뉴 | 실제 경로 | UI/권한 | 데이터·기능 상태 |
|---|---|---|---|
| 대시보드 | `/admin/` | TESTED / 학생·비로그인 차단 | BLOCKED: legacy admin_dashboard 미설치. additive release report 연결 |
| 회원 | `/admin/members/` | TESTED / 학생·비로그인 차단 | CONNECTED: 3명 목록·Student360. legacy 회원 상세 BLOCKED |
| 크레딧 | `/admin/credit/` | TESTED / 학생·비로그인 차단 | PARTIAL: release 집계 연결, legacy 상세 RPC 미설치 |
| 결제 | `/admin/payment/` | TESTED / 학생·비로그인 차단 | PARTIAL: release 집계 연결, orders/mobile report 미설치 |
| 1:1 문의 | `/admin/inquiries/` | TESTED / 학생·비로그인 차단 | BLOCKED: 문의 RPC 미설치 |
| 첨삭 품질 | `/ql/` | TESTED / 학생·비로그인 차단 | BLOCKED: Quality 전용 권한 없음 (정상 차단) |
| 논술 자료 검수 | `/admin/materials/` | TESTED / 학생·비로그인 차단 | BLOCKED: 자료 검수 전용 권한 없음 (정상 차단) |
| 통합 분석 대시보드 | `/admin/data/overview/` | TESTED / 학생·비로그인 차단 | CONNECTED: 원장 집계. GA4 NOT_CONFIGURED |
| 방문자·유입 분석 | `/admin/data/visitors/` | TESTED / 학생·비로그인 차단 | BLOCKED: GA4 보고서 읽기/수집 미연결 |
| 사용자 행동 분석 | `/admin/analytics/` | TESTED / 학생·비로그인 차단 | CONNECTED: 기존 Analytics 원장 RPC, GA4 별도 대기 |
| 가입·전환 분석 | `/admin/data/conversion/` | TESTED / 학생·비로그인 차단 | CONNECTED: 저장된 서버 단계. 방문→가입 연결 NOT_TESTED |
| 앱 설치 유입 분석 | `/admin/data/installs/` | TESTED / 학생·비로그인 차단 | NOT_AVAILABLE: 실제 설치 연동 없음 |
| 학습·입시 종합 현황 | `/admin/data/learning/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 실제 원장 0행 |
| 대학 선호도 분석 | `/admin/data/universities/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 희망 대학 0행 |
| 인기 시험·학습자료 분석 | `/admin/data/materials-data/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 저장·최근 열람 0행 |
| 공부 시간 분석 | `/admin/data/study/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 학습 시간 0행 |
| 성적·학습 분석 | `/admin/data/scores/` | TESTED / 학생·비로그인 차단 | NOT_IMPLEMENTED: 상태 안내만 구현 |
| 입시 지원 분석 | `/admin/data/applications/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 실제 지원 0행, 희망 대학과 분리 |
| 학생 통합 분석 (Student 360) | `/admin/data/students/` | TESTED / 학생·비로그인 차단 | CONNECTED: 회원 선택→학습·지원 기록; legacy 상세만 BLOCKED |
| 개인화 인사이트 관리 | `/admin/data/insights/` | TESTED / 학생·비로그인 차단 | PARTIAL: 집계·DRAFT 미리보기, 승인 저장 미구현 |
| 논술 LAB 이용 현황 | `/admin/data/essay-usage/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 평가 원장 0행 |
| 사용자 답안 샘플 검수 | `/admin/data/samples/` | TESTED / 학생·비로그인 차단 | IMPLEMENTED: 기존 검수 링크. 실답안 열람 BLOCKED |
| 만족도·피드백 분석 | `/admin/data/satisfaction/` | TESTED / 학생·비로그인 차단 | CONNECTED: 기존 피드백. 1~5점 v2 미활성 |
| 평가·비용 모니터링 | `/admin/operations/` | TESTED / 학생·비로그인 차단 | CONNECTED: 5개 탭 실조회, 평가 표본 EMPTY·비용 UNKNOWN |
| 베타 테스트 관리 | `/admin/beta/` | TESTED / 학생·비로그인 차단 | CONNECTED: 캠페인 없음. 설정 변경 NOT_TESTED |
| 베타 이용 현황 | `/admin/beta/usage/` | TESTED / 학생·비로그인 차단 | CONNECTED: 3명 이용 현황·0회, 모바일 수정 재검증 |
| 베타 검증 결과 | `/admin/data/verification/` | TESTED / 학생·비로그인 차단 | NOT_TESTED: 인수 상태 안내 |
| 피드백·오류 신고 | `/admin/essay-feedback/` | TESTED / 학생·비로그인 차단 | CONNECTED: 기존 접수 조회; 처리 변경 NOT_TESTED |
| 공지사항 관리 | `/admin/notices/` | TESTED / 학생·비로그인 차단 | CONNECTED: 기존 공지 조회; 작성·게시 NOT_TESTED |
| 평가 실패·복구 내역 | `/admin/beta/failures/` | TESTED / 학생·비로그인 차단 | CONNECTED / EMPTY: 실패·복구 기록 없음 |

새로고침·뒤로가기는 beta usage→Analytics→back에서 재조회·세션 유지 확인. 390px 전수 검사 중 beta usage document 폭 1025px 결함 발견, 수정 Preview에서 390px=scrollWidth 재검증. 다른 일반 관리자 27개 페이지는 외부 가로 넘침 없음. PC 실제 화면도 확인. Safari·실기기 APP·모든 메뉴별 back/reload 조합은 NOT_TESTED.

### 기존 SQL/RPC 재사용 및 TEST 적용

TEST project `kpqbedylxlyntrrfybpn`만 변경. 기존 소스 SQL을 그대로 적용, 중복 RPC/평가 엔진 미개발.

| TEST migration | 기존 패키지 | 범위 |
|---|---|---|
| `20261101110956 task11f_existing_operations_reporting` | `supabase/candidates/essay_operations_v1/install.sql` | private 보고 view·비용/경고 보조 저장소 및 관리자 RPC |
| `20261101111021 task11f_existing_analytics_reporting` | `supabase/candidates/analytics_admin_reporting_20261030/apply.sql` | 기존 집계 view·7개 보고 RPC, precheck 통과 |
| `20261101111146 task11f_existing_release_reporting` | `supabase/candidates/admin_release_reporting/install.sql` | additive read `admin_release_report` |

운영 모니터링 조회는 기존 설계상 admin access audit를 기록한다. 비용 추정 실행·경고 실행·beta 설정·공지 쓰기·피드백 변경 버튼은 누르지 않았다. 임계값은 미설정, 자동 Worker 없음.

16개 read RPC × Owner/student/anonymous = **48 권한·응답 검사 PASS**. Analytics 7개, admin_learning_analytics, admin_essay_operations, admin_essay_beta_config/report, admin_essay_feedback, notice_admin_list, admin_member_list, admin_student360, admin_release_report. Owner 200; student/anon 401 또는 403. `admin_release_report`는 기존 계약상 student도 401; 403만 강제하지 않음.

미설치 legacy: admin_dashboard, admin_member_detail, admin_member_credit, admin_credit_member_list, admin_payment_orders, admin_mobile_purchase_report, admin_support_metrics, admin_inquiry_list/detail, admin_learning_summary 및 기존 단일 평가 운영 일부. 기존 후보/스냅샷을 조사했으며, 일부 함수는 baseline.private.json에만 있고 별도 설치 Migration이 없음. Credit mutation 함수가 섞인 전체 baseline을 설치하지 않았다. release 집계가 연결되어도 이 의존성 누락을 숨기지 않는다. 후속: 기존 원본 read migration을 회수해 의존성 검증 후 TEST에 적용.

### 실제 데이터와 격리 집계 검증

TEST student_target_universities/bookmarks/recent_views/study_sessions/student_applications 모두 0행. 따라서 학습 EMPTY는 API 실패가 아닌 실제 source 부재. 희망과 실제 지원을 합산하지 않음. 시험 단위 runs와 legacy evaluations도 각 0행. 만족도는 기존 feedback 원장; 1~5점 후보 SQL/flag 미적용. 비용은 실제 영수증 없는 UNKNOWN이며 0달러로 대체하지 않음.

격리 PG17 `task11f_learning`에서 기존 local_test.sql 실행: EMPTY, 기간 검증, admin/anon/service role 권한, 고유 학생/등록 건수 구분, 타이머 중복 union·기간 clipping, 최소 표본5 미만 suppression, 접근 revoke rollback PASS. 공유 TEST에 합성 학습·평가 기록 삽입하지 않음.

격리 UTF8 DB `task08_task11f_utf`에서 기존 TASK08 통합 harness **45 PASS**: SQL 의존성/rollback/reinstall, 베타 경계·동시성, 비용 ACTUAL/ESTIMATED/UNKNOWN, TEST/LIVE·USD/KRW 분리, 취소·환불·예약 해제 구분, run/ledger 보존. 첫 시도 Python psycopg 부재와 SQL_ASCII DB로 실패한 환경 오류는 전용 venv/새 UTF8 DB로 해결했고 제품 결함으로 분류하지 않음.

### TEST Credit 불변 검증 예외 — 숨기지 않음

브라우저 일반 TEST 학생의 최초 로그인(2026-11-01 20:17:04 KST)에서 기존 AuthProvider→ensureOwnerProfile→profiles INSERT→essay_signup_credit trigger가 signup_bonus_v1 **+3 Credit**을 자동 기록했다. 직접 지급/차감 RPC를 실행한 것은 아니지만, 이번 검수 전후 TEST 원장 불변 조건은 **FAIL**이다. 기존 정책/트리거를 변경하지 않았고 지급 기록도 삭제·회수하지 않았다.

- 전: credit_transactions 3행 digest `72f52995f8aec3018c0dd8065748a64a`.
- 후: 4행 digest `f68a1abae309ec383afe8e4e1122e43f`.
- 새 row `914e247d-b1af-46f1-9fd1-35d474ee3420`, reason signup_bonus_v1, actor system/signup_bonus.
- runs/evaluations는 각각 0행 및 `d41d8cd98f00b204e9800998ecf8427e` 유지.
- 운영 DB/Credit에 접근·변경 없음. 후속 read-only 로그인 검수는 기존 profile과 가입 지급 완료 여부를 먼저 확인해야 한다. 새 profile bootstrap이 필요한 계정은 사용하지 않는다.

### 자동 검증·미검증

- Flutter analyze **0 issues**, 전체 **1306 PASS / 7 SKIP**. APP 코드·빌드 번호 변경 없음.
- WEB 전체 **1519 PASS / 4 SKIP** (Student360 실패 격리 2개 신규 회귀 포함), TS PASS, production build PASS, lint **0 errors / 5 기존 warnings**.
- 두 수정은 새 TEST Preview에서 실제 재검증. 브라우저 화면과 비관리자 차단은 자동 unit 결과와 별도 근거.
- GA4/Firebase 설정·실수신·Data API 권한: NOT_TESTED/BLOCKED. 기존 31 event/14 property 계약 변경 없음. 연결 없이 0 방문자로 표시하지 않음.
- 실제 평가/Provider/OCR/결제/IAP/실기기 APP·품질검수 샘플은 NOT_TESTED. 자동 테스트가 실제 평가 품질 PASS를 의미하지 않음.

### 베타 필수와 후속 고도화 / 빌드 준비

베타 필수: Owner 품질·자료 검수 권한 확인, TEST 평가 표본·Gateway/E2E, legacy 운영 read RPC 복구, Credit 부작용 없는 검수 계정 사전 점검. 이 항목 해소 전 통합 운영 준비는 HOLD.

후속 고도화: 성적 분석, 지속 인사이트 승인/게시, GA4/Firebase 실수신·방문 전환 연결, 만족도 v2. 현재 미구현/미연결 안내 유지, 가상 통계 없음.

WEB 빌드는 성공했고 private TEST 검수 가능. APP analyze/test 통과·기존 build33 보존; 새 signed build/스토어 제출은 수행하지 않음. 최종 APP/WEB 출시 빌드 준비 완료로 판정하지 않음.

### 롤백·운영 영향

WEB 수정은 해당 커밋 revert 또는 이전 private Preview `013a8264`로 복귀 가능. 각 기존 SQL 패키지 rollback.sql로 보고 접근 회수/함수 제거; source facts 보존. operations rollback은 감사/비용 보조자료 보존 여부를 원문 확인 후 실행. 이번에는 실제 TEST rollback 미실행(격리 DB 검증만 수행). 자동 가입 지급은 기록 보존하며 무단 회수하지 않음.

운영 DB/Worker/Provider/Credit/결제/WEB/APP/스토어 변경 없음. 공유 TEST report schema와 private branch Preview만 변경. canonical 상태는 이 문서와 current-status/log에 기록한다.

## TASK11-G production integration — 2026-11-01

### 최종 범위와 상태

Owner TASK11-G §16 승인 범위에서 관리자 Pages와 검증된 read-only 보고 RPC만 운영 반영. **PARTIAL / 관리자 배포 완료**이며 전체 베타 출시 완료가 아니다. 실제 운영 진입점은 https://lab.legendstudy.com/admin/ . TASK11-F TEST 결과와 아래 PRODUCTION 결과를 혼동하지 않는다. TASK12 홈페이지는 HOLD 유지.

- WEB source: `9f29bb8f0fa2d69e83dadb8d47e457be206b1545`, branch `codex/admin-production-task11g`.
- APP 기준 source `910cd9a3bdea9a6391a1f681fd0e59f8be7c8b0b`; Native 코드·버전·build 미변경. 이 브랜치에는 SQL 후보 및 Wiki만 추가.
- 원래 운영 배포 `f9e0e83f-6f93-470d-a1e0-0c711607c53c`, source `2f838c29fa25c38c399a6a43f9d567dd89053ffc` 보존.
- 실제 배포 ID와 검증 시각은 아래 최종 배포 증적 참조. 초기 배포 후 발견한 legacy 응답/긴 메뉴 결함을 수정해 최종 재배포했다.

### 보호된 배포 방식

`legendstudy-lab/scripts/deployment/admin-preserved.mjs`는 기존 운영 asset manifest를 기준으로 `/admin/*` HTML/RSC와 신규 content-hashed 자산만 overlay한다. 기존 non-admin 페이지 및 공유 자산 hash 불변을 검사하고 충돌/현재 배포 변경 시 중단한다. 기존 Pages Functions 20개 원문 보존 + 이미 검토된 Owner read-only API 1개 연결. 기존 배포 설정·service binding·redirect 보존. Owner 전용 정적 검수 페이지 3개 추가, private/no-store/noindex 적용. 학생 결과/결제/로그인 코드를 최신 개발본으로 일괄 교체하지 않았다.

백업(비공개, credential 출력/commit 금지): `/Users/woojinchang/.codex/legendstudy-backups/task11g/`, 후속 `task11g-fix/`, `task11g-nav/`. 각 project/files/plan/manifest/compiled functions 및 배포 응답 보존. 기존 rollback asset/source는 `web-safe-preview-20261031/`에 보존.

### 운영 RPC — additive read-only

운영 project `stlhijzpjfgwwdgunlsd`, migration `admin_analytics_readonly_task11g` 적용 성공. TEST는 `kpqbedylxlyntrrfybpn`과 명확히 구분.

1. [읽기 전용 운영 집계](../supabase/candidates/admin_production_task11g/operations_readonly.sql): TASK06 기존 run/call projection 재사용. 신규 테이블/비용 추정 저장/경고 실행/감사 쓰기 제외. `read_only=true`; 해당 WEB 버튼 비활성.
2. 기존 [Analytics reporting](../supabase/candidates/analytics_admin_reporting_20261030/apply.sql): 시험 회차/legacy 분리, LIVE KRW 매출·환불/예약 해제 구분, USD 비용 UNKNOWN 보존.
3. 기존 [학습 집계](../supabase/candidates/admin_learning_task11/install.sql): 최소 cohort5·학습시간 중복 union 및 기간 clipping.

합본 SHA256 `c2b246a1048f3919b73e77b1ddd9f8cbf9eaf66a751980d7b008f60af341a4ac`. 9개 보고 RPC + 기존 형식의 관리자 check helper; private view5개. 기존 3인자 운영 RPC overload 보존. 기존 admin_operator/account gate, UUID/RLS/원장 정책 미변경. STABLE SECURITY DEFINER, empty search_path, authenticated만 execute; 실제 관리자 판정은 서버 내부. private schema 직접 접근 불허.

운영 [사후 검증](../supabase/candidates/admin_production_task11g/verify_readonly.sql): Owner 보고9개 READ ONLY transaction 실행 PASS, 일반 사용자9개 거부 PASS, anonymous/service role execute 없음, 기존 overload 보존, 비용/감사 쓰기 저장소 미생성. 검증 claims는 transaction local+rollback, 계정·권한을 변경하지 않음. 보안 advisor 전후 동일 5개 경고 분류; 기존 Auth leaked-password/pg_net/catalog anon 경고는 별도 기존 항목. 신규 authenticated definer는 위 gate/ACL로 별도 검증.

### 운영 메뉴 30개 검증표

공통: IMPLEMENTED는 화면 구현, TESTED는 실제 운영 Chrome 렌더링/조회, CONNECTED는 실제 원장 RPC 응답. 미설치 RPC를 EMPTY 또는0으로 표시하지 않는다. 일반 사용자 권한은 운영 SQL role 검사와 자동 테스트, 비로그인은 실제 별도 브라우저 차단으로 검증. 일반 사용자 운영 브라우저 로그인은 NOT_TESTED(신규가입 Credit 부작용 방지). 모든 쓰기 버튼 조작은 제외.

| 그룹 | 메뉴·실제 경로 | 운영 조회 결과 |
|---|---|---|
| 기본 | 대시보드 `/admin/` | CONNECTED: 회차54/완료43/실패10 및 기존 운영 원장 |
| 기본 | 회원 `/admin/members/` | CONNECTED: 기존 회원 목록 |
| 기본 | 크레딧 `/admin/credit/` | CONNECTED: 기존 목록, 지급/차감 미실행 |
| 기본 | 결제 `/admin/payment/` | CONNECTED: 선택 조건 EMPTY, 결제 미실행 |
| 기본 | 1:1 문의 `/admin/inquiries/` | CONNECTED: EMPTY |
| 기본 | 첨삭 품질 `/ql/` | 기존 독립 콘솔 렌더링/EMPTY; 시험 회차 Owner 검수는 별도 |
| 기본 | 논술 자료 검수 `/admin/materials/` | CONNECTED: 기존349시험/1014문항 검수 목록 |
| 서비스 | 통합 분석 `/admin/data/overview/` | CONNECTED: 서버 학습·평가·매출; GA 별도 미연결 |
| 서비스 | 방문자·유입 `/admin/data/visitors/` | NOT_CONFIGURED: GA 읽기/수집 미연결 |
| 서비스 | 사용자 행동 `/admin/analytics/` | CONNECTED: 기존 서버 보고; GA 실수신 NOT_TESTED |
| 서비스 | 가입·전환 `/admin/data/conversion/` | CONNECTED: 가입 코호트, 익명 방문 연결 불가 명시 |
| 서비스 | 앱 설치 유입 `/admin/data/installs/` | NOT_AVAILABLE: 설치 완료 미측정 |
| 학습 | 종합 현황 `/admin/data/learning/` | CONNECTED: cohort<5 SUPPRESSED,0으로 대체 안 함 |
| 학습 | 대학 선호도 `/admin/data/universities/` | CONNECTED: SUPPRESSED |
| 학습 | 시험·자료 `/admin/data/materials-data/` | CONNECTED: SUPPRESSED, 저장≠열람 |
| 학습 | 공부 시간 `/admin/data/study/` | CONNECTED: SUPPRESSED |
| 학습 | 성적 `/admin/data/scores/` | NOT_IMPLEMENTED 안내, 가상 분포 없음 |
| 학습 | 실제 지원 `/admin/data/applications/` | CONNECTED: SUPPRESSED, 희망 대학과 분리 |
| 학습 | Student 360 `/admin/data/students/` | CONNECTED: 기존 회원 목록·선택 상세/첨삭 회차/학습 조회, 쓰기 미실행 |
| 학습 | 인사이트 `/admin/data/insights/` | PARTIAL: DRAFT preview, 승인 영속 저장/자동 노출 없음 |
| LAB | 이용 현황 `/admin/data/essay-usage/` | CONNECTED: 선택7일 대학10행, 실회차·문항 집계 정의 표시 |
| LAB | 답안 샘플 `/admin/data/samples/` | 기존 Owner 검수 연결·저장된 성균관대 결과/이전 회차 표시 |
| LAB | 만족도 `/admin/data/satisfaction/` | NOT_CONNECTED: 피드백 RPC 미설치 |
| LAB | 평가·비용 `/admin/operations/` | CONNECTED:5개 탭 실제 조회, 비용UNKNOWN 명시 |
| 베타 | 설정 `/admin/beta/` | NOT_CONNECTED: admin beta RPC 미설치 |
| 베타 | 이용 `/admin/beta/usage/` | NOT_CONNECTED: admin beta RPC 미설치 |
| 베타 | 검증 결과 `/admin/data/verification/` | NOT_TESTED 인수 상태 안내 |
| 베타 | 피드백 `/admin/essay-feedback/` | NOT_CONNECTED: 조회 후 RPC 미설치 안내 |
| 베타 | 공지 `/admin/notices/` | NOT_CONNECTED: 관리 RPC 미설치 |
| 관련 | 실패·복구 `/admin/beta/failures/` | NOT_CONNECTED: beta report RPC 미설치; 기존 운영 탭 조회 가능 |

미설치 쓰기 패키지는 테이블/쓰기 RPC/정책 설치가 필요하므로 이번 read-only 승인에 포함하지 않았다. 이 상태를 전체 관리자 운영 완료로 판정하지 않는다. 기존 운영 모니터링5탭은 최근30일 요청54/성공43/실패10/예약1·무료재첨삭20을 조회. 토큰/영수증175건에 가격·호출시각이 없어 비용UNKNOWN 유지. 일부 오래된 평가유형도UNKNOWN으로 표시. 재처리32회는 차감28건과 다른 단위.

### 결함 수정·브라우저 회귀

- 기존 단일 평가/수리 목록 RPC는 `last_24h`를 반환하지 않음. WEB이 필수 numeric으로 파싱해 MALFORMED 오류 발생. nullable로 호환, 임의0 생성 없이 기존 목록 복구. 회귀 테스트 추가.
- 6개 그룹을 모두 열면 sticky nav 하단이 viewport 밖으로 고정되어 메뉴 클릭 불가. PC max-height/overflow-y 적용, 모바일 static 구조 유지. 실제 하단 클릭 재검증.
- 기존 로그인 세션으로 운영 관리자 접근. 기존 `/my/essays/` 목록과 관리자 왕복 확인. Owner 검수에서 저장된 성균관대3문항·이전 답안·최초/재첨삭 비교 렌더링. 현재 계정 목록15건에는 서울여대 없음: 그 실기록 품질 검수 NOT_TESTED. 원문/점수 수정·실제 평가 없음.
- Chrome desktop 및 좁은 viewport(실제 innerWidth433) 메뉴 접기/펼치기·화면폭/새로고침/뒤로가기 검증. 390px 요청은 Chrome 창 최소폭 때문에 실제433px이므로390px로 보고하지 않음. Safari/iOS/Android 실기기 NOT_TESTED.

### 자동 검증·잔여 사항

- WEB 전체 **1525 PASS /4 SKIP** (212개 test file PASS/3 SKIP), TypeScript PASS, production build PASS, lint0 errors/기존5 warnings. 마지막 nav CSS 변경은 build 및 실제 브라우저 회귀 추가. APP Native 미변경으로 이번 Flutter 실행 SKIP; TASK11-F 결과를 신규 실행으로 보고하지 않음.
- 격리PG17 TASK08 통합SQL/동시성/베타경계/결제TEST-LIVE·통화·환불/21권한거부/원장 fingerprint/rollback-reinstall PASS. 학습 cohort/타이머 union/clipping/privacy PASS. 신규 readonly operations rate/P95/retry/429redaction/권한/ledger 필터 PASS. TEST schema-only clone 설치 PASS.
- GA4/Firebase 실제 수신·Data API 권한 NOT_TESTED/NOT_CONFIGURED. 성적·인사이트 영속승인·만족도v2·베타 공지 피드백 운영SQL 별도 승인 대기. 실평가/OCR/결제/APP빌드·스토어 검수 없음.
- 기존 원장·History·학생 답안·Worker·Provider·Credit·결제 정책 변경 없음. 승인된 보고 함수/view 및 관리자 Pages 배포만 운영 변경. 기존 원문 결과를 재생성하지 않음.

### 롤백

Cloudflare Pages `legendstudy-lab`에서 원래 production deployment `f9e0e83f-6f93-470d-a1e0-0c711607c53c`로 Rollback. API는 `/accounts/{account}/pages/projects/legendstudy-lab/deployments/{deployment_id}/rollback` POST. 실제 rollback은 실행하지 않았으며 배포/원본 asset 존재 및 복구 자료 확인. 이후 관리자/로그인/기록 읽기 재확인. 보고 RPC 접근 회수는 [rollback.sql](../supabase/candidates/admin_production_task11g/rollback.sql)로 새 함수만 REVOKE; 기존 overload/원장/결과/History 삭제 없음. 운영 데이터 restore 불필요. 후속 승인 없는 쓰기 패키지 적용 금지.

### 최종 배포 증적

- Cloudflare Pages production **9c505258-4a49-468a-83ae-2326173fb870**, source **9f29bb8f0fa2d69e83dadb8d47e457be206b1545**. 실제 운영 URL https://lab.legendstudy.com/admin/ . 배포 permalink https://9c505258.legendstudy-lab.pages.dev (Owner API는 운영 origin만 허용).
- 최종 canonical deployment success 재확인. 원래959개 asset 중 non-admin 변경0, production settings 동일, 기존 rollback deployment 존재 확인. 최종 Cloudflare manifest1120개. 기존 Pages Function20개 보존 검사는 배포 도구에서 강제.
- 최종 CSS 수정 후 30/30 실제 메뉴 클릭→경로→제목 확인. 하단 Student360/공지/실패 메뉴 접근 복구. 모바일433px 하단 메뉴 클릭, document scrollWidth433 일치. Student360 기존 계정 상세 로딩/alert없음 확인.
- 최종 로컬 증적 `/tmp/task11g-menu-final.json`, `/tmp/task11g-admin-desktop.png`, `/tmp/task11g-admin-mobile.png`. 원문 답안/계정정보는 Wiki에 복제하지 않음.
- 운영 보고 연결은 완료, 전체 베타 운영 기능은 **PARTIAL**. 일반 사용자 운영 browser login·Safari·실기기 APP NOT_TESTED. Owner 검수 페이지 현재 계정 범위 내 결과만 조회; 다른 학생 전체 답안 접근 확장은 이번 작업에 없음.
