# 논술 LAB 무료 베타 Credit — 계약 분석·최소 변경안

2026-10-27 Owner P1. **A 설계 완료 / B 정책 함수 격리 시제품만 완료 / Production 미적용.** 새 지갑을 만들지 않는다. 지급·예약·사용·반환·무료 재첨삭은 기존 원장을 사용한다. 본 문서는 기존 [Credit 운영](admin-credit-operations-20261027.md), [결제 계약](payment-app-foundation.md), [쿠폰 설계](school-history-and-coupon-design-v1.md), [학습 이력 보존](longitudinal-learning-admissions-data-strategy.md)을 확장한다. 이전 운영 SQL을 재실행하지 않는다.

## 확인 근거 — 운영 읽기 전용

대상 `stlhijzpjfgwwdgunlsd`. 개인정보 행을 조회하지 않고 pg_proc/컬럼 정의를 확인했다.

|계약|확인 결과와 재사용|
|---|---|
|`essay_private.credit_post_grant`|promotion origin·expires_at·external_reference·Ledger 원자적 지급 지원. 계정 잠금 및 같은 키의 수량/만료/사유 일치 검사. 그대로 재사용|
|`credit_grants` / `credit_transactions`|지급 단위 ID·만료일·멱등키·actor/reason·balance/reserved delta 존재. 별도 잔액 컬럼/지갑 불필요|
|`essay_exam_private.reserve`|회차당1, 무료 재첨삭0. 현재는 만료일→생성일→ID 순. 시험별 grant 사용 제한 없음|
|`essay_private.credit_request_v2`, `math_private.authorize_billing`|별도 기존 경로도 만료일 우선 선택. 베타 grant가 이 경로에서 새어나가지 않도록 필터 필요|
|`essay_exam_private.finish`|기존 reserve 거래의 같은 grant를 consume/release. 완료 시 만료일 재검사 없음: 자정 이전 예약은 이후 완료 가능|
|`public.credit_summary`|만료 시각이 지난 grant와 CANCEL_PENDING 구매분은 가용잔액 제외. paid/free/other 합산; 베타는 promotion이라 현재 other에 포함|
|관리자 지급|무기한/기간/직접일 지정 구현됨. 관리자가 매일 수동 지급하는 구조로 대체하지 않음|
|가입·구매·재첨삭|가입3 무기한, 구매3개월, 회차 재첨삭14일·기존 횟수 유지. 가격/정산/환불 변경 없음|
|쿠폰|Wiki는 설계 문서, 운영 함수 이름 조사에서 coupon RPC 미발견. 이미 운영된 쿠폰 기능으로 단정하지 않음|
|피드백|기존 feedback_submissions에 작성자·내용·category·시각 있음. 평가 ID·만족도·보상 binding은 없음|

만료는 현재 조회/예약 시 expires_at 필터로 사용 불가 처리한다. `expiration` 거래를 읽는 관리 함수는 있지만 이번 함수 조사에서 만료 원장 posting 작업은 확인되지 않았다. ‘기존 자정 배치가 있다’고 가정하지 않는다. 새 배치 없이 가용성은 보장할 수 있으며 만료 통계는 아래 파생값으로 명시한다.

## 결정할 최소 구조

새 공개 지갑이나 지급 origin을 추가하지 않는다. `promotion` 지급분에 별도 private **캠페인/시험 범위/지급 연결/피드백 연결**만 둔다(4개 작은 관계; 이름은 migration 검토 시 확정).

- 캠페인: ID, KST 시작일/종료일, enabled, daily_quantity=2, revision, 관리자/변경시각. 기본5일, 최대7일(양끝 날짜 포함). 과거 지급 의미를 바꾸는 수정 금지; 변경은 기존 감사 기록에 before/after 보존. 중첩 활성 캠페인은 서버에서 거부해 하루4개 지급 방지.
- 시험 범위: campaign_id+exam_id+공개/실행 정책 revision 또는 digest+평가 유형+혼합형 Owner QA 근거. 기존 공개 승인과 AND 조건. 전체 문항 연결/현재 공개/실행 승인 변경 시 재판정. 대학명 문자열·클라이언트 유형 신뢰 금지.
- 지급 연결: grant_id, campaign_id, user_id, kind(daily/feedback), KST 지급일. daily는 **user_id+KST일** unique(캠페인 교체로 같은날 재지급 금지). feedback는 **user_id+보상 프로그램** unique(이번 베타 프로그램 전체1회). 잔액은 저장하지 않는다.
- 피드백 연결: 기존 feedback_id, 본인 완료 run/result ID, rating, 오류유형, 보상 grant_id. 시험·문항은 결과 snapshot에서 서버가 유도. 자유 의견은 기존 feedback body에만 저장, 답안/History 복제 금지. 평가 결과 ID와 회차 ID는 혼동하지 않고 소유 관계를 검증한다.

