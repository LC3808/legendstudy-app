# Credit 출처 동의 — Owner 운영 적용·독립 사후 확인 완료

2026-10-27. 기존 베타 일일 지급 migration 20261027040022는 재실행하지 않는다.

## 최소 변경

- private 조회 helper 1개: 실제 가용 지급분/출처별 잔액 및 기존 우선순위에 따른 선택 grant.
- worker 전용 공개 RPC 2개: 기존 quote/submit/cycle을 재사용하는 출처 포함 quote와 확인 grant 전달 submit.
- 기존 `essay_exam_private.reserve` 1개: 계정 잠금·기존 요청 replay 이후, 원장 쓰기 이전에 확인 grant와 실제 선택 grant를 비교. 불일치는 PT409로 원자적 중단.
- 이미 베타를 지급받은 사용자의 구버전 무동의 신규 제출은 차단한다. 이미 접수된 동일 요청 재조회·무료 재첨삭·예약 후 자정 정산은 유지한다.
- 구매 취소 대기 지급분은 기존 credit_summary와 동일하게 제외한다. 구매/환불 함수나 상태를 변경하지 않는다.
- 신규 테이블, 지급/차감, 캠페인 활성화, Secret, 역할 변경 없음. 기존 grant/finish/History 그대로.

## 검증

격리 PostgreSQL: 기존 베타 37 검사 재사용 PASS + 출처 확인 22 검사 PASS.
출처 변경/만료/동시 사용 시 다른 지급분 자동 전환 금지, 동일 요청 재조회, 실패 해제, 무료0, 익명·일반·service_role 직접 실행 차단 확인.
기존 공개 admission/package 호출은 격리 stub; 실제 Provider E2E가 아니다.

## 적용 이력 (재실행 금지)

Owner가 적용 후 5개 true 결과를 전달했고, Codex가 운영 readonly 사후검사 5개 true를 독립 확인했다. 기존 베타 설치 SQL 및 본 apply.sql을 다시 실행하지 않는다.

1. precheck.sql: 3개 true
2. apply.sql: 새 worker RPC와 reserve 제한 변경, hash guard 포함
3. postcheck.sql: 5개 true
4. WEB `ESSAY_CREDIT_SOURCE_ENABLED=true`로 배포. 새 WEB/APP은 확인 grant를 pending request와 함께 유지한다.

캠페인은 비활성 유지. 기존 SQL 파일 중복 실행 금지. 적용 전 manifest 및 실제 함수 hash 확인.

## 복구

rollback.sql로 캠페인 비활성화. 이미 지급된 베타 사용자에게 무동의 fallback을 다시 허용하는 reserve rollback은 금지한다.
WEB flag를 끄면 신규 출처 동의 요청이 안전하게 재확인 오류로 종료된다. 이전 요청·성공 결과·예약 정산은 유지한다.
기존 runtime 설치 SQL / apply-with-temporary-role.sql은 재실행하지 않는다.
