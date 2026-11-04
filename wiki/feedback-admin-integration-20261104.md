# 사용자 문의·피드백 관리자 연결 조사 — 2026-11-04

## 2026-11-04 Owner 승인 후 구현 결과

**코드 구현·격리 TEST 완료, 운영 DB/Edge/WEB/APP 배포 미적용.** 실제 사용자 답변/메일 발송0.
Owner는 원인 조사를 인정하고 두 원본을 유지하는 통합 구현을 승인했다. 운영 적용은 별도 승인이다.

### 통합 목록·답변·보존

- 기존 WEB `/admin/inquiries` UI에서 APP/WEB 출처, 유형, 회원(비회원 구분), 접수일, 상태, 답변 수를 표시한다. 검색·상태/유형/출처 필터와 전체 통합 정렬·페이지네이션을 구현했다.
- 기존 `feedback_submissions`와 `inquiries`를 UNION 조회한다. APP 원본 상태/내용을 덮어쓰지 않고 private 상태 projection을 사용한다. 원본 ID와 회원 연결은 그대로다.
- 기존 `inquiry_replies`/알림/상태이력에 APP 원본 FK를 추가하고 WEB/APP 중 하나만 참조하도록 제약한다. 가짜 WEB 문의 생성과 데이터 이관은 없다.
- APP/WEB 상세·답변·상태 변경을 source+ID로 연결한다. 기존 WEB RPC는 보존한다. 잠금과 요청 키로 동시/재시도 중복을 방지하며 같은 키의 다른 본문은 거절한다.
- 기존 admin_operator 권한, 회원 소유권, 기존 account_service_allowed 검사 재사용. Auth/Credit/Ledger/결제 구현 변경은 없다.

### 회원 확인·알림·관리자 집계

- APP: MY → 문의·건의사항 → 내 문의·답변 → 상세. 설치된 기존 앱에 제공하려면 Native 릴리스가 필요하다.
- WEB: 기존 `/support` 경로에 본인 문의 작성·내역·답변 상세를 연결했다. 로그아웃/계정 전환 시 이전 회원 화면을 제거한다.
- 기존 이메일 outbox와 `process-feedback-notifications`/Resend 어댑터를 확장한다. 답변 저장과 발송은 분리하며 실패 재시도·lease fencing·provider idempotency를 적용한다. 비회원은 식별 가능한 수신자가 없으면 발송하지 않는다.
- 운영에는 사용자 알림센터 서버가 배포되어 있지 않다. 이번 범위는 기존 이메일 + 회원 문의 내역이며 새로운 푸시/알림센터 백엔드는 만들지 않았다.
- 대시보드·사이드바 미처리 배지를 통합 집계한다. 30초/포커스/답변 처리 후 갱신하며 답변 작성 중에는 목록 자동 갱신을 멈춘다.

### 실제 문의 읽기전용 재확인

Owner 제공 ID `65f48fbf-c386-4491-aef0-b697b6952356`의 원본은 기능 제안/2026-11-02 10:29:51 KST/상태 new로 존재한다. 운영 읽기전용 UNION으로 APP 출처·기존 제목·통합 전체3을 확인했다. WEB 복제0/기존 답변0. 신규 RPC와 새 관리자 UI는 미배포이므로 **운영 새 화면 표시 검증은 승인 후 남아 있다.** 실제 문의에 답변/상태 변경을 하지 않았다.

### TEST 결과와 한계

| 검증 | 결과 |
|---|---|
| 로컬 PostgreSQL17 실제 migration 업그레이드 | 7 PASS: 기존 원본·답변·outbox·이력 행 hash 보존 |
| SQL 권한/접수/상세/답변/집계/큐/동시성 | 34 PASS: APP+WEB, 회원/관리자/anon/service_role, 중복/충돌/만료 권한 포함 |
| WEB 영향 테스트 | 58 PASS + 실제 로컬 PostgreSQL UI 연결 1 PASS |
| WEB 타입/변경파일 lint/production webpack build | PASS (160 pages) |
| Native 영향 테스트/분석 | 31 PASS / feedback analyze PASS |
| Edge 기존 intake+답변 adapter | 8 PASS, 실제 이메일 전송 없음 |

로컬 컴포넌트→실제 PostgreSQL 연동은 APP/WEB 답변과 회원 조회를 검증했다. 실제 Supabase HTTP JWT gateway, 실기기, 실제 메일함 수신 E2E는 미실행이다. TEST claim은 합성 값이며 실제 운영 관리자 JWT를 위조해 조회하지 않았다. Node20 경고와 /tmp node_modules symlink의 Turbopack 제약으로 공식 webpack 빌드를 사용했다.

