# TASK16-L — 학습 완성도 저장·재첨삭 비교·History

2026-11-04. **최종 PARTIAL / 신규 혼합형 4단계 저장·Native 조회 PASS / 운영 미적용**.
[Owner 학습 정책](learning-completeness-policy-20261104.md), [직전 품질 결과](task16-evaluation-quality-closeout-20261104.md), [공통 학습 루프](task16g-learning-loop-20261102.md)를 계승한다.

## 범위와 보존 검토

기존 Math 평가와 독립 검토 계약을 재사용한다. 새 엔진·History·이용권 시스템 없음. 과거 결과 소급 수정 없음. 최소 nullable 확장과 기존 혼합형 child JSON만 사용한다.

장기 데이터 보존 검토 7항: (1) 학생의 제출/수정과 평가를 별도 기존 attempt/evaluation ID로 보존, (2) 기존 canonical ID와 parent/prior 연결 유지, (3) 이전 결과 overwrite/backfill 금지, (4) 정책·공식 rubric hash·기존 모델/프롬프트·시각으로 당시 판정 재현성 확보, (5) 같은 기준과 실제 lineage만 비교, (6) 기존 owner RPC/삭제·보존 정책을 계승하고 새 PII 수집 없음, (7) 운영 이관은 승인·preflight·원복과 이전 이력 해시 확인 후 별도 적용한다.

## 저장 계약

- 단독 Math: `math_evaluations.learning_judgement jsonb` nullable. 새 canonical finalize 트랜잭션 안에서만 기록한다. 기존 결과에는 NULL.
- packet: `value`(학습 단계1–5, 근거, 평가 요소별 안전한 근거, policy/rubric, 시각, evaluation/question ID), 독립 검토 승인·candidate hash, 기존 criterion verdict, model/prompt/profile/extraction/attempt/exam/Registry question metadata.
- 혼합형: 기존 시험 결과의 Math child `evaluation.learning_judgement`. 시험 전체 완료 guard를 통과한 뒤 문항별로 공개한다. Essay를 Math에 보내거나 전체 별점을 임의 합산하지 않는다.
- 근거 부족/검토 거절/선택적 학습 생성 실패는 학습 단계 미저장. 유효한 기본 평가까지 막지 않는다. 정답 상태나 점수 평균으로 단계를 만들지 않는다.
- 정책·rubric·model·prompt가 같은 실제 이전 평가만 비교한다. 전후 단계/delta, 전후 근거, 개선/미충족 criterion과 검토된 설명을 반환한다. 실제 실력·합격 가능성으로 해석하지 않는다.
- 기존 `math_coaching` / `essay_math_coaching` read·history에 optional 항목만 추가. 전체 해설은 기존 명시적 공개 guard 유지.

## TEST 적용·문제 해결

TEST `kpqbedylxlyntrrfybpn`에 core / mixed / criterion details 적용. 최초 실제 finalize에서 기존 postgres 소유 facade와 math_executor 내부 잠금 권한 차이를 발견했다. 내부 finalize helper만 canonical math_executor 소유 SECURITY DEFINER로 제한하고 PUBLIC/학생 호출 권한을 부여하지 않는다. 임시 역할·CREATE 권한은 같은 트랜잭션에서 회수한다. 기존 public RPC ACL 유지. 실제 TEST 구조를 로컬 회귀 fixture에도 반영했다.

적용 전 기존 평가24건의 결과 해시 `9c726c6054b05dce430c20dc4b993a83`, 원장20행 해시 `67744cf62a0612cf7ff187edf3201ff3`; 첫 schema 적용 후 두 해시 동일. 기존24건 학습 단계 소급 저장0.

Owner가 격리 TEST 검수용 이용권2개 지급 승인. 기존 `admin_manual_credit_grant`를 실제 TEST 관리자 인증으로 호출, grant `ddf63101-ccf7-429d-8cbe-ccd9508374a0`. 지급 key 고정으로 중복 지급 방지. 운영 지급0. 실패한 신규 평가 `10f1c03a-00e9-4ea8-ac4b-31763e790850`는 원본 보존, 기존 lease recovery로 실패·예약 해제 후 같은 답안 재요청. 임의 원장 UPDATE 없음.

