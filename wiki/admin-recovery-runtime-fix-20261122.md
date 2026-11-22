# 관리자 복구 RUNTIME_UNAVAILABLE 해결 — 2026-11-22

**DONE: 운영 원인 재현·최소 수정·격리 검증·WEB/Worker 배포·실제 관리자 비파괴 진단.** 실제 q1 복구/Provider 호출·학생 완료 결과 검증은 **NOT TESTED / 이번 범위 제외**.

대상 `03629605-9a58-4b78-8465-c5331ac1b1c7`은 재실행하지 않았다. [21:36 승인 제출 실패](admin-recovery-q1-execution-20261122.md)와 [이전 WEB 허용 경로 수정](admin-recovery-binding-fix-20261122.md)을 구분한다. 이번 Owner 승인은 장애 수정·검증·필요 코드 배포이며 DB 변경과 실제 요청 재실행은 포함하지 않는다.

## 확정 원인과 호출 경로

운영 Worker b28790b2의78개 모듈을 내려받아 hash를 기록하고 실제 배포 entry/transport/복구 핸들러를 합성 입력으로 실행했다. **운영 `OperatingTransport.__init__`는 origin을 검증만 하고 `self.origin`을 저장하지 않는다.** 반면 로컬 버전은 test backend 지원 과정에서 이 속성이 추가돼 있었다. 새 관리자 RPC 코드는 `t.origin`을 사용했으므로 운영에서 첫 RPC URL 구성 중 AttributeError가 발생한다.

[entry.py](../tool/cloudflare_essay/entry.py)의 `Default.fetch → admin_rpc`에서 `t.origin+'/rest/v1/rpc/'+name` 평가가 실패한다. 기존 outer except는 `ESSAY_REQUEST_FAILURE AttributeError`만 기록하고 `RUNTIME_UNAVAILABLE`, HTTP503으로 바꿨다. 원본 예외가 변환된 오류이며 환경변수 누락·Provider 장애가 아니다. 기존 tests는 transport를 origin이 있는 SimpleNamespace로 대체하거나 로컬 부모 클래스를 사용해 운영 차이를 놓쳤다.

| 단계 | 21:36 실패의 확인 결과 | 수정 후 검증 |
| --- | --- | --- |
| 관리자 WEB→WEB API | RUNTIME_UNAVAILABLE 문구로 응답 수신 | 실제 UI 진단 PASS |
| WEB API 관리자 진단 | 원 JWT 기반 읽기 경로 | 실제 인증 관리자 PASS |
| Worker binding/라우터 | 기존 WEB 누락 수정 이후 도달 | 배포 경로·원 JWT 전달 PASS |
| 복구 핸들러 | recover_admin_run 진입, 첫 admin_rpc 호출 | 운영 캡처 격리 재현 PASS |
| transport 생성 | 생성되지만 origin 속성 없음 | 검증된 origin 명시 보관 |
| 첫 관리자 RPC | URL 생성 AttributeError로 네트워크 호출0 | 운영 관리자 읽기 RPC PASS |
| 평가 런타임 준비 | 실패 당시 미도달 | 운영 admission 초기화 PASS, Provider 호출0 |
| DB 복구 intent/attempt/감사 | 미도달·생성0 | 격리 PostgreSQL 실제 RPC PASS; 운영 mutation 미실행 |

[재현 영수증](evidence/admin-recovery-runtime-reproduction-20261122.json): 원 배포 모듈에서503/RUNTIME_UNAVAILABLE, origin_present=false, rpc_calls=0, AttributeError. 과거 요청의 내부 trace를 복구한 것은 아니며, **동일 운영 코드의 결정적 실패를 재현한 근거**다. Supabase 당시12:36–12:39 UTC postgres recover/ERROR 검색0과도 모순되지 않는다.

## 최소 수정 및 재발 방지

