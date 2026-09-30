# Platform Architecture Health Review — Cross Review A

2026-09-30 · Codex / Bottom-up implementation & live DB audit · **REPORT ONLY**

## 1. Executive Summary

**제안 판정: HEALTHY_WITH_DEBT.** 핵심 identity, 제출/평가 이력, CORE progress,
공식 evidence provenance, credit ledger는 서로 다른 사실을 분리하고 있다. 테이블 수를
줄이거나 새로운 generic foundation을 추가할 근거는 없다. 다만 다음 schema 확장 전에
권한 과다 부여와 미정의 업무 경계를 먼저 교차 검토해야 한다.

- **HIGH:** `day_targets`에 anon/authenticated의 `TRUNCATE` 등 불필요한 권한이 live로
  남아 있다. RLS는 TRUNCATE 방어가 아니다. 공개 REST에서 실행 가능한 경로를 입증한
  것은 아니며 공격/변경 테스트는 하지 않았다. 별도 보안 수정 승인이 필요하다.
- Human Quality Review는 canonical Production fact로 저장되지 않는다.
  `essay_owner_evaluation_status`는 table 이름이 아니라 migration 이름이며 실제 객체는
  owner lifecycle/credit projection RPC `essay_evaluation_status()`다.
- 학교/학년은 현재 profile preference다. 학교 이력, 검증된 B2B membership, 프로그램
  참여, 기관 사용권을 이 필드에 덧붙이면 현재 사실과 역사·권한이 충돌한다.
- `essay_learning_events`는 세 가지 interaction event다. 문서에 적힌 네 learning stage를
  실제로 emit하는 writer는 찾지 못했다. stage와 event를 혼동한 Analytics 문구를 바로잡을
  필요가 있다. CORE resolution 자체는 `essay_improvement_progress`에 보존된다.
- App/LAB은 같은 Auth identity를 쓰지만 LAB Essay adapter/type은 아직 mock이다.
  Production 계약이 공유 구현으로 이미 연결됐다고 보면 안 된다.

### 조사 기준과 한계

| 항목 | 확인된 기준 |
|---|---|
| App | `codex/essay-scaffolding-vnext`, 시작 HEAD `cca543dc7cda79ae31a653f0d56a181372cab3b3` |
| LAB (read-only) | `claude/intelligence-school-architecture`, HEAD `980e3b2b7845add127c5c7f1875ae068501b7444` |
| Live | 2026-09-30 12:48:43 UTC, transaction_read_only=on; public/essay_private catalog |
| 범위 | 43 tables + 1 view, 67 functions, 그중40 SECURITY DEFINER;21 remote migrations |
| Migration | remote21개 모두 local SQL AST MATCH; local22개 중 telemetry005 하나 DRAFT |
| 방법 | 기존 인증 Supabase CLI의 Management API, BEGIN READ ONLY/ROLLBACK; catalog/ACL/function/migration/storage configuration만 조회 |
| 제외 | 사용자 row, 답안/성적 원문, secret 값, 실제 권한 공격, SQL performance/load, 다른 외부 서비스의 운영 데이터 |
| CLI 부수효과 | 연결 도구가 login-role initialization 메시지 및 local project-link cache 생성; 제출 SQL에는 Auth/role DDL 없음. 내부 서비스 동작 전체를 무변경으로 인증하지 않음 |
| Evidence | [전체 live inventory 및 ACL](reviews/architecture-health-a/inventory.md), [sanitized catalog](reviews/architecture-health-a/catalog.json), read-only query 원문 동봉 |

**LIVE**는 실제 schema 존재, **DRAFT**는 미적용 파일, **DOCUMENTED/PLANNED**는
문서상 결정이다. IMPLEMENTED capability도 Production 트래픽/운영 승인과 동의어가 아니다.
데이터 행을 세지 않았으므로 비어 있거나 사용되지 않는다고 단정하지 않는다.

이번 Owner 메시지로 숙명·한양 일반답안 및 숙명 strong-answer Human Quality PASS,
CORE=0/Positive Learning/No Forced Defect real validation PASS를 기록한다.
Prompt `scaffolding-1.3-v3`, Contract1.3, Evidence `official-evidence-vnext-1` 유지.
이 승인 기록은 과거 raw/terminal receipt를 덮어쓰지 않는다. Primary model selection은
NO, Round2/Production AI는 OFF. 이번 audit provider calls=0.

### 근거 navigation

- [Product architecture](product-architecture.md), [Architecture](architecture.md), [Decisions](decisions.md), [Log](log.md).
- [Longitudinal strategy](longitudinal-learning-admissions-data-strategy.md), [Academic roadmap](roadmap-academic-analytics.md), [Monetization](roadmap-monetization-and-in-app-learning.md).
- [Essay product](essay-lab-product-v1.md), [data foundation](essay-lab-data-foundation.md), [scaffolding](essay-lab-scaffolding-persistence.md), [transactions](essay-lab-server-transactions.md), [worker](essay-lab-worker-provider-l2.md), [bakeoff](essay-lab-model-bakeoff-l2-b.md).
- [School/Coupon](school-history-and-coupon-design-v1.md), [Analytics P0](analytics-p0-launch-contract.md), [Analytics review](analytics-architecture-review-v1.md), [Account erasure](account-deletion-privacy.md).
- 실제 write/read: [Essay gateway](../lib/features/essay/essay_live_gateway.dart), [day events](../lib/features/home/data/supabase_day_event_repository.dart), [worker](../tool/essay_lab/live_worker.py), [SQL migrations](../supabase/migrations/).
- LAB 근거: 위 고정 HEAD의 `src/server/evaluation/mock-adapter.ts`, `src/app/lab/how-it-works/page.tsx`, `docs/architecture/INTELLIGENCE_SCHOOL_PLATFORM_MASTER.md`. 마지막 문서는 Claude 제안이며 live/Owner 승인 schema로 취급하지 않는다.

## 2. Current Product Capability Map

`Owner`는 canonical 문서에 결정이 보존됐다는 뜻이며 본 audit의 신규 실행 승인이 아니다.
trace는 Capability → domain fact → SoT → UI/consumer 순서다.

