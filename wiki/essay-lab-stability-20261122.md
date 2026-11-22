# 논술 LAB 운영 안정성 긴급 점검 — 2026-11-22

상태: 분석·최소 Worker/WEB 패치 운영 적용 DONE. 실제 중단 요청 복구·과거 통신 세부 원인/청구 확인 PARTIAL. 기준 기간은 KST 2026-11-16 00:00부터 11/22까지이며 화면 캡처의 마감은 11/22 15:04:40이다. 후속 운영 변화는 별도 시각을 기록한다. 기존 [Worker 보존·복구](essay-worker-incident-20261028.md), [관리자 보관 정책](admin-archived-run-operations-20261120.md), [장기 보존 전략](longitudinal-learning-admissions-data-strategy.md)을 계승한다.

Owner 승인: 먼저 근거로 원인을 보고하고 필요한 최소 코드 패치·테스트·운영 배포. 실제 학생 요청 재진행, 이용권 변경·환불은 별도 승인이다. 이번 분석은 READ ONLY로 수행하며 답안 원문·이메일·credential을 보고서에 복사하지 않는다.

## 확인된 원인

최근9건=완료8·미완료1, 재시도12건은 이9건 중6건에서 발생했다. 과거 생성 요청의 기간 내 재시도는0이다. 재시도 직전 실패 코드는 독립 검토 미승인8회, 정확 원문 인용 검사 EXACT_QUOTE4회다. 두 경우 모두 생성/검증 단계의 품질 검사 거절이며 Provider 장애·DB 저장 장애로 임의 분류하지 않는다. 6건 모두 후속 재시도로 완료됐다. 분류 G(품질/응답 검증 거절 후 복구)에 해당한다. A처럼 일반적인 일시적 인프라 오류로 단정하지 않는다.

활성 요청 `03629605-9a58-4b78-8465-c5331ac1b1c7`는 경희2027모의 사회 무료 재첨삭이다. 11/22 01:31:23KST 생성, 실행 잠금01:46:26 만료, retry0. q0 완료, q1 reconciling, provider 단계 PROVIDER_NETWORK_UNKNOWN/HTTP 미기록. 15시 조회 시 정상 실행 중이 아닌 응답 불확정 보존 상태다. billing은 reserved이나 credits_required0이고 원장 예약/차감0이다. 과거 심사용 e7af 요청은 보관되어 활성 집계에서 제외되며 이 요청과 다르다.

## 결과·원장 및 호출 근거

완료8건은 답안수와 결과question수가 모두 같다. 일반 첨삭7건은 signup_bonus 이용권에서 reserve1+consume1씩이며 중복 차감 없음. 완료/미완료 무료재첨삭2건은 원장0이다. 기존 보관 심사용 요청의 예약1과 새 무료재첨삭의 상태reserved/수량0을 혼동하지 않는다.

Provider 영수증60건(생성32·독립검토28)은 실제 전체 HTTP 요청 수나 청구 횟수와 같다고 단정하지 않는다. cost는UNKNOWN, called_at은NULL이므로 정확한 과금액과 호출 시각을 복원할 수 없다. 저장된 토큰과 latency만 별도 집계한다. 중복 실행 증거와 품질 거절 후 명시적 재생성 비용은 구분한다. 학생요청/Provider API를 재실행하여 원인을 재현하지 않는다.

## 로그 확인

[Supabase 집계 로그](evidence/essay-stability-20261122-logs.json): 같은 기간 retry HTTP200 12회, session_checkpoint HTTP200 753회, finish HTTP2008회. 이경로의 비200은 관측되지 않았다. 로그 HTTP횟수는 멱등 재전송/폴링을 포함할 수 있어 DB사건·Provider호출과 동일시하지 않는다. history_page404는33건이며 정상history200과 구분되는 선택적 목록경로 문제로 결과저장 실패의 근거가 아니다.

