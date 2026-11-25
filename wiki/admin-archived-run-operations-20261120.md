# 관리자 보관 요청과 활성 운영 집계 — 2026-11-20

상태: 운영 RPC·Worker·WEB 수정 배포 완료, 실제 요청 상태 변경0. Owner는 보관/활성KPI/실제재시도 조건의 일관성 수정·검증·최소 운영배포를 승인했다. 실제 재진행·삭제·환불·원장 변경은 제외한다. [기존 관리자 관리](admin-lab-run-management-20261120.md), [보존 전략](longitudinal-learning-admissions-data-strategy.md)을 계승한다.

## 실제 대상과 결제 조사

대상 `e7af7e52-eba9-46c3-aba4-0961ea516b48`, review@legendstudy.com. 운영 READ ONLY 조회에서 reserved, result NULL, 생성2026-10-26 12:39:51KST, 실행lease12:54:54 만료. retry generation1 생성12:43:20/lease12:58:20만료. q0 completed, q1 failed, q1-retry-1 failed; 최종result없음. UI0/2를 내부checkpoint0개로 해석하지 않는다.

11/20 최신 조회는 `hidden=false`, 20:52:31KST restore 감사1건. 과거20:38 점검 당시hidden=true였지만 현재는복원상태다. Owner가 보고한보관과현재DB상태의불일치를기록하며 자동재보관하지 않는다.

billing `49746a12-e69c-4cd1-a511-137fab1ecb70`: paid_cycle/reserved1, reserve원장1건(balance0,reserved+1), consume/release없음. 연결grant `f2736c0b-febd-403a-a6eb-b57a8e8be1db`는 10/23 13:33:03KST purchase3, actor system/iap, reason iap_apple_v1, iap/apple hashed외부참조다. 동일grant에는 다른첨삭의consume/release도연결되어있다.

review계정의 Toss 주문은 조회한20건모두TEST이며 결제성공은TEST_RECORDED/grant_id NULL이다. 해당첨삭의예약이용권은이Toss TEST주문에서발급된것이아니다. Apple검증환경을과거원장만으로확정할수없으며 현재코드의Sandbox차단정책을과거실행증거로대체하지않는다. 따라서 삭제가능한무원장테스트로분류할근거가없다. 테스트근거를추가해도기존삭제정책의CREDIT_LINKED차단은유지한다.

## 기존 정책과 수정 원칙

기존보관은목록숨김이었다. 기존live.processing/reserved 및retry_pending 집계는보관포함이며Worker차단도보장하지않았다. 이번수정은보관을활성운영대상제외와연결하되 run/billing/답안/checkpoint/원장 자체는보존한다. 복원은재실행가능성만복원하며자동재진행하지않는다. 활성실행과보관경합을서버잠금으로검증하고목록숫자만숨기지않는다.

예약해제는별도조치다. 기존 `essay_exam_private.finish(run,NULL,true)`는실패종료와원래grant에release원장추가를수행하는계약이며직접원장수정과다르다. 그러나상태·예약을변경하므로이번에는호출하지않는다. 필요시정확한전제조건·동시실행차단·멱등검증후별도Owner승인을받는다. 현재관리자UI의보관이예약해제기능이라고안내하지않는다.

## 보존 검토와 구현

1. 요청 생성·재시도·보관/복원 감사 시각을 분리하고 없는 마지막 처리 시각을 만들지 않는다.
2. snapshot/checkpoint/결제 decision/원장과 기존 관리자 감사가 근거다.
3. 보관은 기존 hidden projection만 변경하는 명시적 관리자 작업이며 이번 설치 자체는 기존 행을 변경하지 않는다.
4. 기존 계정·owner/lifecycle·관리자 권한을 그대로 사용한다.
5. 운영 보관을 첨삭 실패·환불·학생 지원 결과로 해석하지 않는다.
6. 새 개인정보를 수집하지 않고 기존 History와 감사 보존을 유지한다.
7. 활성/보관 KPI는 파생 집계이며 과거 기간 통계·비용·원장을 덮어쓰지 않는다.