- [cloudflare_http.py](../tool/essay_lab/cloudflare_http.py): 부모가 검증한 origin을 AsyncOperatingTransport에 명시 저장. 정상 첨삭의 기존 고정ORIGIN 경로·평가 엔진·Provider 설정은 운영 bytes 그대로 유지.
- admin RPC만 HTTP 오류 본문 최대4096B를 읽고 허용된 symbolic code만 사용. 이전 fetch_bytes는 본문을 버려 active lease 등 조건 거절도 일반 권한 거절로 바뀔 수 있었다. 일반 Provider 호출은 error_limit=0인 기존 정책 유지. 원문/답안/키/토큰 로그 없음.
- [entry.py](../tool/cloudflare_essay/entry.py): 관리자 경로에 고정 stage/code 로그 추가. `ADMIN_RPC_UNAVAILABLE`(읽기 연결/응답 미확인), `RECOVERY_RUNTIME_INIT_FAILED`(런타임 준비 단계 실패), 권한 거절, 기존 복구 조건 거절, `RECOVERY_RESPONSE_UNCERTAIN`(mutation/finish/dispatch 응답 불확정)을 구분. 확인되지 않은 세부 원인을 확정하지 않는다.
- `/admin-exam-recovery-check`: 원 관리자 JWT로 진단 조회→기존 admission(공식 material·binding·review 설정·런타임 생성)→기존 Worker-only stable readiness RPC만 호출. recover/context/finish/claim/queue/Provider 호출 없음. readiness PASS는 실제 재실행 완료 보장이 아니다.
- WEB `functions/api/admin/essay-run.ts`, `src/lib/essay-runtime/server/worker-binding.ts`: `check_recovery`의 정확 payload와 새 읽기 경로만 추가. 기존 서버 관리자 검증/원 JWT 전달 유지.
- WEB `src/components/admin/admin-run-recovery.tsx`, `src/lib/admin/run-recovery.ts`: **Worker 연결 진단 (실행 없음)**과 원인별 bounded 안내. 기존 실제 실행·확인창·동일키/응답불확정 보호 유지.
- [캡처 패치 도구](../tool/cloudflare_essay/recovery_transport_patch.py)와 [실제 entry 검증](../tool/cloudflare_essay/test_recovery_entry_runtime.py): 모든 운영 module preimage hash를 확인하고2개만 교체. 로컬 전체 runtime을 덮어쓰지 않는다. 배포 전 실제 부모 constructor와 entry/handler/transport/admission/검증을 함께 실행한다.

## 검증 결과

| 항목 | 결과 |
| --- | --- |
| 실제 캡처 constructor/entry/handler·readiness·오류 본문 상한 | 9 PASS |
| 기존 Worker 평가/재시도/검토/저장/권한 회귀 | 166 PASS |
| 격리 PostgreSQL17 실제 역할·RPC | 55 PASS |
| WEB 관리자/API/실제 binding·UI/기존 server 회귀 | 274 PASS (29 files) |
| WEB 타입·lint·production Webpack/Functions build | PASS |
| 운영 관리자 연결 진단 | 21:53 KST PASS |
| 비로그인 API | 운영401 PASS |
| 일반회원 차단 | 격리 실제 PostgreSQL authenticated 역할 및 entry/API tests PASS |

DB55검사에는 q1 새 attempt/감사, q0 보존, active lease 차단, 옛 attempt 쓰기/최종결과 차단, 같은키·동시 관리자, 이용권0·원장 보존을 포함한다. entry tests는 외부 IO만 합성으로 교체하며 실제 material/runtime/복구 검증을 실행한다. 실제 Provider 청구·학생 재실행·일반회원 운영 계정 로그인·결제/환불 실거래는 NOT TESTED. DB schema 변경은 없으며 기존 설치된 RPC ACL도 읽기 확인했다.

명령: `python3 -m tool.cloudflare_essay.test_recovery_entry_runtime CAPTURE --reproduce-origin-bug`; 수정 후보에는 flag 없이 실행. `python3 -m tool.cloudflare_essay.verify_recovery_candidate CANDIDATE --manifest MANIFEST --report REPORT`; `python3 supabase/candidates/admin_run_recovery_20261122/test_followup.py`는 /private/tmp 격리 DB만 사용한다. [166검사 근거](evidence/admin-recovery-runtime-regression-20261122.json).

