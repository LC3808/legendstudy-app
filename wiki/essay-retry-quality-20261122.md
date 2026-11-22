# 논술 재시도 최적화·Evidence ID·중단 복구 — 2026-11-22

상태: 최소 인용 위치 보정 구현·격리 검증·운영 배포 DONE. 의미적 부분 수정·원인별 상한·응답불확정 복구는 설계 PARTIAL. 기존 [운영 분석](essay-lab-stability-20261122.md), [대시보드](lab-dashboard-implementation-20261122.md), [관리자 복구](admin-run-recovery-20261122.md)를 계승한다. 신규 DB·기존 학생 action 승인으로 해석하지 않는다.

## 실제 코드 경로와 12회 원인

운영 Worker bdee88d0의 76개 모듈을 직접 내려받아 Git과 대조했다. HEAD에는 미배포 관리자 복구 코드가 있어 전체 Worker 빌드 교체는 금지하고 해당 운영본의 두 모듈만 수정한다.

`async_exam.execute_async_exam`은 완료 문항 checkpoint를 재사용한다. `essay_exam_retry`가 확정 실패 문항의 attempt를 늘리고, `Worker.execution_steps → prepare_input/retry_feedback → provider.evaluate → parse_provider/validate_output → semantic_review → finalize`가 그 문항을 처리한다. 따라서 **시험 전체 재생성은 아니지만 실패 문항의 첨삭 전체는 재생성**한다. 이미 완료된 문항은 다시 호출하지 않는다. `retry_feedback`은 이전 실패 코드와 독립검토 거절 항목을 다음 생성에 전달하지만 필드 단위 patch가 아니다.

12회=독립 검토 미승인8+EXACT_QUOTE4, 6개 요청 모두 후속 완료. 사건별 표·시간·토큰은 기존 분석 문서에 있다. 자동 복구와 학생의 재시도 클릭을 구분할 trigger 근거가 없어 6건을 자동 복구 성공으로 표현하지 않는다. 독립 검토의 grounding 실패7 등은 복수 항목 중첩이다.

**EXACT_QUOTE는 학생 답안 sentence_feedback의 quote/start/end 검사**다. 제시문 인용 오류로 단정하면 안 된다. 원문 문자열 일치와 Python codepoint 좌표가 모두 정확해야 한다. 과거 거절 candidate 본문을 보존하지 않아 4회가 좌표 오류인지 문자열 변형인지 소급 판별할 수 없다. 이번 패치가 과거 4회를 모두 예방했을 것이라고 주장하지 않는다.

## 구현: 정확한 인용문의 위치만 보정

`live_worker.align_exact_quote_offsets`는 원래 answer hash가 일치하고 인용문이 답안에 **정확히 한 번** 존재할 때만 잘못된 정수 start/end를 원문 위치로 계산한다. 인용문·관찰·근거·등급·기준·점수는 수정하지 않는다. 유니코드/공백 정규화, 유사 검색, 없는 문장 생성, 중복 발생 위치 추측, 문자열/boolean 좌표 강제 변환은 하지 않는다. 올바른 두 번째 발생 위치는 그대로 유지한다.

기존 `validate_output` 자체는 변경하지 않는다. 보정 후 전체 schema·hash·criteria·evidence·root binding·span 검증과 전체 독립 검토가 통과해야 저장된다. 검토 서명은 최종 보정 결과 hash에 결합된다. Provider 추가 호출은 없다. `quote_offset_alignment` 감사에는 원본 응답 hash/최종 hash/변경 좌표만 기록하며 답안·거절 결과 본문을 새로 복제하지 않는다. 별도 `quote-alignment-` checkpoint 이름으로 Provider 영수증과 충돌하지 않는다. 운영 `essay_ops_private.calls`는 receipt 이름 및 token/independent_review 조건을 함께 요구하므로 이 감사는 호출 집계에서 제외된다.

## 의미적 부분 수정 계약 — 설계, 미활성

1. 재사용 가능한 거절 candidate를 attempt/evaluation/answer hash/package hash/criteria version/reviewer version에 묶어 private artifact로 먼저 보존해야 한다. 현재는 검토 assessment와 hash만 있어 과거 candidate 복원은 불가능하다. 신규 저장은 접근권한·보존 기간·삭제 정책 검토와 DB 승인이 필요하다.
2. allowlist patch는 실패 check가 지목한 stable issue ID와 필드에만 허용한다. 예: grounding 실패는 해당 observation의 evidence_ids 및 근거 설명, root_binding 실패는 기존 criterion ID 중 관계 수정. 원문·시험·답안·criterion 정의·level/score는 고정한다. stance/length 등 영향 범위를 확정할 수 없거나 점수 변경이 필요하면 부분 수정 대상에서 제외하고 관리자 검토로 보낸다.
3. 서버가 원본 candidate+patch를 병합한다. foreign ID/중복 ID/새 기준/allowlist 밖 필드/원본 hash 불일치는 거절한다. 재전송은 parent candidate hash+patch request key로 멱등 처리한다. 결과 전체 `validate_output`과 8개 독립 검토를 다시 수행한다. 부분 검토만으로 통과시키지 않는다.
4. 한 번의 부분 수정 실패 후 무조건 전체 재생성하는 fallback을 넣지 않는다. 아래 총 예산 안에서 재판정하고 상한 시 관리자 검토 대기한다. 기존 정상 결과는 덮어쓰지 않는다.

