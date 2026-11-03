# TASK16-J — 수리·상경 베타 출시 준비

2026-11-03. **최종 출시 판정: NOT_READY.** 핵심 기능 PASS를 재사용하지만 실제 학생의 전체 이용/품질·실기기·운영 공통 계약이 모두 통과하지 않았다. Owner 별도 승인 전 운영 활성화 금지. [I 기능 인정](task16i-owner-review-20261103.md), [I 실제 검증](task16i-integration-quality-20261103.md), [H](task16h-web-math-ux-20261103.md), [G](task16g-learning-loop-20261102.md), [F](task16f-native-math-ux-20261102.md), [E](task16e-recognition-disclosure-p0-20261102.md), [C 실제 필기](task16c-hanyang2024-handwriting-validation-20261102.md)를 교차 확인했다. 신규 평가 엔진/디자인 개편 없음.

## Owner 접근 복구 A–F

| 항목 | 확인 결과 |
|---|---|
| A 구현 | LAB `cloudflare/test-preview-access.ts`, `functions/_middleware.ts`. TASK09 비공개 검수 gate를 TASK16-B에 재사용. 운영 호스트에는 적용하지 않음 |
| B 설정 | Cloudflare Pages `legendstudy-task16b` → Settings → Variables and Secrets → `TEST_PREVIEW_ACCESS_KEY`. Production/Preview binding 존재. 여기서 Production은 **전용 TEST 프로젝트의 기본 배포 환경** |
| C 기존 코드 | `/Users/woojinchang/.codex/legendstudy-task16b-test/owner-access.json`의 `access_code`. 파일0600, 현재 gate 통과 확인. 새 코드 생성/기존 코드 출력·인증 해제 없음 |
| D 검증 | HTTPS+정확 TEST 호스트, 동일 Origin POST `/__review-access`, 입력1KB 제한. Secret을 키로 HMAC-SHA256 비교, 호스트·8시간 만료에 서명한 `__Host-task09_review` HttpOnly/Secure/SameSite=Lax 쿠키. 다른 브라우저/배포 호스트/만료 후에는 다시 필요 |
| E 계정 | gate 통과 후 별도 TEST Supabase Email/Password 로그인. 동일 로컬 파일의 email/password 사용. gate는 사용자 소유권/관리자 권한을 부여하지 않음. APP은 gate 쿠키 대신 제한된 API의 JWT·서버 allowlist 검증 |
| F 이전 경로 | F는 오프라인 Native `LS Math TEST` UI 검수, G부터 같은 TEST 계정의 실제 서버 연결. C/E 내부 preview는 합성/회귀 화면. H/I `/math-review/?evaluation=...`와 `/my/essays/result/`는 저장된 실제 TEST 결과. 별도 코드가 새로 생긴 것이 아니며 브라우저별 쿠키를 공유하지 않음 |

기존 코드 전달 문제는 인증 해제가 아니라 **Owner가 직접 사용할 접속 절차의 전달 문제**다. 이번에 기존 로그인 도우미로 별도 브라우저의 실제 결과4탭을 다시 열었고 Finder에서 실행 파일을 선택했다.

1. 자동 접속: Finder에서 `/Users/woojinchang/.codex/legendstudy-task16i-owner-review/Owner-검수-열기.command` 실행. 기존 파일을 읽어 로그인하며 평가/공개 요청은 하지 않는다.
2. 기본 브라우저에서 직접 접속하려면 `/Users/woojinchang/.codex/legendstudy-task16j-test/TEST-접속정보-복사.command` 실행 → 1(접속 코드), 2(이메일), 3(비밀번호) 중 필요한 항목 선택 → 해당 TEST 입력란에 붙여넣기. 값은 터미널·보고서에 출력하지 않는다. 긴 암호를 직접 타이핑하지 않는다.
3. 직접 파일을 확인하려면 Finder ‘폴더로 이동’에서 위 `owner-access.json` 경로 사용. 채팅/Git에 복사하지 않는다. 기존 값이 존재하므로 재발급 불필요. 분실 시에만 Owner가 해당 TEST Secret을 별도 재등록하고 새 배포/접속을 확인하는 절차를 승인받는다.

실제 gate+계정 로그인 성공은 확인했지만 Owner가 자신의 브라우저에서 직접 들어갔다는 확인까지 받은 것은 아니다. 자동 브라우저와 일반 브라우저의 세션이 다름을 안내한다.

## 기능별 판정 — 코드와 실제 이용 분리

