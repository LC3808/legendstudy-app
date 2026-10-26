# 수리논술 기술 검토 — 2026-10-26

후속: [기존 인하 회차 Q2·Q3 복구 완료·원인 미확정](inha-photo-extraction-20261026.md#2026-10-26-2119-kst--기존-math-회차-운영-복구). 아래는 당시 조사 기록이다.

상태: **조사·설계 제안만**. 코드/DB/Worker/Production 변경·Provider 호출·Credit 처리 없음. 출시/공개 상태도 변경하지 않았다.

기존 결정: [상경 공통 회차](commerce-korea-20261026.md), [인하 추출 복구 및 Math 미복구](inha-photo-extraction-20261026.md), [Math 공유 계약](math-essay-shared-integration-contract.md), [WEB 입력·결과 UI](essay-web-studio-ui-20261026.md). 고려 인문 Owner 공식답안 Q1 4/5·Q2 5/5 정정은 유지하며 평가 설정 변경 대상에서 제외한다.

## 1. 현재 아키텍처 — 코드에서 확인

분석 기준 WEB f45e40ba73738302db72475ec19d51eb4e80b74f. 직전 작업에서 확인된 Production Pages ca6a181e-a7b1-4fab-a759-75629cae3ac2이며 이번에는 재배포/운영 재조회하지 않았다. APP 작업트리의 기존 미커밋 변경은 보존했다. 로컬 코드가 실제 설치 APP과 동일하다고 판단하지 않는다.

WEB 회차 경로:

```text
시험/전체 문항 Registry + 공식 문제/해설 + 고정 프로필
학생 사진 → 브라우저 초안 → artifact 등록/업로드 → 추출 요청
 → 추출 영역(raw_text/normalized_math/순서) 저장
 → 학생 수정·확인 → 확인된 입력 참조
 → 회차 요청·1 Credit 예약 → 기존 큐의 문항별 분기
    ├ Essay 문항 → 기존 Essay 평가
    └ Math 문항 → /api/essay/math-session → Math candidate
        → JSON parse → validateMathEval → physicalFinalize
 → 성공 문항 checkpoint 보존 → 회차 결과/History → 기존 정산
```

사진을 선택했다고 서버 전송·확인이 끝난 것은 아니다. 브라우저 사진 초안과 서버 artifact/추출/확정은 별도 단계다. 단순 텍스트 답안은 사진 추출 없이 기존 입력 경로를 따른다. Math child는 별도 Credit을 예약하지 않는다. 재처리는 성공 문항을 유지하고 기존 회차의 실패 문항만 대상으로 한다.

**실제 Math 평가 입력의 중요한 차이:** `functions/api/essay/math-session.ts`는 서버의 `essay_exam_math_context`를 읽고 `confirmed_input=data.answer.input`, `context.extraction=[]`, `selected_extraction_id=null`을 전달한다. `physicalClaimToInput`의 regionIds는 extraction에서 만들어지므로 이 회차 경로에서는 비어 있다. 이것이 곧 답안 누락을 뜻하지는 않는다. typed_answer와 confirmed_input 전달을 함께 봐야 한다. 다만 영역 참조를 요구하는 출력과의 호환성 점검 대상이다.

`provider.ts`가 실제 이미지 content로 변환하는 것은 `official_images`다. 학생 artifact 참조 문자열이 JSON에 있다는 이유만으로 학생 원본 사진을 Vision 모델이 본다고 볼 수 없다. 이번 코드에서 학생 원본을 평가 단계의 input_image로 넣는 경로는 확인되지 않았다. 현재는 학생 확인 추출/텍스트 중심 평가이며 공식 이미지 보조 입력 기능이 있는 구조다. 전용 OCR 제품을 별도로 쓰는 단순 구조로 단정해서도 안 된다.

Flutter `math_workspace_page.dart`에는 attempt 생성 → register_evidence → uploadEvidence → read_input → extract → confirm_extraction → request_evaluation/request_reevaluation → evaluate가 존재한다. 이는 leaf 단위 Math 경로이며 WEB의 회차 Math bridge와 호출 계약이 다르다. WEB 성공을 APP 다문항 회차 성공으로 계산할 수 없다. APP 변경/빌드/실기기 검증은 이번 범위 밖이다.

근거 코드:
- WEB `functions/api/essay/math-session.ts`
- WEB `src/lib/math-release/server/{provider,exam-bridge}.ts`
- WEB `src/lib/math-eval/{validation.ts,runtime/physical-contract.ts}`
- APP `tool/essay_lab/mixed_math_runtime.py`, `lib/features/essay/{math_gateway,math_workspace_page}.dart`

## 2. 인하대 실패 — 확인 범위와 한계

기존 요청 `fe6a3c4b-2f91-41cc-9e0b-d9490bd34dd1`. 아래는 직전 READ-ONLY 조사 기록을 재사용한 것이며 현재 시점 새 DB 조회 결과로 표현하지 않는다.

| 단계 | 확인된 상태 |
|---|---|
| A 이미지 입력 / B 접근 | 기존 사진 Q1=4장,Q2=2장,Q3=2장 보존·추출에 사용됨 |
| C 추출 | 3건 COMPLETED, 영역25/23/16, Owner 확인 후 CONFIRMED 각1건 |
| D Provider 호출 / E 응답 | 실패 문항에도 usage 기록과 INVALID_MATH_OUTPUT 존재. 평가 응답을 받은 이후 거절 경로 |
| F JSON 파싱 | 이 오류를 반환하는 현재 경로상 candidateJson의 JSON 파싱을 지난 것으로 판단. 파싱 예외는 별도 경로 |
| G 스키마/구조 검사 | 후보: validateMathEval의 구조 예외 또는 domain 거절. 상세 코드 과거 미기록 |
| H 문항·기준/영역 참조 검사 | 후보: pinned 기준/solution/region/step 참조 불일치. 구체 필드 미확정 |
| I 결과 정규화 | 후보: physicalFinalize의 enum/필수 dimension/points/선택 추출 불일치 등. 미확정 |
| J History 저장 | Q2·Q3은 bridge에서 거절되어 성공 결과 저장 단계에 도달하지 못함. History 장애라는 증거 없음 |

Q1 completed, Q2·Q3 최초 및 retry1·2 failed. parent/billing reserved, 완료시각 null, lease 만료였으며 기존1 Credit 예약과 성공 checkpoint가 남아 있었다. 추가 차감 또는 최종 사용 확정을 이번에 수행하지 않았다.

**비교 가능한 차이:** 사진 장수와 추출 영역 수, 완료/실패 상태. **비교할 수 없는 차이:** 실패 후보 JSON의 필드·수식·참조값. 실패 checkpoint output=null이라 Q1과 Q2·Q3의 출력 차이를 재구성할 수 없다. 사진이 더 많은 Q1이 성공했으므로 장수만을 원인으로 단정할 근거도 없다.

정확한 원인은 현재 **G/H/I 중 미확정**이다. ‘수학을 못 풀어서’, ‘이미지 인식 실패’, ‘timeout’이라고 확정하면 잘못된 진단이다. 기존 safe 진단은 structure/domain/physical 및 고정 코드만 기록하도록 배포되어 있지만 새 실패 코드가 확보되지 않았다. 이번 호출 금지 지시에 따라 재현하지 않았다.

과거 실패 응답은 저장되지 않아 재정규화만으로 복구할 수 없다. 추후 승인된 기존 실패 문항 재시도에서 진단 코드 확보 → 해당 계약 최소 수정이 필요하다. Q1 재평가·새 회차·새 예약은 만들지 않는다. 향후 후보 보존을 도입하려면 기존 비공개 저장의 권한/보존기간 검토가 먼저이며 공개 로그·Wiki에 답안을 저장하지 않는다.

## 3. 이미지·수식의 한계

| 항목 | 코드/기록상 사실 또는 일반 위험 | 대응 제안 |
|---|---|---|
| 여러 사진 순서 | 사진별 reading_order 중복으로 저장 실패했던 실제 버그는 수정됨 | 학생 artifact 순서와 문항 범위 유지; 재추출보다 완료 결과 재사용 |
| 분수·지수·근호·적분/상하 관계 | 인식 일반 위험. 이번 Q2·Q3 원인으로 확인되지 않음 | 원본·LaTeX 미리보기·편집을 함께 표시 |
| 여러 줄/중간 계산 | 평문 변환에서 줄과 연결 관계 손실 가능 | 순서/영역/줄 경계 보존, 학생이 쓰지 않은 단계 생성 금지 |
| 손글씨 | 촬영 해상도·회전·필체에 따른 불확실성 | 인식 불명 부분만 표시·수정 요청 |
| 그래프·도형·표 | 텍스트만으로 공간 관계·그래프 특징 보존 어려움 | 원본 이미지 병행 평가를 선택적으로 추가 |
| 대문항/소문항 | 학생 사진순서만으로 실제 답안 단위를 확정할 수 없음 | Registry question/leaf와 artifact 관계를 서버에서 고정 |
| 원본과 추출 불일치 | 사용자 확인은 있으나 렌더링이 부족하면 확인이 어려움 | 확인 전 비교화면, 수정 후 확인버전 유지 |
| 수학적 논리 | 문법이 유효한 JSON/LaTeX도 틀린 추론일 수 있음 | 조건/정의역/대안 풀이를 함께 판단, 불확실 상태 보존 |

Vision도 작은 글자·회전·그래프·공간 관계에서 실수할 수 있으므로 원본 직접 입력은 정확도 보증이 아니다. [OpenAI 이미지 입력 한계](https://developers.openai.com/api/docs/guides/images-vision).

## 4. QANDA 참고 화면

화면에서 확인 가능한 것은 수식 렌더링, 전략 요약, 번호별 단계/접기, 정답식과 조건 구간, 잘한 점/누락 조건의 시각적 구분이다. OCR 엔진·모델·검증기·정확도·비용은 화면으로 알 수 없다. 문제 풀이 생성과 학생 풀이 첨삭도 서로 다른 과제다.

우리도 기존 결과의 steps/hints/criteria를 재사용해 단계별 표시를 구현할 수 있다. 새 풀이를 생성해서 학생의 풀이처럼 보여주지 않는다. WEB은 KaTeX를 우선 후보로, 지원 범위/접근성 필요에 따라 MathJax를 비교한다. 원본 사진 + 읽은 내용 + 렌더링 미리보기는 PC 나란히, 모바일 전환/세로 배치가 적합하다. 편집 원문과 표시용 렌더링을 분리한다. 수식 렌더러는 OCR이나 채점기가 아니다.

KaTeX는 trust=false, 확장/크기 제한과 오류 원문 escaping을 적용한다. MathJax는 ui/safe 설정이 가능하다. Flutter는 pure Dart/Flutter인 flutter_math_fork 후보가 있으나 지원 TeX/현재 SDK 호환성 확인이 필요하다. WEB 화면을 WebView로 복제하지 않는다. 현재 두 프로젝트 의존성 파일에서는 이 세 수식 렌더러의 직접 의존성을 확인하지 못했다.

근거: [KaTeX 보안](https://katex.org/docs/security), [MathJax safe](https://docs.mathjax.org/en/latest/options/safe.html), [Flutter Math 패키지](https://pub.dev/packages/flutter_math_fork).

## 5. 네 가지 대안 비교

상대 비용/지연은 설계 추정이며 실제 단가·초 단위 성능 측정값이 아니다. D는 A/B/C와 배타적인 인식 방식이 아니라 실행 경계 분리 방식이다.

| 기준 | A 추출·LaTeX 개선 | B 학생 원본 직접 평가 | C 원본+추출+공식근거 | D Math 실행 독립화 |
|---|---|---|---|---|
| 정확도 가능성 | 인식 확인 개선, 그림 정보 한계 | 원본 정보 활용, Vision 오류 잔존 | 불일치 대조 가능, 어느 입력을 믿을지 정책 필요 | 분리 자체는 정확도 개선 아님 |
| 기존 재사용 | 가장 높음 | Math adapter/기준/정산 유지 | 추출·Math·기준·정산 유지 | engine 재사용 가능, orchestration 변경 큼 |
| 난이도 | 중 | 중 | 중~높음 | 높음 |
| 외부 서비스 | 필수 신규 없음 | 기존 Provider 이미지 지원·권한 확인 | 기존 Provider로 가능; CAS는 선택 | 큐/실행 자원 추가 가능 |
| 비용 | 추출+평가, 재사용으로 재추출 억제 | 평가 이미지 토큰 증가; 추출 생략 시 확인 UX 손실 | 추출+이미지 평가로 상대적 증가 가능 | 추가 운영 자원, 모델 단가 개선 보장 없음 |
| 응답시간 | 기존 두 단계 | 생성1단계 가능하나 이미지 처리 지연 | 처리/입력량 증가 가능 | 병렬화 가능하나 순서·레이트 한도 영향 |
| 복구 | 추출/평가 단계별 재개 | 실패 문항 평가 재개 | 저장된 추출 재사용·평가만 재개 | 경계/lease/중복방지 추가 복잡성 |
| 다문항 | 기존 parent 활용 | 기존 parent 활용 | 기존 parent 활용 | parent/child 관계 재설계 위험 |
| 유지보수/확장 | 낮음~중간, 기존 계약 의존 | 중간, artifact 안전 전달 | 중간~높음, 증거 충돌 관리 | 높음, 배포·장애 경계 증가 |

네 방식 모두 구현 가능성은 있으나 현재 G/H/I 거절은 B/C/D로 바꿔도 남는다. 입력 기술 교체보다 출력 계약 복구가 선행한다.

## 6. 권장 기술 아키텍처

**단기 A(기존 Math Worker 최소 수정), 중기 B를 추가해 C형 입력을 구성**한다. 새 Math 평가 엔진이나 독립 결제 시스템은 권고하지 않는다. 현재도 Math adapter/validator는 Essay와 논리적으로 분리되어 있으므로 D를 처음부터 구축할 이유가 부족하다.

권장 경로: 기존 회차 parent → 기존 문항별 Math adapter → 학생 확인 텍스트 + 필요 시 해당 문항 원본 이미지 + 공식 근거 → schema 제약 출력 → 구조/참조 검증 → 기존 physical 변환 → 기존 checkpoint/History/정산.

현재 json_object는 JSON 문법 중심이며 코드가 요구하는 복잡한 steps/edges/errors/causes/core/hints/rubric 계약을 보장하지 않는다. 지원 모델을 확인한 뒤 strict JSON Schema를 도입하는 것이 우선 후보다. refusal/incomplete도 별도 상태로 처리한다. Structured Outputs도 수학 내용의 정확성·Registry 참조 일치까지 보장하지 않으므로 domain 검증은 유지한다. [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs).

서버가 아는 provenance/고정 ID는 서버에서 통제하고 모델의 임의 생성 부담을 줄인다. 스키마·TypeScript 타입·physical 변환의 필드/enum을 단일 계약으로 대조한다. 타입·enum의 의미 보존 변환만 결정적으로 정규화하고, 존재하지 않는 기준/영역을 만들거나 오류 필드를 삭제해 강제 통과시키지 않는다. 재처리는 오류코드별로 구분한다: transport 재개, 형식 변환 재검사, 의미 참조 오류 수정. 자동 무한 재호출은 금지한다.

### SymPy 및 수학적 검증

대수식 동치, 미분/적분 결과, 대입, 제한된 계산 단계의 보조 확인에 유용하다. 그러나 정의역·분모0·구간 경계·양변 제곱의 역방향·복소수/실수 가정이 있어야 한다. 식이 단순화되었다는 사실만으로 풀이 전체가 타당한 것은 아니다. 증명·서술·도형 논증은 공식 기준 기반 LLM 판단과 불확실성 표시를 유지하고 CAS 결과는 보조 증거로 사용한다.

SymPy parse_expr는 eval을 사용하므로 학생/모델 문자열을 그대로 실행하지 않는다. 허용 AST/연산·함수 목록, 길이/깊이/차수 제한, 네트워크 없는 별도 격리 프로세스, CPU/메모리/시간 제한이 필요하다. 파싱 실패·timeout·판정 불능을 오답으로 매핑하지 않는다. Python CAS를 현재 JS Worker에 즉시 끼우는 작업은 최소 수정 범위를 넘으므로 이번 장애의 출시 전제에서 제외한다. [SymPy 파서](https://docs.sympy.org/latest/modules/parsing.html), [동치 비교의 주의점](https://docs.sympy.org/latest/explanation/gotchas.html).

## 7. 재사용과 보존

Registry·공식자료·프로필 pin, 사진 artifact·학생 확인, parent 회차/문항별 큐, 성공 checkpoint, 1 Credit 예약·확정, 기존 무료재첨삭/기간, History/result UI를 재사용한다. 인문 경로와 과거 성공 결과는 수정하지 않는다. 입력 origin/모델 출력/검증 결과를 혼합하지 않는다.

7개 보존 검토: (1) 기존 발생시각·재처리시각 구분, (2) 원본 사진/확인 답안 재현, (3) 새 후보가 과거 결과를 덮어쓰지 않음, (4) 기존 사용자/서버 권한 유지, (5) 기술 실패를 학습성과로 기록하지 않음, (6) 비공개 자료의 목적·권한·retention 검토 전 진단 원문 저장 금지, (7) AI/CAS 판정을 공식 정답/원본 사실로 승격하지 않음. 이번에는 저장 구조를 선택하거나 변경하지 않았다.

## 8. 개발 난이도·비용·지연

최소 출력 계약 보완은 중간 난이도, 원본 이미지 병행은 중간, CAS와 독립 orchestration은 높음으로 판단한다. 정확한 일정은 실패 코드 미확보로 산정 불가. 75초 요청 timeout과 12,000 출력토큰 상한은 현재 코드 설정이며 평균 응답시간·필요토큰량이 아니다.

비용 산식: 추출 입력/출력 토큰 비용 + 문항별 평가 입력(이미지 포함)/출력 비용 + 실패 재호출 비용 + 선택적 검증 실행 자원. 현재 모델의 실제 가격·이미지 크기·문항별 token·retry 횟수를 묶어야 원/회차 계산이 가능하다. 기존 usage 존재와 비용 확정을 혼동하지 않는다. 이번 조사 호출0/추가 평가비용0이며 과거 실패 비용은0원이 아니다. A/B/C/D의 구체 원화·응답초·개발일 수는 근거 부족으로 제시하지 않는다.

## 9. 단계별 계획 — 미실행

1. 기존 오류 로그에 상세 코드가 있으면 우선 사용. 없으면 추후 승인 시 기존 실패 문항만 제한 재개해 코드 확보. 이번에는 호출하지 않음.
2. 실제 거절 필드에 대한 최소 수정. 기존 성공 출력과 저장된 입력으로 회귀 확인; Q1 재평가 금지. json_schema 지원과 physical 계약 정합성 확인.
3. 사용자 확인 수식 렌더링 개선. 표시 오류가 원본·확인 내용을 변경하지 않도록 분리.
4. 학생 원본 이미지 병행은 문항별 소유권·순서·확인버전을 고정하여 선택 도입. 공식자료/학생자료 역할을 명시.
5. 출시 전에는 대표 유형의 기존 정상/실패 사례로 저장·재개·중복방지·1/0 정산 확인. 평가 정확도는 Owner가 지정한 소규모 실제 답안으로 측정하되 이번에 실행하지 않음.
6. CAS는 반복되는 계산 오류가 실제로 확인될 때 제한된 식 검증부터 도입. 증명 전체 자동 검증은 별도 목표로 두지 않음.

복구 원칙: 신규 출력은 저장 전 거절, 성공 checkpoint 보존, 기존 lease/멱등성 사용. 복구 불능 예약은 기존 실패 정산 정책과 Owner 승인 범위에서 처리한다. 이번 조사에는 적용 SQL·롤백 SQL이 없고 기존 추출 복구/인하 STANDBY SQL 재실행 금지. 향후 코드 rollback은 해당 배포의 직전 정상 버전으로 하며 학생 데이터를 되돌리지 않는다.

## 10. 출시 전략 의견

현실적인 권고는 **전략 A: 실제 성공 범위의 인문·사회 우선 출시, Math 의존 자연·혼합형은 핵심 장애 해소 후**다. 인하의1/3 부분 성공을 다문항 Math 서비스 완료로 볼 수 없다. 이는 수리 서비스 불가능 판단이 아니라 출력 계약·복구·정산의 미확인 위험을 출시 일정에서 분리하자는 의견이다.

전략 B는 G/H/I 원인 확정·기존 실패 회차 복구·최초/무료/실패 정산과 혼합형 통합이 확인된 뒤 가능하다. 현재 상태만으로 동시 출시 일정을 약속할 수 없다. 공개 범위·버튼·가격은 이번에 변경하지 않았다. 최종 출시 결정은 Owner에게 있다.
