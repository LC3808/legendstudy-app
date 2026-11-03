# TASK16-K — 수리·상경 베타 활성화 준비

2026-11-03. Owner는 다음 WEB/APP 업데이트에서 수리·상경 베타를 제공하도록 준비를 승인했다. **운영 활성화는 별도 최종 승인 전 HOLD.** 기존 [J](task16j-beta-release-readiness-20261103.md), [I 실제 E2E](task16i-integration-quality-20261103.md), [I Owner 경로](task16i-owner-review-20261103.md), [H](task16h-web-math-ux-20261103.md), [G](task16g-learning-loop-20261102.md), [F](task16f-native-math-ux-20261102.md), [E](task16e-recognition-disclosure-p0-20261102.md), [C 원본 검수](task16c-hanyang2024-handwriting-validation-20261102.md)를 재사용한다. 새로운 엔진·시험 DB·Credit/History 시스템을 만들지 않는다.

## 공개 제한과 기존 데이터 — Owner 정정 반영

베타 scope의 수리0은 **종전 공개 정책**이며 데이터 부재가 아니다. J의 ‘자연 대표 시험 최소 등록 필요’는 신규 데이터 구축 지시로 사용하지 않는다. 기존 identity·공식자료·Registry 연결을 먼저 확인한다.

운영 읽기 전용 확인: 기존363시험/1,014문항. Math set 존재 또는 시험명/계열의 상경·자연·수리·경영·경제를 기준으로 추린143행은 **상경·사회 전체 시험 수가 아닌 이번 감사 후보 집합**이다. [시험별 목록 CSV](task16k-registry-audit-20261103.csv)에 기존 ID와 판정을 기록했다.

- 52 Math sets: 50개는 기존 Essay 문항 연결·runtime policy·공식 SCORING hash가 있다. 50개 Evidence Package의 runtimeApproval=APPROVED이고 policy/package digest가 일치한다. review.state=NEEDS_REVIEW만 보고 공식자료가 없다고 판단하지 않는다. 레거시 evidence_links=0도 별도 package 부재의 증거가 아니다.
- 나머지 중 건국2026자연 `25dc068b-4672-56e1-b8df-08ee8800e2f6`는 기존 standalone Math·공식 QUESTION/INTENT/SCORING/SOLUTION hash가 있으나 Essay 문항 binding/common session 적용 검토가 필요하다. 기존 건국 검증 PASS는 유지한다.
- `a1050000-0000-4000-8000-000000000002`는 synthetic fixture로 학생 베타 대상에서 제외한다.
- 기존 runtime policy61 + standalone1 = **NEEDS_REVIEW62**. 현재 감사한 실행 adapter의 policy가 없는80 + synthetic1 = **BLOCKED81**. ‘BLOCKED’는 현 실행 연결의 차단이며 원본 시험이 없다는 뜻이 아니다. 모든 후보를 실제 제출한 것으로 보고하지 않는다.
- 운영 READY0: 공통 신규 RPC/공개·반복 계약/공개 scope/실제 기기 제출·품질 gate가 남는다. **TEST 기능 READY**는 자연2024오전 Q1/Q2와 상경2026 Q1 Essay/Q2 Math 두 대표 시험이다. 기능 READY와 품질/운영 승인은 구분한다.
- 한양2026상경 `e8ea5bb3-0956-5fd6-b90e-4b7fb350b2f9`는 운영의 기존2문항·Math leaf1·공식 Package를 재사용한다. TEST 자연2024오전 `b98fd0c9-8a84-5747-a35c-25755312aede`의 **동일 ID는 운영에 없으며**, 운영의2024자연 모의는 다른 시험이다. 원본/수집 이력과 identity를 대조해야 하며 임의 복제나 모의시험 ID 대체 금지.

## 변경한 학생 화면