새 private 관계는 클라이언트 직접 쓰기 금지, RLS 방어 적용. 기존 authenticated/API 경로에서 서버 주체를 검증하고 고정 search_path 및 최소 EXECUTE 권한. 사용자ID/날짜/수량/만료일/승인상태를 클라이언트 입력으로 결정하지 않는다. 기존 계정 제한 검사 유지.

## 지급·시간·멱등성

서버 transaction의 기준 시각을 한 번 잡는다. KST일 d의 첫 LAB 접속에서 enabled·기간·계정 조건 검사 후 계정 잠금 → 기존 daily binding 확인 → `credit_post_grant` → binding을 같은 transaction으로 commit한다. 실패하면 모두 rollback. 요청 UUID가 바뀌어도 자연키가 같아 중복 지급되지 않는다. reference 예: `lab-beta:daily:<user>:<KST-date>`(서버만 생성).

만료는 **다음 KST 날짜 00:00:00, exclusive**다. 23:59:59를 쓰면 마지막1초가 누락되므로 일일권은 반열린 구간으로 처리한다. 기간 종료도 종료일 다음날00:00 exclusive. 접속하지 않은 날은 지급하지 않고 다음날 이월/소급 지급 없음. 응답 유실 후 같은 날 재접속은 기존 grant 반환. 날짜가 바뀌면 전날 grant 재사용 없이 새날2개 지급.

한 transaction에서 선택한 기준 시각은 예약 직전에도 경계/만료를 다시 확인한다. 자정 전 quote만 받아둔 요청은 예약이 아니므로 자정 뒤 기존 grant를 사용할 수 없다. 예약이 이미 완료된 동일 요청 재시도는 현재 캠페인 종료 여부보다 기존 request_key 복원이 우선이다.

자정 이후 성공은 기존 reserve→consume, 실패는 reserve→release. 만료된 grant로 release된 수량은 가용잔액에 돌아오지 않는다. 새 grant로 보상/이월하지 않는다. 이미 접수된 요청·성공 checkpoint·무료 재첨삭14일은 캠페인 종료로 취소하지 않는다.

## 차감·범위 — 승인 필요한 정산 의미 변경

현재 만료일 우선은 무기한 가입권보다 유료 구매권을 먼저 선택할 수 있다. 베타 시험에 한해 다음 최소 변경을 제안한다.

1. 유효한 당일 베타 grant
2. 가입 보너스
3. 피드백 보상 및 기존 promotion/admin/compensation/b2b(같은 등급 내 기존 만료일·생성일·ID 순)
4. 유료 구매

3번은 Owner가 지정하지 않은 기존 운영 지급분의 위치에 대한 **제안**이며 승인 전 확정 정책으로 배포하지 않는다. beta가 아닌 경로의 기존 일반 grant 순서는 그대로 유지한다. 구매 취소 fence 및 계정 제한은 모든 경로에서 유지한다.

일일권은 기간 내 승인된 시험에만 허용한다. 부분 제출로 Math 문항을 빼도 회차 전체가 미검증 혼합형이면 허용하지 않는다. 자연/의예/과학은 금지. 혼합형은 실제 Math 포함 여부와 Owner QA snapshot 확인. 현재 승인과 달라졌으면 fail closed.

피드백 보상은30일 사용기한이므로 베타 종료 후에도 잔액을 보존한다. **승인된 인문/사회/검증 상경 범위에서 사용 가능**하게 하는 안을 제안한다; 자연 서비스 공개 우회 불가. 캠페인 종료 뒤 보상 사용범위는 별도 확인이 필요한 정책 사항으로 남긴다.

