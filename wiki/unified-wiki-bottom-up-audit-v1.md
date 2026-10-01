# Unified Wiki Bottom-up Audit v1 — UWA-1B

2026-10-01 · **REPORT ONLY / NO REORGANIZATION** · Owner/Claude cross-review 대기.

## 1. Executive Summary

LegendStudy+는 native Flutter APP과 Next.js LAB이라는 두 접점 및 Shared Supabase Backend를 가진다. Backend migration/Essay contract/authorization의 물리적 소유자는 현재 APP repository이지만 논리적 사용 범위는 APP 전용이 아니다.

Architecture 판정 **HEALTHY_WITH_DEBT**를 바꿀 근거는 발견하지 않았다. 이번 감사의 핵심 문제는 구조 부재보다 **현재 사실에 도달하는 경로와 시점 표시**다. APP의 default main과 오래된 clone은 현재 Shared Backend를 대표하지 않으며 LAB도 architecture와 landing main이 서로 다른 최신 사실을 보유한다. “가장 최근 날짜 문서 하나”로 전체 truth를 대체할 수 없다.

가장 먼저 정리할 문서 문제는 U01 stale checkout 안내, U03 current/historical 상태 혼재, U04 cross-repo Auth 상태, U10 unpublished/diverged LAB 문서다. 기존 문서를 변경하지 않고 이 보고서에만 기록했다. 새 DB/UI/Unified Wiki 구현은 필요하지 않다.

[Inventory appendix](reviews/unified-wiki-audit-v1/documentation-inventory.md), [Source-of-Truth 초안](reviews/unified-wiki-audit-v1/source-of-truth-draft.md), [감사 방법과 closeout](reviews/unified-wiki-audit-v1/README.md).

## 2. Repository Truth Map

고정 기준 APP `7e1a5615c0551c54e853425328d84a0889cf6369`, LAB architecture `7bd9f2d11561267ec5abd3f54aa748830413dfed`, LAB remote main `fd4e1fb77748398960691371adafdea266a8b097`. 새 감사 commit 이전 snapshot이다. remote는 read-only `git ls-remote`로 확인했으며 fetch/pull/merge/rebase하지 않았다. a/b는 해당 비교 remote에 대한 ahead/behind다.

| Repository / purpose | Default / relevant branch | Local HEAD / remote HEAD | Ahead/behind | Worktree / clean | Last relevant commit | Doc / migration root | Production ownership / notes |
|---|---|---|---|---|---|---|---|
| APP / mobile + shared backend | default `main`; 이 작업 `codex/essay-scaffolding-vnext` | `7e1a561` / `7e1a561` | 0/0; vs remote main 248/1 | `/Users/woojinchang/.codex/worktrees/essay-scaffolding-vnext/레전드스터디 앱`; tracked clean, 기존 `supabase/.temp/` untracked 보존 | Oct1 gateway VERIFIED | `wiki/`; **`supabase/migrations/`** | Owner Supabase apply / APP migration+verification authority. Flutter release와 DB apply는 별개 |
| APP old development clone | `main` / 이 task 기준 사용 금지 | `d07671e` / remote main `d07671e` | main에 0/0이나 active backend 아님 | `/Users/woojinchang/development/legendstudy-app`; tracked clean, 기존 Owner local config untracked 보존 | 초기 main lineage | 오래된 wiki; SQL 1개 | remote와 sync여도 current task truth라는 뜻 아님 |
| APP older working tree | `codex/day-7-school-neis` | `b00627dd0807d54f5047f5fff71df403ba159dde` / 해당 branch remote 별도 미조회 | NOT_ASSESSED | `/Users/woojinchang/Documents/ChatGPT/레전드스터디 앱`; tracked clean, 기존 `.wrangler/` untracked 보존 | day7 branch snapshot | 그 branch wiki/SQL | Shared Backend/LSA 판단에 사용 금지. 삭제/정리 대상 아님 |
| LAB / architecture proposals | default `main`; `claude/intelligence-school-architecture` | `7bd9f2d` / `1a6b334` | **2/0** | `/Users/woojinchang/development/legendstudy-lab`; clean | Oct1 LSA2 draft; local-only LSA1 `11ab018` + LSA2 `7bd9f2d` | `docs/architecture/`, `docs/`, `todo.md`; canonical migrations 없음 | Cloudflare web/auth implementation repository. LSA draft SQL은 migration authority 아님 |
| LAB / current remote landing variant | `main` | local main `bc340aa` / remote `fd4e1fb` | local main 0/3; architecture vs remote main **5/3** | 별도 checkout 안 함; 이미 존재하는 Git object로 read | Sep27 landing Phase1 closeout `fd4e1fb` | README + docs + todo variants | remote commit이 현재 deployed artifact임을 이번에 재검증하지 않음 |