## 검증 상태

- 로컬 SQL 48검사 + 기존 runtime131 PASS: 원자성·멱등·외부 소유자 거절·과거 보존·무료0·기준 변경 비교 금지·혼합 전체 완료 guard·원복 보존.
- WEB/Math/인문 서버 검사223 PASS, 기존1 SKIP. TypeScript PASS.
- APP 표시/History 검사8 PASS, Analyze PASS. 실제 TEST 응답과 Native 화면·History 대조 PASS (iOS Simulator, 실기기 아님).
- TEST Preview `https://legendstudy-task16b.pages.dev`, 최종 배포 `43aad34c` (이미지 전송 비용 방어 포함; 실제 4단계 생성은 직전 `8847dc1d`).
- 실제 Provider 평가·저장·교차 조회/최종 원장은 후속 실행 결과로 갱신한다. Mock PASS를 실제 E2E로 계산하지 않는다.

## 관리자 품질 분석 데이터 계약

새 관리자 UI/수집 없이 조회 가능한 지표:

| 지표 | 기존 근거·분모 |
|---|---|
| 최초/재첨삭 수 | evaluation request_kind + attempt kind/prior 관계; 혼합은 parent run 단위 |
| 완료율 | 요청 평가 전체 대비 COMPLETED; transport 완료와 판정 보류는 별도 |
| 보류율 | 기존 overall review_status / NOT_DETERMINABLE; 생성 실패와 혼동 금지 |
| 학습 단계 분포 | nullable 중 ASSESSED만1–5; NULL/기능off/검토거절을0단계로 계산 금지 |
| 단계 변화 | 실제 parent/prior + 같은 question/policy/rubric/model/prompt만 |
| 대학/문항별 | 기존 leaf→problem→set→Registry exam/question 연결 |
| 정책별 | 저장 policy/rubric hash와 기존 result provenance model/prompt |
| OCR | selected_extraction_id로 기존 extraction provider/model/version 연결; TYPED는 OCR 없음 |

학습 생성 미저장 이유의 과거 세부분포, 실제 사람의 장기 학습 성과는 현재 데이터만으로 확정할 수 없다. 추가 수집은 별도 설계 대상이다. 혼합 child와 전체 run을 중복 집계하지 않는다.

## 운영·인계

SQL 후보: `supabase/candidates/task16l_learning_persistence/`. 운영 DB/WEB 배포/Store 변경0. APP58 산출물 보존. 운영 적용은 별도 Owner 승인 필요. 단독 Math의 선택적 generation은 `MATH_LEARNING_ENABLED=true`인 격리 TEST만 활성화; 운영 기본off. 기존 베타 종료·14일·유료1/무료1 정책 유지.

## 실제 실행 최종 결과

| 항목 | 판정 | 근거 |
|---|---|---|
| 혼합형 신규 최초 평가 | PARTIAL | `61fa246b-965b-4fbd-882c-a1746f48d24d` Essay+Math completed, 이용권1 소비. 기존 학습 생성 gate가 PARTIAL 풀이를 제외해 학습 단계 없음. 기존 결과를 소급 변경하지 않음 |
| 혼합형 무료 재첨삭 | PASS | `1e6f958c-fba4-4c8f-8ab7-0f181f0fa962` completed, 독립 검토 통과 학습4단계 DB 저장·read·History 노출, 무료 quote0 |
| 실제 단계 변화 비교 | PARTIAL | 최초 단계 미저장으로 `NO_PREVIOUS_ASSESSMENT`; 가상 전후값을 만들지 않음. 같은 기준2→4/+2와 평가 요소별 근거는 로컬 canonical RPC 검사 PASS |
| 단독 Math 실제 저장 | FAIL | 두 요청이 내부 helper/facade 권한 차이로 finalize 실패. 수정 후 Owner 승인 추가1회 `8c11c665-d17b-4b15-a85a-28696ecd1c4e`는 기존 검증 INVALID_OUTPUT으로 종료. 학습 단계 저장0. 무료 재첨삭 선행 완료 조건 미충족 |
| APP↔WEB 공통 조회 | PASS / 범위 제한 | 실제 혼합 재첨삭4단계/근거/정책/History JSON을 WEB 공통 RPC와 iOS Simulator MathCoachingPage에서 대조. 실제 Native 화면 캡처 확인. 이번 신규 WEB 브라우저 전체 제출 E2E·실기기는 별도 NOT_VERIFIED |
| 과거 보존 | PASS | 기존 Math24건 해시와 기존 ledger20행 해시가 위 사전 값과 동일. 과거 학습 단계0 |
| 이용권 | PASS | 승인 지급2, 실제 consume1(혼합 최초), 무료 추가0. 수리3건 reserve/release로 복구, 총 잔여1·예약0. 기존 원장 UPDATE/DELETE0 |
| 인문 회귀 | PASS | 기존 인문 gateway/exam 포함 WEB223 검사와 혼합 Essay 실제 완료. 기존 인문 결과/정책 수정0 |

