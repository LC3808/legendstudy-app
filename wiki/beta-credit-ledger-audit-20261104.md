# 베타 무료 첨삭 원장 읽기 전용 감사 — 2026-11-04

최종 판정 **PARTIAL**. 대상 거래의 베타 지급·예약·정산은 PASS. 관리자 분류/표시와 실패 시 예약 복구의 경로 차이는 후속 검토가 필요하다. 운영 SELECT와 함수 정의 조회만 수행했다. 지급/예약/취소/평가/결제/환불/배포 0회. 제품 코드·DB·표시 문구 변경 없음. 문서만 갱신.

## 1. 실제 거래와 원인

대상 프로젝트 `stlhijzpjfgwwdgunlsd`. 2026-11-04 KST 감사 시점의 운영 원장 기준.

공통 grant ID: `02ee324f-f82f-49f0-9524-79d227a8425f`.

| KST 시각 | 거래 ID | 유형 / reason_code | 잔액 증감 | 예약 증감 |
| --- | --- | --- | ---: | ---: |
| 11-04 01:20:20.471699 | a79efa0f-eb34-471c-a6e9-6d398335271a | promotion / essay_beta_daily | +1 | 0 |
| 11-04 01:20:53.219737 | b8e3f353-a2c8-49ec-88a6-cacb49331dce | reserve / essay_exam_initial | 0 | +1 |
| 11-04 01:21:04.062729 | e00c2e53-84b8-437b-b681-d3d0560dc7d0 | consume / essay_exam_finalization | -1 | -1 |

- 지급 origin/source는 `promotion`, 정확한 사유는 `essay_beta_daily`. `essay_beta_private.daily_grants`의 11-04 일자 및 campaign `cfc56a2b-8fbd-4c2a-a200-e55b509ad972`에 연결된다. **A: 베타 일일 무료 첨삭 지급**이며 별도 이벤트/가입/관리자/보상 지급이 아니다.
- 유효기간: 11-05 00:00 KST. 무료 재첨삭 cutoff: 11-11 00:00 KST. 1회 첨삭에 쓰는 기존 공통 원장의 promotion grant이며 별도 지갑이 아니다.
- 지급 자체는 decision_id가 NULL이다. 제출 전 claim으로 발급하고 이후 예약이 동일 grant를 사용한다. 따라서 발급과 요청 연결은 grant→reserve→decision으로 확인한다.
- 예약/정산 decision: `da9eb8ad-07d1-4e9f-9d51-76a8c6a487ee`, `settled`, credits_required=1, policy_version=`math-session-v1`. reason=`paid_cycle`은 1Credit 회차를 뜻하는 내부 값으로 현금 구매 증거가 아니다.
- Math session run: `a8147d8a-ab21-4345-8a9a-2a077b85313f`, 최초 회차(index1, parent/previous NULL), completed. 평가: `4539b56f-63b7-471b-acb7-6bf34cdac25b`, MATH_INITIAL_EVALUATION / COMPLETED. 시험: **2027학년도 인하대학교 모의논술 자연계열**, exam ID `70b0ddd5-0816-5395-8ac5-6a4e3664a282`.
- decision.evaluation_id는 NULL이지만 `math_private.session_runs → session_members → session_evaluations`로 평가가 연결된다. 이를 미연결 평가로 판단하면 안 된다.
- 해당 grant의 기록은 위 3건뿐이다. release/refund/reversal 없음. 최종 잔액0/예약0, 지급1·확정사용1이다. 01:21의 별도 admin_grant 예약은 이 거래와 무관하다.
- 관리자 행의 “보유 잔액 0”은 **예약 거래의 balance_delta=0**이며 당시 계정 잔액이 0이라는 의미가 아니다. 지급 후 해당 grant는 잔액1/예약0, 예약 후 잔액1/예약1(사용 가능0), 정산 후 모두0이다.

## 2. 정책과 실제 서버 계약