중요: 기존 reserve에만 조건을 추가하면 legacy Essay/standalone Math에서 promotion을 소비할 수 있다. 모든 grant 선택 경로를 목록화하고 베타 binding이 있는 grant는 미지원 경로에서 제외해야 한다. 기존 정산·Ledger posting은 변경하지 않고 선택 부분만 변경한다. quote와 submit은 같은 판정 함수를 사용하며 submit에서 잠금 후 재검사한다. beta가 부족해 가입/유료로 넘어갈 때 서버 확인창에 실제 사용 출처를 표시하고, quote 이후 출처가 바뀌면 재확인을 요구한다.

## 피드백 보상

베타 기간 중 본인 완료 회차가 존재하고 기간 중 의견을 제출한 계정에 프로그램1회2 Credit. 평점/긍정·부정 여부는 자격에 사용하지 않는다. 상태가 진행/실패인 결과, 타인 결과, 다른 시험/문항 ID 조작은 차단한다. 기간 중 시작했지만 종료 후 완료된 회차는 결과는 보존하되 현재 정책상 기간 중 피드백 보상 대상은 아니다.

피드백 저장+보상 binding+기존 promotion grant를 같은 transaction으로 처리한다. 만료는 최초 지급 서버시각+30×24시간, 재시도 시 최초 expiry 재사용. 보상 여부는 grant binding/원장에서 유도하며 독립 boolean으로 중복 관리하지 않는다. 지급 실패로 의견만 남는 부분 성공 금지. 일반 문의 접수는 기존 경로로 계속 가능하되 그 경로로 보상을 자동 생성하지 않는다.

개인정보처리방침 코드 `src/lib/legal-documents.ts`에는 문의/오류 대응은 있지만 평가결과 연계 만족도·보상 목적/보유기준은 명시되지 않았다. 또한 ‘무료 Credit은 무기한’ 문구는 베타·30일보상과 충돌한다. 출시 전 가입3은 무기한, 기간제 프로모션은 고지된 기한으로 분리하고 피드백 연결 목적·항목·보유기간을 Owner와 확정해야 한다. 기존 문의3년 보유를 모든 연구용 피드백에 자동 적용하거나 법적 적합성 확인 완료로 보고하지 않는다. 답안의 모델 학습/마케팅 이용으로 확대하지 않는다.

## 관리자·WEB·APP

기존 관리자 Credit 화면에 캠페인 설정·통계 필터를 추가한다. 누적 지급은 연결된 grant의 최초 양수 posting, 실제 사용은 consume, 피드백은 kind별 합산. **만료 미사용(파생)**은 만료 grant의 현재 max(balance-reserved,0); 자정 후 consume/release에 따라 변할 수 있으므로 as_of를 표시한다. 만료 Ledger가 실제로 존재하지 않으면 ‘만료 거래’로 표시하지 않는다. 참여자는 지급받은 distinct user, 완료참여자는 별도 distinct completed run owner로 구분한다.

LAB 진입에 WEB/Native가 동일 claim RPC 호출 후 기존 credit_summary 새로고침. 기존 paid/free/other DTO 의미 보존, 베타별 상세는 추가 조회 DTO로 제공. 모든 헤더는 서버 합계 사용. 등록·로그인 화면 진입만으로 지급하지 않는다. 자연시험만 사용하려고 들어온 경우에도 LAB 접속 지급조건은 충족하지만 사용범위는 서버가 제한한다.

문구: ‘논술 LAB 무료 베타 / 오늘 남은 무료 첨삭권 N개 / 매일 첫 논술 LAB 접속 시2개 지급되며, 당일 자정에 만료됩니다. / 가입·유료 Credit은 별도로 유지됩니다.’ 자정에 미접속자까지 자동 지급한다고 안내하지 않는다. APP 동적 잔액은 기존 Backend 재사용, LAB 접속 claim·출처 확인 UI는 Native 코드 연결 필요; 구현/실기기 확인 전 완료로 보고하지 않는다.

## 최소 구현 경계 및 검증

후속 구현은 새 campaign admin RPC, daily claim RPC, feedback reward RPC, scoped summary 조회와 기존 grant 선택의 제한적 변경이 필요하다. 관리자/조회는 기존 관리 dispatcher 재사용 가능성을 먼저 확인한다. 새 지갑·새 만료 스케줄러·결제/Toss 수정 없음. 최종 migration은 실제 baseline hash·ACL·호출 경로 대조 후 precheck/apply/postcheck/rollback으로 별도 승인받는다.

