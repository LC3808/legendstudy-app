# 건국 Worker 장애 — 2026-10-28

## 현재 결론과 승인 경계

**Owner 승인 범위 Production 배포 완료 / 기존 run 복구 미실행.**
최신 배포·사후검증은 아래 [Production 적용](#production-적용--owner-승인-2026-10-28)을 따른다. 이전 조사·승인 대기 기록은 시점별 근거다.
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
