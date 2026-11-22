# 관리자 불확정 복구·부분 재생성·상한 후보 — 2026-11-22

현재 운영: Owner 승인으로 DB·WEB·Worker 설치 및 실제 관리자 진단 완료. 실제 재실행0, 신규 품질정책 비활성. [배포·검증·추가 승인](admin-run-recovery-deployment-20261122.md). 아래 설치 전 상태는 구현 당시 이력이다.

상태: 코드·격리 검증 DONE, 운영 DB 설치/복구 활성화 PARTIAL(Owner 승인 대기), 새 정책의 실제 품질·완료율·시간·token 효과 NOT TESTED. 기존 [대시보드 운영](lab-dashboard-implementation-20261122.md), [정확 인용 보정](essay-retry-quality-20261122.md)은 재구현하지 않았다. [관리자 복구 계약](admin-run-recovery-20261122.md)의 A/B/C/D를 확장한다.

## Owner 결정과 보존 검토

Owner가 기존 완료 기능을 인정하고 관리자 미완료 문항 복구를 최우선으로 지정했다. 초기 후보는 **독립 검토 부분 수정 최대2회 → 전체 재생성 최대1회 → 관리자 검토 대기**, Provider 응답 불확정 자동 재실행0이다. 국소화할 수 없는 실패는 부분 호출 없이 전체 재생성1회로 이동한다. 이는 기존 문서의 제안 budget4를 대체하는 후보이며 운영 설치/활성화 승인이 아니다. 실제 학생 재실행은 별도 승인이다.

일곱 보존 검토: (1) 원 요청·새 attempt·관리자 intent/terminal·품질 단계 시작 시각을 구분한다. (2) 기존 frozen answer/package·원 checkpoint·원본 검토/후보 hash를 재사용한다. (3) 완료/불확정 원 checkpoint를 UPDATE하지 않고 retry generation과 immutable audit를 추가한다. (4) 동일 계정/run/evaluation identity 및 부모 무료재첨삭 연결을 유지한다. (5) 운영 복구 Decision과 학생 Learning 결과를 구분한다. (6) 새 품질 후보·검토는 기존 private checkpoint 권한/보존 범위에만 기록하며 WEB은 bounded 실패 설명만 받는다. 새 공개 테이블/수집·학생 복제0. (7) 기록된 호출 영수증·latency/집계와 실제 청구/품질 효과를 구분하고 UNKNOWN을0으로 치환하지 않는다.

## 관리자 복구 E: 불확정 문항만 새 시도

