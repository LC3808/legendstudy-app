# 승인된 q1 복구 1회 실행 — 2026-11-22 21:36 KST

최신 후속: [운영 origin 결함 재현·수정·비파괴 진단 PASS](admin-recovery-runtime-fix-20261122.md). 아래 실패 시점 기록은 보존하며 이후 실제 재실행은 하지 않았다.

## 결론: PARTIAL / 추가 실행 중단

Owner가 WEB 연결 수정 확인 후 대상 `03629605-9a58-4b78-8465-c5331ac1b1c7`의 q1만 다시 승인했다. 관리자 화면에서 실행 버튼 1회, 확인창 2개 승인 후 `RUNTIME_UNAVAILABLE`에 해당하는 “복구 처리 응답을 확인하지 못했습니다”가 표시됐다. 같은 키 재제출 버튼도 누르지 않았다. 새 attempt/queue 접수 성공은 확인되지 않았고 기존 상태가 유지됐다.

이 기록은 [이전 제출 실패](admin-run-recovery-execution-20261122.md) 및 [WEB adapter 수정](admin-recovery-binding-fix-20261122.md) 이후의 별도 승인 실행이다.

## 실행 전 조건 — DONE

- 21:33:22 KST DB 및 21:36 관리자 진단: 전체2/완료1/미완료1, q0 완료 attempt0, q1 응답불확정 attempt0, q1 결과/검토/usage 없음.
- 실행 잠금은 11/22 01:46:26 KST 만료. active_lease=false.
- 설치된 recovery RPC/ACL/3개 보호 trigger postcheck PASS. 새 generation 확정 시 이전 attempt fence가 적용되는 계약 확인. 실제 기존 attempt 쓰기 테스트는 운영에서 실행하지 않았다.
- billing reason=included_revision, required/reserved/consumed=0, 연결 원장0. 기존 무료 재첨삭 정책과 일치.
- Worker b28790b2, Pages 2faad0e4 (WEB 4408c3e6) 운영 재확인. 부분 재생성·새 재시도 상한 비활성, Toss LIVE/Finance Automatic 유지.

## 실행 후 — 21:38:20 KST

| 검증 | 결과 |
| --- | --- |
| 관리자 제출 | DONE: 이번 승인으로 1회, 추가 제출0 |
| 새 attempt / 재시도 | 생성 확인0 / retry_count0 유지 |
| Worker 정상 처리 | PARTIAL: UI RUNTIME_UNAVAILABLE; 정상 queue 실행 미확인 |
| Provider 호출·응답 | 신규 receipt0. 정확한 upstream 호출 수는 측정 불가; 0회 단정 금지 |
| 완료 결과 | q0만 완료, q1불확정 유지, 최종 결과0, run reserved |
| 완료 문항 보존 | DONE: q0 관련7개 checkpoint 전체행 MD5 모두 불변 |
| 이용권·원장 | DONE: 추가 차감0, ledger0/빈 원장 해시 불변 |
| 복구 감사 기록 | 신규0, history=[] |
| 이전 실행 차단 | 설치된 보호 trigger 유지; 새 generation 미생성으로 새 fence 생성 미확인 |
| 관리자 KPI | 처리중1 / 재시도대기0 / 보관1 유지 |
| 학생 완료 결과 화면 | NOT TESTED: completed 미도달로 복구 후 전체 결과 검증 불가 |
| 처리 시간 | 새 attempt/완료 시각이 없어 산출 불가 |

## 원인 확인 범위

이전 오류 문구는 WEB catch의 REQUEST_UNCERTAIN이었다. 이번 문구는 RUNTIME_UNAVAILABLE이며 운영 Worker entry의 일반 예외 응답 코드와 일치한다. WEB 경로 허용목록 수정만으로 실제 복구 성공까지 검증됐다고 볼 수 없다. 원장/체크포인트/감사행이 추가되지 않아 DB 복구 intent의 영속적 생성은 확인되지 않는다. 이 사실만으로 Worker 내부 예외 지점 또는 Provider 호출 유무를 단정하지 않는다.

12:36–12:39 UTC Supabase postgres logs의 recover/ERROR 조건 조회 결과0. 현재 확보된 자료로 상세 예외 원인은 미확정. 후속은 Worker 구조화 실패 로그와 WEB→Worker→RPC 계약을 격리 재현하여 수정하는 작업이며, 대상 요청 재제출은 다시 Owner 승인 필요. 이번 작업은 코드·DB·배포 변경을 하지 않았다.

## 증거 및 Git

[마스킹된 전후 진단·해시](evidence/admin-recovery-q1-execution-20261122.json). 학생 답안·Provider 원문·JWT·진단 토큰은 기록하지 않았다. 보존 설계는 [기존 계약](essay-quality-followup-20261122.md)을 재사용하며 저장 구조 변경 없음.

실행 기준 APP/SQL/Wiki 86cc0e6dff9918edce70e9571909631daf1d7acb, WEB 4408c3e6bcba495dc83e310a2ce5380f9599bdd6. Worker 배포 b28790b2-3949-4ee3-ae59-96d3a9712bf4 유지. 본 보고 commit은 Git 이력에서 확인한다.