확인된 stale APP checkout **2개**. 별도로 LAB local main ref lag 1개, architecture local-only commits 2개. 이 숫자를 한 종류의 “stale repo”로 합산하지 않는다. APP remote HEAD/default main은 `d07671e985929ad1aa4ba2c811919cc592a37b34`이고 LAB remote architecture는 승인 baseline `1a6b33485a4c6dead921de977afcc8eeca10e25a`다.

**U01 (P0):** [APP README](../README.md)의 시작 경로 `~/development/legendstudy-app`를 그대로 따르면 migration 1개만 발견한다. 실제 canonical worktree에는 24개다. 이는 Claude의 과거 inventory 오판을 재현하는 설명이며 migration 손실 증거가 아니다. 별도 승인 후 시작 경로를 task-qualified 안내로 바꿔야 한다.

## 3. Documentation Inventory Summary

전체 tracked Markdown metadata: APP 130 + LAB architecture 18 = **148 distinct repo/path**. LAB remote main의 서로 다른 5개 버전을 추가해 **153 rows**. 신규 audit 4개는 모집단에서 제외한다.

| 지표 | 수 | 해석 |
|---|---:|---|
| CURRENT_CANONICAL | 25 | CURRENT와 CANONICAL 교집합 |
| HISTORICAL | 31 | currentness 기준; 올바른 과거 기록 포함 |
| STALE | 1 | 문서 전체를 최신 root inventory로 쓰기 부적합한 명확한 사례 |
| NEEDS_REVIEW | 16 | classification 기준; 일부 최신/일부 stale인 문서 포함 |
| UNKNOWN currentness | 71 | metadata로만 전수분류한 supporting 문서 등; 전 문장 최신성 확인 주장하지 않음 |
| DUPLICATE_CANDIDATE | 0 | 삭제/병합 가능한 문서 전체의 진짜 중복은 확정하지 않음 |

중복 내용 비교는 §7의 9개 영역으로 수행했다. “중복 후보 0”은 겹치는 문장이 없다는 뜻이 아니다. 문서의 범위/시점/권위가 달라 전면 통합 근거가 부족하다는 뜻이다. `PROPOSED` filename도 실제 상태의 authority가 아니다([Design v2](design-system-v2-proposed.md)는 채택/freeze 기록과 함께 읽어야 함).

Appendix에 모든 row의 path/title/domain/last commit/date/backlinks/currentness/authority/recommendation/reason을 제공한다. inline 상대 file link inventory에서 broken target **0**. absolute URL/bare code path/reference-style link를 자동 검사한 것으로 주장하지 않는다.

## 4. Current Truth Reconstruction

Production 열은 **기존 기록** 기준이다. 이번 감사에서 DB/credential/JWT/deployment를 조회하지 않았다. commit은 관련 문서의 마지막 변경 또는 명시된 closeout이며 모든 하위 기능의 배포 SHA가 아니다.

