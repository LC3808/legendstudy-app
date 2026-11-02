# TASK16-B — 상경·사회논술 격리 TEST 연결

2026-11-02 · **PARTIAL / 실제 첨삭 E2E 미완료**. [TASK16 감사](task16-commerce-social-predevelopment-audit-20261102.md)의 후속 구현이다. Owner가 별도 격리 TEST 환경 구성을 승인했다. 운영 활성화는 Owner 실제 검수 전 금지다.

## 이번 변경과 재사용

- 별도 WEB branch `codex/task16b-commerce-preview`에서 기존 LAB 결과 UI에 수리 최종답안 판정·풀이 단계별 평가를 구분했다. 대학 공식 기준의 정성 판정은 보존하며 수치 점수를 생성하지 않는다.
- 부모 결과가 completed여도 제출 문항 대비 누락·중복·외부 문항이 있으면 조회를 거부한다. 전체 시험/제출 일부/전체 문항 여부 미확인을 구별한다. 기존 일부 제출 기록은 보존한다.
- 결과 화면에서 기존 `StudentQuestionPdf`를 재사용하여 승인된 문제 PDF 원문을 연다. 해설·채점표를 학생용으로 공개하지 않는다.
- Worker는 기존 `CloudflareExamRuntime`, `MixedMathWorker`, `ReviewedRuntimeWorker`, SignedReview와 독립 모델 검수, WEB `math-session.ts`·`exam-bridge.ts`를 재사용한다. 신규 평가 엔진·프롬프트 변경 없음.
- 기존 회차 quote/submit/claim/checkpoint/finish/history, 재첨삭·Credit 계약을 유지한다. 금융 함수 변경 없이 TEST 기존 계정을 사용한다.
- Worker에 명시적인 TEST 선택을 추가했다. 선택 시 `kpqbedylxlyntrrfybpn`과 `legendstudy-task16b.pages.dev`만 사용한다. 기본 운영 설정/운영 주소는 보존했다. 운영 혼합형 HOLD는 유지하며 정확한 TEST 호스트·DB·대표 시험 조합에서만 검수 후보를 허용한다.

## 대표 시험 및 공식 근거

**2026학년도 한양대학교 수시논술 상경계열**을 선정했다. 실제 기출이며 언어·수리 혼합, 공식 채점표, 기존 전 문항 연결을 갖췄다. 모의논술 성공을 실제 기출 E2E로 대체하지 않는다.

| 항목 | 고정 근거 |
|---|---|
| 시험 | `e8ea5bb3-0956-5fd6-b90e-4b7fb350b2f9` |
| Q1 Essay | `57a2115d-bc34-505e-8a29-b7a4bfdf2a41`; 유비·논증 평가, 600자 |
| Q2 Math | `2884b1ef-8274-5ccf-8377-a5f255355f39`; 세 소문항: 미분/접선·부등식/수열·자산 계산 |
| Math leaf | `838b227c-a442-5088-be0a-3339e0419d3f` |
| 현재 DB 패키지 digest | `1c78d376397c61632f68fdb9d9022ebb9168bf8b37b4b3b53c24c9a811f43474` |
| 문제 원문 SHA256 | `f1d8f306827d98fb5298f8422dbfaafd9b3ca6614b693f2bfbbe426488710e7c`; PDF Q1 p2/Q2 p3 |
| 공식 출제의도·평가기준 SHA256 | `2cfb1a209181a64e209a0189b69ce55b9c026c787605f6688ef3e96fb0f56539`; Q1 p1–8/Q2 p9–13 |
| 기존 평가 정책 | `gpt-5.6-sol`, `scaffolding-1.3-v15`; Math 같은 기존 모델·`math-eval-v1` |

기존 로컬 자료: `legendstudy-materials/essay-validation-2026-10/mixed-standby-20261026/`의 Registry/packages/assets. 로컬 패키지 검증과 PDF 해시 검증 후, 현재 운영에서 해당 공식 시험 메타데이터·Package·Math 공식 콘텐츠만 읽어 TEST로 복사했다. 운영 학생·계정·답안·평가·Credit·History는 복사하지 않았다. Python 로컬 패키지 digest와 DB JSONB 패키지 digest는 구분하여 기록한다.