| 점검 | 판정 및 근거 |
| --- | --- |
| 하루 1회 | PASS(운영 정의/데이터). daily_grants PK(user_id,grant_day), grant_id UNIQUE, subject/account 잠금, claim 기존 grant 반환. 현재 캠페인 daily_limit1/daily-v2. |
| WEB·APP 공통 | 같은 회원 UUID에 대해 PASS. 모두 claim_v2와 공통 credit_source/원장 사용. 플랫폼별 별도 지급 없음. 다른 회원 ID 사이 동일인 중복까지 보장하는 베타 계약은 아니다. 해당 거래의 실제 접속 플랫폼은 원장만으로 NOT_VERIFIED. |
| KST 자정 | PASS(정의/데이터). 서버 clock의 Asia/Seoul 날짜, 다음날 자정 expires_at. 잠금 대기 뒤 시간을 다시 읽는다. 자정에 배치 지급하는 방식이 아니라 다음 유효 제출 전 claim이다. |
| 미사용 이월 | PASS(정의). 만료 grant는 선택 대상 제외. 과거 원장 잔액 기록은 삭제하지 않는다. |
| 종료 | PASS(정의). starts_on11-01, ends_on11-10 포함, 11-11 00:00 KST부터 신규 claim 불가. 미래 실제 시각 E2E를 수행했다는 의미는 아니다. |
| 가입 무료3 | 별도 signup_bonus / signup_bonus_v1, 3개, 만료 NULL. account_benefit_claim은 기존 delivery/가입 grant 및 benefit marker를 확인하여 중복 지급 억제. 베타와 합쳐 지급하거나 가입3개를 일일1개로 대체하지 않는다. |
| 사용 우선순위 | 적격 베타 먼저, 이후 expires_at(NULL LAST)→created_at→id. **가입3개가 모든 유료권보다 우선한다는 별도 규칙은 없다.** 무기한 가입권보다 만료일 있는 유료권이 먼저 선택될 수 있다. 오래된 초기 제안의 beta→signup→other→paid를 현재 정책으로 인용하지 않는다. |
| 중복 요청 | account 잠금, 동일 request_key 재사용 시 기존 session 반환, 내용 충돌 거절. 이미 session/evaluation에 묶인 attempt 재사용 거절. 새로운 정상 요청까지 모두 중복으로 보는 계약은 아니다. |
| 실패 시 복구 | PARTIAL. 일반 Essay finish 실패는 release로 예약 해제. **대상 Math session은 실패 문항의 명시적 재시도를 위해 기존 예약을 유지**하고 추가 예약 없이 재사용한다. session_release는 계정 삭제 경로의 해제다. 모든 실패 즉시 복구로 설명하면 부정확하다. 기존 회차/checkpoint 보존 계약과 일치하므로 일괄 release 수정은 권장하지 않는다. 포기/장기 실패/만료 예약 처리 UX와 정책은 별도 검토 대상. |
| 무료 재첨삭 | 최초 완료 후 같은 문제 세트 1회, included_revision/credits_required0, 새 reserve/consume 없음. 대상 Math는 완료+336시간과 베타 revision_cutoff 중 이른 시각까지. 이미 무료 회차가 있으면 추가 무료 생성 금지. 다음 유료 회차는 다시1Credit. 실제 대상 사용자에게 재첨삭을 실행하지 않았다. |

전체 운영 daily_grants **3건**, 사용자·일자 중복0, 지급1개 불일치0, origin 불일치0, 다음 KST 자정 만료 불일치0, campaign 종료 cutoff 불일치0. 감사 시점 만료된 베타 예약0, 미만료 베타 사용가능 잔액0. 이는 당시 스냅샷이며 동시성 부하시험 결과가 아니다.

## 3. 관리자 통계와 표시

실제 WEB `admin-release-report.tsx`는 `admin_release_report`를 사용한다. 동일 credit_transactions/credit_grants 원장을 읽으며, reserve=balance0/reserved+1, consume=balance-1/reserved-1이므로 지급·사용을 이중 계상하지 않는다. dashboard 분기의 credit_used도 consume만 합산한다. “원장 기록 수”는 평가 건수가 아니다.

다만 분류는 purchase/free/admin/consume/expiration/reversal/reservation이다. **free에 signup_bonus·promotion·compensation·b2b_program이 합쳐져 가입/베타/일반 이벤트 별도 통계 요구를 충족하지 못한다.** reserve와 release도 reservation 그룹에 함께 들어가며 별도 필터가 없다. release RPC projection에는 reason_code/grant_id/베타 분류가 없어 WEB 문자열만 바꾸면 모든 promotion을 베타로 오표시하게 된다.

다른 기존 집계도 구분해야 한다:

- `analytics_free_credit`: 가입권 코호트 통계이며 전체 무료/베타 통계가 아니다.
- `admin_dashboard`: consumed_total이 음수 balance_delta 전부를 합산하는 구형 정의다. 향후 음수 환불/조정이 있으면 사용 통계와 달라질 수 있다. 현재 운영 음수 non-consume은0건이라 현시점 오차는 발견하지 못했다.
- `admin_credit_snapshot`: 미만료 beta를 포함. 사용자 `credit_summary`는 scoped beta를 제외. 잔액 숫자의 범위가 다르다. 관리자도 일반 보유권/베타 일일권을 구분하는 편이 정확하다. 현재 미사용 beta0이라 당장 차이는0이다.
- 미만료 grant만 합산하는 관리자 예약 headline은 만료 후 진행 중 예약을 누락할 수 있다. 현재 해당 beta 사례0이며 잠재적 집계 한계다.

