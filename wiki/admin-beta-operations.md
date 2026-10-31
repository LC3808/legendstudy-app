# 논술 LAB 관리자 베타 운영

연결: [베타 v2](essay-beta-daily-v2.md), [관리자 Credit 운영](admin-credit-operations-20261027.md), [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md).

## 보존 검토 7문항

1. 설정 적용 시각과 감사 기록 시각을 분리한다. 평가는 기존 접수·완료 시각을 사용한다.
2. 기존 campaign, grant, revision_cutoff와 평가 당시 snapshot을 보존한다. 현재 설정은 과거 사실을 다시 쓰지 않는다.
3. 현재 설정 UPDATE 전후를 같은 트랜잭션의 변경 불가 감사 로그에 기록한다. 이미 발급한 한도와 cutoff는 수정하지 않는다.
4. 사용자 기준은 auth.users.id다. 이메일·클라이언트 metadata를 권한으로 사용하지 않는다.
5. 설정 결정, 이용권 발급·정산 사건, 평가 결과, 집계를 분리한다.
6. 관리자 조회에는 학생 답안·Provider 원문·비밀키를 포함하지 않는다. 설정 변경은 공식 관리자이면서 별도 승인된 UUID만 가능하다. 새로운 개인정보 수집은 하지 않는다.
7. 사용량은 기존 원장·run의 파생 조회다. 집계 값을 원장으로 역기록하지 않는다.

## 정책

- 기본 비활성, 1회, Asia/Seoul. 목표 종료: 2026-11-11 00:00 KST (11월 10일까지). 화면에서 정확한 시각을 확정한다.
- 일일 한도 변경 기본은 다음 KST 자정이다. 즉시 변경은 당일 발급이 없는 경우에만 가능하다. 이미 발급한 이용권은 증액·감액하지 않는다.
- 이미 발급한 이용권의 재첨삭 cutoff는 변경하지 않는다. 현재 운영 종료/비활성도 신규 beta 접수를 차단한다. 접수 완료된 평가는 기존 finish 계약으로 종료한다.
- 부분 실패는 전체 실패/환불로 간주하지 않는다. 재처리나 수동 복구 실행 버튼은 제공하지 않는다.
- 운영에는 v2가 미설치임을 read-only catalog로 확인했다. 본 패키지 역시 승인 전 미적용이다.

## 구현/검증

기존 일일 베타 v2를 확장한 로컬 구현·승인용 SQL 후보다. 운영 활성화와 배포는 별도 승인 전 미적용이다.

## 구현 파일 / 데이터 계약

- APP 승인 패키지: `supabase/candidates/essay_beta_admin_v1/`. `runtime.sql`은 현재 설정·승인 UUID·변경 불가 감사표, `allocation.sql`은 기존 v2 발급/사용 가능/재첨삭 만료 함수 확장, `reporting.sql`은 기존 run/checkpoint/원장 기반 읽기 집계다. `build.py`로 `install.sql`을 생성한다.
- 공개 RPC: `admin_essay_beta_config`, `admin_essay_beta_save`, `admin_essay_beta_report`. SECURITY DEFINER + 빈 search_path, authenticated만 실행; 내부에서 공식 `admin_operator()`와 account gate 검사. 저장은 추가 `settings_editors` 승인 UUID 필요. private 원본 표 직접 접근은 모든 클라이언트 역할에서 차단한다.
- `operations_config`: 활성/정확한 시작·종료/한도/고정 KST/예약 한도·적용시각/낙관적 version. 기존 campaign의 발급 후 고정 날짜와 grant cutoff는 유지한다. 종료를 앞당기면 실제 접근 만료는 현재 종료와 과거 cutoff 중 이른 값이며, 연장해도 과거 cutoff는 연장하지 않는다.
- `settings_audit`: 변경자 UUID·실제 기록 시각·전체 before/after·필수 사유. 설정과 같은 트랜잭션, UPDATE/DELETE 거절. 충돌한 저장은 PT409이며 자동 재시도하지 않는다.
- WEB: 기존 AdminSurface 메뉴·권한 화면을 재사용한다. `/admin/beta/`, `/admin/beta/usage/`, `/admin/beta/failures/`; `src/components/admin/admin-beta.tsx`, `src/lib/admin/beta.ts`.
- APP/WEB claim 응답의 `daily_limit`을 사용한다. 기존 필드 미포함은 1회로 호환. APP `lib/features/credits/essay_beta_credit.dart`, WEB `src/components/essay-beta-credit.tsx`. 유료/가입 Credit과 합산하지 않는다.
- 한도 선택: 다음 자정(기본), 즉시(당일 계정 발급이 하나라도 있으면 변경 거절). 1~100 검증 상한. KST 외 timezone은 받지 않는다. 크론 없이 서버 날짜와 예약 적용 시각으로 갱신한다.
- 설정 변경 권한은 기존 관리자 권한을 새로 부여하지 않는다. `approve_editor.sql`은 Owner가 별도 검증한 UUID에 추가 capability만 부여하는 승인 템플릿이다.

## 조회 의미 / 미제공 데이터

