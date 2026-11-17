# Toss LIVE Owner QA 재시험 사전 점검 — 2026-11-15

상태 **PARTIAL / 승인 요청 가능한 최종 활성화 단계 아님**. 이번 조사에서 PAUSED 해제·Secret 갱신·정책 변경·DB 쓰기·주문 생성·결제·환불·배포는 수행하지 않았다. 기존 결제 구현을 재개발하지 않는다.

## 기준과 최신 지시

기존 감사: WEB `codex/lab-admin-operations-20261114` 작업트리의 `wiki/toss-live-approval-audit-20261115.md`, Git `16be93159aeced63368765cafa00bfb680853869`. 실제 위치는 `/Users/woojinchang/.codex/worktrees/lab-admin-operations-20261114/legendstudy-release-20261024/wiki/toss-live-approval-audit-20261115.md`다. 이 APP 작업트리에는 원문이 없어 해당 WEB 원문을 직접 읽었다. [11/4 작업명세](task17-payment-work-spec-20261104.md)의 일반 LIVE 공개·환불 사전승인은 최신 지시로 제한된다.

최신 범위: 기존 admin@를 Owner QA로 사용, review@ TEST 유지, 일반 사용자 차단. PAUSED 해제 및 QA 활성화는 사전 점검 완료 후 정확 변경안을 보고하고 Owner 승인 뒤 실행한다. 실제 결제는 Owner가 수행한다. 환불은 별도 승인 전 실행하지 않는다.

## 직접 확인 결과

| 항목 | 결과 |
|---|---|
| 현재 운영 | Cloudflare legendstudy-lab Production, canonical `9105e9e8-3606-472d-976e-2b2ab493438e`, source `902057cb663b4cd131bd5f054806d44619ca80fd` |
| 스위치 | PAYMENT_MODE=LIVE / PAYMENT_ENABLED=false. 운영 runtime POST200 PAUSED/LIVE/consumer_purchase=false |
| 키 metadata | LIVE Client/Secret 및 Finance 모두 secret_text. 값 노출·추출 없음. 등록 존재는 유효성 증명이 아님 |
| DB | configuration LIVE, LIVE PAID0, TEST grant0 |
| 계정 | admin@ UID d5eab102-da92-4c4c-9adb-16d2c9d20e4c, review@ UID ddc5ae63-acbb-490b-a423-c996b811dea8의 현재 이메일·확인 상태 일치 |
| 실제 코드 | 감사 HEAD16be931의 payments.ts 및 Pages 결제 진입점은 배포 source902057c와 diff 없음 |
| 서버 호출 | 브라우저 → `/api/payments/*` → Pages `functions/api/payments/[[path]].ts` → `payment(request,env)` → 기본 fetch로 api.tosspayments.com 직접 호출. Supabase는 주문·Finance RPC 경로이며 Toss 승인 실행 주체가 아님 |
| DB 직접 호출 | payment_order(create)는 current_order_mode로 일반 인증사용자를 LIVE 허용. Cloudflare PAUSED만으로 직접 RPC 주문 생성까지 차단되는 구조가 아님. 생성만으로 Toss 승인·이용권 지급은 되지 않음 |
| QA 제한 | 기존 API에 Owner QA 전용 구매 제한 없음. SUPPORT_SUBJECTS는 취소 담당 권한으로 구매 허용 목록이 아님 |

## Finance 유효성 판정

11/4 갱신 토큰의 마지막 확인 만료는 11/11 11:25:53KST로 지났다. 당시 `/tmp` 갱신 파일은 현재 없다. 홈의 기존 원본 JWT는 존재하지만 10/14 만료이며 기존 서명키도 존재한다. 파일 원문·서명키·subject는 출력하지 않았다.

**현재 배포 Finance 토큰의 실제 exp/서명/권한은 미검증**이다. 이후 갱신됐는지 Cloudflare redacted metadata로 판정할 수 없다. 마지막 발급이 만료됐다는 사실을 현재 런타임 토큰 만료 확정으로 바꾸지 않는다. 단순 runtime200은 비어있지 않음만 증명한다.

필요한 후속: 현재 Production 바인딩을 그대로 쓰는 제한된 서버 진단에서 `payment_process`의 get/nonexistent를 호출, PT404면 인증·권한 통과. JWT exp는 메타데이터만 확인하고 서명 인증 결과와 구분한다. 401이면 만료/서명오류, 권한오류면 role/subject 계약을 구분한다. 갱신 필요 시 기존 issuer/role/subject/signer만 재사용하고 단일 PAYMENT_FINANCE_TOKEN Secret 갱신 및 보존 재배포. 키·역할·원장 변경 금지. 자동 갱신 없음.