| 항목 | 판정 | 근거와 남은 부분 |
|---|---|---|
| WEB 신규 제출 전체 E2E | PARTIAL | I의 실제 사진→OCR→수정확인→최초/무료평가→History PASS 재사용. J는 대학/시험 선택의 TEST 연결 보완. 제출 전 보정과 전체 무중단 신규 흐름은 미완료 |
| APP 실제 기기 제출 E2E | NOT_VERIFIED | F iPhone UI PASS와 G/I Simulator 실서버 PASS는 재사용. 현재 iPhone12ProMax devicectl unavailable. 카메라/Photos/로그인부터 무료 재첨삭까지 실제 기기 검증 없음 |
| 사진 보정·정렬 | PARTIAL | Native 회전/자르기·원본 보존 위젯/Simulator PASS. WEB 결과 확대·회전은 보기 기능, 업로드 전 crop 미구현 |
| OCR 인식 정확도 | FAIL | 실제 Q1 부호·지수·일반항 오류 재현. Q2는 표·수치 정상 사례 및 일부 식별자 오독으로 PARTIAL. 자동 정확도% 미산출 |
| 전사 확인·불확실 차단 | PASS | 기존 영역 확인/수정 취소/UNCERTAIN 차단·서버 진입 검증 PASS, I 실사진 수정 후 평가. 틀린 기호를 학생이 잘못 확정한 경우까지 자동 검출한다는 뜻은 아님 |
| 공식 평가 기준 연결 | PARTIAL | 두 대표 시험 공식 문제/평가기준·Package와 실제 Provider 사용 확인. 화면의 문항별 세부 기준·공식 완성 해설 연결 부족 |
| 첨삭 결과 품질 | PARTIAL | 정답·계산·개념·대안 풀이 실제 증거 재사용. 논리 비약/다수 오류 중요도/원문 판독 범위 검증 부족 |
| 개선 과제 최대5개 | PASS | 서버 상한/DTO/화면 검사. 다수 오류의 학습 우선순위 품질은 PARTIAL이며 상한 PASS와 분리 |
| 기본 개념 | PARTIAL | APP/WEB 공통 계약 연결. 일반적인 동치변형/조건 점검으로 대학 문항별 충분한 구체성 미검증 |
| 단계별 힌트 | PARTIAL | 누적 공개·저장·교차조회 PASS. 스스로 수정할 수 있는 구체적 수식 힌트 품질 부족 |
| 전체 풀이·해설 | PARTIAL | 명시 공개 후 조회, 실제 Q2 수식3개 렌더/1개 원문 fallback. 공식 모범답안 수준 미달 |
| 서버 정답 공개 제어 | PASS | TEST legacy/raw/history 경계·비공개 응답·명시 reveal·이력 검사 재사용. **운영 신규 RPC 미설치**와 구분 |
| 무료 재첨삭1회 | PASS | TEST 유료1→무료0, 14일/베타 종료 경계 로컬 SQL, 실제 무료 사용·다음견적1. 실제 일일 베타 지급과 수리 연결은 별도 미검증 |
| 반복 차감·중복 방지 | PASS | 기존 TEST cycle/동일키 재전송 원장 불변. 운영 신규 반복 RPC/flag 적용 전이며 무한 모든 회차의 실제 Provider 시험이 아님 |
| History 저장·재조회 | PASS | 실제 WEB/Simulator 동일 ID/전사/공개/무료 상태 재조회. 자연계 목록 대학명 누락 등 표시 문제 남음 |
| APP↔WEB 교차 조회 | PASS | H/I 실제 저장 결과 양방향, 원본 SHA256·수정 본문 일치. APP은 Simulator 검증 범위 |
| 상경 Essay+Math | PARTIAL | 한양2026 실제 Worker 두 문항·시험1개 차감·부분처리 전체 미완료·저장 통합 화면 PASS. 전체 신규 UI/사진/무료 재첨삭/실기기 연속 흐름 미검증 |
| 기존 인문논술 | PASS | 기존 실제 실행 증거와 이번 WEB 전체 회귀1591 PASS/4기존skip. 운영 인문 재평가/배포/정책 변경0 |

## 이번 TEST 연결 수정과 검증 경계

LAB `b2e85be` (`5009fa8` 진입 수정 + 등록 상경 목록 보존). 최종 TEST 배포 `9b47d9b8`, canonical `https://legendstudy-task16b.pages.dev`:

- `public-service-status.ts`: TEST의 `ESSAY_PUBLIC_EXAMS='[]'`가 운영 UUID allowlist parser에서 오류가 되어 상태503. 정확 TEST scope에서는 기존 대표 상경과 `ESSAY_COMMERCE_RUNTIME_TEST_ENABLED`를 사용하고 Registry question set/Package digest/Auth 검증을 유지한다. 운영 allowlist 처리 불변.
- `source-exam-selection.tsx`: TEST 자연계 시험은 목록에 있었지만 material projection에는 사진 입력 metadata가 없고 자연계 공통 HOLD가 적용됐다. 기존 등록 catalog를 보존하고 정확 TEST 호스트의 인증된 `/api/essay/catalog`에서 대표 자연 시험의 공식 PDF/image metadata만 보완한다. 자연계 HOLD 예외는 정확 대표 exam만 허용하며 제출은 기존 서버 admission이 계속 결정한다.
- `task16g-test-catalog.ts`의 정확 HTTPS origin 판별과 관련 테스트. 운영/배포 별칭/다른 자연계 시험은 예외 아님. 클라이언트 예외로 평가 권한을 부여하지 않는다.

중간 배포 `ff804713`는 자연계 메타데이터 연결 시 등록 상경 목록을 누락하여 후속 수정했다. `b2e85be`는 기존 등록 시험을 유지하며 정확 자연 exam만 대체한다. 정적 source 자료가 새로운 평가 가능 시험으로 추가되지 않는 회귀도 검증했다.

최초 화면 캡처의 ‘기출 준비’는 로딩 중이었으므로 시험 자체가 없다고 결론 내리지 않았다. 로딩 완료 후 두 시험 존재와 자연계 입력 HOLD를 별도로 확인했다. 브라우저 networkidle timeout/이동 시 ERR_ABORTED는 Provider 실패가 아니다. 실제 503·TEST 베타 상태 RPC404와 구분한다.

최종 배포 후 실제 TEST 상태 API200·Registry/Package 검증 응답을 확인했다. 대학 목록→한양대→2024 자연 선택→독립 새 초안→Q1 student-1.png/Q2 student-2.png 각각 선택·브라우저 저장→추출 준비 버튼 활성화, 2026 상경 선택→2문항 작성기 진입 PASS (`entry-after.json`). 추출·평가 버튼은 누르지 않았다. 저장된 Q1/상경 통합 결과도 재조회했다(`stored-result-after.json`): 브라우저 오류0, Q1 disclosed=false/full_solution 미포함, 공개 요청0. 전체 신규 제출 E2E를 재실행한 결과가 아니다.

전체 WEB **1591 PASS/4skip**, 222파일 PASS/3skip. 최종 선택 관련15검사/앞선 공개상태·gateway·gate63검사 PASS, TypeScript/변경파일 lint/build PASS. 기존 Native/Provider PASS를 불필요하게 재실행하지 않았다. 새 Provider·OCR·평가·결제·이용권 지급/소비0. I Owner 검수 지급의 TEST 잔액2/예약0을 재확인했다.

## 운영과 TEST의 실제 차이 — 읽기 전용 실측

