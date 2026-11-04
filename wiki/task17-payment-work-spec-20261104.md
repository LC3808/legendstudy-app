# TASK 17 — WEB 결제 구축·운영 전환 작업 명세서

작성일: 2026-11-04 KST. 대상: LegendStudy WEB. 작성 근거는 [실행 기록과 검증 영수증](payment-live-activation-20261104.md)이며, 아래 배포·설정은 마지막 확인 시점 기준이다.

## 1. 현재 결론

**결제 DB·서버·홈페이지 구현과 운영 반영은 완료했다. 홈페이지 반영을 기다리는 상태가 아니다.** TEST 실승인은 통과했으나 최초 LIVE 승인에서 토스 오류가 발생해 신규 결제를 일시 중지했다. LIVE 실제 이용권 지급·환불의 운영 검증은 아직 완료하지 않았다.

| 구분 | 상태 |
|---|---|
| IMPLEMENTED | 완료: DB 준비 변경·서버 분기·WEB 배포 |
| TEST_VERIFIED | 완료: 심사 계정 승인·실제 이용권 미지급 |
| LIVE_VERIFIED | 미완료: 첫 LIVE 승인 실패, 지급·환불 미검증 |
| PRODUCTION_ACTIVE | PAUSED: 배포되어 있으나 신규 결제 중지 |
| 전체 작업 | PARTIAL: 카드사 등록·승인 상태 확인 후 실결제 재검증 필요 |

## 2. 범위와 유지 정책

- 운영 WEB: https://lab.legendstudy.com / Cloudflare Pages `legendstudy-lab` Production.
- 운영 DB: Supabase `stlhijzpjfgwwdgunlsd`. 별도 `legendstudy-lab-payment-test` 프로젝트와 혼용하지 않는다.
- 기존 Order·Payment·Credit·Ledger, Toss 연동, 지급·환불 RPC를 재사용한다. 새 결제 시스템·별도 지갑을 만들지 않는다.
- WEB 사용자·관리자 노출 용어는 ‘이용권’. 논술 상품명에 ‘AI’를 붙이지 않는다. DB 내부 Credit 식별자와 기존 거래 원문은 유지한다.
- APP·StoreKit·Google Play Billing·APP58 산출물, 신규가입·베타·이벤트 무료 지급 정책은 변경하지 않는다.
- 기존 주문·원장은 보존한다. 정상 결제·환불에 따른 기존 RPC의 거래 기록만 허용하며, 수동 지급·과거 기록 덮어쓰기·실패 주문 삭제는 하지 않는다.

| 상품 | 금액 |
|---|---:|
| 논술 첨삭 1회 이용권 | 4,900원 |
| 논술 첨삭 3회 이용권 | 11,900원 |
| 논술 첨삭 5회 이용권 | 17,900원 |
| 논술 첨삭 10회 이용권 | 29,900원 |

기존 3개월 유효기간·환불 정책을 유지한다. 구매 횟수만큼 논술 첨삭을 이용하는 상품이며 충전형 포인트로 설명하지 않는다.

## 3. 구현된 처리 흐름

1. Supabase Auth로 사용자를 검증한다. 비로그인 결제 요청은 차단한다.
2. 서버가 결제 환경을 정한다. 고정 UID와 현재 확인된 이메일이 모두 일치하는 `review@legendstudy.com`만 TEST, 그 외 인증 사용자는 LIVE다. 이메일 재생성·변경으로 TEST 권한이 이전되지 않도록 한다.
3. 기존 `payment_order`가 상품·수량·금액·사용자·환경을 확정해 주문을 만든다. 브라우저의 email/mode/is_test는 환경 결정 근거로 사용하지 않는다.
4. 해당 환경의 Toss Client Key로 결제창을 연다. TEST 계정에는 실제 청구·이용권 지급이 없음을 표시한다.
5. 승인 시 저장된 주문 환경의 Secret Key를 사용한다. 먼저 Toss 상태를 조회하고 주문번호·결제키·상점·통화·금액을 검증한다.
6. Toss 승인 결과 확인 후 기존 `payment_process`로 처리한다. LIVE는 기존 구매 지급·원장에 연결하고, TEST는 `TEST_RECORDED`로 기록하며 실제 이용권을 지급하지 않는다.
7. 중복 요청과 응답 유실은 기존 operation/idempotency/reconciliation 경로로 처리한다. 성공 화면 진입만으로 지급하지 않는다.
8. 취소·환불도 원래 주문 환경을 유지한다. 승인된 운영자는 `admin@legendstudy.com`의 기존 UID로 제한한다. 기존 관리자 DB 권한은 추가하지 않았다.

