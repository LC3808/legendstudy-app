# TASK16 평가 정확도 검증 — 2026-11-04

**전체 PARTIAL / 운영 품질 완료 아님.** [이전 최종 품질](task16-final-quality-20261104.md), [학습 5단계 Owner 정책](learning-completeness-policy-20261104.md)을 계승한다. 이번 Owner 지시의 실제 Provider 호출은 격리 TEST에 한정하며, 운영 DB·Credit·Ledger·History와 심사 중 APP58은 변경하지 않았다.

## 실제 최초 보류 원인

원본 evaluation `4539b56f-63b7-471b-acb7-6bf34cdac25b`, attempt `bcb45621-4485-4667-a16c-c5e9f9250729`를 읽었다. EVIDENCE 입력, typed_answer null, 선택된 확정 전사 `5302f304-3cd1-42e6-b749-5138b64db0ca`, 10영역/원문682자/불확실0이 저장돼 있다. Provider candidate-3는 이를 답안 없음으로 판단해 steps0, NOT_ATTEMPTED, NOT_DETERMINABLE을 반환했고 구조 검증 후 COMPLETED로 저장됐다. 처리 완료는 평가 정확성의 증거가 아니었다.

| 경로 | 확인 결과 |
|---|---|
| OCR·확정 전사 | 데이터 존재. 이번에는 원본 사진 OCR 정확도를 새로 PASS 판정하지 않음 |
| 평가 입력 | 확정 전사는 있었으나 typed null과 학생 답안/참조자료 역할 구분이 불충분했음 |
| 공식 기준 | 고정 기준 `cd094849-138f-5068-a7df-43e83815fc4e` 연결 확인 |
| Provider | 실제 전사가 있는데 답안 없음으로 판단한 오판 |
| 검증 | 과거 zero-step/NOT_ATTEMPTED 모순 통과. 이미 후속 student_answer 투영·SUBMITTED_ANSWER_IGNORED 방어가 있음 |
| 정규화·저장 | Provider의 보류 내용을 저장함. UI에서만 누락된 사건으로 볼 수 없음 |
| 표시 | f53fb1d가 제출 답안을 평가 근거와 독립 조회하도록 보완. 최초 평가 자체를 바꾸지 않음 |

기존 수정(candidate-4)을 재사용해 같은 확정 전사에 새 TEST evaluation/attempt ID를 부여했다. Provider는 COMPLETE/CORRECT/ATTEMPTED, 풀이7단계를 반환했다. 접선·x절편·넓이·치환·미분·단조성·최솟값8/9를 공식 기준과 대조했다. **실제 Provider 재평가 PASS, 새 DB 저장/학생 제출 전체 E2E는 NOT_VERIFIED**다. 과거 결과 덮어쓰기나 운영 재평가가 아니다.

## 새로 발견한 계산 오판 및 수정

원본은 보존하고 마지막 확정 영역의 최종값만 8/9→9/8로 바꾼 합성 오류 대조군을 만들었다. 실제 손글씨 오독 사례로 세지 않는다.

1. 기존 candidate-4: 9/8을 VALID/CORRECT로 판정, 오류0. JSON/구조 검증 PASS지만 **수학 품질 FAIL**.
2. 독립 검산에 동일 결과를 제공: accepted=false, 거절 확인. 새 평가를 다시 생성하지 않고 거절 시험 수행.
3. candidate-5: 최종 수치를 기존 식에 직접 대입·검산하고 학생의 틀린 값을 임의 교정하지 말라는 지시 추가.
4. 같은 오류 대조군 재검증: PARTIALLY_CORRECT / ANSWER_INCORRECT_APPROACH_MOSTLY_VALID, 마지막 단계 CALCULATION/ROOT/MATERIAL, 개선 과제1개. 독립 검산 승인.
5. 힌트0은 마지막 대입 위치, 힌트1은 분자·분모 분리 계산, 힌트2는 대입 계산 방향을 제공한다. 최종 정답8/9은 힌트에 없음. generated_solution은 null이므로 전체 해설 생성 PASS 아님.

이 한 쌍의 성공을 계산·개념·대안·누락·다수 오류 전체 정확도로 일반화하지 않는다.

## 구현과 적용 경계

