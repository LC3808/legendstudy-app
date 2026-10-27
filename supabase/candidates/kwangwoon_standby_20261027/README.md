# 광운대 인문 STANDBY — 적용 완료

2026-10-27 인문 16회차·32문항 적용. **재실행 금지**.

정확한 SQL·공식자료·사전/사후 증거는 다음 기존 자료 저장소에 보존한다(비공개 평가 패키지를 Git에 복제하지 않음).

`/Users/woojinchang/development/legendstudy-materials/essay-validation-2026-10/incomplete-recovery-20261027/kwangwoon/`

- `registry.sql`: 16시험·32문항 등록, 적용 완료.
- `owner-sql/apply.private.sql`: 실행 연결·평가자료·정확한 문제 PDF SELECT, 적용 완료.
- `owner-sql/precheck.sql`, `postcheck.sql`: 읽기 전용 검사. 적용 당시 26/7 true.
- `owner-sql/rollback.sql`: 추가 실행 승인과 PDF 정책만 회수. Registry·평가자료·학생 기록은 보존. 후속 변경·진행 요청을 먼저 확인한다.
- `APPLIED.json`: 실제 적용 시각 및 검사 수.
- `applied-manifest.json`: SQL SHA256·회차 ID·배포 정보 추적.

Management API 413 시도는 SQL 미실행. 직접 PostgreSQL 트랜잭션 적용 성공 기록은 `precheck-direct-result.json` 및 `postcheck-direct-result.json`이다.

[Wiki 인수인계](../../../wiki/essay-kwangwoon-standby-20261027.md)