DB 변경: 비공개 `payment_private.current_order_mode()` 추가 및 기존 주문·처리 함수의 환경 조건 최소 수정. 준비 migration `20261104021443_payment_live_review_prepare` 운영 적용. 별도 `activate.sql`로 configuration을 LIVE로 변경했다. [정확 SQL·복구 절차](../supabase/verification/payments/live-20261104/README.md).

## 4. 마지막 확인된 운영 설정과 배포

| 항목 | 값·상태 |
|---|---|
| DB configuration.mode | LIVE 유지 |
| PAYMENT_MODE | LIVE 유지 |
| PAYMENT_ENABLED | false: 신규 주문·미승인 결제 진행 중지 |
| PAYMENT_REVIEW_SUBJECTS | 기존 review 계정 고정 UID |
| PAYMENT_SUPPORT_SUBJECTS | 기존 admin 계정 UID |
| TEST / LIVE 키 | 각 환경별 기존 Secret 등록·분리 |
| PAYMENT_FINANCE_TOKEN | 기존 signer·subject·role 재사용하여 갱신 |
| 최종 중지 배포 ID | `98e2b121-22d8-4bb5-8f78-a7db72c3a587` |
| 배포 WEB Git SHA | `a901568fa7b0acc752061d6fd7361ad5772875c8` |
| WEB 브랜치 | `codex/toss-test-task17` |
| 실제 runtime | `PAUSED / LIVE / consumer_purchase=false` |

기존 정적 자산 1,463개를 보존했다. 기존 완료 주문의 조회·정합성 복구·환불 경로는 유지한다. 중지 스위치는 TEST 신규 결제에도 적용되므로, 심사 계정 TEST 예외 구현이 남아 있다고 해서 현재 새 TEST 결제가 열려 있다는 뜻은 아니다.

**Finance JWT 만료: 2026-11-11 11:25:53 KST. 자동 갱신 없음.** 카드사 심사 대기 중 만료될 수 있다. 재개 전 기존 서명키·subject를 유지해 안전하게 갱신하고 읽기 전용 RPC 인증을 확인한 뒤 단일 Secret 반영·재배포한다. 전체 환경변수의 redacted 값을 재전송하지 않는다. 키·토큰 원문은 채팅·로그·Wiki·Git에 저장하지 않는다.

## 5. 검증 결과와 한계

| 검증 | 결과·근거 |
|---|---|
| 코드·격리 검증 | WEB 1,563 PASS/4 skip, 최신 운영 소스 통합 후 관련 242 PASS/1 opt-in skip. 빌드·기존 DB 회귀·혼합 모드 21검사 PASS |
| 중복 지급·환불·응답 유실·환경 분리 | 격리 검증 PASS. 실제 LIVE 운영 E2E 완료를 의미하지 않음 |
| 운영 TEST 승인 | 11/4 13:16:46 KST, 1회 4,900원 `PAID / TEST_RECORDED`, grant 없음 |
| TEST 잔액 | 화면 95→95, 실제 구매 이용권 지급0 |
| 전환 후 TEST 예외 | review TEST 배너 및 기존 승인 결과 조회 확인 |
| 기존 기록 보존 | 준비 SQL 전후 주문18·지급167·거래262 hash 동일. 이후 추가된 정상 signup_bonus는 결제 지급과 분리 확인 |
| 첫 LIVE 요청 | admin 계정, 1회 4,900원, `FAILED / PROVIDER_REJECTED`, grant 없음·paid_at 없음 |
| 실제 LIVE 지급·환불·매출 집계 | 미완료. 실결제 승인 성공 후 확인 필요 |

증거: [격리 검증](../supabase/verification/payments/live-20261104/validation.json), [Finance 복구](../supabase/verification/payments/live-20261104/finance-recovery.json), [TEST 승인·활성화](../supabase/verification/payments/live-20261104/activation-validation.json), [LIVE 첫 실패](../supabase/verification/payments/live-20261104/live-first-attempt.json).

