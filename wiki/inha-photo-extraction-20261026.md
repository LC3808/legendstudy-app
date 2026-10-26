# 인하대 자연 오전 다중 사진 추출 복구 — 2026-10-26

대상: 인하2026수시 자연 오전 Q1·Q2·Q3. [인하 STANDBY](inha-standby-20261026.md)·[기존 사진 입력 계약](hanyang-mixed-incident-20261026.md)·[WEB UI](essay-web-studio-ui-20261026.md)를 유지한다.

## 확인한 원인과 수정

운영 Postgres 로그09:18~09:32 UTC의 실패5건 모두 `math_extraction_regions_run_id_reading_order_key` 중복 오류. 여러 사진의 Provider 출력이 각 사진마다 reading_order를1부터 시작했으나 저장 계약은 문항 추출 run 전체에서 순번이 유일해야 한다. 사진 업로드/Worker claim은 성공했고 finalize가 롤백되어 PROCESSING이 남았다. 인증이나 이미지 접근 실패로 추정하여 Secret을 변경하지 않았다.

WEB Pages extraction adapter에 `orderExtractionRegions` 추가: 기존 claim evidence의 학생 사진 순서 → page → 사진 내 순번으로 정렬하고 전체 순번1..N을 부여한다. 텍스트/수식/좌표/학생 확인 여부는 수정하지 않는다. 다른 문항 artifact ID는 거절한다. 기존 DB 제약과 Worker 평가 엔진은 유지한다.

WEB 다시 추출은 새 attempt를 만들지 않고 동일 fingerprint·attempt ID를 재사용한다. 서버 claim의 기존 lease 만료/진행중 차단을 사용한다. 이미 완료된 추출은 읽기만 하며 PRESENT 사진을 중복 업로드하지 않는다. 재진입 시 기존 결과를 읽고, 사용자 확인은 자동 수행하지 않는다. 사진별 조작 간소화·촬영/첨부/추출 색상 버튼·History 노란 버튼 적용.

## 보존 검토

1. 기존 생성시각/요청ID 유지, 재개는 기존 서버의 새 추출 세대 기록.
2. 원본 사진·순서·학생 초안 보존.
3. 기존 성공 추출/평가/History UPDATE 없음.
4. 기존 인증 사용자 소유권·leaf 공개승인 유지.
5. 사진 인식은 입력 준비이며 평가/성장 결과로 기록하지 않음.
6. 동일 기존 추출 Provider 경로만 사용, 학생 본문/사진/Secret을 Wiki·로그에 저장하지 않음.
7. 후보 결과는 학생 확인 전 확정 답안으로 승격하지 않음.

## 배포·검사

WEB `3e2e0e46f26ed9225c63934a538c563012aca609`, remote 일치. Pages `00f8c3a8-b101-42d1-a112-bc74396da892` Production success/API 확인. typecheck/build PASS, 관련 검사18 PASS(후속 변경16 PASS), lint 오류0/기존 effect 경고2. Provider 유료 평가/첨삭 submit0. DB DDL/직접 DML·Secret·APP 변경0.

## 복구

직전 WEB86282c7 / Pages e8def797-e14c-40f0-ad05-d50017f8fc7f. 구버전으로 복귀하면 다중 사진 순번 오류가 재발하므로 긴급 복구 시 해당 추출 경로의 제한을 알린다. 학생 사진·attempt·추출세대·History를 삭제하지 않는다. 적용/재실행할 SQL 없음. 기존 인하 STANDBY SQL 재실행 금지.

## 운영 확인

운영 일반계정에서 기존 Q1 4장/Q2 2장/Q3 2장(총8장) 복원. 수정 배포 후 기존 attempt3개를 재사용해 추출3건 COMPLETED. 영역 수 Q1=25/Q2=23/Q3=16이며 각 문항 unique reading_order 수와 일치. 원본 artifact 개수4/2/2 그대로, 평가0, CONFIRMED0. 유료 평가/예약/차감0, UI Credit7→7.

WEB에서 세 문항의 추출 내용 편집 영역과 활성 ‘이 내용으로 확인’ 버튼3개를 확인. PC1413px 가로 넘침0, 촬영 네이비/첨부 파란색/흰글씨 확인. 모바일 실제 화면 확인은 아직 미완료. 다중사진 조작 회귀3검사 추가 PASS.

이번 추출 Provider 요청은4회: 수정 전 기존 입력 확인 중 아직 미접수였던 Q3 1회(동일 순번 오류), 수정 후 기존 attempt 재개3회 성공. 유료 첨삭 Provider 호출0. 추출 token usage/정확한 비용은 확보되지 않아 미확정이며 0원으로 보고하지 않는다.

## Owner 확인 후 읽기 전용 확인