| Domain | Capability | Owner decision found | Current implementation / trace | Status | Gap |
|---|---|---|---|---|---|
| Content | 기출자료/search/filter | YES | source_posts→content_items/exams→Materials | IMPLEMENTED | coverage/publication 별도 운영 gate |
| Content | PDF/open/resource | YES | resources→resolver→native material detail/external target | IMPLEMENTED | native in-app exam viewer는 별도 gate |
| Content | 북마크 | YES | bookmarks→Saved/MY | IMPLEMENTED | 개인 current preference |
| Content | 최근 본 | YES | recent_views→Recent/MY | IMPLEMENTED | full reading history 아님 |
| Content | Recent Updates | YES | publication/source metadata→recent materials | IMPLEMENTED | published_at와 exam date 구분 |
| Content | source posts/exams/subjects/resources | YES | raw label+mapping→canonical catalog→App | IMPLEMENTED | taxonomy coverage/ingestion review 지속 |
| Learning | D-Day/추가 일정 | YES | day_targets→Home/settings | IMPLEMENTED | legacy profile fields/atomic primary gap |
| Learning | Timer/누적/추세 | YES | study_sessions segments/inclusion→shared aggregation→Home/MY/LAB | IMPLEMENTED | school/grade at-event context 부족 |
| Learning | Badge/Achievement | YES | 행동·검증된 성장 철학, 실제 award ledger 없음 | PLANNED | catalogue/award/reversal/version 결정 후 |
| Learning | Push | YES | bell placeholder; FCM 없음 | PLANNED | feedback email worker와 별개 |
| Learning | School setting/NEIS/급식 | YES | profiles NEIS pair→neis Edge→meal UI | IMPLEMENTED | verified membership/학교 history 아님 |
| Learning | Community | YES | FREE/retention, 장기 roadmap | FUTURE | early paywall 중심 아님 |
| Essay | 대학/문항/공식 근거 | YES | universities→essay_exams/questions/evidence/criteria→question package | IMPLEMENTED | archive bulk import 미시작 |
| Essay | session/draft/submission/attempt | YES | draft revision→immutable essay_attempts→student loop | IMPLEMENTED | Production AI entry gated |
| Essay | evaluation/dimensions/strengths | YES | evaluations + dimensions/evidence→Flutter detail | IMPLEMENTED | 실제 운영 모델 미선정 |
| Essay | improvement/CORE/NON-CORE/sentence | YES | items + progress.scaffolding_observation→CORE-first overview/detail | IMPLEMENTED | JSON envelope version strict validation 유지 |
| Essay | rewrite/re-evaluation/progress | YES | attempts + progress chain→learning history | PARTIAL | schema/UI/fixtures; real Round2 NOT_RUN |
| Essay | AI example rewrite | YES | generated_rewrites→optional assistance | PARTIAL | 학생 직접 재작성과 별도, production gated |
| Essay | AI processing/telemetry | YES | runs/lease/finalize→status RPC | PARTIAL | provider005 DRAFT; hosting/lease fit 검토 |
| Essay | evidence/prompt/model/contract versions | YES | canonical source + package/hash + output contract→adapter/parser | IMPLEMENTED | private validated stack ≠ registered Production model |
| Essay | positive learning/CORE0 | YES | promptv3/parser1.3 + frozen real calibration/Owner PASS | IMPLEMENTED | quality fact DB persistence 없음 |
| Essay | credits/billing | YES | grants/transactions/decisions→balance/status | IMPLEMENTED | verified purchase ingress 없음 |
| Essay | Quality Review/Console | YES | private reviews + Wiki, LAB architecture proposal | DOCUMENTED | canonical review/history/authorization 없음 |
| Essay | Golden Set | concept found | versioned private Pilot artifacts만 존재 | FUTURE | candidate→sanitization→approval→benchmark lifecycle |
| Academic | mock self-scoring | YES | own answers + official key/cutoff versions→result/MY/LAB | IMPLEMENTED | 학교가 발급한 성적 아님 |
| Academic | student score/trend | YES | version-bound mock result + learning aggregation | PARTIAL | 내신/공식 transcript backend 없음 |
| Academic | 내신/학기/학년/과목 | YES | current grade + UI/roadmap, transcript 없음 | PLANNED | source/semester/course/raw-label model |
| Academic | school transcript/Excel/CSV | YES | 학교 batch는 동일 academic engine 재사용 결정 | FUTURE | import/quarantine/review; 지금 ingestion 금지 |
| Admission | university master | YES | universities UUID→Essay/target universities | IMPLEMENTED | aliases/official source maintenance 제한 |
| Admission | target university | YES | student_target_universities→owner preference; full UI consumption 제한 | PARTIAL | application/unit/track/outcome와 구분 |
| Admission | department/unit/type/year | YES | roadmap + LAB fixtures; canonical admission entity 없음 | PLANNED | year-scoped unit/track identity 필요 시 설계 |
| Admission | public result/source | YES | source-grounded explorer roadmap | PLANNED | official result provenance/metric definition 없음 |
| Admission | official formula/student comparison | YES | 문서상 단계적 분석 | PLANNED | formula version/context/eligibility/input provenance |
| Admission | LegendStudy model | YES | official rule과 분리하는 분석 roadmap | FUTURE | validation/cohort/uncertainty; 공식값처럼 표시 금지 |
| Admission | school adjustment/subject-major weighting | concept preserved | longitudinal/admission design topics | FUTURE | authoritative input/validation 없음 |
| Admission | 수시 합격예측 | YES | evidence-gated future, 공부시간을 확률 입력으로 사용 금지 | FUTURE | outcome cohort/검증/Owner model scope |
| Admission | 과거 셀티 기능의 구체적 scope | NOT FOUND | App Wiki/docs + LAB docs 검색에서 specific source 없음 | MISSING_FROM_CURRENT_PLAN | UNKNOWN; Owner 원결정 자료 필요, 재구현 승인 아님 |
| Commercial | free grant/account/grant/transaction | YES | signup+3/G1→single ledger | IMPLEMENTED | quantity entitlement/purchase와 혼동 금지 |
| Commercial | paid→included repeat cycle | YES | billing decisions + parent relation→server RPC | IMPLEMENTED | attempt_no parity/평생 cap로 대체 금지 |
| Commercial | Coupon/Voucher | YES | promotion/b2b grant origin 재사용; campaign/redemption design | DOCUMENTED | IAP/Paywall phase 승인 후 구현 |
| Commercial | 광고제거 IAP/purchase | YES | monetization roadmap; store verified records 없음 | PLANNED | credit entitlement와 별도 권리 |
| Commercial | institution entitlement | YES/future | B2B policy proposal; no canonical rows | FUTURE | membership/program/scope/time + credit provisioning |
| Organization | Organization/School/Membership | YES/future | personal NEIS preference만 LIVE | DOCUMENTED | verified tenant boundary 없음 |
| Organization | Program/Staff/Roster/Entitlement | proposal | LAB design only | DOCUMENTED | current admin_users로 tenant role 대체 금지 |
| Organization | school.legendstudy.com/School Report | YES | product family/학교 분석 문서 | FUTURE | batch + program context + authorization |
| Intelligence | Product Analytics | YES | P0 contract; GA4/Firebase client infra 미구현 | DOCUMENTED | acquisition attribution + event wiring |
| Intelligence | Essay Quality Intelligence | YES | private reviews/metrics proposal | FUTURE | versioned human verdict persistence |
| Intelligence | Learning Intelligence | YES | deterministic study trends + progress facts | PARTIAL | metric definition/context/denominator |
| Intelligence | Academic Intelligence | YES | mock foundation + academic roadmap | PLANNED | verified score history/raw inputs |
| Intelligence | Admission Intelligence | YES | roadmap, current master/preferences | PLANNED | official vs LS model/source/validation |
| Intelligence | B2B Report | YES | student-engine reuse + cohort reporting principle | FUTURE | consent/access/membership at-time/aggregation |

