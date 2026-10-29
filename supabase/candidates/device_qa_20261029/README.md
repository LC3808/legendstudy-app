# 광운 계정 Draft 제한 권한 후보 — 운영 미적용

이 폴더는 자동 migration 대상이 아니다. Owner가 DB/RPC 변경 및 대상 사용자·두 문항·14일 기간을 별도로 승인한 뒤 직접 실행하는 후보다. 전체 검수 보고와 실제 원인은 [Unified Wiki](../../../wiki/app-device-qa-fixes-20261029.md)에 기록한다.

## 적용 순서

1. LegendStudy 프로젝트 `stlhijzpjfgwwdgunlsd`인지 확인한다. 적용 세션은 승인된 관리자로 제한한다.
2. `draft-baseline.sql`은 이번 읽기 전용 조회에서 캡처한 기존 `essay_open_session`이다. `draft-install.sql`이 기존 함수 MD5를 검사한다. 달라졌다면 중지하고 현재 계약을 재검토한다.
3. 승인 후 `draft-install.sql` 실행. private 권한 표는 비어 있으므로 누구에게도 저장 권한을 자동 부여하지 않는다. 기존 사용자 session/Draft RLS나 Registry 공개 flag를 바꾸지 않는다.
4. 별도 승인된 실제 사용자 UUID를 `psql -v owner_id=<UUID> -f draft-grant.sql`에 전달한다. 광운2026 인문1교시의 지정된 두 canonical 문항만 14일 허용한다. 이 grant는 기존 동의/접근 권한의 대체 근거가 아니며 관리자가 승인 범위를 먼저 확인해야 한다. 자동 upsert/만료 연장 없음.
5. `draft-verify.sql`로 함수·privilege·공개 flag·RLS를 확인한다. 권한은 평가 요청/무료 첨삭/Credit 지급을 허용하지 않는다.
6. Owner 세션에서 기존 APP의 계정 저장/복원을 확인한다. 이 검증은 실제 Draft 쓰기이므로 이번 읽기 전용 진단에서 수행하지 않았다. 실패하면 기기 답안을 보존하고 중지한다.

## 롤백

`draft-rollback.sql`은 캡처한 원래 open 함수를 복원한다. 운영 적용 이후 다른 변경이 있었다면 먼저 diff를 확인한다. 권한 표/승인 기록/이미 저장된 session·답안은 삭제하지 않는다. 기존 owner RLS와 Draft 저장 계약은 그대로 유지된다. 원래의 비공개 문항 새 session 생성 제한으로 돌아가며 기존 로컬 답안은 영향을 받지 않는다.

## 격리 검증

`PYTHONPATH=.:tool python3 tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin --draft-access-only`

임시 PostgreSQL의 기존 session/Draft DDL·실제 RLS·CAS로 익명/다른 owner/무권한/만료 권한 거절, 권한별 open idempotency, 저장/복원, revision 충돌, 기존 Registry/Ledger/RLS 불변, rollback 후 답안 보존을 확인했다. lifecycle 제한 함수는 로컬 stub이므로 운영 함수의 전체 lifecycle 의미를 재검증한 것으로 계산하지 않는다. 운영 변경 및 Provider 호출 0.