Owner가 세 문항 확인 완료를 회신했다. 운영 DB에서 동일 attempt3개 각각 CONFIRMED1, 원본 사진4/2/2장 보존을 확인했다. WEB 세 문항 모두 ‘첨삭 요청 준비 완료’/‘답안 준비 완료’ 표시.

후속 화면 확인 시 이미 전체3문항 요청 `fe6a3c4b-2f91-41cc-9e0b-d9490bd34dd1`이 2026-10-26 09:41:47 UTC에 접수돼 있었다. 이번 후속 작업에서 agent는 제출·재추출·재처리를 누르지 않았다. 요청 reserved, billing reserved, credits_required1, Ledger reserve1/balance_delta0이며 사용 확정은 아직 없다. q0/q1 checkpoint와 q2 pending을 확인했으며 평가 완료로 보고하지 않는다. 현재 요청 버튼 비활성화는 사진 미확인이 아니라 기존 요청 진행 상태에 따른 것이다.

기존 요청을 보존하고 중복 확인창/신규 요청을 만들지 않았다. 1Credit 안내창의 직접 UI 확인과 모바일 화면 확인은 미수행이며, 서버의 실제3문항 접수·1Credit 예약을 별도 증거로 기록한다. 위 유료평가0/Credit7은 복구 작업 당시 기준이다. 이미 접수된 요청의 평가 비용·최종 정산·History 완료는 아직 미확정이다. 다음에는 동일 요청의 완료 상태만 확인하고 신규 제출하지 않는다.

## 2026-10-26 — Math 실패 후속 조사 (미복구)

기존 요청fe6a3c4b… READ-ONLY 재확인: state/billing_status=reserved, completed_at=null, lease 만료. q0 completed, q1/q2 및 각각retry1·2 failed. 성공 결과와 최초1Credit 예약은 유지되며 이번 작업은 신규 요청·재처리·정산을 실행하지 않았다. 기존 실패 checkpoint output=null이라 과거 생성 결과를 다시 검증할 수 없다.

WEB functions/api/essay/math-session.ts는 Provider 응답 이후 evaluateExamMath의 validateMathEval 또는 physicalFinalize 거절을 모두 INVALID_MATH_OUTPUT으로 축약한다. 따라서 확정 범위는 ‘Provider 응답 이후 출력 계약 검증 거절’이며 구체적 기준/수식/근거 오류라고 단정하지 않는다. context.extraction=[] 전달도 확인했으나 실제 실패 원인이라는 증거는 없어 수정하지 않았다.

최소 진단 보완: exam-bridge에서 구조/domain/physical 실패 단계와 고정 검증 코드만 console.warn에 남긴다. 원문 오류message/학생답안/공식자료/ID/Secret은 기록하지 않는다. 기존 검증 거절·정산·인문경로 불변, 실패 결과를 강제 통과시키지 않는다. WEB f45e40b, 관련1검사·Typecheck·ESLint·Production Build PASS. 다음 기존 실패문항 재처리 시 안전한 로그를 수집해 정확한 거절코드에 해당하는 최소 수정만 수행한다. 기존 성공q0 재평가 금지, 추가 예약/차감 금지. 복구 완료로 보고하지 않는다.

보존 검토: 원본시각/ID·사진·초안·성공checkpoint 유지, DB UPDATE/신규 수집 없음, 기존 owner/Worker 인증범위 불변, 진단코드를 학습성과로 기록하지 않음, 원문 개인정보를 로그로 추가 전송하지 않음. 고려대 Owner정정과 무관한 Math 진단만 다루며 고려 엔진/프롬프트/기준/Registry 변경0. 롤백은 WEB7b5a7c4 / Pagesf6e70e92-7296-47f9-a26b-b054ba01afdb, DB SQL 없음.

진단 보완 Production Pages ca6a181e-a7b1-4fab-a759-75629cae3ac2 success, WEB f45e40ba73738302db72475ec19d51eb4e80b74f 원격 일치 확인. 새 Provider 호출0.


## 2026-10-26 21:19 KST — 기존 Math 회차 운영 복구

Owner의 출력 계약 복구 지시로 기존 실패 문항만 재처리했다. **회차 복구 완료, 과거 출력 거절의 상세 원인은 미확정**이다. 원인 수정·재발 방지까지 완료한 것으로 표현하지 않는다.

