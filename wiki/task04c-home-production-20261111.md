# 작업04-C — 홈 설정 A 제한적 운영 적용

2026-11-11 · **A SQL DONE / 실제 앱 동기화 PARTIAL / C·D HOLD**.
Owner 승인: ef228c2의 수정 A만 운영 적용. B 기존 지원 RPC 유지, C 대학 소식 구조/D 공식 자료 적재 보류.
추가 UI 요청: 홈 편집을 알림 옆에 배치하고 카드 간격 통일.
기준 `codex/task04-applications-app75`, 시작 SHA `ef228c253dc4934bc69bcd0b9d0629c9b4118546`.
[04-B 검토](task04b-production-preflight-20261111.md) · [홈 구현](task04-home-university-news-20261111.md) ·
[운영 영수증·재검증 SQL](../supabase/verification/task04c_home_20261111/README.md).

## 운영 적용 결과

|요청 항목|결과·근거|상태|
|---|---|---|
|1. 적용 시각|2026-11-11 **19:30:58 KST** 성공 응답 확인. 실행 구간19:30:52–58, 사후 객체 확인19:31:29|DONE|
|2. SQL·버전|migration `20261111103058_task04c_home_configuration`, 승인된 apply_a_home.sql과 byte-identical|DONE|
|3. 적용 객체|home_configuration_revisions table1, RPC2, owner SELECT policy1, PK/FK/CHECK. 기존 table 컬럼 변경0|DONE|
|4. 사전 SELECT|동명 후보 객체0, 부모 UUID 호환, lifecycle 함수 hash 일치, 기존 지원 RPC hash 일치|DONE|
|5. RLS·계정 격리|RLS ON; anon EXECUTE 없음; authenticated RPC만 허용; 직접 CRUD/TRUNCATE 모두 거부. 비어 있지 않은 두 계정의 격리는 격리 DB PASS, 운영 앱 JWT는 미검증|PARTIAL|
|6. 탈퇴·삭제 차단|운영 DELETION_PENDING3개 read/save 실제 거부. ERASING은 운영0개로 상태 변경 없이 미검증; 같은 배포 본문의 격리 검증 PASS|PARTIAL|
|7. 저장·변경·복원|동일 SQL의 격리 신규저장/revision/CAS/멱등/변경/복원 PASS, Flutter 새 cache/계정 전환 PASS. 운영 앱에서 실제 write/relaunch 복원 미검증|PARTIAL|
|8. 기존 RPC|public/private 함수371개 정의+ACL 지문 동일, 지원 RPC5개 개별 hash/ACL 동일, 기존 my_applications 조회 contract 정상|DONE(검증 범위)|
|9. 기존 데이터|아래9개 table 전체행 지문·개수 동일, 기존 table87개 권한/RLS 및 policy119개 동일|DONE(검증 범위)|
|10. 롤백|권한 회수/재개 SQL 준비. 격리 실제 실행 시 이력 row digest 보존 PASS. 운영 장애 없으므로 롤백 미실행|DONE(준비)|
|11. 미검증|실제 JWT 저장/다기기·재로그인 복원, 운영 ERASING, 비어 있지 않은 실계정 간 격리, 최신 UI 실기기 설치|NOT TESTED|
|12. Git·Wiki|운영 migration/영수증/SQL·UI 변경·테스트·상태/로그/라우팅 반영. 로컬 커밋으로 기록하며 release merge/push/제출0|DONE|

프로젝트 `stlhijzpjfgwwdgunlsd`(LegendStudy), PostgreSQL17.6, ACTIVE_HEALTHY 확인 후 진행했다.
CLI로 로컬 migration 파일을 생성하고 MCP apply_migration 성공 후 서버의 실제 version으로 파일명을 일치시켰다.
[적용 migration](../supabase/migrations/20261111103058_task04c_home_configuration.sql) SHA256:
`b45fe80cbd0dd302db53fb9242649758a681f530cd443545dbddb1378ac572b5`.
승인 원문을 그대로 기록하므로 파일 상단의 NOT APPLIED 문구는 당시 후보 주석이다. 실제 적용 상태는 이 영수증과 서버 migration 기록이 기준이다. 파일 재실행 금지.

## 사전 통과 조건과 사후 비교

적용 전 운영 SELECT 및 수정 A 격리 재검증을 수행했다. 원본 combined SQL은 실행하지 않았다.

