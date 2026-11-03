# TASK16-I — 수리논술 통합·품질 검증

2026-11-03. **WEB 사진→실제 평가→무료 재첨삭 및 혼합형 서버 평가 성공. 전체 품질 PARTIAL / 운영 HOLD.**

후속 Owner 결정: 실제 통합 E2E의 기능 PASS 인정, 전체 품질/운영 HOLD 유지. [검수 경로·계정 접근·알려진 문제](task16i-owner-review-20261103.md)를 준비했다. 아래 A–J 세부 미완료는 기능 승인으로 덮어쓰지 않는다. 준비 후 TEST 잔액2/예약0이며 아래 잔액0은 I 실행 마감 시점 기록이다.

## 근거·보존

Owner가 [H](task16h-web-math-ux-20261103.md)의 WEB `6f5d726` / APP `9fc3f15`를 확인하고 통합 품질 검증을 승인했다. Academic Purple/현재 UX 구조 유지. [C](task16c-hanyang2024-handwriting-validation-20261102.md), [E](task16e-recognition-disclosure-p0-20261102.md), [F](task16f-native-math-ux-20261102.md), [G](task16g-learning-loop-20261102.md), [G 품질](task16g-quality-closeout-task16h-preparation-20261103.md)의 공식 자료·전사·성공 결과를 재사용했다. 새 평가 엔진 없음.

일곱 보존 답변: (1) 입력/확인/평가/공개 시각 분리, (2) 원본·후보·공식 Package와 hash 유지, (3) 수정은 새 확인본/attempt로 보존하며 기존 평가 삭제·덮어쓰기 없음, (4) 같은 TEST Auth 사용자, (5) 학습과 이용권 판단/입시 성과 분리, (6) 비공개 원본·키·계정 Git 제외, (7) 검증자 수정본/AI 판정과 실제 원문을 구분한다. 새 저장 스키마 없음.

격리 Supabase `kpqbedylxlyntrrfybpn`, Pages `legendstudy-task16b`, Worker `legendstudy-essay-task16b`만 변경/호출했다. 운영 DB/Auth/Credit/Ledger/결제/WEB 및 APP 1.0.1(41) 릴리스 변경 없음.

## A–J 판정

| 기준 | 판정 | 실제 범위와 남은 부분 |
|---|---|---|
| A WEB 실제 E2E | PARTIAL | 기존 시험 History에서 새 유료 사이클 시작→Q1/Q2 사진 업로드→실제 OCR→영역 수정·확정→실제 평가→결과·힌트·공개→수정 제출→무료 평가→History 재조회 PASS. 새 Catalog 선택부터의 연속 촬영 및 제출 전 WEB crop/보정은 미검증/미구현. 결과 원본 회전은 H의 보기 기능 |
| B APP↔WEB 양방향 조회 | PASS | 기존 APP 제출의 WEB 조회(H) 재사용. 이번 WEB 사진 결과/힌트/공개/History, 무료 수정 텍스트·무료 사용 상태를 Native Simulator 실제 gateway/UI로 조회. 원본 bytes SHA-256과 수정 텍스트 일치 |
| C OCR 오류 방어 | PASS(방어) | 영역별 확인 전 확정 금지, 편집 시 확인 취소, 판독 불명/불확실 차단, 정규화 수식의 문장 소실 방지. **OCR 인식 정확도 자체는 Q1 FAIL/Q2 PARTIAL** |
| D 실제 오류 영역 연결 | PASS(1사례) | 신규 Q2 결론 누락 과제의 실제 region/bbox가 원본 하단 영역에 강조됨. 임의 좌표 없음. 전체 OCR 좌표 품질 인증 아님 |
| E 개선 과제·힌트 품질 | PARTIAL | 실제 오류/수정 후 해소 확인, 최대5개·누적 공개 정상. 일반 개념/힌트, 공식 기준별 학습 중요도 및 다수 오류 우선순위는 미완료 |
| F 수식 중심 전체 해설 | PARTIAL | 실제 무료 Q2 해설에서 3식 렌더, 1식 원문 fallback. 공식 완성 예시답안 연결 부족; AI 단계와 공식 해설을 구분 |
| G 상경 혼합형 E2E | PASS(서버) | 한양2026 Q1 Essay/Q2 Math 실제 완료, 시험 단위1개 소비, 두 결과 통합. 한 문항 checkpoint 시 전체 reserved 유지 관찰. 혼합형 전체 APP/WEB 화면·무료 사이클은 별도 미검증 |
| H 이용권·무료 재첨삭 | PASS | 자연계 paid1→free0→다음 견적1, 무료 정확히1회, paid/free 동일 요청 재전송 시 같은 run/원장 불변. 14일·베타 경계는 기존 SQL 검증 재사용 |
| I 인문논술 회귀 | PASS | WEB 전체 1586 PASS/기존4skip. 혼합형 Q1 실제 공식근거 피드백도 보존 |
| J Owner Preview 검수 | PARTIAL | Preview/실제 결과 제공. Owner의 이번 결과 검수는 아직 없음 |

