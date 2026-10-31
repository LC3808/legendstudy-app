# LegendStudy Analytics v1.0 — 구현 (2026-10-30, Claude)

브랜치 `claude/legendstudy-analytics-v1-9a315b`, 베이스 `codex/essay-evaluation-stability-p0-20261029`(`21f1569`, 이 라인 최신 안정). 기존 [P0 데이터 계약](analytics-p0-launch-contract.md)·[측정 아키텍처 리뷰](analytics-architecture-review-v1.md) 준수. 평가 엔진·Worker·Provider·Credit 정산·결제 계약·History 원장·기존 UI/UX·수리 엔진 **불변**. 운영 DB 미적용(Owner 적용 패키지 제공). 새 평가 실행 없음.

## 1. 아키텍처 — 역할 분리(Owner 확정 2026-10-30)
- **GA4/Firebase Analytics = 행동·전환 퍼널**(로그인 전 + 클라이언트 행동). 요청 버튼 클릭·결과 화면 진입 등 행동 이벤트 수집 가능. **이벤트 발생 ≠ 서버 완료.**
- **PostgreSQL = 공식 집계**(첨삭 완료/실패/재처리·Credit·결제·매출). GA4를 공식 완료/Credit/매출 기준으로 쓰지 않음.
- 새 `analytics_events` 테이블 없음, DB 사실의 GA4 이중기록 없음.

## 2. GA4 이벤트 (`lib/features/analytics/`)
추상 `AnalyticsService`(fire-and-forget, void) → `NoopAnalyticsService`(기본) / `FirebaseAnalyticsService`(`firebase_analytics`). `analyticsServiceProvider`는 기본 Noop, 부트스트랩이 `ANALYTICS_ENABLED`+Firebase 초기화 성공 시에만 Firebase 구현으로 override(`main.dart`). 이벤트 이름 상수·화면 상수는 `domain/analytics_events.dart`.
- **개인정보 보호:** `sanitizeAnalyticsParams`가 allowlist(platform/app_version/screen/exam_code/university_code/question_count/attempt_no/is_free/duration_ms/status/error_type/product_id/credit_count/source) 밖 키와 forbidden 키(email/phone/name/token/api_key/answer/body/text/evaluation/user_id…)를 제거, 문자열 100자 cap, 비원시값 drop. 답안 원문·평가 전문·인증정보 **전송 불가**.
- **중복 방지:** `analytics_guard.dart`의 `logEventOnce(onceKey,…)` 세션당 1회.
- **성능:** 모든 전송 try/catch·async·await 없음 → 첨삭 제출 등 어떤 흐름도 차단하지 않음. Noop일 때 완전 무해.

### 계측 완료 지점 (이벤트 호출만 추가)
- `lab_page.dart` → `essay_lab_view`(`AnalyticsView`)
- `essay_growth_page.dart` → `essay_growth_view`(build 1회)
- `credit_purchase_page.dart` → `credit_pricing_view`(initState), `credit_purchase_start`(구매 버튼), `credit_purchase_success`/`credit_purchase_failed`(`BillingPhase` 전이)
- `main.dart` → `app_open`(Firebase 활성 시)

### 계측 **미완료**(Codex 통합 시 1줄 패턴으로 추가 권장, 모두 행동 이벤트)
`AnalyticsView(const)` 또는 `ref.read(analyticsServiceProvider).log(...)` 한 줄로 추가:
- 인증/온보딩: `sign_up`,`login`,`onboarding_complete`
- LAB 선택: `university_select`,`exam_select`,`question_select`
- 에디터/제출: `essay_editor_open`,`essay_draft_save`,`essay_submit_start/accepted/rejected`,`essay_processing_view`,`essay_completed`,`essay_failed`,`essay_retry_requested`,`essay_result_view`
- OCR: `essay_ocr_start/success/failure/apply` (`answer_ocr.dart`)
- 재첨삭: `essay_rewrite_start/submit/completed` (`exam_rewrite.dart`)
미완료 이유: 해당 파일은 Codex 핫 컨트롤러(충돌·회귀 위험)이고, Firebase 미연결로 실수신 검증 불가. 패턴·지점은 위에 명시.