11/22의 PostgreSQL 오류995건23514는 account_private.guard_request, 57건PT404는 payment_process 문맥이었다. 논술 저장 오류로 합산하지 않고 별도 서비스 조사 대상으로 남긴다. 이번에 해당계정/결제코드를 수정하지 않는다. Cloudflare 과거 Observability API는403이며 기존권한을 확대하지 않았다. 과거 Worker재시작/CPU제한/정확Timeout을 입증하는 로그는 미확보다.

## 재시도·보존 검토

1. 요청/완료/retry시각과 조사시각을 분리한다. 없는 Provider called_at을 checkpoint 순서로 추정하지 않는다.
2. 고정 snapshot·checkpoint·Provider영수증·설치함수·배포모듈이 근거다. 원문은 노출하지 않는다.
3. 기존결과/원장/실패기록을 덮어쓰지 않는다. 오류분류 개선은 앞으로 생성되는 기록에만 적용한다.
4. 기존 run/account/owner를 유지하고 시험용 학생복제·실제 재제출을 하지 않는다.
5. 처리장애·품질검수거절을 학생실력/성취판정과 구분한다.
6. 최소한의 symbolic error/stage/status/elapsed만 기록하고 답안·API응답·토큰비밀을 기록하지 않는다.
7. 성공률·평균소요시간·비용은 자료범위가 제한된 파생값이며 UNKNOWN을0으로 표시하지 않는다.

Provider 요청은 기본/상한75초, 자동 SDK retry/backoff 없음. 429는확정거절 failed문항, 5xx/통신불명은reconciling으로보존한다. 큐는batch1/max_retries3/retry_delay0, DLQ와본문retention24시간, DLQconsumer0. 재전달은checkpoint를재사용하므로같은attempt의Provider재생성을막는다. 모호한외부실행을횟수초과만으로실패정산하는것은안전하지않으므로강제실패/환불하지않는다. 확정 실패에 대한 명시적 generation 재시도에는 상한이 없다. 자동 큐 재전달과 별개인 정책 GAP이며 학생 이용권 정산을 동반하는 강제 실패 정책은 이번 패치에서 추가하지 않는다.

## DB 읽기 전용 조사 결과 (2026-11-22 15:12 KST)

기간은 KST 11월 16일 00:00 이상~11월 23일 00:00 미만이며, Supabase `stlhijzpjfgwwdgunlsd` 운영 조회다. 변경·재실행 없이 조사했다. 실제 관리자 RPC는 요청 9, 완료 8, 실패 0, 재시도 발생 12 / 현재 처리 중 1, 재시도 대기 0, 보관 1을 반환했다.

| 요청 ID | 시험 | 생성 KST | 완료 KST | 생성~완료 | 재시도 | Provider 단계 영수증 | 결과/제출 문항 | 이용권 필요 / 정산 |
|---|---|---|---|---|---:|---:|---:|---|
| `79e4168f-a018-4f45-96ca-b41b727a61fe` | 2026학년도 성균관대학교 모의논술 언어형 | 11-20 14:23:46 | 11-20 14:27:07 | 3분 21.4초 | 1 | 8 | 3/3 | 1 / settled |
| `d9714b6f-c8ac-4cd6-b4e4-553c1898c6ce` | 서강대학교 2026학년도 수시 논술 인문계열(경제경영) | 11-20 22:19:09 | 11-20 22:22:02 | 2분 53.6초 | 1 | 6 | 2/2 | 1 / settled |
| `b0cd5b26-8333-4a62-b16d-0394fd58f50c` | 서강대학교 2026학년도 수시 논술 인문계열(경제경영) | 11-21 03:10:27 | 11-21 03:12:07 | 1분 40.2초 | 0 | 4 | 2/2 | 0 / settled |
| `56e42287-8150-455b-b534-1fdbeaeeafc1` | 2026학년도 한국외국어대학교 수시논술 인문계 T1 | 11-21 16:44:50 | 11-21 16:51:47 | 6분 57.2초 | 1 | 8 | 3/3 | 1 / settled |
| `79788b36-3081-4e10-a408-c3ee6c0dbb2b` | 경희대학교 2027학년도 모의논술 사회계 | 11-22 00:14:15 | 11-22 00:21:40 | 7분 24.3초 | 3 | 10 | 2/2 | 1 / settled |
| `03629605-9a58-4b78-8465-c5331ac1b1c7` | 경희대학교 2027학년도 모의논술 사회계 | 11-22 01:31:23 | — | 미완료 | 0 | 2 | 0/2 | 0 / reserved |
| `c37166d0-6a21-45d3-beb8-de87ce9c81a1` | 2025학년도 서강대학교 수시논술 인문계열(경제경영) | 11-22 02:38:05 | 11-22 02:39:40 | 1분 35.0초 | 0 | 4 | 2/2 | 1 / settled |
| `4dcb49e5-789d-4e5b-9989-61a116f47e18` | 서강대학교 2026학년도 수시 논술 인문계열(경제경영) | 11-22 09:51:22 | 11-22 09:54:26 | 3분 3.6초 | 1 | 6 | 2/2 | 1 / settled |
| `741c72ae-fafb-44d9-8d95-9a4de35cffa6` | 2025학년도 한국외국어대학교 수시논술 인문계 T3 | 11-22 11:29:29 | 11-22 12:13:55 | 44분 26.2초 | 5 | 12 | 3/3 | 1 / settled |