운영 읽기 확인: `03629605-9a58-4b78-8465-c5331ac1b1c7`는 parent `79788b36-3081-4e10-a408-c3ee6c0dbb2b`의 완료 결과에 연결된 `included_revision`, 필요 이용권0, billing reserved, 원장0이다. [유료→포함 재첨삭 정책](essay-lab-product-v1.md#credits--g1-commercial-policy-2026-09-29)에 부합한다. 무료여서 예약 상태만 있고 원장 row를 만들 필요가 없다. 복구용 추가 예약·차감·원장 정정은 필요하지 않다.

`admin_lab_run_recovery`는 기본 복구와 `uncertain_recovery.allowed`를 구분한다. 완료/확정실패/응답불확정만 존재하고 active lease·보관·종료·pending write·summary/final·q1 reviewed/usage/Provider receipt가 없으며 원장 정합성이 확인될 때만 명시적 불확정 복구 후보로 표시한다. 단순 시간 경과로 허용하지 않는다. 새로운 증거가 나타나면 진단 digest가 바뀌어 차단된다.

`admin_lab_recover_run(...,p_allow_uncertain=true)`는 기존 관리자 권한·account→run→billing 잠금·진단 token·작업 key를 검사하고 승인 intent를 기록한다. 승인 플래그도 멱등 키의 일부다. 일반 학생의 직접 API 호출은 차단된다. Worker-only context에서 **완료 문항의 기존 full validator/검토/원문 binding을 다시 검증**하고, 불확정 문항은 원 claim/evaluation identity 및 output 없음만 검증한다. 임의 failed/completed 변환 없이 DB finish 단계에서 대상 attempt만 증가시킨다. 일반 A/B/C/D는 기존 retry/finish를 유지한다. E는 기존 retry_requests 계약에 새로운 generation을 기록하고 기존 Worker consumer로 이어진다.

늦은 결과 차단은 lease token 회전으로 완료 claim을 깨뜨리지 않고, append-only 관리 audit의 `fenced_attempts`를 사용한다. checkpoint 트리거가 이전 문항 attempt의 새 begin/write를 거절하며 read는 유지한다. summary/final 및 run 종료는 최신 attempt의 완료 결과와 일치해야 한다. 옛 Worker가 기존 token/writer로 돌아와도 오래된 문항·전체 결과를 저장할 수 없다. 완료 문항 원본은 변경0이다. 이 보호 장치가 실제 사용된 뒤에는 rollback SQL이 제거를 거부하여 과거 실행이 다시 쓰기 가능한 상태가 되지 않는다.

실제 대상은 재실행하지 않았다. 관리자 경로: 요청 관리 → 복구 진단 → `Owner 승인 후 불확정 문항만 재실행` → 실행 승인 및 비용 불확정 안내 확인 → 최신 진단 재검증 → 서버 intent/순수 검증/원자적 새 시도 → 같은 화면에서 상태 재조회. **큐 접수를 완료로 표시하지 않는다.**

## 부분 재생성 구현

`quality_repair.py`가 기존 Worker의 opt-in callback으로 연결된다. 신규 평가 엔진은 만들지 않는다. `SemanticReview`가 기존 8개 검증 판정/사유를 보존하는 `ReviewRejected`를 전달한다. 평가 기준/독립검토 프롬프트·점수 규칙은 변경하지 않는다.

국소 수정은 grounding/root_binding/sentence_diagnosis 중 명시적으로 `[issue ID]` 또는 `"ID"`를 지목한 실패에 한한다. 대상을 확정할 수 없거나 stance/length/previous_task 등 전체 판단이 필요한 경우 full fallback으로 이동한다. 수정 allowlist는 해당 기준/개선항목의 explanation/action/evidence_ids 또는 문장 diagnosis/direction이다. level/점수·criterion 정의·ID·원문 인용·종합 의견·다른 필드를 변경하는 patch는 거절한다. 종합 의견과 국소 설명의 일치 여부는 전체 독립 검토가 다시 판단하며 해결되지 않으면 전체 재생성/관리자 검토로 간다.

모든 patch는 base candidate hash에 결합되고 최대12개 편집, 알려진 필드/ID만 허용한다. 병합 후 기존 정확 인용 보정·전체 schema/evidence/criteria/root/span 검증, 전체 독립 검토, 최종 hash-bound signed review를 모두 통과해야 기존 학생 결과 형식으로 저장된다. 전체 재생성도 동일 validator/검토를 적용한다. 부분 검토만 통과시켜 완료하지 않는다.

단계별 private candidate·assessment·Provider 결과·사용량을 기존 checkpoint에 보존한다. 외부 호출 전에 intent를 기록하므로 Worker 재전달/DB 응답 불확정에서 동일 단계를 다시 호출하지 않는다. network/timeout unknown은 부분→전체 fallback 사유가 아니다. 기존 lease/immutable writer 규칙이 계속 적용되며 lease 부족을 무시하거나 무한 연장하지 않는다. 기록된 generation token/latency는 최종 generation telemetry에 합산하고 독립검토 비용은 별도 receipt로 집계한다. 실제 금액이 없으면 NULL이다.

`ESSAY_QUALITY_REPAIR_ENABLED` 기본 false. 활성화 시 Worker-only `essay_exam_recovery_quality_ready()` 계약을 요구한다. quality-policy checkpoint는 최초 Provider 호출 전에 기록되며 DB retry trigger가 해당 회차의 무제한 외부 retry를 차단한다. 확정 실패 또는 예산 소진은 관리자 검토 대기, 응답 불확정은 reconciliation 보호를 유지한다. 자동으로 기존9요청에 marker/backfill을 만들지 않는다. 이미 진행 중이던 문항의 budget을 소급 재설정하지 않는다.

## 관리자 검토 대기 UI

기존 요청 상세/복구 패널에서 요청 ID, 대학·시험, 저장 완료/미완료·실패 문항, 실패 코드와 최대600자 검토 사유, 원 retry 수, 부분/full 시도 수, 기록된 마지막 실행 시각, 권장 검토 방법을 표시한다. 미기록 시각은 기록 없음이다. 상한 상태는 실행 버튼이 비활성이고 임의 완료/이용권 변경 기능이 없다. 직접 API에서도 DB guard로 재시도 우회를 거부한다.

부분/full 횟수는 durable 시도 intent 수이며 Provider 청구 횟수와 같다고 단정하지 않는다. 기존 result UI 계약은 유지했다. 기본 학생 결과·대시보드·결제/Finance 코드는 변경하지 않았다.

## 기존9요청 재현과 성능/품질 한계

[기록 재집계](evidence/essay-quality-followup-replay-20261122.json): 9요청/완료8, 최초 요청→완료 평균535.195초·중앙값192.494초, 재시도12/경험6, 영수증60, 입력1,114,395·출력153,581 token. 한 문항은 기존3회, 다른 문항은5회 재생성 후 완료됐다.

거절 후보 원문과 다른 정책으로 생성했을 결과가 남아 있지 않으므로, 이 메타데이터로 새 partial repair 성공률이나 완료율 비열등성을 재현할 수 없다. 과거 결과를 재실행하거나 새 모델 응답을 임의 생성하지 않았다. **상한을 단순 소급 적용하면 기존 완료를 보장하지 못한다.** 따라서 후보 정책은 구현/합성 검증 상태로 유지하고 생산 활성화는 보류한다. 변경 후 실제 시간/token/통과율/비용은 NOT TESTED이며 개선 수치 추정0이다. 정답처럼 만든 synthetic 성공 시나리오를 실학생 품질 검증으로 제시하지 않는다.

## 검증 결과

- [SQL 패키지](../supabase/candidates/admin_run_recovery_20261122/followup-result.json): PostgreSQL17, 실제 authenticated/anon/essay_worker 및 NOSUPERUSER owner로55 PASS. A/B/C/D/E, q0 보존/q1 새 attempt, active 차단, 일반학생 차단, 늦은 writer/오래된 최종결과 차단, 새 attempt 저장 허용, 동시 관리자/멱등, 원장0·기존 원장 보존, 상한 우회 거부, rollback 보호 포함. 실제 Toss·Apple 결제 E2E 아님.
- [배포본 기반 Worker 후보](evidence/essay-quality-followup-runtime-tests-20261122.json):166 PASS. 76→78모듈, 기존7개 수정·신규2개·69개 바이트 동일. 과학 입력 및 운영 retry_feedback 보존. 부분 성공/2회 실패→full1/추가 재시도 차단/불확정 fallback 금지/서명·기존 결과 저장 회귀 포함. 평가 Provider 실제 호출0.
- WEB 전체2252 PASS/5 SKIP, 후속 API·UI35 PASS(중복 합산하지 않음), 타입·Webpack production build PASS. 최초 Turbopack은 공유 node_modules symlink 경계 때문에 실패하여 기존 호환 Webpack 경로로 검증했다. KST 자정 표시는 h23을 명시해00:00으로 고정했다.
- 운영 read-only20:15 KST: [고정9요청과15RPC](evidence/essay-quality-followup-preservation-20261122.json)가 직전 배포 후 근거와 동일. 원장/답안/결과/checkpoint/retry/billing/hidden·함수/ACL/owner hash 모두 불변. DB 복구 함수 미설치 확인. WEB e55b4622/84c3f84a, Worker204cfb37 그대로.
- 실제 학생 복구, 실제 Provider 품질·비용 비교, 운영 신규 버튼 동작 E2E는 승인 전 NOT TESTED. 소스/자동화 통과를 운영 설치 완료라고 표시하지 않는다.

## 정확한 승인 대상과 설치 순서

대상 Supabase: `stlhijzpjfgwwdgunlsd`.

설치 SQL: [admin_run_recovery_20261122/install.sql](../supabase/candidates/admin_run_recovery_20261122/install.sql)

SHA256: `c52fb2c42b8a88264f671b78629a1fc89c4307b0d66e0015c1f62cd32676db50`

기존 미설치 승인 패키지를 이번 E/quality guard까지 확장했으므로 과거91875780… hash로 설치하면 안 된다. 기존 승인 절차 [AGENTS §4](../AGENTS.md#4-supabase-policy)를 따른다. 이 패키지는18개 함수,3개 보호 트리거,기존 관리자 감사 action vocabulary 확장이다. 기존 학생 row/backfill/원장 UPDATE0, 기존10개 RPC 정의/권한 보존 preimage guard 포함. 새 테이블 없음.

1. Owner가 **위 정확한 SQL 설치 및 검증 후 복구 WEB·Worker 배포**를 승인한다. 실제036… 재실행과 품질 정책 활성화는 포함하지 않는다.
2. 대상 프로젝트/새 source·ACL·제약·원본 데이터 hash를 확인하고 한 트랜잭션으로 install.sql 실행. [postcheck.sql](../supabase/candidates/admin_run_recovery_20261122/postcheck.sql)로 함수/권한/3개 trigger 확인.
3. 검증된 Worker 후보·WEB 배포. `ESSAY_QUALITY_REPAIR_ENABLED=false` 유지. metadata-only 관리자/일반회원 접근 및 화면 확인. 실제 요청을 검증용으로 클릭하지 않는다.
4. Owner가 대상 요청의 중복 청구 불확실성을 포함한 **실제 q1 재실행**을 별도로 승인한 뒤 관리자 UI에서 실행한다. 완료 q0/원장 보존 재확인.
5. 부분 재생성 정책의 품질·완료율 검증 근거를 확보한 뒤 별도 활성화 판단. 기존 학생 요청 재실행으로 검증하지 않는다.

[rollback.sql](../supabase/candidates/admin_run_recovery_20261122/rollback.sql)은 runtime adapters rollback 뒤 사용한다. 불확정 복구 fence나 quality-policy가 실제 사용되었으면 삭제를 거부한다. 이 경우 보호 트리거와 감사는 유지하고 forward fix한다. 기존 학생 결과/원장을 역변경하지 않는다.

개발 WEB commit: `75397907eba9ff1f7c2e68382db0f0714a68bd79` (Push 완료·운영 미배포). APP/SQL/Worker commit은 이 문서와 함께 기록하며 실제 운영 버전은 위204cfb37과 구분한다.
