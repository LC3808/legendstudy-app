# TASK06 — 평가 비용·장애 모니터링

2026-11-01 · **구현·격리 검증, 운영 SQL/WEB 미적용**.
기존 [Analytics](analytics-v1-implementation-20261030.md), [관리자 베타](admin-beta-operations.md),
[Credit 운영](admin-credit-operations-20261027.md), [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)을 확장한다.
새 평가/과금 시스템이나 재처리 실행 기능은 만들지 않는다.

## Owner 정책과 보존 검토

TASK06은 기존 WEB 관리자에서 평가 처리·비용·장애·Credit을 조회하는 기능이다.
GA4는 행동 분석, PostgreSQL의 run/checkpoint/ledger는 평가·정산 사실을 담당한다.
실제 Provider 호출·운영 평가·Credit/History 변경·Worker 배포는 금지한다.

장기 데이터의 seven preservation questions:
1. 요청/완료 시각과 관측 기록 시각을 분리한다. 없는 호출/오류 시각은 NULL이다.
2. 원본 run/checkpoint/ledger는 읽기 전용. 비용 추정에는 단가 버전과 기록 시각을 남긴다.
3. 원장 UPDATE 없음. 단가·비용 스냅샷·접근 감사는 변경/삭제 차단, 경고는 발생/해제 시각 보존.
4. 기존 canonical run/parent/decision 식별자를 사용한다. 새 학생 identity를 만들지 않는다.
5. 운영 장애/비용은 학습 성취나 대학 평가 점수가 아니다. GA4 이벤트를 거래 사실로 사용하지 않는다.
6. 공식 관리자 gate, blocked-account 검사, private RLS/권한으로 접근 제한. 학생 답안·이메일·토큰·Provider 원문 제외.
   식별자는 익명화가 아니며 감사/운영 보존 기간의 별도 정책 확정이 필요하다. 자동 삭제는 추가하지 않았다.
7. 추정 비용/중복 의심/성공률은 파생값. 실제 청구액/확정 오류와 구분하며 provenance 및 UNKNOWN을 표시한다.

## 기존 실제 코드·DB 확인

APP 시작 기준 `4ba0a4e`, WEB `38d2d8`; 기존 `.fvmrc` 보존. Claude 브랜치 변경 없음.
LegendStudy Supabase `stlhijzpjfgwwdgunlsd`에 SELECT로 source column과 공식 관리자 함수 정의를 확인했다.
파일 존재를 운영 배포로 간주하지 않는다. 새 모니터링 스키마/RPC는 운영에 적용하지 않았다.

- `essay_exam_private.runs`: reserved/completed/failed, snapshot answers의 제출 순서와 parent/decision 연결.
- checkpoints: **개별 created_at 없음**. qN 및 qN-retry-M 상태, receipt와 failure payload.
- retry_requests: 동일 run의 generation/attempts/접수 시각. parent-linked 재첨삭은 별도 회차.
- credit_grants/credit_transactions: purchase/signup_bonus/essay_beta_daily/기타 출처.
  TASK02/04의 beta는 기존 grant origin을 사용한다. 별도 가상 allowance 원장을 만들지 않았다.
- `essay_ai_processing_runs`: legacy Provider 호출. `total_tokens` 컬럼 없음; input+output 사용.
- 공식 `public.admin_operator()` + `account_private.allowed(auth.uid())` 사용.

## 구현

WEB 기존 `/admin/operations/`에 5개 탭: 운영 현황 / 평가 처리 현황 / API 비용 분석 /
장애 및 재처리 / Credit 사용 현황. 기존 운영 RPC 화면은 상세 접기 영역에 보존했다.

- `src/components/admin/admin-essay-monitoring.tsx`: Monitor, Metrics, Table. 날짜/대학/유형/상태/출처/재처리 필터,
  서버 25건 페이지, 처리 상세·문항 공식 제출 순서·재처리·안전 진단·영수증·원장 조회.
