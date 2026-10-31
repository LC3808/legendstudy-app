# TASK07 — APP / WEB BETA RELEASE READINESS REPORT

검수: 2026-11-01 KST. **출시 권고 HOLD / TASK07 전체 완료 조건 미충족 / Owner 승인 대기**.
이번 작업은 신규 기능 개발·운영 적용이 아니라 기존 구현, 격리 실행, 운영 SELECT와 Chrome 읽기 검수다. 실제 검증되지 않은 E2E를 자동 테스트로 대체하지 않는다.

## 1. 검수 대상 및 버전

- APP repository: `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022` (`LC3808/legendstudy-app`), `codex/essay-evaluation-stability-p0-20261029`, 코드 기준 `16a6191c4b70f4dede9c25682bb3c79aef913d7c` (시작 LOCAL=REMOTE).
- WEB: `/Users/woojinchang/development/legendstudy-release-20261024` (`LC3808/legendstudy-lab`), `codex/web-app-release-20261024`, `a4e16c48af3d708a6ccf2979baf67d8523a255ca` (시작 LOCAL=REMOTE). 이번 코드 변경 없음.
- APP artifact: `build/ios/qa-final-feedback-32/Runner.app`, 1.0.1(32), `com.legendstudy.app`. receipt source `a72292e3369c4c481581fb41a15b24c923bc48ab`, App.framework SHA256 `b8d3235706600f8e963bff8c889008df2fd61a8ad9b83f221fe8f909f7b46f59`, codesign deep/strict 통과. Observation V1/social 설정은 receipt 기준. **TASK01–06 이전 빌드, 최신 통합 실기기 검수 증거 아님.** 새 빌드/설치 안 함.
- Supabase `stlhijzpjfgwwdgunlsd`: 현재 migration history 최신 `20261027045140`; 후보 SQL 존재가 운영 적용을 뜻하지 않는다.
- 실제 Cloudflare Pages/Worker GET: 둘 다 HTTP401. 현재 ID 검증 BLOCKED. 기존 기록의 WEB `f9e0e83f-6f93-470d-a1e0-0c711607c53c` / Worker `a462a9a8-4842-4bf9-84d7-7dc9210cedba`는 **과거 관측값**이다.
- Analytics v1: 기존 Claude 구현 재사용, APP/WEB 계약 31 events / 14 parameters. 관리자 WEB는 WEB 코드 기준과 같지만 최신 운영 버전 확인 불가.
- 환경: Flutter3.47.6, Node22, PostgreSQL17 localhost55439 및 disposable local cluster, Chrome 기존 로그인 세션. PG 인증 helper는 synthetic fixture; 실제 JWT 검증과 구분.

## 2. TASK01–06 구현 상태

| TASK | 코드/격리 검증 | 운영·실계정 상태 | 기존 문서 |
|---|---|---|---|
| 01 공지 | 단일 콘텐츠/읽음 원장, 예약·종료·채널·핀·보관·권한 테스트 PASS | 신규 schema 미설치; APP/WEB 실제 읽음 동기화 BLOCKED | [공지](notices-system.md) |
| 02 베타 | 계정/KST 날짜·동시성·복구·rewrite cutoff PASS | campaigns 0건, 운영 활성화 안 됨 | [베타](essay-beta-daily-v2.md) |
| 03 Analytics | 기존 통합/Noop/allowlist/계측 계약 PASS | GA4 실제 수신/현대 exam 집계 의미 GAP; 부분 완료 | [Analytics](analytics-v1-implementation-20261030.md) |
| 04 관리자 | 공식 admin+명시 capability, CAS·감사·수량 변경 PASS | 신규 schema 미설치; 실계정 관리 BLOCKED | [운영](admin-beta-operations.md) |
| 05 피드백 | 기존 feedback 원장 재사용·중복·처리·조회 PASS | 신규 schema 미설치; 실제 접수/관리 BLOCKED | [피드백](essay-feedback-reports.md) |
| 06 비용/장애 | 실제/추정/UNKNOWN·필터·ACL·동시 alert PASS | 신규 schema 미설치; 신규 호출정보 공백은 UNKNOWN | [모니터링](essay-operations-monitoring.md) |

