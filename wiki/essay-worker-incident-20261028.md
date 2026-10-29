# 건국 Worker 장애 — 2026-10-28

10/29 한국외대/건국2023 반복 실패는 아래의 2024 입력 길이 장애와 별개다. [두 run 최종완료·출력 검증 거절·각1Credit 정산 근거](app-owner-fixes-20261029.md#실제-실패-원인--운영-select-확인). Worker 변경/재실행 없음.

## 현재 결론과 승인 경계

**Production 배포 완료 / 기존 중단 run failed 종료·1 Credit 예약 해제 완료.**
최신 결과는 [중단 run 종료 및 예약 해제](#중단-run-종료-및-예약-해제--2026-10-28)를 따른다.
배포·사후검증은 아래 [Production 적용](#production-적용--owner-승인-2026-10-28)을 따른다. 이전 조사·승인 대기 기록은 시점별 근거다.
Owner 지시의 A단계만 수행. APP UI는 Claude 담당이며 통합·빌드·스토어 제출은
Claude 완료/Commit·Push/테스트/Owner 실기기 승인/Worker 결과 확인 및 별도 Owner 승인 후다.
운영 배포, 기존 run 재실행·상태 변경·예약 해제·환불, 실제 Provider/Credit E2E는 각각 승인 전 금지.

기존 [공유 Gateway/회차 정책](phase3-service-20261022.md),
[전체 대학 STANDBY](essay-batch-service-20261023.md#2026-10-25--전체-대학-standby-공통-정책),
[베타 Credit](essay-beta-credit-design-20261027.md),
[최신 Worker 배포 근거](essay-kwangwoon-standby-20261027.md)를 유지한다.
본 지시는 새 평가 패키지/정산 정책/APP UX 재설계 승인이 아니다.

## 확인한 운영 사실

프로젝트 `stlhijzpjfgwwdgunlsd`, 읽기 전용 SELECT와 Cloudflare GET만 사용.
작업 시작 branch `codex/material-service-app-20261022`, HEAD `733bad70ed93de32b51739894044c11e983cd667`.
기존 미커밋 APP/설정/테스트 파일 및 untracked 파일은 보존했다.

|항목|건국 장애 대상|서강 비교 대상|
|---|---|---|
|run|`2998c8ba-9226-4dea-8bd0-ca34daa3744d`|`f1858409-90e2-43f4-a0b2-7165bdff18cc`|
|시험|2024 수시 인문사회Ⅰ|2024 모의 인문사회 1차|
|생성 KST|10/28 14:18:23.838682|10/28 14:43:23.471838|
|완료 KST|없음|10/28 14:44:27.941032|
|state|reserved|completed|
|문항/checkpoint|2 / 0|1 / 8|

서강 완료 기록의 APP/WEB 출처는 확인하지 못했으며 플랫폼으로 단정하지 않는다.
회차는 `essay_exam_private.runs`와 `checkpoints`에 저장된다. 별도의
`essay_exam_runs.requested` 또는 legacy `essay_evaluations` 행을 이 회차 상태로 해석하지 않는다.

건국 billing decision도 reserved, credits_required=1. 원장은 reserve 한 건
(balance_delta=0, reserved_delta=1)뿐이며 consume/release/refund 없음. result=NULL.
상태 RPC의 실제 정의상 두 문항 모두 waiting으로 보이는 것이 맞다.

dispatch key `47b2503d-094d-57d4-9899-e83a6a5486d9`.
lease_until=10/28 14:33:27.522615 KST. 운영 claim 함수가 최초 lease를
clock_timestamp()+15분으로 생성하므로 claim 시각은 14:18:27.522615 KST로 **계산**된다.
이는 별도의 claim 로그 timestamp가 아니다. dispatch key 역시 Cloudflare invocation ID가 아니다.

운영 Worker `202f8f62-83ad-4ae8-9cc7-b4a576226e3b` 100%, 10/27 05:34:21 UTC 배포.
설정 CPU 제한 30000ms. Cloudflare 화면에서 Workers Logs/Traces Disabled 확인.
보관 로그 API는 OAuth 권한 부족403; 로그/추적 활성화나 권한 확대를 하지 않았다.
따라서 당시 invocation ID·예외 로그·CPU/wall timeout·Provider 영수증은 미확인이다.
계정 전체 로그나 DLQ 메시지 소비·ACK·재전송은 수행하지 않았다.

## 원인 재현

1. 해당 run의 고정 package digest는
   `5bdfb87766b2d44b1d4b02ec85b524d0804cc5e6c3331cbf143180309328c2ab`, version/revision2.
   현재 운영 package도 같은 digest, APPROVED 문항2개로 일치한다.
2. 배포된 Worker를 읽어 `entry.py`, `cloudflare_runtime.py`, `material_runtime.py`,
   `async_exam.py`, `live_worker.py`, `reviewed_runtime.py`, `package_registry.py`가
   수정 전 로컬 코드와 byte-identical임을 확인했다. 배포 Registry도 그대로 사용했다.
3. 두 문항의 criteria label은 각각 4576자. 공식 scoring_criteria evidence와 동일 원문이다.
   `load_reviewed_material`은 ready=true이나 `prepare_claimed_material`에서
   `live_worker.package` → `text(criteria.label)` 기본 최대4000을 초과해 `Invalid: TEXT` 발생.
4. 실제 운영 package/배포 Registry + **로컬 합성 답안**으로 두 문항 입력 조립을 재현했다.
   학생 원문은 다운로드/출력하지 않았고 Provider/운영 RPC 실행 없이 순수 함수만 실행했다.
5. 이 검사는 claim 이후, `execute_async_exam` 및 첫 `journal.begin(q0)` 이전이다.
   queue 핸들러는 예외 종류만 출력하고 retry한다. 이 경로는 finish/failure/정산을 실행하지 않아
   reserved가 유지된다. lease 만료나 재배달도 자동 환불/Provider 재호출 권한이 아니다.

**확정 범위:** 동일 배포 코드·고정 패키지에서 반드시 발생하는 입력 검증 오류와
checkpoint 이전 실패 경로를 확인했다. 과거 실행의 유일한 오류였다는 로그 증명은 없다.
이 코드 경로는 Provider 이전에 실패하며 실제 checkpoint도0이다. Provider가 호출됐다는
증거는 없지만 과거 Provider 감사 로그까지 대조한 '호출0 확정'으로 보고하지 않는다.
100초 APP 폴링 문제는 별도이며 이 서버 미완료를 해결하지 않는다.

## 최소 코드 수정과 검증

[live_worker.py](../tool/essay_lab/live_worker.py)의 `package()`에서 **서버의 고정 공식
criteria 입력만** 기존 evidence와 동일한100000자 상한을 적용한다. 원문 자르기/요약,
새 package/ID/digest, prompt/model 변경 없음. 일반 `text()` 기본4000 및 출력 검증은 유지.
Registry·상태 전이·예외/재시도·lease·checkpoint·정산·History 함수는 변경하지 않는다.
범용적인 '모든 예외=실패/환불' 처리는 중복 Provider/모호한 실행 결과 위험 때문에 추가하지 않았다.

- 신규 [회귀검사](../tool/test_essay_long_criteria.py): 수정 전 동일 TEXT 실패 확인,
  수정 후 4000/4001/4576/100000 경계·초과/빈값/타입·binding·출력제한 보존.
  2문항 고정 입력, Mock 평가 완료·checkpoint·큐 continuation·재배달 중복호출 없음 검사.
- 기존 단문/다문항, 성공/실패/timeout, 권한·고정입력, mixed Math, 재시도·lost-finalization,
  큐 send-before-ACK, staging 포함 **65 tests PASS**.
- 격리 PostgreSQL17 기존 canonical Ledger 후보 **18 checks PASS**:
  1/2/4문항1Credit, 무료재0, 8동시 요청1예약, 부분결과 정산 금지, 실패해제 멱등,
  원장이력 불변, 응답유실 재정산 중복 방지. 운영 DB에 테스트하지 않았다.
  첫 실행은 PYTHONPATH 누락으로 중단됐고 임시DB 종료 후 올바른 환경으로 전체 재실행 통과했다.
- 실제 운영 package 두 문항의 수정 후 조립 PASS(4576/4576 원문 그대로).
  실제 Provider·실제 과금 E2E는 미실행. Production 정상화 완료가 아니다.

재현 명령:
```sh
PYTHONPATH=.:tool python3 -m unittest tool.test_essay_long_criteria.LongCriteriaTests tool.test_essay_long_criteria.LongCriteriaAsyncTests tool.test_essay_live_worker tool.test_essay_reviewed_runtime tool.test_essay_async_runtime tool.test_essay_material_execution tool.test_essay_session_retry tool.test_essay_queue_continuation tool.test_cloudflare_stage tool.test_mixed_math_checkpoint tool.test_material_runtime
PYTHONPATH=.:tool python3 tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
python3 tool/check_wiki_handoff.py
```

## 기존 run 처리 및 Production 제안

**이번에는 기존 run에 아무 작업도 하지 않았다.** lease가 이미 만료됐고 원래 q0 intent도 없다.
단순 코드 배포는 기존 run을 안전하게 재개시키지 않는다. 새로운 run 생성/강제 lease 갱신,
checkpoint 삭제/생성, 큐 재등록, 예약해제/환불은 모두 별도 Owner 승인 대상이다.
재개/실패해제 중 선택하기 전에 Provider 미호출 근거와 기존 승인된 복구 함수 적용 조건을
확정해야 한다. 이번 조사만으로 환불 또는 재실행 SQL을 승인된 작업으로 취급하지 않는다.

배포 승인 요청 범위는 **이 Worker 입력 검증 수정만**이다. 기존 live version과 모듈/Registry/
prompt/bindings/Secret/공개목록/큐 설정을 재대조한 뒤 live_worker.py만 교체한 버전을 배포한다.
현재 로컬 기본 Registry로 전체 재생성·덮어쓰기 금지. 기존 run enqueue/실제 평가 E2E는 제외.
운영 로그 활성화는 별도 설정 변경으로 이번 승인 범위에 묶지 않는다.

배포 직전 다른 변경이 없다면 rollback 기준은 `202f8f62-83ad-4ae8-9cc7-b4a576226e3b`.
새로운 진행 요청/후속 배포를 확인하고 Worker만 원복한다. DB/원장/History는 rollback하지 않는다.
현재 수정은 로컬 후보이므로 운영 rollback은 아직 불필요하다.

## 보존 검토 7항목 및 후속 APP

1. 기존 제출/평가 발생 시각과 이번 진단 시각을 구분하고 새 학습 기록을 만들지 않는다.
2. 기존 snapshot·package version/digest·배포본을 근거로 재현, 원문/기준을 보존한다.
3. 운영 UPDATE/DELETE 없음. 현재 reserved를 성공/실패로 덮어쓰지 않는다.
4. 기존 account/run/parent identity 유지, 플랫폼별 계정/이력 복제 없음.
5. 학습 처리 장애이며 학생 역량/입시 결과를 새로 추정하지 않는다.
6. 학생 답안/Secret/Provider payload를 문서·테스트에 넣지 않는다. 합성 답안으로 검사한다.
7. claim 시각은 함수에서 계산한 값, Provider 미호출은 코드 경로 근거와 감사로그 미확인을 구분한다.

2026-10-27 실기기 검수는 로컬 Wiki에서 이번 장애와 연결되는 완료 증거를 찾지 못했다.
기존 문서는 APP 개발검증/실기기 미확인을 구분한다. Claude worktree의 10/28 기록은
UI 변경/1136테스트 및 실기기 승인 대기/미병합으로 기록돼 있다. 이 기록을
Owner 검수 완료나 통합 승인으로 대체하지 않았다. APP 코드·Claude 브랜치 변경0.

관련 10/28 선행 읽기 전용 진단의 핵심 증거와 한계는 위 운영 표와 원인 절에 보존했다.


## Production 적용 — Owner 승인 2026-10-28

Owner가 입력 검증 수정·Commit/Push·Worker 배포·사후 확인을 명시 승인했다.
기존 run 재실행, 신규 요청, 실제 Provider, Credit/DB/History 변경, APP/Claude 통합은 금지 유지.

- 적용 시각: **2026-10-28 16:26:19 KST**.
- Production version: `451b8cae-f603-48e9-9ca9-8ccc16b4e3d4` **100%**.
- Deployment: `775f74de-8d13-496e-905c-2e0ee21333be`.
- 수정 코드 Commit/Remote: `e934240e15584178993bcbd25cbc891859076d76` Push 완료.
  후속 배포 기록 커밋은 문서/검증 기록만 포함하며 Worker 코드는 동일하다.
- [비밀값 없는 배포 검증 기록](../tool/cloudflare_essay/criteria-input-deployment-20261028.json).

### 배포 범위 및 검증

직전 active version `202f8f62`와 설정을 재조회하고 배포된72파일을 Content v2로
다운로드해 원래 MIME/SDK/Registry/프롬프트를 보존했다. `essay_lab/live_worker.py`만
승인된 commit의 bytes로 교체했다. 새 버전 업로드 시 Secret5개는 기존 binding 상속,
나머지 binding은 동일값으로 유지. 버전 업로드 검증 후100% 배포했다.

배포 후 다시 가져온72파일의 이름·MIME·SHA256을 모두 비교: **승인파일1개 변경/71개 동일**.
bindings14개·compatibility date/flags·CPU30000ms·handlers·그 외 설정·workers.dev/preview
설정 동일. Secret 값은 조회/출력/교체하지 않았다. 큐 producer/consumer 설정 변경 요청 없음.
Worker API가 업로드/배포 성공을 반환했고 active deployment/version100%를 독립 재조회했다.

관련65개 회귀검사 재실행 PASS. 앞 단계 격리Credit18 PASS 근거 유지(이번 DB코드변경0).
**배포본을 재다운로드한 코드**에서 기존 공식 package + 합성 답안을 순수 로컬 실행:
두 문항4576자 원문 조립 PASS, 변조 답안 hash 차단 PASS, 출력 길이 제한 차단 PASS.
이는 실제 Provider/운영 평가 E2E가 아니며 호출 없이 검증했다.

배포 전/후 해당 run SELECT 동일: reserved, result=NULL, checkpoint0, billing reserved,
reserve1개(balance_delta0/reserved_delta1). consume/release/refund 없음.
운영 DB쓰기0·신규 평가0·Provider0·기존run 재실행0·APP변경0·Claude병합0.

### 롤백과 남은 작업

이전 version `202f8f62-83ad-4ae8-9cc7-b4a576226e3b` 조회 가능 및 binding/runtime
동일성 확인. 배포검증 문제 없어 실제 rollback은 하지 않았다. 문제 발생 시 후속 변경과
진행 요청을 확인하고 해당 버전100% Worker deployment로 복귀하며 DB/Credit/History는 보존한다.

**기존 건국 run은 복구되지 않았다.** 재개·실패해제·환불 여부는 별도 Owner 승인 후 결정.
APP 통합/빌드/스토어 준비는 별도 승인과 기존 선행조건 충족 전까지 보류한다.


## 기존 run 복구 사전검증 — 2026-10-28

Owner는 기존 run의 안전한 재개를 승인했고, 기존 경로로 재개 불가능하거나 안전성을
확인할 수 없으면 중단 후 실패/예약복구 방안을 제시하도록 지시했다. 해당 중단 조건을
적용했다. 승인 부재로 복구 요청 전체를 거절한 것이 아니라 **운영 retry 계약 미충족**이다.

### 운영 읽기 전용 확인

- 대상 `2998c8ba-9226-4dea-8bd0-ca34daa3744d`: reserved, result=NULL,
  completed_at=NULL, 두 문항, checkpoint0, retry_requests0.
- 원본 snapshot MD5 `46db0a50d62b3e76ba2b5201f5766428` 기록. 학생 답안 원문은
  조회/출력하지 않았으며 snapshot/History 변경 작업 없음.
- claim/lease token 존재. 원래 lease는 2026-10-28 14:33:27.522615 KST 만료.
  billing reserved/credits_required1, 원장 reserve1건(balance_delta0/reserved_delta1).
  consume/release/refund 없음. 추가 예약·차감 없음.
- Cloudflare active deployment 재조회: `775f74de-8d13-496e-905c-2e0ee21333be`,
  Worker `451b8cae-f603-48e9-9ca9-8ccc16b4e3d4` 100% 유지.
- 과거 Provider 호출/과금은 앞선 입력검증 재현상 호출 이전 실패 경로이며 checkpoint0.
  외부 Provider 감사기록으로 과거 호출0을 확정한 것은 아니다. 이번 확인 중 Provider0.

### 기존 경로로 재개할 수 없는 근거

Production 함수 정의를 직접 SELECT해 확인했다.

1. `public.essay_exam_claim`: 이미 있는 동일 dispatch의 lease를 갱신하지 않는다.
   다른 dispatch는 `RECONCILIATION_REQUIRED`로 차단한다.
2. `public.essay_exam_session_checkpoint`: begin 시 원래 lease 또는 retry lease가
   유효해야 한다. 현재 상태로 큐만 재전송하면 `DISPATCH_LEASE_EXPIRED`다.
3. `public.essay_exam_retry`: 모든 문항에 completed/failed checkpoint가 있어야 하며,
   적어도 하나가 failed여야 한다. 대상은 checkpoint0이라
   `RECONCILIATION_REQUIRED` 조건에 해당한다. 실패할 RPC를 실제 호출하지 않았다.
4. 중복 실행 방지는 account/run 행 잠금, 불변 lease token, append-only checkpoint
   key/writer 및 retry request key 멱등성으로 유지된다. 이 조건을 우회하지 않았다.

[10/25 복구 선례](essay-group-1a-20261025.md#2026-10-25-최신--승인된-중단-요청-복구무료-재첨삭-완료)의
`essay_run_recovery_20261025`는 다른 run 전용 SQL 개별승인이며 재사용할 수 없다.
기존 pending 삭제, 가짜 failed checkpoint 생성, lease 직접 연장, 큐 재전송 모두 미실행.
운영 SQL은 SELECT만 사용했다. 새 run/Provider/정산/코드변경/배포 없음.

### 후속 방안과 조회 한계

- **재개 우선안:** 해당 run 전용 사전조건·잠금·변경 감지·중복거절·감사기록을 갖춘
  recovery SQL 후보를 별도로 준비·격리검증한 뒤 개별 승인받아 기존 retry generation
  계약으로 연결하는 방안. 아직 후보 작성·안전성 검증·운영 적용하지 않았다.
  기존 snapshot/예약/원본 lease token을 보존하고 동일 identity만 dispatch해야 한다.
- **실패 종료 대안:** 모든 원래/retry lease 만료와 진행/완료 checkpoint 부재를 잠금
  아래 재확인한 후 기존 `essay_exam_private.finish(run,NULL,true)` 계약을 사용한다.
  이 함수는 run failed/billing released 및 기존 예약의 release 원장으로 처리하며
  추가 지급/환불 거래를 만드는 방식이 아니다. 대상·원장·snapshot 불변 조건과
  재실행 멱등성을 검증한 실행안에 별도 승인을 받아야 한다. 이번에는 미실행.
- 현재 두 문항 평가 결과는 없고 Backend 복구 미완료다. WEB/APP 결과 조회 성공으로
  보고할 수 없다. 화면 실기기 재검증은 하지 않았으며 APP 폴링/복원 문제와 별개다.
  기존 History 저장행은 보존되어 있다.

Unified Wiki만 갱신하고 추가 조사를 종료한다.


## 중단 run 종료 및 예약 해제 — 2026-10-28

Owner가 대상 run 실패 종료와 기존 예약 해제를 명시 승인했다. 기존 계약으로 안전한
경우만 실행하며 Provider/Worker 재실행/새 평가/새 Credit 지급/다른 run 변경은 금지했다.
기존 [예약·실패 처리 정책](phase3-service-20261022.md) 및
[원래 grant로 release하는 계약](essay-beta-credit-design-20261027.md)을 그대로 적용했다.

### 실행 및 검증

- 대상 `2998c8ba-9226-4dea-8bd0-ca34daa3744d`만 기존
  `essay_exam_private.finish(run,NULL,true)` 호출. 직접 UPDATE/DELETE나 새 함수/정책 없음.
- account → run → billing 행 잠금, lock_timeout5초/statement_timeout20초.
  reserved/result NULL/완료시각 NULL, lease 만료2분 초과, snapshot 고정 해시,
  답안2개/checkpoint0/retry0/billing reserved1, reserve 원장 정확1건 조건을 확인했다.
- 처리 후 snapshot 포함 run의 상태·결과·완료시각 외 모든 필드 동일, 기존 reserve 행
  동일, 같은 grant에 release1건(balance_delta0/reserved_delta-1), billing released 확인.
  조건 불일치 시 예외로 전체 rollback하도록 한 트랜잭션으로 실행했다.
- 같은 finish를 한 번 더 호출해 failed 반환/원장2행 유지 확인: 중복 release 없음.
  같은 계정의 다른 run/대상 외 원장/전체 credit_grants 사전·사후 JSON 비교 동일.
  설치 함수는 정확 대상 run/decision만 변경하며 다른 계정 대상으로 쓰는 구문이 없다.
- 실행 전 기존 격리 PostgreSQL 복구 검사 PASS: pre8/post6, 진행 lease 차단,
  기존 checkpoint 보존, 새 예약0, fallback release 멱등. 운영 함수 정의도 직접 대조했다.

### 독립 사후 SELECT 결과

2026-10-28 **16:47:01.938391 KST** release 기록:

|항목|확인 결과|
|---|---|
|run / billing|failed / released|
|원장|reserve1 + release1, consume/refund/신규지급0|
|순차감 / 잔여예약|0 / 0|
|기존 학생 답안|2개 보존, snapshot MD5 `46db0a50d62b3e76ba2b5201f5766428` 동일|
|History|소유자 문맥의 `essay_exam_history(run)` 조회1건, failed, 답안 원본 일치|
|checkpoint|0 유지|
|해제된 원천|유효기간 내·해당시험 사용가능·구매취소중 아님, 원천 가용수량2|
|다른 run/Credit|잠금 트랜잭션 내 같은 계정 비교 동일; 대상 외 변경 없음|

`reserve`는 같은 request_key를 재사용하면 기존 failed run을 반환한다. 재제출은 기존
새 요청 준비 흐름에서 **새 request_key**로 가능하며, 정상 제출 시 기존1Credit 정책을
적용한다. 현재 사용가능한 원천 잔액도 확인했다. 기존 실패 run을 재개하거나 삭제하지
않는다. 실제 새 요청/Provider 호출/예약은 생성하지 않았으며 WEB/APP 실화면 클릭 E2E는
실시하지 않았다. APP의 폴링·재진입 UI 문제는 별도 작업이다.

운영 정리는 완료됐으며 추가 DB/Credit 조치는 필요 없다. History 확인은 실제 로그인
브라우저가 아니라 읽기 전용 트랜잭션에서 대상 소유자 JWT sub 문맥으로 RPC를 조회한
검증이다. 코드/배포/권한/Worker/APP 변경 없음.
