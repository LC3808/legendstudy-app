# TASK10 — 관리자 통합 분석·품질 검수

## 범위와 보존 검토

Owner 2026-11-01 지시. TASK09-B 베타 브랜치 및 TEST Preview를 보존하고 별도 `codex/admin-analytics-task10-20261101`에서 작업한다. 운영 적용은 별도 승인 대상이다.

[장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의 일곱 질문:

1. 발생 시각과 기록 시각을 구분한다. 집계 기간은 KST, 품질 정정은 새로운 판단으로 기록한다.
2. 평가 당시 원본·Package digest·학생 답안·기존 피드백은 불변이다. 집계 UI가 원장을 수정하지 않는다.
3. 기존 판정/만족도를 새 점수로 UPDATE하거나 환산하지 않는다. 신규 계약은 기존 행과 구분하고 정정 이력을 보존한다.
4. 기존 auth.users/평가 run·question 및 feedback_id를 사용한다. 별도 사용자 원장이나 행동 수집 체계를 만들지 않는다.
5. 학습 사실, 운영자의 품질 판단, 학생 만족도는 서로 다른 사실이다. 만족도는 평가 점수나 입시 결과가 아니다.
6. 기존 관리자 권한과 사용자 소유권을 유지한다. 답안·OCR·위치 원문을 Analytics로 전송하지 않는다. 원장 보존 정책을 이번 작업에서 확대하지 않는다.
7. 출처·DTO 버전·통화·시간 범위·미연결/미상 여부를 표시한다. GA4 방문자와 서버 활성 학습자를 구분한다.

## 현재 구현

WEB 기존 `/admin/analytics/` placeholder를 기존 Analytics v1 RPC 소비자로 연결한다. 기존 AdminSurface/AdminGate, 공식 admin_operator/account_allowed 계약을 재사용한다. KST 기간 400일 제한, 로딩/오류/미설치/실제 0/UNKNOWN 구분, 계정 전환 시 이전 결과 제거. 비용은 ACTUAL·ESTIMATED·UNKNOWN, 매출은 LIVE·KRW payment_orders 범위와 Credit 예약 해제/환불을 분리한다.

품질 `/ql/`, 실제 답안 `/owner-review/essay/`, 베타·피드백·모니터링 기존 페이지로 연결한다. 새 대시보드/이벤트 원장을 만들지 않는다.

## 확인된 계약 차이와 남은 작업

- GA4 서버 보고서 인증/속성 연결 및 실수신 미확인. 스크린샷 수치는 Fixture나 운영 KPI로 복제하지 않는다.
- 기존 HQP는 legacy essay_evaluations 참조 및 판정형 rubric이며 현대 exam run/question과 직접 호환되지 않는다. 6개 1~5점은 기존 판정을 환산하지 않고 승인 후보 확장이 필요하다.
- 기존 피드백은 helpful/unhelpful 이진값이다. 1~5점 평균을 이진값에서 생성하지 않는다.
- 현재 대학별 집계는 legacy 문항 세션과 exam 회차를 함께 집계하므로 고유 사용자 순위로 이름을 바꾸지 않는다.
- 퍼널은 가입 코호트의 이후 전체 기간 단계별 도달 수이다. 익명→가입 연결 및 순차 퍼널이 아니므로 단계 전환율을 임의 생성하지 않는다.

## 검증 기록

단계별 진행: Phase A 기존 화면 연결 구현, Phase B GA4 연결 대기, Phase C 6개 수치 검수 미구현, Phase D WEB 선택형 만족도/SQL 후보 구현·APP 미구현, Phase E 기존 집계 표시만 구현. TASK10 전체 완료 또는 출시 준비 완료가 아니다.

WEB `37850ec`: 전체 1492 PASS / 4 SKIP (208 files PASS / 3 SKIP), TypeScript PASS, Production Build PASS, Lint 0 errors / 기존 5 warnings. 신규 analytics/feedback 계약 17 PASS. 실브라우저 반응형·실계정 DB 수신·모달 실기기·GA4 Data API 수신은 NOT_TESTED/BLOCKED로 남긴다. Flutter 소스 변경 없음; 이번 단계 Flutter 테스트 미실행.

격리 PostgreSQL localhost:55439 `task10_feedback_atomic`: TASK05 fixture/base → 만족도 확장 단일 transaction → 신규/기존 계약 테스트 → ACL postcheck → rollback → 기존 계약 재검증 PASS. Auth/admin stub 기반이며 운영 권한 인증 PASS로 간주하지 않는다. authenticated만 execute, anon/service_role 차단, SECURITY DEFINER 및 빈 search_path 확인. 테스트 데이터는 synthetic이고 운영 데이터와 무관하다.

운영 DB/Worker/Provider/Credit/History 및 TASK09 Preview 변경 없음. APP 기존 build33 유지; 신규 빌드/배포 없음.

## GA4 두 속성 조회 — Owner 결정 및 확인 (2026-11-01)

Owner는 기존 레전드스터디닷컴과 LAB 전용 GA4를 모두 조회하도록 확정했다. 기존 속성 데이터·설정은 보존하며, LAB 속성이 있으면 재사용한다. 연결 작업은 베타 출시의 선행 조건이 아니다.

읽기 전용 Chrome 확인: `레전드장` 계정 **47366112**, `레전드스터디닷컴 - GA4` 속성 **396674471**. 현재 계정 목록 및 접근 가능한 속성 검색에서 `LAB`, `LegendStudy`는 결과가 없고 `레전드`는 기존 속성만 표시됐다. 이는 현재 로그인 계정에서 LAB 속성이 발견되지 않았다는 뜻이며, 다른 계정/권한 아래 속성이 없다는 증거는 아니다. 속성/스트림/권한/태그를 생성하거나 수정하지 않았다.

### 연결 절차 (Owner 또는 해당 GA4 관리자)

1. LAB 소유 계정의 GA4 관리 → 속성 세부정보에서 숫자형 **속성 ID**를 확인한다. `G-...` 측정 ID, Firebase 프로젝트 ID와 다르다. 기존 속성은 `396674471`; LAB ID는 아직 미확인이다.
2. LAB 속성이 다른 계정에 존재한다면 기존 속성을 재사용하고 읽기 접근을 부여한다. 모든 소유 계정에서도 없다면 **신규 LAB 속성 생성 승인**이 필요하다. 생성 후보는 보고 시간대 Asia/Seoul, 통화 KRW; 기존 속성 설정은 변경하지 않는다. 웹 스트림과 기존 Firebase 프로젝트의 앱 연결 여부를 먼저 확인한다.
3. 승인된 서버 실행 환경의 Google Cloud 프로젝트에서 Analytics Data API를 활성화하고 전용 서비스 계정을 사용한다. 두 GA4 속성 각각의 관리 → 속성 액세스 관리에서 해당 서비스 계정 이메일에 **Viewer(뷰어)** 권한만 부여한다. 실제 보고서 조회에는 `analytics.readonly` 범위를 사용한다. 사용자 브라우저 로그인 성공은 서버 읽기 연결 완료가 아니다.
4. 서버 비밀 저장소에 자격 증명을 보관한다. 비밀 키 JSON/토큰을 채팅·Git·NEXT_PUBLIC 환경변수·Flutter define에 넣지 않는다. 가능하면 실행 환경의 단기 자격 증명을 사용한다. 숫자 속성 ID는 서버 허용 목록으로 고정하고 클라이언트가 임의 속성을 질의하게 하지 않는다.
5. 기존 관리자 권한 검증을 통과한 요청만 서버 보고서 어댑터로 전달한다. 현재 WEB은 static export이므로 브라우저에 Data API 비밀을 추가하지 않는다. 서버 어댑터 배포는 별도 운영 승인 대상이다.
6. 각 속성의 연결 시험(runReport)과 실시간 조회(runRealtimeReport)를 별도로 검증한다. 권한 실패/미연결/빈 결과/집계 지연을 구분한다. GA4 화면 열람은 이 어댑터의 실수신 PASS가 아니다.

### 지표와 연결 경계

- 기존 사이트: 방문·페이지뷰·검색/게시글·실제 배너 노출/클릭·LAB/스토어 이동. 배너 이벤트가 없으면 노출·CTR은 NOT_AVAILABLE.
- LAB: 방문·행동·유지율은 GA4, 실제 평가 완료·Credit·결제 매출은 기존 PostgreSQL 원장을 기준으로 한다.
- 두 독립 속성의 사용자 수를 더해 고유 방문자로 표시하지 않는다. 익명 방문→가입 연결이 없으면 연결 불가 구간을 명시한다. UTM/외부 이동 클릭과 실제 가입·설치는 서로 다른 사실이다.
- Google cross-domain 측정은 동일 웹 스트림/태그 ID를 사용하는 도메인 간 측정이다. 두 독립 속성 조회만으로 자동 연결되지 않는다. 기존 데이터를 보존하는 측정 설계와 Owner 승인 후 설정한다. 현재 교차 서비스 퍼널 및 앱 설치 완료는 미검증이다.
- APP/WEB 기존 Analytics v1 이벤트 수집을 재사용한다. 새로운 행동 이벤트 원장을 만들지 않는다.

공식 참고: [Data API 시작](https://developers.google.com/analytics/devguides/reporting/data/v1/quickstart), [속성·스트림 설정](https://support.google.com/analytics/answer/9304153?hl=en), [교차 도메인 측정](https://support.google.com/analytics/answer/10071811?hl=en).


## 만족도 확장 후보와 복구

[SQL 후보](../supabase/candidates/analytics_quality_task10/README.md). 기존 feedback 원장/context와 제출 RPC를 확장한다. 수치 1~5와 이진 만족도는 상호 배타적이고 과거 이진값을 점수로 환산하지 않는다. 사유 allowlist, 기존 평가 소유권, request hash 멱등성 및 계정별 lock/시간당 제한 유지. 관리자 보고서는 기존 공식 gate를 사용한다. 저평점 연결은 feedback_id를 통해 기존 관리자 결과 검수 RPC를 재사용할 계약이며 UI 드릴다운은 후속 작업이다.

WEB는 `NEXT_PUBLIC_ESSAY_SATISFACTION_V2_ENABLED` 기본 OFF. 별도 SQL 승인/검증 전 기존 binary UI 유지. 사용자가 버튼을 눌러야 모달이 열리고, 임의 자동 표시 없음. 새 rating과 기존 binary를 분리해 집계한다. 대학/시험/사유별 SQL 집계는 후보에 포함되지만 관리자 화면의 세부 표시 및 APP 모달은 남아 있다.

롤백: WEB 이전 artifact 또는 본 WEB 커밋 revert, 신규 flag OFF. SQL은 flag OFF 후 reviewed rollback.sql로 기존 submit 복원/report 접근 회수; 컬럼·제출 기록 보존. 이 문서는 운영 적용 승인이나 자동 실행 지시가 아니다. GA4 연결·품질 검수 추가 계약·만족도 활성화가 베타 TASK09의 선행 조건이 되지 않도록 별도 유지한다.

## TASK10 GA4 integration / pre-build readiness — 2026-11-01

### 결과와 범위

**PARTIAL / HOLD**. 기존 31개 행동 이벤트·14개 속성 allowlist를 재사용해 WEB 수집 bootstrap을 구현했다. 새 분석 원장·이벤트 체계·평가 엔진은 만들지 않았다. APP Firebase/Noop 및 관리자 원장 집계/품질 검수 연결은 기존 구현을 재사용한다. 운영 DB/Worker/배포·결제·Provider 호출 없음. 최종 native APP 빌드/스토어 제출도 실행하지 않았다. WEB production build는 로컬 컴파일 검증만 수행했다.

Owner의 LAB 운영 태그 미설치 설명을 기준으로 수집은 **미연결**로 취급한다. 기존 레전드스터디닷컴 속성 396674471은 읽기 화면에서 확인됐으나, 접근 가능한 계정의 LAB 속성은 확인되지 않았다. 모든 계정에 LAB 속성이 없다고 단정하지 않는다. 속성 ID는 웹 측정 ID(G-...)와 다르다. 저장소 설정 조사에서 LAB 측정 ID/활성 설정 및 APP Firebase 플랫폼 설정 파일을 찾지 못했다. 임의 ID나 Firebase 프로젝트를 생성하지 않았다.

### 구현과 보호

- WEB `src/lib/analytics/ga4.ts`: 허용 origin·경로 및 설정 검증 후 한 번만 SDK 로드. 자동 page_view를 끄고 pathname 전환으로 수동 page_view를 전송한다. StrictMode 동일 경로 중복은 막고 정상 재방문은 센다. page_view는 GA 표준 이벤트이며 v1 업무 이벤트 31개에 새 이름을 추가하지 않는다.
- `src/components/analytics-collection.tsx`, root layout: SPA 방문 연결. 기존 `client.ts`의 이벤트 이름/속성 필터를 그대로 사용한다. 전송 함수 예외 시 dedupe 키를 소진하지 않는다.
- URL query/hash, 동적 평가/문항 ID, 실제 document title은 전송하지 않는다. 알려진 public route만 사용하고 referrer는 허용된 도메인의 origin만 보낸다. 관리자·Owner 검수·인증 복구 경로는 수집하지 않는다. 광고 관련 consent는 denied, Google Signals/광고 개인화는 false다. 이 설정은 사용자 동의 관리 자체를 대체하지 않는다.
- 이미 gtag/GTM이 설치돼 있으면 소유권을 탈취하거나 두 번째 태그를 삽입하지 않는다. 기존 태그가 있는 환경은 별도 연결 검토가 필요하다. 로드 실패/설정 누락은 안전하게 전송을 중단하고 평가·로그인·결제 흐름을 막지 않는다.
- `admin-analytics.tsx`: LAB 수집 준비 상태와 기존 GA4 보고서 읽기 연결 상태를 분리한다. 설정 존재만으로 실제 수신 완료를 표시하지 않는다. 기존 KST 필터/RPC/권한/원장 수치/품질·피드백 링크를 유지한다.
- 기존 만족도 피드백은 Postgres 원장으로 집계한다. 31개 allowlist에 없는 만족도/배너 이벤트를 임의 추가하지 않는다. banner impression/설치 완료/연결되지 않은 유입은 측정 완료로 표시하지 않는다.

### WEB 설정 및 외부 작업

다음은 승인된 TEST 환경에서 사용할 설정이다. 실제 값은 저장소에 추가하지 않았다.

| 설정 | 요구 조건 |
|---|---|
| NEXT_PUBLIC_ANALYTICS_ENABLED | 명시적으로 true일 때만 수집 |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | 기존 LAB 웹 스트림의 실제 G-... ID |
| NEXT_PUBLIC_GA4_ALLOWED_ORIGINS | 허용 TEST origin 정확한 목록, 쉼표 구분; wildcard 불가 |
| NEXT_PUBLIC_GA4_PRIVACY_REVIEWED | 아래 Enhanced Measurement·동의/개인정보 검토가 끝난 뒤 true |

Next public 설정은 빌드 시 반영된다. 현재 기본은 비활성이다. 기존 legendstudy.com 스트림 ID를 LAB ID로 추정하거나 자동 복사하지 않는다.

**활성화 전:** GA 관리 → 해당 LAB 속성 → 데이터 스트림 → 웹 스트림에서 ID를 확인한다. 기존 LAB 속성이 있으면 재사용한다. 없으면 신규 속성/스트림 생성이 필요하다는 사실을 Owner에게 보고하고 별도 진행한다. 이 수동 계측과 중복되거나 개인정보가 포함될 수 있는 **Enhanced Measurement 전체를 해당 LAB 스트림에서 비활성화**하고 검토한다. `send_page_view:false`만으로 Enhanced Measurement 수집이 모두 중단되지 않는다. Google 문서: https://developers.google.com/analytics/devguides/collection/ga4/views 및 https://developers.google.com/analytics/devguides/collection/ga4/reference/config . 기존 본사이트 설정은 변경하지 않는다.

보고서 조회는 별도다. 기존 본사이트/LAB **숫자 속성 ID**, 각 속성의 승인된 서버 identity **Viewer 권한**, Analytics Data API 읽기 인증(`analytics.readonly`) 연결이 필요하다. 비밀 인증값은 브라우저 public env나 Git에 넣지 않는다. 정적 WEB에서 Data API 비밀키를 직접 사용하지 않는다. 서버 reporting adapter/배포는 별도 승인·연결 대기다. 크로스도메인·UTM/배너 실측은 실제 설정/수신 전까지 미검증이다.

APP은 기존 Firebase AnalyticsService/bootstrap을 유지한다. 필요한 플랫폼 Firebase 앱 등록 및 `GoogleService-Info.plist`/`google-services.json`(또는 기존 초기화 경로에 맞는 FirebaseOptions), 실제 Bundle/Application ID 일치, ANALYTICS_ENABLED 설정이 필요하다. 현재 미설정 Noop을 유지한다. 신규 프로젝트/최종 APP 빌드는 수행하지 않았다. pubspec 선언은 `0.1.0+1`, 기존 QA 버전은 override 기록을 따르며 build33 산출물을 교체하지 않았다.

### 검증 증거

| 검사 | 이번 실행 결과 |
|---|---|
| Flutter 3.47.6 analyze | PASS, 0 issues |
| Flutter 전체 test | 1306 PASS / 7 SKIP / 0 FAIL |
| APP/WEB Analytics 계약 검사 | PASS, 31 events / 14 params |
| WEB Node 22 TypeScript | PASS |
| WEB Node 22 production build | PASS, 로컬 컴파일만 |
| WEB Node 22 lint | 0 errors / 기존 5 warnings |
| WEB 전체 Vitest | 1509 PASS / 4 SKIP / 0 FAIL; 209 files PASS / 3 SKIP |
| Analytics/bootstrap/admin 집중 테스트 | 27 PASS: 설정/host/PII/중복/예외/권한/로그아웃/미설치 |
| 실제 GA4 DebugView/Realtime 및 Data API | NOT_TESTED, ID/권한 미연결 |
| Firebase 실수신·실기기·실계정 관리자 RPC | NOT_TESTED, 이번 자동 테스트와 구분 |
| 운영 데이터 전후 직접 대조 | NOT_TESTED; 운영 쓰기/평가 호출은 수행하지 않음 |

첫 pnpm 래퍼 실행은 Node24를 선택해 지원 버전 경고가 발생했다. Node22 바이너리로 TS/lint/build/전체 테스트를 다시 실행했다. 테스트 SKIP는 PASS로 계산하지 않았다. 기존 명시적 통합/외부 Fixture 게이트를 해제하지 않았다. 공지·베타 KST/한도·재첨삭·Credit·History·OCR·피드백·결제/관리자 권한 관련 기존 자동 회귀를 포함하지만 운영 E2E/실결제/실평가 증거를 대체하지 않는다.

### Owner 검수 및 다음 단계

1. 외부 설정 확보 전: TEST에서 GA SDK 요청이 없고 평가/로그인/공지·피드백 화면이 유지되는지 확인한다.
2. LAB 실제 스트림/Enhanced Measurement 및 개인정보 검토 후 TEST origin만 허용해 승인된 빌드에 설정한다.
3. 로그인/대학 선택/작성/저장된 결과 조회의 이벤트를 Realtime 또는 Tag Assistant/DebugView로 대조한다. 답안/OCR 원문·query·token·동적 ID가 전송되지 않는지 Network payload에서 확인한다. 테스트를 위해 실제 평가/결제를 호출하지 않는다.
4. 관리자에서 수집 준비와 보고서 조회를 각각 확인한다. 일반/비로그인 접근 차단, 계정 전환 데이터 제거를 실계정으로 확인한다.
5. Firebase 플랫폼 설정 후 APP 별도 검수 빌드 승인을 받는다. 양 플랫폼 수신 검증 전에는 연결 완료/출시 완료로 판정하지 않는다.

TASK01~09는 현재 코드/기존 보고서를 재사용했다. TEST Gateway·SQL 설치·계정/실기기 등 잔여 게이트는 [TASK09 현황](essay-shared-test-task09-20261101.md)과 [TASK07 판정](essay-beta-release-readiness-task07-20261101.md)을 유지한다. 이번 변경으로 베타 사용량, Credit, 결제, History, Worker, Analytics SQL을 변경하지 않았다. TASK10 원래 범위의 GA reporting/6항목 수치 품질평가/APP 5점 만족도 확장은 여전히 미완료이며 기존 데이터로 값을 추정하지 않는다.

롤백: 설정 활성화 전에는 SDK 미로드. 코드 문제 시 이번 WEB 커밋만 revert하고 재검증한다. 배포된 환경에서 향후 수집을 끄려면 public flag=false로 승인된 재빌드/배포가 필요하며, 브라우저 신규 로드부터 적용된다. DB 롤백은 필요 없다. 기존 본사이트 GA4와 Analytics 원장은 수정하지 않는다.

구현 기준: APP baseline `8f3279b782cbe3e80119ddb447d3b72ac29e7eca`, WEB baseline `37850ec1534ee93f974e42cd8061da7c99336a41`. WEB 수집/검증 커밋 `017ecd3` (TASK10 별도 브랜치). APP 이번 변경은 Wiki 현행화이며 native source 변경 없음. 최종 SHA/원격 일치는 handoff 시 Git에서 확인한다.


## Analytics phase1 recovery and history re-audit — 2026-11-02

**PARTIAL / HOLD. No production change.** APP41 release branch untouched; documentation is on a separate worktree/branch. Owner requested historical verification before stream/settings decisions.

### Verified existing implementation vs activation
| Layer | Evidence | Current classification |
|---|---|---|
| Claude original | Git ccae6bd31e029efd385fcef694753b0fb8651d02, 31 files; AnalyticsService/Noop/Firebase, 31 events/14 parameters, native admin dashboard, reporting SQL candidate | IMPLEMENTED |
| Codex integration | Git 049d3073dc8ea0d4f8e1339acbe0f5460efdaaea is ancestor of release HEAD; 40 files, bootstrap/auth/OCR/catalog integration; historical tests 1255 PASS/7 SKIP in v1 Wiki | INTEGRATED; not proof of receipt |
| Native dashboard | lib/features/analytics/presentation/admin_analytics_page.dart, /my/admin/analytics; data/supabase_analytics_repository.dart | Existing RPC consumer; unchanged |
| Flutter collection | analytics_bootstrap.dart + main.dart; ANALYTICS_ENABLED defaults false, Firebase initialization failure falls back to Noop | Implemented, activation/config pending; APP41 unchanged |
| WEB collection | src/lib/analytics/{client,events,ga4}.ts; existing host/privacy/measurement flag checks, pageview dedup and allowlist | Implemented, production collection not configured |
| WEB admin ledger | src/components/admin/admin-analytics.tsx + src/lib/admin/analytics.ts; kpi/funnel/revenue/cost/university map to existing analytics_* RPC | Reused/connected; separate from GA4 visitors |
| Official home | official-home build/runtime reuses createGa4Runtime and banner_click; HOME_* flags | Implemented, measurement activation pending |
| GA4 server reading | Before Phase1 no Google token exchange/runReport implementation; only readiness text | Phase1 implementation now local-tested, not deployed/authenticated |

Claude branch names `claude/legendstudy-analytics-v1-20261030` and `...-9a315b` both exist locally. Original commit's own Wiki names `...-9a315b`; identity is verified by SHA rather than branch spelling. Do not remerge/reimplement.

### Current production RPC check (read only)
Live project stlhijzpjfgwwdgunlsd pg_proc confirms analytics_admin_check and seven reports: analytics_kpi_overview, analytics_funnel, analytics_free_credit, analytics_revenue, analytics_reliability, analytics_api_cost, analytics_university_usage. All seven accept p_from/p_to timestamptz. Live migration history confirms **20261101115715 admin_analytics_readonly_task11g**. This agrees with [TASK11-G](admin-data-task11.md#task11-g-production-integration--2026-11-01). Earlier v1 sections saying SQL not applied describe Oct30, not current production. No migrations/reinstalls/writes performed. Current inspection verifies installation, not every live metric or role response; prior role evidence remains dated TASK11-G.

### Wiki vs actual GA4 configuration
Full wiki search for GA4/Firebase/measurement/stream IDs covered v1, P0 contract, architecture review, TASK07/08/09/10/11/12, current-status/log and related routing documents.
- [v1 history](analytics-v1-implementation-20261030.md): original service implemented, Firebase/GA configuration explicitly pending; no completed LAB/home stream ID.
- This document's Nov1 GA4 section: existing property **396674471**, accessible LAB property not found; no stream creation performed.
- [Home TASK12](official-home-launch-task12.md): HOME_ANALYTICS_ENABLED/HOME_GA4_MEASUREMENT_ID/HOME_GA4_PRIVACY_REVIEWED default OFF; actual receipt NOT_TESTED. Deployment success did not establish Analytics activation.
- Nov2 live GA4 account47366112/property396674471 **All streams** lists exactly one: legendstudy.com, stream **5829568136**, existing measurement **G-295EQHYTCK** (Owner and audit confirmed). List shows recent48h traffic. No LAB/home/iOS/Android stream in this property. Other accounts cannot be ruled out.
- Existing Google Cloud **legendstudy / 559697965317** enabled API list has no Analytics Data API (Analytics Hub is different); Credentials page shows no service accounts. Existing login OAuth clients preserved.

Thus the missing activation is not absent Analytics v1 code: Firebase platform/build configuration, WEB measurement/privacy flags, and server GA4 read identity/API permission were never closed. Existing PostgreSQL reporting was installed separately.

### Owner direction and remaining gates
Nov2 Owner overrides earlier new-property candidate: reuse any verified existing stream; if absent, prepare **two web streams within396674471**, LAB and home. Do not create either stream or change operational settings before explicit approval. Preserve main stream. Do not claim cross-stream identity/installation attribution from this arrangement.
Server read setup candidate: enable analyticsdata.googleapis.com in legendstudy; dedicated read service account + GA Viewer only; server-only GA4_SERVICE_ACCOUNT_EMAIL/GA4_PRIVATE_KEY in approved Cloudflare environment. No keys in chat/Git/public env. None of these changes has been executed.

### Phase1 code prepared and verified
WEB branch codex/analytics-phase1-recovery reuses existing UI/period/RPC gate. New Cloudflare /api/admin/ga4 reads fixed property/stream/host; admin_operator enforced server-side; readonly Google scope; date/header/response validation, timeout and error states. Returning users use filtered totalUsers, not new-user subtraction. Daily/channel/page and four existing promotion events supported; installation remains NOT_AVAILABLE. Existing ledger SQL untouched.
TASK15 transport patch replaces only track(): proper arguments queue, existing gtag, existing event names and per-document dedup. Owner must apply skin patch; live Tistory untouched. Replacement and exact location are in WEB docs/analytics-phase1/README.md and promo-track-replacement.js.
WEB: TypeScript/build PASS;1600 tests PASS/4 SKIP;lint0errors/5existingwarnings. Live Data API receipt, mobile promo receipt, LAB/home receipt remain BLOCKED/NOT_TESTED. Flutter tests not rerun: no APP code change. Existing signup/evaluation aggregate code unchanged; this is not a new live aggregate accuracy certification.

Preservation seven answers: marketing eventtime vs serverfacts; GA property/stream/time source; no UPDATE/delete/backfill; admin auth only/no student join; marketing is not learning outcome; readonly/no PII/unchanged consent; transient derived report not second ledger. Existing longitudinal strategy applies.
Rollback: before deployment revert WEB change; after future approved deployment restore prior Pages artifact and restore Owner skin backup if applied. Never reset/delete GA history. Production deploy and settings await Owner review.


## Owner-created LAB and home streams — 2026-11-02
Owner confirms new web streams in existing396674471: LAB G-MVHZ7HS214/16254992877; home G-S4JZMP0141/16255062112. Existing main G-295EQHYTCK/5829568136 preserved. This supersedes the earlier one-stream observation. Both new streams Enhanced Measurement ON, collection inactive warning. Browser reconnect failed during independent recheck; creation details are Owner-confirmed, not independently verified receipt.
Existing manual page_view runtime requires automatic enhanced measurement disabled and privacy review before collection. Approval requested for only the two new streams; no console setting changed. WEB config candidates record exact IDs/origins with flags OFF; existing admin text now references LAB stream rather than nonexistent separate-property requirement. No duplicate runtime or event names. Data API still needs API/Viewer/server credential setup. Live tag/page_view/business events NOT_TESTED, not PASS. Production deployment requires Owner review; APP41/DB/Credit/payment unchanged.