## 3. 결과 집계와 범위

고유 검수 그룹 44개: PASS 21 / FAIL 0 / SKIP 1 / BLOCKED 15 / NOT_TESTED 7. 개별 자동 assertion 수와 합산하지 않는다. TASK07의 모든 세부 bullet이 실행됐다는 의미가 아니다.

| ID | 대상 | 상태 | 범위·근거 |
|---|---|---|---|
| QA-001 | APP Analyze | PASS | isolated automation: 0 issues; /tmp/task07-app-analyze.log |
| QA-002 | APP Flutter Test | PASS | isolated automation: 1306 PASS / 7 SKIP / 0 FAIL; /tmp/task07-app-tests.log |
| QA-003 | WEB TypeScript | PASS | isolated automation: exit 0; /tmp/task07-web-tsc.log |
| QA-004 | WEB Lint | PASS | isolated automation: 0 errors / 5 warnings; /tmp/task07-web-lint.log |
| QA-005 | WEB Build | PASS | isolated automation: production build exit 0; /tmp/task07-web-build.log |
| QA-006 | WEB Test | PASS | isolated automation: 1460 PASS / 4 SKIP / 0 FAIL; /tmp/task07-web-tests.log |
| QA-007 | Worker fixture | PASS | isolated automation: 24 tests; retry/quote/review/error diagnostics; /tmp/task07-worker-tests.log |
| QA-008 | Payment SQL | PASS | isolated automation: 117 contracts; canonical isolated PG17 ledger; /tmp/task07-payment-tests.log |
| QA-009 | Exam Credit SQL | PASS | isolated automation: 18 contracts; idempotency/race/rewrite/recovery; /tmp/task07-credit-tests.log |
| QA-010 | Notices SQL | PASS | isolated automation: schedule/expiry/channel/read revision/ACL/rollback; /tmp/task07-notices-sql.log |
| QA-011 | Beta/Admin SQL | PASS | isolated automation: 30 concurrent claims; midnight/cutoff/capability/audit/restore; /tmp/task07-beta-sql.log |
| QA-012 | Feedback SQL | PASS | isolated automation: owner scope/idempotency/CAS/admin/review link/concurrency; /tmp/task07-feedback-sql.log |
| QA-013 | Operations SQL | PASS | isolated automation: cost basis/ACL/filter/audit; 8 concurrent alert checks; /tmp/task07-operations-sql.log |
| QA-014 | Analytics SQL | PASS | isolated automation: fixture/apply/contracts/postcheck 8 RPC ACL; /tmp/task07-analytics-sql.log |
| QA-015 | Analytics event contract | PASS | APP/WEB 31 events / 14 parameter allowlist match; tool/check_analytics_contract.py --web-root WEB |
| QA-016 | Chrome existing login/history | PASS | existing session; 49 records; 5/page; balance UI 95; Production Chrome /my/essays/; no new login |
| QA-017 | Chrome stored SWU result | PASS | two completed questions; summary/strength/action rendered; 6fe629cb-7bfd-4907-b144-439b299cfdc3 |
| QA-018 | Chrome prior comparison | PASS | Q1 two criteria 1→5, +4; stored explanations and graph; Production result rewrite tab; no evaluation initiated |
| QA-019 | Stored parent/credit | PASS | three selected runs completed; SWU child parent correct; no child credit transaction; Read-only SELECT; bounded observations below |
| QA-020 | Observation RPC metadata | PASS | 3 exact signatures; SECURITY DEFINER; fixed search_path; auth only; Live pg_proc/has_function_privilege SELECT; NOT full JWT proof |
| QA-021 | Build32 artifact | PASS | 1.0.1(32), com.legendstudy.app; receipt hash and codesign verify; Older artifact only; not current TASK01–06 code |
| QA-022 | Notices real APP/WEB sync | BLOCKED | release prerequisite; notices_private absent; no production create/read mutation |
| QA-023 | Beta daily live policy | BLOCKED | release prerequisite; campaigns empty; new configuration not installed |
| QA-024 | Admin beta production | BLOCKED | release prerequisite; essay_beta_admin_private absent; approval required |
| QA-025 | Feedback production | BLOCKED | release prerequisite; essay_feedback_private absent; feature enable/deploy pending |
| QA-026 | Monitoring production | BLOCKED | release prerequisite; essay_operations_private absent; legacy RPC is not new reporting surface |
| QA-027 | GA4 real receipt | BLOCKED | release prerequisite; Firebase config missing/default disabled; WEB collection loader/setup pending |
| QA-028 | Analytics real admin reporting | BLOCKED | release prerequisite; new RPC install pending plus modern-run/cohort/currency semantic gaps |
| QA-029 | Current deployment/Worker identity | BLOCKED | release prerequisite; Cloudflare readonly API 401; historical version is not live verification |
| QA-030 | Current version device E2E | BLOCKED | release prerequisite; available signed build32 predates TASK01–06; no verified latest installation |
| QA-031 | New evaluation/free rewrite E2E | BLOCKED | release prerequisite; Provider requests prohibited; stored reads cannot substitute new submission |
| QA-032 | Cross-platform actual sync/concurrency | BLOCKED | release prerequisite; no authorized local device+browser+staging deployed pair |
| QA-033 | Admin/user/anonymous live JWT matrix | BLOCKED | release prerequisite; synthetic ACL tests do not substitute deployed real-role verification |
| QA-034 | IAP store purchasability | BLOCKED | release prerequisite; Apple/Google product console and signed sandbox purchase not verified |
| QA-035 | Toss actual TEST approval | BLOCKED | release prerequisite; no checkout/payment executed; isolated transaction tests only |
| QA-036 | Performance thresholds/live API timing | BLOCKED | release prerequisite; no approved benchmark baseline or complete device/network measurement |
| QA-037 | iOS/Android device OCR accuracy and rotated photo | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-038 | iOS/Android actual TTS/PDF output | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-039 | Safari/mobile Safari/mobile Chrome flows | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-040 | Slow/offline/background/kill/session-expiry/device concurrency | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-041 | Store metadata/privacy review account/Data Safety | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-042 | Actual APP home/materials/saved/D-Day/MY regression | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-043 | Actual approved-admin setting audit and feedback assignment workflow | NOT_TESTED | actual user/device verification; Automated fixtures do not establish this result |
| QA-044 | Production deployment/store submission/payment/provider | SKIP | explicitly prohibited operations; Owner approval required; no execution |