- `src/lib/admin/monitoring.ts`: 공통 typed report, KST/UNKNOWN/금액/문항 표시.
- `src/app/admin/operations/page.tsx`, `admin-surface.tsx`: 기존 관리자 페이지/메뉴 연결.
- source는 [SQL 후보](../supabase/candidates/essay_operations_v1/README.md).
  `essay_ops_private`의 5개 테이블은 가격/추정 snapshot/threshold/alert/access audit만 저장한다.
  평가 실행·학생 답안·Credit 데이터를 복제하지 않는다. run_facts/calls는 읽기 projection이다.
- 공개 RPC: `admin_essay_operations`, `admin_essay_operations_estimate`, `admin_essay_operations_check_alerts`.
  모두 SECURITY DEFINER, empty search_path, 8초 제한, authenticated EXECUTE + 공식 관리자 gate.
  anon/service_role/PUBLIC 차단; private schema/table/function 접근도 차단, 테이블 RLS.

## 지표 정의 및 비용 한계

요청수/성공률/지연시간/필터 집계는 접수일 코호트이며 날짜는 KST.
성공률 = completed / (completed + failed); reserved는 분모 제외, 부분 실패/재처리 대기는 별도 표시.
평균/P50/P90/P95/최대는 완료시각−접수시각; 존재하지 않는 OCR/대기/저장 단계 시간은 생성하지 않는다.
현재 활성 전체 reserved와 선택 기간 통계는 별도다.

비용 receipt만 집계하고 q결과에 복제된 영수증/usage summary는 제외한다.
legacy와 exam 영수증의 같은 평가 ID 중복도 제외한다.
- ACTUAL: legacy에 `provider_reported`, USD, nonnegative cost가 명시된 값. Provider invoice 대사 완료를 뜻하지 않는다.
- ESTIMATED: legacy `estimate` 또는 명시적 승인 단가로 고정한 snapshot. 과거 추정 덮어쓰기 금지.
- UNKNOWN: 비용 provenance/통화/호출시간/모델/캐시 정보 등이 불충분한 값. NULL을 0달러로 바꾸지 않는다.

운영 exam receipt는 호출시간/캐시가 없고 review는 Provider/model도 없다.
`cost_amount`만 있는 생성 영수증을 USD ACTUAL로 승격하지 않는다.
따라서 오늘·이번 달 **호출일 비용**은 알려진 시각만 집계하며, 미확인 영수증 수를 함께 표시한다.
별도의 일/月/모델/유형/최초·무료재첨삭/최종실패/재처리 비용은 **요청일 코호트**다.
평가당 평균은 알려진 비용 소계 / 영수증이 있는 run 수로 명시한다. 전체 실제 평균이 아니다.
429 등 영수증이 생성되지 않은 실패 호출의 비용은 미확인이다.

평가 유형은 snapshot.evaluationType이 없으면 UNKNOWN. exam.kind의 MOCK_ESSAY를 인문 유형으로 오인하지 않는다.
인문/상경/수리 확장은 필터 계약으로 준비했으나, 기존 미기록 자료의 자동 추론은 하지 않는다.
HTTP429의 요금 부족/rate limit 원인을 일반화하지 않는다. 코드/단계/HTTP와 안전한 정적 안내만 제공한다.
오류시각 부재도 요청시각으로 대체하지 않는다.

Credit은 실제 원장 출처별 사용/성공·실패별 사용/예약·해제·환불을 집계한다.
현재 예약=reserve-consume-release, failed 잔여예약은 복구대기, consume>reserve 등은 **의심** 표시다.
reserved 부분실패의 예약은 자동 복구 대상으로 취급하지 않는다. 오늘 차감은 거래시각 기준 별도다.
확정 중복 거래 판정·원장 조정 기능은 없다.

## 경고·단가

7개 규칙: 일일 알려진 비용, 최종실패율, 평균시간, Provider 오류 건수, 재처리건수, 복구대기, 장시간reserved.
서버 threshold는 NULL/비활성 기본값. 단가도 빈 테이블; 실제 단가를 임의 생성하지 않았다.
관리자의 ‘경고 점검’은 서버에서 계산하고 advisory lock + unique open-rule로 중복 방지,
정상 해소/비활성 시 resolved_at 기록. **자동 background 감시는 미구현**, 이메일/문자/푸시 범위 밖.
단가/threshold 운영 등록은 검증된 근거와 Owner 승인 후 서버 설정 절차로 한다.
가격 interval이 겹치거나 cache를 모르면 자동 추정하지 않는다. 평가 runtime과 무관한 관리 기능이다.

