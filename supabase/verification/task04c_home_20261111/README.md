# 작업04-C 운영 영수증

[완료 보고](../../../wiki/task04c-home-production-20261111.md).
Owner가 ef228c2의 수정 A만 승인했고, 2026-11-11 19:30:58 KST 적용 성공을 확인했다.

- 적용본: [20261111103058_task04c_home_configuration.sql](../../migrations/20261111103058_task04c_home_configuration.sql). 이미 적용되었으므로 재실행하지 않는다.
- `local-validation-results.json`: Flutter130/Analyze/iOS·Android 빌드/Wiki/격리 SQL 영수증.
- `production-evidence.json`: 프로젝트/시각/migration, 사전·사후 집계 지문, 새 객체·권한, DB role 읽기 검증, advisor 변화. 개인 UUID/기록/키 없음.
- `preflight_readonly.sql`: 대상 부재·의존성·기존 lifecycle 확인. 이제 A 객체가 존재하는 것이 정상.
- `preservation_readonly.sql`: 기존 함수371/정책119/table87과 주요9개 데이터 table의 비교 지문. 이후 정상 사용에 따른 데이터 변화는 장애로 단정하지 않는다.
- `postflight_readonly.sql`: 적용 객체/ACL/RLS/함수 본문·C 미적용 확인.
- `role_smoke_readonly.sql`: 기존 pending 계정의 차단과 정상 read contract를 READ ONLY transaction에서 확인. Auth/lifecycle 생성·변경0. 실제 JWT E2E는 아니다.

## 장애 대응

[승인된 비파괴 회수 SQL](../../candidates/task04b_preflight_20261111/disable_a_home.sql) →
[권한 검증](../../candidates/task04b_preflight_20261111/verify_a_readonly.sql) → 기존 지문 비교.
설정 이력 보존, 기존 RPC 유지. 원인 해결 후 [재개 SQL](../../candidates/task04b_preflight_20261111/restore_a_home.sql).
원본 combined rollback의 DROP은 사용하지 않는다. 정상 적용 후 불필요한 운영 revoke/regrant 시험은 하지 않았다.

## 아직 검증하지 않은 범위

실제 앱 계정 저장·변경·재실행/로그인 복원, 비어 있지 않은 운영 계정 간 설정 격리, 운영 ERASING 대상(현재0).
해당 기능은 동일 승인 SQL의 격리 DB 및 Flutter 모사 검증을 통과했지만 실제 계정 결과로 대체하지 않는다.
B/C/D 변경·합성 Auth fixture·기존 사용자 데이터 쓰기·삭제는 이 패키지에 없다.