- 기존 run `fe6a3c4b-2f91-41cc-9e0b-d9490bd34dd1`, exam `3e2526ee-14af-5c47-a5fc-76b70cc5bf8c` 그대로 사용.
- 시작 상태: reserved, Q1 completed, Q2/Q3 failed; 원래 예약 1건 유지. WEB의 기존 `다시 시도 · 0 크레딧`을 한 번 실행하여 retry generation3 생성.
- Q1 checkpoint MD5 `b6e086318254c3fa29cf4e98fda74a11` 전후 동일. Q1 재평가 0. 과거 실패 checkpoint와 학생 입력/확인 결과를 수정하지 않았다.
- Q2 `q1-retry-3`, Q3 `q2-retry-3` 모두 completed, reviewed/usage checkpoint 추가. 전체 run completed `2026-10-26T12:18:56.164417Z`, 결과3문항 저장.
- billing settled. 해당 decision Ledger: reserve1건(09:41:47Z, reserved +1), consume1건(12:18:56Z, balance -1/reserved -1). 새 예약0, 중복 consume0, 신규 유료 회차0. 브라우저 가용 Credit4 유지.
- 실제 일반계정 WEB: 진행 화면에서 결과 전용 화면으로 전환, 문항별 결과3개 표시. 나의 첨삭 기록에서도 동일 run의 인하2026수시 자연오전 `완료` 링크 확인. 무료 재첨삭 사용 가능 표시만 확인했으며 재첨삭은 실행하지 않았다.

### 출력 계약 조사 결과와 한계

실제 회차 경로는 `functions/api/essay/math-session.ts` → `evaluateExamMath` → `validateMathEval` → `physicalFinalize` → parent checkpoint/`essay_exam_finish`다. standalone `worker-client.ts`의 INVALID_OUTPUT / math_evaluation.fail과 구분한다. Claude 분석 브랜치의 Provider 미연결 전제는 현재 운영 회차 코드와 다르며 병합하지 않았다. MATH-2C/2D 정의는 읽었으며 재실행하지 않았다.

기존 오류 INVALID_MATH_OUTPUT는 candidate JSON 파싱 이후 validation/physical 거절 경계다. 과거 실패 candidate가 저장되지 않았고 상세 조건 로그도 없어 정확한 필드는 복원할 수 없다. 이번에는 배포된 안전 진단을 tail하면서 재처리했으나 Q2/Q3 모두 HTTP200 성공하여 실패 코드가 발생하지 않았다. 따라서 UNGROUNDED_STEP_REGION, dimension 누락, 동치 불확실 등 어느 조건도 실제 원인으로 확정하지 않는다. 조건을 제거하거나 prompt/정규화를 추측 변경하지 않았다. 새로운 성공 결과를 다시 호출해 오류를 재현하지 않는다.

기존 진단 WEB f45e40b는 structure/domain/physical 및 bounded code만 기록한다. 학생 원문/토큰/후보 JSON은 Wiki에 저장하지 않는다. 재발 시 이 진단으로 조건을 먼저 확보하고 정확한 조건만 수정한다. 현재 physical 진단은 PHYSICAL_CONTRACT_REJECTED까지이며 세부 조건 분해는 후속 필요 시 수행한다.

### 호출·검사·운영

| 대상 | Provider 입력/출력 토큰 | 처리 시간 | 결과 |
|---|---|---|---|
| Q2 | 9,408 / 5,136 | 56,045ms | completed |
| Q3 | 9,116 / 3,258 | 36,607ms | completed |

총2호출, 입력18,524/출력8,394(총26,918) tokens. model gpt-5.6-sol. cost_amount NULL이므로 비용 확정 불가이며 0원으로 보고하지 않는다.

기존 테스트: WEB Math validation/physical/worker failure/exam bridge/exam endpoint 67 PASS, Python mixed checkpoint/session retry7 PASS. 완료 문항 재사용·실패만 재처리·불명 상태 재호출 금지·정산 중복 방지 경로를 확인했다. Node24 환경은 repo engine22와 다르지만 테스트 통과; 코드/Build 변경은 이번에 없음.

Production READ-ONLY 대조: WEB `5da2d0eee950afc917ec190f2979f40ab7d608fe`, Pages `d8c01203-bd66-49a1-9ad2-ba54e20d117a` production/success. queue Worker version `e85c587b-46fe-4abd-b871-3c84eb4305d7` 100%. 이번 새 코드/배포/DDL/직접 운영 쓰기 SQL/Secret 변경0. 기존 UI 재처리 RPC와 정상 최종 정산만 실행했다.

롤백 대상 신규 배포 없음. 현재 성공 회차의 결과·Ledger를 되돌리지 않는다. 재처리SQL·이전 migration을 재실행하지 않는다. 기존 배포 복구가 필요하면 위 정상 Pages/Worker 버전을 기준으로 하고 Secret을 덮어쓰지 않는다.

기존 인문·상경 경로 코드 변경0. 다른 대학 재평가0. 원본 이미지 병행 평가·수식 렌더링·SymPy는 [기술 검토](math-technical-review-20261026.md)의 후속 과제로 유지한다. 이번 성공은 모든 자연계 시험 또는 모든 출력 형식의 안정성을 보증하지 않는다. 엄격한 Owner 완료 기준 중 ‘과거 실제 실패 조건 식별 및 수정’은 미완료이므로 전 항목 E2E PASS로 일괄 판정하지 않는다.
