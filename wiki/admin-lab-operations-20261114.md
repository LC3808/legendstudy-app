# 논술 LAB 운영 관리 1차 — 2026-11-14

상태 **DONE**: 확정 범위 구현·SQL/WEB 운영 반영·관리자 실제 조회 검증 완료. 미수집 결과 열람 이벤트/기존 테스트 실패/후속 UX는 아래에 명시한다.
기존 정책: [Credit](admin-credit-operations-20261027.md), [베타](admin-beta-operations.md),
[피드백](essay-feedback-reports.md), [장기 보존](longitudinal-learning-admissions-data-strategy.md).
신규 품질 점수/평가 엔진/코멘트 원장은 만들지 않는다. Claude 전체 UI 설계와 분리된 데이터 연결이다.

## 보존 검토 7문항

1. 요청·완료·예약·소비·재작성 시각은 기존 원본의 별도 사건이다. 결과 열람 사건은 확인 불가다.
2. runs.snapshot/result 및 billing/transactions/checkpoints/calls를 읽으며 당시 버전·문항 식별을 보존한다.
3. 원본 UPDATE/DELETE 없음. 함수만 추가/교체하며 rollback으로 기존 함수를 복원한다.
4. auth.users.id → credit_accounts.user_id/account_id → run을 연결한다. 이메일은 검색용이며 권한 기준이 아니다.
5. 학습 요청/평가 결과와 이용권 정산 사건을 구분한다. 입시 Outcome·학습 효과로 해석하지 않는다.
6. 서버 관리자/활성계정 검증, 상세 대상 활성계정 검증. 원문은 관리자 읽기 전용 화면에서만 표시한다.
   공개 집계·외부 전송·새 retention/수집 없음. 운영 학생 원문/전체 UUID는 Git에 넣지 않는다.
7. 집계/이상 징후는 파생 조회이며 원장에 쓰지 않는다. 실패 이력과 현재 상태, 미기록과 0을 구분한다.

## 구현과 계약 — Claude 인계

- `/admin/credit/`: 기본 requested_desc. 완료/사용/잔액↑↓/가입순 선택. 서버 전체 회원 정렬 후 페이지,
  NULL 마지막·UUID 동률 정렬. 기존 검색10/20/50·지급·원장·잔액 helper 보존.
- 기존 `admin_credit_member_list` 응답에 optional `activity` 추가(requested/completed/last_requested_at/
  last_completed_at/latest_university). 최근 이용권 사용 시각 last_used_at과 요청 시각은 다르다.
- 회원 상세와 `/admin/essay-runs/`: `admin_lab_runs(p_user,p_university,p_exam,p_state,p_source,p_offset)`.
  `admin-lab-v1`, summary/items/universities/total/offset/limit25. 전체 또는 회원 scope에서 대학/상태/출처 필터.
  요청순 DESC,id. API 시험 필터 가능; UI에는 대학/상태/출처 제공, 시험은 행에서 구분.
- `admin_lab_run_detail(p_run)` → `admin-lab-detail-v1`, user_id/run/billing/ledger/calls/retries/
  diagnostics/children/reviewed_questions/result_viewed_at. 후자는 null: 확정 열람 이벤트 미연결.
  run.answers/result는 당시 저장본. parent/children 연결, 원본 평가/기준 버전과 학생 EvaluationReport 재사용.
  run 결과가 비었거나 파싱 불가하면 정상 성공으로 표시하지 않는다. Provider 호출은 기존 calls의 기록만 표시.
- 새 RPC는 authenticated EXECUTE + require_admin, 빈 search_path,5초 제한. anon/service_role 거부.
  상세는 account_private.allowed(subject)도 검사,8MB 제한. dispatch키·telemetry·local_reviews 미노출.
- 이상 징후:30분 미완료,실패,결과 없는 차감,예정 수량 초과 소비합계,무료 재첨삭 차감,완료 결과 없음.
  여러 grant의 분할 소비 거래 수를 중복 차감으로 오판하지 않는다. 알림은 수동 검토 신호,복구 실행 없음.
- `/ql/?run=…&question=…`는 기존 ql_exam_detail과 기존 quality_operator 권한을 유지한다.
  관리자 자격만으로 검수 저장 권한을 확대하지 않는다. 일반 진입의 기존 기본 탭 보존.
