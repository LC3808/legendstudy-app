# 무료 베타 Credit 정책 시제품 — Production 적용 금지

정책/영향/미완료: [canonical Wiki](../../../wiki/essay-beta-credit-design-20261027.md).

- `policy.prototype.sql`: 별도 비공개 테스트 schema의 순수 정책 함수3개. 실제 지급·예약 구현 아님.
- `test_policy.sql`: 새 격리 PostgreSQL DB에서 repository root 기준 psql -v ON_ERROR_STOP=1 -f 로 실행. transaction rollback. 기존 운영/테스트 DB에 적용하지 않는다.
- PostgreSQL17 23 policy checks PASS; 실제 동시 지급/금융 통합/권한 RPC 테스트 미완료.
- Production precheck/apply/postcheck/rollback 패키지는 아직 없음. Owner의 이 설계 검토 및 실제 후보 구현·검증 후 별도 운영 승인이 필요하다.
- 기존 관리자 Credit SQL 및 대학연결 SQL을 재실행하지 않는다.