| Domain | Status | Canonical evidence | Relevant commit | Production? | Next gate | Uncertainty |
|---|---|---|---|---|---|---|
| APP | native 5-tab 구현, 자료/학습/MY와 gated Essay | [Current](current-status.md), [UI](ui-ux-v1.md) | `7e1a561` | 일부 backend live; store launch 완료 아님 | 남은 Owner device/release gate | 문서별 Owner acceptance scope 차이 |
| LAB | landing/auth 구현; Essay data는 prototype/mock, Quality UI 미구현 | LAB main@`fd4e1fb` README/docs; architecture@`7bd9f2d` | `fd4e1fb`, `7bd9f2d` | web 운영 기록; 이번 deployment 미조회 | Essay canonical mapping / Quality UI 별도 승인 | 서로 diverged branch가 동일 배포를 설명하지 않음 |
| SHARED_BACKEND | migration/contract/RLS/Quality 공유 foundation | [Quality verified package](../supabase/verification/quality_authorization/README.md) | `7e1a561` | recorded remote22 / local24 | pending별 개별 승인 | local SQL 존재 ≠ remote apply |
| CONTENT | 자료 검색/PDF/저장/최근/official exam mapping | [Database](database.md), [Materials closeout](materials-final-closeout-2026-09-27.md) | `fee8112`, `b20889d` | bounded ingestion/publication 적용 기록 | 남은 Owner final device coverage | 전체 archive 수집 완료 아님 |
| LEARNING | D-Day/Study Timer/self-scoring/trends 구현 | [Study](study-v1.md), [Scoring](day-8-d2-answer-scoring.md), [D-Day](day-7-dday-storage-proposal.md) | `320c7fa`, `aa4111d`, `c249200` | 저장/RPC 기존 acceptance | 후속 UX/gates는 기존 문서 | Badge 전체 engine/Community 미래 |
| ESSAY | L1 persistence/contract1.3; v3 prompt; original+strong Owner PASS | [Bakeoff](essay-lab-model-bakeoff-l2-b.md), [Worker](essay-lab-worker-provider-l2.md) | `9d8a296`, `7e1a561` | Production AI OFF | Owner model decision / later Round2 authorization | GPT candidate ≠ selected; offline/real/human gate 구별 |
| QUALITY | **LSA_2_PRODUCTION_AUTHORIZATION=VERIFIED** | [Gateway record](../supabase/verification/quality_authorization/gateway_verification.json) | `7e1a561` | SQL/tracking/auth VERIFIED | LAB mapping / console design | full answer live NOT_ASSESSABLE: case 없음 |
| AUTH | shared identity, native/browser provider flows | [Auth acceptance](auth-native-owner-acceptance.md), [Shared identity](essay-lab-shared-identity.md) | `1a1fbbe`, `2819b67` | Owner provider reports + independent Quality JWT record | deletion/revoke/rotation 별도 | Owner report를 이번 independent test로 바꾸지 않음 |
| CREDIT/BILLING | G1 ledger/server decision, paid→included | [Transactions](essay-lab-server-transactions.md), [Product](essay-lab-product-v1.md) | `db72764`, `4bf1e34` | core deployed record | 구매/coupon 별도 gate | IAP/subscription 미구현 |
| ACADEMIC | mock self-score 있음; 내신 raw pipeline future | [Academic roadmap](roadmap-academic-analytics.md) | `c165052` | transcript foundation 없음 | Essay 이후/수능 이후, sample 확보 | PHASED + SOURCE_GATED, cancelled 아님 |
| ADMISSION | university/target foundation; 공식환산/LS model future | [Data strategy](longitudinal-learning-admissions-data-strategy.md) | `c165052` | targets existing; Intelligence 미구현 | 공식자료 기반 정시→1월 확장 | formula ≠ model; eligibility 단순 bool 아님 |
| SCHOOL/B2B | App school preference/NEIS meals 완료; B2B future | [NEIS](day-7-neis.md), [School history design](school-history-and-coupon-design-v1.md) | `340d234`, `68553f3` | 개인설정/급식 경로 있음 | membership/program은 future design | school history “staged” 문구 U06 |
| ANALYTICS | Deep Analytics core goal; P0 design only | [P0](analytics-p0-launch-contract.md), [Student data](student-analytics-data-architecture.md) | `7dd2f00`, `dff7f68` | warehouse/pipeline ON 아님 | domain history 보존 / scoped later implementation | event≠domain fact |
| COMMERCIAL | credit / one-time ad removal / period intelligence 구분 | [Monetization](roadmap-monetization-and-in-app-learning.md) | `c165052` | credit core만; 결제 상품 전체 아님 | coupon/IAP/subscription 각각 승인 | 설계 채택≠구매 live |
| RELEASE/OPERATIONS | 기록/수동 Owner apply/tooling 존재 | [Operating](operating-principles.md), [Privacy](account-deletion-privacy.md), [Scope](product-scope.md) | `113ac5b`, `3552c7e`, `c165052` | release/삭제 final gates 남음 | 이번 Owner 목표 Oct10 기준 재정렬 | canonical mid-Oct 문구와 deadline 불일치 U08 |

### LSA-2C 상태를 압축해도 잃으면 안 되는 사실