## 4–8. APP·WEB·동기화·평가/OCR·Credit

Chrome 운영 `/my/essays/` 기존 로그인 세션에서 49건/5건씩/1–10페이지 및 잔액 UI95를 확인했다. 서울여대 무료 재첨삭 결과 두 문항, 재작성 안내, 최초 비교를 열었다. 문제1의 두 기준은 저장된 1→5(+4), 설명·그래프가 표시됐다. 신규 로그인·제출·재처리·TTS 실행은 하지 않았다. 현재 운영 화면은 최신 로컬 UI와 다른 버전이므로 로컬 구현의 배포 PASS가 아니다.

운영 SELECT (답안 원문 출력 없이 snapshot/result/checkpoint hash 확인):

| run | 상태 | parent | decision 기준 거래 |
|---|---|---|---|
| 경희 `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1` | completed | 없음 | reserve +1 / consume balance−1,reserved−1 |
| 서울여대 최초 `6ef28b49-12a5-4825-886d-548f0d9897df` | completed | 없음 | reserve +1 / consume balance−1,reserved−1 |
| 서울여대 재첨삭 `6fe629cb-7bfd-4907-b144-439b299cfdc3` | completed | 위 최초 | 해당 decision Credit 거래 없음 |

각 q0/q1/final/summary 및 재시도 checkpoint 존재. UUID/배열 순서를 공식 문항 순서로 추정하지 않았다. result md5 각각 `0583f3943a46d45cc39b1bcab31af71c`, `1e596b01ba5b48f17b8c14a07d360041`, `90ad0b01da88524d77ef3ca15f01fbb5`. 이는 **현재 보존/정산 관측**이며, 전체 DB 전후 동일성·모든 사용자 정합성을 증명하지 않는다. 종료 전 동일 SELECT 재조회에서 위 세 result hash/상태 및 거래 수(2/2/0)·순차감(−1/−1/없음)·예약 합계(0/0/없음)가 같았다. 이 제한된 샘플의 관측 간 불변만 확인했다. 운영 쓰기 0.

