# 신규 무료 첨삭권 2개 정책 — 2026-11-25

상태: 구현·격리 검증 DONE, 운영 DB/WEB 전환 PARTIAL(Owner DB 적용 승인 대기), APP 스토어 업데이트 NOT TESTED. 운영에서 현재 지급되는 수량은 아직3개다. 기존 회원·원장 변경0, 실결제/환불0. 이 문서는 [기존 G1 계약](essay-lab-server-transactions.md)과 [베타 안내](essay-beta-credit-design-20261027.md)의 신규 지급 수량만 후속 변경한다.

## Owner 결정과 단일 기준

신규 지급 대상만2개. 기존3개 지급/잔액/소진 이력 보존, 소진 회원 추가 지급 없음. 유료 가격과 무료 재첨삭 유지. 기존 재가입 방지 namespace `essay_signup_3_v1`은 수량이 아닌 identity 계약이므로 바꾸지 않는다. 기존 사용자의 잔액을2로 제한하지 않는다.

실제 프로젝트 `stlhijzpjfgwwdgunlsd`에서 lifecycle enabled=true 확인. 운영 함수 원본·권한은 [preimage](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/signup_credit_two_20261125/preimage.json)에 보관했다. 실제 지급은 `account_benefit_claim(uuid,jsonb)` 및 legacy `credit_profile_signup()`/`essay_claim_signup_credit()`의 서버 경로다. APP/WEB은 지급 RPC를 호출할 뿐 수량을 결정하거나 별도 원장을 만들지 않는다.

새 비공개 `essay_private.credit_signup_grant(uuid,text)`에 신규2개를 집중한다. 기존 grant가 있으면 소진 여부와 관계없이 해당 ID를 반환한다. 이 보호 없이 수량만3→2로 바꾸면 기존 grant의 idempotency payload 충돌이 발생한다. 기존 `credit_post_grant`의 비교·잠금·고유 제약은 그대로 둔다. 새 reason은 `signup_bonus_v2`, 기존 사유는 보존. 기존 eligibility/identity marker/claim 권한은 유지한다.

## 변경 파일과 화면 조사

| 영역 | 실제 수정 및 결과 |
|---|---|
| DB | `supabase/migrations/20261125125051_signup_credit_two.sql`, 같은 내용의 candidate install. 내부 helper 추가·지급 진입점3개 연결 |
| WEB | `src/lib/pricing.ts`의 표시 기준2. 요금/환불/약관이 재사용. `legal-documents.ts` 기존 지급분 보존·소진 재지급 없음 명시 |
| WEB LAB | `essay-beta-credit.tsx`가 표시 기준을 import; 고정3 제거, 베타·유료·무료 재첨삭 별도 정책 유지 |
| WEB 관리자·이력 | `credit-display.ts`가 v2를 신규 가입 무료로 표시, 실제 delta/잔액 유지 |
| APP | release88 작업 트리 `lib/features/credits/essay_beta_credit.dart`의 안내2 및 기존 잔액 보존, 해당 테스트 변경 |
| 기타 | 온보딩/마케팅/구매/FAQ 검색: 해당 무료 수량 안내는 위 WEB 공통 정책에서 파생. 유료3회 상품·실제잔액 fixture의3은 변경하지 않음 |

APP 배포 기준은 main보다 앞선 `08345b69`의 `codex/operations-commercial-20261113`이며 그 체크아웃에 수정했다. WEB 기준 `4e865437`, SQL/Wiki 기준 `7ad4be95`. 최종 변경 commit은 각 저장소 Git 기록을 확인한다.

## 구버전 호환성

양 스토어1.0.6/build88에는 베타 안내의 고정3개 문자열이 있다. 종료된 베타 배너는 현재 노출되지 않지만 이미 배포된 바이너리 문구를 WEB 배포로 바꿀 수 없다. 이번 Flutter 변경은 다음 스토어 업데이트에 포함한다. 구버전 balance DTO와 거래 type `signup_bonus`는 그대로이므로 신규2/기존3 실제 잔액과 이력은 읽을 수 있고 수량 clamp는 없다. 서버 reason v2 추가로 앱의 거래 type 표시 계약을 바꾸지 않는다.