- SQL APPLIED / migration tracking APPLIED / Quality operator registered. Operator actual JWT helper=true/list ALLOW. 일반 사용자 helper=false/list+detail403. anon3RPC401. forged JWT401/unsupported user-id argument404. 이것은 **기존 검증 기록**이다.
- `profile/school/admin_users`는 Quality 권한 authority가 아니다. 기존 17 Essay tables/44 functions catalog 보존 확인 기록 있음.
- full answer는 canonical RPC contract에서 허용하지만 legitimate evaluation case가 없어 Production 실제 반환 검증은 **NOT_ASSESSABLE**이다. VERIFIED를 “모든 detail 내용 실측 PASS”로 확대하지 않는다.
- local24 = tracked remote22 + provider005 pending + day_targets SQL-applied/ledger-absent. `20261001000100_quality_read_authorization`만 새 tracking에 포함. day_targets `20260930000100`은 별도 이슈로 보존한다.

## 5. Shared Backend Physical Ownership

| Logical domain | Physical repo / path | Canonical? | APP consumer | LAB consumer | Documentation | Drift risk |
|---|---|---|---|---|---|---|
| DB migration | APP `supabase/migrations/` | YES | backend | 같은 backend; migration authority 아님 | Quality package + migration records | LAB draft를 두 번째 ledger로 착각 |
| Identity/Auth | Supabase identity; APP `lib/`; LAB auth client + `functions/api/auth/` | same subject, surface별 code | native | browser | auth acceptance/shared identity + LAB setup | stale provider status |
| Essay schema/RPC | APP product/server/scaffolding SQL | YES | L1 mapping | future live adapter | product/persistence/transactions | mock DTO를 live truth로 오해 |
| Evidence/Contract | APP `tool/essay_lab/evidence/`, parser/finalize SQL | YES | Essay | future canonical mapping | data foundation/persistence | physical APP = mobile-only 오해 |
| Credit/Billing | APP credit/server SQL | YES | Essay | future shared consumer | transactions/monetization | Coupon별 balance 복제 위험 |
| Quality authorization | APP `20261001000100_quality_read_authorization.sql` | YES/APPLIED | shared DB gate | future `/ql` web surface | verification README + JSON | LSA2 proposal을 applied truth로 오해 |
| Worker/provider | APP `tool/essay_lab/`, worker/provider docs | canonical validation tooling | gated | future | worker-provider-l2 | Pilot PASS ≠ production deployment |
| Production verification | APP `supabase/verification/quality_authorization/` | sanitized record authority | backend handoff | LAB mapping input | README/JSON | 새 credential 재검증 불필요 |
| Architecture baseline | LAB `docs/architecture/ARCHITECTURE_BASELINE_V1.md` | approved **design** snapshot | cross-product | cross-product | APP product/Owner decisions + LAB baseline | 이후 live facts 누락된 frozen snapshot |
| Deployment operations | APP release/DB packages; LAB Cloudflare config/web docs | 각 surface별 | mobile build/Owner DB apply | web/auth deploy | APP operations, LAB release docs | code SHA와 deployed SHA 혼동 |

위 ownership은 registry/readme routing으로 드러내면 충분하다. 이번에 backend repository 분리나 migration 이동을 제안하지 않는다.

## 6. Current vs Historical Problems

| ID / priority | Exact evidence | Problem / recommended interpretation |
|---|---|---|
| U01 P0 | APP README path + old clone SQL1 / canonical SQL24 | task canonical branch/absolute checkout 먼저 검증. main sync만으로 current 판정 금지 |
| U02 P0 | [supabase README](../supabase/README.md), Quality verification package | initial10 tables/16 policies는 역사적 부분 inventory. 현재 backend entry pointer 필요 |
| U03 P0 | current-status의 `Ledger21`; migration reconciliation의 여러 과거 ledger 단계 | 최신 recorded22와 과거21/17/16을 scope/date 없이 비교하면 오판. current header + immutable stage labels 필요 |
| U04 P0 | product-platform-boundaries/product-architecture/LAB auth setup의 pending vs Sep28 acceptance | 과거 provider gate를 재개하지 않도록 현재 acceptance로 cross-pointer. Owner report와 independently verified 방식도 기록 |
| U05 P0 | 초기 overview/App-centric README vs Owner LegendStudy+ 관계 | 시작 index에 APP/LAB/shared physical owner를 짧게 명시하는 후속 변경 후보 |
| U06 P1 | current-status school history “staged migration” vs design “NO IMPLEMENTATION”; tracked school SQL는 selection뿐 | 실제 staged artifact 위치를 문서 소유자에게 확인. migration 생성/적용 추정 금지; 미tracked/private 영역 조사 안 함 |
| U07 P1 | design-system-v2-proposed header vs index/current-status Owner freeze | 파일명으로 status 추론 금지; 별도 status metadata 필요 |
| U08 P0 | product-scope/monetization mid-Oct vs 이번 Owner Oct10 before Yonsei | 후속 최소 current critical-path header에 최신 목표와 날짜를 명시; 이번 기존 문서는 수정하지 않음 |
| U09 P0 | LAB frozen baseline의 no-server-auth/day_targets debt/meal PLANNED vs APP closeout | baseline 자체를 rewrite하지 말고 이후 구현/검증 overlay link; meals는 APP scoped current fact |
| U10 P0 | LAB architecture local-onlyLSA2개; remote main3개 divergence | branch-qualified links와 remote availability 표시. remote main을 LSA 최신으로, local-only commit을 인수인계 가능한 원격문서로 오해 금지 |

