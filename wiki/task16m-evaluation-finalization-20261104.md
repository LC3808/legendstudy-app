# TASK16-M — 최초 평가·성장 비교·베타 준비 검증

2026-11-04. **PARTIAL. 신규 저장·실제 비교 기능 PASS, 평가 일관성 P0와 과거 INVALID_OUTPUT 원인 미확정으로 품질 마감 불가.**
[이전 L](task16l-learning-persistence-history-20261104.md), [Owner 5단계 정책](learning-completeness-policy-20261104.md), [기존 품질 감사](task16-evaluation-quality-closeout-20261104.md), [공통 학습 루프](task16g-learning-loop-20261102.md)를 재사용한다.

## 승인·보존 범위

TASK16-M은 격리 TEST 신규 수리 평가 및 실제 비교 검증을 승인했다. 기존 TEST 잔여1개 사용. Owner 추가 승인으로 기존 관리자 RPC를 통해 TEST 이용권1개만 지급하여 혼합형 신규 최초/무료1쌍 검증. grant `bedb8f53-dd8e-4b8c-88ba-340f87a6623b`. 운영 DB/WEB/Store 변경0, APP58 IPA/AAB·심사 앱 변경0.

보존 7항: 기존 canonical 학생/문항/attempt/evaluation ID 재사용; 최초/수정 시각·lineage 분리; 과거 결과 덮어쓰기 없음; 기존 policy/rubric/model/prompt 근거 보존; 학습 판단과 공식 점수/Outcome 분리; 기존 접근·삭제 정책 유지/추가 PII 수집 없음; 새로운 판단만 신규 결과에 저장. 이번 schema/migration 변경0. 진단 로그에는 내용 대신 고정 오류 코드만 추가.

## INVALID_OUTPUT 조사 및 변경

L 실패 `8c11c665-d17b-4b15-a85a-28696ecd1c4e`는 FAILED 그대로 보존. 당시 보관 파일은 HTTP422/EVALUATION_FAILED이고 Provider 원본 후보 JSON·해당 검증 로그가 없어 **실제 거절 필드를 확정할 수 없다**. 원본이 없는데 재구성하거나 정상 응답이었다고 추정하지 않는다.

코드상 INVALID_OUTPUT은 canonical `validateMathEval` 거절/구조 예외 또는 `physicalFinalize` 거절에서 기록한다. 학습 단계 생성은 이 두 검증 이후이므로 이 오류의 직접 발생 경로가 아니다. adapter/Provider 예외는 별도의 PROCESSING_FAILED/TIMEOUT 경로다. 기존 권한 오류2건은 L에서 이미 수정했으며 이번 재수정 없음.

WEB `432ab37`: physical 변환의 기존 거절 조건은 유지하고 출처/선택 extraction/경로 verdict/단계 위치/필수 풀이/힌트 공개 계약/숫자 배점/단계 kind/필수 rubric 누락을 고정 진단 코드로 구분한다. 구조 검증 예외도 별도 비식별 태그로 구분. 후보 원문·예외 내용·Secret은 로그에 추가하지 않는다. 새 정상2회 성공은 과거 실패 원인 해결의 증거가 아니므로 해당 항목 NOT_VERIFIED.

변경 파일(WEB): `src/lib/math-eval/runtime/physical-contract.ts`, `physical-contract.test.ts`, `worker-client.ts`. APP 런타임 변경 없음. TEST 배포 `6b25e1bf` / https://legendstudy-task16b.pages.dev . 운영 배포 아님.

## 실제 신규 E2E

| 구분 | 최초 | 무료 재첨삭 | 실제 비교 |
|---|---|---|---|
| 한양대2024자연 오전 Q2 | `76105e18-973a-4dc9-822c-5f5ee91afcde`, COMPLETED, 5단계 | `3194e028-6ade-449b-bc25-676094a7f0c3`, COMPLETED, 4단계 | 비교 가능, -1, 이전/현재 근거·미충족 criterion 저장 |
| 한양대2026상경 Essay+Math | run `2bb84c9f-9d7d-4f0d-bc6b-d7c6fefd45f5`, 전체 completed, Math4단계 | run `df5d19d2-352a-41ca-b28c-89bbd3ffcade`, 전체 completed, Math4단계 | 비교 가능, 0, 같은 기준 및 실제 parent 연결 |