## 6. 남은 차단 요소

11/4 13:38:34 KST의 LIVE `POST /v1/payments/confirm`이 HTTP400 `INVALID_UNREGISTERED_SUBMALL`을 반환했다. MID는 `leglabn24k`다. Owner는 카드사 선택 후 앱카드·ISP 인증을 진행했다고 확인했다.

Owner가 사전에 안내받은 내용: 카드사별 승인이 순차적으로 진행되며 최대 약 2주 걸릴 수 있다. 따라서 해당 카드사의 등록·승인 미반영 가능성을 우선 확인한다. 실제 카드사명·완료일·해당 거래의 정확한 원인은 아직 확정되지 않았다. 일정 경과만으로 승인 완료를 간주하지 않는다. [토스 공식 오류 설명](https://docs.tosspayments.com/reference/error-codes).

첫 실패 화면은 ‘결제 상태를 확인해 주세요 / 주문 상태를 확인했습니다’로 표시돼 실패를 명확히 설명하지 못했다. 이 사용자 안내 개선은 후속 항목이며 아직 수정·배포하지 않았다. 키 교체나 임의 submall ID 추가로 문제를 우회하지 않는다.

## 7. 재개 순서와 완료 기준

1. **Owner/Toss:** 이용할 카드사의 하위가맹점 등록·LIVE 승인 반영 완료를 확인한다. 승인된 결제수단 범위를 함께 확인한다.
2. **개발 담당:** 현재 Git·배포·DB·환경 설정을 다시 조회한다. 이 문서의 SHA로 무조건 되돌리지 않고 이후 정상 배포를 보존한다. Finance 만료·키 형식·권한·원래 주문 환경 유지 여부를 검증한다.
3. **개발 담당:** 기존 실패 화면의 명확한 안내를 보완하고 관련 회귀 검증을 수행한다. 실패 주문·기록은 보존한다.
4. **개발 담당:** 신규 결제 활성화 설정과 배포를 통제해 재개한다. review TEST/일반 LIVE 분기와 실제 운영 URL을 확인한다. 재개 중 오류 발생 시 즉시 중지한다.
5. **Owner:** `admin@legendstudy.com`의 새 1회 이용권 4,900원 주문으로 직접 카드 인증·결제를 수행한다. 실행 전에 대상·금액을 재고지한다. 기존 실패 주문을 임의 재승인하지 않는다.
6. **개발 담당:** Toss DONE, DB PAID/POSTED, 정확히 1회 이용권 지급·단일 구매 원장 연결을 확인한다. 동일 결과 재조회·재시도에서 중복 지급이 없어야 한다.
7. **Owner/개발 담당:** 이번 검증용 미사용 주문의 4,900원 환불 대상·금액을 고지하고 기존 승인된 환불 경로로 처리한다. 토스 취소와 DB 환불·이용권 회수·중복 방지·관리자 매출 구분을 확인한다. 기존 고객 거래는 사용하지 않는다.
8. **개발 담당:** 변경 코드·검증·최종 배포 ID·Git SHA·운영 URL·남은 제한을 Wiki에 기록하고 Commit/Push한다. 실제 LIVE 승인·지급 확인 전에는 LIVE_VERIFIED로 보고하지 않는다. 전체 완료에는 환불 검증도 포함한다.

문제 발생 시 `PAYMENT_ENABLED=false`로 신규 결제만 중지한다. LIVE 주문이 존재하므로 DB를 TEST로 되돌리거나 주문의 mode·원장을 수동 수정하지 않는다.

## 8. 운영 경로

- 로그인: https://lab.legendstudy.com/login/
- 이용권 구매: https://lab.legendstudy.com/pricing/
- 성공·상태 확인: `/payments/success/` (해당 주문으로 진입)
- 실패 안내: `/payments/fail/`
- 관리자 결제 확인: https://lab.legendstudy.com/admin/payment/

현재는 카드사 확인 대기 상태이며, 이 명세서 작성 자체는 신규 결제 재활성화나 추가 실결제 실행을 의미하지 않는다.
