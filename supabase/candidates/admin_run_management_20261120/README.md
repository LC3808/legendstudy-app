# 관리자 운영 관리 — Owner 적용 패키지

Production APPLIED — Owner 명시 승인, 2026-11-20 20:28 KST, migration `20261120112811`. Project: `stlhijzpjfgwwdgunlsd` only. 아래 절차는 완료 기록이며 운영에서 재실행하지 않습니다. WEB/Worker 배포·읽기 검증 완료; 실제 기존 요청 작업0. 상세: `wiki/admin-lab-run-management-20261120.md`.

1. Supabase SQL Editor에서 `install.sql` 전체를 한 번 실행합니다. 새 테이블·RPC·인덱스만 설치하며 기존 요청·답안·이용권·원장은 변경하지 않습니다.
2. `postcheck.sql`을 실행합니다. 보안 검사 3행 true, 최초 action/test count 0, 기존 요청 reserved / ledger 1 / retry 1을 확인합니다.
3. WEB 관리자와 Worker adapter를 함께 배포하고 실제 UI 읽기를 검증합니다. 기존 요청의 재진행·삭제는 별도 Owner 승인 후에만 실행합니다.
4. 문제 시 `rollback.sql`로 새 API를 닫고 기존 WEB/Worker 배포로 복원합니다. 원장/감사 이력은 삭제하지 않습니다.

테스트 요청은 이메일·베타 이용권으로 추정하지 않습니다. `verified_test_runs`에는 Owner가 정확 요청의 테스트 출처와 결제·학생 기록 무관함을 검증한 후에만 기록할 수 있습니다. 등록 UI/API는 제공하지 않습니다. 등록해도 원장, 유료/예약/정산 판단, 완료, 활성 잠금, 연결 회차, 평가/피드백/코칭 기록이면 삭제를 거부합니다. 기존 요청을 자동 등록하는 SQL은 없습니다.

재진행: 예약 상태 + 만료된 실행/재시도 lease + 최신 문항 checkpoint 전부 terminal + 실패 문항 존재 + 예약 billing만 허용. 기존 `essay_exam_retry` 호출; 답안·완료문항·decision·ledger 불변. 완료/종료 실패, pending/불확정 checkpoint는 수동 점검으로 제한합니다. 새로운 유료 재요청 정책을 만들지 않습니다.

KPI: 요청 생성 시점 범위의 요청/현재완료/현재실패, 재시도는 retry_requests.created_at 사건 범위. 시작 포함/끝 미포함 KST. 현재상태는 기존 전체 범위 RPC, 신규+확인 중 피드백. 숨김은 KPI 제외가 아닙니다.

검증: fixture.sql + 기존 essay_session_retry/install.sql의 retry 테이블/함수 + install.sql + test.sql을 임시 PostgreSQL에서만 실행. test.sql에는 합성 데이터 생성·삭제가 있으므로 운영 실행 금지. fixture auth/admin 함수는 권한 검증을 모사하며 실제 Production require_admin은 변경하지 않습니다.