현재 `creditTransactionLabel(promotion)` 및 `creditOriginLabel(promotion)`은 “이벤트 지급”. 넓은 원장 분류상 허위는 아니지만 **실제 베타 정책을 설명하기에 부적절**하다. 사용자 공통 formatter도 promotion을 “프로모션 지급”으로 묶는다.

권장 표시:

- beta binding이 확인된 지급: **베타 무료 첨삭 이용권 지급**
- 예약: **첨삭 이용권 사용 대기**, 출처 **베타 일일 무료**
- 가입 지급: **신규가입 무료 이용권 지급**
- 수치: **보유 잔액 증감 / 사용 대기 증감**. 거래 후 잔액이 필요하면 별도 계산/표시한다.

과거 거래는 daily_grants.grant_id 및 지급 reason_code로 읽기 시점에 분류하고 원본 source/type/ID/시각을 유지한다. 증거가 없는 promotion은 일반 이벤트로 유지한다. 향후 거래에도 동일 분류를 적용한다. 원장 backfill·복제·금액 수정은 필요 없다.

## 4. 수정 범위와 검증 한계

필요한 후속은 **조회 RPC/DTO의 의미 분류 필드·통계 분리와 WEB/APP 표시 계층**이다. admin_member_credit는 reason_code를 이미 반환하지만 release report는 읽기 projection 확장이 필요하다. DB 쓰기/지급·정산 로직 변경을 이번 감사에서 제안하지 않는다. 실패 복구 정책을 변경하려면 Math 재시도 및 checkpoint 보존 계약을 먼저 확정해야 한다. 이번 운영 변경/배포는0회이며 제안 적용은 별도 승인 작업이다.

기존 로컬 WEB 테스트 5파일 **61/61 PASS**: essay-beta-credit, credit-source, exam-session-submit, credit-display, beta-expansion. mock/클라이언트 계약 검사이며 새 운영 E2E가 아니다. pnpm 최초 실행은 연결된 node_modules 보호로 중단됐고, 기존 vitest 직접 실행에서 캐시 접근 허용 후 PASS. Node24 환경(프로젝트 요구22), jsdom navigation 경고가 있어 정식 빌드 인증으로 확대하지 않는다. 운영 실제 자정/종료/동시 WEB·APP 제출/실패·무료 재첨삭 재현은 이번에 미실행. 과거 daily-v2 Wiki의 격리33 assertion 그룹은 역사적 근거이며 이번 재실행 결과가 아니다.

근거는 운영 pg_get_functiondef와 원장 SELECT, 현재 WEB 코드 및 더 최신 APP58 Wiki를 교차 확인했다. 이 감사 checkout의 Oct27 “캠페인 비활성” 기록은 현재 운영과 불일치하여 최신 감사 링크로 정정했다. 최신 정책 근거는 APP checkout의 `wiki/essay-beta-daily-v2.md`, `wiki/decisions.md`, `wiki/app58-expanded-production-connection-20261104.md`, `wiki/math-technical-review-20261026.md`; 기존 계약은 [Credit G1](essay-lab-product-v1.md), [베타 초기 설계 이력](essay-beta-credit-design-20261027.md), [관리자 Credit](admin-credit-operations-20261027.md).

Git 기준:

- 감사 시작 APP checkout: `fb58fa4b9d05d4050de6b6746fa591743d69d86c`
- 현재 WEB 배포 소스/테스트: `0e735c6fbf74d3351cbb8eca9915b1c650c37251`
- 최신 APP58 정책 교차확인 checkout: `0236d58a32dfa567eb4f4b39759b171ca2ff513d` (앱 배포 증거로 사용하지 않음)
- 운영 DB에는 Git SHA를 추정 부여하지 않았다. 운영 함수 정의를 직접 확인했다.

읽기 재검증 예시(개인정보/답안 제외):

```sql
select t.id,t.grant_id,t.decision_id,t.transaction_type,t.reason_code,
       t.balance_delta,t.reserved_delta,t.created_at,t.reversal_of,
       g.origin,g.expires_at
from public.credit_transactions t
join public.credit_grants g on g.id=t.grant_id
where g.id='02ee324f-f82f-49f0-9524-79d227a8425f'
order by t.created_at;
```

검수 시 관리자 이용권 내역을 11-04 01:20~01:22 KST로 조회하고 위 3개 ID/증감을 비교한다. 실제 평가나 이용권 버튼을 실행할 필요가 없다. 과거 기록의 표시 개선과 금액 수정은 다른 작업이며 후자는 필요하다는 근거가 없다.

Wiki handoff 검사: 도메인 검사10개 PASS, current-status 11,869 bytes로 12KB 이내. 전체 링크 검사는 기존 TASK16 문서의 외부 상대경로 20개 누락으로 FAIL이며 이번 감사 링크의 신규 오류는 없다.

후속 Owner 승인: [지급 유형·통계 구현(운영 미적용)](credit-classification-20261104.md). 이 감사 당시 결과는 보존한다.