| 구분 | 운영 | 격리 TEST / 필요한 조치 |
|---|---|---|
| 프로젝트/Auth | `stlhijzpjfgwwdgunlsd` | `kpqbedylxlyntrrfybpn`, 독립 계정. TEST 계정/토큰을 운영으로 이관하지 않음 |
| Provider | 운영 Pages/Worker에 Math/Essay Secret binding 존재, 실행 flag true. 키 원문/동일성 미조회 | 전용 Pages/Worker 키 분리·실제 호출 성공 재사용. 키 존재만으로 품질/전체 출시 승인 아님 |
| Registry | 2026상경2문항/Math set 존재. 2024자연 오전 exact ID 및 동년도 동일 실제시험 없음(2024자연 모의는 별개) | 자연2024 Q1/Q2 official seed는 TEST에만 있음. 공식 자료/hash/시험 정체성 재확인 후 최소 등록 필요 |
| RPC | 기존 Math 입력/추출/평가/session 기반 존재. `math_coaching`, `essay_math_coaching`, `math_session_quote/continue` 없음 | TEST에 F/G wrapper·cycle·공개/힌트 이력 있음. 단순 WEB 배포로 공통 계약 충족 불가 |
| Credit/Ledger | 기존 기록 유지. Pages `ESSAY_CONTINUOUS_CYCLES_ENABLED=false`; Math session에 previous_run_id/submission_index 없음 | TEST true와 loop 구조. 기존 원장/decision을 재사용하는 증분 migration 필요. TEST 설치 SQL 전체 복사 금지 |
| History | 기존 essay_exam_history/math_learning/raw detail 정의와 TEST hash 다름 | 공개 전 projection/연결 wrapper·새 event tables 필요. 기존 결과/공개기록 소급 덮어쓰기 금지 |
| Storage | math-private 비공개20MiB, essay-material-originals 비공개32MiB | TEST 동일 bucket 경계. 자연 대표 문제/평가자료·정확 PDF 권한·프로젝트 URL을 운영 기준으로 재검토. 학생 원본 복사 금지 |
| WEB | `legendstudy-lab` / lab.legendstudy.com, 실측 배포 `aaf80a93`·SHA `c9bda913` | 전용 `legendstudy-task16b`만 J 배포. 운영 브랜치/인문 수정과 통합 리뷰 필요; TEST branch 전체 덮어쓰기 금지 |
| APP | 1.0.1(41) 릴리스 변경 없음 | 개발 worktree a9017f7 실행 코드·전용TEST bundle. 실기기 검증/운영 env 구성/별도 릴리스 승인 필요 |
| 베타 | enabled=true, starts_on11/1, ends_on11/10, daily_limit1. 함수 종료=(ends_on+1) KST → **11/11 00:00**. 대상160개/has_math0/대표2시험0 | TEST campaign0, `essay_beta_daily_status_v2` 없음(화면404). admin grant E2E를 일일 베타 E2E로 대체 불가 |

과거 current-status의 ‘베타 캠페인 비활성’은 이번 운영 실측과 달라 정정한다. 이번 작업이 활성화한 것은 아니다. 운영 Math enabled=true도 기존 runtime의 상태이며 TASK16-F/G 공개 계약이나 대표 수리 베타 출시를 의미하지 않는다. TEST Pages의 preview 환경은 현재 Math API/Worker Secret 일부가 기본 배포 환경과 달라 canonical URL만 실제 제출 검수 경로로 사용한다.

## 운영 적용 필요 작업 — 실행 승인 전 목록

1. **증분 DB migration 작성/검증**: 현재 운영에도 session_core와 session_finance가 있으므로 `install.test.sql`, `seed.test.sql`, local rollback을 운영에 그대로 실행하지 않는다. F `001_coaching.sql`/`002_disclosure_boundary.sql`, G `loop.sql`/`mixed_disclosure.sql`/`mixed_learning.sql`/`coaching_cycles.sql`의 필요한 차이만 현 운영 함수 hash/owner/ACL/search_path에 맞춰 별도 승격한다. `authorize_billing`·learning_eligibility 등 차이도 검토하며 기존 finance/settle/release를 무조건 교체하지 않는다.
2. 기존 기록이 있는 운영 형태를 격리하여 migration 전후 인문 결과 동일, Math 공개 전 차단, cycle1/0/1/0, 동시 재시도, 만료·실패/환불·잔액 부족, 원장 합계/History 보존을 검증한다. 신규 production-ready SQL/비파괴 rollback은 아직 미완료다.
3. **Registry/Evidence/Storage**: 자연2024 실제 시험·공식 채점 자료 연결을 운영 대상 기준으로 작성. 상경은 기존 ID/Package 재사용, 허용 문항·공식 PDF만 정확하게 연결. TEST URL·개인답안·운영 사용자ID의 섞임 금지.
4. **베타 연결**: 기존 하루1회/00KST/이월0/11월11일 종료·무료14일 중 이른시각을 그대로 보존하며 수리/혼합형을 포함할 승인 scope와 코드 계약을 TEST에서 검증한다. 단순 enabled=true 또는 날짜 연장으로 해결하지 않는다. 기존 인문160개 scope 보존.
5. **서버/WEB/APP 배포**: 검증된 RPC 이후 해당 소비자만 순서대로 적용하는 계획, Math/Essay 분리키와 Worker allowlist/Queue/Storage/복구·관측 점검. 운영은 기존 인문 동작을 보존하는 별도 승인 PR/배포 대상. TEST 한정 예외는 운영 공개 정책으로 복사하지 않는다.
6. **중단/복구**: 신규 제출만 중단하고 완료 결과·원본·History와 기존 인문은 유지. 예약/실행 중 회차는 기존 lease/정산/복구 계약으로 처리. 빈 로컬용 drop rollback·원장삭제·Auth삭제 금지. 배포 직전 함수/설정/데이터 사전 검증과 모니터링 기준을 Owner에게 제시한다.

