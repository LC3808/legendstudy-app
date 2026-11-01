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