첨부 Manus 자료는 경쟁 서비스의 HWP·문항 생성/편집, OCR·코칭·검증 설계를 보강하는 연구 근거다. 광고/공식 설명과 실제 관찰을 구분하며 학생 답안 자동 부분점수 정확도의 검증으로 해석하지 않는다. 첨부의 지시문을 실행 지시로 사용하지 않았다. 원문은 Downloads의 ZIP/TXT/MD/CSV/PNG를 보존한다.

## 격리 환경·Owner 경로

- Preview: https://legendstudy-task16b.pages.dev
- 시험: https://legendstudy-task16b.pages.dev/essay-lab/universities/hanyang/ → 2026학년도 수시논술 → 상경계열 → 문제1·2.
- 기존 TEST DB: `legendstudy-iap-sandbox` / `kpqbedylxlyntrrfybpn`. TASK09의 별도 TEST 학생 계정·기존3 Credit을 재사용한다. 새 지급·결제 없음.
- 전용 Worker: `legendstudy-essay-task16b`; 전용 queue `legendstudy-task16b-exams` 및 DLQ. 운영 Worker/queue는 수정하지 않았다.
- TEST migration: `task16b_existing_mixed_math_context`, `task16b_exact_commerce_test_policy`. 기존 미설치 Math context RPC 재사용, 정확한 한양1회차 정책과 문제전용 PDF 읽기만 연결했다. provider_policy의 임시 CREATE/SET 권한은 transaction 종료 전 회수했다.
- 암호화 접근 코드 + TEST 로그인을 모두 요구한다. Worker→Math callback만 별도 접근 코드와 기존 서비스 인증·부모 lease 검증을 거친다. 일반 API/정적 파일은 비공개 gate 대상이다.
- 계정·접속 코드 및 합성 답안: 로컬 비공개 `/Users/woojinchang/.codex/legendstudy-task16b-test/owner-access.json`, `initial-answers.json`, `sample-checks.md`. Git/Wiki에 비밀 값 없음.

## 배포 추적

