# 이용권 지급 유형 세분화·관리자 통계 개선 — 2026-11-04

**SQL·WEB 운영 적용 및 읽기 검증 PASS / APP58·앱 빌드 별도.** 아래 구현 기록 뒤 Owner가 운영 적용을 별도 승인했다. Owner의 [원장 감사](beta-credit-ledger-audit-20261104.md) 승인 후 조회·표시·통계만 개선했다. 신규 원장/운영 UPDATE·백필/지급·차감/결제·환불/Provider/배포 실행0. 기존 지급·예약·정산 RPC와 베타 정책은 변경하지 않았다.

## 운영 적용 완료 — 2026-11-04 15:28~15:31 KST

- Owner 명시 승인 범위: 조회 SQL→WEB 순서, 운영 원장 읽기 검증. 실제 지급·예약·차감·결제·환불 실행0. APP58 통합/앱 빌드0.
- 사전 운영본은 `a901568fa7b0acc752061d6fd7361ad5772875c8`, Pages `98e2b121-22d8-4bb5-8f78-a7db72c3a587`로 변경돼 있었다. 최신본에 이용권 커밋만 충돌 없이 선택 통합. 기존 결제 emergency-pause 포함 운영설정49개·API 입력138개·대상 외 페이지 보존.
- SQL hosted migration **20261104062802 / credit_classification_read_reporting**. 기존 member 함수 hash 검사 후 단일 트랜잭션 적용. 저장소 이력 [SQL](../supabase/migrations/20261104063113_credit_classification_read_reporting.sql)은 동일 내용이며 재실행/중복 push 금지.
- WEB 배포 SHA **61c75caf8b2ef90b5b0392defb91ab1d9d078abc**, Pages **8209d68d-8769-4788-a254-8db4494d63ac**, production/success/canonical 및 전체 manifest 일치 확인. `/admin/*`, `/account/credits/*` 및 새 hashed assets만 교체. 다른 정적 경로 보존.
- SQL 전후/WEB 검증 후 전체 원장273행 digest `14254691e3d30000dce360a60c6e0bbc` 동일. 기존 private 거래함수 digest `15538db2c0459895a71b168647f7fee0` 동일. 새 읽기 helper는 비교에서 제외. authenticated EXECUTE=true, anon/service_role=false, 실제 관리자 세션으로 새 RPC 조회 성공.
- 실제 Chrome 관리자 화면: 베타 필터 전체5기록, 지급3개·예약1개·소비1개. 기존 01:20 지급/예약 및 01:21 소비 **원본 ID3개와 grant ID 일치**, 인하2027모의 자연계열 시험/완료 상태 확인. 예약/사용 중복 소비 없음.
- 전체 기간 UI 및 운영 SELECT 일치: 가입165건495개, 베타3건3개, 관리자7건325개, 구매3건5개, 기타 유형0. 신규 지급178건828개·소비37개·예약49기록·해제9기록. 이는 아래 오전 감사 스냅샷과 시점이 다르며 그 사이 서비스에서 발생한 가입 지급을 이번 작업이 만든 것으로 오해하지 않는다.
- 최신 운영 통합본 WEB163경로 빌드/타입 검사 PASS. 관련284테스트는 만료 명칭 기대값1개를 정정해 해당34개 재실행 PASS; 기존 문의 DB opt-in1 SKIP. 디스크 ENOSPC는 이 작업의 재생성 가능한 build cache만 정리 후 해결.
- [운영 영수증·롤백 기준](../supabase/candidates/credit_classification_20261104/production-receipt.json). 롤백은 위 이전 Pages로 복귀 후 기존 조회 함수 변경 여부를 검토하고 rollback.sql. 원장 역분개 불필요.

아래는 오전 구현/격리 검증 당시 이력이다. 완료표의 운영 SQL·WEB 항목은 이 절의 PASS가 최신이며 APP 빌드는 계속 별도이다.

## 실제 운영 지급과 매핑

운영 프로젝트 `stlhijzpjfgwwdgunlsd` 읽기 전용 조회. 11-04 작업 시점 스냅샷이며 일반 사용자 실거래와 기존 운영 테스트 기록을 임의로 분리/삭제하지 않는다.

| 원장 origin / 최초 지급 reason | 분류 | 표시 | 운영 지급 기록 / 수량 |
| --- | --- | --- | ---: |
| signup_bonus / signup_bonus_v1 | signup | 신규가입 무료 이용권 지급 | 153건 / 459개 |
| promotion / essay_beta_daily 또는 daily_grants 연결 | beta | 베타 무료 첨삭 이용권 지급 | 3건 / 3개 |
| promotion / 기타 실제 이벤트 사유 | event | 이벤트 이용권 지급 | 0건 |
| admin_grant / manual_support 및 일반 관리자 사유 | admin | 관리자 지급 | 7건 / 325개 |
| purchase / iap_apple_v1, iap_google_v1 | purchase | 이용권 구매 | 3건 / 5개 |
| compensation / customer_compensation 등 | compensation | 이용권 복구 또는 보상 지급 | 0건 |
| b2b_program / program_allocation 등 | school | 학교 단체 이용권 지급 | 0건 |
| admin_grant / admin_grant_v2 JSON kind=other, 미확인 origin | other | 기타 지급 | 0건 |