## 3. Live DB / Domain Map

[부록](reviews/architecture-health-a/inventory.md)은 **모든44 relation과67 function**에
NAME/DOMAIN/PURPOSE/SoT/KEY RELATIONSHIPS/LIVE/RLS/WRITE/HISTORY/usage를 제공한다.
Column/PK/FK/UNIQUE/CHECK/index/policy/grant/trigger는 [catalog](reviews/architecture-health-a/catalog.json)에 있다.

| Domain | Live objects | write authority / lifecycle |
|---|---|---|
| Identity/Profile | profiles, admin_users | auth.users 확장; owner-scoped preference; admin은 feedback allowlist |
| Content | source_posts/content_items/exams/subjects/exam_subjects/resources, bookmarks/recent_views, ingestion_quarantine | ops publication + owner personal state |
| Learning | day_targets/study_sessions | OWNER-RLS; duration/segment validation; day primary client sequence |
| Essay source | universities, essay_exams/exam_resources/questions/question_evidence/evaluation_criteria | reviewed ops source/mapping; question-scoped constraints |
| Essay learning | practice_sessions/drafts/attempts/evaluations/evaluation_dimensions/evaluation_evidence/improvement_items/improvement_progress/generated_rewrites/learning_events | owner RPC + worker strict finalize; most results/history immutable |
| AI processing | essay_ai_processing_runs | worker claim/lease/fencing/finalize/reconcile; result and run separate |
| Billing | credit_accounts/grants/transactions, essay_billing_decisions | finance/server authority; balance derived from ledger |
| Academic scoring | answer_key_versions/exam_questions/grade_cutoff_versions/mock_exam_attempts/mock_exam_answers + availability view | source publication + authenticated scoring RPC |
| Admission | universities, student_target_universities | shared institution identity + owner interest |
| Operations | feedback_submissions/notifications, resource_resolver_quota | feedback RLS/admin; service lease/quota RPC |
| School/Analytics future | no school master/org/transcript/review/analytics warehouse table | NEIS preference external identity; learning_events is scoped interaction log |

**Deployment evidence:** neis, feedback-notification worker, resource-resolver Edge functions are
ACTIVE. delete-account is **not listed**, so local implementation is not live deletion capability.
No Production Essay worker deployment was performed or inferred.

**Migration history:** 21/21 remote entries match local SQL AST; the sole local-only migration is
`20260929000500_essay_provider_provenance_telemetry.sql`. No remote-only/missing-local/duplicate
migration found. Initial baseline is represented locally. This corrects the risk hypothesis “remote-only
schema has advanced without files”: it is **not observed at this snapshot**. Future manual DDL drift
still requires catalog comparison. No migration was restored/applied.

## 4. Canonical Source-of-Truth Map

| Fact | Canonical source of truth | Other representations | Health |
|---|---|---|---|
| authenticated user | auth.users.id | profiles.id; App/LAB independently stored sessions | CLEAR |
| current personal profile | profiles | UI caches / Auth display metadata not commercial authority | CLEAR |
| current school selection | profiles NEIS office+school pair | NEIS response/display label | CLEAR |
| school membership/history | absent | current school selection cannot prove either | MISSING |
| university identity | universities UUID | Essay FK; LAB slug fixture needs mapping | CLEAR |
| current university interest | student_target_universities | future application/preferences projections | CLEAR |
| application/outcome | absent | target≠applied≠admitted | MISSING |
| source material | source_posts/resources | derivative text/cache/display | CLEAR |
| official question criterion | essay_questions/evaluation_criteria + source mappings | prompt assembled input; examples not rubric | CLEAR |
| exact evaluation evidence bytes | versioned package/source/derivative hashes | DB durable identity/mapping; package assembly manifest | CLEAR |
| submitted essay | essay_attempts | draft is work in progress; raw provider input bound by hash | CLEAR |
| logical evaluation result | essay_evaluations + normalized children | parsed wire JSON / UI view models | CLEAR |
| CORE progress | essay_improvement_progress + stable improvement_items | learning_events/analytics cannot override | CLEAR |
| physical AI execution | essay_ai_processing_runs | private Pilot receipts for separate experiments | CLEAR |
| Human Quality judgment | private review/Owner record currently; no Production canonical review | lifecycle RPC and reviewer signature not sufficient | MISSING |
| credit balance/reservation | aggregate credit_transactions by account/grant | account is identity, billing decision is policy | CLEAR |
| entitlement/purchase | no verified durable purchase/tenant policy yet | grant is fulfilled credit, not full usage right | MISSING |
| D-Day | day_targets current UI | unused legacy profiles.target_* path | OVERLAP |
| study duration | validated study_sessions/segments + inclusion | trends/mean/streak are derived | CLEAR |
| mock answer/score | mock_exam_answers/attempts + frozen key/cutoff version | grade/raw score derived, not official transcript | CLEAR |
| academic official record | absent | profile grade + mock scoring cannot substitute | MISSING |
| current material recency | recent_views | not a complete study/reading history | CLEAR |
| event funnel stage | attempts/evaluations for submissions; interaction events for UI-only acts | event stage column vs missing writer | AMBIGUOUS |
| B2B impact/quality rates | no complete canonical inputs/metric definition | analytics dashboard would be derived | MISSING |

## 5. DB Health Matrix

**KEEP**: 37 distinct live relations (see exhaustive per-object appendix). Immutable result/history,
source/mapping, ledger/decision and physical processing run are intentional separation.

