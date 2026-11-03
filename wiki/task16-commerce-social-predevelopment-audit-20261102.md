# TASK 16 — 상경·사회논술 개발 전 조사·Wiki 감사

기준일: 2026-11-02 KST. **조사 완료 / 구현 범위 제안 / 자료 확보·운영 품질 검증 PARTIAL.**
이번 작업은 코드·DB·Provider·Credit·결제·APP 릴리스 브랜치를 변경하지 않았다. Wiki만 갱신했다. 신규 기능 구현·배포·실제 평가 호출은 0회다.

결론: 기존 Essay + Math + 회차 orchestration + 대학별 공식 근거 + 재첨삭 계약을 재사용한다. 새 상경 평가 엔진은 필요하다는 근거가 없다. 우선 과제는 **대표 회차의 정확한 근거/문항별 연결, 결과 표현, 코칭 조회 연결, 실제 답안 품질 검증**이다. 11월 3일까지 전체 상경·사회 자동평가/정식 공개 완료를 약속할 수 없다.

## 감사 기준과 범위

- AGENTS → index → current-status → decisions → product-scope를 복원하고 Wiki 전체에서 상경/사회/commerce/business/Manus/Grok/경쟁 서비스 별칭을 검색했다. 아래 도메인 문서와 관련 저장소·Git 객체·실제 코드를 교차 확인했다.
- APP/Worker: 현재 작업트리 `legendstudy-service-app-20261022`, 관찰 HEAD `ae3b35a`, `codex/material-service-app-20261022`. 기존 미커밋 코드/문서가 있어 보존했다.
- LAB: service checkout `e0667cb`와 더 최신 release checkout `843f3a8`의 관련 코드를 비교. 아래 WEB 판정은 후자 기준. 체크아웃 SHA는 감사 재현용이며 현재 운영 배포 SHA라는 주장이 아니다.
- 통합 문서: `legendstudy-docs` 관찰 HEAD `f3ee5cf`. Claude 브랜치 LAB `f496c20`, 통합 문서의 별도 Git 객체 `2652cbe`도 읽었다. 브랜치를 이동·병합하지 않았다.
- **운영 DB·실행 플래그·현재 설치 APP·현재 배포 버전은 이번에 직접 조회하지 않았다.** 운영 PASS는 날짜가 명시된 기존 Wiki 증거이며 11월 2일 재검증 PASS가 아니다. 신규 DB 스키마/UPDATE 의미를 선택하지 않는다.
- `IMPLEMENTED`: 명시된 범위의 코드 구현 확인. `PARTIAL`: 일부 구현/연결만 확인. `PLANNED`: 기존 설계/결정 존재, 해당 구현 미완료. `NOT_IMPLEMENTED`: 조사 코드 경로에 구현 없음. `NOT_VERIFIED`: 원문·현재 운영·정확성 근거 부족. 코드 구현과 운영·교육 품질은 별도 판정한다.

## A. 조사 자료 목록과 위치

