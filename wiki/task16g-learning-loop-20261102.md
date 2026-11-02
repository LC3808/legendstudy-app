# TASK16-G — 학습 루프 통합

2026-11-02 · 구현/TEST 검증 진행 중, 운영 HOLD. 기준 Native SHA `787987f`.

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
