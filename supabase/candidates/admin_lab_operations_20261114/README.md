# 관리자 논술 LAB 조회 후보 R1

상태: 2026-11-14 Owner 직접 실행 위임 후 R1 운영 적용/검증 완료. 재실행하지 않는다. WEB 배포 검증 진행 중.

대상 프로젝트: `stlhijzpjfgwwdgunlsd` (LegendStudy).
전체 `apply.sql`을 SQL Editor에서 한 번 실행한다. 임시 테이블/선택 실행에 의존하지 않는다.
마지막 결과 `ADMIN-LAB-20261114-R1`, `installed=true` 확인 후 `postcheck.sql` 실행.
기존 함수 원문 해시가 다르면 변경 없이 중단한다. 원인을 확인하기 전 guard를 제거하지 않는다.
설치 중 오류는 전체 트랜잭션을 원복한다. 성공한 설치의 재실행은 차단한다.

변경: 기존 admin_credit_member_list에 활동 집계·요청/완료순 추가,
admin_lab_runs 및 admin_lab_run_detail 관리자 읽기 전용 RPC 신설.
학생 API·이용권 계산 helper·원장·평가·사용자 레코드 변경 없음.
신규 RPC authenticated 실행 + 서버 관리자/활성계정 검사, anon/service_role 직접 실행 거부.
상세는 탈퇴/비활성 대상 거부, 답안·평가 외 dispatch 키/원본 telemetry 제외.

검증: `python3 test_isolated.py` (로컬 PostgreSQL17 필요).
격리 fixture만 생성하며 실제 운영에 연결하지 않는다. 정렬/검색/페이지/역할/계정,
베타 발급 연결/동률/재실행 차단/원복의 원본 보존을 검사한다.
기존 잔액 helper는 fixture stub이므로 운영 적용 후 실제 잔액 비교가 별도로 필요하다.

원복: 먼저 WEB 이전 배포로 복귀한 후 `rollback.sql` 전체 실행.
설치한 함수 원문 해시가 달라졌으면 원복도 중단하므로 후속 작업을 덮어쓰지 않는다.
신규 조회 함수2개 삭제, 기존 회원 목록 함수 복원만 수행한다.
회원·답안·결과·이용권 원장에는 쓰기가 없다.

계약/조사: [공식 Wiki](../../../wiki/admin-lab-operations-20261114.md).