무료 재첨삭/실패 복구/중복 방지/paid·signup 잔액 분리는 격리 canonical ledger 테스트로 검증. 베타 end exclusive는 2026-11-11 00:00 KST; min(parent 완료+14일,end), accepted child 종료 후 finish, 신규 종료 후 거절, 30동시 claim 단일 grant, 자정 이월 없음, 예약/실패 1회 복구, 다음날 한도에 과거 복구 혼입 없음. 운영 정책 활성화는 별도 승인 필요.

B01은 [최종 UX 정책](final-feedback-ux-refinement-20261031.md)의 빈 재작성 + 명시적 원본 가져오기 + scoped Draft 우선 정책이다. 자동복사를 없앤 것을 결함으로 단정하지 않는다. 실제 두 진입 경로의 실기기 체감/명칭은 NOT_TESTED(P2 검수 후보). OCR/TTS/PDF는 mock 회귀 통과와 기기 출력/인식 정확도를 구분한다. 현재 TASK에서는 실제 사진 인식·신규 평가 품질을 검증하지 않았다. 학생 친화적 강점 소제목 전체 대학 적합성도 실제 품질 검수 잔여이며 임의 제목 생성/평가 원문 변경 없음.

## 9–13. 공지·분석·피드백·관리자·모니터링

- 공지: 단일 Supabase 콘텐츠/사용자 read revision, 익명 공개만, 만료/예약/APP·WEB 노출은 SQL 검사. 운영 신규 schema absent이므로 실제 관리자 작성→두 클라이언트 표시 PASS 아님.
- Analytics: GA4 행동/전환과 Postgres 평가·Credit 거래 진실을 분리. disabled/Noop 실패가 평가를 막지 않는 코드 회귀. 답안/OCR 원문·키·결제민감정보 allowlist 차단. 31-event 계약 일치는 전송 수신 증거 아님.
- 필수 이벤트 `app_open`, `web_visit`, `signup`, `login`, `essay_lab_open`, `university_select`, `exam_select`, `question_select`, `essay_editor_open`, `essay_submit`, `evaluation_completed`, `evaluation_failed`, `evaluation_result_view`, `rewrite_start`, `rewrite_submit`, `growth_analysis_view`, `beta_credit_used`, `feedback_submit`, `error_report_submit`: **각 실제 GA4 수신 상태 BLOCKED**. 공지/OCR/결제진입 실제 수신도 BLOCKED. 계약별 지원명은 기존 31-event 명세를 따르며 사용자 지시의 별칭을 새 이벤트로 임의 중복 생성하지 않았다.
- Firebase 설정 파일·WEB loader/stream 연결과 ANALYTICS_ENABLED 운영 활성화 필요. 관리자 집계 SQL 8 RPC 로컬 postcheck PASS여도 현대 exam/checkpoint 미포함, cohort/NSM 의미, paid LIVE/refund/currency 구분 GAP 때문에 배포 승인 패키지의 집계 의미 보완이 먼저다.
- 피드백: 만족도/유형 분리, 실패 시 작성 유지, idempotency/rate limit, 소유권/CAS 상태메모/audit. 기존 Owner review 링크 재사용. legacy Math/부분checkpoint review 링크 지원 공백은 기존 문서 참고. 담당자 지정 및 보류 상태의 요구 대응은 검증되지 않아 NOT_TESTED; 기존 new/reviewing/resolved/closed를 임의 변경하지 않는다.
- 관리자: official admin + 명시 capability; 일반/익명/service role grant 제한 synthetic PASS. 실제 각 역할 JWT 및 Owner 권한은 BLOCKED. 과거 Owner49기록 계정 403 롤백 이슈 미해소 상태를 승인된 관리자 추가로 우회하지 않았다.
- 비용: ACTUAL/ESTIMATED/UNKNOWN, 모델·유효기간 가격 snapshot, missing usage/call-time/cache/review model은 UNKNOWN. 성공률 completed/(completed+failed), 처리중 제외. 8동시 alert 단일 open, 롤백 시 operational/audit 보존. 새로운 집계 RPC는 audit write가 있어 운영 호출하지 않았다. 관리자 비용 수치를 실제 전원장과 대조한 검증은 BLOCKED.

