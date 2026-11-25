# 신규 무료 첨삭권 2개 — Owner 적용 패키지

상태: **PREPARED / NOT APPLIED**. 대상은 LegendStudy `stlhijzpjfgwwdgunlsd`만. 운영 DB 적용 승인은 아직 받지 않았다. 기존 지급분 회수/수정, 실계정 테스트 금지.

## 변경

- 신규 지급 수량 단일 기준: 비공개 `essay_private.credit_signup_grant(uuid,text)`에서2개, 사유 `signup_bonus_v2`.
- 기존 profile trigger, authenticated self claim, lifecycle server claim이 같은 helper 사용. 클라이언트 별도 지급 없음.
- 기존 지급이 있으면 잔량과 무관하게 원 grant 반환. 3개 지급을2개로 수정하지 않고, 소진0에도 추가 지급하지 않음.
- `essay_signup_3_v1`은 수량 표시가 아닌 기존 재가입 중복 방지 namespace이므로 유지. UUID/key/marker·최초 eligibility·profile·권한 계약 유지.
- 유료 가격/credit_post_grant 원본/정산/무료 재첨삭/Finance 변경 없음.
- 변경 직전 시작된 기존 트랜잭션은 기존 정책을 보존한다. 설치 commit 이후 시작되는 신규 지급부터2개. 승인 전 미리 지급하거나 backfill하지 않는다.

## 적용 순서

1. Supabase Dashboard에서 프로젝트 ref `stlhijzpjfgwwdgunlsd`와 SQL Editor `postgres` 실행자를 확인한다.
2. [precheck.sql](precheck.sql)을 실행한다. 함수 body/owner/ACL 변경, 이미 설치된 helper가 발견되면 중단한다. live 검증 기준은 [preimage.json](preimage.json), 조사 시점 원장 합계/hash는 [production-before.json](production-before.json). 조사 이후 정상 신규 가입이 증가할 수 있으므로 오래된 전체 합계를 강제로 맞추지 않는다.
3. Owner 승인 후 [install.sql](install.sql) **전체를 한 번** 실행한다. 같은 내용의 `supabase/migrations/20261125125051_signup_credit_two.sql`을 중복 실행하지 않는다. 신규 권한은 내부 helper의 executor/postgres만. 임시 역할 SET/CREATE 권한은 같은 트랜잭션 안에서 원복하고 이전 RPC ACL은 유지한다.
4. 설치는 credit account/grant/transaction을 짧게 잠그고 변경 직전·직후 기존 grant/ledger 전체 해시를 비교한다. 기존 이력 차이/권한 잔류 발생 시 exception으로 전체 rollback. lock_timeout5초/statement_timeout30초. 실패 시 무작정 재시도하지 않고 원인을 확인한다.
5. [postcheck.sql](postcheck.sql) 실행. 수량2·비공개 권한·기존 중복 namespace·CREATE 권한 미잔류 PASS. 새 signup2개가0건이어도 실제 신규 가입 전이면 정상이다. 검증을 위해 운영 회원 지급을 호출하지 않는다.
6. DB 성공 후 WEB 준비본 배포·요금/약관/베타 안내·기존 잔액 표시 확인. DB 전 WEB2개 문구만 먼저 배포하지 않는다. APP 준비본은 다음 스토어 업데이트에 포함한다.

SQL Editor 실행 결과를 공유받으면 함수/권한/기존 데이터 보존을 읽기 전용으로 재검증한다. 운영 helper 설치 여부를 migration 파일 존재로 추정하지 않는다.

## 원복

별도 Owner 결정 후 [rollback.sql](rollback.sql). 앞으로 지급할 수량만3개/사유v1로 되돌린다. 기존2개/3개 지급·소진 이력은 보존하며 top-up하지 않는다. 호환 wrapper는 남겨서 이미2개 받은 계정의 재호출이 수량 충돌하지 않게 한다. 최초 함수3개를 그대로 되돌리는 방식은 사용하지 않는다.

## 격리 검증

[test_postgres.py](test_postgres.py) / [결과](test-result.json): 합성24검사 PASS. 운영에서 캡처한 실제 지급 함수 및 동일 비슈퍼유저 postgres/essay_executor 역할·ACL 구조로 검증. 새2/옛3/소진0, legacy 및 lifecycle, 동시4요청, 같은 marker 재가입, 권한 거절, 기존 원장 해시, 구매10, 원복 후 과거2 유지 포함. 운영 DB DSN을 받지 않고 로컬55443·지정 data_directory만 허용한다.

재현: PostgreSQL17 격리 cluster를 `/private/tmp/legendstudy-signup-policy-pg`, socket `/private/tmp`, port55443에 준비. bootstrap `supabase_admin` 및 독립 `postgres` login을 준비하고 `python3 supabase/candidates/signup_credit_two_20261125/test_postgres.py`. 운영에 연결하지 않는다. 합성 테스트의 eligibility/lifecycle 주변 fixture는 최소 재현이며 운영 전체 인증 E2E 대체가 아니다.