| 반드시 분리할 상태 | 현재 잘 지켜지는 곳 | 위험 / 최소 보완 방향 |
|---|---|---|
| DOCUMENTED ≠ IMPLEMENTED | school/coupon design, analytics P0 | staged migration 표현 source 확인 |
| IMPLEMENTED ≠ PRODUCTION_APPLIED | provider005 pending | 최신 migration scope별 matrix entry |
| APPLIED ≠ VERIFIED | LSA package 단계별 기록 | RPC detail 실제 case 공백도 보존 |
| SQL_APPLIED ≠ MIGRATION_TRACKED | day_targets closeout | ledger repair를 기본 다음 작업으로 만들지 않음 |
| STRUCTURAL ≠ HUMAN PASS | Bakeoff 실험별 history | C3 Owner PASS가 이전 failed/UNKNOWN slot을 지우지 않음 |
| CANDIDATE ≠ SELECTED | current GPT candidate / AI OFF | 평가 성공을 자동 rollout로 연결 금지 |
| authenticated EXECUTE ≠ authorized data | helper/operator 내부 gate + 실제 deny | 권한 metadata 한 줄만 보고 공개접근 판정 금지 |
| OWNER_REPORTED ≠ INDEPENDENTLY_VERIFIED | auth-native-owner-acceptance + gateway record | 증거 유형/date 별도 칸 |
| NOT_ASSESSABLE ≠ PASS | full-answer gateway note | 종합 VERIFIED headline에 남은 적용 범위 포함 |

## 7. Duplicate/Overlap Findings

| Area / sources | Classification | Finding / recommendation |
|---|---|---|
| APP product architecture ↔ LAB approved baseline | DIFFERENT_SCOPE | physical implementation vs cross-product design. 같은 authority로 합치지 않음 |
| APP shared identity ↔ LAB auth setup | CROSS_REPO_POINTER_NEEDED | setup 절차 유지, 최신 acceptance status는 한 source로 연결 |
| APP Essay product/persistence ↔ LAB prototype migration | PROPOSAL_VS_CANONICAL | mock adapters는 future; production DTO 계약은 APP authority |
| APP LSA2C SQL/record ↔ LAB LSA1/2 | PROPOSAL_VS_CANONICAL | 제안 이유/테스트 역사는 보존; 적용 SQL signature/DTO는 canonical successor |
| APP academic roadmap ↔ LAB Intelligence master | DIFFERENT_SCOPE | Owner phased/source gates와 conceptual domain design 관계 명시 |
| APP admission strategy ↔ LAB landing3축 | DIFFERENT_SCOPE | 마케팅/정보구조 ≠ implemented analysis pipeline |
| APP current-status ↔ log/EOD | CURRENT_VS_HISTORICAL | 현재 fact / 과정 / dated handoff를 분리, 동일 current status 복제 금지 |
| LAB todo ↔ future handoff ↔ release docs | CROSS_REPO_POINTER_NEEDED | 역할 다른 문서의 반복된 “next gate” 문단은 stale 위험. 하나의 current pointer로 축약 후보 |
| APP review A ↔ LAB review B | NO_PROBLEM | 독립 검토는 중복 제거 대상 아님. 둘 다 HEALTHY_WITH_DEBT 역사 보존 |

문서 전체가 동일 사실/목적을 중복 소유한다고 확정할 TRUE_DUPLICATE는 없었다. 부분 요약/문단의 향후 통합은 Owner IA 결정 후 수행한다.

## 8. Missing Documentation

MISSING은 아래 질문에 대한 **단일하고 최신인 cross-repo 진입 답**이 없다는 뜻이다. 관련 사실이 어느 문서에도 없다는 뜻은 아니다.