## 14–16. 결제·보안·성능

- Toss TEST/APP 구매 안내 기존 코드·테스트 유지. TEST→실제 credit 금지, 중복 confirm/cancel/refund, 예약 credit 환불 차단 및 legacy 유지 117 isolated assertions PASS. 외부 Toss/StoreKit/Play sandbox 승인·거래 없음. LIVE 운영 설정 실검증과 스토어 상품 구매 가능 상태는 BLOCKED. 상품/3개월/신규가입3/14일 기존 정책 변경 없음.
- Observation RPC3개 실metadata: UUID signature, SECURITY DEFINER/fixed search_path, authenticated만 실행, anon/service_role 실행 차단. 이는 함수 실제 사용자 소유권 전체 JWT 보안검사와 다르다.
- 운영 SQL은 SELECT만, 최소3개 run와 메타데이터. 키/학생답안/OCR 원문을 증거에 저장하지 않는다. 로컬 ACL mock이 실제 Auth/JWT 권한 시험을 대신하지 않는다.
- 성능: APP test94s, analyze5.6s, WEB test34.04s는 **도구 실행 시간**이지 사용자 화면/평가 latency가 아니다. API/PDF/관리자 P50/P90/P95·브라우저별 UX·느린망/오프라인/백그라운드 측정 NOT_TESTED. 임의 통과 임계값 설정 안 함.

## 17–20. 결함·미검증·출시 위험·롤백

| ID | 심각도/유형 | 재현·근거 | 조치/출시 영향 |
|---|---|---|---|
| G01 | P0 출시 gate (환경/미적용) | live schema 조회: 신규 notice/feedback/ops/admin absent, beta campaigns0 | 승인·사전점검·SQL 적용·실제 역할/동기화 검증 전 HOLD |
| G02 | P0 검증 gate | build32 source가 최신 TASK01–06 코드와 다름; 신규 평가 E2E 금지 | 테스트환경/승인된 시나리오와 최신기기 검증 필요 |
| G03 | P0 검증 gate | 실제 IAP/결제환경/role JWT/전원장 정합성 미검증 | automatic PASS로 대체 불가 |
| G04 | P1 Analytics | Firebase/GA4 미설정, 보고 SQL 현대 run 집계 GAP | 의미 보완·Owner 설정 후 실수신/대시보드 검수 |
| G05 | P1 운영 권한 | 과거 Owner review 403; 현재 배포API401 | 로그인/권한 재확인, 임의 admin 부여 금지 |
| G06 | P2 품질 | WEB lint5warnings; 강점 소제목/B01 명칭 실제 검수 잔여 | 동작 변경 없이 후속 검수 |

위 gate는 새로 재현된 중복차감/결과유실 결함이 있다는 뜻이 아니다. **그런 결함 0건을 실환경에서 확정할 근거도 부족하다.** 테스트 삭제/SKIP 확대/검증 완화·기능 수정 없음.

