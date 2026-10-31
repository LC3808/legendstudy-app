# TASK05 — 논술 LAB 사용자 피드백·오류 신고

2026-10-31 Owner TASK05 구현. 기존 [피드백 원장](day-11-account-personal-feedback.md), [관리자 Inbox](day-11-b3-admin-inbox.md), [이메일 outbox](day-11-b4-feedback-email.md), [Owner 검수](web-safe-owner-preview-20261031.md)를 확장한다. [베타 운영](admin-beta-operations.md)과 평가·과금 계약은 그대로다.

## 보존 검토 7문항

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md) 적용:
1. 사용자 발생 시각 occurred_at, 서버 접수 recorded_at, 처리 변경 recorded_at을 분리한다.
2. 사용자 의견 원문은 기존 feedback_submissions에 한 번 저장한다. 별도 콘텐츠 원장을 만들지 않는다.
3. 상태는 current projection이며 변경 전후·관리자 메모를 append-only actions에 보존한다. 기존 APP 관리자 경로의 상태 변경도 trigger로 기록한다.
4. auth.users.id가 identity다. context 사용자 FK는 계정 삭제 시 NULL 처리하며 과거 평가를 새 사용자에게 연결하지 않는다.
5. Learning의 자기보고 피드백으로 분류한다. Decision/Outcome이나 성적 확정값이 아니다. 의견은 사용자 판단/신고 사실이고, 실제 평가 오류 확정·평가 점수·성적 사실이 아니다.
6. 답안·민감정보·Provider 원문을 자동 첨부하지 않는다. 본문은 사용자 자발 입력, 관리자 메모는 private다. 기존 피드백 보존/삭제 정책을 따른다. 운영 승인 시 기존 outbox 전송과 개인정보 보존 정책도 함께 확인한다.
7. 긍정/부정 비율과 유형별 수는 해당 기간의 파생 집계다. 평가 원장으로 역기록하지 않는다.

## 재사용과 구현

- 기존 feedback_submissions: title/body/user/platform/version/status의 단일 소스. category는 기존 bug/suggestion을 사용한다.
- private essay_context: satisfaction과 세부 category 분리, request key/hash, canonical evaluation_ref(`runUUID/questionUUID`), run/question/exam/university ID, 오류 코드·발생 시각.
- private actions: 상태 전후·메모·변경자·시각. 일반 사용자 및 anon 직접 접근 불가.
- APP `lib/features/feedback/essay_feedback.dart`: result 하단, LAB, 기존 MY 고객지원 FeedbackPage. 만족도만 제출 가능, 오류는 유형+설명 필수, 추가 의견 선택. 비로그인에는 로그인 안내. 제출 실패 시 입력 유지, 결과 조회 독립.
- WEB `src/components/essay-feedback.tsx`: 기존 결과 문항 탭 하단, LAB 홈, /support/. 공유 Owner 렌더러에 제출 폼을 넣지 않는다.
- WEB `src/components/admin/admin-essay-feedback.tsx`, `/admin/essay-feedback/`: 공식 AdminSurface를 사용. 유형/세부유형/기간(KST)/사용자/상태 필터, 25건 페이지, 상세·상태·메모·감사 이력.
- 통계: 전체, 만족도 응답 중 긍정/부정 비율, 오류, 유형별, new+reviewing 미처리, resolved 해결 완료. closed는 해결 완료로 집계하지 않는다.
- `essay_feedback_mine`: 본인 제출 이력 25건 조회. 기존 APP 문의 내역도 기존 원장을 그대로 조회한다.
- 관리자 결과 링크는 `/owner-review/essay/?feedback=<feedback_id>`로 기존 화면 재사용. 기존 caller token+admin_operator 서버 검증을 거친 뒤 해당 신고 문항과 동일 소유자의 parent만 읽는다. 임의 user/run 지정은 허용하지 않는다.

## SQL 승인 후보