DB 적용 후 WEB 요금/약관 안내와 기존 공지 기능으로 신규 지급2·기존 지급분 유지 정책을 안내하는 것이 구버전 대응안이다. 이번에 공지 게시/스토어 제출/강제 업데이트는 실행하지 않았다. 구버전 실기기 신규 가입 E2E는 NOT TESTED이며 정책 전환 후 정상 신규 가입을 읽기 검증할 수 있다. 운영 계정을 테스트 목적으로 만들거나 지급하지 않았다.

## 보존 검토 일곱 질문

1. 사실은 당시 grant/ledger 수량·사유·생성 시각이며 미래 정책과 분리한다.
2. 원장·원 grant ID/사유를 보존해 당시 지급을 재현한다.
3. 기존 row UPDATE/DELETE/backfill 없음. 미래 helper 수량만 변경한다.
4. 기존 auth subject 및 identity marker namespace를 유지해 재가입 중복 지급을 막는다.
5. 이용권 entitlement 사실이며 Learning/Decision/Outcome 평가 자료를 변경하지 않는다.
6. 새 개인정보 수집·retention 변경 없음. 기존 server/authenticated 권한과 내부 helper 최소 권한 유지.
7. 잔액은 원장 파생값 그대로; 표시 정책2를 과거 원장 사실에 덮어쓰지 않는다.

## 검증 결과

- 신규 SQL 합성 PostgreSQL17: **24 PASS**. 신규2, 기존3/소진0, lifecycle/legacy, 동시4회, marker 재가입, 권한 거절, 기존 원장 해시, 유료10, 미래3 원복 후 과거2 보존. 비슈퍼유저 postgres와 운영형 SET/CREATE ACL로 실행했다. 실제 운영 인증 E2E 대체는 아니다.
- 기존 결제 이후 G1 **84 PASS**: 유료 및 무료 재첨삭 계약 회귀. 기존 baseline migration 검증이며 새 migration 통합24와 구분한다.
- WEB/Finance/결제 관련 **12 suites 288 PASS**, 최종 가격·약관·credit 관련 **5 suites 101 PASS**(서로 중복 가능, 합산하지 않음). Node22 사용. TypeScript/ESLint 및 webpack production build PASS. Turbopack는 기존 node_modules 외부 symlink 제약으로 실패하여 공식 webpack 옵션으로 검증했다.
- Flutter credit **21 PASS**, 변경 파일 analyze PASS. Store build/실기기/배포 UI NOT TESTED.
- 운영 읽기 전후(21:58:13→22:05:03 KST) grant938/ledger1057 건수 및 전체 row hash 동일. signup923건 모두 기존3/v1. [기준값](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/signup_credit_two_20261125/production-before.json). helper 미설치 재확인. 실제 학생 원장 변경0.
- Toss LIVE·Finance 설정 및 Worker 엔진 수정0. 결제/환불 실행0. 자연 갱신을 유발하는 운영 인증 상태 호출 없음.

## 적용·승인·원복

[Owner SQL 패키지와 정확한 순서](https://github.com/LC3808/legendstudy-app/blob/fee6af5237dfcf5a8ff05aceea6ed69feaeb4f9c/supabase/candidates/signup_credit_two_20261125/README.md): precheck→install 전체1회→postcheck. Migration과 install을 중복 실행하지 않는다. 함수 hash/owner/ACL drift 시 중단, 기존 이력 hash 및 임시 권한 원복 검증을 단일 transaction에서 수행한다. 운영 기존 회원을 호출해 테스트하지 않는다.

AGENTS §4와 이번 Owner 지시에 따라 **DB 적용 승인 및 Owner 실행이 남았다**. 승인 전 운영 DB 변경 금지. SQL 성공 확인 후 WEB을 배포해 지급3/안내2 불일치를 방지한다. WEB 운영 배포·브라우저 확인은 따라서 아직 수행하지 않았다. APP은 다음 별도 스토어 업데이트에 포함한다.

rollback은 미래 지급만3으로 복구하고 기존2/3 이력을 보존한다. 예전 함수 전체를 복원하면 이미2개 받은 계정의 재호출 충돌이 생기므로 호환 wrapper를 유지한다. 실제 원복도 Owner 결정 후 수행한다. 신규 정상 가입이 조사 이후 발생하면 과거 전체 건수를 강제로 복구하지 않는다.