롤백: 이번은 검수 문서/evidence만 commit; 해당 commit revert로 복구(앱코드/원장 영향 없음). 향후 운영 적용은 각 후보 README precheck→승인→install→postcheck, feature flag 먼저 off, 비어있지 않은 원장 destructive rollback 금지. WEB 기존 backup `/Users/woojinchang/.codex/legendstudy-backups/web-safe-preview-20261031` 존재 확인; 과거 asset hash manifest/설정 백업 보존. 현재 Cloudflare401로 실제 rollback 실행가능 권한 재확인 BLOCKED. Worker 미변경. 기존 앱build32 유지. 운영 롤백 실행 없음.

## 21–22. 자동 테스트와 실제 사용자 시나리오

자동: APP1306/0/7, WEB1460/0/4 (PASS/FAIL/SKIP). 합계2766PASS,0FAIL,11SKIP. Worker24, Payment117, ExamCredit18 및 후보SQL/동시성은 **별도 harness**로 총 UI case 수에 중복 합산하지 않는다. Analytics 계약31/14 PASS. 신규 기능 전체 실제사용 시나리오 BLOCKED, 기존 Chrome 조회·비교만 PASS.

초기 Python harness는 psycopg/PYTHONPATH 누락으로 시작 실패했다. 임시 venv에 psycopg 설치/PYTHONPATH 지정 후 동일 테스트 정상 통과. 코드/판정 완화 아님. notices/analytics fixture의 로컬 DB명 guard는 신규 isolated DB로만 바꿔 실행했고 이미 존재하는 global role CREATE만 생략했다. assertions는 유지했다. 전체 최종 원시 로그는 `/tmp/task07-*.log` (일시 파일), [기계 판독 요약 및 digest](../supabase/verification/task07/readiness.json)에 결과 보존.

WEB lint warnings: owner-review/app.tsx generation ref cleanup 1; math-release/exam-session-submit.tsx deps2; my/essay-session-retry.test.tsx unused args2. Production build는 통과했다. 실제 backend feature deploy PASS가 아니다.

## 23–26. Repository·Wiki·권고·Owner 승인

APP/WEB 코드 SHA는 §1. 이번 QA commit은 본 문서/요약/current-status/index/log만 포함. 최종 commit SHA는 Git log/최종 보고에서 확인하며 문서의 코드 기준 SHA와 구분한다. APP push 후 remote 일치 확인, WEB 변경/push 없음(이미일치). 기존 `.fvmrc` 유지. 테스트가 생성한 payment validation의 역사 필드는 원상복원했다.

Wiki는 기존 TASK01–06 문서와 [장기 데이터 전략](longitudinal-learning-admissions-data-strategy.md)·[결제 기반](payment-app-foundation.md)·[기존 안정화](pre-release-stabilization-20261030.md)에 연결한다. 새로운 데이터 모델/보존정책 선택 없음. 현 지시는 기존 정책의 최종검수이며 새 제품정책을 결정하지 않았다.

**HOLD**. TASK07 완료 조건 전체 충족으로 보고하지 않는다. 다음 승인/선행 작업이 필요하다:
1. 후보별 production precheck·검토 및 Owner SQL/활성화 승인. Analytics 의미 GAP 먼저 보완.
2. 실제 Owner/approved admin/일반/익명 권한 확인 및 배포 인증 복구.
3. 최신 통합 검수 빌드/테스트 환경으로 APP·WEB 동기화와 핵심 E2E; 실제 Provider/결제는 별도 승인 범위만.
4. Firebase/GA4 설정 후 실수신, 스토어 상품/샌드박스 확인, 기기/브라우저·네트워크·OCR/TTS/PDF 검수.
5. 검증된 정확한 배포 버전과 실제 롤백 권한 확인 후 최종 Owner 출시 승인.

운영 DB/Worker/Auth/Credit/History 변경0, Provider/실제 결제0, 배포/스토어 제출0. 신규 run·기존 재실행 없음.