## 검증

- PostgreSQL17 격리 fixture: terminal 성공률·부분실패·문항 순서·Credit 출처/해제·필터·receipt 중복제거,
  ACTUAL/ESTIMATED/UNKNOWN·cache 단가·추정 불변·관리자 허용/일반·blocked·guest·anon/service_role 차단 PASS.
- 기존 run/checkpoint/ledger hash 불변 PASS. 8개 동시 경고 점검→open alert 1개 PASS.
  rollback→기존 운영 데이터 및 새 감사/추정 이력 보존 PASS.
- WEB widget 6건: UNKNOWN, 필터, 문항 순서, 상세, 실패필터, 권한오류, 로그아웃, KST/0값 표시 PASS.
- WEB 전체/TypeScript/Lint/Build 및 APP Analyze/Test 최종 결과는 아래 완료 기록 참조.
- 격리 auth stub 테스트는 **운영 실계정 JWT 검증이 아니다**. 실제 운영 관리자·일반계정 및 브라우저 반응형 검수 미실시.
  표 내부 스크롤·필터 wrap·반응형 metric grid를 코드에 적용했다.

## 운영 적용·롤백·남은 작업

1. Owner SQL 승인 → precheck에서 source/gate/schema없음 재확인 → install 1회 → postcheck.
2. 실계정 JWT allow/deny, production-size EXPLAIN/8초 query latency, private grants/RLS 검증.
3. 실제 모델 단가·시각/cache attribution·threshold 확정. 완전 비용/단계 telemetry 수집은 별도 Worker 출력계약 승인 과제.
4. WEB 별도 승인 배포 후 관리자 read 검수. 이번에는 로컬 빌드까지만 수행.
5. 문제 시 WEB 수정 commit revert 먼저, 필요 시 rollback.sql로 새 공개RPC3개 제거.
   private audit/price/snapshot/alert와 원래 평가·Credit·History는 보존. install 무조건 재실행 금지.

실평가·Provider 호출·Credit 수정·History 수정·운영 DB/Worker/Auth 변경·스토어 제출 없음.
기능 구현과 실제 운영 계측의 완전성을 구분한다. 비용 완전성/실계정 권한/성능/상시 경고는 출시 전 잔여 검증이다.

## 최종 자동 검증 기록

2026-11-01, 실제 운영 호출 없이 실행:
- Flutter Analyze: **0 issues**. 전체 Flutter Test: **1,306 PASS / 7 SKIP / 0 FAIL** (APP 코드 변경 없음).
- WEB TypeScript: PASS. ESLint: **0 errors / 기존 5 warnings** (math submit 2, history test 2, Owner preview 1).
- WEB Production Build: PASS. 전체 Test: **1,460 PASS / 4 SKIP / 0 FAIL**, 204 files PASS / 3 files SKIP.
- SQL local fixture + ACL/metric/price/immutability 검증 PASS; 8 concurrent check + rollback PASS.
- Wiki handoff/link/task routing 검사 PASS, current-status 12,000 bytes(12KB budget 이내).
- 운영 계정 접근/운영 성능/실제 비용청구 대사/브라우저 실화면은 NOT TESTED. 통계 원본 SELECT는 schema 확인 범위다.

Commit은 APP 후보 SQL+canonical Wiki와 WEB 관리자 UI+tests로 분리한다.
최종 SHA는 완료 보고와 각 저장소 Git history를 사용하며 current-status에 고정 HEAD로 기록하지 않는다.

Provider 오류 경고는 오류 시각이 없는 기존 checkpoint의 제약으로 **오늘 접수된 run의 Provider 단계 실패 기록 수**를 사용한다. 오류 발생일 집계로 해석하지 않는다. 오류 시각은 UNKNOWN으로 유지한다.