| 외부 작업자 질문 | Availability | Evidence / gap |
|---|---|---|
| 1 LegendStudy+란? | PARTIAL | APP product + LAB baseline에 있음; root 경로에서 한눈에 복원 어려움 |
| 2 APP/LAB 관계? | PARTIAL | Owner clarified; LAB old README와 상위 구조 차이 |
| 3 shared backend 위치? | PARTIAL | 실제 APP migrations; LAB proposal에 canonical successor pointer 필요 |
| 4 현재 최신 branch? | MISSING | 양 repo 역할별 live branch registry 없음; U01/U10 |
| 5 실제 Production 적용? | PARTIAL | 상세 verification 존재; entry current/historical 혼재 |
| 6 pending migrations? | READY | latest quality package가 provider005/daytargets tracking 분리 |
| 7 현재 launch critical path? | PARTIAL | current-status next gates 있음; Oct10 deadline cross-repo 일치 필요 |
| 8 다음 작업? | PARTIAL | APP closeout 최신; LAB handoff 오래됨 |
| 9 먼저 읽을 문서? | READY(APP) / PARTIAL(cross-repo) | APP AGENTS/index Task Routing 있음; LAB AGENTS는 Next.js 중심 |
| 10 historical 구별? | PARTIAL | history/dated reports 존재; prep/apply/current header 혼재 |
| 11 design-only 기능? | PARTIAL | analytics/school 명시적; baseline/landing에서 runtime 혼동 가능 |
| 12 AI/DB/결제 Production? | PARTIAL | 세 domain별 gate 명확하나 한 headline로 읽으면 위험 |
| 13 오늘 다른 작업자 작업? | MISSING(cross-repo) | APP log 있으나 LAB local-only LSA가 remote에 없음 |
| 14 종료시 업데이트? | READY(APP) / MISSING(shared protocol) | APP AGENTS completion rule 있음; LAB 같은 daily protocol 없음 |

## 9. Source-of-Truth Draft

[21개 capability registry 초안](reviews/unified-wiki-audit-v1/source-of-truth-draft.md)을 제공한다. canonical fact/physical source/doc/actual vs future consumer/status를 분리했다. 없는 Academic Transcript/B2B Membership/Human QA persistence를 existing object인 것처럼 채우지 않았다.

새 `SOURCE_OF_TRUTH.md`, `AI_CONTEXT.md`는 **생성하지 않았다**. 초안의 승인과 위치 결정은 Claude top-down IA와 교차검토 후다. 현재 domain fact를 analytics/event로 대체하거나 Quality store를 복제하는 제안도 없다.

## 10. Daily Closeout Feasibility

**기존 current-status + log 재사용을 권고한다.** 세 역할을 위해 세 개의 매일 복제되는 문서가 필요한 것은 아니다.

| 역할 | launch 전 최소 운영 제안 | 금지할 오용 |
|---|---|---|
| CURRENT_STATUS | 현재 사실/조건부 gate/다음 행동 + 증거 링크 | 하루하루 과정 누적 |
| DAILY | 기존 `wiki/log.md` 날짜 entry: 변경, 검증, 미완료, commits | 전체 제품 status 복제 |
| HANDOFF | 같은 log entry 또는 task closeout의 작은 snapshot block: repo/ref, scope, next gate | 별도 stale todo를 매일 양산 |

기존 [EOD Sep25](eod-2026-09-25.md)는 특정 Owner review handoff 역사로 유효하다. 매일 동일 분량 EOD 신설 의무로 일반화하지 않는다. current-status는 현재 **11,991 bytes / 12,000 budget**이므로 append-only 운영을 지속할 수 없다. 후속 승인 시 current를 압축하고 과거 근거를 log/domain history에 유지해야 한다. 이번에는 이동/정리하지 않았다.

최소 closeout block 제안: date/time + task/domain + repo/branch/base/end refs + code/SQL/ledger/verification/human/production 각각의 변화 + check result + 남은 gate/다음 담당 + source links + remote sync. `NONE/NOT_RUN/NOT_ASSESSABLE`을 생략하지 않는다. 새로운 durable Owner decision만 decisions에 기록하고 routine 결과는 log에 둔다.

## 11. External AI Failure Modes