WEB `MathDocument`는 기존 KaTeX 위에 표시만 담당한다. 명시 LaTeX/구분자 없는 수식·한국어 결론을 보존하고, 확정 raw_text를 normalized_math보다 우선한다. 원문 값을 덮어쓰거나 식을 계산·추정하지 않는다. 긴 식은 독립 가로 스크롤, 실패 시 원문과 표시 오류 안내. Q2처럼 바깥 `|` 없는 명시 구분 표도 행·열로 표시하며 누락 셀/공백 정렬을 추정하지 않는다. 그래프·도형은 원본 영역 비교를 유지한다.

OCR 확인은 정돈된 답안을 기본으로, ‘원본 이미지와 비교’/‘최초 인식 원문’/‘전사 내용 수정’을 구분한다. 원본 bounding box는 기존 값만 사용한다. 미확정 영역/UNCERTAIN은 기존 확인 gate를 통과해야 한다. 입력 교체 후 ‘입력 다시 준비’로 새 입력을 만들며 과거 원본/인식/확정본은 보존한다. 서버 공개·확인·평가 엔진은 변경하지 않았다.

WEB 사진 회전·자르기는 명시 적용 시 별도 PNG로 생성한다. 취소는 원본 File을 유지하고, 현재 화면에서 ‘보정 전 원본 복원’을 제공한다. 업로드된 보정본은 기존 불변 evidence가 된다. **보정 전 사진의 복원 연결은 화면 메모리 범위이며 새로고침 후 서버에서 복구하는 계약은 아직 없다.** 원본 로컬 파일은 수정하지 않는다. Native의 기존 비파괴 보정 UI를 재사용한다.

Native `MathStudentText`도 원문 수식·혼합 문장·명시 표 표시를 개선했다. Academic Purple/화면 구조를 유지한다. 별도 bundle `com.legendstudy.app.task16f` / LS Math TEST, Profile 빌드만 기기에 설치한다. APP1.0.1(41) 릴리스 브랜치·운영 앱은 변경하지 않는다.

## 실제 검증 및 증거

K TEST 배포/신규 평가와 최종 검증 결과는 아래 마감 기록으로 갱신한다. 실제 Provider 호출·잔액은 코드 테스트와 별도로 기록한다. 기존 I 혼합형2문항 완료/1이용권 차감/부분 완료 차단·원장 중복 방지·History PASS는 재사용한다. 새 호출하지 않은 항목을 K 신규 실험으로 세지 않는다.

실제 iPhone12ProMax Profile/USB 인증으로 저장 Q1/Q2 결과·힌트·History와 WEB 원본 hash/수정 답안/공개상태·무료 상태를 확인했다. 이 검증은 신규 촬영이나 OS Photos 선택을 대체하지 않는다. 자동 TEST 계정 전달은 paired USB의127.0.0.1 일회 채널을 사용하며 키/암호는 빌드/Git/보고서에 포함하지 않는다.

신규 WEB 사진: 기존 실물 답안 Q1/Q2로24영역, 확인 전 평가 차단. 기존 검수본과 대조해18영역을 수정, 그중 Q1의2영역은 명시 TEST 학생 수정 풀이로 기록했다. 원본에서 불명확한 지수/일반항을 정확한 전사라고 확정한 것이 아니다. Q1의 e^{-x}→e^{x}, 이차식 계수/αβ 오독, Q2의 l→q 및 표의12/13 위치 오독이 남는다. **OCR 정확도 FAIL/PARTIAL 유지.** 수식 표시 개선을 OCR 정확도 개선으로 계산하지 않는다.

증거는 로컬 비공개 `/Users/woojinchang/.codex/legendstudy-task16k-test/`에 보관한다. 원본 이미지·학생 답안·세션은 Git 제외. 공개 가능한 Registry 메타데이터만 위 CSV에 기록했다.

## 운영 적용 준비 — 실행하지 않은 항목

