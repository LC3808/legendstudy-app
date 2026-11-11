# 작업04-B 운영 적용 검토 패키지

**후속:** 수정 A는 [작업04-C](../../../wiki/task04c-home-production-20261111.md)에서 승인·운영 적용됐다. 이 패키지는 승인 전 검토 근거이며 재실행 금지. C/D HOLD 유지.

**운영 미적용. 원본 combined candidate는 HOLD.**
기준 `codex/task04-applications-app75` / `37eb530737e1676379f1d5446ac7af2c74d5f4d3`.
[검토·실기기·승인 범위](../../../wiki/task04b-production-preflight-20261111.md).

- A: `apply_a_home.sql`은 기존 계정 탈퇴 접근 제한을 보완한 **미적용 대체 후보**다. 원본과 함께 실행하지 않는다.
- B: 실제 지원 대학은 기존 운영 RPC를 재사용한다. 신규 DDL·RPC·migration 없음.
- C: 원본 뉴스 feed의 동시 적재/페이지 누락 재현. 구조·RPC 보완 전 적용 금지.
- D: 공식 일정 적재0. 검수된 원본·대상·revision manifest 승인 전 실행 금지.

## 승인 후 A 적용 순서

1. `preflight_readonly.sql`: 동명 후보 객체 없음, 부모 FK 타입, 기존 함수/정책/ACL을 재확인·보관한다.
2. `apply_a_home.sql`: Owner가 승인한 migration owner로 한 transaction 실행. 신규 table1/RPC2/policy1만 만든다. 기존 lifecycle 함수는 호출만 하고 수정하지 않는다. 의존 함수 hash가 다르거나 객체가 이미 있으면 STOP; 임의 `CREATE OR REPLACE`/`IF NOT EXISTS`로 우회하지 않는다.
3. `verify_a_readonly.sql`: 처음에는 rows/owners0, invalid/duplicate0, RLS ON, anon EXECUTE false, authenticated EXECUTE true, 직접 테이블 권한 모두 false. preflight를 재실행하여 기존 application 함수/정책/ACL 불변 확인.
4. 해당 DDL이 PostgREST schema cache에 반영됐는지 승인된 검수 세션으로 확인한다. 미반영이면 운영자의 표준 schema reload 절차를 별도로 수행하며 함수가 없다고 재생성하지 않는다.
5. 승인된 테스트 계정/별도 기기에서 저장·재실행·동일계정 재로그인·다른 계정·실패/재시도 검수. 자동화된 합성 production INSERT/SET ROLE 검증은 이 패키지 범위 아님.
6. APP75 유지, WEB·릴리스·스토어는 이번 승인 범위 밖.

## 롤백

- 트랜잭션 내부 실패: 전체 A rollback. 재실행 전 동명 객체 재확인.
- 커밋 후 장애: `disable_a_home.sql`로 client EXECUTE만 회수. **이력 테이블 보존**. 신규 앱은 기본 홈/저장 실패/온보딩 건너뛰기 흐름 사용.
- 원인 해소 후 `restore_a_home.sql`; `verify_a_readonly.sql` 재검증. 계정 본인 캐시는 기존 앱 정책대로 처리된다.
- C가 나중에 승인·적용된 경우만 `disable_c_news.sql`/`restore_c_news.sql` 사용. 현재 C에는 실행하지 않는다. 적재도 중지하고 원본 증거 보존.
- D 오류는 현재 revision을 UPDATE/DELETE하지 않고, 검수 후 같은 series의 다음 `withdrawn`/정정 revision을 발행한다. 올바른 다른 전형·학과 기록을 일괄 철회하지 않는다.
- 기존 `task04_home_20261111/rollback.sql`은 모든 신규 이력을 DROP하는 파괴적 철거용이다. 일반 운영 롤백으로 사용하지 않는다. 별도 삭제/보존 검토·승인이 없으면 실행 금지.

## 격리 재현

`python3 supabase/candidates/task04b_preflight_20261111/run_isolated.py`

Homebrew PostgreSQL17 필요. 새 임시 cluster, localhost:55450만 사용한다. 포트 점유 시 시작 실패하며 기존 서버에 연결하지 않는다. 합성 auth/users/university만 생성한다. 종료 시 해당 cluster만 정지·삭제. 운영 DSN 인자를 받지 않는다.

- `verify_original_local.py`: 원본 권한/CAS 및 lifecycle 누락·pagination 반례 재현.
- `verify_a_local.py`: 수정 A의 lifecycle/동시성/RLS/비파괴 rollback 검증.
- `original-local-results.json`, `revised-a-local-results.json`: 이번 격리 검증 영수증.
- `verification-results.json`: APP75 동일 실패 비교, 집중 테스트 수·로그 hash.
- `verify_c_readonly.sql`: **미래 C/D 승인 후** 구조/기초 데이터 SELECT 검증용. 공식 원본 내용의 정확성을 SQL만으로 판정하지 않는다.

운영에 `isolated_bootstrap.sql`, `isolated_test.sql`, `verify_*_local.py`를 실행하지 않는다.