## 3. Supabase 집계 (Owner 적용 패키지)
`supabase/candidates/analytics_admin_reporting_20261030/` — **READY_FOR_OWNER_REVIEW, 미적용.** 기존 테이블 위 **관리자 전용 SECURITY DEFINER RPC**(집계 전용, 행 단위 학생 데이터 없음, `admin_operator()`+`account_private.allowed()` 게이트, authenticated에만 execute). 함수: `analytics_admin_check`, `analytics_kpi_overview`, `analytics_funnel`, `analytics_free_credit`, `analytics_revenue`, `analytics_reliability`, `analytics_api_cost`, `analytics_university_usage`. pglast 파싱 PASS(apply/precheck/postcheck/rollback). 정의·가정은 패키지 README 참조.

## 4. 관리자 대시보드 (`lib/features/analytics/presentation/admin_analytics_page.dart`)
라우트 `/my/admin/analytics`(기존 admin feedback 페이지에 진입 카드 추가). 기존 관리자 게이트 재사용(`analytics_admin_check`=`admin_operator`). 기간 선택(오늘/7일/30일/사용자지정). 상단 KPI → 퍼널 → 무료 Credit → 상품별 매출 → 신뢰성·재처리 → API 원가 → 대학별. **데이터 없음은 0/'데이터 없음'으로 정직 표시.** 차트 라이브러리 미추가(경량 KPI 타일/바/표).

## 5. 전환 퍼널 / 6. 무료 Credit / 7. 유료 매출 / 8. 평가 실패 / 9. API 원가
각각 §3 RPC로 계산. NSM=주간 unique 인증 학생 전체 루프(제출→평가완료→재작성→재평가, `request_kind='student'`, retries=`processing_runs` 제외). 무료/유료=`credit_grants.origin`(signup_bonus vs purchase)+`credit_transactions`. 매출=`payment_orders`(PAID·LIVE, TEST 제외)+환불=`payment_operations`. API 원가=`essay_ai_processing_runs`(토큰/latency/cost, `cost_basis`로 실측/추정 구분, null='데이터 없음'). 오류=`error_code` 버킷(미상은 임의 생성 없이 `other`).

## 10. 개인정보 보호
§2 sanitizer + allowlist. 사용자 식별은 pseudonymous `user_id`만(선택), Google Signals OFF(Owner 콘솔). GA4에 PII·답안·평가·결제수단 미전송.

## 11. 자동 테스트
`test/analytics_event_test.dart`(allowlist/PII drop/길이 cap/dedup/Noop/기간 계산·동등성), `test/analytics_dashboard_gate_test.dart`(비관리자 차단·관리자 조회). **`fvm flutter analyze` 0건, `fvm flutter test` 1241 PASS / 7 skip / 0 fail.** GA4 콘솔 실수신=**미검증**(Firebase 미연결). 운영 집계 일치=Owner 적용 후 postcheck.

## 12. 변경 파일
신규: `lib/features/analytics/**`(service/noop/firebase/providers/guard/events/dashboard domain·data·providers·presentation(page,view)), `supabase/candidates/analytics_admin_reporting_20261030/**`, `test/analytics_*`, 본 문서.
수정(최소): `lib/main.dart`(부트스트랩 override+app_open), `lib/core/config/app_config.dart`(`analyticsEnabled`), `lib/app/router.dart`(라우트), `lib/features/feedback/presentation/admin_feedback_page.dart`(진입 카드), `lib/features/lab/lab_page.dart`, `lib/features/essay/essay_growth_page.dart`, `lib/features/billing/presentation/credit_purchase_page.dart`(이벤트 호출), `pubspec.yaml`/`pubspec.lock`(firebase_core ^5.1.0, firebase_analytics ^13.0.1 + transitive만).

## 13. 최종 SHA
`ccae6bd31e029efd385fcef694753b0fb8651d02` (+ 본 SHA 기록 docs 후속 커밋). 브랜치 `claude/legendstudy-analytics-v1-9a315b`, origin push 완료.

## 14. Codex 통합 방법 · 충돌 가능성
- **충돌 위험 파일(Codex 핫):** `pubspec.yaml`/`pubspec.lock`(firebase 6패키지 추가만, 기존 핀 불변), `lib/app/router.dart`(admin 라우트 1개 추가), `lib/features/feedback/presentation/admin_feedback_page.dart`(카드 1개), `lib/features/lab/lab_page.dart`·`essay_growth_page.dart`·`credit_purchase_page.dart`(이벤트 호출). 모두 **추가 위주**, 로직 변경 없음 → 충돌 시 추가분만 재적용하면 됨.
- **저충돌 신규:** `lib/features/analytics/**`, `supabase/candidates/analytics_admin_reporting_20261030/**`, `test/analytics_*`.
- 통합 순서 권장: (1) 신규 analytics 모듈 머지 → (2) 핫 파일 추가분 재적용 → (3) `pubspec` firebase 추가 → (4) §2 미완료 이벤트 1줄 패턴으로 보완.

