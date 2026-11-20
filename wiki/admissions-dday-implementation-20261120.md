# 수시 지원 일정 → D-Day 구현 — 2026-11-20

상태: **로컬 구현·검증 완료 / 운영 DB 설치·seed·초기 동기화 PASS / WEB 운영 확인 후속**. [기존 조사](admissions-dday-linkage-research-20261120.md)를 구현 기준으로 사용했다. Owner의 후속 지시로 이벤트 유형을 논술·면접·실기·1단계 발표·최초 발표·등록 마감·기타 공식 일정까지 지원한다. 논술 문제/자료 신규 등록은 이번 범위가 아니다.

처음 승인은 코드·격리 검증·Wiki·Commit/Push까지였다. **후속 Owner 승인**으로 기준 `6cd4c1a7`의 운영 DB 설치/공식 seed/기존 수시 초기 연동을 2026-11-20 적용했다. WEB은 DB gate 이후 별도 배포·화면 확인 단계다. Flutter 코드는 별도 APP 업데이트가 필요하며 WEB 배포로 스토어 앱이 바뀌지 않는다.

## 구현 결과

| 영역 | 구현 |
|---|---|
| DB 후보 | 공식 일정 현재값+불변 revision, 지원 연결, 학생 상태/삭제 기억, 작업 이력. 기존 `day_targets` 열은 변경하지 않는다. |
| 매칭 | 대학 UUID/학년도/수시/명시적 전형 별칭/모집단위. 공백·대소문자 정규화만 허용하고 유사도/날짜 추정은 없다. 캠퍼스가 충돌하는 범위 공개를 거부한다. |
| 동기화 | 지원 추가/수정/삭제 trigger, 공식 일정 save/publish, 학생 화면 진입. 동일 owner/event unique와 계정 잠금으로 중복 방지. |
| 삭제·복원 | ACTIVE/DISMISSED/CANCELLED. 학생 삭제는 즉시 projection 제거, source revision·지원 삭제/재등록에도 DISMISSED 유지. 명시적 복원만 최신 공식 날짜로 재생성. |
| 구버전 APP | 직접 `day_targets DELETE`도 삭제 의사 기록. 자동 날짜/제목의 직접 UPDATE 차단, 수동 CRUD 유지. 대표 지정은 원자적 RPC 추가. |
| WEB 관리자 | `/admin/admission-schedules/`: 대학/학년도/캠퍼스/전형/모집단위/유형/날짜·시간/출처/검수/공개 등록·수정. 기존 AdminSurface/nav와 서버 관리자 helper 사용. |
| WEB 학생 | MY 입시 D-Day: 자동 일정·삭제/복원, 공식 출처, 지원 저장 이후 갱신. 내부 검토 메모/상태 코드는 학생에게 노출하지 않는다. |
| Flutter | 기존 Home 대표1+가까운2+더보기/접기 유지. 관리 sheet의 입시 배지·출처·삭제/복원/새로고침. 공식 날짜 편집을 차단하고 수동 추가/수정/삭제 보존. |

새 수시 지원 **헤더 저장 자체**가 연동 입력이다. 조사 단계의 ‘submitted 이후만’은 당시 권장안이었고, 이번 Owner의 등록 즉시 연동 요구에 맞춰 별도 상태 입력을 요구하지 않는다. 관심 대학을 지원으로 바꾸거나 기존 지원 상태를 변경하지 않는다. 정시는 전부 제외한다.

## 공식 일정 검토와 실제 14건의 예상 연결

[승인 대상 seed](../supabase/candidates/admissions_dday_20261120/reviewed_schedules.json)에 **15개 공식 일정/검수 후보**를 준비했다. 공개 후보는 10개(논술4+최초발표6), PENDING은5개다. 이는 공식 사건 수이며 학생 연결 수와 다르다.