완료 8건의 소요시간 중앙값 192.494초, 평균 535.195초, p95 1888.562초, 최대 2666.250초다. 최장 외대 요청은 최초 재시도까지 33분 11.955초 간격이 있으므로 44분 26초 전체를 Provider 처리 지연으로 단정할 수 없다. 화면 성공률 100%는 completed+failed 8건만 분모로 삼아 미완료 1건을 제외한다.

### 재시도 원인

12건은 전부 이 기간에 생성된 요청에서 발생했고, 과거 요청에 대한 기간 내 재시도는 0건이다. `INDEPENDENT_REVIEW_NOT_ACCEPTED` 8건과 `EXACT_QUOTE` 4건이다. 세부 요청·문항·직전 attempt·코드는 JSON의 retry_events에 기록했다.

- 성균관 79e4 q2 1회, 서강 d971 q1 1회, 외대 56e4 q0 1회, 경희 7978 q0 3회, 서강 4dcb q1 1회: 독립 검토 미승인.
- 외대 741c q1 5회: EXACT_QUOTE → EXACT_QUOTE → EXACT_QUOTE → 독립 검토 미승인 → EXACT_QUOTE 후 마지막 attempt 5 완료.
- 미승인 검토 8회에서 grounding 7회, root_binding 2회, stance_preservation 1회, no_content_clarity_confusion 1회, length_requirement 1회 fail. 복수 항목이 한 검토에서 실패할 수 있다. 서술 reason·학생 답안은 읽거나 저장하지 않았다.

### 재시도 12회 사건별 분류

문항은 0부터 시작하는 내부 index다. 각 행은 G(품질 검증 거절 후 복구)이며 후속 완료가 확인됐다.

| KST 발생 시각 | 요청 ID 앞8자리 | 문항 / 직전 attempt | 직전 거절 코드 |
|---|---|---|---|
| 11-20 14:26:15 | `79e4168f` | q2 / 0 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-20 22:21:07 | `d9714b6f` | q1 / 0 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-21 16:50:38 | `56e42287` | q0 / 0 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-22 00:17:24 | `79788b36` | q0 / 0 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-22 00:18:48 | `79788b36` | q0 / 1 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-22 00:20:38 | `79788b36` | q0 / 2 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-22 09:53:47 | `4dcb49e5` | q1 / 0 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-22 12:02:40 | `741c72ae` | q1 / 0 | EXACT_QUOTE |
| 11-22 12:03:52 | `741c72ae` | q1 / 1 | EXACT_QUOTE |
| 11-22 12:07:16 | `741c72ae` | q1 / 2 | EXACT_QUOTE |
| 11-22 12:09:14 | `741c72ae` | q1 / 3 | INDEPENDENT_REVIEW_NOT_ACCEPTED |
| 11-22 12:12:42 | `741c72ae` | q1 / 4 | EXACT_QUOTE |