## LIVE 키·MID 및 API 접근 정책

11/4에는 MID leglabn24k 거래가 실제 승인 API까지 도달했다. 이는 과거 키 근거이며 현재 두 키 세트의 증명이 아니다. 현재 키의 raw 값은 Pages API에서 읽을 수 없다. 따라서 **현재 Client/Secret 세트 일치 NOT VERIFIED**.

최근 감사의 토스 UI 확인: 국내9카드 심사승인, LIVE 접근 정책 대한민국/연결키3개. 이번에는 UI를 다시 열지 않았으므로 감사 증거를 인용한다. 구매자 IP/도메인 등록과 서버 egress 허용은 별개다. 공식 정책은 서버 Secret API에 적용되며 차단 시403 API_KEY_ACCESS_DENIED. 현재 실제 Pages egress 주소/국가 및 연결키 매칭은 NOT VERIFIED. 로컬 Mac curl 성공이나 Cloudflare colo만으로 토스가 본 egress를 증명하지 않는다.

읽기 전용 확인안(아직 미구현·미배포): 현재 배포의 동일 Pages 실행 위치·바인딩에서 Owner 인증만 허용하는 임시 진단을 사용한다. 일반 사용자403, PAUSED 유지, 지정된 과거 실패 주문의 Toss GET 조회만 허용하며 URL/메서드/주문번호를 사용자 입력으로 받지 않는다. confirm/cancel 호출·DB write는 없음. 응답은 HTTP/오류코드·예상MID/주문일치 boolean·Finance 통과 boolean만 반환, 키/Payment 원문은 반환하지 않는다. Toss 조회가200이고 MID/기존주문이 일치하면 Secret의 해당 상점 조회권한과 그 호출 시점의 접근 정책 통과를 확인할 수 있다. 404만으로 MID 일치를 증명하지 않는다.

Client Key의 세트 일치는 별도로 같은 MID의 토스 개별연동 키 세트와 안전한 비교가 필요하다. Owner가 로컬0600파일로 제공한 해당세트 값을 서버에 비공개 비교하거나, 승인된 단일 Secret 재등록으로 같은 세트를 확정한다. 기존 값을 무조건 교체하지 않는다. 브라우저 키 노출/로그 출력 없이 match boolean만 남긴다. 키를 채팅으로 받지 않는다.

대한민국 제한과 실제 egress가 충돌하면 정책 해제·국가 확대를 자동 적용하지 않는다. 토스 정책에 맞는 서버 경로를 별도 검토·승인한다. 현재 정적 egress 보장 근거 없음. 한 번의 GET 성공은 향후 모든 실행 위치의 통과 보장이 아니다.

## Owner 승인 후 필요한 정확 변경안

| 대상 | 변경안 | 현재 실행 여부 |
|---|---|---|
| Production Finance | 현재값 읽기 전용 인증 검사, 필요할 때만 동일 신원의 토큰 갱신 | 미실행 |
| DB 생성 권한 | current_order_mode만 QA/review 고정UID+현재확인메일로 제한. 다른사용자는PT403. 기존 get/처리/원장 보존 | [검토 SQL](../supabase/verification/payments/owner-qa-20261115/owner-qa-mode.sql), 미적용·격리검증 전 |
| Pages 구매 접근 | `PAYMENT_LIVE_QA_SUBJECTS=d5eab102-da92-4c4c-9adb-16d2c9d20e4c` 신규 서버설정 + fresh Auth UID/정확 admin메일/confirmed 검사. 설정 누락 시LIVE 신규구매 차단 | 제안, 미구현 |
| runtime/UI | Owner만 LIVE 구매 가능, review만 TEST, 일반/비로그인은 PAUSED와consumer_purchase=false. UI만 숨기는 방식 금지 | 제안, 미구현 |
| orders/confirm | 비QA LIVE 요청은 DB/Finance/토스 전403. QA 시험은sku1c/4,900원. 클라이언트mode/email 우회거부 | 제안, 미구현 |
| reconcile | 기존 DONE는 원장 정합성 복구 유지. 비QA의 IN_PROGRESS에 대한 새 provider confirm은 차단. review가 보유한 과거LIVE 주문에도 동일 제한 | 제안, 미구현 |
| 취소/환불 | 기존 권한·기능 보존. 이번 실행0, 별도 Owner 승인 필요 | 변경 없음 |
| 스위치 | 위 제한·진단·회귀가 통과하고 Owner 활성화 승인 후에만 PAYMENT_ENABLED=false→true 및 현재자산/타API보존배포 | 금지 상태 유지 |
| 유지값 | PAYMENT_MODE=LIVE, DB configuration LIVE, review/support UID, 상품가격, 원래 주문mode, TEST키 보존 | 유지 |