- 사용자 UUID 검색, 기간 시작 포함/끝 미포함, 최근/이용/실패 정렬, 25행 페이지. 날짜 미지정은 누적. 오늘 사용은 순소비+현재 예약, 남은 수는 실제 원장 또는 아직 미발급한 현재 한도다. 미발급 값은 **예약·발급을 발생시키지 않는 잠재 이용 한도**이며 실제 문항 자격은 제출 서버가 판단한다.
- 완료·부분 실패/실패·복구 대기·복구 완료·수동 확인을 분리한다. 최초 예약·실제 consume·release를 각각 표시한다. 부분 실패는 성공 checkpoint 보존과 예약 유지이며 자동 복구 버튼을 제공하지 않는다.
- 기존 `essay_exam_finalization` 사유 release만 자동 복구로 분류한다. 다른 release는 수동 확인 필요(자동이라고 추정하지 않음). 수동 Credit 변경 기능은 없다.
- 최신 문항 시도는 snapshot ordinal과 retry attempts로 연결한다. 진단은 저장된 execution/validation failure의 code/stage/http_status만 읽는다. 답안·Provider 오류 원문은 수집/표시하지 않는다. 진단이 없으면 알 수 없음이며 실패 원인을 생성하지 않는다.
- 발생 시간 대신 실제 저장된 **접수 시각**을 표시한다. 별도 확정 실패 시각이 없는 계약을 임의로 보완하지 않는다. 실패 건수는 현재 run/문항 상태 기준이며, 과거 모든 재시도 실패 횟수의 합이 아니다.

## Owner 승인 후 적용 순서 (현재 미적용)

1. 공지 TASK01, 일일 베타 TASK02 v2 후보를 각각 승인/검증한다. 운영 catalog에서 v2 미설치를 확인했다. TASK04 precheck는 v2 함수 본문·소유자·ACL가 다르면 실패하도록 한다.
2. reviewed campaign/notice/exam scope를 기존 TASK02 절차로 준비한다. 활성화된 캠페인이 없도록 설치 창을 유지한다. Worker·평가 Package를 변경하지 않는다.
3. `precheck.sql` 검토 → `install.sql` 1회 적용. 초기 operations_config가 없으면 발급은 fail-closed다. 재실행은 ALREADY_INSTALLED로 차단한다.
4. 공식 관리자 계정을 별도로 확인하고 `approve_editor.sql`의 UUID/승인 근거를 Owner가 확정해 적용한다. 이메일·JWT user_metadata로 관리자 권한을 만들지 않는다.
5. WEB 검수 배포/APP quota UI 반영 후 승인된 관리자가 화면에서 시작·종료 시각을 입력하고 **비활성 상태로 먼저 저장**한다. 종료 기본 제안은 11/11 00:00 KST. 공지/승인 시험 범위를 확인한 뒤 활성화한다.
6. `verify.sql`은 RPC 권한/설정 및 run·원장·grant 보존 해시 확인용이다. 설치 전 동일 데이터 SELECT의 해시를 보관해 대조하며, 동시 정상 운영 변경이 있으면 해당 차이를 별도 조사한다. SQL 성공 표시만으로 기능 PASS 처리하지 않는다.
7. 일반/비로그인/조회 전용 관리자/승인된 관리자 실계정 검수는 적용 후 필요하다. 운영 평가를 검증 목적으로 생성하지 않는다.

## 롤백

- 승인된 관리자 화면에서 활성화를 끈다. `rollback.sql`은 기존 authenticated Owner 세션에서 같은 RPC를 호출하는 대안이다. 감사 기록을 남기고 신규 beta 접수만 차단한다.
- 원장/기존 grant/감사/History/접수 완료 job은 보존한다. 데이터 삭제/수동 Credit 복구/Worker 변경을 하지 않는다.
- WEB/APP 해당 기능 커밋을 revert할 수 있다. 복수 이용권이 발급된 뒤 구버전 1회 runtime으로 무조건 되돌리지 않는다. 스키마 제거 또는 이전 SQL 복원은 별도 검토 대상이다.

## 자동 검증 / 출시 제한

- Flutter Analyze: 0 issues. 전체 Test: 1,303 PASS / 7 SKIP / 0 FAIL.
- WEB 전체 Test: 1,448 PASS / 4 SKIP / 0 FAIL. TypeScript PASS. Lint 0 errors, 기존 5 warnings. Production Build PASS (로컬 정적 빌드만).
- 격리 PostgreSQL 17: 설치 baseline guard/권한/설정 충돌/시작 전/종료 경계/30 동시 발급/자정 한도/예약 멱등성/실패 반복 finish 1회 release/설정 변경 원장 불변/감사 불변/무료 재첨삭0/종료 전 접수 후 완료/과거 부모 결과 해시/유료14일/가입3잔액 분리/기능 비활성 롤백. 최종 격리 DB `beta_admin_task04j`에서 전체 시나리오 PASS, 생성된 install.sql 및 verify.sql 직접 실행 PASS.
- 실제 운영 DB 변경, Worker 배포, Provider 호출, Credit 수동 조정, 운영 WEB 배포는 수행하지 않았다. 실계정 관리자 설정·APP/WEB 동기화는 운영 패키지 승인·배포 전 NOT TESTED다.
