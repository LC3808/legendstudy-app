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

### Owner 실기기 사진 검수 후속 — 인문논술 자르기 방식 재사용

Owner가 iPhone 12 Pro Max에서 로그인 후 사진 **자르기까지 완료**했다고 확인했다. 이어 수리 자르기가 인문논술과 달라 불편하다고 지적했다. 이는 사진 입력 단계 확인이며 실제 기기 신규 평가·무료 재첨삭 전체 PASS를 의미하지 않는다.

- 원인: TASK16-F MathPhotoEditor는 가로/세로 RangeSlider, 기존 인문 APP은 이미지 위 모서리 핸들·영역 이동 방식이었다.
- 재사용 근거: `legendstudy-app-claude-20261028`의 `c61a898` (`answer_image_crop.dart`, 기존 §10 사진 크롭) 구현/테스트를 현재 개발 브랜치로 가져왔다. 기존 인문 화면 연결·운영 앱은 변경하지 않았다.
- Math는 같은 드래그 자르기 → 적용 → 미리보기 → 첨부 흐름을 사용한다. 기존 `transformMathPhoto` 회전/PNG 사본과 원본 복원을 유지하고 미리보기 원본 비교를 제공한다. 슬라이더 제거, 하단 버튼은 작은 폭에서 줄바꿈한다. 원본 메모리 보존/취소 시 기존 첨부 유지, 서버 저장 계약 불변. 재촬영은 기존 사진 입력 화면에서 진행한다.
- 회전/원본 복원 직후 적용 버튼이 layout 전 crop-null 상태를 읽어 비활성화되는 문제도 회귀 테스트로 확인 후 수정했다. 이미지 codec/picture 해제 및 좁은 사진의 드래그 최소 크기 경계도 보완했다.
- 코드 검사: crop 5 + 기존 Math UI/수학 문서 13 = **18 PASS**, 영향 4파일 analyze 0 issues. 기존 사진 루프 integration의 적용→첨부 셀렉터 갱신만 했으며 실제 Provider E2E는 재실행하지 않았다.
- 기존 한양 Q1 이미지로 428×926 로컬 Flutter 화면을 렌더링하여 드래그/미리보기를 검수했다. 이 캡처는 실기기 스크린샷 또는 새 OCR 검증으로 계산하지 않는다. 원본·캡처는 Git에 넣지 않았다.
- 별도 `com.legendstudy.app.task16f` Profile 빌드/설치/실행 PASS. 앱 삭제 없이 덮어 설치하여 기존 앱 데이터와 로그인 세션을 보존한다. 새 자르기 방식의 Owner 실기기 사용성 확인은 대기한다.
- 변경 파일: `lib/features/essay/answer_image_crop.dart`, `lib/features/essay/math_mobile/math_image_tools.dart`, `test/answer_image_crop_test.dart`, `integration_test/task16g_photo_loop_test.dart` 및 본문/current-status/log. Provider0, DB/Auth/Credit/Ledger/결제 변경0, WEB 변경0, APP1.0.1(41) 브랜치 변경0. 기존 F 디자인 유지 결정 및 K 실기기 검수의 좁은 사용성 보완이며 운영 HOLD는 유지한다.


## FINAL BETA READINESS — 11월 3일 실기기 차단 조사와 보완

Owner는 기존 WEB 전체 E2E·이용권/History와 iPhone 크롭 사용성 개선을 인정했다. 신규 디자인/엔진 개발 없이 실제 카메라 학습 루프와 운영 연결 차단을 마감한다. 이 승인은 운영 활성화 승인이 아니다.

### 실기기 OCR 차단: 화면 진입과 인식 성공을 구분

Owner의 ‘OCR 결과 화면까지 완료’ 보고 이후 서버를 대조한 결과, 실제로는 ‘저장한 답안 입력 확인’ → ‘처리 중’ → ‘처리 상태를 확인하지 못했어요’였다. Q1 두 장은 원본 왼쪽/오른쪽 촬영본이며 11,417,229 + 14,218,771 bytes로 개별 업로드는 PRESENT이나 합계25,636,000 bytes가 OCR 요청 합계20MiB 제한을 초과했다. 최초 실패 run은 INPUT_FAILED, Provider 이전 Storage 읽기 단계에서 중단했다. 원본/실패 기록은 보존했다.