| 대상 | 검토 결정 |
|---|---|
| 아주 기계공학과 논술 12/5 | 공식 계열·모집단위와 논술우수자 표 대조, VERIFIED 공개 후보 |
| 인하 기계공학과 논술 12/6 | 자연계 모집단위·논술우수자 표 대조, VERIFIED 공개 후보 |
| 고려 국제학부 논술 11/22 | 모집단위 직접 명시, VERIFIED. 입실08:30을 시험 시작 시각으로 저장하지 않음 |
| 서강 경제학과 논술 11/22 | 모집단위 배정표·시험19:00 대조, VERIFIED |
| 최초발표 근거11건 중8건 | 아주1·인하1·고려2·서강2·한양1·연세1. 대상이 명확한 범위를 승인 후보로 포함 |
| 최초발표 근거11건 중3건 | 중앙 세부 기회균형/서강 학교장추천 명칭 미확정, 이화는 논술유형 확인 전 자동 등록 금지라는 최신 Owner 결정에 따라 PENDING |
| 이화 논술 | 선택 유형 확인 전 PENDING, 학생 화면에 미노출 |
| 서울과기 논술 | 최신 공식 날짜/선발 계열 미확인. 날짜 NULL·PENDING, 학생 화면에 미노출 |
| 국민 계획 / 서울대 정시 | 국민은 전형·모집단위 불명확으로 매칭 없음, 서울대 정시는 대상 제외 |

**2026-11-20 21:23 KST 운영 read-only CTE 검증** 당시 원래 지원14건 그대로, 공개 후보가 연결되는 지원8건, 지원–일정 연결12건(논술4+최초발표8), owner/event 중복 제거 후 **D-Day12개 생성 예상**이었다. 이후 승인된 초기 연동으로 실제 **12개 생성/중복0**을 확인했다. PENDING 연결5개는 생성 대상이 아니다. 합격자 발표의 전형 공통 사건은 같은 학생의 여러 지원에 하나의 카드로 연결하지만, 서로 다른 학생의 카드를 합치지 않는다. [조사 집계](evidence/admissions-dday-implementation-20261120.json) · [실제 설치 영수증](evidence/admissions-dday-production-20261120.json).

11/20 발표(연세)는 당일 기준으로만 초기 생성 대상이다. 승인/적용 시점이 지나면 과거 일정을 새로 생성하지 않으므로 이 숫자를 고정 운영 기대값으로 사용하지 않는다. 기존에 생성된 일정이 지난 날짜가 되는 것은 기존 D-Day 과거 표시 계약을 따른다.