| 경계 | 기존 상태 / 필요한 작업 |
|---|---|
| WEB 이용불가 표시 | `source-exam-selection.tsx` naturalHeld, 공개 상태/Registry 필터. TEST 한정 대표 예외를 운영 전체 허용으로 복사하지 않는다. 기존 인문 공개 목록 보존 |
| APP 실행 | 기존 catalog/preflight/Math session 경로, TEST public config. 운영 계약 적용 후 별도 새 APP 릴리스 후보 빌드·실기기 검수 필요 |
| Registry | 기존363시험/1014문항·50개 연결 Math 재사용. READY scope만 승인 manifest로 고정; 없는 새 DB/복제 seed 작성 금지 |
| Provider | 기존 Math/Essay 분리 Secret·runtime flag·worker allowlist 유지. 운영 math_private.evaluation_admission은 runtime_control 외에 기존 leaf `3bab07d3-c047-53c2-89ad-9fa20ec7b3f3` 제한이 있어 enabled=true만으로 전체 사용 불가 |
| RPC/공개 | J에서 실측한 미설치 `math_coaching`, `essay_math_coaching`, `math_session_quote/continue` 및 이벤트·공개 projection 증분 승격. 기존 raw 응답/History의 조기 공개 차단 포함 |
| Credit/Ledger | 기존 reserve/settle/release/원장 보존. 운영 continuous_cycles=false와 TEST true 차이. 1/0/1/0,14일,중복·동시·실패 복구 검증 후 순차 적용 |
| 베타 | 운영 하루1/00KST/이월0/11월11일00KST 종료/기존160대상 보존. Math/혼합의 승인 공개 scope와 일일 beta eligibility 연결을 TEST에서 검증해야 함. TEST admin grant 이용권을 일일 무료 지급 PASS로 계산하지 않음 |
| Storage | 기존 비공개 bucket·owner/서명 조회·원본 hash 유지. TEST 학생 원본을 운영에 복사하지 않음 |
| 배포/복구 | 기존 운영 LAB/인문 무변경. 새 제출만 중지 가능한 flag/허용 scope rollback 준비, 완료 결과·원장·History 삭제 금지 |

기존 후보 SQL: F `001_coaching.sql`/`002_disclosure_boundary.sql`, G `loop.sql`/`mixed_disclosure.sql`/`mixed_learning.sql`/`coaching_cycles.sql`. 운영에는 이미 Math/session/finance가 있으므로 `install.test.sql` 전체 실행 금지. **현재 운영 함수 hash/ACL에 맞춘 production-ready 증분 migration·복구 SQL 완성은 남은 차단 요소**다. 파일 존재를 배포로 보고하지 않는다.

## 보존 검토 7답변

1. 원본 사진/최초 인식/학생 확정/AI평가는 서로 다른 사실로 유지한다.
2. 공식 시험·문항 ID와 Package/hash를 재사용한다.
3. 재작성·재인식은 새 attempt, 완료된 기록 UPDATE 없음.
4. 동일 TEST student와 기존 History를 유지하고 신규 계정/이용권 시스템을 만들지 않는다.
5. 학습 평가를 합격·입시 결과로 해석하지 않는다.
6. 비공개 Storage와 기존 삭제/접근 경계를 보존, Git에 개인정보/원본/Secret 없음.
7. 화면은 원문 projection이며 OCR/평가 판단을 사실로 소급 덮어쓰지 않는다. 보정 전 파일 서버 보존은 미구현으로 구분한다.

## Owner 검수 경로