### 적용 패키지·변경 파일·검수

[배포/롤백 순서](../supabase/verification/support_integration/README.md), [정확한 SQL](../supabase/migrations/20261104002306_unified_support_inquiries.sql), [읽기전용 사전 검사](../supabase/verification/support_integration/preflight.sql), [사후 검사](../supabase/verification/support_integration/postflight.sql), [WEB 패치](../supabase/verification/support_integration/web.patch).

APP 변경: `lib/features/feedback/presentation/{feedback_page,feedback_history}.dart`, `test/support_history_test.dart`, 위 migration, `supabase/functions/process-feedback-notifications/{index,support_replies,support_replies_test}.ts`, `supabase/verification/support_integration/*` 및 Wiki.
WEB 변경: `src/lib/admin/{client,contract,format}.ts`, `src/components/admin/{admin-inquiries-view,admin-dashboard-view,admin-surface}.tsx`, `src/components/support-inquiries.tsx`, `src/app/support/page.tsx`, `src/components/admin/{support-integration,support-postgres}.test.tsx` (정확한 경로는 패치 참조).
WEB commit `82a4aea6a0f604bfef5c5a853921d361ac8e9b02` (base `ce86e5c47144aae5f9adff9f6ab4fad4148d38db`). 전용 clone의 commit을 패치로 이 저장소에 보존하여 동시 WEB 작업에 선택 적용할 수 있다. APP SHA는 완료 보고의 commit을 따른다.

Owner 검수: 격리 TEST에서 두 출처 접수 → 관리자 필터/상세 → 답변 → 회원 내역 → 미처리 감소 → 재시도 중복0 순서로 확인한다. 운영은 승인 후 SQL → 기존 Edge worker → WEB 순으로 적용하고 실제 대상은 목록/상세만 읽는다. Native는 APP58과 통합 검토 및 실기기 QA 후 별도 릴리스한다. 실제 메일 E2E는 통제된 TEST 계정으로만 수행한다.

Wiki handoff: task routing/current-status budget/본 작업 링크는 검증한다. 격리 checkout에서 기존 TASK16 문서의 저장소 밖 상대링크20개 오류는 기존과 동일하며 전체 checker PASS로 보고하지 않는다.

## 최초 읽기전용 조사 기록

최초 조사 상태(아래 구현 승인 이전): 원인 조사 완료 / 복구 구현·운영 적용 미실행. 운영 DB 쓰기0, 배포0, 메일 발송0, 실제 문의 복제0.
Owner는 먼저 읽기 전용 원인 보고를 요청했다. 운영 변경은 별도 승인 대상이다.
전용 브랜치 `codex/feedback-admin-audit-20261104`, APP 조사 기준 `8a1498359bbcd0899f8321e5589028d40440b632`.
기존 작업 디렉터리의 미커밋 APP58·수리·상경 작업은 이동하거나 수정하지 않았다.

## 확인한 운영 증거

LegendStudy 프로젝트 `stlhijzpjfgwwdgunlsd`만 조회했다. 2026-11-04 KST 조회 시점 기준:

- 대상 Feedback ID는 채팅 완료 보고에 제공. 제목·시각·ID를 운영 DB와 Owner가 열어 둔 Gmail에서 대조했다. 사용자 본문·회원 UUID는 Git에 복제하지 않는다.
- 접수: 2026-11-02 **10:29:51.278816 KST**, `suggestion`, iOS, 회원 연결 있음, 상태 `new`.
- 이메일 outbox: 같은 feedback에 1행, `sent`, 시도1, 오류없음, 발송시각 **10:30:05.153210 KST**.
- 운영 function log: 10:30:05.170 KST에 같은 ID의 `notification_sent`, attempt1 확인.
- 실제 Gmail: `[LegendStudy] 새 문의 — 기능 제안`, 발신 feedback@legendstudy.com, 10:30 수신. 본문 접수시각·Feedback ID가 DB와 일치.
- 운영 웹 `https://lab.legendstudy.com/admin/inquiries/`: 로그인된 관리자 화면에서 검색어 없음/상태 전체, **전체0·미처리0** 확인.
- `feedback_submissions` 전체3/미처리3, `feedback_notifications` sent3. `inquiries`0, `inquiry_replies`0, `inquiry_status_events`0. 다른 문의 본문은 읽지 않았다.
- 배포된 `process-feedback-notifications` v39 코드와 활성 cron `legendstudy_feedback_notification_worker` (`* * * * *`) 확인.

## 접수·발송·조회 경로와 원인