수리 신규 attempt는 과거 검수 사진의 확정 전사 텍스트를 재사용해 TYPED로 제출했다. 수정 답안은 기존 검증 자료의 LaTeX 전사와 경계값 결론을 재사용했다. 새로운 OCR/카메라 제출을 수행한 것으로 표시하지 않는다. 혼합형은 기존 대표 시험 답안 두 문항을 그대로 재사용한 최초/무료 제출로, 학생의 실제 개선 효과 검증이 아니다. 일부 Math만 끝났을 때 시험 전체 completed로 표시하지 않았고, Essay까지 완료 후 coaching 접근이 허용됐다.

학습 단계는 저장된 독립 검토 통과 판단이며 평균/정답=5 변환 없음. 최초/재첨삭 각각 생성·저장·History 읽기 성공. 과거 L 최초/실패에 소급 저장0.

## 새로 확인한 품질 P0

수리 최초5→재첨삭4에서 모델은 재첨삭의 표준화 문장 변수 혼동을 국소 개념 오류로 판정했다. 실제 두 제출을 대조하면 **동일한 `Z=(X-m)/σ=X/2`가 최초에도 있고, 앞의 X와 변환 변수 Y의 평균/표준편차 설명도 함께 있다.** 최초는 이를 주로 기호 명료성 보완으로 취급하고 전체 충족, 재첨삭은 개념 오류로 취급했다. 저장·비교 산술은 맞지만 같은 수학적 표현의 중요도 판단이 일관되지 않았다.

따라서 이 -1을 실제 학생 실력 하락이나 정당한 품질 변화로 인증하지 않는다. 기존 결과를 임의 수정하지 않는다. 후속 고정 비교 사례에서 변수/모수 대응·사용되지 않은 부가식의 materiality와 공식 기준 관계를 검토해야 한다. 학습 판단의 독립 검토 통과만으로 교육적 정확성을 보장하지 않는다. 이번 총평가 품질/베타 준비는 PARTIAL이며 신규 수치 운영 활성화 근거로 사용하지 않는다.

혼합형 두 결과는 동일한 마지막 총자산 합산의 자릿값 오류와 핵심 방법 성취를 일관되게 지적하여4→4. 이 한 사례를 전체 대학·오류 유형 품질 PASS로 일반화하지 않는다.

## History·APP/WEB

4개 실제 결과의 learning_completeness·learning_comparison 및 전체 History JSON을 WEB 공통 RPC와 iOS Simulator MathGateway/MathCoachingPage에서 정확히 대조 PASS. 최초/무료 수리 History2, 혼합 History6(이전 이력 포함). 첫 Simulator 검사는 무료 완료 전 저장한 History를 기대값으로 사용해 실패했으며, 최종 완료 후 같은 기준 시점으로 갱신해 재실행 PASS. 검증 조건 완화 없음.

기존 `integration_test/task16l_history_test.dart` 재사용. Xcode Simulator 빌드42.9초·Native 실제 조회 PASS, 8개 화면 캡처. `/Users/woojinchang/.codex/legendstudy-task16m-test/native-captures/`에 비공개 보관. 실제 iPhone·이번 신규 WEB 브라우저 전체 클릭 E2E·APP에서 새 평가 제출은 NOT_VERIFIED. APP58에 신규5단계 기능이 배포됐다는 뜻이 아니다.

## 이용권·기존 기록

신규 검증 전 cutoff `2026-11-04T07:45:09.266581Z`의 평가27건 hash `5b75f50d6919093a52a558f9de354a23`, 원장29행 hash `2379993bc6dcba9faddde7bacd468afb` 모두 사후 동일.

신규 거래: admin_grant +1, reserve2/consume2, reserved_delta 합0. 이전 잔여1+추가1을 두 최초에 각각1 사용. 무료2회 추가0. 수리 최초/재첨삭 request를 같은 멱등키로 반복하여 같은 평가ID·무료0을 확인; Provider 재실행 없음. 과거 실패3건 수정0, 기존 원장 UPDATE/DELETE0. TEST 계정 최종 잔여0·신규 미해소 예약0.

