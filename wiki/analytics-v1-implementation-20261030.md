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
커밋 후 본 문서 하단/로그에 기록.

## 14. Codex 통합 방법 · 충돌 가능성
- **충돌 위험 파일(Codex 핫):** `pubspec.yaml`/`pubspec.lock`(firebase 6패키지 추가만, 기존 핀 불변), `lib/app/router.dart`(admin 라우트 1개 추가), `lib/features/feedback/presentation/admin_feedback_page.dart`(카드 1개), `lib/features/lab/lab_page.dart`·`essay_growth_page.dart`·`credit_purchase_page.dart`(이벤트 호출). 모두 **추가 위주**, 로직 변경 없음 → 충돌 시 추가분만 재적용하면 됨.
- **저충돌 신규:** `lib/features/analytics/**`, `supabase/candidates/analytics_admin_reporting_20261030/**`, `test/analytics_*`.
- 통합 순서 권장: (1) 신규 analytics 모듈 머지 → (2) 핫 파일 추가분 재적용 → (3) `pubspec` firebase 추가 → (4) §2 미완료 이벤트 1줄 패턴으로 보완.

## 15. 운영 적용 대기 (Owner)
- `analytics_admin_reporting_20261030` precheck → apply → postcheck(비관리자 REST 거절은 실제 JWT로 확인; SET ROLE 비권위).
- Firebase 프로젝트 생성 + `google-services.json`/`GoogleService-Info.plist` + iOS/Android 와이어링, GA4 property(Signals OFF) → `ANALYTICS_ENABLED=true` 빌드 → DebugView 실수신 확인.

## 16. 미완료
- §2 미완료 행동 이벤트(인증/선택/제출/OCR/재첨삭) 계측(패턴 제공).
- GA4 실수신·네이티브 Firebase 빌드 검증(Owner Firebase 선행).
- 미성년 개인정보(PIPA) 동의/보존 게이트는 별도 법적 트랙([리뷰 §B-3](analytics-architecture-review-v1.md)).