이번 구현: [정책 SQL 시제품](../supabase/candidates/essay_beta_credit_20261027/policy.prototype.sql), [격리 검사](../supabase/candidates/essay_beta_credit_20261027/test_policy.sql). PostgreSQL17 신규 loopback55447 임시 DB, 전체 transaction rollback 및 서버 종료. KST 자정 경계·5/7일·기간 전후·공개/전체문항/혼합QA·제외유형·차감순서23검사 PASS. 운영 데이터/기존 격리 DB를 쓰지 않았다.

**미검증**: 실제2Credit 지급, 동시2기기 claim, 피드백 원자성/중복, 예약 후자정정산, 실패release, 무료재첨삭, 원장불변, UI·Native. 시제품은 순수 정책 함수이므로 이를 실제 금융 통합 통과로 보고하지 않는다. 다음 구현에서 기존 지급/예약 함수의 운영 정의를 격리 복제하고 합성 사용자로 아래를 확인해야 한다.

- 같은 날짜 다중기기/다른키100회 → grant1·+2; 다음날 별도+2
- 자정 직전/직후·기간 종료·기간 연장/중첩·계정 제한·비로그인
- 가입/유료/관리자/예약/만료혼합 잔액 및 구매취소 fence 보존
- 예약1 → 자정 후 성공consume1 또는 실패release1; 가용성0/중복정산0
- 무료 재첨삭0, 기존1회·14일 자격 보존; 종료후 기존요청 복원
- 승인시험 외/다른API/선택문항조작 시 베타 사용0
- 본인완료 보상1회+2/30일, 타인/실패/중복/의견변조 차단, 부정평점도 동일보상
- 운영 적용 전 기존 Ledger·History immutable 및 기존 거래회귀

## 보존 검토 7항목

1. 지급·예약·사용·의견 제출·정정의 발생시각/기록시각 구분.
2. grant/transaction/run 원본으로 당시 잔액·자격·정책revision 재현.
3. 원장·기존 평가 UPDATE/DELETE 금지, 캠페인 변경 감사 보존.
4. 기존 auth.users 동일주체; 클라이언트 user_id 권한 신뢰 금지.
5. 피드백은 서비스 개선 자기보고, 학습 성과나 합격 Outcome으로 간주하지 않음.
6. 본인/운영권한만 접근, 의견 최소수집·목적/보유기간 확정 전 수집 활성화 금지.
7. 잔액·만료·참여 통계는 as_of 파생값이며 실제 원장 거래와 구분.

## 운영·롤백

Production 변경0, 실제 지급/회수/예약/Provider0. WEB·APP 배포 없음. 지금 적용할 Production SQL은 없으며 prototype은 실행 승인용 파일이 아니다. 코드 롤백은 이 설계/시제품 commit만 revert하면 된다. 후속 출시 rollback은 신규지급·보상을 먼저 off하되 기존 예약finish/release 및14일재첨삭은 유지한다. **베타 grant가 남아 있으면 예전 무제한 allocator로 되돌리지 않는다**; 범위 차단을 유지하며 지급내역/History를 삭제하지 않는다. 이미 지급된 feedback 보상30일 권리도 보존한다.


## 2026-10-27 — 일일 지급 런타임 구현, 운영 승인 대기

Owner P0-1에 따라 설계를 실제 SQL 및 WEB/Native 코드로 구현했다. Production 미적용·캠페인 미활성 상태이며 베타 출시 완료가 아니다.

