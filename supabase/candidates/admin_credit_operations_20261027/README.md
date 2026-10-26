# 관리자 지급 사용기한·지급 건별 회수 — 운영 적용 완료

Production `stlhijzpjfgwwdgunlsd`. **Owner 승인 후 2026-10-27 적용 완료 — 재실행 금지**. 기존 조회 RPC 및 과거 SQL 재실행 금지.

## 변경 범위

새 공개 RPC 3개만 추가한다. 기존 함수·테이블·RLS·만료 배치·결제/환불/Toss 계약 변경 없음. SQL 적용 자체는 기존 데이터에 쓰지 않는다.

- `admin_credit_operation_info(uuid,uuid)`: 관리자 전용 기능 버전 및 지급 건별 원장 집계 조회.
- `admin_credit_grant_expiring(uuid,text,integer,text,text,date,text,uuid)`: 기존 `credit_post_grant` 재사용. 1~100, 대상 이메일 재확인, 필수 사유. 관리자/이벤트/보상/기타(기타는 admin_grant origin+감사 사유 kind로 구분). 무기한 기본, 7/14/30/90일은 서버 현재 시각+24시간×일수, 직접 지정은 해당 KST 날짜 23:59:59. 재시도는 최초 저장된 만료일을 재사용한다.
- `admin_credit_recover(uuid,uuid,integer,text,uuid)`: 관리자/이벤트/보상 지급만, 해당 grant의 원장 잔액−예약분 한도. 이미 만료된 지급 제외. 계정→지급 건 잠금, 음수 adjustment 한 건 추가. 원본 사용·예약·지급 기록 UPDATE/DELETE 없음. 구매/가입/학교 지급 회수 금지.

모든 함수는 SECURITY DEFINER+빈 search_path, authenticated EXECUTE만 허용하며 내부에서 관리자·계정 권한을 검증한다. 사유/관리자/시각/지급·거래 UUID는 기존 원장 필드에 보존한다. 동일 키·동일 내용은 기존 결과 반환, 변경된 내용은 충돌 처리한다.

## 적용 이력 (완료, 재실행 금지)

1. `precheck.sql`: 8개 true. 기존 함수 5개 hash와 신규 함수 부재 확인.
2. `apply.sql`: 단일 transaction. 기존 지급 함수 hash guard, 신규 함수 생성. 이미 존재하면 실패하므로 재실행하지 않는다.
3. `postcheck.sql`: 기존 5개 함수 불변 및 신규 3개 함수 권한/설정 true.
4. 관리자 WEB 새로고침: 지급 유형·사용기한 및 회수 기능 활성화 확인. 운영 회원 지급/회수 테스트 금지.

2026-10-27 운영 READ-ONLY precheck: 8개 모두 true. Owner “RPC 3개 Production 적용 승인” 후 migration `admin_credit_operations_20261027` 성공. 사후검사 8개 true(기존 함수 5개 불변·신규 권한 3개). 운영 회원 지급/회수 실행0.

## 검증

격리 PostgreSQL17 / loopback 55439 / 합성 사용자만 사용. `isolated-fixture.sql` → `isolated-baseline.sql`(운영 지급 함수 정의) → `apply.sql` → `clock-access-fix.sql` → `python3 test_isolated.py`.
30검사 PASS: 무기한/7일/KST 지정일, 사유, 같은 지급 재시도, 전액/부분 회수, 사용·예약 보호, 만료 차단, 다른 지급 불변, 비관리자/anon 거부, 기존 지급, 동시 70+70 회수 중 하나만 성공, 원장 불변. rollback→apply도 PASS.
격리 fixture는 전체 운영 DB 복제본이 아니다. 운영 학생 History에 쓰지 않으며 실제 예약/정산 전체 E2E를 새로 실행한 것으로 보고하지 않는다.

## WEB 및 복구

RPC 부재/조회 실패 시 기존 무기한 관리자 지급만 유지한다. 새 만료일 지급·회수는 활성화하지 않는다. 확정되지 않은 요청 키는 sessionStorage에 보존해 같은 키로 재확인한다.
복구 순서: WEB 이전 배포 `30bfbe41-f1c3-4988-bf46-e01c3582ae05`(6934af8)로 복귀 → `rollback.sql`로 신규 RPC 3개만 제거. 지급/회수 실행 후에도 원장 기록은 삭제하지 않는다. 이미 실행된 운영 거래를 자동 역분개하지 않는다.

## 데이터 보존 검토

1. 기존 회원·grant·transaction ID를 사용한다.
2. 지급/회수는 새 불변 이벤트이고 기존 결과를 덮어쓰지 않는다.
3. 실행 시각은 DB 서버 기준이며 기존 생성 시각을 보존한다.
4. 원본 지급 ID·actor·사유·멱등키로 인과관계를 추적한다.
5. 잔액은 기존 원장 합계의 파생값이며 직접 UPDATE하지 않는다.
6. 관리자 운영 목적·기존 권한 내에서만 처리하고 신규 학생 학습정보를 수집하지 않는다.
7. History·평가·예약/정산·구매·가입 정책은 변경하지 않고 불명확한 실행 응답은 동일 요청으로 복구한다.

## 운영 시각 함수 보완

`clock-access-fix.sql`도 migration `admin_credit_operations_clock_access_20261027`로 적용 완료했다. 신규 RPC에서 권한이 제한된 `essay_private.clock()` 대신 동일 의미의 `pg_catalog.clock_timestamp()`를 사용한다. 기존 함수·ACL은 변경하지 않았다. 이후 사후 8개 true 및 실제 관리자 회수 정보 조회 성공. 두 적용 SQL 모두 재실행 금지.