## 15. 운영 적용 대기 (Owner)
- `analytics_admin_reporting_20261030` precheck → apply → postcheck(비관리자 REST 거절은 실제 JWT로 확인; SET ROLE 비권위).
- Firebase 프로젝트 생성 + `google-services.json`/`GoogleService-Info.plist` + iOS/Android 와이어링, GA4 property(Signals OFF) → `ANALYTICS_ENABLED=true` 빌드 → DebugView 실수신 확인.

## 16. Claude 인계 당시 미완료 (현재 상태는 아래 Codex integration review 참조)
- §2 미완료 행동 이벤트(인증/선택/제출/OCR/재첨삭) 계측(패턴 제공).
- GA4 실수신·네이티브 Firebase 빌드 검증(Owner Firebase 선행).
- 미성년 개인정보(PIPA) 동의/보존 게이트는 별도 법적 트랙([리뷰 §B-3](analytics-architecture-review-v1.md)).

## Codex integration review — 2026-10-30

Owner 통합 지시에 따라 APP 최신 `b1c784398c4a86d9328f15be5b72c1d05395f611` 위에
Claude 구현 `ccae6bd` 및 최종 문서 `0047186`을 통합했다. Claude 브랜치 자체는
변경하지 않았다. 충돌은 `wiki/current-status.md` 한 곳이며 최신 APP 기록을 유지했다.
최신 결과 UI/문단 처리/성장 페이지네이션/OCR/Observation V1/무료 재첨삭 로직 보존.
기존 미추적 `.fvmrc` 보존. iOS30 재빌드/설치 없음.

### 보존 검토 7문항

[상위 전략](longitudinal-learning-admissions-data-strategy.md) 및
[기존 Analytics 계약](analytics-p0-launch-contract.md)에 연결한다.
1. 클라이언트 이벤트는 동작 관측 시점의 의도이며 서버 완료 사실이 아니다.
2. 학습/결제/평가 사실은 기존 Postgres 원장과 provenance로 재구성한다.
3. 기존 원장 UPDATE/삭제/백필 없음. SQL은 읽기 집계 함수 후보뿐이다.
4. 학생 ID/답안/평가문/요청키를 GA4 이벤트에 전송하지 않는다. 기존 identity 유지.
5. 행동·학습 결과·결제 사실의 역할을 분리한다. 대시보드 숫자는 GA4에서 가져오지 않는다.
6. 이벤트는 정해진 source/status/count 값만 사용. 관리자 집계는 서버 권한 검증이 필수.
   Google Signals/동의·보관기간/Firebase 콘솔 설정과 실제 수신은 Owner 설정 후 확인한다.
7. 집계는 파생 데이터이며 원장이 아니다. 기간·분모·버전을 구분한다. 비용 미측정은 NULL.

### 추가한 행동 이벤트

| 위치/함수 | 이벤트/의미 |
|---|---|
| auth_page.dart `_passwordAuth`, `_oauth` | login/sign_up + status=started, 인증 시도(가입 완료 수 아님) |
| source_catalog_page.dart `selectUniversity`, `choice`, 문항 onChanged | 대학·시험 필터·문항 선택, 본문/식별자 전송 없음 |
| `_SourceWriter` 로드/saveManually/importOcr | editor_open/draft_save/OCR 적용, 키 입력 내용 수집 없음 |
| answer_ocr.dart `recognize` | start/success/failure, 인식 원문·사진 전송 없음 |
| ExamSubmissionPanelState.submit | 실제 전송 직전 submit_start 또는 rewrite_submit, is_free/question_count만 |
| shared_history_page.dart `_Result.openWriter`/header | rewrite_start(서버 자격 확인 후), result_view(마운트 1회) |

무료 재첨삭은 기존 parent·quote·서버 자격 검사를 그대로 사용한다.
관측 이벤트로 성공/매출/정산을 확정하거나 요청을 재실행하지 않는다.

### 검토 중 보완

- 관리자 후보 SQL 7개 데이터 RPC는 `analytics_admin_check() IS NOT TRUE`이면 거절.
  auth.uid NULL, 권한 함수 NULL도 거절. 8개 함수 빈 search_path, postgres owner,
  PUBLIC/anon/service_role 실행권한 제거, authenticated만 허용. 운영 JWT 검증은 미실행.