- SQL: `supabase/candidates/essay_beta_credit_runtime_20261027/README.md`. private 관계3개, 본인 claim RPC1개, 기존 allocator6곳의 선택부만 수정. 기존 non-beta 지급분끼리 순서는 그대로 유지한다. 캠페인/회차를 임의 활성화하지 않는다.
- 일일 사용자+KST일 unique, 계정 잠금, 기존 grant/원장 재사용, 다음날00시 만료, exact exam/runtime/full-question scope, 미지원 legacy/Math에서 beta 제외. 기존 reserve/finish의 재시도·실패해제·만료후 예약 정산 보존.
- WEB: LAB layout의 self-scoped claim, 계정 전환 응답 격리, 자정/포커스/잔액 변경 갱신, RPC 미설치·캠페인 비활성 시 숨김.
- APP: 기존 Native LAB 진입에 동일 RPC 연결, 서버 잔액 표시·복귀/자정/잔액 변경 갱신. APP 배포/실기기 확인은 미완료.
- 격리 PostgreSQL17 합성 계정34검사 PASS(100동시claim 포함), 운영 read-only 사전7 true. 실제 운영 회원 지급/예약/차감/Provider 호출0. Legacy/Math5경로는 변경된 SELECT 직접 실행 검사이며 엔진 E2E가 아니다.
- WEB 관련17검사·타입·변경파일 lint·Node22 build PASS. Native DTO3검사·변경파일 analyze PASS. 운영 화면 확인 및 배포는 아직 하지 않았다.

### 활성화 전 남은 항목

1. 신규 Production SQL Owner 승인 및 적용/사후검사. 승인 요청된 패키지는 캠페인 비활성 설치만 포함한다.
2. 기존 설계의 **quote에 실제 사용 출처 표시 및 quote→submit 출처 변경 시 재확인**은 미구현. 가입·유료로 자동 전환되는 혼동을 막기 위해 이를 연결하기 전 캠페인을 활성화하지 않는다. 추가 RPC 의미 변경은 별도 영향/승인 필요.
3. 실제 캠페인 시작·종료일과 허용 시험 범위 확정, WEB/APP 실제 연결 확인. 피드백 보상은 이번 최소 구현에 포함하지 않는다.
4. 5대학 STANDBY 선행 미완료는 [현황](essay-all-university-standby-20261026.md) 그대로 유지. 코칭/537표시명 완료로 간주하지 않는다.

복구는 후보 `rollback.sql`로 캠페인 중지. 기존 지급/원장/예약은 보존하며 beta 지급 이력이 있으면 무제한 구 allocator로 복귀하지 않는다. 미적용 후보이므로 재실행 금지 적용 이력은 아직 없다.

### 승인 후 적용 시도 — 내부 역할 차단

Owner SQL 설치 승인 수신. 운영 사전7 true 이후 apply_migration 두 시도는 owner/SET ROLE 권한 오류로 모두 rollback. 다시 사전7 true, 신규schema 부재 확인. 운영 기능 설치·지급·캠페인 활성화0.

실제 원인: postgres는 essay_executor ADMIN membership을 갖지만 INHERIT=false/SET=false. 내부 owner 유지/테이블 직접 접근 차단을 보완한 격리37검사 PASS. 한시 SET membership을 같은 transaction 안에서 부여/자기 grantor만 회수하는 정확한 파일 `apply-with-temporary-role.sql` 준비. 기존 supabase_admin membership 유지 검증. 이 권한 변경은 별도 Owner 승인 요청이며 아직 실행하지 않았다. 기존 출처 quote-submit GAP도 유지.

### Production 비활성 설치 완료 — 2026-10-27

Owner의 한시 역할 권한 승인 후 migration `20261027040022` (`essay_beta_credit_runtime_20261027`) 성공. 적용 파일 `supabase/candidates/essay_beta_credit_runtime_20261027/apply-with-temporary-role.sql`, 재실행 금지. 사전7·사후11·역할/소유자5·기존 credit_post_grant/finish2 모두 true. 임시 SET/CREATE 권한 원복 및 기존 supabase_admin membership 보존. 신규 캠페인0/베타지급0, 운영 회원 지급·차감·Provider 호출0. 기존 History 테이블 변경 없음.

Security advisor: beta private3테이블 RLS/no policy INFO는 클라이언트 접근 차단 의도와 일치. authenticated claim SECURITY DEFINER 경고는 auth.uid/account.allowed 검증을 거치는 본인 지급용으로 의도된 공개 RPC이며 익명 실행/직접테이블 접근 차단 확인. 나머지 전체 프로젝트 경고는 이번 작업에서 변경하지 않았다.

**DB 설치만 완료. WEB·APP 배포/운영 베타 활성화 완료가 아니다.** 사용 출처 quote-submit 확인과 캠페인 기간/대상 확정이 남는다. 복구는 후보 rollback.sql 캠페인 중지이며 기존 원장/예약/정산 유지. 정확한 적용 파일 hash와 결과는 `production-installation.json`에 보존.