- 후보 table/RPC 없음. auth.users.id UUID 참조 가능.
- `account_private.allowed` MD5 `5bb28e0026f17746239e4369a772a5ce`,
  `lock_subject` MD5 `e48a7203c22b570c80e65ed51a7d20c9` 그대로다.
- 기존 공개/전용 함수371개, policy119개, 기존 table87개의 ACL/RLS 지문을 전후 비교했다. 모두 동일.
- 지원 대학 save MD5 `65edac758433cde4a123b95be3da42ee` 포함 기존5개 RPC 불변.
- 새 read RPC MD5 `dd86b20e7ef547a061a67459f6252083`, save RPC MD5 `12d3286751b7bc9f11bdc1c9f2e0ff9e`.
  live pg_get_functiondef의 두 body가 승인 후보와 정확히 일치한다.
- 신규 홈 이력은 직후0행, invalid0. 모든 기존 사용자에게 기본값을 INSERT하는 backfill0.
- C의 대학 소식 table2개/feed RPC는 여전히 없음. C/D 관련 DDL/DML0.

|기존 table|전후 행 수|전체행 지문|
|---|---:|---|
|profiles|522|동일|
|study_sessions|65|동일|
|mock_exam_attempts|15|동일|
|mock_exam_answers|405|동일|
|day_targets|105|동일|
|student_applications|0|동일|
|student_application_events|0|동일|
|account_deletion_requests|3|동일|
|universities|53|동일|

합계1168행. 이 표는 검증한 범위이며 전체 운영 DB의 모든 데이터를 snapshot한 주장은 아니다.
실사용자의 프로필/학습/지원/결과/Auth/lifecycle 데이터 수정·삭제0.

## RLS·탈퇴 차단·실제 DB 검증의 한계

운영에서 `BEGIN TRANSACTION READ ONLY`로 DB role 검증 후 ROLLBACK했다. 합성 사용자/자료 INSERT, lifecycle 상태 변경, table 임시 GRANT는 운영에서 하지 않았다.

1. 기존 pending subject3개를 DB role authenticated로 모사하여 read/save가 모두 SQLSTATE42501로 차단됨을 확인했다. READ ONLY transaction이므로 오류가 있어도 쓰기 commit 불가다.
2. 기존 정상 subject의 홈 read 및 기존 지원 목록 read RPC contract를 확인했다. 반환된 개인 기록/UUID는 영수증에 저장하지 않았다.
3. authenticated의 신규 table 직접 SELECT, anon의 신규 read RPC 모두 차단했다.
4. 실제 클라이언트 JWT/갱신토큰/PostgREST 세션 E2E가 아닌 **DB role 검증**이다.
5. ERASING 운영 대상0이라 고객 계정을 강제로 바꾸지 않았다. 해당 상태는 격리 PostgreSQL에서 read/save 차단 및 탈퇴 lock 대기 후 차단을 검증했다.
6. 두 정상 계정에 다른 설정을 넣는 운영 시험도 하지 않았다. 격리 owner별 다른 행, RLS predicate, 실제 배포 body 동일성을 확인했고 운영 실계정 검수는 남겼다.

신규 함수는 SECURITY DEFINER + empty search_path + auth.uid/lifecycle 명시 검사이며, 저장은 기존 subject lock→home lock 순서다.
RLS만으로 definer를 보호한다고 해석하지 않는다. 두 client role의 직접 SELECT/INSERT/UPDATE/DELETE/TRUNCATE는 모두 false.

security advisor는 기존5개 종류 유지. authenticated SECURITY DEFINER 노출 항목에 신규 RPC2개가 추가(151→153)됐다.
이는 승인한 RPC 접근 방식이며 owner/lifecycle/ACL과 함께 검토했다. 새 anon 노출·RLS 미설정 문제는 없다.
[Supabase 해당 권고 설명](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).
기존 unrelated 권고/운영 Auth 설정은 수정하지 않았다.

## 홈 UI 변경

Owner 첨부 IMG_1377의 별도 편집 행과 카드별 혼합 여백을 개선했다.

