# TASK16-G — 학습 루프 통합

2026-11-02 시작 · 11/3 기능 E2E Owner PASS, 품질 PARTIAL/운영 HOLD. [품질 검수·H 준비](task16g-quality-closeout-task16h-preparation-20261103.md). 기준 Native SHA `787987f`.

Owner는 [TASK16-F](task16f-native-math-ux-20261102.md)의 모바일 UI/UX를 PASS 처리했다. Academic Purple과 승인 화면 구조를 유지하며 추가 디자인 개편은 하지 않는다. 이는 F 전체 완료·운영 활성화 승인이 아니다. [C](task16c-math-recognition-scaffolding-20261102.md)/[E](task16e-recognition-disclosure-p0-20261102.md)의 입력/공개 방어를 재사용한다.

## 시작 시 확인 (이후 설치 결과는 아래)

격리 TEST `kpqbedylxlyntrrfybpn` 읽기 확인: math_input/math_learning/essay_exam_history 존재, math_coaching 및 math_session_submit/read/history 없음. F SQL 파일 존재를 배포로 간주하지 않는다. 기존 LAB math-session 설치 코드와 기존 beta 정책을 재사용한다. 운영·릴리스 변경 금지.

## 보존 설계 검토

1. 제출/확인/평가/공개/차감 시각을 구별하고 서버 시각을 사용한다.
2. 기존 공식 PDF·Package·후보·학생 확인본·평가 원문을 보존한다.
3. 반복 첨삭은 새 attempt/run으로 이전 결과를 덮어쓰지 않는다. 기존 원장 행 수정/삭제 없음.
4. 동일 auth owner와 기존 lineage/parent/History ID를 유지한다.
5. 학습과 이용권 Decision을 구분하며 입시 Outcome으로 해석하지 않는다.
6. 기존 TEST 계정·비공개 자료·최소 권한을 재사용한다. 운영 학생 데이터를 복사하지 않고 Secret/원본 사진을 Git에 넣지 않는다.
7. 안전 projection과 원본 평가 결과를 구별하고 Provider 실제 호출/저장 결과 재생/코드 테스트를 따로 보고한다.

## 실행 순서

기존 회차 계약+반복 정책 로컬 검증 → 모든 학생 응답 공개 경계 → TEST 설치/소비자 연결 → 한양2024 Q1/Q2 실제 제출/재첨삭 → 혼합형·인문 회귀 → Owner Preview. 성공한 Provider 품질 검증은 반복하지 않고 통합에서 필요한 호출만 한다. 운영 적용은 별도 승인이다.

## 11월 3일 TEST 통합 검증 — 진행 중

운영과 분리된 `kpqbedylxlyntrrfybpn`에 session/loop/coaching/mixed disclosure/힌트 SQL을 적용했다. 자동 운영 migration이 아니라 `supabase/candidates/task16g_learning_loop/` 검토 패키지다. 기존 beta 함수 정의/ACL을 먼저 백업·해시 확인하고 설치했다. 신규 평가 엔진 없음.