| Entity/group | Classification | Reason |
|---|---|---|
| profiles | KEEP_BUT_CLARIFY | current settings acceptable; membership/commercial/history must not accumulate here |
| day_targets | KEEP_BUT_CLARIFY | proper multiple-event fact; excessive ACL and non-atomic primary change need separate fix |
| admin_users | KEEP_BUT_CLARIFY | feedback binary authority, not platform/B2B role catalogue |
| essay_generated_rewrites | KEEP_BUT_CLARIFY | AI assistance separate from student rewrite; operation gated, no deletion proposal |
| essay_learning_events | KEEP_BUT_CLARIFY | interaction events useful; writer unavailable, analytics wording misleading |
| student_target_universities | KEEP_BUT_CLARIFY | current interest, not applications/outcomes or all track choices |
| subjects | KEEP_BUT_CLARIFY | content area taxonomy; cannot silently become full school course master |
| profiles.target_date/target_label + old day-target repository | LEGACY_OR_DEPRECATION_CANDIDATE | new UI uses day_targets; old provider has no active consumer found except shared clock import |
| legacy D-Day read paths | CONSOLIDATE_CANDIDATE | one current fact/UI source; confirm all consumers before later retirement |
| profile as future history/tenant container | SPLIT_CANDIDATE (future extension only) | current row not automatically wrong; adding longitudinal facts there would lose meaning |
| Human Quality Review | MISSING_FOUNDATION | explicit verdict/reviewer/versioned evaluation binding absent |
| school/context history | MISSING_FOUNDATION | current UPDATE loses past context; accepted design already exists |
| Org/Membership/Program/Institution Entitlement | FUTURE_DO_NOT_CREATE_YET | design tenant/actor/time/benefit policy first |
| Academic import/transcript, Admission result/formula/model | FUTURE_DO_NOT_CREATE_YET | approved source samples/context precede persistent contract |
| Golden Set/Metric Registry | FUTURE_DO_NOT_CREATE_YET | governed artifact/definition can precede new tables |

No live table was confirmed redundant or safe to delete. `NO_REFERENCE_FOUND` for an event writer
or target-university consumer is not evidence of no external/service use.

## 6. Duplication / Boundary Findings

### Object and naming boundaries

| Term A / structure | Term B / structure | Relation | Recommendation |
|---|---|---|---|
| auth.users | profiles / LAB user | DIFFERENT projection, same identity | one UUID; no separate LAB/School/Essay account |
| Auth metadata | profile | OVERLAPPING display hints | auth provider identity vs owner-editable profile; never trust metadata for grants/roles |
| school preference | Organization Membership | DIFFERENT | self-selection cannot authorize teacher/cohort access |
| universities | Essay university / Admission university | SAME institution identity | reuse UUID, map LAB slug; year/unit/track separate |
| target university | application / admission preference | OVERLAPPING intent | preserve actual applications and decisions independently |
| mock attempt | school transcript | DIFFERENT | self-scoring vs school-provided grade; do not place transcript in scoring JSON |
| improvement_progress | learning_events | DIFFERENT | progress canonical; events UI behavior only |
| evaluation status | Human Quality Review | DIFFERENT | lifecycle success≠educational acceptance |
| evaluations | processing_runs | DIFFERENT | logical request/result vs physical attempts/unknown/fencing |
| credit grant | coupon/voucher | DIFFERENT | redemption source produces one idempotent grant |
| credit transaction | institution entitlement | DIFFERENT | accounting movement vs eligibility/scope/time policy |
| domain fact | analytics event | DIFFERENT | DB owns submitted/completed/consumed; analytics does not become second ledger |
| current status | history/event | DIFFERENT where documented | synchronized lifecycle projection is useful; no independent conflicting authority |
| Essay source | Admission source | OVERLAPPING provenance philosophy | reuse hash/source/locator discipline; do not cram official admission metric into essay evidence role |
| content subject | academic course / raw school label | DIFFERENT granularity | area→course→curriculum→raw label mapping, no generic taxonomy shortcut |
| attempt | submission | SAME submitted act in current Essay vocabulary | UI term may differ; draft and physical run remain separate |
| evaluation | review | DIFFERENT | model result vs human judgment; never overwrite model output with review |
| institution / organization / university / school | contextual DIFFERENT | organization tenant may reference school institution; do not assume all are universities |
| program | cohort | OVERLAPPING but not SAME | program participation and report population/effective dates need decisions |
| subject / course | issue category / Essay criterion / metric | DIFFERENT | evidence criterion is not educational course taxonomy |

### Essay normalized vs JSON and state ownership

- `essay_evaluations`: logical status/request_kind + input snapshot/provenance + summary, strengths,
  checklist. Dimensions and used-evidence relationships are normalized children.
- `essay_improvement_items`: stable root. `essay_improvement_progress`: per-evaluation state and
  previous_progress chain; versioned `scaffolding_observation` JSON carries CORE focus and sentence
  observations. Sentence observations retain a real root; no orphan/null linkage model.
- CORE is selected priority, not synonymous with all improvements. UI presentation does not delete
  NON-CORE history. `NOT_ASSESSABLE` review context is not a fake resolved/open state.
- `essay_generated_rewrites`: generated artifact, not student submission; must remain secondary.
- `essay_ai_processing_runs`: physical attempt status/lease/token/result selection/unknown/timing.
  Logical evaluation and billing can remain reconciling while outcome is uncertain. That separation
  prevents unknown transport from being misclassified as a free failed evaluation.
- `essay_billing_decisions`: policy/version/current reserve/settle/release plus included_by chain.
  Ledger, not decision display state alone, is the movement authority.
- `essay_evaluation_status`: read-only owner projection over the above. `reconciling` may be computed,
  not an extra independent stored status. **LIFECYCLE_ONLY** for Quality Review sufficiency.
- Worker signed review receipt binds output/package/reviewer and expiry. It is a technical quality
  guard, not a complete durable human verdict/history/appeal model.

### History, time, NULL, raw and derived

| Area | Actual preservation | Gap / constraint |
|---|---|---|
| Essay | immutable submitted text/hash/context, result supersession, progress chain, source/model/prompt regime | privacy erase deliberately removes learning facts; human review persistence absent |
| Credit | grant origin + idempotent movements/reversals + decision policy | no verified store purchase fact; tenant benefit is not a ledger delta |
| Mock | own raw choices + official key/cutoff version + derived score/certainty | official key does not make student score an official school transcript |
| School/profile | current school/grade/status | silent UPDATE loses past context; no fake historical backfill |
| Target university | current university/year intent | NULL year unspecified, not all years; cannot reproduce old applications |
| Source content | raw labels/hash/parser, mapping confidence/version | mutable source metadata is not whole archival byte history; Essay manifest retains raw/derivative versions |
| Academic/admission/org/formula | no canonical history implementation | effective academic/admission year, recorded/corrected time and revision policy design required |
| Metrics/report | raw/session/progress facts mostly reusable | definition/version/denominator/cohort unknown; registry table not required immediately |