WEB 서버 `independent-review.ts`는 기존 Math Provider를 재사용해 공식 기준·확정 학생 답안·평가 결과를 독립 검산한다. 응답은 내용 해시 일치 및 학생 근거/계산/기준/오류 분류/힌트 안전성 모두 true여야 한다. 거절/오류 시 결과 저장 전에 실패하며 자동 재시도·자동 정답 수정·과금 변경은 없다.

단일 Math와 혼합 Math child의 기존 경로에 `MATH_INDEPENDENT_REVIEW_ENABLED` 옵션을 연결했다. 기본 비활성이다. 검토 활성 시 호출당45초, 최대2호출로 제한하고 단일 gateway100초/기존5분 lease 범위에서 처리한다. 혼합 child는 두 호출의 사용량을 합산한다. 운영 플래그·Worker·WEB 변경은 하지 않았다. 이번 실호출은 임시 TEST 검증 경로였다.

## 학습 5단계

정상 신규 TEST 평가에 기존 `generateReviewedMathLearning`을 적용했다. 실제 후보 생성과 해시 결합 독립 검토2호출 성공: 학습5단계, 공식 기준1개·풀이7개 근거, 산출 사유/강점/다음 방향 존재. 대학 점수·합격 가능성이나 자동 CORRECT→5 변환이 아니다. 다만 개선점 목록에 ‘핵심 보완점은 없음’이 들어간 사례로, 무개선 항목을 불필요한 과제로 표현하지 않는 후속 정리가 필요하다.

**생성·독립 검토 PASS / DB 저장·coaching·History·최초/재첨삭 비교·APP/WEB 실제 동일 표시 NOT_VERIFIED.** 저장을 완료했다고 보고하지 않는다. 과거 결과 소급 생성0.

## 중앙대 Q2 및 나머지 대상

공식 문제2는 `6dd7b23e-7ffc-562e-8bc0-2c19c76391b1`이며 Essay 경로다. 과거 실패 내부 q1은 실제 문제1이었다. 실제 문제3이 Math다. 기존 completed/settled 회차와 성공 checkpoint는 보존한다. 이번 지시의 **새 TEST 정답/오류 답안 실제 Provider 재평가 및 혼합 전체 E2E는 NOT_VERIFIED**다. 기존 독립 검토 PASS를 새 품질 검증으로 대체하지 않는다. 서강·기존 인문은 기존 결과와 코드 회귀만 재사용했고 새 Provider 호출0이다.

## 검증 및 사용량

- Math 평가·입력·gateway·학습 계약 147개 PASS, 타입 검사 PASS.
- 인문 독립 검토·재시도·reviewed runtime 21개 PASS. 실제 인문 Provider 품질 시험과 구분한다.
- 실제 Provider 7호출: 입력55,218 / 출력10,666 / 합계65,884토큰. [안전한 사용량 영수증](task16-quality-closeout-usage-20261104.json).
- 응답에는 가격 정보가 없어 실제 비용 NOT_VERIFIED. 비용0으로 기록하지 않는다.
- 최초 TEST 배포 시 outfile multipart 형식 오류는 outdir 번들로 수정 후 빌드/배포 성공. 최종 검증 종료 후 기존 TEST `626fa92d-84f9-41d4-8f2b-5c15cc0b2308`로 복원 확인. Secret 설정 변경0.
- 임시 검증 경로 소스 제거. 원본/후속 JSON은 Git 밖 `.codex/legendstudy-task16b-test/quality-closeout-20261104`에 0600 보존. Production 데이터·TEST DB 쓰기0.

## 남은 P0 및 운영 적용 전 조건

1. 학습 판단의 신규 평가 원자적 저장·본인 조회·기존 lineage 비교 연결, TEST SQL/권한/원복 검증 후 운영 후보 보고.
2. 중앙대 공식 Q2의 정답/오류 대조군 TEST 실평가 및 혼합 전체 완료·공식문항 번호 검증.
3. 정상·오류·대안·부분·개념·누락·다수 오류의 품질 행렬 확대. 이번 발견한 최종 산술 오판을 고정 회귀 사례로 유지.
4. 독립 검산이 실제 finalize를 차단하는 TEST 저장 E2E, 거절 시 사용자 재시도/이용권 상태 보존 확인.
5. 최초/무료 재첨삭 학습 변화·History·APP/WEB 교차 조회, 전체 해설·새 빌드 실기기 검증.
6. 운영 적용은 별도 승인 전 실행하지 않는다. 전체 작업 완료·베타 품질 PASS·스토어 재제출 가능으로 판정하지 않는다.
