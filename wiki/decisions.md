# Durable Decisions

This file records long-lived product and architecture decisions. Routine progress belongs in `log.md` and `current-status.md`.

## 2026-09-12 — Project independence

LegendStudy is fully separate from Muselry, including repository, codebase, Supabase, secrets, OAuth setup, identifiers, wiki, and deployment.

## 2026-09-12 — Native app, not WebView

LegendStudy will not be implemented as a simple WebView wrapper around `legendstudy.com`.

## 2026-09-12 — Canonical knowledge location

The repository-local `wiki/` directory is the official long-term development knowledge base. There must be only one canonical `wiki/current-status.md`.

## 2026-09-12 — Agent role split

- Codex: main coder + implementation lead (updated Day 4-A)
- Claude: UI/UX lead + support coder / code reviewer (updated Day 4-A)
- ChatGPT: planning, architecture, specification, review
- Manus: execution, Git/build/deployment support; Supabase direct work only when specifically useful
- User: final product decisions and default direct executor of Supabase SQL/migrations

## 2026-09-12 — Public repository during early development

The repository starts public to reduce multi-agent access friction. Before private conversion, access for all required development agents must be verified. Secrets are forbidden from Git regardless of repository visibility.

## 2026-09-12 — Structured ingestion

The app should consume normalized structured data. `legendstudy.com` content should be ingested into the backend rather than scraped by the mobile app during normal usage.

## 2026-09-12 — Login philosophy

Public study-resource access should not require login where possible. Login is primarily for personalization and synchronization.

## 2026-09-12 — Production application identity

Owner-approved in Day 2 / issue #3: use `com.legendstudy.app` for both Android
applicationId/namespace and the iOS Runner bundle identifier. Dart package remains
`legendstudy_app`; both platforms display `레전드스터디`. The iOS test-only bundle
uses `com.legendstudy.app.RunnerTests` to remain distinct from the app target.

This decision replaces Day 1's temporary identity and is independent of Muselry.
It does not imply Apple/Google registration, signing or OAuth configuration.
If platform registration reports a conflict, report it to the owner and keep the
choice unresolved rather than silently inventing another production identifier.


## 2026-09-12 — Content normalization and source evidence

Separate private source_posts from public content_items. One source post may
contain multiple content items; exam-type items optionally have shared-ID exams
metadata and raw subject occurrences. All content types may have resource links. Preserve raw labels and source provenance after normalization;
unknown values remain NULL rather than forced into modern taxonomy. Curated
subjects are versioned; historical variants require their own reviewed mappings.
Calendar year and academic/CSAT year are distinct fields.

## 2026-09-12 — Content access and personal data

Public active content is readable without login; published descendants must also
have a visible parent content item and subject occurrence when scoped. Mobile clients cannot write content
or source metadata. Personal profiles/bookmarks/recent views are auth-user-owned
under RLS. Auth-user removal cascades only personal data; content deletion is
restricted and normal unpublishing is an explicit inactive state.

## 2026-09-12 — Resource locations and ingestion identity

Preserve source URLs first; landing pages are not assumed to be direct file URLs.
No bulk mirroring or Supabase Storage setup in v0.1. Future mirrors must preserve
original provenance. Persist stable ingestion keys independent of display order,
normalized labels and mutable link queries. Ambiguous reconciliation requires
review; unique constraints alone do not make parsing idempotent.

## 2026-09-12 — Recent views and historical design-task boundary

Keep one recent_views row per `(user_id, content_item_id)`, upserting the server timestamp;
analytics event history is separate future scope. Day 3 produces a draft migration
and offline static review only. No SQL application, project creation, remote push
or merge is authorized by this design task.

## 2026-09-12 — Day 3 independent-review remediation

Claude's reported verdict was C (important corrections needed). Preserve the
existing entity architecture and raw evidence; add a backend quarantine queue.

1. LegendStudy's mandatory external post ID with source is the canonical ingestion
   identity. URL is provenance/location, never a fallback conflict key.
2. Assign `legendstudy-{external_post_id}-{source_content_key}` once (key moved to content_items). main or stable
   semantic keys identify source exams; never title, taxonomy or display position.
3. Taxonomy activity does not control source-content publication. Publish reviewed
   exams/occurrences/resources independently; inactive master joins fall back to raw labels.
4. Source-link-first remains. Attachment identity must be deterministic; same-content
   normalized URL collisions go to quarantine. URL UNIQUE is deferred for lack of
   evidence about legitimate reuse. Provenance corrections preserve resource UUIDs.
5. Notifications remain v1.0 product scope, with specific schema deferred to a later
   v1.0 milestone. No speculative profile arrays.