- postcheck는 함수 존재뿐 아니라 실제 ACL/owner/search_path까지 확인하도록 보강.
- 비용의 provider_reported 원본이 없으면 0원으로 오인시키지 않도록 NULL 유지.
- Firebase boolean 매개변수를 0/1로 변환, non-finite 숫자 제거.
- 초기화 오류/미설정/3초 지연은 Noop. native 자동 수집 기본 OFF, 광고 ID 수집 OFF.
  `ANALYTICS_ENABLED=true`인 성공 초기화 서비스의 이벤트만 collection 활성화.
- 결과 이벤트는 독립 순수 위젯이 아닌 인증된 화면에 배치. UI standalone 회귀 보존.

### 적용/미검증 경계

운영 SQL **NOT APPLIED**. 후보 precheck/apply/postcheck/rollback은 Owner 승인용이며
실제 운영 스키마 호환성·집계 숫자·admin/non-admin JWT 권한은 적용 전후 별도 검증한다.
현재 후보 funnel은 **선택 기간 가입 코호트의 전기간 학습 루프**이며 주간 완료 NSM과
같은 값이 아니다. 재시도는 processing_runs이고 학생 재작성 회차와 구분한다.
전통 essay_evaluations 기반 집계가 현행 시험 run/checkpoint 결과를 모두 포함하는지,
환불/비용 통화/집계 기준은 운영 적용 전 데이터 대조가 필요하다. 숫자 검증 완료로 보고하지 않는다.
Firebase 프로젝트 파일은 추가하지 않았다. GA4 실제 수신, native SDK iOS/Android 빌드,
실기기 및 콘솔 광고·개인정보 설정은 NOT TESTED. 기본 ANALYTICS_ENABLED=false 유지.
이전 활성 빌드에서 비활성 빌드로 전환할 때 native SDK의 persisted collection 설정도
Owner 설정 검증 대상이다. 앱 네이티브 설정/서명/로그인 설정은 변경하지 않았다
(Analytics 수집 기본값 메타데이터 추가 제외).

### 검증 및 롤백

Flutter 3.47.6 Analyze 0 issues. 전체 Flutter Test 최종 결과는 아래 통합 검증 기록 참조.
view 마운트/Noop 추가 테스트 포함 Analytics targeted 7 PASS.
RPC 권한 검사는 정적 계약/클라이언트 gate 단위 테스트이며 운영 검증과 구분한다.
운영 DB/Worker/Auth/Credit/History 변경, Provider 호출, 스토어 제출 모두 0.
롤백은 이 통합 커밋 revert 또는 ANALYTICS_ENABLED=false 검수 빌드.
미적용 SQL rollback 실행 불필요. 기존 구현/정산 정책 복구 작업도 불필요.

### 통합 최종 검증 기록

- Flutter 3.47.6 `flutter analyze --no-pub`: **0 issues**.
- `flutter test --no-pub --reporter expanded`: **1255 PASS / 7 SKIP / 0 FAIL**.
- `python3 tool/check_wiki_handoff.py`: PASS, current-status 11,984 bytes.
- `git diff --check`: PASS. 기존 미추적 `.fvmrc` 제외하고 통합 파일만 커밋.
- 전체 테스트에는 기존 무료 재첨삭·Credit·History·OCR·TTS·UI 회귀가 포함됨.
  테스트 통과는 운영 GA4 수신/SQL 적용/실기기 PASS를 의미하지 않음.

## TASK03 existing integration verification — 2026-10-31

### 기준과 재사용

Owner TASK03은 새 Analytics/관리자 대시보드 개발이 아니라 기존 v1 통합 확인과 남은 행동 계측이다. APP 시작 `9b911694c455abee452ce14f63524f18f056cfee` (`codex/essay-evaluation-stability-p0-20261029`), WEB 시작 `c5300dfc3d9979ae93bcb580f96b807700e612b9` (`codex/web-app-release-20261024`). Claude `ccae6bd`, `0047186` 모두 APP HEAD의 조상으로 확인했다. 재병합하지 않았다. 기존 TASK01 공지/TASK02 베타 구현과 `.fvmrc`를 보존했다.

기존 AnalyticsService/FirebaseAnalyticsService/NoopAnalyticsService, bootstrap, allowlist, 이벤트 정의, 관리자 repository/provider/page와 공식 admin_operator 권한 계약을 재사용했다. 기존 7개 보존 검토 답변 및 GA4/PostgreSQL 분리 결정을 유지한다. 신규 사실 데이터 수집 테이블, 개인정보, 학생 답안 또는 run ID 외부 전송은 추가하지 않았다.