0건 유형은 기존 코드/계약에 존재하는 분류이고 운영에 실제 지급됐다고 주장하지 않는다. 합성 TEST에만 사례를 만들었다. 관리자가 적은 “오류” 같은 자유 사유만으로 보상으로 분류하지 않는다. 베타 지급은 promotion source를 보존하며 **최초 지급 이유/바인딩**으로 판별한다. 예약 reason=essay_exam_initial을 베타 여부로 해석하지 않는다.

총 신규 지급792개, 사용 완료37개. 출처별 사용완료: 가입4/베타1/관리자28/구매4. 원장 예약 순증감3(가입2/구매1); 만료/fence를 적용한 현재 사용 가능 잔액과 다른 수치이다. 원본 대상 grant `02ee324f-f82f-49f0-9524-79d227a8425f`의 지급+1→예약+1→확정-1/예약-1을 재조회하여 보존 확인.

## 사용·예약·복구 표시와 통계

| 실제 거래 | 표시/집계 |
| --- | --- |
| reserve | 첨삭 이용권 사용 대기 / 예약 수량만 집계 |
| consume | 첨삭 이용권 사용 완료 / 최종 소비 수량만 집계 |
| release | 이용권 예약 취소 / 예약 해제 수량, 신규 지급 아님 |
| refund 양수 | 이용권 복구 / 신규 지급 총량 제외 |
| adjustment 양수 + iap_refund_reversal_apple/google | 이용권 복구 / 신규 지급 총량 제외 |
| expiration | 이용권 만료 |
| adjustment 음수 + purchase_cancel_v1 또는 iap_refund_apple/google | 환불에 따른 이용권 조정 |
| 기타 adjustment 및 미확인 거래 | 이용권 조정 / 원본 사유·부호 보존, 환불/복구 추정 금지 |

관리자 `admin_recovery_v1`은 **회수**이며 복구가 아니다. compensation은 신규 보상 지급이고 기존 소비 복구는 restore 동작이다. 지급 출처와 거래 구분을 서로 다른 축으로 보며 같은 거래가 두 지급 카테고리에 들어가지 않는다. 각 합계는 페이지 LIMIT 이전 동일 필터 결과에서 계산한다. 행 수와 첨삭 횟수는 별개.

## 구현

- 읽기 전용 `admin_credit_report(credit-report-v2)` 및 private 분류 helper 3개. STABLE/IMMUTABLE·빈 search_path, 관리자 검증, authenticated만 public RPC 실행. admin_member_credit는 기존 grant 행에 display_kind만 추가. 기존 지급·차감·환불·보유량 산식 변경0.
- 기존 관리자 이용권 report와 회원 상세에서 같은 컴포넌트/조회 사용. 출처8개 및 거래구분 독립 필터, 기존 KST 기간/회원검색/5건 페이지 유지. 날짜·유형·수량·사유·증감·원본 ID·주체·시험·회차·상태·지급 건 거래 직후 잔액 제공. raw source/reason은 기술 상세에서 확인.
- 합계의 기간은 시작 포함/종료 제외. 회원 필터는 기존 user_id, 관리자에게만 허용. 전체 결과 카운트/합계와 현재 페이지 행을 구분한다.
- 거래 직후 잔액은 지급 건별 전체 이력을 먼저 합산하고 기간을 나중에 적용한다. 현재 spendable과 다르며 같은 timestamp는 ID 순으로 고정한다.
- WEB 사용자 내역은 원 reason과 delta로 표시하고 다중 grant 소비를 decision별 한 번만 합산. APP은 기존 RLS 조회에 reason_code만 추가하고 동일 명칭 사용. 두 클라이언트의 예약/해제 숨김·확정 사용 표시 정책은 보존한다. 관리자는 모든 거래를 조회한다.
- 기존 조회에서 분류 필드가 없는 경우 일반 source 명칭만 표시하며 베타라고 추정하지 않는다. 새 통계 RPC 미설치는 오류로 표시한다.
- `credit_summary`, 기존 대시보드·결제 report, 가입권 분석의 기존 계약은 변경하지 않는다. 신규 세분화 통계는 이용권 화면·회원 상세에서 같은 원장으로 제공한다.

## 검증과 결과 구분