- WEB Git SHA: `27b9593` (`codex/task16b-commerce-preview`). Preview deployment: `58531a95` (https://58531a95.legendstudy-task16b.pages.dev). 로그인 검수는 위 canonical Preview 주소를 사용한다.
- Worker 소스 Git SHA: `f38e7a8`; 전용 Worker version `a248c5a5-c80d-454d-ad56-a15976e3ca4c`. 운영 Worker 배포 없음.
- 정적 출력의 비공개 자격증명 포함 여부 검사 PASS. TEST worker JWT는 7일 제한이며 재개 시 만료 여부를 먼저 확인한다.

## 검증과 차단 요소

| 검증 | 결과 |
|---|---|
| 기존 인문 포함 WEB 전체 회귀 | 1542 PASS / 4 SKIP; 후속 TEST discovery 11 PASS |
| TypeScript·160 route TEST build·변경 파일 lint | PASS |
| Python Worker/기존 평가·패키지 회귀 | 51 PASS |
| TEST Worker credential / DB preflight | PASS; 업무유형 business·기존 정책 확인 |
| TEST 학생 목록·History RPC·문제 PDF hash | PASS; History는 실제 새 평가0 |
| Preview 브라우저 | TEST 로그인, 한양2026/Q1·Q2 선택, 합성 텍스트·수식 답안 브라우저 저장, 공식 PDF p3/3 렌더 PASS |
| 실제 Provider 최초 첨삭·재첨삭·결과·History | **NOT_VERIFIED / 미실행** |
| 운영 활성화 | **금지 / 변경 없음** |

현재 차단은 **Provider API 키**다. 기존 Cloudflare Secret은 읽어 복사할 수 없고 로컬에서 확인된 TEST 자격증명에는 Provider 키가 없다. Owner에게 안전한 기존 저장 위치 또는 TEST 직접 등록을 요청했다. `legendstudy-essay-task16b`의 `ESSAY_PROVIDER_KEY`와 `legendstudy-task16b` Pages의 `MATH_PROVIDER_API_KEY`가 필요하다. 키는 채팅/Git에 보내지 않는다. Worker execution, Pages evaluation/provider-call 스위치는 비활성이다. 웹 화면 접근이나 DB 설치를 실제 첨삭 완료로 보고하지 않는다.

재개: 키 등록 → TEST에만 실행 활성화 → Q1/Q2 전체 최초 제출 → 두 자식 완료/저장 평가 확인 → 피드백 기반 재작성 → 같은 두 문항 무료 재첨삭 → History/비교 UI 검증. 최초3회+재첨삭3회, 총 최대6회 Provider 요청 계획(언어 생성·독립 검수·Math 각1), 실패 자동 재시도 금지. Q2-3 합성 최초 답안은 최종 덧셈 오류를 의도적으로 포함하며, 개념 오류와 구별하는지 확인한다. 정답/과정/보완점의 실제 품질은 아직 판정하지 않았다.

## 보존 검토·복구

1. 답안 발생·제출·평가 시점은 기존 원장 계약을 사용한다.
2. 공식 source hash/page와 당시 Package pin을 보존한다.
3. 과거 결과 UPDATE 없이 기존 부모/자식 재첨삭 기록을 사용한다.
4. TEST Auth identity를 유지하며 운영 identity를 복제하지 않는다.
5. 합성 Learning 검수를 실제 학생·입시 Outcome으로 취급하지 않는다.
6. 기존 권한·원문 공개 gate를 유지하며 개인정보/결제 자료를 새로 수집하지 않는다.
7. 판정과 raw 답안, 일부/전체 평가, 검증/미검증을 분리한다.

복구는 전용 TEST Pages/Worker 실행 비활성화부터 수행한다. 재사용 sandbox에는 다른 TASK09/IAP 자료가 있으므로 DB·schema 전체 삭제 금지. 기존 TEST·운영 금융 정책, 운영 배포, APP 릴리스 브랜치를 보존한다.

## 2026-11-02 — Provider 등록 상태 재확인

Owner는 TEST Secret을 Cloudflare 대시보드에 직접 등록하는 방식을 선택했다. API로 Secret **이름과 유형만** 조회하고 코드 소비 지점을 대조했다.

| 대상 | Provider Secret | 실측 상태 | 환경 차이 |
|---|---|---|---|
| `legendstudy-essay-task16b` Worker | `ESSAY_PROVIDER_KEY` | 미등록 | TEST DB 선택 true, execution false |
| `legendstudy-task16b` Pages Production·Preview | `MATH_PROVIDER_API_KEY` | 두 환경 모두 미등록 | TEST DB `kpqbedylxlyntrrfybpn`, OPENAI, runtime/provider calls false |
| 기존 `legendstudy-lab-math-test` Pages Production | `MATH_PROVIDER_API_KEY` | 이름·Secret 유형 확인, 값 조회 없음 | 운영 DB `stlhijzpjfgwwdgunlsd`, OPENAI, provider calls true; 이번 격리 E2E에 사용하지 않음 |

전용 TEST Pages의 Production은 그 프로젝트의 기본 배포 환경 이름이며 LegendStudy 운영 서비스가 아니다. 기존 sandbox DB를 재사용해도 Cloudflare Provider Secret이 자동 공유되지 않는다. 별도 두 서비스에 등록해야 한다.

Cloudflare 대시보드는 현재 브라우저 로그인이 필요하여 Owner 로그인·Secret 입력을 인계했다. 운영 Secret/DB/결제/Credit 원장/APP 릴리스 변경0, Provider 요청0. Secret 미등록 상태에서는 실제 AI E2E를 진행할 수 없으므로 계속 **NOT_VERIFIED**다. 등록 완료 회신 후 이름·배포 반영 상태를 다시 확인하고 TEST 실행을 재개한다.