DB 변경은 신규 테이블·칼럼·지급체계 추가가 아니다. 그러나 운영 함수 변경이므로 별도 승인·사전정의/ACL 저장·격리검증·사후검증이 필요하다. 검토 SQL은 실행용 최종 승인안이 아니다. helper가 action=create에만 쓰임을 현재 정의로 확인했다. 기존 confirm의 안전성은 adapter 제한을 함께 적용해야 확보된다.

반드시 검증할 접근 조합: 비로그인/일반/다른관리자/Owner/review, 동일이메일재생성/이메일변경/미확인메일, 직접RPC/클라이언트우회, PAUSED on/off, 기존LIVE·TEST 조회/응답유실복구. 일반사용자RPC 생성과 토스 confirm 모두 막혀야 한다. 배포 전에 최신source와다른작업변경을다시확인한다.

## 4,900원 시험 및 성공 후 검증표

Owner QA는 기존 admin@ 계정, 신규 1회4,900원 주문. 과거FAILED 주문 재사용 금지. 활성화 승인 후 Owner가 직접 결제한다. 환불은 포함하지 않는다.

- 직전 계정 가용/전체/예약 잔액과 기존 구매grant·거래 목록을 읽기 스냅샷으로 남긴다. 동시 첨삭소비·무료지급은 주문지급과 분리한다.
- Toss DONE/MID/orderId/paymentKey/KRW/totalAmount/balanceAmount/approvedAt 일치.
- 주문 PAID/POSTED, 실제 승인시각, 기존 grant_id 연결.
- external_reference=payment/주문UUID의 grant 정확히1개와 해당지급원장1개 확인. 수량1, 기존3개월정책 확인.
- 동일주문 재조회/복구에서 grant·거래 증가0. 별도새주문 생성으로 중복검사를 대체하지 않는다.
- WEB 및 APP를 동일 Auth UID로 확인, 기존 credit_summary 재조회 후 지급+1 반영. APP 코드는 변경하지 않는다. 저장 잔액만 확인하고 실기기 UI 확인없이 APP PASS로 보고하지 않는다.
- 실패/시간초과면 새결제 반복을 멈추고 기존주문 조회. 임의재지급·원장수정0. 환불은 별도승인 대기.

## 보존 검토 및 다음 판단

발생·기록시각 보존, 원본주문·원장 재현, 과거mode/이력덮어쓰기0, 기존Auth UID 재사용, 학습기록과결제사실분리, 비밀값·신규개인정보수집0, TEST금액을매출로집계하지않음의7원칙 유지.

**사전검증 전체 완료 아님.** 현재값 기반 Finance 인증·키세트·Pages→Toss 정책 통과, QA gate 구현/격리시험이 남았다. 현재 PAUSED 해제 승인을 요청하지 않는다. 다음 실제운영작업은 PAUSED를 유지하는 제한진단 배포·필요시Finance갱신의구체패치를준비해검토한뒤진행해야한다. 정책변경/신규결제/환불을진단에섞지않는다.