일곱 보존 답변: 원본/확정/평가/공개 시각 구분, 공식 package/hash 보존, 재작성은 새 attempt, 동일 owner ID 유지, 학습과 입시 결과 분리, 비공개 Storage/삭제 경계 유지, AI판정은 사실 전사와 구분. 이번 새 DB/Storage UPDATE 설계·학생 수집 없음.

## 출시 기준 A–L / 남은 P0

A 실제 사용자 E2E **PARTIAL**; B OCR확인수정 **PASS**; C 잘못된 전사 차단 **PARTIAL**(UNCERTAIN 방어 PASS, 잘못 확정한 전사까지 자동보장 불가); D 공식 기준 **PARTIAL**; E 수학 오류 정확성 **PARTIAL**; F 전체 해설 수식 **PARTIAL**; G 무료1회 **PASS(TEST)**; H 중복차감 **PASS(TEST)**; I History **PASS(TEST)**; J 인문 **PASS(회귀/기존 증거)**; K 교차조회 **PASS(Simulator↔WEB)**; L Owner 실제 신규 학습 루프 검수 **NOT_VERIFIED**.

P0 순서: (1) 실제 Q1 OCR 오류·수정 부담/대안풀이 품질, (2) 공식 기준별 힌트·완성 해설/수식 fallback, (3) WEB 신규 전체 흐름/이미지 보정 및 상경 무료 전체 흐름, (4) iPhone 실제 촬영·선택·보정·확인·평가·무료·History, (5) 운영과 동일한 베타 scope/반복·공개 계약의 격리 검증 및 증분 migration, (6) Owner 검수와 별도 활성화 결정. 기능 PASS 인정은 철회하지 않으며 출시 조건을 별도로 판정한다.

실기기 Owner 체크: iPhone12ProMax 연결/잠금 해제 → 별도 LS Math TEST/TEST계정 → 대학·시험·Q1/Q2 선택 → 카메라와 Photos 각각 → 회전/자르기·취소/복원 → 원본대조·수정 → 최초 견적1 → 실제 결과/힌트/명시 공개 → 무료견적0 → History → 동일 WEB 조회. 혼합형도 시험2문항 완료/시험1개 차감 확인. 이 과정은 Simulator로 대체하지 않는다.

## Owner 경로와 증거

[자동 접속·실제 Q1/Q2/상경 결과·알려진 문제](task16i-owner-review-20261103.md)의 링크를 그대로 사용한다. 신규 진입은 [TEST 한양대 선택](https://legendstudy-task16b.pages.dev/essay-lab/universities/hanyang/) → 학년도·시험 및 계열 선택 → 2024수시 자연 오전 또는 2026수시 상경 → ‘아니오, 새로 작성’. 운영URL에서 검수하지 않는다.

로컬 비공개 증거 `/Users/woojinchang/.codex/legendstudy-task16j-test/`: `database-readonly.json`(운영/TEST RPC hash·공식 Registry), `cloudflare-sanitized.json`(Secret 값 제외), `catalog.mjs`/캡처(수정 전), `entry-after.mjs`/`entry-after.json`(수정 후), `natural-photo-ready.png`/`mixed-entry.png`(실제 화면), `stored-result-after.json`(저장 결과 조회), `tests-final.log`, `build-final.log`, `deploy-final.log`. 원본·인증·답안 Git 제외. Secret/설정 PATCH0, 운영 SQL 쓰기0, 운영 WEB 배포0, APP 빌드/릴리스0.

## 변경 파일과 검증 기준점

WEB 두 커밋 `5009fa8`/`b2e85be`: `functions/api/essay/public-service-status.ts`, `src/components/source-exam-selection.tsx`, `src/lib/essay-runtime/task16g-test-catalog.ts`, 각 세 대응 테스트 파일. 최종 배포9b47d9b8. Native 실행 코드/APP 릴리스 변경 없음.

Wiki: 본 보고서, index/current-status/decisions/log, 베타 실측 정정, I Owner 검수 후속 링크. `python3 tool/check_wiki_handoff.py` 및 `git diff --check` PASS, current-status11,703bytes로12KB 이내. 코드 전체 테스트와 기존 실제 Provider E2E, 이번 브라우저 입력/조회, 아직 미검증인 Owner 실기기를 별도 판정한다.