공식 URL/PDF 페이지/SHA256 및 조건은 [조사 원문 근거](admissions-dday-linkage-research-20261120.md#공식-근거)와 seed에 연결했다. 미확인 면접·실기·등록 마감 날짜는 데이터로 만들지 않았다. **7종 유형을 구현한 것과 7종의 모든 일정을 확보한 것은 다르다.**

## 보존 검토와 실제 설계 조정

조사 문서의 [일곱 보존 검토](admissions-dday-linkage-research-20261120.md#저장-설계-전-일곱-보존-검토)를 구현에 적용했다.

1. `event_date/time`, 원문 검수/게시 revision 시각, 학생 작업 시각 분리. KST 달력 날짜 기준.
2. 공식 URL/hash/page/note와 전체 일정 snapshot, application revision 및 명시적 매칭 근거 보유.
3. 공식 정정은 revision INSERT. revision/action UPDATE·DELETE는 방어 trigger로 거부하며 계정 삭제 때 reviewer 비식별/학생 작업 이력 삭제만 허용한다. Home projection UPDATE는 원본 변경이 아니다.
4. 기존 profiles/Auth UID와 owner RLS/lifecycle lock 재사용. 별도 학생 identity 없음.
5. 지원 Decision과 일정 fact/표시를 분리. 자동 accepted/rejected/응시 이벤트 생성 없음.
6. 신규 학생 식별정보·자격 증빙·수험번호 수집 없음. 개인 상태/action은 계정 lifecycle에 종속되고 공개 일정과 분리한다.
7. 매칭/D-n/카드 수는 파생값. 정규화 규칙 버전과 입력 revision 기록, 불명확 후보는 PENDING으로 유지한다.

실제 코드와의 조정: 운영 `my_application_save`에는 원래006 migration 이후 추가된 semantic duplicate 방어가 있었다. 이를 삭제하지 않고 **읽기 확인한 정확한 현재 함수에 catalog shared lock 한 줄과 설명만 추가**했다. 기존 함수의 `pg_get_functiondef` MD5가 예상값과 다르면 설치 전체가 중단된다. 원본/새 signature·권한·반환값은 유지한다.

## 자동 동기화와 동시성 계약

- `application_schedule_links`: UNIQUE(application,event), 당시 지원/공식 revision과 MATCHED/PENDING.
- `student_schedule_preferences`: UNIQUE(owner,event), day_target unique, ACTIVE/DISMISSED/CANCELLED, `ever_activated`. application 삭제 cascade는 연결만 지우고 개인 삭제 기억은 남긴다.
- 학생 화면 RPC는 아직 한 번도 공개·생성되지 않은 PENDING 후보를 반환하지 않는다. 이전에 표시되던 공식 일정이 비공개/철회되면 CANCELLED와 설명을 반환한다.
- 모든 개인 동기화/삭제/복원은 기존 계정 advisory lock을 사용한다. 기존 직접 DELETE도 statement 단계에서 잠근 후 row를 삭제해 RPC와 잠금 순서를 맞춘다.
- 공식 일정 게시자는 catalog exclusive lock을, 지원 저장은 **계정 잠금 전에** 같은 catalog shared lock을 사용한다. 동시에 새 지원과 새 공개가 생겨 서로 미커밋 데이터를 놓치는 경합을 실제 PostgreSQL 테스트에서 발견·수정했다.
- 공식 일정 수정은 stable event ID를 유지한다. 대학/학년도/캠퍼스/유형 identity 변경은 거부한다. 같은 범위의 새 UUID로 공개해 학생 삭제를 우회하는 행위도 거부하며 기존 일정을 편집해야 한다.
- 관리자 게시와 연결 갱신은 같은 트랜잭션이다. 현재 규모의 동기 처리를 재사용하며 신규 Worker/외부 큐/크롤러는 만들지 않았다. 화면 진입도 같은 멱등 경로로 복구한다.
- 공식 사이트 자체의 변경 탐지는 이번에 자동화하지 않았다. 관리자가 공식 변경을 검증·게시하면 연결된 학생 일정은 자동 갱신된다.

## DB 패키지와 RPC

후보 디렉터리: [admissions_dday_20261120](../supabase/candidates/admissions_dday_20261120/README.md). migration chain에 승인 전 SQL을 넣지 않으며, 적용 후 검증된 파일만 정식 이력으로 승격한다.

| 파일 | 실행 범위 |
|---|---|
| [preflight.sql](../supabase/candidates/admissions_dday_20261120/preflight.sql) | SELECT 전용: 충돌·기존 save 함수·기존 데이터 count/digest |
| [install.sql](../supabase/candidates/admissions_dday_20261120/install.sql) | 신규 private schema/5 public tables/RLS/RPC/trigger, 기존 save의 잠금 보완. 기존 개인 행 백필 없음 |
| [seed_reviewed.sql](../supabase/candidates/admissions_dday_20261120/seed_reviewed.sql) | 공식 일정15행만 신규 등록, 재실행 동일성 검증·drift 거부 |
| [activate_existing.sql](../supabase/candidates/admissions_dday_20261120/activate_existing.sql) | 별도 명시 단계: 현재 수시 지원의 생성 가능한 자동 D-Day만 추가 |
| [postflight.sql](../supabase/candidates/admissions_dday_20261120/postflight.sql) | SELECT 전용: RLS/ACL/연결/중복/기존 원본·수동 행 digest 대조 |
| [rollback.sql](../supabase/candidates/admissions_dday_20261120/rollback.sql) | 승인된 원복 시 공식 공개 중단·자동 projection 제거, 기존 save 복구. evidence/삭제 기억은 보존하고 수동/지원 데이터는 유지 |

RPC: `my_admission_day_events()`, `my_admission_day_event_action(event_id,action,expected_revision,request_key)`, `my_set_primary_day_target(id)`, `admin_admission_schedules()`, `admin_admission_schedule_save(id,expected_revision,request_key,schedule)`.

관리자 API는 기존 `admin_operator()`와 계정 상태를 서버에서 검증한다. anon/PUBLIC 실행 금지, private 함수 실행 금지, 학생은 owner만 조회/관리한다. VERIFIED는 날짜+공식 HTTP(S) URL+검수 설명을 필수로 요구하고 SHA256/page는 HTML 공지 등을 위해 선택값이다. URL 형식 검사가 공식성 자동 판별을 대신하지 않으며 관리자의 실제 원문 검수가 필요하다.

## 검증 결과와 한계

- Flutter: SDK3.47.7, 신규+기존 D-Day **59 tests PASS**, 변경7파일 analyze PASS. 360px/확대2배 widget 검증, guest/auth 전환/수동 CRUD/삭제·날짜변경·복원/멱등 재시도/원자적 대표 지정 포함.
- PostgreSQL: 실제17.11 격리 인스턴스, NOSUPERUSER postgres 설치·authenticated/anon 역할, 실제 기존 지원 RPC+캡처한 현재 save 사용. **46/46 PASS**. 동시 등록/공개·동일 요청키·구버전 삭제·권한/타인·불변 이력·계정 삭제·seed 멱등성/drift 거부·정확한 원복 포함. 14개 합성 헤더를 한 소유자로 묶은 fixture에서는 12연결→10카드이며 운영 read-only 예측12카드와 소유자 구성이 다르다. [SQL hash/영수증](../supabase/validation/admissions_dday/result.json).
- WEB: 관련69검사 PASS, 전체2210 PASS/5 SKIP(284파일 PASS/4 SKIP). TypeScript·변경 파일 ESLint·171경로 production static build PASS. 임시 mocked RPC 화면에서 390px 모바일 넘침 없음, 학생 삭제/복원·관리자 비공개 초안/날짜 정정 확인. 임시 route/export 제거 후 최종 빌드했다.
- 기존 WEB boundary 검사에는 변경하지 않은 `payment-checkout.tsx`의 테스트 결제 문구와 `admin-members-view.tsx` write-call 규칙 위반2건이 남아 있다. 두 파일 및 검사 스크립트가 HEAD와 바이트 단위 동일함을 확인했다. 이번 입시 일정 항목의 오류는 없지만 전체 boundary 검사 PASS로 표시하지 않는다.
- 운영 학생 데이터를 테스트 fixture로 쓰지 않는다. 후속 승인된 신규 설치/seed/자동 projection 생성만 수행했고, 운영 검증은 READ ONLY 역할·RLS 검사와 기존 데이터 hash 비교를 사용했다. 실제 학생 일정의 삭제·복원·날짜 정정은 실행하지 않았다.
- **운영 DB 설치·seed·초기 동기화·기존 데이터 보존·DB 역할 검증은 PASS**. 운영 PostgREST/브라우저 E2E와 WEB 배포는 별도 확인하며 Flutter 실기기/스토어 릴리스는 NOT TESTED/NOT DEPLOYED다. 격리 UI/DB PASS를 운영 화면 PASS로 표시하지 않는다.

## 운영 DB 적용 — 2026-11-20 Owner 승인

프로젝트 `stlhijzpjfgwwdgunlsd` / LegendStudy / 서울 / ACTIVE_HEALTHY 확인 후 적용했다. 승인 기준 APP/SQL HEAD는 `6cd4c1a7fc320b9f9378c9100e6988f390c2481c`. 설치 SHA256 `f56ac57b9644d9487a25d49ed71c3ffa80b90df5b9ccde50fcf91a1f5d482e11`가 최종 46검사 영수증과 일치했다.

1. preflight: 기존 save MD5 일치, 신규 schema/table/RPC 충돌0. 지원14·지원이력30·수동 D-Day142·Essay 시험478.
2. `apply_migration`으로 **20261120124053 / admissions_dday_20261120** 적용. 설치 직후 개인 projection0, 기존63테이블 count/hash 동일.
3. 공식 seed15행을 원문과 전필드 대조: VERIFIED 공개10 / PENDING 비공개5. seed 직후 개인 projection0, 기존63테이블 count/hash 동일.
4. 별도 `activate_existing.sql` 실행: 지원8건 매칭·자동 D-Day12·중복0. 원래 지원14/이력30/수동142는 전체 행 hash 동일.
5. 결제 주문22/operations13/events49·Credit accounts853/grants866/ledger969, Essay/Math/운영 private 원장을 포함한 **63테이블의 기존 행 count/hash 불변**. Finance 역할·membership·테이블 ACL·결제 RPC 본문/ACL도 동일했다. 실제 결제/환불/첨삭 실행0.
6. 실제 DB READ ONLY + authenticated/anon 역할 검증: 관리자 목록15 허용, 일반 회원 관리자 목록/save 거부, 타인 preference/day_target 노출0, private schema와 직접 공식 일정/상태 쓰기 불허, anon 신규 RPC 거부.
7. 배포 함수15개의 `prosrc` MD5가 테스트 installer의 원문과 전부 동일. Supabase migration에 저장된 전체 SQL MD5 `a6671110b3112ece78c088dfc57288b1`도 로컬 원문과 동일했다. 삭제·복원·날짜 변경·동시성의 운영 학생 조작 검사는 하지 않았으며, 격리46PASS + 배포 본문 일치로 확인 범위를 명시한다.

신규 Security advisor는 의도된 접근 구조에 대한 INFO4/WARN5다. 직접 접근을 거부하는 네 테이블의 [RLS no-policy](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), 서버 owner/admin 검증을 수행하는 다섯 RPC의 [authenticated SECURITY DEFINER](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) 알림이다. 신규 ERROR/예상 밖 권한 확대는 없고 Finance 역할은 불변이다. 접근을 열어 경고를 없애지 않았다.

[운영 영수증](evidence/admissions-dday-production-20261120.json)에 비밀·학생 UUID 없이 검증값을 저장했다. 정식 이력은 [20261120124053_admissions_dday_20261120.sql](../supabase/migrations/20261120124053_admissions_dday_20261120.sql)이며 설치 원문과 동일하다. CLI 빈 파일의 생성 시각124459를 원격 실제 적용 시각124053으로 정정했고 중복 pending 파일은 남기지 않았다. seed/activation은 승인된 별도 데이터 작업으로 영수증에 기록한다.

## 운영 적용 승인 경계

[AGENTS §4](../AGENTS.md#4-supabase-policy)의 기본 절차에 따라 SQL 패키지·검증·원복을 먼저 제공했다. 후속 Owner가 **해당 프로젝트의 준비된 SQL 설치·공식15건 seed·기존 수시 초기 연동·gate 통과 후 WEB 배포**를 명시 승인해 위 DB 단계까지 완료했다. 같은 승인을 다시 요청할 필요는 없다. APP 스토어 출시와 기존 학생 답안/수동 일정/지원 원본 변경은 승인 범위 밖이다.

승인 뒤: 프로젝트/SQL hash 재확인 → preflight → install → seed → activation → postflight/권한 회귀 → WEB 배포·실화면 검증. 실제 결제/환불/원장/Essay 평가 실행은 범위 밖이다. APP는 별도 기기 QA/버전 빌드/스토어 출시 절차로 구분한다.

Owner가 직접 SQL을 실행하는 경우 같은 순서의 출력 영수증을 대조한다. 예상하지 못한 기존 원본/수동 데이터 변경·권한 확대·함수 preimage 차이가 나오면 적용/배포를 중단한다. soft rollback은 제한 계정의 lifecycle을 우회하지 않으며 해당 계정의 접근 불가능한 데이터 정리는 기존 탈퇴 절차에 맡긴다.

## 검증 재현과 Git 인계

Flutter: `flutter test --no-pub test/admission_day_event_test.dart test/day_event_test.dart test/day_target_test.dart test/day_target_persistence_test.dart` (SDK3.47.7). 변경7파일 `flutter analyze --no-pub`도 PASS. DB는 [격리 실행 README](../supabase/validation/admissions_dday/README.md)를 따른다. WEB은 관련69검사와 전체 suite를 구분하며 skipped5개를 실행 성공에 포함하지 않는다.

Wiki routing/내부 링크/12KB restore budget 검사와 diff 검사를 통과했다. 기존의 다른 작업 수정은 보존하고 이번 기능과 조사 증거만 Commit/Push한다. 운영 배포 및 APP 출시 승인을 뜻하지 않는다.

WEB 구현 commit: `76e24b44266f5d4156952b11ad28845a5f4bb5bc` (`codex/lab-admin-operations-20261114`). APP/SQL/Wiki는 `codex/material-service-app-20261022`에서 이번 파일만 별도 기록한다. 구현 Commit/Push 당시 운영 설치·배포0이었으며 후속 DB 승인·적용 결과는 위 절을 따른다.

Push 전 현재 Cloudflare Pages 설정을 read-only 확인했다: Production branch는 `main`, 이 codex branch는 자동 Preview 빌드 대상이다. Git Push와 운영 배포를 구분한다. 이번에는 운영 설정/Secret을 바꾸지 않았고 Production 기준은 `e84b1232-4991-49ef-81e0-32cdefc137ec`다. Git 연동 Preview가 생성되더라도 운영 DB 적용/운영 검증으로 표시하지 않는다.

WEB Push 완료 후 read-only 재확인: Production은 위 기준 그대로이며 branch Preview `faeb2403-82d2-4f68-b2fb-c554731faa3d`가 새 commit으로 빌드 중이었다. Preview 브라우저 접속/학생 DB 호출은 하지 않았다.

## WEB 운영 배포·화면 확인 — 2026-11-20

DB gate PASS 뒤 source `76e24b44266f5d4156952b11ad28845a5f4bb5bc`를 Pages `624664a1-c22b-49a3-9c47-9d656dd95449`로 배포했고 canonical success를 확인했다. 관리자 root/새 일정 관리/MY account 15파일과 신규자산25개만 반영, 기존3107파일·Pages Worker·routing·bindings·전체환경설정 보존. Toss LIVE/Finance Automatic 유지. [WEB 영수증](evidence/admissions-dday-web-deployment-20261120.json).

실제 Owner 세션에서 관리자 일정15건·아주12/5 수정 화면·변경불가identity를 확인했다(저장하지 않음). MY 신규영역은 정상로드했고 해당Owner의 연결일정은0건으로 빈상태를 확인했다. 대상학생 계정을 대리 로그인하거나 지원을 추가하지 않았다. 대상학생12개 카드의 개별 브라우저 표시와 일반학생 브라우저 관리자차단은 NOT TESTED이며, 실제DB 생성12개·본인/타인RLS·일반회원관리자RPC차단 검증과 구분한다. 기존학생삭제/복원/날짜변경은 운영에서시험하지 않았으며 격리46검사+배포함수동일성으로 검증했다. Flutter59검사 통과 코드 준비, 실기기·스토어제출은 이번범위 밖이다.