- 공식 한양2024 자연 오전 exam `b98fd0c9-8a84-5747-a35c-25755312aede`, Q1/Q2 canonical FK 및 공식 문제/평가 기준 연결. 평가표 내부100/문제50의 차이는 보존하며 임의 점수 환산 안 함.
- 실제 답안 PNG 업로드와 hash 검증, C 저장 OCR 재생(신규 OCR 호출0), 학생 확인 RPC, 원본/확정 전사 분리. Q1 불명확 부분은 TEST 검증자 수정본으로 명시했으며 원문 판독 성공으로 세지 않는다.
- 실제 AI 최초 Q1/Q2 완료. Q1 판정 보류, Q2 정상. 두 문항 종료 후에만 전체 completed, 이용권1 consume. 공개 전 raw 응답 차단, 명시 reveal 후 History 기록.
- 수정 답안 Q1은 TEST 검증자가 작성한 완전 풀이, Q2는 기존 경계 오류 샘플. 무료 회차는 Q1 정상(11단계), Q2 부분 정답(9단계, root2/전파1). 공개 전 과제0/2, 개념/방향 힌트, 공개·History2회 확인. 실제 consume0.
- 3회차는 **동일 답안의 저장된 AI 결과를 Worker 계약으로 재생**하여 회차/원장만 검증. 신규 Provider 호출이 아니다. consume1, 4회차 무료 견적0 확인. 실제 원장 1→0→1, 기존 signup grant 외 지급 없음.
- 실제 Provider 요청8회: 최초2 성공, 무료 저장 실패2(풀이 단계 누락/힌트 분류 계약), 무료 timeout2, 수정 후 무료2 성공. 실패도 호출 수에 포함. 최초 실패 저장 전에는 전체 완료 표시 없음. 오류는 계약 검증·prompt·75초 Provider/80초 Worker 제한으로 수정했다. 별도 AI 품질 통과와 통합 검증을 구별한다.
- 확인된 토큰: 저장 실패2회 input8,370/output7,918; 최종 무료 성공2회 input8,714/output10,304. 최초2회/timeout2회 사용량 미확보. 전체 비용 확정 불가. Secret/Provider 원문 로그 없음.
- TEST 환경변수 전체 갱신 중 Secret 가림값으로 새 배포가503이 된 사고 발생. 직전 배포 rollback으로 즉시 복구, 보관된 TEST 전용키 재등록 및 Owner가 MATH_PROVIDER_API_KEY 재등록. 이후 연결/실제 무료 평가 성공. 운영 Secret 변경0. 앞으로 가림값을 포함한 환경 전체 PATCH 금지.
- 현재 TEST Preview: https://legendstudy-task16b.pages.dev (배포별 URL은 최종 보고에서 갱신). 전용 Math/Essay Provider 키 분리 유지. TEST의 Pages production은 운영 서비스가 아니다.

### 검증 수준과 남은 일

로컬 SQL: 기존 Math131 + 여섯 회차1/0 반복, 동시8요청1예약, 실패문항만 retry, frozen 문항,14일/beta 경계, owner ACL/rollback PASS. F coaching18 + mixed 공개/힌트/History/인문 byte-preservation PASS. Native 기존 전체1,141 PASS/7skip, WEB 기존 전체1,558 PASS/4skip. 후속 변경은 별도 회귀 중이며 최종 집계로 대체해야 한다.

Native TEST origin을 전용 Pages+DB 쌍에서만 허용했다. 공통 source writer의 재작성 draft key와 Math Session 이전 회차를 연결하고, History 코칭에서 전체 시험 재작성으로 이동한다. 디자인은 F 유지. WEB도 같은 math-coaching-v1로 read/hint/reveal하며 raw fallback 없음. TEST 한양2024 catalog/문제 PDF manifest와 exact-hash Storage read를 연결했다. 공식 채점 PDF와 학생 원본은 공개하지 않았다.

남은 검증: 신규 Native Profile 실기기 통합/전체17단계 UI, WEB 실제 화면 및 재작성 CTA, 혼합형 실제 Worker E2E(현재 SQL fixture 검증), 전체 회귀/배포 SHA, TEST 설치 패키지 문서/사후 권한검사. 아직 TASK16-G 전체 완료 아님. 운영 활성화는 별도 Owner 검수/승인 대상.

## Owner 접속 안내 정정 — 2026-11-03

Owner는 접속 코드를 전달받지 못했다고 확인했다. 이전에 전달되었다고 가정하지 않는다. TASK09의 private preview gate(`b971a65`, 2026-11-01)를 TASK16-B(`8ba5c96`, 2026-11-02)에 재사용했다. 실제 설정은 전용 Pages `TEST_PREVIEW_ACCESS_KEY`; Provider Secret과 다르다. TASK16-B 기존 `owner-access.json`의 `access_code`와 현재 배포의 코드 일치/HTTP303·검수 cookie 발행 확인. TASK09 코드는 서로 다르다. 코드 신규 생성·교체0.