- LAB `extractInBatches`: 원본 bytes를 축소하지 않고 기존 OCR Provider에 요청당20MiB 이하로 순차 전달. artifact ID·원본 순서를 유지하며 전부 성공한 경우에만 단일 extraction 결과를 finalize한다. 외부 artifact/사진 누락/부분 실패/합계100영역 초과는 완료로 취급하지 않는다. 이 수정은 OCR 모델 정확도 개선이 아니다.
- APP는 실패/처리 중/응답 불명을 구분하고 같은 attempt를 조회한다. 실패 시 저장 사진 재시도, 처리 중에는 중복 OCR/평가 요청을 하지 않는다. 응답 유실 후 실제 COMPLETED 결과가 있으면 해당 결과로 복구한다.
- `[분수식]`처럼 값이 빠진 OCR placeholder를 서버·Native 공통 불확실 입력으로 차단했다. 평범한 ‘분수식의 분모’ 문장은 차단하지 않는다. 기존 부호·지수·UNCERTAIN 확인 gate와 공개 정책 유지.
- 저장 Q1 실기기 사진에 대한 실제 재시도와 Owner 전사 확인은 아래 후속 결과로 기록한다. 카메라/크롭/업로드 확인을 전체 평가·무료 재첨삭 PASS로 확대하지 않는다.

### 혼합형 WEB 실제 무료 재첨삭

기존 paid run `7fd28980-cf88-4382-baf9-4434ca7556b1`을 재사용하여 브라우저에서 이전 답안 불러오기 → Q1 논증/Q2 계산 수정 → 두 문항 저장 → 무료 재첨삭 0 이용권 명시 확인 → 제출 → 두 결과/History 재조회를 실행했다. 새 run `dd5b335f-4a08-4025-993e-c4482b7bdbf2`, previous=기존 paid, submission_index2, 두 문항 COMPLETED. Q2 계산 합계1,393,900을 인정, 우선 과제0; Q1 수정된 논증 개선을 인정하되 글자 수 검토가 남는다. 일부 완료를 시험 전체 완료로 표시하지 않았다.

실제 Math/Essay/독립 검토 receipt가 있으며 무료 실행 이후 새 Credit 거래0, 가용 잔액1 유지. Math20,056tokens(17,187/2,869), Essay generation18,210tokens(16,187/2,023)은 확인된 두 호출만의 수치이며 독립 검토를 포함한 총량/금액이 아니다. 비용 NULL을0으로 보고하지 않는다. 합성 검수용 텍스트이며 실제 상경 합격자 손글씨 품질 검증으로 해석하지 않는다. 혼합형 실제 기기 전체 제출은 미완료다.

### 수식/원문 대조

실제 상경 결과의 `f′(t)` Unicode prime이 strict renderer에서 실패하는 문제를 표시 단계에서만 ASCII prime으로 정규화했다. 저장 답안/수치/공식은 변경하지 않는다. TEST 실제 혼합 결과17개 수식 fallback0, 공개 상태 재조회 유지. 기존 자연 Q1/Q2 무료 결과의 workspace 전체 수식74/39개 fallback0,390px 문서 가로 넘침0. 숫자는 해설만의 개수가 아니다. Q2 화면에서 원본/중앙/해설 3열과 수식 표시를 시각 확인했다.

OCR 원본 대조 결과는 여전히 PARTIAL/FAIL: Q1 e^{-x} 부호·이차식 계수, Q2 l/q 및 표의12/13 위치 오독. 독립 정답 전사 집합이 없어 정확도 %를 만들지 않는다. 정상 최종값만으로 중간표 OCR 정확성을 인정하지 않는다. 공식 예시답안이 연결되지 않은 공개 화면은 AI 평가 단계라고 표시하며 모범해설 수준 완성을 선언하지 않는다. Q1/Q2 저장 결과는 answer_status=CORRECT이나 review_status=HUMAN_REVIEW_REQUIRED이므로 화면의 확정 판정 보류는 서버 정책과 일치한다. 이를 자동 해제하지 않는다. 힌트의 구체성과 검수 보류 해소는 품질 gate다.

### 운영 읽기 전용 재확인과 적용 순서

운영363시험/1,014문항/52 Math set 유지. 대표 상경 기존2문항을 재사용한다. 한양2024자연 오전 TEST와 동일한 운영 ID는 없고 운영2024자연 모의는 별개다. `is_active=false`만으로 차단 원인을 단정하지 않는다(기존 인문에도 같은 값 존재). 실제 WEB launch hold/public scope/Worker admission을 함께 확인한다.