- 완료 목록 필터에서 모든 완료 회차 접근 가능. 기존 검수는 회차·문항 단위이며 회원/회차 수와 다르다.
  대학/시험/문항/시각/평가 버전/검수 여부는 기존 기록으로 후속 샘플링 가능. 랜덤 추출 추가 없음.

## 운영 읽기 전용 조사

2026-11-14 조회 스냅샷. `essay_exam_private.runs` 전체(내부/검수/과거 테스트 포함) 기준:

| 지표 | 값 | 정의 |
|---|---:|---|
| 요청 |58|회차 행 수|
| 완료/실패/진행 |47/10/1|state completed/failed/reserved|
| 최초·후속 유료 |38|parent_id IS NULL; paid_cycle required1|
| 무료 재첨삭 요청 |20|included_revision required0; 완료15/실패5|
| 유료 완료/실패/진행 |32/5/1|paid_cycle|
| 유료 소비 완료 |32|완료 원장 consume 수량1|
| 완료 결과 존재 |47|result.questions 존재, 제출 문항 대응 확인|
| 차감 후 결과 없음 |0|consume 수량>0 및 결과 없음|
| 예정 수량 초과 차감 |0|회차별 consume 수량 합계 > credits_required|
| 무료 재첨삭 소비 |0|required0 회차 consume|
| 완료 문항/결과 불일치 |0|제출 문항마다 결과 존재|
| 베타 발급 연결 |1|daily_grants.grant_id → transaction → decision|
| 저장된 회차 품질 검수 |0|human_quality_judgments의 exam_run 연결|

전체58을 실제 학생58명 또는 전부 LIVE라고 부르지 않는다. promotion origin/기간만으로 베타를 판정하지 않는다.
베타 외 기록도 LIVE/유료 실사용으로 단정하지 않는다. 30분 넘은 미완료1은 10/26 한양대2027 모의 상경
기존 기록이며 이번 작업에서 재평가/취소/차감/복구하지 않는다.

### 성균관대 베타 사례

회원 식별자는 관리자 상세에서 확인(개인 UUID/답안 원문 Git 제외).
2023학년도 성균관대학교 수시논술 언어형2교시,11/6 13:02:26 KST 요청 →13:07:11 완료.
최초 paid_cycle1,settled,3문항 결과 존재,contract1.3,평가/근거 버전
`material-1-e3deb0831c945d5199a80aa8cf4698340bfa0c41c1606a6e8fac45fa38aa5951`.
promotion grant의 예약/소비-1이며 **daily_grants가 연결된 실제 베타 무료 발급 사용**이다.
무료 재첨삭 회차 자체는 아니다. 연결 재첨삭0. 캠페인11/1–11/10,cutoff11/11 00KST.
기존 성균관대 다른6회는10/23·25 과거 내부 기록을 포함하므로 베타 사례에 합치지 않는다.
초기 검수 후보로 조회 가능하나 검수 판정 작성/재평가 실행은 하지 않았다.

## 기존 화면·피드백 조사

- 운영 beta v2 campaigns/daily_grants는 존재. admin_essay_beta_config/report 등 설정 조회 RPC는 부재:
  화면의 '조회 기능 미연결'은 실제 상태다. 과거 이력 조회를 위해 베타 재활성화/발급 설정 설치하지 않는다.
- 학습 분석은 기존 admin_exam_learning,대학 활동 admin_member_university_activity,운영 추적 admin_essay_operations 재사용.
- 기존 /ql/ 회차·혼합형 접근/목록89문항 운영 브라우저 확인(기존 최근30일 목록,회차수와 다름).
- public.feedback_submissions 및 feedback_notifications 운영 존재. feedback에는 user/category/title/body/
  app_version/platform/status 등이 있으며 run 연결 컬럼은 없다.
- essay_feedback_submit/mine/admin_essay_feedback 계열 운영 함수는 없음. 기존 essay_feedback_v1 후보 및
  `/admin/essay-feedback/` 구현을 후속 UX와 함께 재사용 가능하나 이미 운영 연결됐다고 표시하지 않는다.
  학생 코멘트는 기존 원장에 run/question 연결 설계를 적용하는 후속 작업,이번 신규 테이블0.

## 검증·배포 인계