`exams.year` and `academic_year` distinguish calendar and academic axes; admission year, grade,
semester, event timestamp, publication timestamp and effective period must not be collapsed into
one year string. Target year is not university identity. `student_target_universities`의 status는 interested/considering/planned이고 admission_type/intended_division은 preference text다. UNIQUE(user,university,year)는 같은 대학·연도의 여러 실제 전형 지원 이력을 표현하지 못한다. Raw school course/unit/track/metric labels
must survive normalization, following existing exam_subject mapping practice.

NULL cost means unavailable, not free; provider actual cost vs list-price estimate remain distinct.
NULL official_weight means unknown, not zero; diagnostic level1–5 is not university points.
Unavailable grade/cutoff is not zero performance. A future metric needs an explicit unavailable/
not-applicable/pending context instead of interpreting every NULL identically. No blanket schema
change is proposed from this review.

### Golden Set and source/import boundary

Private Pilot packages already preserve exact inputs, prompts, outputs and receipts. A future Golden Set needs candidate selection, permission/minimization, sanitization, human approval and immutable benchmark membership/version. Production student-table flag alone cannot record those transitions or prevent private content reuse. Candidate/evaluation linkage should stay restricted; export a separately governed versioned package. No new Golden Set table is required for the next design review.

Content ingestion has staging/private preparation, validation/quarantine and controlled publication. Reuse hash-based duplicate detection, raw labels, resumable review and explicit approval for later school/admission imports. A byte duplicate is not a semantic revision; do not silently discard a revised official source. Archive/source content and provider/student judgments remain different source classes.

### Authorization / RLS / SECURITY DEFINER

All43 tables RLS-enabled; all40 SECURITY DEFINER functions pin empty search_path. Owner-facing
Essay RPCs derive identity/session ownership; workers finalize with lease fencing, finance roles
post grants/refunds. `essay_private` is not a client-accessible helper surface. Authenticated users
cannot directly rewrite Essay immutable children or the ledger. Scoring submit/fetch enforce own
study/attempt context. These are strong reusable patterns, not blanket authorization certification.

`essay_worker`/`essay_finance`/`essay_executor` are separated roles; postgres/admin operations remain
privileged. BYPASSRLS/owner access is intentionally outside student isolation. Current tenant policy
is **one owner**, not an organization roster. School staff need an explicit verified membership/
scope/program boundary, not `profiles.school_* = school_id` or `is_feedback_admin()` alone.

**AUTH-01:** live `day_targets` grants anon/authenticated TRUNCATE/TRIGGER/REFERENCES in addition
to DML. The migration grants intended DML without stripping inherited defaults. TRUNCATE bypasses
row policies. Both roles are NOLOGIN and no exposed arbitrary-SQL route was demonstrated; classify
as HIGH excessive privilege / latent reachability risk, not proven REST exploitation. No test mutation.

`admin_users` + `is_feedback_admin()` is a binary feedback/moderation gate with no domain role,
review assignment or tenant scope. Do not reuse it as blanket Quality/Academic/Admission/B2B access.

Edge `verify_jwt=false` metadata alone does not establish unauthenticated sensitive access; service
notification and resolver/NEIS handlers have different intended trust boundaries. Runtime negative
JWT/tenant tests and deployed bundle verification were not rerun in this read-only metadata review.

### Document/live and cross-repository drift

| Document says / implies | Live/code says | Authoritative / action needed |
|---|---|---|
| Analytics P0 §L2_SHARED_CONTRACT: emit four named learning stages as learning events | event_type permits rewrite_started/example_viewed/source_opened; no real event writer found | live constraints/code; revise contract/wiring plan before KPI claims |
| Account deletion: all user rows cascade; school/grade/D-Day only in profile | credits detach owner and ledger/billing retained; day_targets separate; delete-account not deployed | live FKs + edge list; reconcile erasure/retention and deployment docs before launch |
| Academic roadmap “no Production schema implements any” candidate profile/targets/essay records | profile, target universities, study/mock/Essay foundations live | preserve higher academic feature as planned, update overly broad absence statement later |
| LAB how-it-works says actual login/shared account unavailable | shared Supabase Auth implemented and Owner login identity PASS | actual auth code/Owner verification; copy drift, not second identity |
| LAB Essay types/fixtures look product-like | uppercase mock lifecycle lacks live reconciling/strict result/credit contract | mock adapter clearly stub; require explicit mapping before integration |
| recent Gate D log says Owner pending | current audit request accepts strong-answer/positive quality PASS | new Owner decision supersedes current status only; historical logs/receipts unchanged |
| proposed LAB School/Intelligence architecture names new tables/roles | none exists live | PROPOSED/DESIGN ONLY; no implicit migration authorization |

### Delete/erasure and telemetry

`essay_erase` authorizes owner, coordinates outstanding credit release, removes session learning
facts by cascade. Billing/ledger retain their accounting history with deleted identity/evaluation
links detached where specified. Auth deletion candidate and avatar cleanup are not a deployed
end-to-end guarantee. A retained free-form reason/external reference must not be assumed anonymous.
Future school-provided transcripts, review notes and derived reports need explicit purpose/retention/
erasure propagation before collection; immutable history does not override privacy requirements.

No GA4/Firebase implementation carrying student essay/grade bodies was found. Product Analytics is
planned, while notification/quota are operational logs, learning events are domain interactions,
progress is learning fact. Do not emit ingestion bodies or purchase truth to general analytics.

## 7. Missing Foundations

These are sequencing recommendations, **not approval to create tables**.