APP `lib/features/feedback/data/supabase_feedback_repository.dart`는 PostgREST로
`feedback_submissions`에 직접 INSERT한다. 별도 이메일 전용 접수 API가 아니다.
DB trigger `enqueue_feedback_notification`은 같은 transaction에서 outbox를 생성한다.
따라서 outbox enqueue 실패는 접수 transaction 실패지만, 나중에 발생한 이메일 발송 실패는 접수를 취소하지 않는다.
Cron → Edge worker → claim RPC → feedback ID로 원문 조회 → Resend → complete/fail RPC 순서다.
Flutter는 메일 발송을 기다리지 않는다. 기존 이메일 경로는 유지해야 한다.

Native 관리자 Inbox는 `is_feedback_admin()` 검사 후 `feedback_submissions`를 직접 조회하고 상태만 변경한다.
반면 WEB 관리자는 `admin_inquiry_list` → **public.inquiries만 조회**한다.
운영 DB의 함수 정의를 직접 읽어 목록/상세/답변/집계 모두 별도 inquiry 모델만 사용하는 것을 확인했다.

- `admin_inquiry_list`: inquiries만 count/list, RECEIVED/IN_PROGRESS만 open 집계.
- `admin_inquiry_detail`: inquiries에 ID 없으면 INQUIRY_NOT_FOUND.
- `admin_support_metrics`: inquiries만 집계. 앱 feedback은 대시보드에도 누락.
- `admin_inquiry_reply`: inquiry_replies FK가 inquiries.id를 요구. reply+notification+ANSWERED+status event는 transaction 처리, request_key 멱등성 존재.
- `inquiry_mine`: inquiries만 조회. 단순 관리자 목록 UNION만으로 사용자 답변 경로가 완성되지 않는다.

즉 **두 문의 저장 모델 간 통합 누락**이다. 해당 건은 저장 실패·메일 전용 접수·검색 필터 문제가 아니다.
현재 RPC는 feedback 테이블 자체를 참조하지 않으므로 RLS 완화나 관리자 권한 확대는 해결책이 아니다.
두 관리자 권한은 같은 admin_users를 사용하지만 WEB admin_operator는 유효 authenticated JWT 문맥도 검사한다.
운영 UI 접근은 성공했다. 일반회원/타회원의 실제 JWT 보안 재검증은 이번에 수행하지 않았다.

WEB 비교 소스: `legendstudy-service-lab-20261022/src/lib/admin/client.ts` 및
최근 WEB 작업 checkout `legendstudy-toss-test-task17` HEAD `ce86e5c47144aae5f9adff9f6ab4fad4148d38db`의 같은 RPC 호출.
이는 소스 조사 SHA이며 운영 배포 SHA를 증명하지 않는다. 실제 운영 판정은 DB 함수 정의와 화면을 기준으로 했다.

## 기존 시스템 재사용과 수정 범위

권고는 원본2개를 유지하는 통합 projection이다. 기존 feedback을 inquiries에 임의 복제하거나 기존 ID/접수시각을 재생성하지 않는다.

1. 관리자 전용 조회 RPC에서 source+source_id로 두 원본을 통합한다. 동일 정렬/페이지/검색을 전체 집합에 적용한다.
2. 유형은 inquiry/bug/suggestion/other 원값을 보존하고 기존 WEB 세부분류와 출처를 별도로 표현한다. suggestion을 other로 소실시키지 않는다.
3. 원상태를 보존하며 표현만 new→접수, reviewing→처리중, resolved→종결로 매핑한다. resolved를 답변완료로 간주하지 않는다. 답변 여부는 실제 reply 존재로 결정한다.
4. 기존 WEB inquiry 답변·status event·outbox·멱등성 경로는 보존한다. feedback용 답변 연결은 기존 FK가 허용하지 않으므로 별도 migration 설계가 필요하다. 대상 원본을 명시하는 관계/제약을 검증하고 기존 답변의 FK를 무조건 제거하지 않는다.
5. 회원 식별은 기존 auth user 연결을 사용하고 guest/null은 명시 표시한다. 게스트에게 수집하지 않은 이메일을 추정하거나 전송하지 않는다.
6. 미처리 집계·대시보드·사이드바 배지·신규표시·상세 이동은 같은 통합 집합을 쓴다. 오류를 0건으로 표시하지 않는다.
7. 기존 관리자 접수 이메일은 그대로 유지. 답변 알림 worker의 실제 배포와 사용자 조회/알림 연결은 추가 확인 대상이다. Supabase Edge 목록/cron에는 문의 답변 전용 worker가 확인되지 않았으나 외부 worker 부재까지 단정하지 않는다.

### 보존 검토 일곱 질문