- `HomeGreeting`의 알림 바로 왼쪽에 조절 아이콘(tooltip/접근성 이름 **홈 편집**)을 배치. 인사와 두 버튼은 같은 행.
- 기존 알림 동작·배지 유지, 편집 버튼은 기존 HomeEditor를 그대로 연다. 선택을 자동 저장하지 않는다.
- `HomePage`가 표시 카드 사이 간격을 **16dp**로 단일 관리. Registry의 카드별8/16dp 여백과 홈 SectionHeader의 중복 상단 여백 제거.
- 섹션 제목–내용 간격은 기존12dp 유지. 다른 화면의 SectionHeader는 기존 기본24dp 유지.
- 카드 표시/숨김/순서/기본값/홈 저장 계약은 변경하지 않는다. 대학 소식은 바깥 여백만 변경했고 SQL·매칭·적재 변경0.

[428px 기본 글씨 미리보기](assets/task04c-home-20261111/home-428.png) ·
[320px 큰 글씨 미리보기](assets/task04c-home-20261111/home-320-large.png).
합성 Flutter 렌더이며 실기기 스크린샷이 아니다. 실제 APP75 설치본은 이번에 업데이트하지 않았다.

## 검증과 남은 검수

- 수정 A 새 격리 cluster 검증 PASS: owner isolation, 두 lifecycle 상태, 동시 CAS/멱등, subject lock, 삭제 cascade, 비파괴 롤백.
- Flutter 기존 홈/설정/온보딩/지원/계정/디자인 회귀126 PASS + 새 배치/간격 검사4 PASS = **130 PASS**.
- 428px1배/320px2배, 전체9개 카드 원래·역순 모두16dp 간격 및 두 버튼 같은 행 확인. 렌더 PNG 시각 확인.
- Analyze: No issues found. iOS profile/no-codesign PASS(55.4MB), Android debug PASS. 로컬 검수 버전1.0.2(76), 새 기기 설치/릴리스 번호 확정 아님. 기존 flutter_tts SPM/Kotlin2.2.20 미래 지원 경고는 유지. [검증 영수증](../supabase/verification/task04c_home_20261111/local-validation-results.json).
- 기존 APP75 FAIL5 분석은 [04-B](task04b-production-preflight-20261111.md#기존-fail5--app75-동일-조건-비교) 유지. 이번에 기대값을 고치거나 전체 suite green으로 보고하지 않는다.

Owner 후속 실계정 검수: 승인된 개발 빌드에서 로그인→홈 편집→카드 숨김/순서 변경→저장→앱 종료/재실행→동일 계정 재로그인→다른 계정에서 섞이지 않음 확인.
기존 계정 탈퇴 상태를 테스트 목적으로 바꾸지 않는다. 실계정 쓰기 시험에는 명시된 검수 계정만 사용한다.
이전 LS04B Offline 앱은 운영 키 없는 별도 앱이므로 운영 동기화 검수에 사용할 수 없다.

## 비파괴 롤백과 범위 보존

장애 발생 시 이번 Owner 지시로 승인된 [disable_a_home.sql](../supabase/candidates/task04b_preflight_20261111/disable_a_home.sql)을 우선 실행해 두 신규 RPC의 PUBLIC/anon/authenticated EXECUTE를 회수한다. 이력 table/DROP/DELETE0.
회수 후 has_function_privilege와 기존 함수/정책/데이터 지문을 재검증한다. 정상 APP75는 신규 RPC를 사용하지 않아 유지된다.
새 개발 앱은 기본 홈·저장 실패 안내·온보딩 건너뛰기 흐름을 사용한다. 원인 해소 후 재개는 별도 확인하고 restore_a_home.sql 사용.
원본 combined rollback.sql은 파괴적 철거이므로 사용 금지. 이번 운영 검증은 통과하여 롤백을 발동하지 않았다.

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의7항 및 [04-B 보존 검토](task04b-production-preflight-20261111.md#보존-검토와-owner-승인-항목)를 그대로 유지한다.
설정 revision/본인 identity/lifecycle, Interest·Application·Outcome·Learning 분리, 새로운 수집·분석 없음, 파생표시 비저장을 보존했다.
UI 결정은 [홈 기반 정책](home-personalization-and-events.md)의 명시적 편집 원칙과 [이번 Owner 결정](decisions.md#2026-11-11--홈-편집-위치와-카드-간격)에 연결했다.

운영 WEB 배포0, APP release merge0, App Store/Google Play 제출0, B RPC 변경0, C SQL 적용0, D 자료 적재0.