패키지: `supabase/candidates/essay_feedback_v1/` (운영 미적용).
- precheck → install(한 번만) → postcheck. rollback은 실제 문제 발생 시만 실행.
- RPC: essay_feedback_submit, essay_feedback_mine, admin_essay_feedback, admin_essay_feedback_update, admin_essay_feedback_result.
- SECURITY DEFINER + empty search_path. authenticated만 EXECUTE; anon/service_role/PUBLIC 차단. 일반 사용자 제출/본인 조회, 관리자 공식 admin_operator+active account gate.
- 기존 직접 피드백 insert 및 일반 고객지원 권한은 보존한다. 새 LAB 기능은 로그인 필수다.
- 사용자별 advisory transaction lock, request key unique, payload hash 일치 시 기존 ID 반환, 변경된 payload 충돌. 시간당 새로운 접수 최대10건; 같은 요청 재전송은 한도 소비하지 않는다.
- 관리 상태 변경은 updated_at CAS. 메모와 상태 변화는 각각 독립 감사 행으로 저장된다.
- 기존 enqueue_feedback_notification trigger 유지. 운영 활성화 후 기존 이메일 알림 경로에도 접수될 수 있다. 이번 테스트는 로컬이며 메일/Provider 전송 없음.

## 활성화/롤백

APP `ESSAY_FEEDBACK_V1_ENABLED=true`, WEB `NEXT_PUBLIC_ESSAY_FEEDBACK_V1_ENABLED=true`; 기본 false. SQL 적용·권한 검증 승인 후 검수 빌드/배포에서만 설정한다. WEB 버전 식별은 `NEXT_PUBLIC_RELEASE_VERSION` (미설정이면 unknown), APP은 기존 네이티브 appVersionProvider의 실제 version/build를 재사용한다(조회 불가 시 unknown).
Owner review 별도 bundle은 기존 `scripts/owner-review/build.mjs` 절차로 재생성해야 한다. 이번에는 소스와 build 가능성을 검증하며 운영 정적 bundle을 교체하지 않는다.
롤백: 먼저 기능 플래그 끄고 이전 APP/WEB artifact 복귀 → 필요시 rollback.sql로 새 RPC 실행 권한 회수. 접수·메모·감사 이력과 기존 평가/과금은 삭제하지 않는다.

## 검증 결과

- APP Analyze: 0 issues. 전체 Flutter Test: **1,306 PASS / 7 SKIP**. 만족도 단독·오류 필수 입력·재전송 요청 키·민감본문 미포함 신규3건 PASS.
- WEB 전체: **1,454 PASS / 4 SKIP**, 203 files PASS /3 SKIP. 만족도·오류·재전송, 관리자 거절/통계/기존 검수 링크, 서버 admin gate 신규 회귀 포함.
- TypeScript PASS, Production build PASS. Lint 기존5 warnings/0 errors (최종 재실행 기록 확인).
- 로컬 PostgreSQL17: 기존 피드백 migration+후보 설치, ACL/RLS, 본인/타인/anon, 관리자 처리/감사, rate limit, 요청 충돌, 일반 사용자 타인 결과 연결 거절, 관리자 신고 문항 제한, telemetry/local_reviews 제외 PASS.
- 실제 서로 다른 PostgreSQL 연결 두 개의 동시 제출: 같은 피드백 ID 반환 PASS.
- 기존 run snapshot hash 불변. SQL에 평가·Credit·History 변경문 없음. 운영 데이터 변경은 실행하지 않았으며 실제 운영 전후 행 단위 E2E 불변 검증은 NOT TESTED.
- Auth/admin/local fixture는 합성 gate다. 실제 계정 로그인·실기기 제출·WEB↔APP 실시간 동일 데이터·운영 관리자 결과 조회는 NOT TESTED.

## 미완료/제약과 승인 사항

1. 운영 SQL 적용/APP·WEB 활성화/배포는 Owner 승인 대기. 현 운영에는 새 기능이 켜지지 않는다.
2. 현재 연결 대상은 canonical exam result `run/question`. UUID 단독 legacy·수리 결과는 일반 의견 접수 가능하지만 평가 직접 연결은 하지 않는다. 해당 계약 확장은 별도 작업.
3. 관리자 결과 조회는 completed run의 저장 결과와 parent만 지원한다. 부분 완료 checkpoint/실패 run의 상세 평가 화면은 현재 NOT SUPPORTED; 오류 신고 자체·상태 관리에는 영향 없다.
4. error_code는 allowlisted code만 수용하나 UI가 전역 로그·오류 메시지를 자동 수집하지 않는다. 오류 화면 전용 context wiring은 추가 작업으로 남긴다.
5. 운영 전 개인정보 보존/메일 수신 정책 및 실계정 보안 E2E 검수 필요. 첨삭 실행·Credit 조정·Worker 변경·스토어 제출 없음.

## 변경 기준

APP 시작 `c87a1a2`, WEB 시작 `4aaf963`. 최종 커밋은 해당 브랜치 Git log와 완료 보고를 따른다. 기존 `.fvmrc` 및 앞선 TASK01~04·Analytics 작업 보존.