6. pg_trgm and the broad active_filters index are deferred until measured need.
   Stored sort_date is an exam-date sorting proxy, not a historical fact.
7. Verified mappings are immutable to automated ingestion **by contract**. S-9 is
   partially applied: no override GUC or service-role protection trigger in v0.1.
   The checker requires the contract and document rule. Before actual ingestion,
   assess a separate enforcement migration/management workflow; runtime protection
   against arbitrary service_role writes is not claimed.
8. ingestion_quarantine persists ambiguous evidence privately, including failures
   whose normalized transaction rolled back. Only trusted backend CRUD; no app API.
9. Duplicate content remains inactive with merged_into_content_item_id; trusted transactional
   merges validate cycles and personal conflicts. No automatic personal migration.
10. Profile id UPDATE enables key-preserving upsert; recent UPDATE grants only its
    two conflict keys and the trigger stamps time. Runtime coverage is tracked in
    database.md; the post-deployment recent upsert test now passes.

The supplied directive identifies S-7/S-8 (taxonomy), S-9 (verified protection) and
S-12 (profile upsert). It does not supply Claude's complete S-1–S-15 numbered review;
other numbers cannot be reliably assigned. Coverage is recorded by directive topic
rather than fabricating review IDs. At this remediation stage, independent
re-review had not yet been performed.

## 2026-09-12 — General public content layer (supersedes exam-centric draft)

LegendStudy app uses a general public content layer (`content_items`).
`source_posts` is ingestion/provenance-only, and `exams` is specialized metadata
for exam-type content. Bookmarks and recent views target content_items, not exams.

- Move common source identity, slug/title, original URL, publication and soft-merge
  pointer to content_items. Keep one authoritative parent is_active; remove exams'
  duplicate identity/publication columns. Assigned slug values remain stable.
- Use exams.content_item_id as shared PK. A generated constant exam discriminator
  with composite FK enforces exam-type specialization. Occurrences reference that
  shared key; resource occurrence/content composite FK preserves same-exam integrity
  with no redundant exam_id. Non-exam PDFs and attachment-free columns are valid.
- Home is latest **known source** publication/modification (greatest of timestamps),
  not ingestion time. No reliable modified time means publication fallback without
  a synthetic bump. Exam sort_date remains separate historical-date sorting proxy.
- Source classification is a reviewed ingestion step. Ambiguity persists privately
  in quarantine; new resources/modified title never manufacture a new content ID.
- Unified title/summary search covers university/year wording. Actual multi-year
  essay evidence makes a universal single admission_year unsafe. Defer extra common
  university/year fields and separate essay metadata until typed filtering is needed;
  retain raw evidence. No university taxonomy/master now.
- Native content cards/details may open original articles externally. Full article
  bodies are deferred; normal app browsing never scrapes HTML or wraps the website.
- During pre-deployment design, the initial file was revised in place. This is
  superseded by the applied-migration immutability decision below.

## 2026-09-13 — Dedicated deployed backend and evidence policy

LegendStudy uses its own Supabase project, separate from Muselry. The project name,
ref `stlhijzpjfgwwdgunlsd`, region and verified-at-report server version may be
recorded in canonical docs as target identifiers; they are not credentials.
Never store test-user passwords, access/refresh JWTs, service-role or secret keys.
Reconfirm the intended target for future DB operations rather than borrowing any
other application's environment.

Applied migration artifacts are immutable, including historical comments. Future
DB changes must be new migration files; a successful deployment is not permission
to replay or rewrite the initial artifact. Generated fallback notes are contingency
options only and require a reviewed new migration if ever needed.

Validate client-path RLS with actual PostgREST REST requests and real anonymous or
user JWT contexts. SQL Editor SET ROLE is not authoritative client-path evidence
for this project because editor session behavior may differ. Distinguish owner-
reported runtime results, structural policy review and tests directly performed
by an agent; never promote a structural check into unreported behavioral coverage.

## 2026-09-13 — UI/UX and implementation ownership

Claude leads app-wide information architecture, screen hierarchy, interaction flow
and design-system refinement, and reviews Codex UI implementation. Codex remains
the implementation lead for Flutter/data/state/repositories/integration, tests and
builds, including implementation of Claude's specifications. ChatGPT retains
planning/architecture/specification/review/coordination; Manus operations support;
the owner retains final product/scope decisions and default SQL execution.
Day 4-A establishes minimal data states only; no final screen/card design is adopted.

## 2026-09-13 — Approved UI/UX v1.1 product decisions

