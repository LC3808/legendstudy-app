# TASK19 등급컷 조회 후보 — 운영 미적용

Owner TASK19 §15에 따라 **승인 전 운영 적용 금지**. 기존 시험·학생·채점·이용권·History를 변경하지 않는 부가 조회 테이블/RPC이다. 학습 채점용 `grade_cutoff_versions`를 대체하거나 표준점수를 해당 테이블에 넣지 않는다.

## 검토 범위
- [Migration](../../migrations/20261105032113_grade_cutoff_reference_lookup.sql): 새 `grade_cutoff_references`, 복합 Registry FK, 원점수/범위/표준점수/백분위 분리, revision, 출처/확정 상태, RLS SELECT, invoker RPC.
- [데이터](../../../data/grade_cutoffs/task19/reviewed_rows.json): 11시험 2,457행, 273과목·선택과목 조합. 점수 확인 2,212행 + 경계 미확인 NULL 245행. 모두 draft/non-current. NULL/추정/확정 여부 미제공 보존.
- [검증기·SQL 생성기](../../../tool/check_task19_cutoffs.py), [로컬 PostgreSQL 검증](../../../tool/test_grade_cutoff_reference_sql.py).
- [상세 조사·한계](../../../wiki/task19-lab-ux-grade-cutoff-20261105.md).

## 사전 확인 (읽기 전용)
`preflight.sql` 실행 결과를 저장한다. 테이블/RPC가 이미 있으면 자동 덮어쓰기하지 않는다. 기존 `exam_subjects(id,content_item_id)` UNIQUE와 public SELECT 권한, 과목 active 상태를 확인한다. 연결 프로젝트를 반드시 확인한다. 운영은 미적용. 2026-11-05 TASK19-C Owner 승인으로 격리 TEST 적용·실제 HTTP 검증 완료: [실기기/TEST 보고서](../../../wiki/task19c-device-verification-20261105.md). TEST에는 대상 Registry가 없어 같은 공개 ID의 최소 fixture를 먼저 추가했으며 generated 열은 제외했다.

## 승인 후 적용 순서
1. 정확한 프로젝트/대상 11시험과 데이터 누락·추정 정책을 검토한다. `python3 tool/check_task19_cutoffs.py` 통과 확인.
2. Migration을 트랜잭션으로 적용한다 (`begin;` → 파일 SQL → `commit;`). 일반 사용자는 조회만 가능하다.
3. `python3 tool/check_task19_cutoffs.py --seed-sql > /private/tmp/task19-seed.sql`로 생성해 검토 후 적용. 기존 revision과 겹치면 중단하며, 초안은 익명 사용자에게 보이지 않는다.
4. 별도 공개 승인을 받은 후 `--publish-sql`로 생성한 SQL을 적용. 후보 값·출처·검수시각이 모두 일치하는 정확한 2,457행에만 작동한다. 다른 revision/current와 충돌하면 트랜잭션 실패.
5. `postflight.sql`로 수량/권한/익명 RPC 확인. 실제 앱 자료/학습 조회와 GA4 DebugView를 확인한 후 후속 릴리스에 포함한다.

CLI 일괄 `db push`는 미관련 migration까지 적용할 수 있으므로 사용하지 않는다. 현재 CLI major/대상 옵션을 확인한다. 관련 [Supabase CLI v3 변경](https://supabase.com/changelog/supabase-cli-v3), [GRANT+RLS 공식 문서](https://supabase.com/docs/guides/api/securing-your-api).

## 원복
`python3 tool/check_task19_cutoffs.py --withdraw-sql > /private/tmp/task19-withdraw.sql`로 생성·검토·적용한다. 정확히 일치하는 후보 행만 withdrawn/non-current 처리하며 기존 수치는 삭제하지 않는다. 앱에서 이 데이터가 보이지 않게 되고 PDF/기존 채점은 그대로다. 공개 후 정정은 새 revision으로만 한다. 테이블 DROP이나 기존 Registry/채점 결과 UPDATE는 원복 절차에 포함하지 않는다.

로컬 테스트는 seed 중복 중단, publish 후 anon 조회, 일반 사용자 INSERT/UPDATE/DELETE 차단, 공개값 수정 금지, 원복 후 조회0/행 보존을 실제 PostgreSQL에서 검증한다. 이것은 운영 적용 증거가 아니다.