## 운영 배포 및 보존

- Worker source **a9bedebba77ca2a20a9e637c540791e7ccf07ae1**, version **29f4f6cc-433f-4e8e-8da4-9ca5710f2e71**, deployment70e6df7f-3db6-42cd-ace1-0cea6ec54d1e,100%. **entry.py/cloudflare_http.py 두 모듈 변경,76모듈 bytes 불변**, 설정/secret binding/queue/CPU/compatibility 불변. [Worker 증거](evidence/admin-recovery-runtime-worker-release-20261122.json).
- WEB source **4e8654378abc0b181ff0f902947b72af0c6c127f**, Pages **f1882082-9950-46cc-9f2c-fd35a17e9d4d**, success/production. 관리자 요청5파일·신규해시자산4개 및 API입력2개만 변경, 다른3168경로 보존. 실제 HTML/manifest 일치. [WEB 증거](evidence/admin-recovery-runtime-web-release-20261122.json).
- PAYMENT_MODE=LIVE, PAYMENT_FINANCE_AUTO=true 유지. 부분 재생성·신규 상한 비활성. DB Migration0, 학생 action0, 원장 변경0.
- 배포전21:44→배포후/비파괴진단21:53 **고정9요청과15기존RPC의 hash 불변**. 요청/답안/결과/checkpoint/retry/billing/ledger/보관 및 RPC소스·ACL·owner 비교. 전체 운영 테이블 모든행 비교를 뜻하지 않는다. [보존·대상진단](evidence/admin-recovery-runtime-preservation-20261122.json).
- Supabase health advisor 지적0. 기존 security/performance lint는 이번 transport AttributeError 원인으로 판단하지 않았고 권한/인덱스를 변경하지 않았다.

## 대상 복구 준비와 승인

21:53 운영 UI에서 정확 대상에 대해 연결 진단과 기존 읽기 진단만 수행했다. Worker 연결·관리자 권한·런타임·DB 읽기 PASS. q0 완료 attempt0/7개 checkpoint hash 불변; q1 reconciling attempt0/결과없음; lease만료; retry0; recovery history0; state reserved. included_revision의 credits_required/reserved/consumed0, ledger0. 신규 attempt/fence/감사 생성0이며 기존 설치된 fence 보호는 유지한다.

**실제 q1 재실행만 별도 Owner 승인 필요.** 승인 후 최신 상태 재진단→기존 q0검증/보존→q1 새 attempt 및 옛 attempt fence 원자적 생성→기존 큐/전체 검증 경로를 사용한다. 운영 mutation/실제 Provider 성공은 이번 작업에서 검증했다고 주장하지 않는다. 새 DB 승인 필요 없음. 품질 정책 활성화는 별도 승인 영역 그대로다.

원복: WEB2faad0e4와 Worker b28790b2로 코드만 되돌릴 수 있으나 origin 결함도 복원되므로 forward fix 우선. DB/학생 데이터 rollback 불필요. 예상외 실패 시 실제 재실행하지 않고 비파괴 연결 진단과 stage만 확인한다.

## 일곱 보존 검토

기존 [보존 결정](essay-quality-followup-20261122.md#owner-결정과-보존-검토)을 계승한다. (1) 이번 사실은 관리자 연결 진단 시점이며 첨삭 실행과 구분. (2) 원배포 hash·재현 영수증·기존 immutable 결과로 추적. (3) 학생 UPDATE/삭제0. (4) 동일run/student identity, 원관리자JWT 유지. (5) 운영 진단 Decision을 학생 Learning/Outcome으로 저장하지 않음. (6) 고정 symbolic 로그, 원문/secret 노출0, 기존 ACL 유지. (7) 준비 성공을 실제 복구 완료·Provider 과금0의 실측으로 대체하지 않음.