### Provider 사용량과 비용 한계

| 범위 | 생성 영수증 | 독립 검토 영수증 | input tokens | output tokens | 기록된 latency 합 |
|---|---:|---:|---:|---:|---:|
| 최초 attempt | 20 | 19 | 726,294 | 87,870 | 841.704초 |
| 재시도 attempt | 12 | 9 | 388,101 | 65,711 | 574.593초 |
| 합계 | 32 | 28 | 1,114,395 | 153,581 | 1,416.297초 |

생성 영수증은 openai/gpt-5.6-sol이다. 독립 검토는 top-level 및 nested telemetry 모두 model/provider가 저장되어 있지 않다. 현재 운영 설정은 독립 검토도 OpenAI/gpt-5.6-sol이지만, 이는 과거 모든 호출의 실제 모델을 증명하는 영수증이 아니다([런타임 근거](evidence/essay-stability-20261122-runtime.json)). 60개 모두 monetary cost UNKNOWN, called_at NULL이다. 잠재 호출 1건은 영수증이 없어 집계되지 않는다. 따라서 60건은 정확한 전체 과금 호출 수가 아니며, USD 비용을 추정하지 않았다. latency 합은 병렬 실행·재시도·사용자 대기와 별개이므로 벽시계 완료시간과 다르다. 검증 통과에 필요한 재생성이 섞여 있어 재시도 사용량 모두를 불필요한 비용이라고 판단하지 않는다.


저장 영수증의 응답 시간은 다음과 같다. 응답 불확정 1건은 영수증이 없어 제외되어 있으며, 따라서 이 표로 전체 호출 성공률이나 Timeout 비율을 계산하지 않는다.

| 단계 | 영수증 수 | 평균 기록 응답 시간 | 최대 기록 응답 시간 |
|---|---:|---:|---:|
| 생성 | 32 | 29.614초 | 57.441초 |
| 독립 검토 | 28 | 16.738초 | 24.066초 |

Rate Limit·5xx의 확인된 사건은 해당 12회에 없고, 응답 불확정 요청은 HTTP status가 저장되지 않아 배제할 수 없다. 응답 형식 문제와 품질 검증 거절은 구분한다. 현재 증거로 Provider 전체 성공률·Timeout 횟수·과거 Worker 재시작 횟수는 NOT VERIFIED다.

### 현재 처리 중 1건

`03629605-9a58-4b78-8465-c5331ac1b1c7`: 경희 2027 모의 사회계, KST 11/22 01:31:23 생성, 실행 lease는 01:46:26 만료. q0 완료 및 reviewed/usage 영수증 존재, q1은 reconciling이고 output 없음. q1-a0-execution-failure는 `PROVIDER_NETWORK_UNKNOWN`/provider/http_status NULL/provider_call possible. q1 생성/검토 영수증·reviewed·usage·final 없음. 재시도 이력 0건.

관리자 retry/archive 모두 false, 사유 `RECONCILIATION_REQUIRED`. 포함 재첨삭으로 credits_required=0, 해당 요청 credit ledger 행 0건이다. run state reserved이므로 처리 중에 포함되고, q1이 failed가 아닌 reconciling이라 재시도 대기에는 포함되지 않는다. checkpoints 테이블에 시각 열이 없고 failure에 elapsed/response_id/시각도 없어 75초 timeout인지 DB 단독 확정할 수 없다. 자동 재실행은 중복 호출 우려가 있어 조사 단계에서 실행하지 않았다.

보관 1건 `e7af7e52-eba9-46c3-aba4-0961ea516b48`은 KST 11/20 22:17:16 보관 기록이며, 활성 1건과 별도 요청이다.

### 결과·원장 보존