참고: [Toss API 키](https://docs.tosspayments.com/reference/using-api/api-keys), [접근 정책](https://docs.tosspayments.com/reference/using-api/api-key-access-policy), [Cloudflare Placement](https://developers.cloudflare.com/workers/configuration/placement/).

## 11/15 최종 단일 Owner 정책 및 동시 작업 검토

Owner최종정책: LIVE QA는admin@ 고정UID1개,review는TEST전용,다른관리자포함모든계정LIVE차단. UI/API/DB계층모두적용하고PAUSED유지. 실제결제/환불0. 앞선최대다중QA허용가능성은허용하지않는다.

동일 WEB 작업트리에서 다른 활성 대화 ‘안정화 및 상용화 순차 실행’이 QA/진단/SQL 후보를 수정 중임을 확인했다. 파일 덮어쓰기·동시 배포를 피하기 위해 읽기 검토만 수행하고, 최신정책을해당대화에전달할권한을Owner에게질문했다. 최종정책전달전후변경을구분하며그대화의169검사/전체2068PASS보고는최종단일Owner정책검증으로간주하지않는다.

정책 전달 전 미커밋 후보에서 확인했던 보완점(후속 검토 결과는 아래 참조):

1. payment-qa.ts는최대5개UID와QA_ONLY미설정/false시무제한허용. 최종안은고정Owner UID1개만허용하고잘못된/누락설정으로일반LIVE가열리지않아야한다.
2. payment-runtime.ts의checkoutOpen은state LIVE이면consumerPurchase=false여도true. 따라서runtime만false반환하는후보는일반사용자버튼차단을충족하지못한다. LIVE에서도consumerPurchase를필수로검사하고UI회귀검증해야한다.
3. diagnostics는SUPPORT_SUBJECTS목록을사용중. 구매QA및진단권한을고정Owner로한정해야하며다른관리자/지원담당자로확장하면안된다.
4. confirm후보의QA확인은provider confirm직전에있어비QA도confirm_begin에접근가능. 저장주문mode확인후LIVE+비Owner를finance승인시작전차단해야한다. review의과거LIVE주문도신규승인금지. 이미DONE인기존주문정합성복구는분리검토한다.
5. DB후보는configuration에5개칼럼과다중UID정책을추가한다. 단일Owner최종정책과필수PAUSED DB차단범위로축소검토한뒤정확SQL·ACL·기존행불변·격리테스트결과를보고한다. 이번검토에서운영SQL적용0.

이섹션은코드수정/배포완료보고가아니다. 동시작업조율후최종단일Owner정책을반영·검증해야한다. 별도앱1.0.5(85) QA요청은미완료이며이번결제최종정책으로완료처리하지않는다.


## 11/15 22:17 KST 독립 검토 — WEB 1814111

Owner 승인으로 상대 대화에 정책을 전달하고 WEB 구현·배포 담당을 단일화했다. 상대 작업의 `1814111742d73897fc8483893d2fef42c1ace640`를 읽기 검토했다. 앞선 다중 UID·누락 설정 허용·LIVE UI 무조건 허용·지원 계정 진단 권한·비Owner confirm_begin 접근은 수정됐다. 고정 Owner UID, review TEST 전용, 신규 LIVE 1c/4900원 제한을 확인했다.

독립 실행: payments/payment-diagnostics/payment-runtime/pricing-plans 4파일 **158 PASS**. 운영 runtime POST는 `PAUSED / LIVE / consumer_purchase=false`. 결제·환불·운영 SQL 실행0. 운영 진단/신규 코드 배포 완료로 해석하지 않는다.

남은 검토 사항을 담당 대화에 전달했다:

- Owner의 QA 설정 누락/만료/상품 불일치에서는 confirm_begin 후 토스 신규 승인 직전 차단된다. 신규 승인 시도는 상태 변경 전 제한할 수 있도록 검토하고 기존 DONE 복구는 보존해야 한다.
- 운영 SQL 후보는 configuration 3칼럼(purchase_enabled=false, qa_started_at, qa_until) 및 payment_order 교체로 변경됐다. 앞선 APP helper 단독 후보는 최종 적용안이 아니다. 운영 적용은 미승인·미실행이다.
- postcheck에 함수 정의/ACL·고정UID 및 기본 차단 상태 검증을 보완해야 한다. 운영 직접 RPC 차단은 아직 입증되지 않았다.
- Finance 인증, LIVE Client/Secret 세트·MID 및 실제 Pages→Toss 접근 정책은 운영 진단 미실행으로 NOT TESTED다.

**판정: 코드의 핵심 단일 Owner 정책은 반영, 전체 운영 완료는 아님. PAUSED 해제 승인 요청 시점이 아니다.** 필요한 SQL 별도 승인·적용 검증, PAUSED 유지 배포 및 읽기 진단, 권한 조합 회귀를 마친 뒤 DB purchase_enabled와 Worker PAYMENT_ENABLED를 켜는 정확한 변경값·QA 만료시각·원복안을 제시해 별도 해제 승인을 요청한다.


## 2026-11-17 17:53 KST — Owner 실결제 재시험 요청 및 실제 진단

Owner가 관리자 실결제 시험을 요청했다. 기존 admin 전용 범위를 유지하며 운영 관리자 /admin/payment/의 읽기 진단을 직접 실행했다. Finance HTTP401/PGRST303, Toss GET HTTP200/MID 일치, Client·Secret 쌍 미확인. 신규 결제 일시 중지 표시와 1회권 구매 비활성 확인. 과거 배포 영수증은 WEB cc8acf6 문서에 있으며 11/15 PAUSED 코드 배포 c6dcd96a-8ac1-4d32-8dbe-97959286969d를 기록한다. 오늘 새 배포는 수행하지 않았다.

운영 DB 독립 SELECT: configuration은 singleton/mode만 존재하며 QA 3칼럼 미설치, payment_order 정의 MD5 1afb9a07c8688d74517df6b999dc7320으로 원본 유지. TEST CREATED10/PAID TEST_RECORDED10, LIVE FAILED/NONE1, LIVE 성공0. admin/review 기존 UID·이메일 일치. Secret 출력·주문생성·지급·환불0.

실결제 준비를 막는 것은 UI 자체가 아니라 PAUSED, Finance 인증 실패, DB QA 제한 미적용이다. 상대 대화의 11/15 Owner SQL 보류 결정을 존중하여 정확한 SQL 후보 승인 없이 적용하지 않았다. 준비 변경안: 기존 signer/subject/role를 보존하는 Finance 인증 복구, WEB wiki/candidates/payment-qa-20261115/apply.sql 적용(3칼럼 및 주문함수; purchase_enabled=false), postcheck 검증. 키 쌍 확인 후에만 단일 Owner 1c4900원 QA 시간창 활성화 변경값을 제시한다. 기존 11/15 검토의 신규 confirm 선차단 보완은 ca56582에서 수정된 것으로 코드/작업 기록 확인; 실제 신규 결제는 아직 시험하지 않았다.


## 2026-11-17 — Owner 정책 변경 및 일반 LIVE 활성화

Owner가 “전체 결제 가능하게 수정해봐”로 앞선 admin 단일 QA·PAUSED 유지 지시를 대체했다. 일반 로그인 사용자는 기존 네 상품 LIVE, review 고정UID는 TEST 전용을 유지한다. 비로그인·타인주문·금액위조 차단, 실결제Owner직접·환불별도 원칙 유지. 운영 DB의 기존 일반LIVE/reviewTEST 계약이 이미 존재해 QA 제한 후보SQL은 적용하지 않았다.

WEB 구현 `01d2624298241aeb522e5d809b4223a0dfd546d8` Commit·Push. 전체2108 PASS/5 SKIP, TypeScript·ESLint·Functions build PASS. 현재 운영 GA4 소스0bcf681 보존, 비결제API입력75·정적자산3070개 동일 확인. 기존 Finance signer/JWKS/subject/role 유지 갱신 후 관리자 운영진단 PT404(권한확인), TossGET200/MID일치. 토큰 만료11/24 18:03:34 KST, 자동갱신미구현.

PAUSED 복구배포 `526ed879-1b91-443a-9371-80b07fe39ccc` 이후 공개배포 `3f7a57bb-5096-488c-bef1-f28787f7f458`. 변경 설정은 PAYMENT_FINANCE_TOKEN 갱신, PAYMENT_PUBLIC_ENABLED=true, PAYMENT_ENABLED=true. PAYMENT_MODE=LIVE·TEST/LIVE키·기타설정 유지. SQL변경0. 익명runtime LIVE/consumer_purchase=false 확인.

운영 pricing에서 admin 로그인 구매버튼 활성화 및 1c4900원 Toss LIVE 창 확인. 신규 주문 `86f4d220-6527-4689-8723-52800802b2b6`, ORDER_CREATED/NONE, 기존잔액92, LIVE성공0(18:10 조회). Owner에게 카드인증·최종결제 인계. 아직 실결제 성공/지급 E2E 완료로 보고하지 않는다. 기존 주문·원장 변경0, 새 주문 생성1, 환불0.


## 2026-11-17 18:11:53 KST — 첫 LIVE 결제 성공

Owner 결제완료 통보 후 운영 DB와 실제 WEB 내역을 독립 확인했다. 주문86f4d220-6527-4689-8723-52800802b2b6: LIVE/1c/4900원/PAID/POSTED, CONFIRM SUCCEEDED(error null), 승인시각18:11:53. 지급grant d3f28406-2959-4cb5-946d-0672c48f39cf, external_reference payment/주문ID에 해당하는 grant 정확히1개. 연결원장 purchase/purchase_v1 +1·reserved0 정확히1행. 잔액92→93. 실제 /account/credits/에 구매+1·구매분1·전체93 표시 확인. 유효기간2027-02-17 18:11:53 KST. 중복지급0, 환불실행0.

서버의 Toss 응답 일치 검증을 거친 승인·지급 성공을 확인했다. 이번 turn에서 Toss GET을 별도로 재호출하지 않았으며 APP 실기기 잔액은 NOT TESTED(공유 DB 잔액93 확인과 구분). 실제 callback 재전송 시험은 수행하지 않았고 중복지급 방지 회귀는 앞선 합성 테스트 결과를 사용한다. 일반LIVE 공개 유지, review TEST정책 유지. Finance 11/24 갱신 필요는 남아 있다.