| Foundation | Why / dependent capability | Recommendation | Create now? / Owner decision |
|---|---|---|---|
| Human Quality Review | evaluation-bound reviewer/verdict/dimensions/tags/note/time/history; Quality PASS rate | DESIGN FIRST, then CREATE SOON when Console persistence approved | NO; reviewer roles, rubric version, revision/adjudication/retention |
| school/grade context history | longitudinal analysis and future cohort reports cannot infer past school from current profile | existing design review → CREATE SOON before longitudinal launch | NO; approved correction rules, initial snapshot vs unknown history |
| attribution persistence | acquisition facts cannot be reconstructed after anonymous signup | DESIGN FIRST before acquisition launch | NO; minimize identity bridge/consent/scope, not a new domain ledger |
| verified purchase/redemption | IAP/refund/coupon replay-safe ingress to credit system | DESIGN FIRST in approved IAP/Paywall track | NO; store verification/refund/expiry + one grant per redemption |
| Org/Membership/Program | verified staff/student roster and at-time scope | DESIGN FIRST before B2B write or tenant report | NO; institution types, affiliation evidence, multi-membership |
| institution entitlement | use-right eligibility/scope/term/quota + credit provisioning | DESIGN FIRST | NO; pooled vs individual, revocation, unused grants/refunds |
| Academic raw/import | actual transcript facts/source/review/correction needed for internal grades | DESIGN FIRST when representative school source available | NO; self-reported vs verified, curriculum/semester/course/scale |
| Admission result/formula | official published metric source/year/unit/track required for comparisons | DESIGN FIRST with reviewed representative sources | NO; source rights/metric meaning/formula inputs/version |
| LS analysis model | cannot conflate official calculation and validated inference | DEFER | NO; validation/outcomes/uncertainty gate |
| Golden Set | governed reviewed benchmark distinct from student production | DESIGN FIRST as versioned sanitized artifact lifecycle | NO table required yet; reuse immutable package hashes |
| Operator audit | multi-reviewer/tenant/source approval actions cannot be reconstructed from feedback notification logs | DESIGN FIRST with authorized operations | NO; actor/reason/before-after/scope/retention, existing ledger remains independent |
| Metric definition/version | reports need stable numerator/denominator/exclusions/regime | DESIGN FIRST in docs/code; registry DEFER | NO; define core metrics before storage |

## 8. Recovered Owner Decisions

| Owner decision | Current doc | Current implementation | Recovery classification / disposition |
|---|---|---|---|
| native App + deep-work LAB, same identity/engine | product-architecture / academic roadmap | App real Flutter; LAB separate session/shared Auth; academic engine not duplicated | PRESERVED / IMPLEMENTED identity |
| Study Timer/actual-time totals | core-app-improvements / study docs | validated sessions and shared aggregates | IMPLEMENTED |
| Badge/Achievement = real behavior/verified growth | academic roadmap §9 / longitudinal | no award catalogue; intentionally no decorative fake badge UI | DEFERRED, INTENTIONALLY_DEFERRED |
| NEIS/school/meal | school docs/current-status | live neis + owner profile selection, Owner device PASS | IMPLEMENTED |
| school change history/correction limits | school-history-and-coupon | current profile update only | DEFERRED, not superseded; P0_NON_BLOCKING design |
| Community free/retention future | monetization §18 | not implemented | PRESERVED, INTENTIONALLY_DEFERRED |
| 광고제거 IAP | monetization | not implemented; no verified purchase records | DEFERRED, no evidence of cancellation |
| Essay no lifetime rewrite cap; paid→included repeat | product/transactions/monetization | server decision chain/G1 ledger | IMPLEMENTED contract; real Round2 deferred |
| Positive Learning / no forced defects / CORE0 | Essay product + current Owner review | promptv3/offline + real calibration accepted | PRESERVED / IMPLEMENTED, not model selection |
| Quality Console | worker/longitudinal/LAB proposal | signed technical review guard + private human artifacts only | PRESERVED / DEFERRED; persistent review missing |
| School B2B uses same student analysis engine | academic roadmap/product-architecture | future proposal, no tenant DB | PRESERVED / DEFERRED |
| Coupon/Voucher is distribution into existing ledger | school-history-and-coupon | credit grant origins exist, redemption absent | DOCUMENTED / DEFERRED to IAP/Paywall |
| academic analysis and raw history | academic/longitudinal | mock only, not transcript | PRESERVED / DEFERRED |
| Admission explorer / target unit / official vs LS model | academic/longitudinal | university/target foundation only | PRESERVED / DEFERRED |
| 수시 합격예측 | academic/longitudinal | future evidence gates; no predictor | PRESERVED_FUTURE |
| 셀티-specific legacy capability | no exact source in searched App Wiki/docs or LAB docs | unknown | NEEDS_OWNER_CONFIRMATION; POSSIBLY_MISSED scope, not confirmed MISSED |

No decision is labeled SUPERSEDED without a replacement decision. Absence of code is not proof
that an accepted future capability was forgotten. Current documents are not a complete archive of
all external Owner conversations; specific 셀티 history cannot be truthfully recovered beyond this.

## 9. Architecture Debt Register

| ID | Domain / severity / type | Current state | Why it matters | Recommended direction | When / dependency |
|---|---|---|---|---|---|
| A01 | Learning HIGH AUTHORIZATION | day_targets client TRUNCATE/TRIGGER/REFERENCES | RLS does not cover TRUNCATE | separately approved least-privilege correction + negative access tests | before next release/security signoff; Owner DB executor |
| A02 | Quality HIGH MISSING | no durable human review; status RPC lifecycle only | cannot reproduce educational PASS/reviewer/history/report | bind append-only/versioned judgments to immutable evaluation, independent of result | before Quality Console persistence; review policy/roles |
| A03 | Analytics MEDIUM DOC_DRIFT | stage interpreted as event; writer not found | wrong funnel completeness claims | reconcile event vs facts and minimal writer plan | before P0 KPI launch; analytics contract |
| A04 | Profile HIGH VERSIONING | school/grade current update only | future school reports rewrite past context | preserve accepted history/current projection, unknown prehistory explicit | before longitudinal/B2B data collection; correction/retention policy |
| A05 | Commercial HIGH MISSING | purchase/redemption/tenant entitlement absent | second ledger or insecure grant ingress risk | verified source→idempotent grant; entitlement separate policy | IAP/Coupon/B2B phase; entitlement/refund decisions |
| A06 | Privacy HIGH DOC_DRIFT | deletion doc all-cascade; retained ledger; Edge absent | incomplete launch erasure promise | inventory retained fields/derived exports + deployment/E2E plan | before deletion/Store readiness; privacy Owner |
| A07 | AI Ops HIGH FUTURE_RISK | 75s transport/120s lease, slow Pilot;005 draft | production timeout/reconciliation mismatch | preserve async architecture; lease/hosting/provider policy review | before production activation; not current model selection |
| A08 | Cross-repo MEDIUM AMBIGUOUS_BOUNDARY | LAB mock types/id/status differ from live | accidental incompatible integration | explicit DTO mapping/contract regression/shared fixture provenance | before LAB live Essay; App canonical contract |
| A09 | Learning MEDIUM DUPLICATION | legacy target fields/repository alongside day_targets | ambiguity in future consumers | identify consumers, one canonical UI path; later retire only by approval | before further calendar changes; migration/erasure review |
| A10 | Learning MEDIUM UNDER_ENGINEERING | primary target clear/set separate calls | partial failure leaves no primary | atomic command candidate; keep unique constraint | separate focused UX/write review, no fix now |
| A11 | Admission MEDIUM PROVENANCE | master/interest only, no units/results/formula version | future official vs inferred conflation | representative source-led design; reuse university ID | before explorer/calculator source ingestion |
| A12 | Academic MEDIUM MISSING | self-score only, current context | transcript truth/semester/course lost if forced into mock | raw source/import review/correction design | before school Excel work; sample/consent |
| A13 | Admin HIGH FUTURE_RISK | binary feedback admin, owner RLS only | staff access could become overbroad | domain/tenant reviewer permissions design | before multi-user operations; roster/role trust |
| A14 | Intelligence MEDIUM AMBIGUOUS_BOUNDARY | metrics not frozen; history available unevenly | incomparable CORE/pass/impact rates | define version/denominator/exclusions/regime before dashboard | report design; no registry table yet |
| A15 | Roadmap LOW DOC_DRIFT | Selti exact scope unavailable; some old broad absence claims | accidental scope loss or unauthorized resurrection | link original decision if provided; retain unknown meanwhile | Owner cross-review |

