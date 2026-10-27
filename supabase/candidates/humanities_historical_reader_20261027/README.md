# 과거 패키지 조회 호환 변경 — Production 적용 완료

기존 부분 공개 4회차를 전체 문항으로 확장할 때, 기존 요청에 고정된 평가자료 digest를 계속 조회하기 위한 변경이다.
대상: 숭실 2024 수시·2026 수시·2027 모의, 숙명 2026 수시 1회차.

기존 public.essay_material_runtime_package(uuid,text) 함수 1개의 과거 조회 허용 범위만 확장한다. 신규 테이블·권한 변경 없음. 지급/예약/사용/History 함수 변경 없음.
기존 서울여대·성균관대 허용 조건은 유지한다. 추가 4회차는 approved-history-manifest.json의 정확한 revision/digest만 허용한다. 현재 승인 및 현재·과거 자료 전송 권한, 문항 ID, digest 검사는 유지한다.

Owner 승인 후 Production precheck.sql → apply.sql → postcheck.sql 적용 완료. baseline/exact_reader 모두 true. APPLIED.json 참조. apply.sql 재실행 금지. 그 다음 별도의 전체 문항 패키지 연결을 적용한다.
롤백: 패키지 확장 전에는 rollback.sql로 원복 가능. 확장 후에는 신규 실행을 먼저 중단하고 기존 요청의 과거 digest 조회가 필요한지 확인한다. 과거 조회가 필요한 동안 reader를 되돌리면 안 된다.
