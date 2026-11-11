# 작업04-B — 운영 연동 사전 검증

후속 [작업04-C](task04c-home-production-20261111.md): 수정 A는 Owner 승인 후 운영 적용 완료. 아래 사전 검토/기존 구현 기록은 당시 근거이며, C/D HOLD·실계정 검수 잔여는 유지한다.

2026-11-11. **운영 변경0 / 원본 후보 HOLD / 보완한 A만 별도 승인 요청 / C·D HOLD.**
기준 브랜치 `codex/task04-applications-app75`, 검토 소스 `37eb530737e1676379f1d5446ac7af2c74d5f4d3`.
실제 APP75 빌드 소스 `c9b483018bcada179050595cf78c8ca4a3d213ba`. 문서 포함 시작점633f982와 혼동하지 않는다.
[작업04 구현](task04-home-university-news-20261111.md) · [지원 관리](task04-applications-20261111.md) ·
[SQL·검증·비파괴 롤백 패키지](../supabase/candidates/task04b_preflight_20261111/README.md).

## 결론과 발견 사항

|항목|원본37eb530 검토|판정·후속|
|---|---|---|
|A 홈 설정|타인 접근/멱등/CAS는 통과하지만 `account_private.allowed`와 기존 subject lock 누락|P1. 탈퇴 대기·삭제 진행 중 본인 read/save 성공을 격리 재현. 기존 lifecycle 함수를 호출하는 별도 A 대체 후보 준비·검증. 운영 미적용|
|B 실제 지원|기존 운영 RPC5개 재사용, 저장 함수의 의미상 중복 방지 확인|새 SQL 불필요. 기존 함수/테이블/이력 유지|
|C 대학 소식 구조/RPC|`created_at <= snapshot_at` + OFFSET은 DB snapshot이 아님|P1. 늦은 commit으로 100개+2개 중1개 중복, 새1개 누락. C 적용 보류|
|D 공식 자료 적재|공식 검수 완료 데이터·운영 수집기0|C 보완, 원본/변경 공지/정확한 전형·학과/운영 검수 책임·주기 승인 전 보류|
|원복|기존 rollback.sql은 신규 table3개 DROP|일반 장애 원복은 실행권한 회수로 대체. 이력 삭제는 별도 승인 필요|

이번 변경은 검토 SQL·격리 검증·복원 회귀 테스트·Wiki뿐이다. Flutter 구현·원본 candidate.sql·운영 함수·기존 브랜치·릴리스는 수정하지 않았다.

## 운영 읽기 전용 대조

LegendStudy 프로젝트 `stlhijzpjfgwwdgunlsd`, PostgreSQL17.6, ACTIVE_HEALTHY를 확인했다.
운영 도구는 프로젝트/권고 사항 조회와 SELECT만 사용했다. 운영 합성 INSERT/SET ROLE/DDL/ROLLBACK 테스트0.

- 후보 table3개와 function4개 모두 **없음**. 명칭 충돌 없음. `auth.users.id`와 `universities.id` UUID, `universities.name` text 일치.
- 기본 privilege에 anon/authenticated의 table CRUD와 function EXECUTE가 있어 명시 REVOKE가 필수다. 격리 DB도 이 기본 권한을 모사했다.
- 기존 application table2개 RLS ON. 본인 `auth.uid()` + `account_service_allowed()` SELECT 정책 확인.
- live `account_private.allowed(uuid)`는 Auth 실존 및 DELETION_PENDING/ERASING 없음 확인. definition MD5 `5bb28e0026f17746239e4369a772a5ce`.
- 기존 `lock_subject(uuid)` MD5 `e48a7203c22b570c80e65ed51a7d20c9`. A 대체안은 두 의존 함수 hash가 다르면 적용을 중단한다.
- security advisor는 기존5개 종류(무정책 RLS, public extension, anon/authenticated definer 노출, leaked-password protection)를 반환했다. 이번 신규 객체는 운영에 없으므로 후보 RLS의 운영 PASS 근거로 쓰지 않는다. 기존 권고에 대한 운영 수정은 하지 않았다.

|기존 RPC|signature의 입력 타입|live definition MD5|
|---|---|---|
|my_applications|integer|fcec97ef2cf3028a0843d25b7a2a1756|
|my_application_save|uuid,integer,integer,uuid,text,text,text,uuid|65edac758433cde4a123b95be3da42ee|
|my_application_event|uuid,text,timestamptz,uuid,uuid|acc3526305dd6981d1ef85b834c9466c|
|my_application_events|uuid,integer|5cc6659d757adf6aec8eb01f869812ac|
|my_application_delete|uuid|d27ad21f793fe4f951d3055d4c05d9ad|