기존 RPC10개를 정확한 preimage/ACL 검증 후 수정하고, essay_worker 전용 읽기 dispatch guard1개를 추가한다. 기존 boolean을 재사용한다. 학생·관리자 retry 재전송도 보관이면 차단, claim은 archived 상태로 종료, checkpoint begin은 신규 실행만 차단한다. 보관과 claim/retry는 account→run 잠금을 공유한다. 활성 lease, 최초dispatch 미확정, pending/reconciling 또는 정산 전 final checkpoint가 있는 reserved 요청은 보관을 거부한다.

Worker는 새 enqueue 전에 읽기 guard를 확인하고, 이미 배달된 보관 메시지는 claim 결과를 근거로 ACK한다. 처리 중 오류도 다시 확인한 guard가 archived일 때만 ACK하며 다른 장애는 기존 재시도 계약을 유지한다. 복원은 enqueue·lease·원장을 생성하지 않는다.

WEB은 활성 처리/재시도에서 보관을 제외하고 보관 전체 건수를 별도로 표시한다. 활성 목록 링크도 visible 필터를 사용한다. 기간별 과거 통계는 보관을 포함한다. 보관 확인창에 처리 대상 제외와 예약 유지, 복원에 자동 재진행 없음이 표시된다.

## 검증과 운영 적용

- SQL 격리20/20 PASS: 보관/복원, 학생·관리자·legacy경로, checkpoint·claim·retry재전송, 동시보관/실행, 권한, 원장보존, 정확원복.
- WEB 전체2215 PASS/5 SKIP 후 모니터링보완 관련21 PASS, 변경lint·TypeScript·171route production build PASS. Worker집중15 PASS, 실제운영4모듈에7개diffhunk를적용한runtime8 PASS.
- DB migration `20261120130743`, install SHA256 `6a8370d24aba9d8b6f65940836603528f9d7f35c9755aed1d86a934ef81fcc4e`. 11함수테스트동일, 기존10함수owner/ACL·sessionclaim wrapper·finish불변. 기존63테이블/대상run·snapshot·checkpoint·billing·reserved1·hiddenfalse·Finance해시동일. 일반회원·anon차단, guardessay_worker전용. [DB 영수증](evidence/admin-archived-run-production-20261120.json).
- 실제DB KPI processing1/retry_pending1/archived0. 대상 hidden=false이므로정상이며이번작업에서0으로강제하지않았다. SQL원문에보관제외조건을검증했고실제보관→KPI0 전환은대상데이터변경금지로실행하지않았다.
- Worker version `5095226c-82b8-4b64-bf14-9d3f16c4fbcf` 100%, 기존75모듈중71개보존/관련4개만패치. WEB Pages `842dccfe-570c-458a-a23e-a0c5220bb766`, source fe1bae1. 관리자4루트만교체하고기존3115파일·PagesAPI/routing/bindings·TossLIVE/FinanceAutomatic 보존. [WEB·Worker 영수증](evidence/admin-archived-run-web-worker-20261120.json).

## 관리자 최종 처리 방법

1. `/admin/essay-runs/`에서 대상ID 검색 → 상태확인. 현재는복원상태이며예약1개다.
2. Owner가보관을선택하면확인창의활성운영제외/예약유지안내를확인한다. 서버는실행잠금·미확정checkpoint를재검사한다. 성공하면활성목록/KPI·실행및재시도에서제외되고보관목록/건수로이동한다.
3. 보관필터에서기존상세·답안·이력조회가능. 복원하면활성대상으로돌아오지만자동재진행하지않는다.
4. 예약해제까지원하면별도Owner승인후검증된실패종료/기존release경로를사용해야한다. 현재보관버튼은예약해제버튼이아니다. 이요청은원장연결이므로테스트라고이름붙여삭제차단을풀지않는다.

실제재보관/복원/재진행/삭제/환불/원장변경은0회다. 필요시새RPC원복과기존Worker/Pages버전복구를하되실제run/ledger를직접UPDATE·DELETE하지않는다.

최종 실제 Owner UI 확인: `/admin/`, `/admin/lab-dashboard/` 모두 처리1/재시도1/보관0. 활성 목록에서 대상 상세의 예약1·원장1·재진행/보관 가능·영구삭제 비활성을 확인했다. 보관 필터는 빈 목록이며 `/admin/operations/`의 보관 한국어 라벨과 범위 안내도 정상이다. 상태 조회만 수행했다. 실제 대상 보관 전후 전환은 NOT TESTED이고, 격리 테스트·운영 함수 동일성 검증과 구분한다.
