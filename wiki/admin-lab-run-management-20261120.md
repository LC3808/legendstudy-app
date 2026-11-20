# WEB 관리자 논술 운영 기간·요청 관리 — 2026-11-20

**PARTIAL — 구현·격리 검증 완료, 운영 DB 설치 승인 대기. WEB/Worker 운영 미배포. 기존 요청 재진행·삭제 0.**

Owner의 이번 지시는 실제 관리자 기능 구현과 WEB 운영 배포를 승인한다. 기존 요청을 실제 재진행·삭제하는 작업은 별도 승인 단계다. AGENTS §4의 Owner DB 적용 원칙 때문에 준비된 새 DB 기능 설치 방식만 확인 중이다. 파일 존재를 운영 설치로 간주하지 않는다.

기존 정책: [데이터 보존 전략](longitudinal-learning-admissions-data-strategy.md), [Worker 중단/기존 finish 복구](essay-worker-incident-20261028.md), [Credit 운영](admin-credit-operations-20261027.md), [Finance 자동 갱신](finance-auth-renewal-20261117.md). WEB 기존 운영 근거는 WEB checkout의 `wiki/operations-integrity-20261115.md`, 기존 숨김 구현 b6d47c5. 기존 숨김 RPC는 운영에 있으나 현재 source에는 UI 연결이 누락되어 재연결했다.

## 구현

- `/admin/`: 기존 AdminPeriodFilter 재사용, 오늘/7일/30일/직접 입력. KST 자정 시작 포함·마지막 날 다음 자정 미포함, 직접 입력 최대93일, 존재하지 않는 날짜 거부.
- `/admin/lab-dashboard/`: 같은 기간 컴포넌트, 기존 전체기간 선택도 보존. 기간 통계와 전체기간 현재상태를 별도 제목·카드로 구분. 직접 입력 미완성/오류여도 현재상태 조회는 유지.
- 기간 KPI: 요청 생성 시점 범위의 요청 수, 해당 요청 중 현재 완료/실패 수. 실패 발생 시각을 지어내지 않는다. 재시도는 `retry_requests.created_at` 사건 발생 시점으로 별도 집계한다. 기존 RPC의 `summary.retries`는 기간 접수 요청의 생애 누적값이므로 사용하지 않는다.
- 현재 KPI: 기존 `admin_essay_operations.live.processing`(reserved), `retry_pending`(reserved 중 문항 실패 기록), 피드백 `new + reviewing`. 전체기간·전체출처·숨김 포함. 각 카드에 범위와 마지막 응답/서버집계 시각 표시. 처리중/재시도대기 중복 가능, 합산·장애 단정 금지.
- 요청 목록: 상세 + 상태확인. 서버 capability 조회 후 재진행·삭제·보관/복원 버튼과 차단 사유를 표시한다. 별도 화면 이동 불필요. 확인창은 대학·시험·ID·상태·테스트 판정·이용권 상태/수량·원장 수·decision ID 포함.
- 기존 숨김/표시 목록 RPC를 재사용한다. 보관은 처리 취소·KPI 제외가 아니며 학생 답안/결과를 보존한다. 성공 후 목록과 선택 상세를 갱신하고 대시보드 갱신 이벤트를 발행한다.

## 서버 경계

[Owner 설치 패키지](../supabase/candidates/admin_run_management_20261120/README.md): [설치](../supabase/candidates/admin_run_management_20261120/install.sql), [사후검사](../supabase/candidates/admin_run_management_20261120/postcheck.sql), [권한 닫기 복구](../supabase/candidates/admin_run_management_20261120/rollback.sql).