5개 모두 SECURITY DEFINER/search_path empty, authenticated EXECUTE, anon/PUBLIC EXECUTE 없음 확인.
저장 함수는 기존 사용자 lock 안에서 연도/대학/학과/모집시기/전형명 조합 중복을 거부하며, 다른 전형·학과는 구분한다.
`request_key` 재시도는 같은 기록 반환, 수정은 revision 검사, event 이력은 별도 보존한다. B를 다시 배포하지 않는다.

### 기존 데이터와 APP75 영향

신규 A는 table1개와 RPC2개만 추가한다. 기존 profiles 컬럼 변경/기본값 강제/backfill/기존 회원 일괄 INSERT 없음.
미설정은 null이고 새 앱에서 기존6개 카드 기본 홈으로 표시한다. 실제 지원/합격 결과/학습 데이터와 별도다.
홈 이력은 auth.users FK cascade: 최종 회원 삭제 시 함께 삭제한다. subject lock으로 탈퇴 요청/삭제와 저장 순서를 직렬화한다.
A DDL의 FK 참조/카탈로그 lock은 짧은 대기를 유발할 수 있으므로 lock_timeout5초, statement_timeout30초와 한 transaction을 사용한다. 대기 실패 시 부분 적용하지 않는다.

APP75는 신규 홈/소식 RPC를 호출하지 않는다. 실제 c9b4830 대비 lib/features/study, core, auth, ios, android, pubspec/lock 변경0 확인.
작업04의 router/home/profile/onboarding 변경은 기존 개발 범위이고 이번04-B에서는 앱 코드 변경0.
자동채점·학습 동작을 전부 실기기 회귀한 것은 아니며, 소스 보존·동일 테스트 비교와 아래 집중 검증이 근거다.

## 신규 SQL 목록과 권한 검증

A `home_configuration_revisions`: user_id/revision 복합PK, config_version=1, cards JSON 배열, updated_at. RPC는 read/save2개.
최대100카드/64KB, card_id 중복 금지, unknown ID 유지, 동일 payload 재요청은 revision 추가0, 다른 payload stale revision은40001.
read/save SECURITY DEFINER의 명시 owner/lifecycle 검사와 empty search_path를 사용한다. 테이블 직접 접근 권한은 anon/authenticated 모두 회수한다.
보완한 A의 RLS SELECT 조건에도 본인+lifecycle를 넣었지만, **실제 RPC는 definer이므로 RLS만으로 보호된다고 주장하지 않는다**.
서비스 역할은 운영 기본 권한을 상속하는 신뢰된 backend이며 앱에 노출하지 않는다. 이 후보로 service-role 권한을 다른 객체까지 바꾸지 않는다.

C `university_official_sources`: 대학/host 복합PK와 reviewed_at.
C `university_news_revisions`: series/revision unique, 대학·학년도·모집시기·전형·학과·scope,
kind/event_type/title, DATE 또는 timestamptz/precision/KST, 공식 URL/host/원본 SHA256/archive/locator,
게시·수정·확인·만료·생성 시각, verified/withdrawn. FK/시각/범위 CHECK, index2개, immutable trigger1개,
trigger function1개 + feed RPC1개. 기존 테이블 컬럼 추가0.
클라이언트 직접 읽기·쓰기 차단, 공개 공식 정보는 authenticated feed로만 제공한다. 개인 지원 데이터는 feed SQL에서 읽지 않는다.
series+revision은 중복 차단하지만 **다른 series_key로 같은 사실을 다시 넣는 중복은 막지 못한다**. D에서 공식 사실 식별/검수 manifest가 필요하다.

|격리 PostgreSQL17 검증|원본|보완 A|
|---|---|---|
|anon RPC, 두 client role의 직접 테이블 접근|차단 PASS|SELECT/INSERT/UPDATE/DELETE/TRUNCATE 차단 PASS|
|다른 계정 조회|null PASS|null PASS|
|RLS만 분리 검사(격리 transaction에서 임시 SELECT 허용)|다른 owner0행|본인1행, 다른 owner0행, 탈퇴 owner0행|
|동시 동일 설정 저장|revision1 한 번 PASS|동일 PASS|
|동시 다른 설정 저장|stale 거부 PASS|동일 PASS|
|DELETION_PENDING/ERASING read/save|실패: 접근 허용|차단 PASS|
|탈퇴 lock 대기 중 pending commit|미보호|대기 후 save 거부 PASS|
|Auth 없음/최종 삭제, cascade|기존 삭제 cascade PASS|누락·삭제 subject 거부/cascade PASS|
|권한 회수·재개|원본 파괴적 롤백은 사용 안 함|전체 row digest 동일, RPC 차단→재개 PASS|
|뉴스 원본 UPDATE 금지/최신 withdrawn|PASS|A와 무관|