## Evidence ID 계약 — 기존 재사용 우선

공식 제시문 package에는 이미 `reference.id/role/hash/version/locator`와 `text`가 있고 출력 `evidence_ids`는 claim의 허용 ID로 제한된다. 신규 대학/시험/문항 row를 만들거나 원문을 UPDATE할 이유가 없다. 기존 ID를 문장 단위 식별자로 오인하지 않는다.

후속 제안: 검증된 package의 원문 codepoint 구간을 결정적 규칙으로 분할하고 `source_unit_id=hash(package_digest, reference.id, reference.hash, start, end, segmentation_version)`를 파생한다. 서버 사전 `{id, reference_id, start, end, text_hash}`가 원문을 해석하며 AI는 허용 ID만 선택한다. 사용자 표시 인용문은 서버가 원문 slice로 구성한다. package/source hash가 바뀌면 새 ID를 발급하고 이전 attempt의 사전은 보존한다. 좌표/원문이 불확실한 OCR 근거는 연결하지 않는다.

학생 답안은 별도 answer hash 기반 `answer_span_id` namespace를 사용한다. 공식 근거와 학생 문장 ID를 섞지 않는다. 지금의 위치 보정은 이 후속 wire contract를 도입한 것이 아니다. 양쪽 output/prompt/parser/schema/signed review/DB writer를 버전 협상한 뒤 적용해야 하며 기존 v1.3 출력과 무단 혼용하지 않는다. 원문 인용 검사 완화 없음, 실제 Evidence ID 신규 데이터 설치 없음.

## 중단 요청 재확인

2026-11-22 16:27 KST 읽기 전용 조회: `03629605-9a58-4b78-8465-c5331ac1b1c7`, created 01:31:23 KST, lease 01:46:26 KST 만료, retry0. q0 completed 및 reviewed/usage 존재. q1 reconciling, provider 단계 PROVIDER_NETWORK_UNKNOWN, HTTP status 미기록. q1 응답·review·usage checkpoint가 없어 검증 가능한 결과 복원은 현재 불가능하다. Provider에서 실제 생성/청구가 되었는지는 확정 불가다.

billing reserved지만 credits_required0, 연결 원장0. 보관된 심사용 e7af의 예약1과 다르다. 이번에 답안/결과/checkpoint/원장/예약/상태를 변경하지 않았다.

기존 관리자 복구 패키지는 확정 실패 문항만 재실행하므로 q1 불확정 guard를 우회할 수 없다. 관리자 절차는 (a) 기존 상세에서 Provider 불확정·q0 보존 확인, (b) 증명 가능한 Provider 결과가 확보되면 기존 full validation+review+original writer 복원, (c) 확보 불가라면 Owner가 추가 호출 가능성과 중복 비용 불확실성을 확인하여 **q1만 새 attempt**로 실행 승인. (c)에는 별도 감사 가능한 reconciliation resolution DB 계약이 필요하다. q1 원기록은 유지하고 이전 attempt를 fence하며 새로운 attempt만 기존 retry 경로에 연결한다. SQL 준비·검증·설치 승인 전 비활성으로 유지한다. q0 재생성·기존 상태를 failed로 직접 UPDATE하는 방법은 금지한다.

## 원인별 재시도 정책 제안 — DB 승인 전 미적용

| 원인 | 제안 예산·대기 | 상한/불확정 처리 |
|---|---|---|
| 유일한 정확 인용의 위치 오류 | 로컬 보정1회, Provider0회 | 전체 검증·검토 실패 시 원래 원인으로 분류 |
| 품질 검토 거절 / 그 외 EXACT_QUOTE | 문항당 추가 시도 최대2, 같은 원인 반복도 차감 | 관리자 검토 대기, 성공/실패 정산을 강제하지 않음 |
| 확정429 등 실행되지 않은 일시 거절 | 추가2, Retry-After 우선·30/120초+jitter, 전체 budget 적용 | 관리자 검토 대기 |
| timeout/5xx/network unknown | 자동 새 Provider 호출0 | reconciliation 대기; timeout만으로 실패 확정 금지 |
| Worker 재시작/DB 저장 불확정 | 동일 attempt checkpoint 재조회, 큐 기존 상한3 유지 | 원 결과 검증·저장 재개, 새 생성 금지 |
| 인증/권한/schema/criteria 영구 오류 | 자동재시도0 | 관리자 검토 대기 |

제안 전체 문항별 추가 Provider 생성 budget은 최대4이며 품질2/확정인프라2 각각도 적용한다. 이는 Owner가 확정한 수치가 아닌 구현 검토안이다. 검토 대기는 run.state를 임의 추가하는 대신 별도 사유·attempt·budget·next_eligible_at·audit 상태로 설계하고 기존 결과/원장을 보존한다. 모든 student/admin/queue 진입이 같은 DB row lock 하에서 예산·lease·request key를 검사해야 우회가 없다. 클라이언트 버튼만 막는 패치는 하지 않는다. 자동 retry 활성화·신규 RPC/테이블/Migration은 이번에 설치하지 않았다. 현재 명시적 generation retry 상한 미설치 GAP는 남는다.