명시 재시도 RPC `essay_exam_retry`는 실패 문항 attempt와 generation을 1씩 증가시키며 상한을 검사하지 않는다. 테이블도 generation > 0만 검사한다. 현재 전체 기간 max generation 15가 관측되었다. Queue 자동 재전달 최대 3회와 학생/관리자 명시 재시도는 별개다. 명시 재시도의 최대 실패 종료 정책은 GAP이며, 자동 실패 전환·원장 정산 정책 변경은 수행하지 않았다. 운영 retry 함수 MD5는 `b505a07b40ff3bbb9490705adf426164`이다.

완료 8건 모두 제출 snapshot questionId 배열과 결과 questionId 배열이 정확히 일치하고, 고유 문항수 및 final checkpoint 1개가 확인됐다. 일반 첨삭 주기 7건은 signup_bonus 이용권 각 1개 reserve/consume이고, 포함 재첨삭 2건은 원장행 0개다. 중복 소비 의심 0, release/refund 0. 현재 public.essay_exam_finish 정의 MD5는 `b2ff3dce059d8a5d6b3652094c6a757a`다.

전체 조사 쿼리는 READ ONLY 트랜잭션으로 실행했다. schema/권한/기존 요청/학생 답안/결과/결제/원장 변경, Provider 호출, 재진행·삭제·보관·복원 모두 0회다. 한 차례 raw reviewer 필드 조회는 자동 승인 검토가 개인정보 범위 초과로 실행 전 차단했고, 필드 구조·검증 enum만 조회하는 안전한 대체 조회를 수행했다.

상세 근거: `wiki/evidence/essay-stability-20261122-db.json`. 보안·성능 advisor는 기존 project-level 항목을 집계했으며 이번 원인으로 단정하거나 관련 없는 hardening 변경을 수행하지 않았다.

## 최소 패치 및 검증

운영 적용 완료: 75초 제한과 기존 실패/불확정 상태 전환을 유지하면서 timeout·network·body_read·response_too_large·HTTP 오류를 제한된 진단 필드로 구분한다. 관리자에는 만료된 잠금과 RECONCILIATION_REQUIRED를 함께 확인해 응답 확인 필요 및 자동 재진행 불가를 표시한다. 품질 기준, 프롬프트, DB schema, 재시도·차감 정책은 변경하지 않는다.

기존 코드/다운로드한 운영 런타임 합성 검증 및 로컬 PostgreSQL 결과는 [테스트 근거](evidence/essay-stability-20261122-tests.json)에 기록했다. 신규 패치 검증·배포·사후 확인은 아래에 기록했다. 실학생 E2E/Provider 실호출·중단 요청 복구는 수행하지 않는다.

## 운영 판단과 남은 조치

- **DONE — 재시도 분류:** 6개 요청의 12회는 G(품질 검증 거절 후 복구). B/C/D/E/F를 입증하는 사건으로 분류하지 않는다. 성공한 8건의 결과·정산 정합성은 확인했다.
- **PARTIAL — 활성 요청:** `03629605-9a58-4b78-8465-c5331ac1b1c7`는 실행 중이 아니라 결과 불확정 보존 상태다. 기존 관리자의 재진행/보관도 허용되지 않는다. 승인 없이 상태·잠금·checkpoint를 초기화하지 않는다. Provider 처리 여부를 확인한 뒤 q0 보존·q1 한정 복구 및 중복 과금 위험을 명시한 별도 복구안이 필요하다. 이번 패치는 이 요청을 재실행하거나 소급 진단하지 않는다.
- **PARTIAL — 호출·비용:** 저장 영수증에서 동시 중복 실행 증거는 찾지 못했지만, 전체 HTTP 이력 및 Provider 청구 자료가 없으므로 중복 호출·청구가 전혀 없었다고 보증할 수 없다. 재시도 21개 영수증의 토큰은 추가 사용량으로 보고하되 불필요한 비용으로 단정하지 않는다.
- **PARTIAL — 재시도 정책:** 큐 재전달 3회와 명시적 재시도 무상한은 별개다. 품질 거절 후 연속 재시도 제한·운영 경고 정책, DLQ 처리 및 불확정 요청 대조 절차가 후속 과제다. 중복 방지 때문에 차단된 요청을 무조건 실패 정산하는 정책은 추가하지 않았다.
- **NOT TESTED — 실제 장애 주입/복구:** 실학생 재실행, 실제 Provider timeout/429, 결제·환불, 실운영 프로세스 강제 재시작은 수행하지 않았다. 합성 오류 주입과 격리 로컬 DB 검증을 실제 운영 E2E와 구분한다.