이 검증은 local role/JWT subject 모사다. **운영 JWT·PostgREST·실계정 RLS E2E는 NOT TESTED**.
원본 반례와 수정 A 결과는 패키지 JSON 영수증 및 run_isolated.py로 재현한다.

## 홈 설정 저장·복원 검증

Flutter SDK3.47.6 stable, 동일 lockfile. 기존 집중93개와 새 캐시·계정별 서버 복원1개, 총 **94 PASS**, analyze **No issues found**.

|요구 시나리오|자동화 근거·결과|실계정/실기기 기능 E2E|
|---|---|---|
|신규 가입자 설정 저장|온보딩 명시 save→완료, 오류 후 선택 보존·재시도 PASS; SQL 처음 save revision1|NOT TESTED|
|온보딩 건너뛰기|홈 save 호출0, 기존 best-effort 완료/실패 처리 PASS|NOT TESTED|
|기존 회원 기본 홈|기존6개ON/새3개OFF, 미설정과 명시 기본값 구별 PASS|NOT TESTED|
|카드 표시·숨김|숨긴 provider 요청0·초기 조회 대기 중 요청0·전체OFF PASS|NOT TESTED|
|드래그 순서 변경|reorder/숨김 ID/unknown ID 보존·편집 렌더 PASS|실제 touch drag NOT TESTED|
|앱 재실행|새 cache/repository 생성 후 서버 복원·logout→b→a·불필요한 저장0 PASS|오프라인 앱 재실행만 PASS, 설정 영속 UI는 NOT TESTED|
|로그아웃·재로그인|auth 복귀 및 owner별 cache/provider 격리 PASS|운영 세션 복원 NOT TESTED|
|다른 계정 로그인|숨겨진 홈 탭 상태 a→logout→b, 과거 결과 제거 PASS|NOT TESTED|
|서버 조회 실패|기본 홈 복귀, 기존 캐시 덮어쓰기0, 미확정 저장 제한 PASS|실제 네트워크 장애 NOT TESTED|
|서버 저장 실패|선택 유지, 저장 성공 오표시0, 완료 실패 별도 재시도 PASS|NOT TESTED|

현재 운영에 새 RPC가 없으므로 신규 앱의 로그인 홈 저장은 아직 운영 연결 완료가 아니다.
A만 적용해도 일정 기능 C/D는 준비 중으로 남으며 카드 기본 OFF는 유지한다.

## 대학 일정 매칭 검증

|요구 시나리오|격리 Flutter 결과|
|---|---|
|희망 대학만|대학 공통 정보만, 관심 연도 없음은 연도무관 소식만 PASS|
|실제 지원만|대학·학년도·모집시기·전형·학과 정확 일치 PASS|
|둘 다 등록|같은 series 중복 제거, 양쪽 소속 유지 PASS|
|같은 대학 다른 전형|각 전형 정확 구분 PASS|
|같은 대학 다른 학과|division 범위 구분 PASS|
|공식 일정 없음|빈/미매핑/확인 중, 가짜 일정·D-Day 없음 PASS|
|일정 변경|최신 revision 우선·withdrawn 재등장 차단 PASS; **동시 적재 페이지 일관성 FAIL**|
|학년도 불일치|다른 연도 매칭 제외 PASS|
|KST 경계|날짜 전용/정확 시각/‘이후’/자정·기간 종료·만료 PASS|
|공식 링크 이동|widget에서 검증된 exact HTTPS URL 전달 PASS; 실기기 브라우저 도착·실제 공지 내용 NOT TESTED|

테스트는 합성 자료다. 실제 공식 일정 적재·실지원 데이터와 운영 매칭 건수는 검증하지 않았다.

### C 페이지 일관성 반례와 보완 방향

101개 공개 series를 먼저 commit한다. 그보다 앞에 정렬될 새 series1개를 별도 transaction에 INSERT하고 commit을 지연한다.
그 상태에서 page1은100개와 snapshot_at을 반환한다. 지연 transaction을 commit한 다음 같은 snapshot으로 offset100을 조회하면2개가 반환되고, 이전 페이지의1개가 중복된다. 새 앞쪽 series는 두 페이지 합계에서 누락된다.
같은 snapshot으로 page1을 다시 읽으면 새 series가 나타나므로 snapshot 불변 주장도 깨진다.