Owner 절차: 로컬 `/Users/woojinchang/.codex/legendstudy-task16b-test/owner-access.json`(0600, Git 외부)의 `access_code`로 canonical TEST URL 입장 → 같은 파일의 `email`/`password`로 TEST 로그인 → 논술 LAB/한양2024 또는 MY 첨삭 기록. 접근 cookie는 8시간이며 다른 브라우저에는 공유되지 않는다. 운영 계정·원장을 연결하지 않는다. F standalone iPhone은 오프라인 UI 예제였으므로 인증이 없었고, G는 실제 제출/History 인증이 필요하다. 비공개 gate를 제거하지 않는다.

후속 검증: Native 전체1,142 PASS/7skip, WEB 전체1,563 PASS/4skip; 새 재작성 draft/Math독립 admission17검사 PASS. 혼합 History를 같은 시험·문항의 기존 bounded History 목록에 연결하는 SQL131+18검사 PASS 및 TEST 적용. iOS Profile compile/sign PASS, 신규 실제 화면 실기기 설치·Owner 로그인은 진행 중. TEST 질문 PDF의 인증 읽기/hash 및 catalog/manifest HTTP200 PASS.

사후 ACL: 새 공개 RPC anon/service deny, authenticated allow, raw 이전 함수 authenticated deny, 빈 search_path 확인. Supabase advisor의 private-table no-policy INFO는 의도된 직접 접근 차단이다. authenticated security-definer 경고는 owner검증 RPC별 검토 대상이다([설명](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)). 기존 TEST leaked-password protection 경고는 변경하지 않았다([설명](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)). 전체 보안 감사 통과로 확대 해석하지 않는다.

검수 체크포인트: Native 구현 `3cd7853`, WEB `9551f8f`; TEST 배포 https://43cdc8cf.legendstudy-task16b.pages.dev (canonical 로그인 주소 유지). iPhone12ProMax에 동일한 별도 bundle `com.legendstudy.app.task16f` Profile 설치 완료. 실행은 기기 잠금으로 거절되어 런타임 화면 PASS로 세지 않는다. Owner가 잠금 해제 후 LS Math TEST의 TEST 로그인을 진행해야 한다. 새 브라우저에서는 위 기존 접속 코드가 필요하며 코드 전달 누락을 정정했다. 전체 UI E2E·혼합형 실제 Provider 검증은 아직 미완료다.


## Mobile First 결정 및 작업 중단 체크포인트 — 2026-11-03

Owner 요청으로 오늘 작업을 정리하고 다음 작업은 Owner 재개 후 이어간다. 기기 잠금 해제 요청은 지금 수행할 필요 없다. 이 체크포인트에서 추가 Provider 호출·배포·DB 변경은 하지 않는다. TASK16-G 완료 또는 운영 활성화로 처리하지 않는다.

