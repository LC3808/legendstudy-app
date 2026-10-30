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