운영 미설치 RPC4개: `math_coaching`, `essay_math_coaching`, `math_session_quote`, `math_session_continue`. 기존 `authorize_billing`, `evaluation_admission`, `learning_eligibility`, `essay_exam_history`는 TEST와 함수 정의가 다르다. 운영 Provider enabled만으로 공개 가능하지 않으며 admission의 leaf 단일 제한이 남는다. TEST continuous_cycles=true/운영false, 별도 Provider Secret과 Storage/계정 경계 유지. 운영 beta는 활성 하루1·scope160·수리0·종료11/11 00KST이며 TEST admin grant는 이 정책 검증을 대체하지 않는다.

승인 전 준비/적용 순서:
1. 기존 함수/ACL·Registry·beta scope·Credit/History 보존 기준 확보, 실제 READY 시험의 ID·공식 Package manifest 확정.
2. F/G 후보를 운영 현황에 맞춘 비파괴 증분 migration/복구 SQL로 정리하고 격리 환경에서 검증. 전체 install/seed 실행 금지.
3. 새 제출 gate는 닫은 채 Provider/RPC/Storage·공개 응답과 기존 인문 회귀 확인.
4. TEST에서 베타 하루1/00KST/이월0/14일과11/11종료 경계 및1/0반복·동시 요청 검증.
5. WEB 후보 + 별도 APP 신규 업데이트 빌드의 실기기 전체 루프/Owner 화면 검수.
6. Owner 최종 승인 후 READY scope만 단계 활성화. 장애 시 새 제출 gate를 닫되 완료 결과·이용권 원장·History를 삭제하거나 재작성하지 않는다.

현 판정 **NOT_READY / 운영 HOLD**. 실기기 전사 확인 이후 평가·무료 재첨삭·History, OCR/수학적 피드백 품질, 운영 증분 계약/베타 연결/대표 자연 identity, Owner 최종 검수가 P0다. 운영 DB/Auth/Credit/Ledger/결제/WEB/APP1.0.1(41) 변경0.

검증: WEB1610 PASS/4skip, Native25 PASS. TEST LAB 배포 `1ee87b1` (`e0a5fb6a`), 이전 prime 표시 수정 `fe23ea3`. APP Git/분석/빌드·실기기 후속은 마감 기록으로 보완한다. 비공개 사진·세션·실행 증거는 `/Users/woojinchang/.codex/legendstudy-task16k-final-test/`에 두며 Git 제외.

실기기 복구 추가 발견: 첫 분할 OCR은 Provider2회(입력17,687/출력10,087,총27,774tokens) 응답 후 DB의 `math_extraction_regions_check`(bbox 영역 경계)에서23514로 거절됐다. 저장되지 않은 OCR을 성공으로 처리하지 않는다. TEST 로그로 원인을 확정했으며 같은 run을 기존 worker fail RPC로 INVALID_OUTPUT 처리했다(원본/실패 이력 보존, 평가0). bbox 양수·이미지 경계와 필드 검증을 저장 전에 추가하고 Provider에 extents 계약을 명시했다. 좌표를 임의 clipping/재생성하지 않는다. 확정 SQL validation reject만 실패 처리하며, 응답 유실은 완료 가능성이 있으므로 lease를 무조건 실패시키지 않는다. 해당 경계 테스트18 PASS, 서버66 PASS 후 추가3경계 PASS. 후속 TEST배포 `86f5fe5` / `c018c076`, 실제 재시도 결과는 이어 기록한다. Native 정적분석0문제/Profile build·동일 TEST bundle 업데이트 설치·launch 성공.


### 실기기 원본 OCR 복구 결과 (최종 조회)

동일 attempt의 새 후보 `8e7c62df-4d2f-43e2-a571-800b01eb1263`는 COMPLETED/52영역, 상태 CONFIRMATION_REQUIRED, 평가 가능false·평가 기록0. 원본 사진을 다시 촬영/업로드하거나 자동 확정하지 않았다. 호출 대기 연결은 timeout이었지만 서버는 성공해 동일 attempt 재조회로 복구했다. 모바일의 ‘저장한 답안 입력 확인’으로 결과를 재조회하도록 Owner에게 안내했으며 화면 도달/수정·평가 이후 전체 실기기 PASS는 아직 미확인이다. 이번 복구는 Q1의 좌우 사진이며 Q2 신규 실기기 촬영 완료로 계산하지 않는다.