| 관찰된 실패 경로 | 증거 | 막는 최소 metadata |
|---|---|---|
| main만 보고 초기 App 수준 판정 | APP defaultmain vs current248/1 | task-specific repo/path/ref + inspected_at |
| development clone migration1을 전체로 판단 | U01 재현 | absolute worktree + migration count + record/source scope |
| LAB/App을 다른 제품으로 해석 | App-centric overview + LAB landing | LegendStudy+ 관계 1단락 + logical/physical owner 구분 |
| Auth 과거 pending을 현재 blocker로 복원 | U04 | current gate evidence date/type + superseding pointer |
| LSA proposal을 live schema로 사용 | U09/U10 | proposal → canonical SQL → applied/tracked → verified chain |
| planned capability를 구현으로 보고 | roadmap/landing/design 문서 | status와 actual consumer 열 |
| 로컬 최신 commit을 외부 AI가 볼 수 있다고 가정 | LAB ahead2 | remote_available YES/NO 및 필요한 branch/ref |

메타데이터를 코드/DB 변경권한으로 사용하지 않는다. 이 audit도 pinned snapshot이지 영구 current HEAD 정의가 아니다.

## 12. Acquisition/Handoff Readiness

| 항목 | 판정 | 실제 근거 / 남은 공백 |
|---|---|---|
| Repositories | PARTIAL | 경로/remote 확인 가능; stale/task branch routing 부족 |
| Architecture | READY | independent A/B + approved baseline + Owner principles |
| Environments | PARTIAL | toolchain/Supabase/Cloudflare docs 분산; cross-repo entry 없음 |
| Deployment | PARTIAL | Owner SQL procedures와 web release docs 있음; deployed SHA 통합 증거 없음 |
| DB ownership | PARTIAL | APP canonical24 SQL/verification 명확; shared 의미 discovery 약함 |
| Auth/identity | PARTIAL | 최신 acceptance 존재; stale LAB status와 evidence-type 혼재 |
| Security | PARTIAL | Quality 실제 deny/ACL 보존 기록 좋음; privacy/revoke 후속 gate 존재 |
| AI architecture | READY | product/contract/evidence/worker/real-vs-production 분리 기록 |
| Data provenance | READY | ingestion/evidence/hash/version history 문서 |
| Billing | PARTIAL | core ledger/decision clear; commercial future capability와 경계 숙지 필요 |
| Production capability | PARTIAL | feature별 기록 있으나 status/ledger 역사 혼재 |
| Technical debt | READY | A/B debt registers, 미구현과 risk 구별 |
| Roadmap | PARTIAL | Owner phase/source gates 있음; deadline/cross-repo next gate 정합성 |
| Operational procedures | PARTIAL | APP runbooks/AGENTS/checker 있음; 공유 handoff/remote availability 공백 |

전체 **PARTIAL**. 이는 기술실사 자체 수행/법률 실사 결과가 아니라 문서에서 찾을 수 있는 정도다. 별도 Due Diligence 문서나 인프라는 만들지 않는다.

## 13. Stale Checkout Prevention

후속 채택할 최소 protocol 제안:

1. 요청의 task domain에 맞는 canonical repo/branch/worktree와 dependency refs를 확인한다. default branch와 같다고 가정하지 않는다.
2. `git remote -v`, `git branch --show-current`, `git rev-parse HEAD`, `git status --short`, `git worktree list`를 확인한다. 민감한 remote URL은 출력 전 제거한다.
3. `git rev-list --left-right --count HEAD...origin/<branch>`는 cached ref 기준임을 기록한다. read-only `git ls-remote` 실제 remote ref와 비교하고 network unavailable이면 UNKNOWN으로 남긴다.
4. 현재 docs/SQL count와 task checkpoint를 대조한다. mismatch이면 올바른 checkout을 찾아 읽는다. 자동 reset/fetch/merge하지 않는다.
5. cross-repo consumer는 각 ref/remote availability를 적는다. LAB landing main과 architecture branch처럼 단일 HEAD가 모든 최신 domain을 포함하지 않을 수 있다.
6. 종료 시 변경한 repo만 commit/push하고 local/remote sync를 확인한다. 다른 branch 전용 문서를 current root로 착각하지 않도록 next gate와 source links를 남긴다.

어떤 AI도 오래된 두 APP checkout에서 이번 Shared Backend의 absence 결론을 내리면 안 된다. 그렇다고 해당 checkout의 독립 작업이나 Owner 파일을 지우지 않는다.

## 14. P0/P1/P2 Recommendation