[전용 TEST](https://legendstudy-task16b.pages.dev)만 사용. [기존 안전한 접속 도우미](task16j-beta-release-readiness-20261103.md#owner-접근-복구-af)와 [실제 결과 경로](task16i-owner-review-20261103.md)를 유지한다. 대학 한양 →2024수시 자연/오전 또는2026수시 상경 → 새 답안. 신규 사진·확인 후 평가와 기존 결과 재작성은 분리된 경로다. 운영 URL에서 검수하지 않는다.

## K 마감 검증 기록

- 신규 WEB 최초 run `0e884f90-b54b-407b-b913-14e49cd23f95`: Q1 `480055c9-1966-4067-9e78-f6792cccb360`, Q2 `341630f9-6d29-4271-b558-7f3fb9d9821c`, 두 문항 COMPLETED. 검수자가 수정한 답안을 기존 Provider가 CORRECT/REASONING_SUFFICIENT로 인정했다. 원본 자동 인식의 정확도 판정이 아니다.
- 무료 run `20ff28c3-3a18-4bc0-a5a1-faf6ffab5513`: 기존 WEB 재작성 경로에서 이전 답안을 불러오고 Q2 결론을 보완하여 제출, 두 문항 COMPLETED, credits_required0. 최초1/무료0, 다음 견적1(index3), 무료 재사용 불가. TEST 원장 reserve1/consume1, 최종 잔액1·예약0. 같은 키 두 회차 재전송 시 동일 run 반환·원장 전체 불변.
- 해당 TEST grant는 beta 일일 지급이 아니므로 free_expires_at이11/17(14일)이다. 이를11/11 베타 종료 경계 PASS로 오인하지 않는다. beta 종료·일일 지급 연결은 미검증 P0로 남는다.
- 실제 요청6회: 사진 OCR2 + 최초 평가2 + 무료 평가2. 별도 재평가 엔진/Provider 설정 변경0. 실행 중 재배포나 표시 검사 때문에 이미 성공한 Provider를 재호출하지 않았다. 기존 응답 계약은 토큰 사용량을 DB 결과에 보존하지 않아 이번 정확 비용을 임의 산출하지 않는다.
- 원본 대조/수정 확인 → 최초/무료 평가 → 결과/History 재조회와 명시 전체 풀이 공개를 실제 TEST에서 확인. Q2 공개 전 `disclosed=false`, `full_solution` 없음; reveal 후 true+full_solution. 이번 정답 사례는 개선 과제 원본 영역0으로, 오류 영역 연결 PASS는 기존 I의 실제 오류 사례를 재사용한다. 과제가 없는 것을 임의 오류로 보충하지 않는다.
- WEB 실제 1440px3열/900px2열/390px1열, 문서 body 가로 넘침0. 전체 해설의 명시 `√n` 원문2개가 renderer에서 실패한 것을 발견하여 display-only `\sqrt{n}`로 처리, 값·부호·식 구조는 변경하지 않는다. 일반적인 불명확 OCR 구조를 자동 보완하는 기능이 아니다.
- 실기기: iPhone12ProMax/USB/Profile, 동일 TEST 계정·실제 저장 Q1/Q2·웹 수정 답안·원본 SHA256·공개/무료/History 상태 검사 PASS, 화면5개. Provider0·새 제출0. 마지막 테스트 종료 시 도구의 stop-app 실패 로그는 테스트 실패가 아니며 이어 별도 정상 앱 설치/launch 성공. 실제 카메라/OS Photos/새 제출→재첨삭을 한 번에 검증한 것은 아니다.
- Owner용 정상 `lib/main.dart` Profile 앱을 같은 TEST bundle로 설치·실행했다. USB에서 인증한 TEST session의 일반 앱 인계를 시도했으나 Owner가 로그인 오류를 보고했다. 실제 AppBootstrap/SDK 로그인과 재실행 유지 검증을 추가한다. 로그인 우회/새 Auth 계정/비밀번호 변경 없음. Owner 사진 선택·촬영·보정 확인을 요청했다.
- 혼합형은 기존 I 한양2026상경 실제 Essay+Math run `7fd28980-cf88-4382-baf9-4434ca7556b1` completed/두 문항/시험1이용권·부분완료 차단 증거를 재사용하고 조회했다. 답안은 합성 검수본이며 실제 합격자 상경 답안이 아니다. 새 혼합형 무료 전체 UI/실기기 E2E는 미완료.

검사: WEB 전체 회귀 결과·Native13검사·분석·build·Wiki handoff는 최종 Git 기록과 함께 확인한다. 브라우저 Canvas 실제 픽셀 검사에서90°회전+우측상단crop 결과1×2px의 예상 색상 일치, 원본 bytes 불변. 코드 mock을 실제 사진 OCR 검사로 계산하지 않는다.

전체 boundary 검사에는 기존 `admin-data-table.tsx`의 `url.searchParams.delete()`를 DB write로 잡는 오탐1개가 있다. 해당 파일과 감사 스크립트는 J 기준 `b2e85be` 이후 변경0이며 이번 범위에서 관리자 기능을 수정하지 않았다. 이를 전체 검사 PASS로 숨기지 않는다.

### 출시 기준 A–J

| 항목 | 판정 | 범위 |
|---|---|---|
| A 정돈된 수학 답안 | PARTIAL | 대표 명시 LaTeX·표·루트·긴 식 표시 PASS, 불명확 OCR 표/수식의 완전 자동 구조화는 아님 |
| B OCR 확인·수정 | PARTIAL | 사용자 확인·수정·전사 보존 gate PASS, 실제 OCR 정확도·확인 부담은 P0 |
| C WEB 실제 E2E | PASS(TEST) | 이번 신규 사진2장·보정·OCR·수정·실평가·무료·History |
| D APP 실제 기기 E2E | PARTIAL | 실제 기기 저장 결과/힌트/History PASS, 촬영→신규 제출 전체 루프는 Owner 확인 대기 |
| E 상경 혼합형 | PARTIAL | 기존 실제2 Worker·시험1개·통합 결과 PASS 재사용, 신규 사진/무료·실기기 연속 미검증 |
| F 이용권·무료 | PARTIAL | 1/0/다음1·동일키 원장 불변. 운영과 같은 일일beta/종료 연결 미검증 |
| G History | PASS(TEST) | 저장/재조회/기존 APP↔WEB·실기기 동일 원본/수정본. 자연 목록 대학명 표시 누락 남음 |
| H 전체 해설 | PARTIAL | 공개 제어·대표 수식 표시 검사. 공식 모범답안 수준/모든 오류 유형 품질 미검증 |
| I 인문 회귀 | PASS(코드·기존 증거) | 기존 평가 엔진/운영 결과 변경0. 이번 운영 인문 Provider 재평가 없음 |
| J Owner 화면 검수 | PARTIAL | F 디자인 PASS 유지. K 신규 학습·사진/최종 품질 승인 대기 |

**운영 활성화 HOLD / 출시 판정 NOT_READY.** 남은 P0: 원본 OCR 의미 오류와 과도한 확인 부담, 실제 기기 신규 사진 전체 루프, 공식 기준별 힌트·완성 해설 품질, 혼합형 신규 무료 루프, 운영용 비파괴 증분 migration와 beta scope/일일 지급/종료 연결, 자연 대표 시험의 기존 Registry identity 대조, Owner 최종 검수. APP 신규 운영 build가 필요하며 TEST Profile 설치를 스토어 출시 후보 승인으로 보지 않는다.

### 최종 코드/TEST 배포와 변경 파일

WEB Git `e1e8095` (기능4830a91, 표/fallback fc9de05 포함), TEST deploy `c36d5cf1`. 실제 제출 검수는 [canonical TEST](https://legendstudy-task16b.pages.dev)를 사용한다. 해시 Preview는 환경 binding 차이 때문에 신규 제출 기준 URL로 사용하지 않는다.

WEB 변경: `math-display/math-document.tsx`/test, `math-display/math-text.tsx`, `math-input/photo-adjustment.tsx`/test, `math-input/math-input-flow.tsx`, `answer-image-input.tsx`, `math-learning/server-coaching.tsx`/`study-evidence.tsx`/`study-math.tsx`, `math-release/exam-session-submit.tsx`/`student-route.tsx`, `source-exam-writer.tsx` (모두 LAB `src/components/` 아래).

APP 변경: `lib/features/essay/math_text.dart`, `test/math_student_text_test.dart`, `test/task16f_mobile_test.dart`, TEST 전용 `integration_test/task16g_saved_history_test.dart`/`task16k_owner_login_test.dart`. Wiki: 본문·Registry CSV·index/current-status/decisions/log/J 정정. APP 구현 Git `5f9b962`, 실제 SDK 로그인 검증 추가 `7e2fc0c`. 후속 Wiki 커밋은 코드 변경 없이 마감 증거를 기록한다.

최종 WEB **1,599 PASS/4기존skip,224파일PASS/3skip**, Native **13 PASS**, 변경 Native analyze 오류0, WEB 타입/build/변경 renderer lint PASS. Canvas 실제 픽셀 및 iPhone 실제 저장 결과 PASS. Wiki link/routing검사 PASS, current-status12KB 미만. boundary 오탐1개는 위와 같이 별도 기록한다. 운영 SQL 쓰기/Secret 수정/운영 WEB 배포/APP 릴리스 변경0.

최신 Owner 조회: [K Q1](https://legendstudy-task16b.pages.dev/math-review/?evaluation=480055c9-1966-4067-9e78-f6792cccb360), [K Q2](https://legendstudy-task16b.pages.dev/math-review/?evaluation=341630f9-6d29-4271-b558-7f3fb9d9821c), [K 무료 재첨삭 회차](https://legendstudy-task16b.pages.dev/my/essays/result/?source=math&id=20ff28c3-3a18-4bc0-a5a1-faf6ffab5513), [기존 상경 통합](https://legendstudy-task16b.pages.dev/my/essays/result/?source=exam&id=7fd28980-cf88-4382-baf9-4434ca7556b1). 동일 TEST 계정 로그인 필요. 자동 평가가 좋은 답안으로 인정한 것과 Owner가 공식 기준별 품질을 승인한 것을 구분한다.

최종 배포 화면 재조회: 신규 무료 Q2 전체 해설 **수식11개/fallback0**, PC3열·태블릿2열·모바일1열/body 가로 넘침0, 상경 통합 결과 정상조회. `web-final-read.json`/`math-*-viewport.png`/`mixed-existing.png`, iPhone `device-captures/`를 Owner 증거로 제공한다. 최초 Playwright storageState 복원은 File이 직렬화되지 않아 실패했으며, 기존 작성 세션에 같은 사진을 다시 연결해 기존 OCR 결과를 조회한 후 진행했다. 이 과정에서 Provider 중복 호출/새 유료 회차 생성은 없었다.

Owner 로그인 장애 원인: Flutter drive의 기본 종료는 TEST 앱 **uninstall**을 수행한다. 서버 TEST 설정/계정은 정상이나 검사 후 설치한 일반 앱에는 삭제된 세션이 없었다. `--keep-app-running`으로 검사 종료 후 앱/데이터를 유지하고 실제 AppBootstrap/SDK 세션 저장을 검증한 뒤 일반 Profile 앱을 덮어 설치한다. 운영 Auth/비밀번호를 변경해서 해결하지 않는다.

로그인 복구 실측: 실제 AppBootstrap/Supabase SDK 로그인·TEST 저장소 assertion PASS. `--keep-app-running` 종료 후 TEST 앱 Preferences에 세션 존재, 정상 `lib/main.dart` Profile 덮어 설치·launch 후에도 같은 TEST 세션 보존 확인. 비밀번호/Auth 설정 변경0. `login-run-preserved.log`, `device-prefs-preserved/normal` 비공개 증거. 이전 `Failed to stop app` 로그 뒤 기본 drive가 uninstall했던 것이 원인이며 앱 로그인 기능의 실패로 일반화하지 않는다. Owner에게 무입력 홈 진입·카메라/Photos 확인을 다시 요청했다. 화면 검수 최종 PASS는 Owner 응답 전 보류.