최종 재시도2 Provider 호출: 입력18,007/출력9,586=27,593tokens. 앞선 bbox 실패까지 복구 과정 총4호출55,367tokens. 성공 인식은 재호출하지 않는다. 금액은 실제 과금 영수증/가격 검증 없이 추정하지 않는다.

실물과 비교한 신규 품질 문제:
- 영역6: 원본 -1/6을 -1/5로 인식. 자동 계산으로 원문을 고치지 않는다.
- 영역24: 왼쪽 하단 |f(x)|의 미분 불가 지점·이차식·접선 논증·그래프 설명이 크게 누락/오독됨. ‘최고차항 x⁴, x=6’ 전사는 원본과 다르다.
- 영역27/28: 적분 상한/α를 x로 읽는 문제.
- 영역45: `2n+?`처럼 미해결 기호를 포함. APP의 기존 ? 차단 유지, WEB/worker에서도 수학 연산식의 ?/？을 차단하도록 공통 인식 안전 규칙 보완(일반 한국어 질문의 ?는 허용).
- 지수 부호를 이번에 맞게 읽은 일부 구간이 있어도 전체 정확도 PASS로 확대하지 않는다. 작은/흐린 기호·원본 자체의 불명확성은 원본 대조/학생 수정 필요.

52영역 전체가 확인 대상으로 분류되어 학생 확인 부담도 남는다. 누락 문장을 수학적 정답에 맞춰 채워 넣거나 대리 확인하지 않았다. **기능 복구 PASS / 실제 OCR 품질 PARTIAL(오독 확인) / 실기기 전체 학습 루프 PARTIAL / 베타 NOT_READY**. 원본·후보·확정본 분리와 서버 차단 유지.

검사 최신: WEB 전체1617PASS/4skip(추가 수학 ? 방어3건은 별도83개 focused 검사에 포함), Native25PASS·분석0문제·Profile build/설치/launch PASS, Wiki handoff PASS. 운영 변경0. 실기기 화면 응답을 받으면 전사 확인 이후의 실제 평가/무료재첨삭/History를 이어서 검증한다.