### 행동 이벤트 보완 (§2·§14 후속)

- APP: 기존 로그인/가입·대학/시험/문항·editor/draft/OCR·rewrite/result/growth·결제 호출부 유지. 제출 시작 중복 방지, 서버 접수 확인 accepted, 확정 거절 rejected, 확인된 terminal completed/failed, 재첨삭 완료, 처리 화면 관측, 실패 문항 재처리 요청, onboarding 완료 계측 보완.
- APP 진행 화면과 History에서 같은 terminal/rewrite key를 사용한다. once guard는 **이벤트명+로컬 key**로 구분해 같은 요청의 start/accepted를 서로 누락시키지 않는다.
- WEB: 기존 v1 wire 이름/속성만 사용하는 작은 gtag 어댑터를 추가했다. SDK 로딩·새 저장소·새 수집 체계는 없다. 로그인/가입·소셜 진입, LAB/대학/시험/문항, editor/명시적 기기 저장/계정 저장, 제출 start/accepted/rejected, 처리/완료/실패, 재처리, 결과, 재작성 진입/제출/완료, 성장 화면을 연결했다. WEB OCR UI는 존재하지 않아 OCR 기능을 새로 만들지 않았다.
- 성공 로그인과 소셜 `started`, 서버 접수와 완료 관측은 status/source로 구분한다. `is_free`는 해당 제출의 included parent 경로 의미이며 신규가입/유료 Credit의 재원 판정이나 매출로 사용하지 않는다.
- 재처리 이벤트는 사용자 요청 행동(`started`)이다. 실제 성공·비용·과금 지표는 PostgreSQL 원장으로 판정한다. GA4 terminal은 `client_observation`으로, 백엔드 전체 완료 건수가 아니다.
- 중복 억제 범위는 클라이언트 프로세스/페이지 수명이다. 다른 기기·재시작까지 exactly-once를 주장하지 않는다. 로컬 once key는 외부 payload에 넣지 않는다. 분석 전송 실패/설정 부재는 본래 사용자 동작을 차단하지 않는다.
- `tool/check_analytics_contract.py --web-root /Users/woojinchang/development/legendstudy-release-20261024`: APP/WEB 31개 이벤트 및 14개 허용 속성 일치. 금지/미등록 속성 제거, 유한 숫자/문자열 길이 제한을 검사했다.

### 관리자와 SQL (운영 적용 금지 유지)

기존 APP `/my/admin/analytics`와 관리자 feedback 페이지 연결을 유지했다. analytics_admin_check 실패/false는 dashboard 조회를 허용하지 않는다. WEB 저장소에는 별도 Analytics dashboard가 확인되지 않았다. 이번에 중복 대시보드는 만들지 않았다. 기존 APP 화면에 **기존 단일 문항 집계 범위·통화/환불 검토 전 사용 금지** 안내를 추가하고, 주간 NSM으로 오해되지 않도록 `가입 코호트 전체 루프`로 표시했다.

Production `stlhijzpjfgwwdgunlsd`에서는 읽기 전용 메타데이터 조회와 precheck만 실행했다. analytics RPC 8개는 미설치다. 실제 관리자 로그인 결과/데이터 조회는 운영 PASS가 아니다.

실제 스키마에는 `essay_ai_processing_runs.total_tokens`가 없다. 후보 apply의 합계를 기존 input_tokens + output_tokens로 정정하고 precheck를 실제 8개 열에 맞췄다. 일부 토큰 미상은 합계에도 미상으로 유지한다.

격리 PostgreSQL17 `analytics_task03`/55439에 `local_schema_fixture.sql → precheck.sql → apply.sql → postcheck.sql → local_contract_test.sql`을 실행했다. 모든 8개 함수 SECURITY DEFINER/search_path 고정, authenticated 실행, PUBLIC/anon/service_role 거부, 일반 사용자 7개 보고서 PT403, 미로그인 관리자 판정 false, 관리자 7개 조회, 잘못된 기간 거부, 100+40=140 토큰, 시험/credit/평가 데이터 불변 검사를 통과했다. fixture auth.uid/admin_operator는 mock이며 실제 JWT 인증의 대체 검증이 아니다. seed 트랜잭션은 rollback했다.

**배포 가능 판정: BLOCKED.** 다음 계약 검토 전 Owner에게 apply를 권하지 않는다.