## Provider 토큰·비용

[비식별 호출별 기록](task16m-usage-20261104.json). Math12하위 호출(4평가 × 기본평가/학습생성/학습독립검토), 입력139,946 + 출력22,080 = **162,026토큰**. Essay 기존 q1 usage 체크포인트 두 건은17,473/18,815토큰이다. 체크포인트가 모든 Essay 독립검토·요약 호출까지 포함하는지 별도 입증하지 않았으므로 이를 전체 청구 총량으로 단정하지 않는다.

| Math 흐름 | 입력 | 출력 | 합계 |
|---|---:|---:|---:|
| 수리 최초 | 17,498 | 3,937 | 21,435 |
| 수리 무료 | 20,304 | 7,867 | 28,171 |
| 혼합 최초 Math | 43,479 | 5,335 | 48,814 |
| 혼합 무료 Math | 58,665 | 4,941 | 63,606 |

OCR 재호출0. 혼합 학습 생성/검토 입력은14,441/14,875 및19,564/19,958로 이전L의135,599/135,916보다 적게 관측됐다. 공식 이미지가 input_image로 이동한 수정 후 실제 실행이지만 이전 후보/이력/문장 내용이 달라 **동일 조건 절감률 아님**. 실제 전송 바이트·동일 이미지 중복 전송 수는 미측정. 실제 청구액/검증된 단가 미확인, USD 비용 생성 금지. 원본 Cloudflare 임시 로그는 토큰/코드 추출 후 제거; 비공개 답안/키 Git 미추가.

## 테스트·운영 준비

- 신규 고정 진단 검사 포함 Math/학습/인문/혼합 서버: 260 PASS, 기존1 SKIP; 집중12 PASS; TypeScript PASS; Functions 빌드/TEST 배포 PASS.
- 기존 L SQL48+runtime131/APP8은 변경되지 않은 계약의 이전 증거로 재사용, 이번 실행 수로 합산하지 않음.
- 실제 Math2평가와 혼합2시험(Essay 포함) completed. 자동/Provider/Simulator를 구분.
- 기존 인문 로컬 회귀와 실제 혼합 Essay 완료 PASS. 전체 운영 인문 재평가 수행 없음.
- 운영 적용 필요: 기존 L SQL/ACL 후보의 별도 승인·운영 사전검사, 학습 flag와 WEB 운영 배포 별도 승인, 새 APP 후보 빌드·실기기 검수. APP58 및 Store는 Owner 관리 유지.

## 관리자 분석 준비

기존 evaluation/attempt/parent/criterion/정책 버전/History에서 대학·문항·최초/재첨삭·단계분포·동일기준 변화·완료/보류를 조회할 수 있다. UNKNOWN 학습단계를0으로 집계하지 않는다. 이번처럼 의미가 비슷한 답안의 판정 불일치는 별도 품질 사례로 구분해야 한다.

추가 검토 대상: 실패 후보의 최소 비식별 진단 보존(현재 고정 로그만, 과거 raw복구 불가), 정책상 허용된 OCR 수정 유형, 하위 Provider 호출별 사용량/이미지 중복량/실제 비용. 관리자 UI·새 장기 수집·과거 backfill 구현 없음.

## 남은 P0 및 최종 판정

1. 과거 INVALID_OUTPUT 실제 거절 원인 NOT_VERIFIED. 신규2회 통과와 진단 보완은 완료했으나 원인 규명 완료 아님.
2. 수리5→4의 변수/모수 오류 materiality 일관성 PARTIAL. 근거 재검토 및 고정 사례 검증 전 품질 마감 불가.
3. 실제 iPhone/WEB UI 양방향 신규 제출, 동일 입력 토큰 비교·이미지 크기 측정은 NOT_VERIFIED.
4. 운영 DB/WEB/새 앱 활성화는 미실시·별도 승인.

**최초·무료 평가/학습 단계 저장/동일 기준 비교/History/원장 기능 PASS, 전체 TASK16-M 및 베타 품질 준비 PARTIAL.**
