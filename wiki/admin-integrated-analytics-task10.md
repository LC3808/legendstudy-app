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