- Four bottom destinations: Home / Materials / Study / MY. Saved moves under MY.
- Stored personalization requires authentication, including school/grade settings,
  bookmarks/recent views, study history/totals, personal notifications/account settings.
- School search/selection remains guest-accessible; school persistence requires login.
- Guest timer execution may be allowed; durable study history requires authentication.
- Social-login-only: Kakao / Google / Apple / Naver. Facebook, X and email/password
  signup are excluded from v1.
- Free-with-ads + ₩4,900 one-time support purchase removes ads permanently. This is
  neither a subscription nor a core-feature unlock. No interstitial ads in v1;
  protect PDF/timer/login/school flows and important CTAs from ads.
- School settings, NEIS meals and study timer/history are promoted into v1 product
  scope; implementation is staged and their backend is outside Day 5.
- wiki/ui-ux-v1.md is the canonical UI implementation specification, normalized
  from the owner's approved Day 5 directive; see its provenance statement.

## 2026-09-19 — Study analytics, achievement and admissions are three separate layers

Study and Mock Exam are the first data sources of a longer chain, not standalone
features: Study → Subject Study Tracking → Academic Record → Academic Analytics
→ Achievement Engine, and Academic Profile → Target University/Department →
Admissions Engine. The boundaries are binding:

- Study time belongs to learning diagnosis; score change belongs to Academic
  Analytics; admission probability belongs to the Admissions Engine and is
  computed only from 내신, 모의고사 성적, 대학별 반영 규칙, 모집단위, 수능최저,
  과거 입결 and official 전형 data.
- **Study time is never a direct predictor of admission probability.** A
  structure such as "100시간 공부 → 합격확률 +10%" is rejected.
- Correlation between study time and score change is expressed as correlation,
  trend or observed change — never as causation.
- A score gap against a target is not an admission probability.
- LS LAB 논술 evaluation results are never summed onto the same score scale as
  모의고사/내신; each domain stays independent and is combined only as context in
  the Academic Profile.

## 2026-09-19 — Achievements record behaviour and confirmed growth, never prediction

The badge idea returns as an Achievement Engine driven by real learning
behaviour and confirmed growth, not by logins, ads or arbitrary activity.
Behaviour-based and growth-based achievements are modelled separately, and study
volume alone never earns a growth-based achievement.

**Prediction-style badges are forbidden** — nothing of the shape "서울대 합격
가능", "합격 유력" or "상향지원 성공". The Achievement Engine and the Admissions
Engine stay separate systems: an achievement is never an input to an admission
estimate, and an admission estimate is never surfaced as a badge.

Both this and the entry above are roadmap decisions. They do **not** promote the
advanced achievement system or the early-admission prediction service into v1.0;
`product-scope.md` still excludes both. See
[roadmap-academic-analytics.md](roadmap-academic-analytics.md).

## 2026-09-19 — Web and App are different products

The App is not a second skin over the same content. Web keeps search
acquisition, the public archive and AdSense; the App carries the learning
workflow — FIND → VIEW → SOLVE → SCORE → RECORD → ANALYZE → IMPROVE. Every new
feature is designed with its role on four axes stated: user value, app
advantage, retention and monetization.

## 2026-09-19 — Premium sells intelligence, not basic access

Public educational material and the basic in-app viewer are not the centre of
the paywall; free users must be able to search and read well enough to see the
app's value. Paid value is analysis, AI evaluation and longitudinal data
continuity. The basic experience is never degraded to force conversion.

Candidate tiers FREE / BASIC / ADVANCED / MAX supersede the earlier
Free/Basic/Pro sketch as working vocabulary; the Entitlement-layer rule in
`architecture.md` still applies. The ₩4,900 one-time ad-removal purchase and a
premium subscription remain separate product roles.

## 2026-09-19 — Metadata coverage and viewer coverage are separate

Historical metadata may expand far beyond what the in-app viewer serves.
Resources outside viewer coverage fall back to the original LegendStudy source
page, and a primary viewer path never removes that fallback. Storage cost is
therefore not a reason to slow metadata expansion. Any mirrored copy still
depends on the deferred rights decision recorded in `day-9-ingestion.md`, and
the no-bulk-mirroring rule of 2026-09-12 stands until that decision is made.

## 2026-09-19 — AI-heavy features may combine subscription and credits

Features with a real marginal inference cost (LS LAB essay evaluation,
handwritten math Vision, multimodal evaluation) are entitled by a subscription
plus usage credits. MAX is not defined as unlimited AI. Quotas and prices are
set after cost measurement.

## 2026-09-19 — Community is a free retention feature, not a launch blocker