| Owner 완료 보고 항목 | 판정 | 근거/한계 |
| --- | --- | --- |
| 1 실제 운영 지급 목록 | PASS | 위 SELECT 스냅샷. 비발생 유형 별도 명시 |
| 2 source/reason 매핑표 | PASS | 위 표·private helper·공통20사례 |
| 3 지급 표시 | PASS | WEB/APP formatter·widget 합성 검증 |
| 4 사용·예약·복구 표시 | PASS | reserve/consume/release/restore/refund 조정 구분, 기존 원장 불변 |
| 5 세분화 통계 | PASS(격리) | 신규 지급과 복구·예약 분리, 8출처·동작별 집계 |
| 6 필터 | PASS(격리) | 출처/동작/회원/기간/페이지 카운트·합계·자정 경계 |
| 7 WEB·APP 의미 일치 | PASS(테스트) | 동일20개 JSON fixture, 사용자 내역 원장 합산 유지. 실기기 미검증 |
| 8 기존 원장 정합성 | PASS | 운영 쓰기0, 대상3거래 동일, 격리 전후 hash·rollback 보존 |
| 9 테스트 | PASS(아래 범위) | 운영 실제 인문·수리·상경/결제·환불 E2E는 NOT_VERIFIED |
| 10 변경 파일 | PASS | 아래 목록·각 Git diff |
| 11 Git SHA | PASS | WEB 아래 커밋, APP/SQL 전용 브랜치 문서와 최종 보고 |
| 12 Wiki | PARTIAL | 문서/라우팅 갱신; 기존 외부 링크20개 누락 유지 |
| 13 운영 적용 | NOT_VERIFIED | SQL·WEB 미적용, 별도 Owner 승인 필요 |
| 14 APP 빌드 | NOT_VERIFIED | 표시 반영에는 APP58에 변경 선택 통합 후 신규 앱 빌드 필요. 앱 릴리스 미실행 |

실행 결과:

- 신규 임시 PostgreSQL17: 분류/기간/회원/페이지/빈 결과/Math 연결/권한/잘못된 필터/적용 기준 drift 검사/원장 hash/롤백 PASS. 실 운영 전체 DB 복제는 아니다.
- 기존 첨삭 원장 격리 회귀18개 PASS: 최초1, 무료0, 복수문항1, 동시재시도, 중복충돌, 부분실패, 해제, 이력보존. 기존 후보 계약 회귀이며 운영 최신 전체 인문·수리·상경 E2E 인증은 아니다.
- WEB Node22: 관련36파일284 PASS, 문의 전용 DB통합1개 기존 환경조건 skip. 최종 사용자 합산 명칭 보완 뒤 관련4파일62 PASS. 관리자 UI·원장·결제 transport는 mock이며 실제 결제/환불0.
- WEB TypeScript·변경파일 ESLint PASS. Next webpack 정적 production build163경로 PASS. Turbopack은 외부 node_modules symlink 때문에 실패하여 webpack으로 검증. 최종 표시 문자열 보완은 테스트로 재확인.
- Flutter3.47: 표시/내역/잔액/베타/출처34 PASS, 수정4파일 analyze 오류0. 기본 PATH SDK가 오래되어 프로젝트 SDK로 실행. APK/IPA/기기 QA는 미실행.
- `git diff --check` PASS. Wiki checker의 기존 TASK16 외부 상대경로20오류는 다른 작업 범위이므로 그대로 보고한다.

## 변경 파일·Git·적용

APP/SQL branch `codex/credit-classification-20261104`, 시작 `ba1021ccc95c372fbcfe08a4a4b4f431e3426463`:

- `lib/features/credits/credit_display.dart`, `credit_history.dart`
- `test/credit_display_test.dart`, `credit_history_test.dart`, `test/fixtures/credit_display.json`
- `tool/test_credit_classification.py`
- [SQL 패키지·보존 질문7개·순서·복구](../supabase/candidates/credit_classification_20261104/README.md): apply/precheck/postcheck/rollback/member-baseline
- 본 문서, index/current-status/decisions/log, 기존 감사 연결

WEB branch `codex/credit-classification-web-20261104`, 구현 커밋 `21e6716` (로컬, 미배포). checkout `/private/tmp/legendstudy-feedback-web-20261104`:

- `src/lib/credit-classification.ts`, `credit-display.ts`, `credit-display-cases.json`와 테스트
- `src/lib/admin/credit-report.ts`, `credit-transaction.ts`, `client.ts`, `contract.ts`
- `src/components/admin/admin-credit-report.tsx`, `admin-member-credit-panel.tsx`, `admin-release-report.tsx`와 관련 테스트
- `src/lib/my/data.ts`와 테스트, WEB Wiki4개

APP58 현재 worktree를 수정하거나 병합하지 않았다. 표시 파일은 최신 APP58의 KST 시각 표시와 일치하도록 구현했지만 이 오래된 audit checkout 전체를 APP58 위에 덮어쓰면 안 된다. 신규 표시 파일/좁은 history 변경만 선택 통합하고 APP58 테스트를 거친 뒤 앱을 빌드한다. WEB도 승인 시점 최신 배포 SHA와 차이를 재검사해야 한다.

검수: 격리 TEST에서 지급유형8개와 예약·사용·취소·복구·환불 조정을 선택하고 유형 합계/전체합계/페이지/회원필터를 비교한다. 운영 승인 후 SQL→조회/권한 검사→WEB 순서. 실제 베타 grant의 3개 원본 거래가 beta로 보이고 소비1개로 집계되는지 읽기만 확인한다. 신규 운영 테스트 거래나 실제 사용자 평가를 생성하지 않는다.