- `admin_lab_run_capabilities` / `admin_lab_manage_run` / `admin_lab_operation_stats`는 기존 `essay_ops_private.require_admin()`을 호출한다. Auth uid + 기존 admin_operator + account allowed 그대로 사용. authenticated만 실행 권한, anon/service_role/essay_worker/public 거부.
- account → run → billing 잠금 순서. 유효한 run/retry lease는 재진행 거부. 최신 문항 checkpoint가 모두 completed/failed이고 실패 문항이 존재하며, run/billing reserved인 경우에만 기존 `essay_exam_retry` 호출.
- 최종 완료/최종 실패(이미 정산·복구 포함), pending/불확정 checkpoint, final checkpoint, 누락된 lease token 등은 차단하고 이유 표시. 불확정 실행을 나이만 보고 중단으로 단정하거나 pending checkpoint를 탈취하지 않는다. **확정 종료된 failed 요청을 새 유료 요청으로 만드는 기능은 미구현/미승인**.
- 기존 snapshot/완료 checkpoint/decision/credit_transactions를 수정하지 않는다. retry generation만 append. 동일 action UUID는 idempotent; 다른 concurrent retry는 새 lease/최신 checkpoint 검증으로 거부. 구세대·완료 후 action 재생은 거부.
- WEB `/api/admin/essay-run` → Worker `/admin-exam-retry` adapter. 두 경계 모두 원래 관리자 JWT로 capability/mutation RPC 검증. client가 subject를 전달할 수 없다. DB가 반환한 실제 owner만 기존 queue identity로 전달. Worker는 기존 admission/consumer/lease/checkpoint 검증을 그대로 사용한다. 새 평가 엔진 없음.
- 큐 응답 불확정 시 UI는 성공 처리하지 않고 같은 작업 키를 유지한다. 새 예약/자동 환불 없음. Worker admission 실패 시 retry 기록도 만들지 않는다.
- 삭제는 별도 `verified_test_runs`에 Owner가 검증 근거를 등록한 요청만 가능. email/review/beta를 테스트 근거로 쓰지 않는다. 운영 설치 시 등록0. 원장·유료/예약/정산·완료·활성lease·연결회차·평가/코칭/피드백/pending 기록은 삭제 거부. 새 미검토 FK가 생겨도 삭제 거부. 삭제해도 billing decision·원장은 보존한다.
- 성공 작업은 `run_actions`에 actor/run/action/action_id/time/outcome append. 일반 역할의 직접 테이블 접근과 update/delete 금지. 과거 hidden_runs projection은 현재상태일 뿐 과거 감사를 backfill하지 않는다.

## 실제 중단 요청 — 운영 읽기 검증

| 항목 | 확인값 |
|---|---|
| 요청 | `e7af7e52-eba9-46c3-aba4-0961ea516b48` |
| 시험 | 한양대학교 2027학년도 모의논술 상경계열 (`68996278-1e19-5560-ac94-cf43656bf684`) |
| 생성 | 2026-10-26 12:39:51 KST |
| 현재 상태 | reserved, completed_at 없음 |
| 실행 lease 만료 | 2026-10-26 12:54:54 KST |
| 재시도 | generation1, 2026-10-26 12:43:20 KST, lease 만료12:58:20 |
| 문항 checkpoint | q0 completed, q1 failed, q1-retry-1 failed, final 없음 |
| Worker 기록 | generation·independent_review receipt2건; called_at 미기록. 최종 상태변경 timestamp도 별도 필드가 없어 확인 불가 |
| 이용권 | decision `49746a12-e69c-4cd1-a511-137fab1ecb70`, reserved1개 |
| 원장 | reserve1건 `ff1a6cd6-fe62-424d-ad9e-7662089b7a8a`, balance_delta0 / reserved_delta+1; consume/release0 |
| 두 KPI | 동일 요청이 processing와 retry_pending 양쪽에 포함 |
| 테스트 여부 | 검증 근거 없음. 원장 연결 요청으로 보호. review 프로필 여부는 삭제 근거가 아님 |

10/26 과거 요청이고 lease가 만료됐으며 최신 문항 실패가 확정되어 재진행 검토 대상이다. 실제 재진행·보관·삭제는 하지 않았다. Owner가 승인하더라도 이 요청의 영구 삭제는 서버 보호 기준상 허용하지 않는다. 보관 또는 기존 실패 문항 재시도가 가능한 경로다.

