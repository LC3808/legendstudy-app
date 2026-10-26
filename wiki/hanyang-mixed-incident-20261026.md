# 한양대 2027 모의 상경 사진 확인 경로 — 2026-10-26

상태: WEB 사진 입력 복원 수정·Production 반영 확인. 실제 평가/사진 최종 확인은 Owner 대기. [기존 혼합 STANDBY 계약](essay-handoff-20261025-final.md#2026-10-26-최종-추가-작업--standby-82회차), [회차 1Credit 정책](decisions.md#2026-10-24--시험-회차-첨삭-단위-복원)을 유지한다. 이번 Owner 범위는 한양2027모의 상경 한 회차의 연결 오류이며 다른 대학/APP/평가 엔진/DB 변경은 하지 않았다.

## 운영 확인

- 시험 `68996278-1e19-5560-ac94-cf43656bf684`의 전체2문항: Q1 `2b733da1-6c2a-50d8-a32d-83d136636754`는 Essay, Q2 `a32bc8ed-edf9-580e-b2e6-10ddaea4cf1e`는 기존 Math child. 시험 전체를 Math Worker로 바꾼 상태가 아니다.
- 실제 배포 Worker `a99a7cfc-022d-4408-84b5-cc9c44f967dd`의 module을 읽어 `CloudflareExamRuntime`의 문항별 engine 분기와 `MixedMathWorker` 존재를 확인했다. Q2의 Math binding은 이미 공식 패키지에 있으며, 이름에 상경/수리가 있다는 이유로 임의 전환한 것이 아니다. 이 binding을 Essay로 바꾸지 않았다.
- 해당 시험의 Essay 회차0, Math 유료 session0, 해당 Math attempt의 evaluation0. 따라서 이번 장애에서 1Credit 예약·확정은 발생하지 않았다. 취소·예약 해제·재평가 조치는 필요하지 않다.
- 기존 사진 attempt1개와 PRESENT PNG1개, CANDIDATE 추출1개 COMPLETED/error_code없음, CONFIRMED0. 사진 추출 실패가 아니라 학생의 추출 내용 확인 대기다. 민감한 답안 본문/사진/학생 ID는 이 문서에 복사하지 않는다. 원본 ID와 상세 read-only 결과는 로컬 `legendstudy-materials/essay-validation-2026-10/hanyang-mixed-incident-20261026/` 증거에 한정한다.

## 차단 지점과 최소 수정

기존 MixedExamSubmit은 사진 문항만 Math 입력 확인 컴포넌트에 보내고, 최종 유료 제출은 기존 Essay parent에 맡긴다. 사진 없는 수리 텍스트는 기존 Math child 계약에 직접 전달할 수 있다. 사진에는 원본 업로드 → 추출 → 학생 확인 → confirmedRunId 연결이 필요하다. 수식/이미지를 확인 없이 임의 텍스트로 바꾸거나 자동 확인하지 않는다.

재진입 시 브라우저에 attempt ID가 남아 있어도 컴포넌트가 서버의 기존 추출 결과를 자동으로 읽지 않아 ‘사진을 확인하면 제출 가능’ 안내와 비활성 버튼만 표시됐다. ‘저장한 답안 입력 확인’ 클릭으로 기존 추출을 읽었을 때 ‘이 내용으로 확인’이 나타남을 운영에서 확인했다. 이 동작은 새 attempt/Provider 호출 없이 기존 결과만 읽었다.

수정: **해당 exam ID만** `restoreExistingInputs`를 켜서 기존 fingerprint/선택 문항/leaf ID가 일치하는 경우에만 기존 `read_input` 결과를 자동 복원한다. 새 attempt 생성·추출·학생 확인·유료 제출은 자동 실행하지 않는다. 사진 확인 영역 이름도 해당 경로에서 ‘사진 답안 확인’으로 바꿔 시험 전체가 수리 경로로 전환된 것처럼 보이는 표현을 없앴다. 혼합 사진 안내에 ‘이 내용으로 확인’ 다음 단계를 명시했다. 정상 인문 Essay 경로는 수정하지 않았다.

## 결과와 한계

- WEB commit `d861586`, Production `2737bf18-b6f7-453f-b784-48bdd2ae0d04` deploy success를 API로 확인.
- 일반계정 WEB 새로고침 → 2027모의/상경 선택 후 전체2문항과 기존 답안/사진 유지, 기존 사진 추출 내용·‘이 내용으로 확인’ 자동 표시 확인. 저장된 입력 복원 안내 확인.
- 로컬 관련 회귀9검사 PASS: 기존 Math 회차 멱등성 유지, 기존 후보 read-only 복원, 이미 학생 확인된 ID를 Essay parent로 전달, 독립 Math 유료 submit/Provider 호출0. WEB 배포용 build PASS. APP build 없음.
- 현재 실제 입력은 CONFIRMED0이므로 최종 첨삭 버튼은 사진 확인 전까지 차단되는 것이 정상이다. 학생 대신 내용 확인 버튼을 누르지 않았다. Owner에게 실제 사진 내용 확인을 요청했다. **사진 확인 이후 서버1Credit 안내/실제 평가 성공은 아직 미확인**이며 E2E PASS로 보고하지 않는다.
- 이번 작업의 새 평가·Provider/OCR 호출·예약/차감0. 기존 사진 원본/추출/답안·History·Ledger는 변경하지 않았다. DB SQL 쓰기0, Worker 재배포0, 환경변수/Secret 변경0.

## Owner 다음 순서 / 복구

1. 한양2027모의 상경을 다시 선택한다. 기존 추출 내용이 자동 표시된다.
2. 사진과 추출 내용을 대조하고 필요한 부분만 수정한 뒤 ‘이 내용으로 확인’을 누른다.
3. 회차 첨삭 버튼 → 기존 서버1Credit 안내 → Owner가 실제 제출 여부를 결정한다. 사진 확인 자체는0Credit이며 별도 Math 유료 제출을 하지 않는다.
4. 오류가 다시 발생하면 기존 attempt/confirmed/run 상태를 먼저 확인한다. 사진 삭제·입력 다시 준비·새 제출키 생성으로 우회하지 않는다.

복구: WEB `d861586`의 세 파일 변경만 되돌려 재배포하거나 직전 정상 WEB `aedbf200-98f1-46c9-b565-a94bb9d3fddf`로 복귀한다. 현재 공개scope142/Worker a99a7cfc·DB·Secret은 그대로 둔다. 이전 STANDBY SQL은 재실행하지 않는다.

보존 검토7: 기존 발생/기록 시점 유지; 원본 사진·추출 ID 유지; 학생 이력 UPDATE 없음; 동일 인증 소유권 재사용; UI 상태를 새 학습성과로 기록하지 않음; 기존 사용자 소유권 조회만 사용; 후보 추출을 확인된 학생 답안/평가 결과로 승격하지 않음. 신규 storage/스키마 설계 없음.