## 실제 실행·이용권

한양2024 자연 오전 exam `b98fd0c9-8a84-5747-a35c-25755312aede`.

- WEB 사진 입력 Q1 `fd2de18a-0fdc-4f35-a44a-20e437308c99`, Q2 `14a521ba-9ae3-44df-9674-c6f6d27ca96c`.
- 새 유료 run `168093b9-59f3-4a26-8b19-a4348d909d32` (기존 G 무료 run의 다음 유료 사이클, submission_index3). Q1 `cf0c23fa-a3ea-41ac-bf57-30fd73bb7745`, Q2 `24fee771-ea23-4cb3-93cc-62f4aeada9a6` 모두 COMPLETED.
- 무료 run `9dd33da1-b2a8-4c46-b78c-80ea893046b9`, parent=위 유료 run. Q1 `fe9c590c-800b-4e6a-80b0-ff163eadc515`, Q2 `833869d1-a9c1-4531-a4e3-32e35dcb3449` 모두 COMPLETED/CORRECT/오류0.
- 무료 수정 입력 `4a100143-5055-41f4-9be0-3ab60298aea6`, `2c5de798-723b-4d09-bd1d-90d3256cd667`. 사진 없는 새 typed 수정이며 기존 원본은 이전 attempt에서 유지.
- 다음 견적은 submission_index5/1개. 무료 만료는 유료 완료+14일인 11/17; 이번 지급은 admin_grant여서 베타 일일 무료 회차가 아니다. 베타 종료 연장 없음.
- 혼합형 run `7fd28980-cf88-4382-baf9-4434ca7556b1`, exam `e8ea5bb3-0956-5fd6-b90e-4b7fb350b2f9`, 완료 결과2개, 무료 가능 true.

TEST 잔액0에서 기존 관리자 RPC로 **2개**를 idempotency key와 TASK16-I 사유를 남겨 지급했다. 새 금융 시스템/직접 원장행 조작 없음. 실제 원장: grant+2, 자연계 reserve1/consume1, 혼합 reserve1/consume1, 무료 추가 소비0. 최종 balance0/reserved0. 자연계 paid/free 동일 키 요청을 실제 RPC에 재전송해 run 동일 및 전체 원장행 불변 확인. 혼합형 실행 재개도 같은 요청키/run을 사용하여 중복 예약하지 않았다.

## OCR와 발견·수정한 입력 손실

최초 Q1 WEB 추출이 PROCESSING에 머물렀다. 원인 확정 없이 새 attempt를 만들지 않았고 lease 만료 후 같은 attempt로 복구했다. 성공 OCR은 Q1 16영역/Q2 15영역. 첫 요청의 Provider 실행/사용량은 확정할 수 없으며 성공 호출0이라고 주장하지 않는다. 복구 중 Playwright JSON storageState가 File을 보존하지 못한 route error는 테스트 하네스 문제로, 원본 파일을 다시 선택하여 기존 요청에 연결했다. 이를 제품 IndexedDB 결함으로 단정하지 않는다.

Q1 새 결과에서도 e^{-x}→e^x, 도함수 부호, 교점 수, 일반항/급수 소실이 재현됐다. Q2 주요 수치 표는 C 검수본과 일치했으나 k/l·U 식별자 오독이 있었다. 독립 전수 정답 전사가 없으므로 정확도 %를 산출하지 않는다.

**새 P0 발견:** Q2 OCR raw_text에는 `25<n<100 (최대값 99, 최소값 26)`이 있었지만 normalized_math에는 끝의 답안 문장이 없었다. 기존 확인 기본값이 normalized_math였으므로 실제 평가에는 25<n<100만 제출되어 CONCLUSION 오류가 생성됐다. 이는 모델이 제출에 없는 값을 무시한 것이 아니라 **클라이언트 확인 입력의 소실**이다. 원문/전사/평가를 비교하지 않았다면 우수답안 오답 판정으로 오인할 수 있었다.

수정:

- WEB 회차 입력에 기존 `RegionConfirmation`/원본 영역 컴포넌트 재사용. 모든 후보를 개별 확인, 편집 시 확인 취소, 빈 값/미확정 내용 최종 확정 차단. 사진 연결은 실제 artifact.position만 사용.
- APP/WEB 확인 기본값을 **전체 raw_text 우선**으로 바꿔 수식 정규화에서 빠진 서술/최종 답을 보존한다. normalized_math와 원래 후보는 DB에 유지한다.
- 실제 나온 `[판독 불명]`, `[판독 불확실: x 또는 -x]`, `[인식 불가]`를 기존 UNCERTAIN 차단에 추가. WEB Worker 진입과 Native 확인에도 적용.
- 무료 수정 답안에 최댓값99/최솟값26을 명시하여 Q2 CORRECT/오류0 확인. 자동 OCR 교정으로 계산하지 않는다.

Q1은 C 검수 전사를 위치별로 재사용하되 불명확했던 지수/일반항 등 order10/12/15는 검증자가 직접 작성한 수정 풀이로 비공개 provenance를 남겼다. 원문 기호가 원래 그렇게 쓰였다고 확정하지 않았다. 최초 Q1 CORRECT는 이 수정본 평가다.

## 품질 유형별 증거

| 유형 | 근거 |
|---|---|
| 정답 | 새 자연계 수정 Q1/Q2 CORRECT, C/G 정상 사례 재사용 |
| 계산 오류 | 새 혼합형 Q2의 1,197,900+196,000→1,393,000 오류를 CALCULATION ROOT로 정확히 분류 |
| 개념 오류 | C의 2026 상경 Q2 THEOREM_MISUSE 실제 결과 재사용. 2024 자연 별도 개념 오류 실호출 아님 |
| 논리 비약 | 자연계 독립 대조군 미검증. 인문 Q1 논증 부족 성공과 혼동하지 않음 |
| 미완성 | 이번 Q2 결론값 소실 입력의 CONCLUSION 판정 및 수정 후 해소 확인. 손글씨 원본이 미완성인 사례는 아님 |
| 대안 풀이 | C 2024 자연 Q2 독립성/조건부 합산 풀이 수용 결과 재사용 |
| 다수 오류 | 실제 5개 이상 오류 표본과 중요도 순위 미검증. SQL 최대5개 제한과 구분 |

혼합 Q1은 합성 검수 답안의 A/B 차이점 유추 평가 누락 및 죽이는 행위/구조 실패 구별을 공식근거와 함께 지적했다. Math와 인문을 같은 엔진으로 처리하지 않는다. 자연계 safe projection의 기본 개념·힌트는 여전히 일반적인 동치변형/조건 점검 수준이며, ROOT+MATERIAL 후 UUID 순서 문제도 남는다.

## 공개·시각화·교차 플랫폼

실제 WEB Q2 read/hint 응답은 full_solution 없음, 명시 reveal 후만 있음. 힌트1/2·공개 이력이 저장되고 Native에서 재조회됐다. 새 무료 결과도 History 재조회와 명시 공개 검사. 공개 전 Provider 원시 결과로 fallback하지 않는다.

실제 bbox `{x:.559,y:.813,width:.367,height:.06}`이 신규 Q2 원본 하단 마지막 결론 영역과 연결됨을 브라우저/스크린샷에서 확인했다. 이 과제는 전사 소실에서 발생했으므로 원본 자체의 수학 오류라고 보고하지 않는다.

무료 Q2 해설 렌더에서 3개 수식 성공, `b-a=5·2/√n=10/√n, d-c=3·2/√n=6/√n`은 KaTeX fallback1개. 원문 보존/오류 표시 정상이나 모범답안 수준 완성은 아니다. 기존 분수/지수/적분/행렬 fixture PASS와 실제 전 응답 품질을 구분한다.

Simulator는 WEB paid Q1/Q2 결과·개념·힌트·History를 실제 Native 화면으로 읽고, WEB free 입력의 텍스트 일치/완료·무료0·parent 연결 및 원본 bytes SHA-256 일치를 검증했다. APP→WEB은 H의 실제 자료 조회를 재사용했다. 새 APP 제출 Provider 재호출 없음.

## TEST 설정과 호출 구분