실제 요청 재진행·삭제·보관·이용권 변경/환불은 별도 Owner 승인 대상이다. 코드 진단 개선 배포에는 DB migration이 필요하지 않다. Toss LIVE 및 Finance 자동 갱신을 유지한다.

소스 최소 패치 커밋: `9bffbc0` (Worker Python 4개 파일과 오류 주입 테스트). 운영 후보는 현재 배포 5095226c의 75개 모듈을 기준으로 기존 3개 변경 + 신규 진단 모듈 1개만 적용한 76개 모듈이다. 소스 HEAD의 다른 모듈로 전체 교체하지 않는다.

### 검증 범위

- 기존 소스 합성 테스트: 131개 중 129 PASS, 2 SKIP(비공개 C1 fixture 부재).
- 실제 배포 5095226c 다운로드 런타임: 93/93 PASS. 동기/비동기 비교의 실제 monotonic 2ms 차이를 고정 clock으로 제거한 테스트 harness 조정은 근거 파일에 명시했다.
- 최소 변경 운영 후보: 111/111 PASS(실제 다운로드 코드 기준). 오류 기록 저장 실패 뒤 재시작 시 재호출·정산을 막는 회귀 테스트를 저장소에 추가했고, 소스의 집중 테스트 18/18도 통과했다.
- HTTP 429/500/503/timeout 합성 주입: 각 transport 1회, 429는 failed, 나머지는 reconciling, 결과 저장/정산 0.
- timeout 이후 오류 receipt DB 저장 실패 + 재시작: 기존 pending 보존, 새 Provider 호출/정산 0.
- 격리 PostgreSQL 17: 18/18 PASS. 동시 요청·중복 재시도·완료 중복 정산·부분 결과·저장 실패 rollback·정산 응답 유실 재생 검증. 운영 DB 전체를 복제한 검증이 아님을 명시한다.
- 원본 DB 읽기 및 보존 대조: [배포 전후 해시 영수증](evidence/essay-stability-20261122-preservation.json). 기존 9개 요청·checkpoint 242·원장 14·핵심 RPC 15개의 건수/해시를 고정 대상으로 비교한다.
- 실제 Provider 호출/실학생 장애 주입/결제·환불: 0회, NOT TESTED. 장시간 경과는 합성 시간·실제 만료 상태 읽기로 확인했으며 운영 프로세스 강제 종료 테스트는 하지 않았다.

## 요청 항목별 보고