1. 발생/기록/정정: 원접수 created_at와 답변/처리 event 시각을 분리한다.
2. 원본 재현: 원본 ID·유형·제목·본문·접수 메타데이터를 이동/덮어쓰지 않는다.
3. UPDATE 이력: 현재상태 projection과 상태 이벤트를 분리하고 기존 이벤트 보존. Native 기존 status-only 경로의 이력 공백도 후속 설계에 명시한다.
4. 동일 identity: 기존 user_id만 사용, 새 회원 매핑/추정 병합 없음.
5. Learning/Decision/Outcome: 고객지원 운영기록이며 성적·학습결과나 입시 사실로 전용하지 않는다.
6. 목적/권한/retention: 기존 관리자 범위와 guest 경계 유지. 본문/회원 식별은 필요한 운영화면에 한정. 기존 탈퇴/보존 정책을 자동 확장하지 않는다.
7. 파생값: 미처리/신규/답변 여부는 원본과 답변에서 계산하며 이메일 sent를 처리완료로 취급하지 않는다.

## 검증 결과 및 미완료

| 항목 | 이번 확인 | 복구 후 필요한 검증 |
|---|---|---|
| A 앱 접수 | 대상 운영 저장행·메일의 iOS 메타데이터 확인 | TEST 신규 제출/중복 탭/네트워크 실패 |
| B DB 저장 | 대상 실제행·원시각·원상태 확인 | TEST rollback/멱등성 |
| C 이메일 | outbox+function log+수신 메일 일치 | TEST provider 실패에도 문의 유지 |
| D 관리자 목록 | 운영0 재현, 누락 원인 확정 | 통합3건/추가문의/페이지/권한 |
| E 유형 | suggestion 보존 확인 | 4유형+기존 WEB분류 필터 |
| F 상세 | 운영 RPC는 inquiries만 조회 | 양쪽 원본·guest 상세/타회원 차단 |
| G 답변 | 기존 RPC/FK 구조 확인, 실제 작성0 | TEST 답변/중복 request_key/원기록 보존 |
| H 사용자 알림 | 관리자 접수 이메일만 PASS | 답변 worker·회원수신·사용자 조회·guest 미발송 |
| I 미처리 | feedback3 vs 웹0 확정 | 대시보드/배지/목록 일치·상태 반영 |
| J 보존 | 이번 읽기 전용, 데이터 변경0 | 적용전후 ID/본문해시/시각/답변/event 비교 |

로컬 기존 오프라인 검사: unittest14 PASS + SQL/worker 계약9 PASS = **23 PASS**.
pytest 실행은 환경에 모듈 없어 실패했고, 동일 파일의 unittest 및 무인자 계약 함수로 실행했다.
이는 통합 복구 TEST/E2E 통과가 아니다. 실기기 신규 접수·답변작성·메일재발송·운영 상태 변경은 수행하지 않았다.

Wiki handoff: 전용 worktree 생성 직후 baseline부터 인접 checkout 상대링크20개가 깨져 전체 checker FAIL.
이번 문서의 내부 링크/라우팅은 별도 검사하고 current-status 12KB 제한을 유지한다.
기존 타작업 링크를 임의로 수정하지 않는다.

## 운영 적용 및 Owner 검수

복구에는 WEB 변경과 통합/답변 연결용 DB migration이 필요하다. **아직 SQL 후보 작성·TEST 구현·운영 적용 승인 요청 단계가 아니다.**
이 보고 이후 전용 브랜치에서 구현 → 격리 TEST → 정확한 migration/사전·사후 SELECT/rollback 패키지 준비 → Owner 운영 승인 순서다.
운영 적용 전 auth/credit/ledger/payment 변경이 없음을 diff로 확인한다.

Owner 검수: 현재는 기존 앱 관리자 Inbox에서 접수건 확인 가능 여부를 확인하되 상태는 유지한다.
복구 TEST에서는 네 유형 접수→목록/상세→답변→회원알림→미처리 감소를 검수한다.
운영 승인 후에는 기존 문의가 새 접수로 복제되지 않고 원래 시각·ID로 표시되는지 먼저 읽기 전용 확인한다.
실제 사용자에게 답변/메일을 보내는 것은 별도 명시적 지시가 있어야 한다.

기존 근거: [접수와 outbox](day-11-b-feedback-production.md), [Native Inbox](day-11-b3-admin-inbox.md),
[이메일 운영](day-11-b4-feedback-email.md), [보존 전략](longitudinal-learning-admissions-data-strategy.md),
[기존 결정](decisions.md). 최신 Owner의 통합조회·원본보존 요청은 이 기존 모델을 계승하며 운영 승인으로 확대하지 않는다.