SQL: [후보와 적용/원복 절차](../supabase/candidates/admin_lab_operations_20261114/README.md).
격리 PostgreSQL17에서 exact apply/rollback,검색/전체정렬/동률/NULLlast/25페이지/회원·대학·시험필터,
역할/비관리자/비활성대상 차단,버전보존·민감필드제거,재실행차단,원복의 run 불변 검증.
실제 잔액 비교와 실제 학생 답안·결과의 신규 관리자 화면 E2E 완료.
WEB 변경 자체는 기존 렌더러/읽기 hook 재사용. fixture테스트와 실제운영 확인은 구분한다.

운영 기준 배포798de461-c684-428e-90dc-3d3489191cc2/source c995178.
WEB 기준62a3296에서 작업. 운영 SQL은 Owner 직접 위임 후 R1 적용 성공; 신규 UI도 아래 최종 배포로 반영 완료.
이전 웹 배포로 복귀 후 rollback.sql 적용 가능. 배포 도구는 /admin/와 /ql/만 교체하고
기존 공개 학생 자산·API·설정을 보존하며 동시 배포 drift 발생 시 중단한다.

이번 요청은 [11/13 운영 작업](operations-commercial-20261113.md)의 후속이며
학교 공개 정책 총·평균3/참여1,PDF845 활성화 및 [장애 조사](supabase-temp-incident-20261113.md)의 미확정 인과관계를 변경하지 않는다.

### R1 운영 SQL 적용 확인

Owner “sql까지 니가 직접 진행해” 지시로 기본 실행자 원칙의 이번 작업 예외를 명시했다.
Supabase apply_migration(admin_lab_operations_20261114) success,3함수 권한/config 확인.
관리자 역할 조회58/47/10/1·베타1 및 성균관대 답안3/결과3 PASS.
인증 문맥 없는 authenticated 역할 ADMIN_REQUIRED(42501),anon/service_role 실행권한 없음.
기존 used_desc 첫10명 잔액 summary 적용 전후 일치.
runs/credit_transactions/credit_grants 전체행 해시 적용 전후 각각 동일(사용자 데이터 변경0).
WEB TypeScript·변경 ESLint·production 설정 정적 build PASS.
전체1987 PASS/5 SKIP/11 FAIL 및 기존 dashboard mock 오류1. 실패11개·오류1은 깨끗한62a3296에서도 동일 재현.
신규5·회원격리2·기존Credit7·Quality36 관련 검증 PASS(각 실행 범위의 수치를 중복 합산하지 않음).
격리 exact SQL 재실행 차단·베타 연결·동률·원복 검사도 PASS.

### 최종 운영 배포·검수

WEB source `3d19c03a79b4a86245cc4a43529323c1dffb96c4`, Pages
`698baa47-dc13-4621-b964-dd0ceaa3aaa2` success. 바로 이전bc89be7e,작업 전798de461 보존.
최종 변경 범위 /admin/·/ql/와 새 해시 자산,기존 비대상2653자산·API 번들·환경설정 동일.
운영 migration version `20261114125224`를 repository migrations에도 동일 SQL로 기록.
기존 함수/원장 불변·requested_desc 독립 원천 정렬 일치·잔액 불일치0·UUID 검색1·마지막 페이지8 PASS.
일반 회원 인증 문맥의 상세 조회 ADMIN_REQUIRED(42501) 확인.
실제 Chrome 관리자 세션: 기본 최근 요청순·활동 컬럼,679회원 중 성균관대 회원 검색1,
회원 상세1회/완료1/베타1,전체58회,베타필터1회,실제답안3·결과3·원장 예약/소비·재처리1 표시 PASS.
기존 품질 검수 해당 문제3 원본 상세 조회 PASS; 검수 저장/재평가/금전 변경 수행0.
공식 라벨이 registry에 없는 과거 문항은 UUID로 구분한다. 배열 순서를 공식 문항 번호로 추정하지 않는다.
검수 링크 전체 탐색으로 이전 탭 상태 재사용을 방지. 보완 후 신규5/TS/build PASS.

남은 범위: 결과 열람 시각은 기록 미연결(확인 불가),beta 관리자 설정 RPC 미설치,
학생 코멘트/전체 UI 재설계는 후속. 품질검수 판정 작성·실제 재평가·유료 결제 실행 NOT TESTED(이번 읽기 기능 범위 밖).
전체 테스트 기존11실패/오류1은 별도 정리 대상이며 이번 배포의 신규 회귀로 오인하지 않는다.