| 항목 | 상태 | 결과 |
|---|---|---|
| 재시도 12회 상세 분류 | DONE | 독립 검토 미승인 8 / EXACT_QUOTE 4, 사건별 표 참조 |
| 재시도 발생 요청 수 | DONE | 6개, 모두 최종 완료 |
| 요청별 처리 시간 | DONE | 9행 표; 완료 평균 535.195초, 최장 2666.250초는 사용자 재시도 대기 포함 |
| 현재 처리 중 요청 상태 | DONE / 복구 PARTIAL | 03629605, q0 완료·q1 reconciling, lease 만료·현재 관리자 재진행 차단 |
| Provider 오류 현황 | PARTIAL | NETWORK_UNKNOWN 1; timeout/네트워크/응답읽기 과거 세부 원인 확인 불가 |
| Worker 오류 현황 | PARTIAL | 과거 재시작/CPU 제한 로그 미확보. 이번 API 집계에서 checkpoint/finish 비200 미관측 |
| 중복 AI 호출 | PARTIAL | 저장 자료에서 동시 중복 실행 증거 없음. 실제 전체 호출 이력 미확보 |
| 추가 비용 | PARTIAL | 재시도 영수증 21, input388101/output65711; 금액 UNKNOWN, 낭비로 단정 불가 |
| 결과 저장 정합성 | DONE | 완료 8건 모두 문항 ID 일치·final 각1 |
| 이용권 원장 정합성 | DONE | 일반7건 각1reserve/consume, 무료2건 원장0, 중복차감0 |
| 개선 필요 | DONE | bounded 진단·관리자 안내 패치; 명시 재시도 cap/DLQ/불확정 복구는 후속 정책 |
| 수정·배포 | DONE | Worker bdee88d0·WEB c5348617 운영 반영, 실제 관리자3화면 및 설정 확인 |
| Git | DONE | APP 코드9bffbc0 및 추가 회귀/보고 커밋, WEB d6d0107 Push; 최종 HEAD는 인계 응답 참조 |
| Wiki | DONE | 본 문서·index/current-status/log 및 DB/log/test/preservation 근거 |

### 원복 범위

Worker는 배포 직전의 `5095226c-82b8-4b64-bf14-9d3f16c4fbcf` 버전으로 트래픽을 되돌리는 방식이다. Pages는 직전 `842dccfe-570c-458a-a23e-a0c5220bb766` 배포가 원복 기준이다. 신규 DB 스키마나 데이터 변경이 없으므로 SQL rollback/원장 보정은 하지 않는다. 새 오류 진단 기록이 생성된 경우 원복 전에 해당 checkpoint의 읽기 호환성을 별도로 확인한다. 이번 작업에서 기존 checkpoint를 수정하지 않는다. 원복 실행 필요 여부는 배포 후 검증으로 판단한다.

WEB 소스 `d6d0107` 커밋·Push, 관련 15/15 테스트·lint/typecheck·171경로 production build PASS. 이후 기존 Functions 원본 회수 불가를 확인하여 아래의 소스·재빌드 검증으로 배포 기준을 확인했다.

## 운영 적용 및 사후 확인

### Worker — DONE

2026-11-22 15:26:15 KST: version `bdee88d0-d23f-4e92-abef-3c009c92efb8` 100%, deployment `6a4966b6-e5d1-4df8-ad26-ba2c7623c3b2`. 76개 배포 모듈이 검증 후보의 exact hash와 일치한다. 기존 72개 보존, 3개 변경, 1개 신규. binding/limit/compatibility 설정은 같으며 배포 설명문만 변경됐다. 운영 기능을 호출해 학생 작업을 시작하지 않았다.

15:27:22 KST 동일 READ ONLY SQL 재실행: 기존 요청9개 전체행/snapshot/답안/결과, checkpoint242개, retry 이력, ledger14개, billing/hidden, 핵심 RPC15개 정의·ACL hash가 모두 같음(`differences=[]`). 이는 Worker 배포 후 확인이며 WEB 배포 후 확인은 별도 기록한다.

### WEB Functions 재빌드 검증 경계

UI 관련 소스만 수정했으나 이전 Functions binary `a753222551b0ce9a46e98733d002077bdfbff3311c462fc5e5508ec26cb55413` 원본은 임시 파일 정리·managed Pages 다운로드404로 회수하지 못했다. 제한한 로컬 캐시 후보81개에서도 찾지 못했으며 권한 확대나 비밀 조회를 하지 않았다.