No proven generic-framework over-engineering or unnecessary history table was found. Highest risks
are authorization and missing semantic boundaries; do not treat the register as an implementation queue.

## 10. Simplification Opportunities

| Current complexity | Simplification idea | Benefit | Risk | Data migration? | Recommend now? |
|---|---|---|---|---|---|
| legacy profile D-Day + new multi-event API | converge remaining consumers on day_targets after usage proof | one current calendar truth | older client/data compatibility | possibly | review only |
| future dashboards joining many Essay children | one documented read projection/view if real query cost warrants | fewer client joins/consistent semantics | hiding history or unbounded aggregation | no raw migration expected | DEFER until measured |
| LAB mock types duplicate contract vocabulary | generated/validated adapters and cross-repo fixtures | drift detection | bundling UI mock contract with DB internals | no | design before live integration |
| analytics table desired for every domain event | derive submission/credit/progress metrics from canonical facts | no duplicate balance/progress truth | UI-only starts still need event capture | no | approve principle, no implementation |
| potential per-product user/university/ledger | reuse existing stable IDs and one ledger | avoids reconciliation | contextual entities still needed | no duplicate creation | KEEP boundary |
| proposed universal source/import/taxonomy system | reuse validation/quarantine/hash pattern, not universal table | bounded scope | distinct provenance roles conflated | no | avoid premature framework |

Normalized evaluation detail is justified by provenance, ownership and chain integrity. No EXPLAIN,
production workload or row-size benchmark was run; “query too complex” is **not established**.
Use future read models for actual timeline/dashboard needs, not premature denormalization.

## 11. Strong Existing Foundations

1. **One identity:** auth.users UUID extends to profile/Essay/credit/preferences; App/LAB sessions are
   independent, not separate people. Preserve native App / web product boundaries.
2. **Essay immutable learning facts:** submission timing/hash, superseded result, stable issue and
   per-evaluation progress chain enable longitudinal review without turning telemetry into truth.
3. **Official evidence discipline:** raw PDF→versioned reviewed derivative→question role mapping→
   deterministic package, prompt/output versions independent. Example≠rubric; length target≠scoring tolerance.
4. **Credit transaction system:** account/grant/ledger/decision separate; idempotency, reversal,
   reserve/release and paid/included chain. Coupon and institution provisioning must reuse it.
5. **Server authority / constraints:** student owner checks, worker/finance roles, empty search_path,
   lease fencing, terminal guards, composite references. Reuse this pattern after addressing A01.
6. **Content ingestion pattern:** raw labels, parser/source hashes, mapped taxonomy, validation and
   quarantine. Reuse the process discipline for academic/admission imports, not a premature generic CMS.
7. **Academic self-score provenance:** answer key/cutoff versions and raw selected answers remain
   separate from derived score/grade certainty.
8. **Time/uncertainty:** exam calendar/academic year and NULL official weight/cost distinguish facts
   that must not be silently inferred.

## 12. Cross-Domain Collision Check

| Planned area | Decision | Existing reuse / collision avoided |
|---|---|---|
| Quality Review | NEW_FOUNDATION_NEEDED (DESIGN FIRST) | evaluation immutable binding; do not overwrite output/status |
| Golden Set | DESIGN_FIRST | private versioned packages; no production-student “golden=true” shortcut |
| Organization | DESIGN_FIRST | Auth identity + distinct institutional entity; not a second user |
| Membership | NEW_FOUNDATION_NEEDED (DESIGN FIRST) | verified affiliation/effective-time; not profile school preference |
| Institution Program | DESIGN_FIRST | scoped participation; not global user status |
| Institution Entitlement | DESIGN_FIRST | policy scope/time→existing credit grants, no new balance |
| Voucher/Coupon | EXTEND_EXISTING | campaign/redemption evidence→idempotent G1 grant |
| Academic Transcript | NEW_FOUNDATION_NEEDED (DESIGN FIRST) | course/raw/source/term; not mock attempts |
| School Bulk Import | DEFER | existing quarantine/validation house pattern after raw contract |
| Admission Result | NEW_FOUNDATION_NEEDED (DESIGN FIRST) | university UUID+unit/track/year/metric/source |
| Official Formula | DESIGN_FIRST | immutable official source and version/effective rules |
| LegendStudy Scoring Model | DEFER | separate model version/validation, not official formula |
| Metric/Reporting | REUSE_EXISTING / DESIGN_FIRST definitions | canonical facts→derived projections; registry only if justified |

### Do not build

- Duplicate LAB/School/Essay user, university master, or credit balance/ledger.
- Membership authorization derived only from profile.school/NEIS code.
- Transcript stuffed into mock scoring, or official source quality assigned to self-reported scores.
- Voucher as another wallet; institution entitlement reduced to one grant row.
- Human review overwrite of evaluation JSON, or `completed` relabeled quality PASS.
- Golden Set as an unsanitized flag on production student data.
- Official admission formula merged with LS inference/model or raw label discarded after normalization.
- Generic taxonomy combining courses/criteria/issue categories/metrics; universal source table without source semantics.
- Production model registration, new foundation migrations or schema cleanup from this report.

## 13. Top Risks / Top Gaps / Top Strengths