원인은 created_at default now()가 **transaction 시작 시각**이고 RPC 요청마다 MVCC snapshot이 달라지는 것이다.
[PostgreSQL 현재 시각](https://www.postgresql.org/docs/17/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT),
[Read Committed](https://www.postgresql.org/docs/17/transaction-iso.html#XACT-READ-COMMITTED)와 격리 반례가 일치한다.
clock_timestamp나 keyset만으로 최신 revision/철회 membership 전체의 불변성을 보장하지 않는다.

후속 후보는 완전히 commit된 발행 묶음의 불변 manifest에 series→revision 목록을 고정하고, 해당 publication ID로 모든 페이지를 읽는 방식으로 검토한다.
발행 전 원본/개정/철회 검수, 발행 시 원자적 포인터 변경, 긴 적재 commit·동시 정정·철회·페이지 경계 회귀가 필요하다.
긴급 철회 시 기존 publication 접근 처리와 보관기간도 확정해야 한다. 이번에 그 구조를 임의 생성하거나 운영 적용하지 않았다.

## 기존 FAIL5 — APP75 동일 조건 비교

APP75 실제 c9b4830을 새 임시 archive에 추출. 현재37eb530과 pubspec.lock 및 두 테스트 파일이 byte-identical임을 SHA256으로 확인했다.
양쪽 모두 같은 Flutter3.47.6/host, offline pub get, 아래 명령으로 실행했다.

```sh
./tool/flutterw test --no-pub --reporter json test/grade_runner_navigation_test.dart test/mobile_ia_render_test.dart
```

양쪽 결과 모두 **56 PASS / 5 FAIL / 0 SKIP**, 실패명·위치 동일. green으로 만들기 위한 기대값/채점 코드 변경0.

|실패|원인|작업04 관련성|
|---|---|---|
|D3 runner real routes restore history and do not resubmit|test81행에서 이미 없어진 ‘다시 학습으로’ Finder의 ensureVisible → No element. 점수2/6·draft null 확인 후 실패|APP75 동일 실패. 작업04 신규 회귀 아님. 이후 재제출 방지 assertion은 이 테스트에서 실행되지 못했음|
|mobile IA mock 360.0 1.0|365행 `mock-subject-국어` 없음. APP75 default official=true, 해당 dropdown은 자유 연습에서만 생성|동일|
|mobile IA mock 360.0 2.0|같은 Finder/기본 모드 불일치|동일|
|mobile IA mock 428.0 1.0|같은 Finder/기본 모드 불일치|동일|
|mobile IA mock 428.0 2.0|같은 Finder/기본 모드 불일치|동일|

기존 전체 suite 기록은37eb530에서2505 PASS/8 SKIP/5 FAIL. 이번04-B는 해당61개 양쪽 비교와 관련93개와 추가 복원1개를 실행했으며 전체 suite 재실행으로 과장하지 않는다.
학습 담당 후속은 새 navigation 의미/공식·자유연습 각 경로에 맞게 테스트를 고치고 재제출 방지 검사를 끝까지 실행해야 한다.

## 실기기 결과

- iPhone12 Pro Max: 기존 `com.legendstudy.app` **1.0.2(75)** 설치를 읽기 확인.
  별도 `com.legendstudy.app.task04b.offline` / 표시명 **LS04B Offline** /1.0.2(76) 설치·실행·프로세스 생존·재실행 PASS.
  현재37eb530을 /tmp에 추출하여 운영 키 없는 profile/no-codesign 빌드 PASS(55.2MB), 기존 wildcard 개발 profile로 분리 서명했다.
  앱 bundle ID/표시명/독립 keychain 변경, OAuth URL scheme 제거, Apple sign-in entitlement 없는 **오프라인 smoke artifact**다. Auth/서버 연결 검수 빌드가 아니다.
  별도 앱 설치 후 기존 APP75 버전75 유지 재확인. 기존 앱 삭제/업데이트/데이터 제거0.
- iPhone17 Pro Max: inventory에는 paired/available이나 실제 연결에서 CoreDevice4000 / connection reset. 설치·실행 NOT TESTED.
- Android: adb physical device0. 설치·실행 NOT TESTED. 이전37eb530 Android debug build PASS는 실기기 증거가 아니다.
- 실계정 홈 동기화/실제 drag/공식 외부 링크/실데이터 뉴스 E2E는 NOT TESTED. launch/process 확인을 화면 검수 PASS로 대신하지 않았다.

## A·B·C·D 적용 순서·검증·원복

1. **사전 공통**: 이 보고서와 대체 A를 Owner 검토. preflight SELECT 재실행, 동명 객체·live hash drift·migration owner·기존 ACL/policy 증거 확보. 합성 fixture 운영 실행 금지.
2. **A만 별도 승인 시**: 패키지 apply_a_home.sql 한 transaction. 기존 combined candidate 실행 금지.
   verify_a_readonly.sql: 초기에0행, RLS/권한/유효성/중복 확인. 기존 B 정의·정책 불변 대조.
   승인된 별도 계정·빌드에서 실제 저장/복원·계정전환을 Owner가 검수. 기존 APP75 유지.
   실패 시 transaction rollback, 커밋 후 장애는 disable_a_home.sql로 client RPC만 중단. 데이터는 보존.
   원인 해결·승인 후 restore_a_home.sql 및 동일 SELECT 재확인.
3. **B**: 이미 운영에 존재. 신규 SQL0. existing my_* API의 signature/ACL/hash를 유지하고 별도 승인된 계정 검수로 create/update/event/retry를 확인한다.
   앱 롤백 시 기존 APP75로 돌아가며 공유 RPC/지원·결과 기록을 DROP/삭제하지 않는다.
4. **C**: publication 일관성 후보·검증 완료 후 별도 승인. A와 독립 transaction으로 새 구조를 적용하고 데이터0에서 권한/DTO/페이지 계약 확인.
   장애 시 feed EXECUTE 회수 + 적재 중지, 이력/원본 보존. 현재 원본 C는 적용 대상 아님.
5. **D**: C 완료 후에만 검수된 대학/학년도/전형/학과의 작은 명시적 발행 묶음을 별도 승인.
   공식 입학처 host 소유, 최신 모집요강·변경 공지 원본, SHA/archive/locator, 정확도(date/exact/after), 확인·만료 기준을 원본과 대조한다.
   manifest의 series/revision 중복·같은 사실 재발행·다른 전형/학과 누락·연도 불일치 검증 후 원자 발행.
   verify_c_readonly.sql + read RPC 결과 및 앱 exact match 검수. 오류는 같은 series의 새 withdrawn/정정 revision으로 복구; 원본 UPDATE/DELETE0.
   과거에 조사한 서울대 안내/모집요강 링크는 후보 근거이며 운영 seed 승인이나 최신 전체 공지 검수 완료를 의미하지 않는다.

완료 시 DB migration 기록과 Wiki 상태는 **실제 적용 영수증 후** 갱신한다. 파일 존재로 운영 적용을 추정하지 않는다.

## 보존 검토와 Owner 승인 항목

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의7항과 [MY 공통 기반](my-shared-foundation.md)의 lifecycle 규칙을 재검토했다.

1. UI 선택, 지원 Decision, 결과 Outcome, 공식 발표 사실의 발생/게시/수정/확인/수집 시간을 분리한다.
2. 설정 revision 및 공식 archive/SHA/locator를 보존하고 원본을 최신 화면으로 덮어쓰지 않는다.
3. 새 설정/정정은 append; display/latest는 파생 결과다. D 공개는 불변 publication 설계가 추가로 필요하다.
4. 기존 auth.users identity 유지. 학년/학교 변경이 기록 주체를 바꾸지 않는다. 탈퇴 pending 접근 차단·최종 삭제 cascade 적용.
5. 희망/실지원/결과/학습을 서로 변환하지 않는다. 대학 소식 조회로 지원/합격 상태를 자동 기록하지 않는다.
6. 본인 설정과 공개 공식 자료만. 새로운 수집/학생 analytics/외부 제공/장기 개인자료 보존 승인 없음.
7. D-Day/정렬/매칭은 파생 표시이고 원점수/학습시간/원래 D-Day·Outcome에 저장하지 않는다.

기존 [홈 정책](home-personalization-and-events.md)·[작업04 Owner 결정](task04-home-university-news-20261111.md#복원기준기존-결정-최종-보고-14)을 이어가며 새 제품 정책을 임의 승인하지 않았다.

**요청 승인 범위:** 보완한 A의 table1/RPC2/policy1 생성 + 읽기 전용 사후 확인만. B 유지, C/D 보류, 운영 WEB/릴리스 병합/스토어 제외.
별도 테스트 계정의 운영 쓰기·실기기 동기화 검수 범위는 A 승인 시 명시하고, 승인 없는 기존 사용자 기록을 테스트용으로 수정하지 않는다.
C/D는 페이지 일관성 보완·공식 자료 manifest·검수 책임/주기·원본 보관/긴급 철회 정책을 확정한 다음 다시 승인받는다.

공식 권한 기준: [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security),
[Database Functions](https://supabase.com/docs/guides/database/functions).
SDK/CLI changelog를 확인했으며 이번 검토에서 패키지·CLI 버전 업그레이드는 하지 않았다.