| 우선순위 | 제안 | 필요한 승인/범위 |
|---|---|---|
| **P0 BEFORE LAUNCH** | 시작 경로/task branch metadata와 APP/LAB/shared 관계 짧은 안내 | 기존 root/index 최소 수정 별도 승인; repo 재배치 없음 |
| **P0** | current gate block: LSA VERIFIED 범위, full answer N/A, provider005/daytargets tracking 분리, AI OFF | authoritative record link 사용; 재검증 불필요 |
| **P0** | stale Auth/LSA proposal에 current pointer; LAB local-only 문서 remote handoff 계획 | 각 repo owner가 수행; 이번 LAB push 없음 |
| **P0** | Oct10 deadline과 승인된 다음 gate, current/log/handoff 최소 daily 규칙 | feature 개발 중단 없이 작은 문서 변경 |
| **P1 AFTER LAUNCH** | U06 학교 history artifact 상태 확인; proposed/accepted filename 혼동 metadata; 반복 status 문단 정리 | history 보존, IA cross-review 후 |
| **P1** | branch-aware link/status drift 검사 범위 확대 | 실제 필요 있는 checker만; 현재 검사 재사용 |
| **P2 LONG TERM** | Unified navigation/실사 package 자동 조립 평가 | doc consumer가 요구할 때; 대량 이동/새 framework 선행 금지 |

P0는 정보 탐색/오판 방지/일일 인수인계에만 제한한다. Quality UI, schema, payment, analytics 작업을 이번 audit의 P0로 추가하지 않는다.

## 15. Cross-Review Questions for Claude

1. 상위 IA가 **LegendStudy+ → APP/LAB → Shared Backend**를 보여주면서 APP의 물리적 migration authority를 보존하는가?
2. current facts와 FROZEN baseline/history를 어느 entry에서 연결할 것인가? baseline 내부 past debt를 조용히 고치지 않을 방법은?
3. LAB architecture local2/remote main3 divergence와 unpublished LSA가 외부 AI에게 보이는 방식은? 하나의 “canonical branch”로 뭉개지 않는가?
4. 현재 Quality VERIFIED와 full-answer NOT_ASSESSABLE를 동시에 표현하는가? SQL/tracking/gateway/human/product enabled를 따로 유지하는가?
5. 기존 APP current-status/log/Task Routing을 재사용하고 launch 전 문서량 증가를 최소화하는가?
6. Auth setup과 Owner acceptance/current independent verification의 authority를 구별하는가?
7. Unified registry에서 actual consumer와 future adapter를 구별하는가? LAB mock을 live Essay로 표기하지 않는가?
8. U06 staged school history 문구가 가리키는 공개 artifact가 있는가? 없다면 이후 어느 current 문구를 정정할 것인가?
9. Owner deadline Oct10와 오래된 mid-Oct roadmap의 충돌을 최소 어느 곳에서 정리할 것인가?
10. 읽기 경로 개선을 위한 P0 승인만으로 파일 이동/문서 병합/기능 구현까지 범위를 확대하지 않는가?

## 16. Final Audit Gate

UNIFIED_WIKI_BOTTOM_UP_AUDIT=COMPLETE (요청한 metadata 전수 + 핵심 내용 감사 범위). 전 문장 최신성/현재 live runtime 재검증을 의미하지 않는다. 71개 supporting 문서 currentness UNKNOWN은 appendix에 공개했다.

SHARED_BACKEND_OWNERSHIP=CLARIFIED; CURRENT_STATUS_RECONSTRUCTED=YES; SOURCE_OF_TRUTH_DRAFT=READY_FOR_REVIEW; DAILY_CLOSEOUT_RECOMMENDATION=REUSE_CURRENT_STATUS_AND_LOG_WITH_SMALL_HANDOFF; ACQUISITION_READINESS=PARTIAL.

FILES_MOVED=0; FILES_DELETED=0; EXISTING_CANONICAL_DOCS_CHANGED=NO; PRODUCTION_DB_CHANGED=NO; MIGRATION=NO; PROVIDER_CALLS=0. Credential/private artifact 내용에 접근하지 않았고 auth 검증을 재실행하지 않았다. 기존 audit/Owner files 보존. 새 감사 문서만 commit/push한다. 검증/closeout은 [audit README](reviews/unified-wiki-audit-v1/README.md)에 기록한다.

다음 행동은 **Owner/Claude 교차검토**다. Unified Wiki 구축, Quality/LAB adapter, Human QA persistence 또는 다른 기능 작업을 시작하지 않는다.