최초 서버 배포 source `1f345807`와 현재 Functions 번들에 포함된 모든 저장소 입력은 byte동일이다. dependency/환경 불변 확인, Wrangler4.163.0 동일 입력 재빌드2회 비교에서 차이는 `// ../.wrangler/tmp/pages-<random>/functionsRoutes-<random>.mjs` 주석1줄뿐이다. 주석 제외 SHA는 동일(`3f7ec334da20fb236b5ba7dd572533c3fb9f72d38f877f15b72d1bafea9a3a96`). 따라서 원본 binary 동일성이 검증됐다고 주장하지 않으며, 소스·환경 불변 및 회귀 검증을 근거로 재컴파일 배포를 진행한다. 기존 Pages842dccfe가 원복 기준이며 결제·Finance 설정은 변경하지 않는다.

### WEB 첫 적용·권한·데이터 확인

Pages `6e153e0f-0e52-43b2-abac-a039f284d84f`, source `d6d0107e3fc4b3f64bcc19a0f18c044827eb628d`, 15:30 KST 관리자 실제 확인. /admin 및 /admin/essay-runs를 먼저 반영했다. 공유 컴포넌트를 사용하는 /admin/lab-dashboard 경로가 이전 청크를 참조하는 것을 최종 검토에서 발견하여, 검증된 같은 build와 Functions9361…를 재사용해 해당 경로도 반영한다. 이 후속은 소스·서버 로직 변경이 아니다.

관련 WEB15/15, Finance/결제/인증 회귀226/226, lint/typecheck/build171경로 PASS. 운영 무인증 관리자 API401, 잘못된Origin403, 무인증 Finance 상태401, 결제 runtime LIVE200 확인. 실제 결제/환불·Finance갱신을 호출하지 않았다. 기존 Owner 세션으로 관리자 화면 조회만 수행했고 정상 회원 별도 브라우저 세션 검증은 NOT TESTED다.

실제 화면(15:30 KST): KPI 요청9/완료8/실패0/재시도12, 활성1/재시도대기0/보관1 유지. 03629605의 응답 확인 필요 문구·만료잠금·예약0·원장0 및 재진행/삭제/보관 disabled를 확인했다. 상태조회 외 실제 운영 action은 0회다. Toss LIVE, Finance Automatic=true, Functions routing/bindings/settings를 유지했다.

15:31:55 KST 최초 baseline과 동일한 보존 쿼리 결과 PASS: 요청9/checkpoint242/ledger14/RPC15 및 관련 기존 데이터의 건수·해시 전부 동일. [통합 배포·실제 UI·설정 근거](evidence/essay-stability-20261122-web-worker-release.json). 이 DB 영수증은 첫 WEB 배포까지이며 마지막 화면 경로 추가는 별도 UI 범위로 기록한다.

### WEB 최종 3개 경로 적용 — DONE

15:33 KST 최종 canonical Pages `c5348617-8676-45c0-92d6-4efdf9bafd42`. /admin, /admin/essay-runs, /admin/lab-dashboard 모두 반영했다. 첫 배포에서 사용한 Functions SHA9361…를 byte그대로 재사용하고 LAB 대시보드 페이지5파일만 추가했다. 최초 baseline842dccfe 대비 페이지15파일 교체·신규asset4개, 기존3125경로 보존이다. 두 번의 배포는 동일 소스 d6d0107이며 추가 서버 변경이 아니다.

실제 LAB 대시보드의 기간 지표9/8/0/12와 활성1/재시도대기0/보관1, 새 안내 문구를 확인했다. LIVE/Automatic 설정과 무인증 경계·Functions routing/bindings도 재확인 PASS. 실제 요청 action은0이다. 마지막 화면 경로 추가는 기존 동일 Functions를 재사용한 UI 배포이며 DB 해시 영수증의 최종 관측 시각은15:31:55로 구분한다.

최종 판정은 **PARTIAL**: 원인 분류·결과/원장 검사·최소 진단/UI 패치·운영 적용은 DONE이나, 03629605 응답 불확정 요청 복구와 과거 정확한 호출/청구 확인은 남아 있다. 해당 요청을 재진행하지 않았으므로 활성 KPI1은 유지된다. 명시 재시도 상한·불확정 복구 절차와 실제 재진행/이용권 변경은 별도 검토 및 Owner 승인 대상이다.