## Seven preservation answers

1. 생성/완료/재시도/관리 작업 발생 시각을 구분. 없는 마지막 상태변경 시각은 생성시각으로 대체하지 않는다.
2. 원본 snapshot, checkpoint, billing decision, ledger 보존. 삭제 가능한 검증 테스트의 원문 복원은 불가능하므로 확인창에 명시; 감사 metadata는 남긴다.
3. 숨김은 기존 current projection UPDATE, 새 관리 작업은 append audit. retry append. 원장 UPDATE/DELETE 없음.
4. 기존 credit_accounts.user_id를 조회하여 실제 auth identity를 유지. 관리자 JWT를 학생 identity로 바꾸지 않는다.
5. 첨삭 원본은 Learning, 관리자 동작은 운영 Decision. 입시 Outcome이나 결제 성공으로 해석하지 않는다.
6. 기존 관리자 권한에 한정, 공개 집계/신규 개인정보 수집 없음. 감사에 답안·credential 저장하지 않는다. verified evidence는 최소 검증 출처만 기록. 기존 retention/삭제 정책 확대 없음.
7. KPI는 조회시 재계산, `as_of`와 원자료 기간 정의 표시. 종료 실패 발생시각·마지막 열람·장애 여부를 추정하지 않는다.

## 검증 및 배포

- DONE: 로컬 PostgreSQL 격리 SQL 설치·권한·상태·삭제·감사·원장 보존·KPI 검증, concurrent2개→generation1/audit1/다른요청 ACTIVE_LEASE.
- DONE: WEB 최종전체 2,184 PASS /5 SKIP, 신규 API/route/UI11 PASS. typecheck·변경파일 ESLint·운영값 Next build·Pages Functions compile PASS.
- DONE: Python adapter+기존 async retry/queue/stage/math checkpoint21 PASS. Worker stage PASS.
- NOT TESTED: 실제 Production 관리자 mutation/Provider 재실행, 실제 학생 데이터 변경, 실제 결제/환불. 실행하지 않음.
- PARTIAL: 운영 DB 새 패키지 NOT_APPLIED. 기존 DB read와 대상 식별만 완료. Owner 설치 방식 확인 대기.
- PARTIAL: WEB/Worker 새 버전 NOT_DEPLOYED. 기능 의존 DB 미설치 상태의 불완전 UI를 운영에 덮어쓰지 않는다.
- 준비 기준 Pages: `969afe59-8bf4-4940-b0a9-d32b2ac9a9ba`, source `d559b9b58ef6b419b500e3f7a5333b65d9849230`. 현재 Finance Automatic/Toss LIVE 설정 보존 대상. 새 공개 경로는 `/api/admin/essay-run` 하나.
- 운영 Worker는 로컬보다 최신 prompt/모듈을 포함한다. 전체 재빌드 교체 금지. 현재74모듈 중 entry의 관리자 어댑터만 패치하고 helper1개 추가하는 방식으로 나머지 모듈을 바이트 보존한다. [패치 준비 도구](../tool/cloudflare_essay/admin_run_patch.py)는 기존 fetch 메서드 drift 시 중단한다.

## 재개 순서

1. Owner가 새 DB 기능만 설치하도록 Codex 승인 또는 직접 install/postcheck 결과 전달.
2. 읽기로 설치/ACL/기존 요청·원장 불변 검증.
3. 현재 운영 모듈 보존 Worker adapter + WEB 관리자 경로 한정 배포, 기존 학생 자산·Finance/Toss 설정 전후 대조.
4. 실제 관리자 UI에서 기간4종/상태확인/disabled 사유/확인창을 검증. 기존 요청 mutation은 Owner 별도 승인 전 금지.
5. 별도 승인된 합성 데이터가 없다면 운영 삭제/재진행 E2E는 NOT TESTED로 남기고 격리 검증과 구분.