## 성능·비용 비교와 검증

| 지표 | 변경 전 관측 | 변경 후 |
|---|---|---|
| 완료8건 최초요청→완료 평균/중앙값 | 535.195초 / 192.494초 | 운영 표본 미확보 NOT TESTED |
| 재시도 사건 / 경험 요청 | 12 / 6 | 운영 표본 미확보 |
| Provider 영수증 | 생성32+검토28=60 (HTTP 총수 아님) | 실제 호출0, 인공 요청 미실행 |
| 입력 / 출력 token | 1,114,395 / 153,581 | 운영 절감량 미측정 |
| 독립 검토 | 28개 검토 중 미승인8, 승인20 | 동일 검토 유지, 실운영 개선율 미측정 |
| 완료 결과 정합성 | 완료8/8 문항수 일치 | 기존 데이터 해시 비교로 보존 검증 |

서로 다른 문항·모델·학생 대기 시간을 섞어 인과적 성능 향상을 주장하지 않는다. 예상 효과는 유일한 원문 인용의 좌표 오류에서 재생성 필요를 줄이는 것뿐이며 절감 비율/금액은 산출하지 않는다. 의미적 부분 수정도 token 감소를 측정하기 전 수치 약속하지 않는다. 새 표본은 배포 시각 이후 자연 발생 요청만 동일 정의로 비교하며 요청·문항 수와 unknown 포함 범위를 표시한다.

[격리 검증](evidence/essay-retry-quality-20261122-tests.json): 실제 운영 후보 import로117 PASS. 정상/품질 거절/timeout/429/Worker 재전달/DB ambiguous/fencing/기존 완료 문항 재사용/보관 차단/혼합 수학 checkpoint와 인용 보정 경계 검사 포함. 직접 단위25 PASS. 실제 Provider·학생 재실행·결제0. 큐, billing, DB RPC, 모델/프롬프트/criteria/scoring 변경0. 기존 감사 namespace와 호출 집계 분리를 검사했다.

## 보존 검토 일곱 답변

1. 요청·실행·검토·관측 시각을 구분하며 Provider 미기록 시각을 생성하지 않는다.
2. 원 answer/package hash와 기존 immutable checkpoint로 재현하며 인용문 자체는 바꾸지 않는다.
3. 기존 결과를 UPDATE하지 않고 신규 실행의 좌표 보정 감사만 추가한다.
4. 기존 run/evaluation/student identity를 유지하며 시험용 학생 복제를 하지 않는다.
5. 품질 거절/운영 장애를 학생 학습 성취나 지원 결과로 취급하지 않는다.
6. 감사는 hash/좌표 최소정보이며 raw candidate 신규 저장은 별도 privacy/retention 승인 전 미구현이다.
7. receipt count/quality 통과율/latency는 분모가 있는 파생값, 청구금액 UNKNOWN을0으로 치환하지 않는다.

## 운영·승인 경계

운영 결과는 아래 사후 기록으로 확정한다. WEB은 기존 대시보드 Pages e55b4622 유지. 관리자 recovery DB 패키지와 불확정 resolution은 미설치이며 실제 요청 재진행·복원·삭제·보관·환불·원장 변경0. 롤백은 Worker 이전 bdee88d0 100% 재배포로 코드만 되돌리고 새 감사/학생 결과를 지우지 않는다. 실행 중 요청을 강제로 중단·재제출하지 않는다.

### 운영 사후 확인 — 2026-11-22 16:32 KST

Worker `204cfb37-0b73-4f33-9f6c-86efc178539c` 100% 배포 DONE, 코드 commit `685e772928bc164a5be09c639a365e98aa9d09fe`. [배포 증거](evidence/essay-retry-quality-20261122-deployment.json): 76개 중2개 변경/74개 보존, 전체 다운로드 hash 일치, binding/compatibility/limits 설정 동일. WEB Pages e55b4622 및 LIVE/Finance Automatic 유지. 신규 DB 설치0, Provider 검증 호출0, 실학생 action0.

[전후 보존](evidence/essay-retry-quality-20261122-after.json): 고정9요청의 row/snapshot/answer/result/checkpoint/retry/billing/ledger/hidden hash 및15개 RPC 정의/ACL/owner 동일. q0 결과 보존·q1 응답불확정과 무료재첨삭 원장0 유지. DB 계정 권한 확대0. 과거 해시가 동일하다는 것은 배포 이후 미래 요청의 품질 향상을 입증하지 않는다.

최종 경계: 실제 인용 위치 보정은 DONE. 의미적 부분 수정/Evidence span 계약/원인별 상한/불확정 q1 전용 실행은 PARTIAL(설계, 운영 미활성). 실운영 시간·비용 개선 및 실제 학생 복구는 NOT TESTED. 신규 DB 정책과 q1 재실행은 별도 승인 대상이며 이번 기록으로 승인된 것으로 취급하지 않는다.