Community stays on the long-term product map as PLANNED, with the role FREE /
RETENTION, and is not the centre of the early paywall. Initial candidates are
학교 급식 자랑 (linked to the Meal feature) and 잡담; 공부 인증, 모의고사 후기 and
학습 팁 are later candidates. Single-user learning value — viewer, Mock Exam,
Academic Record — ships first. Because the users are students, reporting,
blocking, moderation, spam and banned-word handling, prevention of
personal-information exposure, image safety and an operator workflow are
designed together with the posting feature, never afterwards. This does not
promote Community into v1.0; `product-scope.md` still excludes it. See
[roadmap-monetization-and-in-app-learning.md](roadmap-monetization-and-in-app-learning.md).

## 2026-09-20 — In-App Exam learning loop and authority boundaries

Refinement below supersedes only mandatory Viewer ordering and the combined
implementation hold; the following original safety decision is retained.

In-App Exam V1 is FIND → VIEW → START ATTEMPT → SOLVE → AUTOSAVE → SUBMIT →
SERVER SCORE → RESULT → ACADEMIC RECORD. Basic history/Record are required;
deep Analytics and AI subjective scoring remain later/separate. Whole-PDF eager
rendering and client-only authoritative scoring are unacceptable architecture.
Use bounded lazy rendering, atomic answer preservation, continuous elapsed timing
with server reconciliation, one active device/session owner, immutable submitted
answers and pinned scoring provenance. Retakes create new attempts; corrections
must be auditable revisions, never silent current-key reinterpretation.

Design entitlement compatibility now (CHECK → RESERVE → EXECUTE/SCORE → SETTLE;
definitive failure releases/refunds); payment/tier quotas remain separate and
undecided. Rights gate media storage/access; metadata coverage is independent of
Viewer coverage. Existing Study pause and Guest preview remain unchanged.
Detailed requirements and open prerequisites have one owner:
[architecture-in-app-exam.md](architecture-in-app-exam.md). No implementation approval.

## 2026-09-20 — Paper-first / answer-first Exam Engine refinement

Primary mobile value is SOLVE → ANSWER → SUBMIT → SCORE → GRADE → RECORD →
ANALYZE → IMPROVE. Users can select an exam and create an Attempt after solving
on paper without ever opening a Viewer. Viewer is an independent resource-access
convenience layer; its failure cannot block answers/scoring/records. Optional
Tablet Viewer flow remains supported in direction. This supersedes mandatory
FIND → VIEW ordering above, not atomic persistence, revision/recovery, single
execution ownership, idempotency, immutable submissions or pinned server scoring.

Separate rights-gated resource delivery/mirroring from exam identities, validated
answer/scoring/grade data and Academic Record. PDF Storage/mirrors remain HOLD;
engine contracts may advance independently. No new data-use approval is implied.
User Academic History, not PDF collection, is the retention asset: Exam → Score
→ Grade → Subject Performance → Historical Trend → Weakness → Study Strategy.
V1 provides records/basic comparison; advanced/AI strategy remains later.
Monetization centres on repeat scoring, longitudinal records/comparisons and
personalized analysis, not file ownership. Free/basic access remains meaningful;
prices, FREE/BASIC/ADVANCED/MAX entitlements and quotas remain undecided.
[Canonical architecture](architecture-in-app-exam.md) owns separate track gates.

## 2026-09-23 — Owner device corrections and MY Achievement surface

Logout confirmation success returns HOME; failure stays Settings. Save success
returns to the previous edit caller. Photo success requires completed Storage
write and verified refreshed bytes/UI, including first upload, replace and remove.
All five main screen families share the section heading/divider primitive; avoid
heavy nested cards. Settings has one destructive deletion action, no duplicate
heading.

