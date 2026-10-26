# 관리자 크레딧 사용기한 지급·지급 건별 회수

2026-10-27. [기존 회원별 조회](admin-credit-directory-20261026.md)의 후속 구현. Owner의 신규 RPC 3개 Production 적용 승인 및 관리자 로그인 확인에 따라 반영했다.

## 현재 운영

- WEB branch `codex/web-app-release-20261024`, 구현 `f7122f9968e3e74a8908a83aacd127dc0ef7d73b`, 모달 보완 `41bd8f6ec6f99e6a998a3361878e0a96158bd919`. origin SHA 일치 확인.
- Pages Production `1517370e-3cff-4117-9347-ce1249af2986`, canonical deployment success 및 commit 일치 확인.
- Supabase `stlhijzpjfgwwdgunlsd`: migrations `admin_credit_operations_20261027`, `admin_credit_operations_clock_access_20261027` 적용 완료. 기존 함수 5개 불변 및 새 RPC 권한/설정 사후검사 8개 true.
- 운영 회원 지급·회수 실행 **0건**. Provider 호출·Credit 차감 0. 기존 History·원장 데이터 변경 없음. APP UI/Worker/Secret/결제·환불/Toss 변경 없음.

## 지급 및 회수 계약

기존 지급 함수와 grant 만료 구조를 재사용한다. 관리자 지급 기본값 무기한, 7/14/30/90일은 DB 서버 시각에서 일수×24시간, 직접 지정은 KST 해당 날짜 23:59:59이다. 관리자·이벤트·보상·기타 및 필수 사유/관리자/만료일/거래 식별자를 기존 원장에 기록한다. 기타는 admin_grant origin과 감사 사유 kind로 구분한다. 기존 구매/가입/쿠폰 정책은 변경하지 않는다.

회수는 특정 운영 grant의 원장 잔액에서 예약분을 뺀 수량만 가능하다. 구매·가입·학교 지급과 만료 지급은 제외한다. 계정→grant 잠금으로 동시 요청을 직렬화하고 음수 adjustment를 추가한다. 기존 원장 UPDATE/DELETE 또는 회원 잔액 직접 UPDATE는 없다. 동일 요청 키는 기존 결과를 반환하며 다른 내용의 재사용은 차단한다.

관리자 전용 RPC: `admin_credit_operation_info`, `admin_credit_grant_expiring`, `admin_credit_recover`. SECURITY DEFINER, 빈 search_path, authenticated EXECUTE 및 함수 내부 관리자/계정 검증. 새 권한을 일반 사용자에게 부여하지 않는다.

## WEB UI 및 운영 확인

기존 지급 모달에 유형·기한 선택과 직접 날짜·사유·최종 확인을 추가했다. 지급 내역은 무기한 또는 KST 만료 시각을 표시한다. 지급 건별 회수 모달은 최초 지급/사용/예약/기존 회수/만료/회수 가능/회수 후 잔액을 표시한다. 사유 없는 실행은 비활성화한다. 확정되지 않은 요청 키는 sessionStorage에 보존하여 재시도 중복을 방지한다. RPC 준비 여부를 확인하지 못하면 신규 기능은 닫고 기존 무기한 지급을 유지한다.

Production 관리자 계정에서 회원 목록·상세·기존 거래 내역·6개 사용기한 옵션·직접 지정 입력·회수 모달을 확인했다. 기존 10 지급/6 사용/4 미사용의 회수 가능 4 표시, 구매·가입 지급 회수 비활성화, 사유 미입력 실행 차단을 확인했다. 최종 지급·회수 버튼은 실행하지 않았다.

운영 조회에서 내부 clock 함수 실행 권한 오류를 발견했다. 권한을 확대하지 않고 신규 RPC 내부에서 동일한 PostgreSQL 서버 시각 함수를 직접 사용하도록 보완했다. 수정 후 조회 성공을 확인했다.

PC UI 확인 완료. 모바일 400px 에뮬레이션 진입 후 브라우저 클릭 제어(CDP)가 시간 초과되어 모바일 모달 조작 완료로 보고하지 않는다. 반응형 CSS는 적용되어 있으나 실제 모바일 최종 확인은 남아 있다.

## 검증

- 격리 PostgreSQL17 합성 계정 30개 검사 PASS: 무기한/7일/지정일/과거일 차단, 필수 사유, 지급 멱등성, 전액/부분 회수, 사용·예약·만료·다른 지급 보호, 중복/동시 초과 회수 차단, 비관리자/anon 거부, 기존 지급, 원장 불변.
- 관련 WEB UI/adapter 테스트 59개 PASS, Typecheck PASS, Lint 오류0(기존 경고4), Production Build PASS.
- 격리 환경은 전체 운영 DB 복제본이 아니다. 실제 운영 지급·회수 거래 검증은 하지 않았다. 기존 예약/정산 전체 E2E를 다시 수행한 것으로 보고하지 않는다.

## SQL·복구·인수인계

[SQL README 및 보존 검토 7항목](../supabase/candidates/admin_credit_operations_20261027/README.md), [최초 적용](../supabase/candidates/admin_credit_operations_20261027/apply.sql), [시각 함수 보완](../supabase/candidates/admin_credit_operations_20261027/clock-access-fix.sql), [사후검사](../supabase/candidates/admin_credit_operations_20261027/postcheck.sql), [롤백](../supabase/candidates/admin_credit_operations_20261027/rollback.sql).

**이미 적용한 두 SQL 및 과거 directory SQL을 재실행하지 않는다.** 장애 시 WEB 이전 Pages `30bfbe41-f1c3-4988-bf46-e01c3582ae05` (6934af8)로 복귀 후 rollback.sql로 신규 RPC 3개만 제거한다. 이미 생성된 거래는 삭제하거나 자동 역분개하지 않는다.

다음 확인은 Owner의 실제 모바일 관리자 화면 확인이다. 실제 지급/회수는 관리자가 대상·수량·사유를 확인해 명시적으로 실행한다. 현재 별도 SQL 승인 대기 없음.