| Rank | Risk (evidence) | Missing/unclear foundation (evidence) | Strong foundation (evidence) |
|---|---|---|---|
| 1 | A01 day_targets overgrant, live ACL | A02 human review absent, lifecycle RPC source | auth.users/profile identity, live FKs/shared Auth |
| 2 | A06 erasure promise vs retained ledger/deployment | A04 school/context history absent | immutable attempts/results/progress guards |
| 3 | A13 treating personal school/admin as B2B authority | A05 purchase/redemption/tenant policy absent | G1 ledger/server decisions/idempotency |
| 4 | A07 Pilot quality mistaken for production readiness | A11/A12 official academic/admission raw provenance | official evidence source/derivative/version package |
| 5 | A03/A08 analytics and LAB contract drift | A14 metric definition + event wiring | restricted worker/finance RPC and checked source mappings |

### Reporting readiness: recomputable is not already measured

| Metric | Canonical inputs | Readiness / remaining gap |
|---|---|---|
| CORE resolution rate | items + progress chain + per-evaluation CORE selection | calculable within retained comparable regimes; define denominator, recurred/not-assessable, superseded exclusion |
| rewrite submission rate | session attempt_no + prior evaluated attempt | calculable; exclude operator re-evaluation, deleted history and incomplete cycles explicitly |
| rewrite-start/view/source-open funnel | learning_events | incomplete until real writer confirmed; submission is not proof of UI start/view |
| quality PASS rate | versioned human judgments | unavailable as canonical Production metric; private sample not population rate |
| model latency/unknown rate | physical runs / terminal times | available fields, but provider gate off; selected-result bias and unknown denominator matter |
| actual cost | provider authoritative cost/cost_basis | NULL unavailable; estimated list cost separately named |
| credit balance/history | ledger/grants | reconstructable; decision release vs unknown reconciliation respected |
| study trends | raw sessions/segments/inclusion | reconstructable deterministic aggregate; not proof of score improvement |
| score improvement | self-score versioned results | only comparable exams/scales/context; school transcript missing |
| School/B2B impact | at-time membership/program/consent + learning/score facts | not ready; cannot infer roster from current school selection |
| admission prediction accuracy | versioned inputs/prediction + verified application/outcome cohort | not ready; target preference is not outcome |

Index/constraint audit: no invalid index or unvalidated constraint found in scoped catalog. PK/FK,
version uniqueness, selected-result uniqueness, credit idempotency and progress-chain restrictions
are present. day_targets at-most-one primary is not atomic at-least-one behavior. No data-level orphan
scan or query-plan/load test performed, so performance/data-health certification remains out of scope.

## 14. Before Next Schema Change

1. **Security:** separately review A01 exact privilege reachability and minimal correction. No new
   generic role/table is needed to fix an excessive existing grant.
2. **Quality:** decide reviewer identity/assignment, verdict and dimension vocabulary, rubric version,
   correction/adjudication history and erasure. Can begin bounded design from existing evaluation IDs.
3. **Organization:** Owner must settle school/academy/other institution scope, staff verification,
   student roster consent, multi-membership and effective dates before tenant schema selection.
4. **Entitlement/Voucher:** retain single ledger; decide campaign redemption idempotency/refund and
   institution pooled vs individual rights. Existing coupon design is the starting point, not a fresh wallet.
5. **Academic:** obtain representative permitted transcript/import samples; identify raw school labels,
   curriculum/grade/semester/scale and correction workflow. Mock sources cannot fill missing official facts.
6. **Admission:** select one verified official result/formula sample with year/unit/track/metric meaning;
   distinguish official computation from LS model. Specific 셀티 preserved scope needs Owner source.
7. **Cross-repo:** freeze App/LAB Auth/DTO/ID/status mappings before replacing mock adapters; proposed
   School platform docs remain proposed until cross-review acceptance.
8. **Metrics/erasure:** define retained facts/denominators/deletion propagation first. No broad analytics
   warehouse, registry, Golden Set student flag or foundation batch is authorized.

### Seven preservation questions — audit answer before any future design

| Question | Review answer |
|---|---|
| Historical fact and occurrence/record/correction time? | Essay/ledger strong; school/membership/transcript/review require explicit at-time/history design |
| Reconstructable from immutable source? | Essay package/attempt + scoring source version yes within retention; current profile preferences cannot reconstruct past |
| Loss through UPDATE? | school/grade/targets and legacy calendar projections lose prior state; corrections must not invent backfill |
| Same student identity? | use auth.users UUID; affiliation changes never change student identity |
| Learning / Decision / Outcome? | study/attempt/score=Learning; target/application=Decision; admissions result=Outcome; do not substitute one for another |
| Privacy/authority/consent/retention? | owner RLS exists; B2B reviewer/cohort access and erasure need separate policy; immutable does not mean perpetual personal retention |
| Derived treated as raw? | totals/score/CORE rates/report/model estimates need inputs/version/uncertainty; official formula and LS model remain distinct |

## 15. Recommended Next Architecture Actions

1. Owner/ChatGPT/Claude cross-review this evidence-backed report and the separate LAB proposal.
2. Authorize a narrowly scoped A01 privilege correction/security test separately; reconcile deletion
   and analytics contract claims before release promises.
3. Review Human Quality persistence and school/context history boundaries first, using existing
   evaluation and identity keys. **Do not create schema until that design is accepted.**
4. Schedule purchase/Coupon and B2B entitlement decisions in their own tracks; preserve G1 ledger.
5. Gate academic/admission foundations on representative source material and Owner scope decisions;
   preserve raw labels, effective-year context, corrections, review and uncertainty.
6. Keep model-selection/Production worker/real Round2 outside this architecture review.

**STOP:** no refactor, cleanup, new migration, Quality Console build, Organization/Membership,
Academic/Admission schema, provider request or deployment follows this report automatically.

### Completion and qualification

ARCHITECTURE_AUDIT=COMPLETE for requested read-only investigation/report scope.
LIVE_SCHEMA_REVIEW=PASS (catalog scope, not runtime security certification).
MIGRATION_HISTORY_REVIEW=PASS. OWNER_DECISION_RECOVERY=PARTIAL (specific 셀티 source unavailable).
PRODUCT_CAPABILITY_MAP/CANONICAL_DATA_MAP/DB_HEALTH_MATRIX/DUPLICATION_AUDIT/
MISSING_FOUNDATION_AUDIT=COMPLETE. Remaining unknowns are explicit findings, not invented facts.
Production code/DB/RLS/Auth changes, migration creation/application, provider calls and deployment=0.
Validation: read-only query AST guard, 44-relation/67-function inventory coverage, 21/21 migration AST correspondence, Wiki links/routing, private hash/exclusion and changed-file secret scan. Runtime/Flutter/build tests not run because only documentation changed; no live row or mutation tests. Final Git/validation results are reported with the commit handoff; report baseline HEAD remains immutable.