Owner now requests MY access to earned achievements and a compact profile badge.
This promotes the **surface direction**, not the Advanced Achievement Engine or
its catalogue into v1. Existing [Achievement philosophy](#2026-09-19--achievements-record-behaviour-and-confirmed-growth-never-prediction)
and [roadmap §9](roadmap-academic-analytics.md#9-achievement--badge-engine) remain
canonical. No catalogue/model/persistence exists in the current App migrations;
this task records FOUNDATION and exposes no fake awards/collection. Study Level
has no approved taxonomy and remains FUTURE.

## 2026-09-24 — Design System v2 approved scope

Owner selects Claude Palette A (orange/navy/cool neutral); white grouped surfaces
on cool page, no peach title strips, shared typography/components. MY Study CTAs
become navigation rows, preserving Trend→Timer order. Guest MY clearly offers
Login and hides private modules. Settings logout moves below policy/info, directly
above destructive deletion. Materials initial/load-more pages are10; existing
explicit load-more and query semantics stay unchanged. This supersedes the prior
2026-09-23 strip/outlined-MY-CTA/logout-order styling only. Feature/data contracts
remain; no Badge/backend/auth redesign. [Approved mapping](design-system-v2-proposed.md).

## 2026-09-24 — Device follow-up and analytics layer allocation

Owner refines v2: personalized own-nickname Home greeting (safe guest/fallback copy),
no Home wordmark/duplicate brand text; neutral cards with small D-Day orange,
Study blue/navy, Meal green semantic icons. Meal type and school share header,
existing selection unchanged. Notification trailing slot only, no fake bell/count.
Materials initial/load-more5 supersedes10, same query/pagination. Timer seven-day
chart reuses canonical included-time totals/Trend chart: oldest→newest, weekdays,
actualmax and zero bars. Mock subject label is optional-only; validation retained.
MY score is a snapshot with LAB detail CTA; push preserves MY/LAB caller context.

[Three-layer allocation](product-architecture.md#academic-analytics-three-layer-allocation--2026-09-24)
is canonical Owner direction. [Research](research-registry.md) is evidence, not
Owner approval: retain future admission bands behind explicit research gate, not
permanent deletion or implementation approval. Existing Achievement philosophy stays.

## 2026-09-24 — Owner device follow-up 2

Keep existing v2/analytics allocation. Compact own/Guest greeting + planned neutral
notification slot; D-Day name/date metadata and primary D-n; study label/value row;
Meal actual trailing school and chronological expanded date chips, no policy change.
Daily seven-slot chart adds actual durations and mean reference; shared included-time
aggregation stays canonical. Canonical scoring setup selects actual exam then its
subject/variant; independent timer practice is explicitly separate. Successful-state
repository-refresh control removed, entry loading/error retry retained. MY comments
only confirmed structured result facts. Materials5/load-more and MY→LAB→Back are
Owner PASS; preserve. New changes require device acceptance, no new admission claim.

## 2026-09-24 — Owner device follow-up 3

Owner confirms icon-derived **#FFA300** as Brand Primary. Earlier #FB8C00 and
peach selected surfaces are superseded; **PEACH UI PROHIBITED BY OWNER**. Keep
white/cool-gray/navy surfaces, small D-Day brand/Study blue/Meal green icons.
Meal expansion has an explicit trailing control; chips represent actual provided
meal dates only, at most three, date+weekday. Existing14/19KST and next7day preview
contracts remain. Expanded-only bounded context is detailed in Home policy.
Daily study mean is annotated beside its neutral dashed line, outside the bars;
“이번 주” is presentation copy for the existing recent7day window, not a new
Monday-based aggregation. Dynamic scale/zero/time inclusion/comments stay.

Mock has two purposes: **Official Past Exam Practice** uses canonical exam,
subject/variant and published verified key; **Free Practice** uses user title,
time and optional manual score. Manual scores are personal practice only, never
verified results or MY/LAB/admissions inputs. No new taxonomy, fake key or invented
official duration. Full key catalogue and analytics stay gaps. Implementation
scope and storage boundary: [Mock contract](day-8-d2-answer-scoring.md#owner-follow-up-3--dual-practice-modes).
Daily Sync Phase1 is explicitly outside this task.

## 2026-09-24 — Final Home and Study visual polish

Owner narrows this pass to Home daily white border/shadow, check-free Meal date
selection, and displayed7day Study total/max plus line-bound mean annotation.
Existing brand/Meal/Study contracts remain; [design](design-system.md#owner-final-ui-polish--2026-09-24)
and [Study](study-v1.md#owner-final-ui-polish--2026-09-24) own details. Future
study/score relationship analysis is descriptive PLANNED work, never automatic
causation; no Mock/LAB/Daily Sync/backend expansion is authorized by this pass.

## 2026-09-24 — Longitudinal learning and admissions data strategy

Owner adopts [Longitudinal Learning and Admissions Data Strategy](longitudinal-learning-admissions-data-strategy.md)
as HIGH / CANONICAL PRODUCT STRATEGY for Product/Data/Marketing/Business design.
Learning→performance→planning→application→outcome→analytics→guidance is the long-term
loop; preserve event time, academic context and provenance within purpose/retention/
rights boundaries. Existing three-layer UX, Achievement and Official/Free separation
remain. Cohort requires sufficient samples plus Privacy/Statistical review; predictions
remain MODEL/EVIDENCE GATED. Raw individual-data sale is not the default business.
This refines the 2026-09-19 analysis/retention decisions and final Study comparison
direction; it does not implement engines, fix catalogue/thresholds or authorize
new collection, use, sharing, payment, schemas or deployment.