- Pages 새 `ESSAY_COMMERCE_RUNTIME_TEST_ENABLED=true`: 정확한 canonical TEST 호스트+TEST DB+대표 상경 exam에만 적용. 기존 `ESSAY_EXAM_RUNTIME_ENABLED=false` 유지하므로 운영/다른 시험의 hold를 풀지 않는다.
- Native mixed `/api/essay/exam`은 같은 TEST flag와 canonical POST+Bearer에만 접속 gate를 통과하고 실제 gateway의 JWT/owner/allowlist 검사를 그대로 받는다. 익명/다른호스트/GET 차단 회귀.
- TEST Worker의 `ESSAY_EXECUTION_ENABLED=false`가 남아 있어 처음 예약 후 dispatch가 진행되지 않았다. secret put으로 plain binding 교체 시도는 Cloudflare10053으로 거절됐고 변경되지 않았다. 이후 공식 settings API의 `inherit` binding 방식으로 **해당 plain flag만 true**, 나머지 모든 binding을 상속해 실제 완료했다. Secret 가림값을 저장하거나 Provider 키를 교체하지 않았다. [Cloudflare 설정 계약](https://developers.cloudflare.com/api/resources/workers/subresources/scripts/subresources/script_and_version_settings/methods/edit/).
- 완료한 Provider 작업: OCR2, 자연계 Math 최초2+무료2, 혼합 Math1+Essay 생성1+독립검수1. 첫 OCR 불명 요청의 사용량/실청구는 별도 미확정. 새 결제0, 운영 Provider0.
- 로그에서 확인한 성공 OCR 토큰: 2,625+5,897 및 2,631+5,039. 혼합 Math17,117, Essay 생성17,734. 모든 호출의 사용량을 합산한 값/정확한 비용은 확보하지 못했으므로 임의 총비용 없음. Provider 성공과 이용권2개 소비는 별개다.

## 테스트·파일·배포

WEB 전체 **1586 PASS/기존4skip**, 222파일 PASS/3skip. 최종 입력 영향24PASS, 혼합 gateway/gate47PASS, TypeScript·build PASS. 기존 hook dependency lint 경고2개는 회차 컴포넌트에 남아 있으며 ESLint 오류0. Native widget9PASS, Simulator실네트워크 PASS, analyze PASS. Wiki handoff와 diff 검사는 최종 커밋 전 수행한다.

WEB 변경: `src/components/math-release/exam-session-submit.tsx`/test, `src/components/math-input/math-input-flow.tsx`/test, `src/lib/math-input/recognition-safety.ts`/test, `functions/api/essay/exam.ts`, `src/lib/essay-runtime/server/exam-endpoint.test.ts`, `cloudflare/test-preview-access.ts`/test.
APP 변경: `math_mobile/math_recognition_panel.dart`, `math_formula_editor.dart`, `test/task16f_mobile_test.dart`, `integration_test/task16g_saved_history_test.dart`, Wiki.

WEB commits `cd05757`(영역 확인), `f00501b`(TEST 혼합 경계), **`e3efa29`**(전체 전사/미확정 표식). 배포 **`e22dd7a8`**, [TEST Preview](https://legendstudy-task16b.pages.dev/math-review/?evaluation=833869d1-a9c1-4531-a4e3-32e35dcb3449) / [고정 배포](https://e22dd7a8.legendstudy-task16b.pages.dev).

비공개 증거 `/Users/woojinchang/.codex/legendstudy-task16i-test/`: `web-photo-retry.json`, `input-1/2.json`, `reviewed-edits.json`, `web-paid-result.json`, `web-free-result.json`, `web-final-read.json`, `idempotency.json`, `final-verification.private.json`, `mixed-raw.private.json`, `native-cross-captures/`. 원본/인증/원시 답안 Git 제외.
스크린샷 `web-photo-review.png`, `web-confirmed-before-evaluation.png`, `live-region-hints.png`, `web-paid-result.png`, `web-free-result.png`, `web-final-solution-history.png`.

## 남은 P0와 재개

1. Q1 실제 손글씨 부호·지수·일반항 OCR 실패와 추출 PROCESSING 복구의 신뢰성. 원문 대조 없이 자동 정오 확정 금지.
2. Raw/normalized 전사 보존 수정은 회귀 PASS지만, 신규 전체 자연스러운 WEB 사진 확인 흐름에서 원문 우선 기본값을 추가 검수할 것. 기존 확정/평가 기록을 소급 수정하지 말 것.
3. 문항별 공식 세부 기준·개념·수식 중심 힌트, 다수 오류의 학습 중요도 순위, 논리비약 대조군 검증.
4. 유니코드 수식 fallback 및 공식 완성 해설 연결. 없는 공식 답안/점수 생성 금지.
5. WEB 제출 전 이미지 보정·fresh 시험 선택부터의 연속 E2E, 혼합형 전체 APP/WEB 화면·무료 재첨삭 검증.
6. Owner Preview 검수. 현재 TEST 잔액0/예약0이며 결과 열람 가능. 운영 활성화 별도 승인 전 금지.