Owner 추가 결정은 기존 F 디자인 승인/G 통합 정책을 보완한다. **Mobile First**: 승인된 Academic Purple 유지 → 모바일 실제 학습 루프/E2E 우선 → G 완료 후 TASK16-H WEB UX. WEB은 모바일 확대가 아닌 원본 답안·첨삭 결과·기본 개념 동시 비교 PC 레이아웃, LaTeX 긴 수식·분수·행렬·적분 표시, 개선 과제와 원본 오류 위치 연결을 요구한다. PC 레이아웃 구현은 G 범위에서 제외한다. 공통 Backend·평가 결과·History·이용권·재첨삭 정책과 APP↔WEB 제출 조회 계약 정리는 G 범위다. [기존 결정](decisions.md#2026-11-02--task16-g-디자인-pass--학습-루프-통합).

재개 순서:
1. 현재 worktree/TEST 상태 확인 후 iPhone 12 Pro Max의 LS Math TEST 로그인·실제 화면 검증. 기존 성공 API/Provider 호출은 반복하지 않는다. 저장된 한양 Q1/Q2 결과부터 재사용한다.
2. History 재진입 시 원본 이미지 연결 보완 여부 확인. 현재 coaching의 `source_regions`에는 artifact/좌표가 있지만 Native History 진입은 원본 이미지 bytes를 넘기지 않는 것으로 확인했다. 기존 업로드/Storage 소유자 검증을 재사용하는 인증 조회 경로를 조사 중이며 해결 완료로 표시하지 않는다.
3. 실제 모바일 전사 확인→평가 결과→힌트→명시 공개→수정→무료 재첨삭→History 17단계를 확인한다. 서버 HTTP/RPC PASS와 실기기 UI PASS를 구분한다.
4. APP/WEB 동일 사용자·exam/question/run/parent 식별자, 확정 전사와 원본 artifact/영역, math-coaching-v1 공개 경계, 회차 견적/중복 요청 키, History 조회를 공통 계약으로 정리하고 양방향 조회를 검증한다. PC 레이아웃과 수식 표시 확장은 H로 넘긴다.
5. 혼합형 실제 Worker E2E 미완료를 별도 추적하고 필요한 최소 검증만 수행한다. Flutter analyze 최종 재확인 및 변경 범위 회귀 후 Owner 검수 보고.

기준 구현 Native `3cd7853`, WEB `9551f8f`; 직전 문서 체크포인트 `29556d5`. TEST Preview/기존 접속 절차는 위 안내를 유지한다. 현재 설치된 Profile은 G 실제 TEST 연동 앱이며 F 오프라인 예제와 다르다. 운영 DB·Credit·Ledger·결제·APP 릴리스 브랜치 변경 금지 및 운영 HOLD 유지.


## 2026-11-03 재개 — 원본 조회 및 공통 계약

Owner 재개 지시로 Mobile First 통합 검증을 계속한다. PC 화면 확장은 H에 유지한다. 기존 7가지 보존 검토를 계승: 새 저장 구조/원본 수정 없이 기존 artifact와 소유권을 사용하며, 확인된 영역만 표시한다.

`POST /api/math/artifact`에 artifact_id만 전달한다. 서버는 Auth 사용자→기존 math_artifact_storage describe의 active/owner 검증→공개 leaf 범위(설정 시)→PRESENT/image/크기/서명/SHA-256을 확인한다. private bytes만 no-store 반환하며 storage key·Worker credential·signed URL은 반환하지 않는다. Native History는 source_regions의 artifact를 기존 MathGateway로 읽고, 없는 영역을 추정하지 않는다. 결과 화면이 떠 있는 동안 autoDispose Gateway를 구독해 비동기 읽기 수명을 유지한다. DB schema/원장/Provider 변경 없음.

TEST WEB 서버 `52f62a6`, 배포 https://9ffd0510.legendstudy-task16b.pages.dev. 저장 Q1/Q2 원본 두 장 HTTP200 및 SHA-256 일치, 브라우저형/Dart User-Agent 모두 확인. Python 기본 User-Agent는 Cloudflare1010으로 차단되어 초기 검사 실패였으며 보안 설정은 변경하지 않았다. Native 관련16검사, 서버/접근 경계20검사 PASS; 타입검사/Analyze PASS. 실제 화면 검증은 별도 진행 중이다.

### APP / WEB 공통 계약과 H 인계

| 대상 | G에서 사용하는 계약 | 검증/남은 사항 |
|---|---|---|
| 사용자·시험·문항 | 같은 Auth user, canonical exam_id/question_id/leaf_id | TEST 한양2024 Q1/Q2 연결, 플랫폼 별 복제 ID 없음 |
| 원본·전사 | artifact_id + confirmed extraction/regions; 원본 이미지 인증 조회 | 기존 후보와 학생 확인본 보존. 실제 단계의 source_regions가 없으면 위치 미확정 안내; 임의 연결 금지 |
| 평가 결과 | math-coaching-v1 read; 최대5 tasks, concepts, source_regions | 정답 포함 raw fallback 금지. 검수 개념 미연결/일반 힌트는 품질 GAP로 유지 |
| 공개·힌트 | 같은 coaching hint/reveal 및 History 이벤트 | 명시 공개 후 full_solution. 인문 결과 비간섭, 혼합 Math만 적용 |
| 반복 첨삭 | math_session quote/continue, previous_run_id, 기존 client_submission_id | 시험 단위1/0 반복·중복 방지. 클라이언트 예상 비용은 서버 견적/동의 기준 |
| 기록 | 같은 math_session_history/read, math_learning/coaching history, 기존 mixed History | HTTP/RPC 저장·재조회 PASS와 실제 APP↔WEB UI 교차조회는 구분. 양방향 UI 검증 미완료 |
| H WEB 표현 | 기존 LaTeX/원문 fallback와 서버 DTO 재사용 | 원본·결과·개념 PC 동시 비교 및 긴 수식/행렬/적분 viewport는 H 검증 대상; G 완료로 간주하지 않음 |

현재 무료 재첨삭 샘플은 typed 답안이어서 source_regions가 빈 배열이다. 원본 이미지 API 성공을 이 샘플의 오류 위치 자동 연결 성공으로 확대하지 않는다. Provider 단계가 확인본 region을 연결한 경우에만 해당 영역을 강조한다.


### Native 실제 저장 결과 UI 검증

iOS Simulator에서 기존 TEST 계정으로 로그인하여 저장된 실제 한양2024 Q1/Q2 결과를 `MathCoachingPage`로 조회했다. 결과·최대5과제·기본 개념·History 실제 RPC/화면 연결, 원본 이미지 두 장 인증 다운로드 PASS. 기존 3회차 결과에서 4회차 무료 재첨삭 안내→시험/문항 고정→수정 답안 작성 화면까지 PASS. 제출 버튼은 누르지 않았으며 Provider0/새 평가0/원장 변경0이다. 이 검사는 전체17단계 신규 사진 제출 E2E와 구별한다.

실제 캡처 검토에서 학생 전사본 전체를 강제로 TeX 수식으로 감싼 문제가 확인되어 `MathStudentText`로 보완했다. 일반 설명·줄바꿈과 명시적 LaTeX 구분자를 유지하고, 고립된 수식만 수식 렌더러에 전달한다. 새 디자인/전사 수정/평가 재호출 없음. 원문·혼합문장·분수·중복 delimiter 방지 회귀 포함 Native18검사 PASS. 초기 캡처 driver가 reportData를 덮어써 파일을 저장하지 못한 것은 수정 후 재검증했다.

Owner iPhone12ProMax는 로그인 화면 진입을 확인했다. 기존 TEST 계정 로그인 후 홈 화면 확인은 진행 중이다. 임시 서명 설정 파일이 재부팅 후 없어져 첫 재서명 빌드가 실패했으며, 전용 TEST bundle/URL scheme과 별도 임시 설정을 복원해 다시 빌드한다. 운영 앱 설정 파일을 수정하지 않는다.

캡처에서 발견한 제목의 내부 leaf_key는 아래 후속 패치로 수정했다. 남은 품질 GAP: 일반 힌트/개념은 대학별 검수 개념과 동등하지 않음; typed 수정 답안은 사진 영역이 없음; 전체 사진 제출/확인/평가/재첨삭 실기기 연속 검증과 WEB 교차 화면·혼합형 실제 Worker 검증은 미완료. Source 조회 성공을 이들 품질 PASS로 확대하지 않는다.


최종 화면 재검증 기록:

- 전사 표시 수정 후 Simulator 실네트워크 UI 재검증 PASS: Q1/Q2 결과·개념·History, 원본2장, 다음 무료 수정 작성 화면. 테스트의 첫 Scrollable이 탭 가로 스크롤을 가리켜 긴 전사본에서 탐색에 실패한 것은 실제 세로 ListView 지정 후 PASS. 앱 예외를 숨기거나 제출 단계를 생략해 통과한 것으로 처리하지 않는다(제출은 애초 이 읽기 검증 범위 밖).
- 실제 화면은 Git 외부 `~/.codex/legendstudy-task16g-test/native-captures/`에 q1/q2-result, q1/q2-history, next-free-rewrite PNG로 보존. 학생 원본 이미지를 Git에 넣지 않는다.
- 추가 회귀: 일반 설명/영문 등식 포함 설명은 원문으로, 고립 수식/명시 구분자는 수식으로 유지. 기존 전체 회귀 결과는 앞선 기록을 재사용하고 영향 범위18검사와 후속 prose2검사/Analyze를 실행했다.


최종 빌드: Native Profile 재빌드/서명 PASS, iPhone12ProMax의 `com.legendstudy.app.task16f` / `LS Math TEST`에 설치 및 devicectl 실행 PASS. 검수 앱은 테스트 엔트리 대신 `lib/main.dart`이고 TEST DB·Pages 설정만 사용한다. 운영 앱의 bundle/URL scheme과 별개이며 Provider 키/계정 비밀번호는 빌드에 넣지 않았다. Owner 로그인 후 홈/실제 상세 화면 확인은 대기 중이다.


### 공식 문항 표시명 / TEST RPC 후속

`coaching_labels.test.sql`은 이미 설치된 coaching wrapper의 표시명만 보완한다. 기존 소유권/공개 검증 뒤 canonical Registry question FK로 문제1/2를 연결하며 새 권한·테이블·금융 변경은 없다. 신규 설치는 갱신된 `coaching_cycles.sql`을 사용한다. TEST에서 transaction rollback dry-run 후 적용하고, 기존 평가6건의 실제 인증 API 응답을 비교했다. `exam_label`과 원래 매 조회 갱신되는 `rewrite_policy.as_of` 외 모든 필드 동일, 함수 owner/search_path/ACL 보존 PASS. 운영 미적용. 이전 함수 원문은 비공개 TEST ops 디렉터리에 보존했다.

History 위젯 회귀 추가 PASS: 여러 과제가 같은 artifact를 참조해도 한 번만 읽고, 이미지 조회가 끝날 때까지 gateway를 유지하며 화면 종료 시 해제한다. Widget mock에 실제 SDK 타이머를 만들던 테스트 구성은 순수 mock으로 교체했으며 실제 Auth/Storage는 앞선 Simulator·HTTP 검증으로 분리했다.


## 2026-11-03 Owner — Simulator로 검증 계속

Owner가 휴대폰 긴 비밀번호 직접 입력 대신 시뮬레이션 검증 진행을 지시했다. 실기기 로그인 요청을 더 진행하지 않고 기존 TEST 계정의 Simulator 자동 인증을 사용한다. 비밀번호 단순화/재설정·인증 우회·운영 Auth 변경은 하지 않는다. 계정 비밀은 기존 one-shot loopback runner로 전달하며 코드/빌드 defines/로그에 넣지 않는다. 실기기 검수 미확인을 Simulator PASS로 바꾸어 기록하지 않는다.

로그인 진단은 TEST 로그의 invalid_credentials와 안내 파일 계정의 인증 성공, 설치 Profile의 TEST DB/Pages 설정 일치를 확인한 범위다. 어느 입력값이 달랐는지는 확인하지 못했다. 계정 원문을 보고서에 남기지 않는다.

Simulator 실네트워크 검증 PASS: 기존 실제 Q1/Q2 평가 재사용, 단계별 힌트1/2, 공개 취소 시 비공개 유지, 명시 공개 후 full_solution 및 History 공개 기록, 다음 무료 재작성 화면. 최초 실행에서 공개 전 disclosed=false/full_solution 없음과 공개 후 상태를 확인했다. 공개 기록을 지우지 않고 보존하며 재실행은 이미 공개된 상태를 사용한다. TEST 학습 열람 이력만 추가되었으며 새 평가·Provider 호출·차감은0이다. 비공개 증거 simulator-learning-loop-first.json과 native-captures/에 보존한다.

전체 풀이의 단계 representation도 전사본과 같은 MathStudentText를 재사용하여 한글 설명을 강제로 TeX 처리하지 않도록 보완했다. 기존 History 탭은 힌트/공개 후 재조회 시 갱신됨을 회귀 테스트로 확인했으므로 별도 캐시 구조 변경은 하지 않았다. 영향 범위 위젯11검사/Analyze PASS. 표시 수정 후 Simulator 실네트워크 재실행 PASS 및 전체 풀이 화면 한글·수식 구분 확인. Wiki handoff 2110링크/11982bytes PASS. 일반 힌트의 대학별 품질, 새로운 사진부터 재첨삭까지 전체17단계, 실기기 로그인 이후 검수는 여전히 미완료다.

## 2026-11-03 — 신규 사진 Simulator E2E

Owner가 격리 TEST에서 신규 사진→실제 평가→무료 재첨삭→History까지 이어서 검증하도록 지시했다. 기존 7가지 보존 검토를 유지하고 새 schema/엔진/금융 시스템을 만들지 않는다. 원본 자료·이전 시도·확인 후보를 삭제하거나 덮어쓰지 않는다.

검증 경계: iPhone16Pro Simulator/iOS18.6, 기존 TEST 계정 자동 로그인, 실제 Registry의 한양2024 자연 오전 Q1/Q2로 선택 목록을 제한한 Native 화면. OS 사진 선택 결과만 실제 준비 사진 bytes로 공급한다. 카메라 하드웨어/시스템 Photos 선택기 검증은 아니다. 업로드·인식·확인·평가·History는 실제 TEST 서버를 사용한다.

발견·수정:
- 시험 작성 화면이 일반 `AnswerImagesInput`만 사용하던 연결 누락: canonical Math exam/question 매칭에 한해 기존 `MathImageInput` 보정·순서 UI 재사용. 인문 사진 입력 유지, 신규 디자인 없음.
- 준비된 입력 재진입 시 `sourceImages`가 비어 원본 대조 불가: 기존 인증 artifact 읽기로 후보 영역의 원본 재조회. 조회 실패 시 입력 확인을 진행하지 않으며 기존 요청/답안을 유지한다.
- 인식/수정 미리보기의 한글을 강제 TeX 처리하던 부분은 기존 `MathStudentText`로 통일. 학생 수정 후 확인 문구는 원본 인식의 정확성 확정과 구별한다.

사진·인식 단계 PASS. 첫 OCR Q1/Q2 13/17영역, 학생 확인 전 평가 차단. Simulator drive 재설치로 로컬 요청이 초기화되어 후속 빌드에서 OCR2회가 추가 실행됐다(합계4회). 두 번째 후보는17/18영역. 이후 runner가 TEST 저장 체크포인트·인증 원본 bytes를 복원하고, 준비 체크포인트가 있으면 신규 OCR 실행을 거절한다. 사용되지 않은 첫 시도도 삭제하지 않는다. 검수 전사 ID가 바뀐 것을 테스트가 탐지해 확인/평가 전에 중단했다.

Q1 숫자·지수·그래프 교점 오인식, Q2 표의22/140→20/140 및13/140→15/140 오인식을 확인했다. 기존 검수 전사와 원본을 대조해 수정한다. Q1의 판독이 확정되지 않은 도함수/일반항은 TEST 검증자 직접 수정본임을 명시하며 원문 판독 성공으로 세지 않는다. Q2의 실제 수치 오류도 원본과 비교한 후 수정한다. 자동 OCR 품질 PASS가 아니라 오인식 확인/수정 흐름의 검증이다.

### 최종 결과

신규 사진→보정(회전/복원/적용)→인식→전사 수정·확정→실제 평가→결과·개념·명시 공개→수정 답안→무료 재첨삭→History 저장/재조회 Simulator PASS. 빌드 재시작 사이에는 같은 저장 요청·시도를 복원했으므로 단일 무중단 실행으로 해석하지 않는다. 원본과 개인 runner/인증 정보/원시 결과는 Git 외부 TEST 디렉터리(0600)에 보관한다.

- 최초 run `a2dadaaa-5e4a-4354-8a69-dae035209ec4`: Q1/Q2 실제 AI 완료, TEST 이용권1개. Q1만 완료/Q2처리 중일 때 전체 run은 reserved로 유지됨을 관찰했다.
- 무료 run `3aad2966-68c4-44d3-93d3-b164bdd4fb96`: Q1/Q2 실제 AI 완료, 최초 run 연결, 이용권0개·원장 거래 없음. 다음 견적1개.
- 두 완료 요청을 동일 키/시도로 재전송해 같은 run 반환·원장 무변경. 기존 원장행/이전3run 보존, 이번 balance delta−1, 미정산 예약0. `sim-final-verification.json`에 증거 보존.
- 실제 Provider는 이번 작업에서 OCR6회+평가4회=10회. 재설치 추가OCR2회 외에 Math 재작성의 legacy 초안 이관이 이전 사진을 복사하여 OCR2회가 더 발생했다. 확인 전 차단되어 이 미사용 시도에 평가는 실행되지 않았다. `math_session_run_id`로 Math 재작성을 식별해 legacy 자동 복사를 제외하고 새 작성/기존 자기 초안 복원을 회귀 검증했다. 미사용 시도는 보존한다.
- 평가4회 관측 토큰은 입력25,020/출력19,743(합44,763). 최초 OCR4회 사용량은 수집하지 못해 전체 토큰·비용은 확정하지 않는다. 평가 재호출0.
- 새 무료 결과 읽기 전용 Simulator 후속 PASS: Q1/Q2 결과·개념·History·원본, Q2 힌트1/2 표시. 이 후속 Provider/차감0. Q2는 기존 TEST 경계값 오류 샘플이며 원본 합격자 오류로 해석하지 않는다.

검증: 영향 범위 Native25검사, 인문/History49검사 PASS. 신규 사진 학습 루프와 저장된 새 결과 조회 모두 Simulator 실네트워크 PASS. Analyze PASS; Wiki handoff 2,111링크/11,975bytes PASS. 실행 로그는 `/tmp/task16g-new-evaluate7.log`, `/tmp/task16g-new-history.log`; 실제 화면은 `~/.codex/legendstudy-task16g-test/native-photo-captures/`, `native-new-history-captures/`에 보존한다.

남은 GAP: OCR 자체 정확도 미통과, Q1 일부 수식은 검증자 직접 수정본. 새 최초 결과 과제0개이며 Q2 오류 샘플 힌트는 일반적인 개념/조건 점검 수준이다. History 화면의 이용권 내역 미제공/미완료 시도 표시도 남아 있다(차감은 원장으로 별도 검증). 단계별 원본 영역 연결 미확정, 대학별 구체적 힌트·공식 전체 해설 품질, 혼합형 Worker 실제 E2E, APP↔WEB 실제 UI 교차 검증 및 실기기 입력 검수는 별도다. 이 PASS는 TASK16-G 전체 완료/운영 승인으로 해석하지 않는다.

이번 변경은 APP 개발 브랜치와 TEST 학생 요청에 한정한다. backend 배포·schema·운영 DB/Credit/Ledger/결제·APP 릴리스 변경 없음. 기존 TEST Preview는 `https://legendstudy-task16b.pages.dev` (배포 `9ffd0510`)를 유지한다. Owner 검수 전 운영 HOLD.