1. legacy essay_attempts/evaluations 집계는 현재 essay_exam_runs/checkpoint 전체를 포괄하지 않는다.
2. signup cohort full_loop는 주간 NSM이 아니며 free-credit dropoff 1/2/3 usage bucket도 검증된 이탈률이 아니다.
3. 매출의 PAID/LIVE·환불·통화 계약 및 원화 UI와 통화별 합계 분리 검토가 필요하다.
4. 비용 통화/미상 비용 해석도 운영 지표 승인 전 검토해야 한다.

기존 SQL 파일 존재는 운영 설치 증거가 아니다. 새로운 평가·Credit·History 변경 및 운영 SQL Apply는 실행하지 않았다.

### Firebase / GA4 — NOT TESTED (실수신)

현재 APP ANALYTICS_ENABLED 기본 false. iOS GoogleService-Info.plist 및 Android google-services.json 미연결. Android Google Services plugin 연결도 아직 없다. WEB gtag SDK/승인된 GA4 stream 설정 미연결이며 NEXT_PUBLIC_ANALYTICS_ENABLED 미설정은 Noop이다. 임의 프로젝트를 만들지 않았다.

Owner 후속 작업:

1. 기존 승인된 Firebase/GA4 프로젝트·APP iOS/Android `com.legendstudy.app` 등록 및 WEB stream을 확정한다.
2. 해당 프로젝트의 native 설정 파일을 로컬 제공하고 iOS Runner target resource 및 Android Google Services plugin 연결을 검토한다. 공개 client ID 외의 secret은 Git에 넣지 않는다.
3. 검수 빌드에만 `--dart-define=ANALYTICS_ENABLED=true`를 전달한다. 기존 Supabase/소셜/Observation 설정은 유지한다.
4. WEB의 승인된 gtag 로더/동의 정책을 연결하고 검수 환경 `NEXT_PUBLIC_ANALYTICS_ENABLED=true`로 빌드한다. 현재 어댑터는 gtag가 없어도 안전하게 무시한다.
5. DebugView/Realtime에서 로그인·목록·기존 결과 조회 등 평가/과금 없는 행동으로 이름·속성·중복을 확인한다. 실제 신규 평가나 Provider 호출은 이 설정 검증 승인에 포함되지 않는다.

### 검증 및 영향

- Flutter Analyze: 0 issues. 전체 Flutter Test: 1,302 PASS / 7 SKIP / 0 FAIL.
- WEB TypeScript PASS, Lint 0 errors / 기존 5 warnings, Production Build PASS. 전체 1,438 PASS / 4 SKIP / 0 FAIL (199 passed/3 skipped files). 신규 어댑터 테스트 6개 PASS.
- 로컬 SQL 및 APP/WEB 계약 일치 검사 PASS. 실제 GA4 수신/운영 관리자 집계/실제 인증은 NOT TESTED 또는 설치 선행 BLOCKED.
- 기존 평가/무료 재첨삭/Credit/History 회귀는 기존 자동 테스트로 확인했다. 운영 원장 before/after 전수 비교를 수행했다는 의미가 아니다. 운영 DB/Worker/배포/Provider 호출은 하지 않았다.
- 개발 코드 롤백은 TASK03 변경 커밋 revert. 외부 계측은 두 플랫폼 flag false로 비활성화 가능. SQL은 운영 미적용으로 롤백할 대상이 없다. 기존 UI·평가 계약은 유지된다.

### 변경 파일과 handoff

- APP: `analytics_guard.dart` (`AnalyticsOnce.logEventOnce`), `source_catalog_page.dart` (submit/poll/retry), `round_history_actions.dart` (retry/상태 관측), `onboarding_page.dart`, 기존 `admin_analytics_page.dart`, `analytics_event_test.dart`.
- WEB: `src/lib/analytics/{events,client,client.test}.ts`와 auth/forms, source selection/writer, submit, progress/retry, result, rewrite, growth 기존 화면의 계측 지점. 구현 커밋 `d5cd458`.
- SQL 후보: apply/precheck의 token 열 수정, 격리 schema/contract fixtures. 운영 적용본 아님.
- Wiki handoff 검사 PASS (current-status 11,962 bytes). APP과 WEB 코드의 실제 수신/운영 집계는 위 제한대로 후속 검증한다. 이 절의 TASK03 기록이 과거 §2/§14의 미계측/미실행 상태보다 최신이다.

## TASK08 aggregation candidate correction

Modern exam-level scope, KRW revenue/refund and separate Credit recovery, USD ACTUAL/ESTIMATED/UNKNOWN corrected and tested in isolation; no production apply. [Details and remaining gates](essay-beta-integration-task08-20261101.md).