마감 Git/Preview: Native 실행 코드 `e645c38`(동일 TEST bundle Profile 설치), LAB `968aa5f`·배포 `f9d0fdc7`, [격리 TEST](https://legendstudy-task16b.pages.dev). Native 사진 상태 복구25검사/분석0문제/Profile build/업데이트 설치·launch PASS; 마지막 WEB 수학 ? guard83개 focused 검사·빌드 PASS. 이전 전체1617PASS는 marker3건 추가 전 실행이라는 범위를 유지한다. 원본 학생 전사 확인/실기기 평가·재첨삭은 Owner 응답 대기이며 임의 진행하지 않는다.


### Owner 실기기 확인 — 인식 수식·원본 비교 화면 PASS

2026-11-03 Owner가 업데이트된 iPhone LS Math TEST에서 ‘저장한 답안 입력 확인’ 후 **인식 수식·원본 비교 화면이 열림**을 확인했다. 실제 카메라 촬영·크롭·업로드와 복구된 OCR 결과 조회까지의 구간을 PASS로 기록한다. 서버 복구 개입이 있었으므로 처음부터 중단 없는 전체 E2E 성공으로 확대하지 않는다. 전사 내용의 정확성/학생 수정/확정/평가·무료재첨삭·History는 별도 미완료다.

다음 실기기 확인은 영역6의 -1/5를 원본 -1/6으로 수정하여 표시 반영 여부를 확인하는 단계다. 다른 오독·누락이 남아 전체 확정/평가를 먼저 요청하지 않았다. 이번 확인 기록에서는 Provider 호출·TEST 평가·차감·운영 변경0.


### Owner 실기기 확인 — 전사 수정 표시 PASS

2026-11-03 Owner가 영역6의 r=-1/5를 원본의 r=-1/6으로 수정한 뒤 **인식 수식 화면에 수정값이 표시됨**을 확인했다. 전사 편집·수식 표시 반영 UI는 PASS다. 이는 로컬 수정 표시 확인이며, ‘답안 입력 완료’를 통한 서버 확정본 저장/재조회나 해당 사진의 평가 성공을 의미하지 않는다.

실기기 확인된 구간: 촬영 → 모서리 크롭 → 업로드 → 복구된 OCR 결과 조회 → 원본 비교 → 전사 일부 수정·표시. 남은 구간: 나머지 오독·누락 대조/수정 → 전체 전사 확정·저장 → 실제 평가 → 무료 재첨삭 → History. 영역24 풀이/그래프 설명 누락, 영역27/28 α/적분 구간, 영역45 미해결 기호 때문에 현재 전사를 그대로 확정해 평가하지 않는다. 52개 영역 확인 부담도 품질 P0로 유지한다. 기존 WEB/서버 평가·무료 재첨삭·History PASS는 재사용하며 이 사진의 실기기 전체 E2E로 대체 표기하지 않는다.

이번 작업은 Owner 검수 기록만 갱신. 코드/Provider/DB/평가/차감/배포 변경0. 베타 NOT_READY 및 운영 HOLD 유지.


### Owner 전사 편집 후 키보드 가림 — 닫기 동작 보완

Owner가 전사 수정 후 iOS 키보드가 닫히지 않아 화면 하단 확인 버튼을 볼 수 없다고 보고했다. 기존 MathFormulaEditor 입력창에 ‘키보드 닫기’ 버튼과 바깥 터치 해제를 추가했다. 수식 입력 도구는 TextFieldTapRegion으로 묶어 분수/지수 버튼 사용 시 불필요하게 키보드가 닫히지 않도록 했다. 공통 답안 확인 sheet와 standalone Math 목록은 드래그 시 키보드를 닫는다. 이 공통 sheet의 키보드 동작 외에 인문 입력/평가/과금 계약은 변경하지 않는다. Academic Purple 디자인/다중 행 입력은 유지한다.

기존 인식 확인 회귀 검사에 키보드 열림→닫기→수정값 유지→자동 확정0→명시 확인 가능을 추가했다. Native14검사 PASS·관련3파일 정적분석0문제. 서버/Provider/DB/차감/운영 변경0. 키보드 닫기는 로컬 수정값을 보존하지만, 현재 미확정 전사 편집의 앱 재시작 복구는 별도 미구현이다. Profile 빌드/TEST 설치 상태는 후속 기록으로 구분한다.

키보드 수정 검증 마감: Native14 + 기존 공통 catalog/답안 회귀19 =33 PASS, 정적분석0문제, iPhone용 TEST Profile 빌드 성공. 설치 파일 `/tmp/task16k-native-owner/Build/Products/Profile-iphoneos/Runner.app`의 TEST bundle을 확인한 뒤 업데이트한다. 설치 시 실행 중인 화면이 재시작되어 아직 서버에 확정하지 않은 영역6 편집은 재입력이 필요하다. 사진/기존 서버 후보·결과/계정 기록은 그대로다. 따라서 현재 편집을 닫아도 되는지 Owner에게 설치 시점을 확인하며, 설치 전 상태를 실기기 검수 PASS로 기록하지 않는다.


### Owner 승인 후 키보드 수정 TEST 설치

2026-11-03 Owner가 ‘지금 TEST 앱 업데이트’를 선택하여 미확정 편집 재입력이 필요한 점을 확인한 뒤 설치를 승인했다. 코드 `ff68fa6`의 Profile 빌드를 iPhone12ProMax에 기존 `com.legendstudy.app.task16f` bundle 업데이트로 설치하고 `devicectl` 실행 성공을 확인했다. uninstall/계정 변경/Provider 호출/서버 기록 변경/운영 릴리스 변경0. 원본 사진과 OCR 서버 결과를 다시 만들지 않았다. 키보드 닫기 버튼·스크롤 해제의 실제 기기 사용성은 Owner 재검수 대기이며 설치 성공과 구분한다.


### Owner 키보드 닫기·하단 확인 접근 PASS

2026-11-03 Owner가 iPhone LS Math TEST에서 **‘키보드가 닫히고 확인 버튼이 보임’**을 확인했다. 코드 ff68fa6의 전사 편집 키보드 닫기 및 하단 확인 버튼 접근 문제를 실기기 PASS로 마감한다. 버튼/바깥 터치/드래그 각각을 별도 실기기 검증한 것으로 확대하지 않는다.

이는 답안 전체 확정이나 평가 실행 승인이 아니다. 기존 전사 오독·누락, 미확정 편집의 재시작 복구, 전체 실기기 평가·무료 재첨삭·History 및 운영 연결 P0는 유지한다. 이번 Owner 확인 기록에서 Provider/평가/차감/운영 변경0.
