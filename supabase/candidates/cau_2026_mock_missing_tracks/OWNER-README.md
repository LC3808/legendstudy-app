# 중앙대 2026 모의논술 누락 계열 — 등록 보완 후보

상태: NOT_APPLIED / OWNER_APPROVAL_PENDING. Project stlhijzpjfgwwdgunlsd.

원인: 인문사회·경영경제 공식 문제/해설 resource 4개는 이미 존재하지만 해당 두 시험 Registry가 없다. 자연계열만 등록되어 UI도 그 계열만 표시했다. 기존 source-registration-v1 ID 생성 규칙을 그대로 재사용한다. 기존 자연 ID가 동일 규칙으로 재현됨을 확인했다.

대상: 인문사회3문항, 경영경제3문항(언어2+수리1). 변경: 비활성/review 시험2행 및 비공개 문항6행 추가만. 기존 자료 재업로드/ID 변경/정책/함수/RLS/Worker/Credit/History/Ledger 수정 없음.

실행 순서(Owner 승인 후): precheck.sql(4 true) → apply.sql → postcheck.sql(4 true). 같은 계열이 다른 ID로 이미 등록되면 중단한다. 기존 회차는 변경하지 않는다.

이 SQL만으로 STANDBY 완료가 아니다. 이후 기존 resource ID를 공식자료 패키지·문제 PDF manifest·Worker 실행 승인에 연결해야 한다. 경영경제 Q3은 기존 수리 입력/Math 실행 계약을 사용하며 언어 엔진으로 강제 연결하지 않는다. 실제 평가 호출은 하지 않는다.

rollback.sql은 별도 승인이 필요한 미사용 후보 복구용이다. 수정되거나 참조된 행은 삭제하지 않으며 FK/CASCADE 우회 금지. 운영 공개/학생 기록 생성 후에는 전진 수정만 준비한다.

문항별 평가 테스트/Provider 호출/DB 쓰기 실행 없음. 이 패키지는 기존 적용 완료 10회차 SQL과 별개다.