| 요청 자료 | 확인 위치·근거 | 이번 확인 상태 |
|---|---|---|
| 1. LegendStudy Essay Lab 리서치 보고서 | [Manus V2 인수인계](essay-lab-manus-handoff-20261010.md), [12파일 해시 감사](../tool/essay_lab/evidence/overnight-20261010/manus-audit.json)의 `research/essay-lab-research-report.md` | 과거 원문 확보·해시일치 기록 확인. 이번 원문 자체는 NOT_VERIFIED. 기록된 Downloads ZIP과 `/private/tmp/legendstudy-manus-v2`는 현재 미발견 |
| 2. 2027 논술전형 조사 및 Web MVP Foundation | 위 V2, [완료/제한 보고](essay-full-service-implementation-20261011.md), [WEB preview 문서](../../legendstudy-release-20261024/docs/ESSAY_RESEARCH_PREVIEW.md); [2027 조사 1-A 발췌](../../legendstudy-materials/essay-validation-2026-10/group-1a-20261025/manus-structure/2027학년도_논술전형_조사보고서-1a.md), [첨부 원본 경로·해시](../../legendstudy-materials/essay-validation-2026-10/group-1a-20261025/manus-structure/attachment-manifest.json) | 구현 보고·조사 발췌는 직접 확인. 요청한 합본 제목의 전체 원문은 미확보. 발췌를 전체 원문으로 대체하지 않음 |
| 3. AI수학 경쟁정보: 콴다·스쿨작·수작 | [통합 Wiki P0 연구 요약 §3](../../legendstudy-docs/00_PROJECT/PRIORITY_MATH_VISUAL_COACHING_20261027.md), [로컬 기술 검토](math-technical-review-20261026.md) | 요약 확인. 정확한 요청 제목의 원문/버전/원본 첨부는 NOT_VERIFIED |
| 4. 스쿨작·수작 문제 인식·풀이 및 수리논술 기술 조사 | 같은 P0 문서의 Manus 10/27 요약: `AI 수학 튜터링 심층 벤치마크`, `feature_comparison.csv`, `poc_cost_model.csv` 참조 | 요약 확인. 요청 문서와 동일 원문인지 미확정, CSV·공식화면 번들 미확보 |
| 5. `LEGENDSTUDY_MATH_COMMERCE_MANUS_ADDENDUM_20261029.md` | 로컬 Wiki/관련 저장소/Downloads, GitHub 연결 검색, Drive 검색 | **NOT_VERIFIED — 정확 파일 미발견. 내용·결론을 추정하여 재작성하지 않음.** |
| 6. `2026-10-26-essay-launch-beta-growth-owner-decisions.md` | [통합 Wiki 원문](../../legendstudy-docs/90_HISTORY/2026-10-26-essay-launch-beta-growth-owner-decisions.md) | 원문 직접 확인. 장문형 우선, 혼합형 회차 검수, 원문 기반 코칭, 1/0·14일 보존 |
| Claude 계열 기술 검토 2종 | [코칭 검토 f496c20](https://github.com/LC3808/legendstudy-lab/blob/f496c20/docs/MATH_COACHING_PIVOT_TECH_REVIEW.md), [평가 검토 f496c20](https://github.com/LC3808/legendstudy-lab/blob/f496c20/docs/MATH_ESSAY_EVALUATION_TECH_REVIEW.md) | 로컬 Git 객체로 원문 확인. 코칭 문서 자체 작성 표기는 **Codex 세션**으로, Claude 브랜치 보관과 저자를 구분 |
| Claude 수학·과학 추론 연구 | [2652cbe의 원문](https://github.com/LC3808/legendstudy-docs/blob/2652cbe/90_HISTORY/REVIEWS/LEGENDSTUDY_MATH_SCIENCE_REASONING_SCAFFOLDING_RESEARCH_20261027.md) | 로컬 Git 객체로 215줄 원문 확인. 현재 docs 체크아웃 파일 목록에는 없음. 저자 Claude 명시 |
| Grok 기술 검토 | [10/12 코드 리뷰 기록](../../legendstudy-docs/90_HISTORY/REVIEWS/2026-10-12-grok-code-review.md), 위 P0 문서 Grok 요약 | 코드 리뷰 기록 확인. 수학 경쟁·기술 원보고서는 미확보. IAP 리뷰는 이번 평가 범위와 분리 |

탐색은 관련 저장소의 숨김 worktree를 포함한 파일명, Git 이력/명시 ref, Downloads(한글 NFC 정규화 포함), 연결된 GitHub/Drive 검색까지 수행했다. 검색 결과 없음은 자료가 존재하지 않는다는 증명이 아니다. 기존 Manus 도구는 신규 조사 생성용으로, 원문 조회 대신 새 조사를 시작하지 않았다. 누락 원문 확보 시 이 감사의 해당 행만 갱신한다.

기존 개발 보고 재사용: [PHASE3](phase3-service-20261022.md), [대학 프로필 PHASE1](university-evaluation-profile-phase1.md)·[PHASE2](university-evaluation-profile-phase2.md)·[운영 E2E](university-profile-production-e2e-20261023.md), [상경·고려](commerce-korea-20261026.md), [인하 복구](inha-photo-extraction-20261026.md), [전체 STANDBY 감사](essay-all-university-standby-20261026.md), [WEB 작성](essay-web-studio-ui-20261026.md), [성장·결과 UX](essay-growth-history-ui-20261026.md).

## B. 조사 결과 핵심 요약

1. 연구의 공통 방향은 원본 → 확인된 전사 → 단계/오류 → 최소 힌트 → 재작성 → 성장이다. MATH-3/4/5/6에 이미 모델·검증·학습 계약이 존재한다. 연구를 신규 모듈 전체 개발 지시로 해석하지 않는다.
2. 경쟁 서비스의 관찰 가능한 입력·단계 표시 UX와 내부 OCR/정확도/자동 부분점수는 별개다. 기존 Manus 요약도 자필 장문 수리논술의 자동 부분점수·재첨삭 정확성이 공개 검증됐다고 주장하지 않는다. 경쟁사 최신 기능/가격을 이번에 새 조사한 것은 아니다.
3. 대학별 실제 기출·문항별 공식 채점표가 우선이다. 2027 모집요강/모의 구조를 과거 기출에 소급하거나 계열명으로 Math를 강제하지 않는다. 특히 서강 경제경영은 언어논증형 사례가 있다.
4. 렌더링 개선은 계산/통계 판단 정확성 개선과 다르다. LaTeX·OCR·LLM·CAS를 같은 기능으로 세지 않는다. CAS와 다중 Provider는 연구 권고이며 현재 범위의 구현/도입 승인이 아니다.
5. 기존 코칭 연구의 상용 수준·정확도 등 평가는 가설/구조 평가로 취급한다. 실제 학생 답안의 잘못된 확신·대안 정답·오독 평가가 검증돼야 교육 품질 PASS다.

## C. 기존 설계와 현재 구현의 차이

| 항목 | 코드/연결 상태 | 근거와 남은 차이 |
|---|---|---|
| 제시문 분석 | IMPLEMENTED(기존 Essay), 상경 전 범위 PARTIAL | `material_runtime.py`의 공식 패키지 + 기존 평가/독립 검수 재사용. 서강2025모의 사례는 기준에 없는 관점 순서를 요구해 검수 실패. 대학 전체 품질 완료 아님 |
| 표·그래프 인식 | PARTIAL, 정확도 NOT_VERIFIED | Math region의 TABLE/GRAPH·공식 이미지 입력 존재. 숙명2026 그래프 포함 사례의 과거 검수 기록 존재. 학생 도표 원본→셀/축/단위→평가의 전용 검증 완료 근거 없음 |
| 통계 자료 해석 | PARTIAL | 기존 Essay 공식 기준으로 해석 평가 가능. 별도 통계 검산·표 값/축/모수 검증 모듈은 NOT_IMPLEMENTED(조사 경로). 표본/인과 해석 정확도 미검증 |
| 수식 입력 | IMPLEMENTED(텍스트·사진·추출 확인), 표현 PARTIAL | WEB/Native 입력 계약 존재. 수식 전용 시각 편집·LaTeX 렌더러 직접 의존성 미확인, 현재 경로는 텍스트 표시 |
| 계산 검증 | PARTIAL(LLM 진단), CAS NOT_IMPLEMENTED | `CALCULATION`/대안 경로 등 출력 모델과 검증기 있음. 구조 검증은 수학적 참 증명이 아니며 독립 CAS/수치 검산 없음 |
| 혼합형 문항 | PARTIAL | 기존 `MixedMathWorker`, WEB `math-session.ts`·`exam-bridge.ts`, 부모 checkpoint/정산 구현. 한양2027모의 Q1 Essay/Q2 Math 통합 코칭 E2E는 NOT_VERIFIED |
| 대학별 채점 기준 | PARTIAL | `university_profile.py` scope/hash/version·문항 기준 우선 구현. 공식 자료 연결·프로필 상속·문항 전체 입력 검수·실제 품질은 서로 다른 수치 |
| 풀이 과정 평가 | IMPLEMENTED(모델·검증), 서비스 PARTIAL | steps/edges/errors/causes/CORE 있음. 결과 화면은 주로 텍스트 나열이며 원본 단계 연결·연쇄 오류 표현 미완료 |
| 부분점수 | PARTIAL(제한된 계약), 공식 점수 정확도 NOT_VERIFIED | `validateMathEval`은 공식 max 없는 awarded_points를 거절. 현재 Provider 지시는 임의 숫자점수 금지. PARTIALLY_SATISFIED/5단계 진단을 공식 부분배점으로 환산하면 안 됨 |
| 재첨삭 | IMPLEMENTED(기존 계약), 상경 Math 연결 PARTIAL | `math_learning` 재작성/재평가·기존 회차 최초1/무료0·14일 계약. 기존 Essay·건국 Math 운영 증거와 한양 혼합형의 신규 E2E는 구분 |
| 평가 결과 UX | PARTIAL | WEB/Native 결과·History·동일 기준 비교 구현. Math 전용 단계/힌트와 공통 회차 결과 사이 연결, 수정 풀이 토글·원본 사진·수식 표시 미완료 |
| 신규 시각 코칭·제한 CAS 확대 | PLANNED | 10/27 Owner P0·기술 설계 존재. 통합 품질 검증/공개 미완료 |

구체적 코드 차이:

- [회차 Math endpoint](../../legendstudy-release-20261024/functions/api/essay/math-session.ts): `typed_answer=data.answer.body`, `confirmed_input=data.answer.input`, `extraction=[]`, `selected_extraction_id=null`. 답안 누락으로 단정할 수 없지만 영역 좌표 기반 코칭을 그대로 붙일 수 있다고도 할 수 없다.
- [Provider adapter](../../legendstudy-release-20261024/src/lib/math-release/server/provider.ts): `json_object`, 공식 `official_images`를 input_image로 변환. 학생 원본 사진의 평가 단계 직접 전달은 이 코드에서 확인되지 않음. 출력 구조/참조 검증을 유지해야 한다.
- [전용 Math 화면](../../legendstudy-release-20261024/src/components/math-release/student-route.tsx): 단계 representation/explanation, LearningGuidance, delta/history 연결은 존재. [현재 LearningGuidance](../../legendstudy-release-20261024/src/components/math-learning/learning-guidance.tsx)는 `onRevealSolution`을 props에 남기지만 호출 UI가 없다. 과거 f496c20의 ‘해설 보기 구현됨’을 최신 화면에 그대로 적용할 수 없다.
- [공통 결과](../../legendstudy-release-20261024/src/components/my/evaluation-report.tsx): 저장된 원문 인용은 실제 답안에 포함된 경우만 표시. 문장 수정 예시는 존재하지만 개별 접힘 토글이 아니다. Math 전용 L0/L1/L2 UI를 이 컴포넌트에서 연결하지 않는다.
- [Native Math](../lib/features/essay/math_workspace_page.dart): 입력·확인·learning state 조회·재평가 존재. WEB 전용 코칭과 같은 수준의 Native 표시/회차 E2E 완료로 간주하지 않는다.

Wiki 정합성 발견:

- 10/8 mixed foundation의 ‘혼합 coordinator 없음’은 당시 상태. 후속 회차 구현을 기준으로 PARTIAL로 읽어야 한다.
- 인하 1/3 성공·Q2/Q3 미복구는 **10/26 21:19 3/3 복구 기록**으로 갱신된다. 복구는 과거 거절 원인의 확정/재발 방지 증명이 아니다.
- f496c20의 ‘라이브 모델 미연결’은 당시 브랜치 범위. 현재 코드 adapter와 기존 운영 성공을 무시한 전체 미연결 결론은 잘못이다.
- 로컬 ‘출시 준비 후 순차 착수’보다 통합 Wiki 10/27 P0는 **즉시 병행 착수, 11/10 제한 무료 베타 STANDBY 목표**를 기록한다. 이번 TASK16은 최신 요청대로 조사만 하며 그 과거 구현 지시를 자동 실행하지 않는다.
- current-status에 과거 ‘Production AI OFF’와 후속 운영 성공이 함께 남아 있다. 대학/회차별 승인과 기록 날짜를 따라야 하며 전역 ON/OFF로 요약하지 않는다. 현재 플래그는 NOT_VERIFIED.

## D. 이미 개발된 기능 — 재개발 금지

공식 자료·Registry/문항 ID·고정 패키지, 프로필 scope/hash/version 선택, 기존 Essay 평가/독립 검수, Math 입력·학생 확인·단계/오류 모델, 회차 부모/문항별 실행·성공 checkpoint·중복방지, 기존 재작성/재첨삭·History, WEB/Native 공통 결과·동일 기준 성장 비교는 재사용 대상이다.

운영 완료 증거는 범위 한정이다: 기존 건국 인문/수리, 성균·숭실 최초/무료 재첨삭, 인하3문항 복구, 고려 Owner 공식답안 Q1 4/5·Q2 5/5 확인. 이는 과거 Wiki 증거이며 상경 모든 회차 또는 공식 대학점수 정확성을 보장하지 않는다. [PHASE3](phase3-service-20261022.md)·[현재 상태](current-status.md)·[인하](inha-photo-extraction-20261026.md)·[고려 정정](commerce-korea-20261026.md) 참조.

## E. 미구현 또는 추가 연결이 필요한 기능

- Math 원본 사진·확정 전사·수식 미리보기·단계/ROOT/전파 오류를 함께 보여주는 완성된 결과 UI.
- 공통 회차 결과에서의 MATH-5 힌트/수정 풀이, MATH-6 재작성 연결의 완성 및 Native 동등 경험.
- 제한 CAS/수치 검산, 표·그래프·통계 해석 전용 검증, 검증된 공식 부분배점 자동 산출.
- 전 대학·회차의 공식 근거/physical leaf 연결 완성. 자료 부족/범위 미검수는 UI를 만들어 해소할 수 없음.
- 전체 무제한 성장 이력: 기존 WEB 기록은 최근50회차 한계. 신규 서버 기능으로 확대하려면 별도 범위 필요.

## F. 품질 검증 필요 기능

| 검증 대상 | 통과 근거로 필요한 것 |
|---|---|
| 제시문/사회·상경 논증 | 실제 기출의 공식 평가항목과 학생 인용 대응; 서강처럼 없는 조건 생성 금지; 인문 기존 성공 fixture 회귀 |
| 표·그래프·통계 | 숫자/부호/축/단위/범례/표본 조건 전사 비교, 근거 없는 인과 추정 차단, 이미지 누락 시 불확실 표시 |
| 수식·과정 | 완성·부분·중단·계산오류·개념오류·조건누락·대안정답 사례별 검수; OCR 오류를 학생 오류로 분류하지 않기 |
| 부분점수 | 대학·학년도·문항별 공식 배점과 일치, 기준 미공개는 점수 미제공, 중복 감점/전파 오류 처리 검수 |
| 혼합형·재첨삭 | 전체 필수 문항, 부모 1건, 실패 child 재개·성공 재사용, 기존 무료 횟수/14일, History 정확 참조 |
| 코칭 UX | 저장 결과만 표시, 힌트 순서/누설 제한 유지, AI 참고 풀이·공식 해설·학생 원본 구분, 원본 좌표 없는 강조 금지 |

이번 재실행: Python 프로필/material/exam/mixed checkpoint **56 PASS**; WEB evaluation/physical/exam-bridge/learning/runtime/Guidance **7파일121 PASS**. 모두 오프라인 계약/fixture 검사이며 Provider·운영 DB 호출 없음. 최초 Python 명령은 import path 오류 2건 후 `PYTHONPATH=tool:.`로 정상 재실행했다. Node v20.19.5에서 실행했고 저장소 요구는22이므로 배포 환경 검증으로 승격하지 않는다. Flutter build·실기기·브라우저 운영 E2E는 실행하지 않았다.

## G. 상경·사회 개발 우선순위

1. **P0 근거·범위 고정:** 기존 장문형 사회/상경 패키지 재사용. 서강 언어형과 한양 혼합형을 분리. 후보 공식 문제/평가표·입력·현재 저장 결과를 읽기 전용 추적하고 비어 있는 연결만 명세화.
2. **P0 표현·조회 최소 보완:** 기존 결과 구조로 수식/단계·오류·근거를 표시하고, 기존 learning 계약에 맞는 힌트/재작성 UI를 연결. 저장 데이터가 없는 필드는 생성하지 않음. 인문 prompt/평가 경로는 변경하지 않음.
3. **P0 대표 검수:** 한양2027모의 상경 Q1/Q2, 서강은 문항 형식 확인 후 언어형/실제 Math 회차 구분. 인하·건국 성공 결과는 회귀 근거로 재사용하되 상경 E2E 대체 금지.
4. **P1 정확성 보강:** 실제 오류 근거에 따라 제한 CAS·학생 이미지 병행·표/통계 검증을 별도 설계. Provider/Worker/DB 변경이 필요하면 정확한 영향 범위를 먼저 제시.
5. **P2 확대:** 잠금 검수셋·실학생 품질 지표 확보 후 대학 확대·과학·전이학습. 연구 비용/일정 수치를 실측처럼 사용하지 않음.

## H. 11월 3일까지 가능한 범위 — 조건부 개발 제안

**11월 2일 개발 범위 확정 후 약 1일, 기존 데이터/실행환경이 사용 가능하다는 전제의 추정이다. 이번 감사에서는 구현하지 않았다.**

| 범위 | 11/3 목표 | 제외/조건 |
|---|---|---|
| 대표 회차 자료/코드 | 한양 혼합형1 + 서강 언어형1의 공식 근거·문항별 binding·조회 GAP 명세 확정 | 원문/현재 DB 검증이 불가하면 보류 사유와 정확한 ID를 남김 |
| 표시 최소 후보 | 기존 저장 결과 또는 명시된 fixture로 수식 표시·단계 카드·근거/불확실 상태 UI 후보 | 이 중 최소 범위를 우선. 원본 접근 API/DTO 변경이 필요하면 이미지 연결은 다음 단계 |
| 힌트/수정 풀이 | 기존 계약과 실제 조회 데이터가 맞는 범위에서 연결 후보·접힘 표시 검토 | 단독 Math와 회차 Math 저장구조가 다르면 즉시 통합 완료 약속 금지 |
| 검증/인수인계 | 인문 회귀·Math 계약·모바일 WEB 표시 검사, 미연결/품질 GAP 보고 | 운영 Provider 평가·공개·APP 릴리스는 포함하지 않음 |

11/3에 포함하지 않을 것: 전 대학 상경·사회 완성, 공식 부분점수 정확성 인증, 새 OCR/Provider/CAS 운영 도입, 과학 평가, DB/정산 변경, APP 릴리스/스토어 배포. 기존 11/10 목표는 별도 Owner 검수·대표 E2E를 요구하며 11/3 소규모 후보 완료와 동일하지 않다.

## I. 재사용 코드·RPC·Package

| 자산 | 실제 위치/계약 | 재사용 원칙 |
|---|---|---|
| 상경 정책·공식 입력 | [evaluation_policy.py](../tool/essay_lab/evaluation_policy.py), [material_runtime.py](../tool/essay_lab/material_runtime.py), [university_profile.py](../tool/essay_lab/university_profile.py) | 기존 문항별 essay/math binding·profile pin 유지 |
| 회차 실행 | [mixed_math_runtime.py](../tool/essay_lab/mixed_math_runtime.py), [async_exam.py](../tool/essay_lab/async_exam.py), [exam_runtime.py](../tool/essay_lab/exam_runtime.py) | 기존 parent·lease·checkpoint·timeout/정산 경계 재사용 |
| Math bridge | [math-session.ts](../../legendstudy-release-20261024/functions/api/essay/math-session.ts), [exam-bridge.ts](../../legendstudy-release-20261024/src/lib/math-release/server/exam-bridge.ts) | `essay_exam_math_context`, `essay_claim`, `essay_finalize_success/failure`, 기존 회차 finish 계약; child 별도 예약 없음 |
| 추출·평가 | [math-input](../../legendstudy-release-20261024/src/lib/math-input/types.ts), [math-eval](../../legendstudy-release-20261024/src/lib/math-eval/types.ts), [validation](../../legendstudy-release-20261024/src/lib/math-eval/validation.ts), [physical-contract](../../legendstudy-release-20261024/src/lib/math-eval/runtime/physical-contract.ts) | 원본/학생확인/region·criterion pins·검증기 재사용 |
| 학습·재첨삭 | [learning-client](../../legendstudy-release-20261024/src/lib/math-learning/runtime/learning-client.ts), [기존 물리계약 Wiki](math-essay-learning-runtime.md) | `math_learning`: read_learning_state/reveal_hint/reveal_solution/create_resolve_attempt/request_reevaluation/read_learning_history. 권한·무료자격 서버 판단 |
| 결과·성장 | [LearningGuidance](../../legendstudy-release-20261024/src/components/math-learning/learning-guidance.tsx), [공통 결과](../../legendstudy-release-20261024/src/components/my/evaluation-report.tsx), [Native 보고서](../lib/features/essay/evaluation_report_view.dart) | 인문 결과·History 보존; 같은 문항/버전/척도만 비교 |
| 공식 Evidence Package | [기존 package refs](../tool/essay_lab/evidence/overnight-20261010/existing-package-references.json), materials의 `university-profiles-20261023`, `commerce-korea-20261026`, `group-1a-20261025` | 원본 hash/page/학년도/문항/revision 재사용. 새 가짜 정답·임의 기준 생성 금지 |
| 패키지 의존성 | WEB React/Next/PDF.js, APP Flutter 기존 스택 | KaTeX/MathJax/flutter_math_fork는 기존 설치 자산으로 확인되지 않음. 도입 후보와 재사용 패키지를 구분 |

## J. 착수 시 주의사항·보존 검토

- 이번 TASK16을 구현·운영 변경 승인으로 해석하지 않는다. 10/26·10/27 정책은 보존하되 현재 요청의 조사 제한이 우선한다. 인문 평가 prompt/공식 기준을 상경에 맞춰 일괄 변경하지 않는다.
- 계열명이 아닌 실제 문항·공식 기준으로 route. 수리 문항을 제외하고 전체 혼합형 회차 완료로 판매하지 않는다. 기존 부분제출 정책과 전체회차 서비스 준비 상태는 별개다.
- 과거 성공 SQL 재실행·프로필 최신버전 무조건 교체·기존 기록 재평가 금지. 현재 미커밋 수정과 동시 작업을 보존한다. 코드/문서 파일 존재만으로 Production 적용을 추정하지 않는다.
- 누락된 Manus 추가보고서는 후속 자료 GAP다. 현 원문이 없는 상태에서 그 권고를 Owner 확정 정책으로 채택하지 않는다.

[상위 데이터 전략](longitudinal-learning-admissions-data-strategy.md)의 일곱 보존 질문에 대한 이번 범위 답변:
1. 새 학습 사실을 생성하지 않는다. 과거 제출/평가/복구 시각과 이번 감사일을 분리한다.
2. 원본 PDF/hash/page·답안/확정전사·당시 package pin으로 재현한다. 원문 미확보는 복원 완료로 표시하지 않는다.
3. 원본/이력 UPDATE·삭제 없음. 미래 수정 풀이는 원본을 덮어쓰지 않는다.
4. 기존 canonical 사용자·문항·회차·evaluation ID 유지. 새 identity를 만들지 않는다.
5. 코칭/평가는 Learning이며 합격 Outcome·지원 Decision으로 해석하지 않는다.
6. 이번 새 개인정보 수집·Provider 전송 없음. 기존 owner-scoped/private 자료 권한·보존/삭제 계약 유지.
7. OCR·AI 판정·부분 만족·성장 delta는 파생값. 공식 점수/원본 사실로 승격하지 않고 버전·불확실성을 보존한다.

## 검증·다음 단계

실행 명령: `PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tool:. python3 -m unittest tool.test_university_profile tool.test_material_runtime tool.test_essay_exam_runtime tool.test_mixed_math_checkpoint` → 56 PASS. WEB은 release checkout의 기존 Vitest로 위 F의 7파일121 PASS. Wiki handoff 검사 결과는 [작업 로그](log.md)에 기록한다.

Owner 보고 제안: **대표 회차 근거 확인 + 기존 결과 UI/코칭 연결의 최소 범위**를 다음 개발 단위로 한다. 운영/품질 NOT_VERIFIED 항목과 원문 미확보는 그대로 이월한다. 이번 감사는 개발 착수 전 판단 근거이며 정식 공개 완료 보고가 아니다.