수리 실패 ID: `10f1c03a-00e9-4ea8-ac4b-31763e790850`, `31286587-2d5c-4d10-a744-3ca713b556cd`는 만료 복구 후 TIMEOUT 이력 보존. 세 번째 INVALID_OUTPUT도 기존 실패 정산으로 예약 해제. 실패한 요청을 완료로 변경하지 않음. 추가 최초 평가 승인 횟수 소진 후 Provider 재호출0. 승인받은 무료 수리 재첨삭은 최초 성공 선행 조건이 없어 실행하지 않음.

실제 4단계 근거는 핵심 접근/계산이 뒷받침되지만 마지막 총자산 합산의 국소적 산술 오류가 남았다는 판단이다. 결과를 만점/합격 가능성으로 표현하지 않으며 최종 정답 수치는 학습 단계 설명에 포함하지 않는다.

## 호출·비용 및 비용 방어

이번 실제 평가 실행은 단독 Math3회(저장 권한 실패2/INVALID_OUTPUT1), 혼합 시험2회(최초/무료)다. Provider 내부 하위 호출 수 전체는 완전한 사용량 기록이 없어 확정하지 않는다. 캡처된 Math 하위 호출7건만 입력322,106 + 출력13,201 = **335,307토큰**. 이는 전체 사용량의 하한이며 첫 실행/추가 최초 실행/Essay 호출 일부를 포함하지 않는다. 모델 `gpt-5.6-sol`, 정확한 단가·전체 청구액 미확인으로 예상 달러 비용을 임의 작성하지 않는다.

혼합 재첨삭의 학습 생성/독립 검토가 공식 PNG base64를 JSON 텍스트로 전송해 각각 입력135,599/135,916토큰을 사용한 문제를 확인. 최종 코드는 기존 Math Provider와 동일하게 `input_image`로 전송하고 텍스트에서 base64만 분리한다. 공식 이미지/criteria/확정 답안/검토 해시는 보존하며 변형·생략하지 않는다. 전송 회귀2개 PASS, 최종 배포 후 실제 추가 호출은 하지 않았으므로 절감량은 미측정이다.

## 남은 차단 요소 및 다음 검증

1. 단독 Math 신규 최초→무료 재첨삭의 실제5단계 저장 E2E와 실제 두 단계 비교. Provider 재시도 예산/범위는 별도 확정 후 진행; TEST 이용권1개 잔여.
2. 혼합 최초·재첨삭 양쪽 모두 학습 단계가 있는 실제 비교. 지금 이전 결과는 소급 채우지 않는다.
3. 최종 이미지 전송 비용 방어의 실호출 토큰·정확 비용 측정; 품질 기준 완화 없이 수행.
4. 운영 SQL/ACL·기능 플래그·WEB 배포는 별도 승인. APP58 보존, 새 스토어 빌드/제출0.

읽기 전용 Native 캡처(원본/학생 비공개 자료는 Git 미추가): `/Users/woojinchang/.codex/legendstudy-task16l-test/native-captures/mixed-revision-learning.png`, `mixed-revision-history.png`.

검증 스크립트: `tool/test_task16l_learning.py`, `integration_test/task16l_history_test.dart`; 수학/인문 Provider 성공 사례를 이 테스트의 전체 PASS로 재분류하지 않는다.
