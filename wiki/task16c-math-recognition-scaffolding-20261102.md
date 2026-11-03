# TASK16-C — 수학 인식·스캐폴딩 UX

2026-11-02 · **PARTIAL / 실제 손글씨 전체 학습 E2E 미완료**. Owner 방향 수정에 따라 신규 엔진 없이 기존 입력/평가/학습 계약을 재사용한다. 잘못 보냈다고 철회한 인수인계서는 정책 근거로 사용하지 않았다. 운영 활성화 없음.

## 재사용한 증거와 구현

[TASK16 감사](task16-commerce-social-predevelopment-audit-20261102.md), [10/27 필수 코칭 결정](math-technical-review-20261026.md#2026-10-27--owner-필수-후속-ai-풀이-코칭성장), [건국 실제 검증](phase3-service-20261022.md#2026-10-23-math-worker-갱신-및-실제-최초-평가), [한양 Q2 Provider 결과](task16b-commerce-social-integration-20261102.md#2026-11-02--수학-전용-provider-e2e-pass)를 우선 확인했다.

건국 자연1번의 WEB 업로드→8영역 확인→최초 평가 및 iOS Simulator 재첨삭→WEB/APP History 교차조회는 기존 PASS를 재사용한다. 해당 사진은 **합성 인쇄 이미지**였으며 실학생 손글씨 검증이 아니다. 이전 성공 평가나 Credit 처리를 재실행하지 않았다.

| 기존 구성 | 이번 처리 |
|---|---|
| Math Provider·MATH-4 검증기 | 기존 adapter/validator 그대로, 새 평가 엔진·프롬프트 없음 |
| MATH-3 입력·추출·확인 | 기존 영역/신뢰도/확인 intent 재사용, WEB 수식 미리보기·원문·유형·불확실 안내 보강 |
| MixedMathWorker·math-session | 변경 없음. 기존 confirmed_input/extraction 영역 전달 한계 유지; 원인 없이 재설계하지 않음 |
| MATH-5/6·math_learning | 기존 reveal_hint/reveal_solution 및 재작성/재평가 계약 재사용 |
| History·성장 | 기존 서버 공개 기록·LearningDelta·History 재사용. 새로운 저장/원장 없음 |
| 공통 결과 | WEB Math 풀이 표시에 수식 렌더링; Native Math 보고서만 새 렌더러 적용, 인문 텍스트 표시는 유지 |

## 구현 변경

- WEB KaTeX 0.19.1: 명시적 LaTeX 구분자·정규화 수식 렌더. 분수·지수·첨자·적분·행렬. 신뢰되지 않은 HTML/URL 명령 비허용, 확장/길이 제한, 오류 시 원문 표시. 답안 원본을 변환·UPDATE하지 않는다.
- Native flutter_math_fork 0.7.4: 동일 수식 표시와 실패 시 선택 가능한 원문. 인문 보고서는 기존 SelectableText 유지. APP 릴리스·기기 배포 없음.
- WEB 인식 확인: 페이지/텍스트·수식·표·그래프 유형/신뢰도 표시, 최초 인식 원문 보존. 판독불가 그대로 확인·빈 수정 제출 방지. 확인 후 내용을 고치면 이전 확인을 취소하여 다시 확인해야 한다.
- WEB/Native 스캐폴딩: 오류 위치→힌트→다음 힌트→명시적 참고 풀이 공개 확인. 기존 서버 hint 가용성과 reveal RPC를 사용하고 해설은 기본 접힘. AI 생성/공식/검수 참고 풀이의 출처를 구별한다. 재작성 callback·기존 재첨삭 및 History 계약 유지. 새로운 사용자 공개 정책·단위오류 enum 등 DB 계약을 임의로 추가하지 않았다.
- 수치 표/점 그래프 공통 컴포넌트: 원문 문자열과 숫자 값 대조, 유한 수·좌표 중복·근거 유무 검사. 미확인 값의 점/보간 생성 없음. 원문 값과 표시 값을 함께 보인다. **실제 OCR 표·그래프 결과와 자동 연결되지는 않았다.** CAS/증명 검증기가 아니다.

## 검증: 구현과 품질 구분

| 사례 | 결과 | 범위 |
|---|---|---|
| 한양 Q2 계산 오류 | 기존 PASS 재사용 | 마지막 합산 1,393,000→1,393,900; CALCULATION, 추가 호출0 |
| 한양 Q2 정답 풀이 | 신규 Provider HTTP200·validator PASS | CORRECT, 오류/CORE0; 올바른 풀이에 오류를 생성하지 않음 |
| 한양 Q2 개념 오류 | 신규 Provider HTTP200·validator PASS | 거듭제곱 미분에서 지수를 유지한 오류를 THEOREM_MISUSE, 후속 결론을 전파 오류로 구분 |
| OCR 오류 | UI/계약 fixture PASS | 기호 불명확 수정·판독불가 승인 방지·확인 취소. **실제 손글씨 OCR 정확도 미검증** |
| WEB 인문 포함 전체 회귀 | 1,550 PASS / 4 SKIP | 이후 영향 범위 24 PASS, 타입·lint·161 route build PASS |
| Native 기존 Math·공통 결과·인문 | 29 PASS; 신규 위젯2 PASS | 최종 보고서 Math 분리 후 영향24 PASS, analyze PASS. 실기기 미검증 |
| Preview 실제 브라우저 | PASS | 수식 렌더, 인식 예제 수정, L1→L2→명시 확인→접힌 참고 풀이 확인. 합성 화면 검수이며 실학생 E2E 아님 |

신규 API는 정답·개념오류 **2회만** 호출했다. 배포 직후 첫 진단 요청은405(Provider 미호출), 비호출 readiness 확인 후 실행했다. 각 실제 호출은1회로 제한했다. 전용 TEST Pages의 수학 Secret만 사용했으며 Essay 키 사용0.

- 정답: input12,815/output3,201/total16,016,26.291초.
- 개념: input12,833/output4,534/total17,367,36.162초; cached input1,571 포함.
- 합계33,383tokens. 입력 $4/백만·출력 $20/백만의 캐시할인 제외 보수 추정 **USD0.257292**. 실청구 미확인. [공식 단가](https://developers.openai.com/api/docs/models/gpt-5.6-sol).
- 비공개 증거: `/Users/woojinchang/.codex/legendstudy-task16b-test/math-provider-correct-result.json`, `math-provider-concept-result.json`. 공식 Package·합성 답안을 고정한 임시 진단이며 DB/원장 client가 없다. 사용한 임시 진단 배포dfc2e83f와 라우트는 제거했다.

## Preview·Git

- [Owner 화면 검수](https://legendstudy-task16b.pages.dev/internal/math-coaching-preview/): 화면 동작용 합성 예제라고 명시. 기존 비공개 접근 코드 사용. 입력값은 이 화면에서만 유지되며 실제 History 저장을 가장하지 않는다.
- 최종 Preview deployment `a591fefb-445a-458e-8ad5-2c40506768c6`.
- WEB SHA `512e06f`, Native 개발 코드 SHA `a9921bb`. 운영/APP 릴리스 브랜치 변경0.
- 스크린샷 `/Users/woojinchang/.codex/legendstudy-task16b-test/task16c-preview.png`.

## 남은 완료 차단 요소

1. 기존 자료에서 실학생 손글씨·정답 전사 쌍을 확보하지 못했다. Owner에게 비식별 사진의 로컬 경로를 요청했다. 합성 이미지를 손글씨 품질 근거로 대체하지 않는다.
2. 격리 TEST DB에 math_input/extraction/evaluation/learning/catalog는 있지만 **math_session_submit/read가 없다**(읽기 전용 실측). 기존 회차 계약과 Worker credential/admission을 격리 TEST에서 추가 연결해야 새 standalone 사진 제출→평가·재첨삭 전체 흐름을 검증할 수 있다. 운영/TEST Credit 원장 무변경 제약을 지켜 이번 회차 제출은 하지 않았다. 임의 금융 우회·새 결제 원장 생성 금지.
3. 공통 Essay 혼합형 결과와 standalone math_learning의 저장/공개 이력 연결은 미완성이다. 화면에 힌트를 임의로 복사해 서버 학습 이력이 생긴 것처럼 표시하지 않는다.
4. 실제 손글씨 OCR의 문자/수식·표·그래프 판독 정확도, 영역 근거 위치 정합성, 단위·조건누락·논리비약의 대표 품질셋, APP 실기기 수식/힌트 및 새 전체 학습 E2E는 미검증이다.

**완료 판정:** 구현한 표현·학습 RPC 연결과 제한된 실제 평가 품질은 위 범위만 확인했다. Owner의 사진 제출→인식 확인→오류/힌트→직접 수정→재첨삭 완료 기준은 아직 충족하지 못했다. 운영 활성화 금지 유지.

## 보존 검토

기존 7개 보존 원칙을 유지한다: 제출/확인/평가/공개 시각 분리, 원본 이미지·전사·패키지 보존, 재작성은 새 attempt로 기존 답안 UPDATE 금지, 기존 사용자 identity, 학습과 입시 결과 구분, 기존 접근·삭제·비공개 정책, AI 판정/성장 delta를 원본 사실로 취급하지 않기. 새 storage/schema/학생 수집·원장 수정 없음. rollback은 위 커밋의 표시·연결 코드만 되돌리며 학습 기록 삭제 없음.
