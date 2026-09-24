# Research A–D Product and Operations Consolidation

**Status:** Research-to-Wiki handoff, prepared 2026-09-24. This is **not an Owner decision record** and does not implement code, database schema, scheduled jobs, source crawling, publication, or a production change.

## Purpose

This document makes the completed Manus Research A–D findings discoverable through the repository Wiki. It distils the operational and product boundaries that a future implementer needs before starting daily synchronization, academic analytics, admissions data work, AI essay release work, community work, or monetization.

The original research reports remain evidence artifacts outside this repository. This page is the canonical **router and handoff**, not a duplicate of those reports. `current-status.md` remains authoritative for actual implementation state, and `decisions.md` remains authoritative only for durable Owner decisions.

## Classification vocabulary

| Classification | Meaning in this document |
| --- | --- |
| `ADOPTED_EXISTING` | The finding matches an existing Owner decision, code contract, or canonical Wiki rule. |
| `RECOMMENDED` | Research supports the direction, but Owner approval is still required before implementation or policy change. |
| `CONFLICT` | A source of truth, historical record, task premise, or implementation claim disagrees and needs explicit resolution. |
| `GAP` | An important capability or contract is missing from the current implementation. |
| `FUTURE` | Outside the current delivery scope. |
| `BLOCKER` | Evidence or an Owner decision is required before the related implementation or release can proceed. |

## Research inputs and current interpretation

| Research | Consolidated finding | Classification | Canonical route |
| --- | --- | --- | --- |
| **A. Daily Content Sync** | Existing ingestion identity, source-time ordering, quarantine, verified-mapping protection, and safe external opening are reusable. A durable daily control plane, general staged updater, scheduler, review queue, and operational alerting do not exist. | `ADOPTED_EXISTING` + `GAP` | [Ingestion Strategy](ingestion.md) and [Daily Sync section](#daily-sync-and-pilot-c-baseline) |
| **B. Admissions Data Sources** | Official documents and public APIs support source-aware discovery, rule checks, and dated historical comparison. They do not justify a personal admission-probability claim or automatic special-admissions eligibility decision. | `RECOMMENDED` + `BLOCKER` | [Academic Analytics Roadmap](roadmap-academic-analytics.md) |
| **C. Competitive Intelligence** | Do not pursue feature parity with lecture, community, question-bank, or prediction incumbents by default. A differentiated hypothesis connects materials, learning records, official rules, explainable analysis, and LAB. | `RECOMMENDED` | [Product Architecture](product-architecture.md) and [Monetization Roadmap](roadmap-monetization-and-in-app-learning.md) |
| **D. Launch Compliance Audit** | Data mapping, deletion, accurate disclosures, minor/student safeguards, review access, and claim accuracy are release evidence, not documentation-only work. Community, AI, notifications, ads, and payments each need conditional gates. | `BLOCKER` | [Privacy and Account Deletion](account-deletion-privacy.md) |

## Research-to-Wiki traceability matrix

| Research | Finding | Current Wiki / code evidence | Classification | Owner decision required | Target Wiki | Next implementer |
| --- | --- | --- | --- | --- | --- | --- |
| A | Source identity is `(source, external_post_id)` and source time controls Home ordering. | `ingestion.md`, `database.md`, `SupabaseContentRepository`. | `ADOPTED_EXISTING` | No. | `ingestion.md` | Codex only when daily work is approved. |
| A | Failure, source absence, or partial parse must not delete/unpublish existing content. | `ingestion.md` soft-state contract and local pipeline behavior. | `ADOPTED_EXISTING` | No. | `ingestion.md` | Codex. |
| A | Pilot writer is intentionally bounded/insert-only; it is not an unattended general updater. | `tool/ingestion/apply.py`, Day 9 records. | `GAP` | Yes, before a general writer. | This page and `ingestion.md`. | Codex after Phase 0. |
| A | Run ledger, lease/fencing, staged revision, review request, alerting, and reconciliation cursor are absent. | No operational schema or scheduled workflow found in the inspected repository. | `GAP` | Yes for runtime and migration. | `ingestion.md`. | Codex. |
| A | Supabase Cron → private Edge coordinator → durable Supabase control plane best co-locates state and promotion. GitHub Actions is a fallback/reconciliation candidate; Cloudflare is an alternative. | Research comparison; current Python pipeline requires parity or an approved runner. | `RECOMMENDED` | **Yes.** | `ingestion.md`. | Owner + Codex. |
| A | `unknown` Kakao resources must open the original post, while landing pages and verified files use their distinct targets. | Resource resolver and external launcher are implemented. | `ADOPTED_EXISTING` | No. | `ingestion.md`, Day 9-C documents. | Codex regression owner. |
| B | Final university guidelines/corrections and public primary sources are the rule authority. | No admissions engine exists; source registry research supplies the proposed hierarchy. | `RECOMMENDED` | Yes for initial university scope. | `roadmap-academic-analytics.md`. | Planner/Codex later. |
| B | Special-admissions discovery may show conditions and documents, not automatic eligibility. | No feature is implemented. | `BLOCKER` | Yes for future workflow. | `roadmap-academic-analytics.md`. | Product/Legal/Codex later. |
| B | Admission probability or five-stage likelihood is not currently evidence-validated. | Existing long-term product idea is retained; no model exists. | `FUTURE` + `BLOCKER` | Yes. | `roadmap-academic-analytics.md`. | Research/Product later. |
| C | A connected materials → learning → evidence-based analysis → LAB flow is a defensible strategic hypothesis. | Public-content, Study, Mock Exam, and Essay plans exist; broad parity services do not. | `RECOMMENDED` | Yes before product commitment. | `product-architecture.md`. | Product owner/Planner. |
| C | Free access should cover basic information and evidence; paid value must be cumulative and real. | Existing ₩4,900 supporter direction and planned Essay credit direction are separate. | `ADOPTED_EXISTING` + `RECOMMENDED` | Yes for future pricing. | `roadmap-monetization-and-in-app-learning.md`. | Product/Legal/Codex later. |
| D | Account deletion, data map, accurate store declarations, and review access are release blockers. | Current Wiki has no complete implementation evidence. | `BLOCKER` | Yes for launch plan. | `account-deletion-privacy.md`. | Owner/Legal/Codex. |
| D | Community requires in-app report, block, moderation, support/contact, and policy before release. | Community is outside current v1 scope and unimplemented. | `BLOCKER` | Yes before community work. | `account-deletion-privacy.md`. | Product/Legal/Codex later. |
| D | AI essay needs disclosure, data lifecycle, safety/reporting, limitation language, and evaluation-quality gates. | Essay Lab is planned and text-first; no AI production service is claimed. | `BLOCKER` | Yes before launch. | `account-deletion-privacy.md`, `roadmap-essay-lab.md`. | Owner/Legal/Codex later. |
| D | Notification Center and achievement alerts need separate foundations. | No notification backend or achievement catalogue/persistence is recorded. | `GAP` + `FUTURE` | Yes for initial scope. | `product-architecture.md`. | Product/Codex later. |

## Daily Sync and Pilot C baseline

### Phase 0 Owner validation — `PUBLISHED_COMPLETE`

The Product Owner directly ran the Phase 0 aggregate-only validation on 2026-09-24.
The factual result is `PUBLISHED_COMPLETE`: Pilot C has 23 source posts, 23 content
items with 23 active, 23 exams, 363 exam subjects with 363 active, 739 resources with
739 active, and 23 quarantine rows. All reported orphan, scope, and provenance checks
returned zero. This is the current Daily Sync baseline.

Earlier Pilot C preparation/apply records retain inactive or pre-publication wording
because they document their historical gate and transaction design. The original Daily
Sync research likewise began before this direct validation. These records are not
deleted or rewritten; the Owner-validated Phase 0 result resolves their current-state
interpretation.

### Phase 0 Owner read-only validation SQL

This is the historical package retained for repeat validation.

> **Safety:** This package is `SELECT`-only. It does not set a role, issue DDL/DML, reveal user data, URLs, tokens, raw metadata, or source body content. Run it in the intended LegendStudy production SQL editor and share only the aggregate result rows.

```sql
-- LegendStudy Daily Sync Phase 0 — Pilot C factual baseline
-- Read-only. No DDL, DML, role change, or user/personal-data output.

with pilot_ids(external_post_id) as (
  values
    ('1709'), ('1708'), ('1707'), ('1706'), ('1705'), ('1704'),
    ('1703'), ('1702'), ('1700'), ('1695'), ('1694'), ('1693'),
    ('1686'), ('1685'), ('1684'), ('1668'), ('1667'), ('1666'),
    ('1665'), ('1664'), ('1663'), ('1662'), ('1661')
),
pilot_posts as (
  select sp.id
  from public.source_posts sp
  join pilot_ids p using (external_post_id)
  where sp.source = 'legendstudy'
),
pilot_content as (
  select ci.id, ci.is_active
  from public.content_items ci
  where ci.source_post_id in (select id from pilot_posts)
),
pilot_occurrences as (
  select es.id, es.is_active
  from public.exam_subjects es
  where es.content_item_id in (select id from pilot_content)
),
pilot_resources as (
  select r.id, r.is_active
  from public.resources r
  where r.content_item_id in (select id from pilot_content)
),
summary as (
  select
    (select count(*) from pilot_posts) as pilot_source_posts,
    (select count(*) from pilot_content) as pilot_content_items,
    (select count(*) from pilot_occurrences) as pilot_exam_subjects,
    (select count(*) from pilot_resources) as pilot_resources,
    (select count(*) from pilot_content where is_active) as pilot_active_content_items,
    (select count(*) from pilot_occurrences where is_active) as pilot_active_exam_subjects,
    (select count(*) from pilot_resources where is_active) as pilot_active_resources
)
select
  case
    when pilot_source_posts = 0 and pilot_content_items = 0
         and pilot_exam_subjects = 0 and pilot_resources = 0
      then 'MISSING_OR_DIFFERENT_SCOPE'
    when pilot_source_posts = 23 and pilot_content_items = 23
         and pilot_exam_subjects = 363 and pilot_resources = 739
         and pilot_active_content_items = 0
         and pilot_active_exam_subjects = 0
         and pilot_active_resources = 0
      then 'INACTIVE_COMPLETE'
    when pilot_source_posts = 23 and pilot_content_items = 23
         and pilot_exam_subjects = 363 and pilot_resources = 739
         and pilot_active_content_items = 23
         and pilot_active_exam_subjects = 363
         and pilot_active_resources = 739
      then 'PUBLISHED_COMPLETE'
    else 'MIXED_OR_CONFLICT'
  end as pilot_c_baseline_status,
  *
from summary;

-- Aggregate inventory only. It separates all source rows from the fixed Pilot C scope.
with pilot_ids(external_post_id) as (
  values
    ('1709'), ('1708'), ('1707'), ('1706'), ('1705'), ('1704'),
    ('1703'), ('1702'), ('1700'), ('1695'), ('1694'), ('1693'),
    ('1686'), ('1685'), ('1684'), ('1668'), ('1667'), ('1666'),
    ('1665'), ('1664'), ('1663'), ('1662'), ('1661')
),
pilot_posts as (
  select sp.id from public.source_posts sp
  join pilot_ids p using (external_post_id)
  where sp.source = 'legendstudy'
),
pilot_content as (
  select id, is_active from public.content_items
  where source_post_id in (select id from pilot_posts)
),
pilot_occurrences as (
  select id, is_active from public.exam_subjects
  where content_item_id in (select id from pilot_content)
),
pilot_resources as (
  select id, is_active from public.resources
  where content_item_id in (select id from pilot_content)
)
select 'source_posts_all' as metric, count(*)::bigint as value
from public.source_posts
union all select 'source_posts_legendstudy', count(*) from public.source_posts where source = 'legendstudy'
union all select 'pilot_source_posts', count(*) from pilot_posts
union all select 'content_items_all', count(*) from public.content_items
union all select 'pilot_content_items', count(*) from pilot_content
union all select 'pilot_content_items_active', count(*) from pilot_content where is_active
union all select 'pilot_content_items_inactive', count(*) from pilot_content where not is_active
union all select 'exams_all', count(*) from public.exams
union all select 'pilot_exams', count(*) from public.exams where content_item_id in (select id from pilot_content)
union all select 'exam_subjects_all', count(*) from public.exam_subjects
union all select 'pilot_exam_subjects', count(*) from pilot_occurrences
union all select 'pilot_exam_subjects_active', count(*) from pilot_occurrences where is_active
union all select 'resources_all', count(*) from public.resources
union all select 'pilot_resources', count(*) from pilot_resources
union all select 'pilot_resources_active', count(*) from pilot_resources where is_active
union all select 'ingestion_quarantine_all', count(*) from public.ingestion_quarantine
union all select 'pilot_quarantine', count(*) from public.ingestion_quarantine
  where source_post_id in (select id from pilot_posts)
order by metric;

-- Integrity and public-projection aggregates. A nonzero value requires investigation,
-- not automatic repair or publication.
with pilot_ids(external_post_id) as (
  values
    ('1709'), ('1708'), ('1707'), ('1706'), ('1705'), ('1704'),
    ('1703'), ('1702'), ('1700'), ('1695'), ('1694'), ('1693'),
    ('1686'), ('1685'), ('1684'), ('1668'), ('1667'), ('1666'),
    ('1665'), ('1664'), ('1663'), ('1662'), ('1661')
),
pilot_posts as (
  select sp.id from public.source_posts sp
  join pilot_ids p using (external_post_id)
  where sp.source = 'legendstudy'
),
pilot_content as (
  select ci.id, ci.is_active from public.content_items ci
  where ci.source_post_id in (select id from pilot_posts)
)
select 'pilot_content_without_exam' as metric, count(*)::bigint as value
from pilot_content pc
left join public.exams e on e.content_item_id = pc.id
where e.content_item_id is null
union all select 'pilot_resource_provenance_outside_scope', count(*)
from public.resources r
where r.content_item_id in (select id from pilot_content)
  and r.source_post_id not in (select id from pilot_posts)
union all select 'all_exam_subject_parent_orphans', count(*)
from public.exam_subjects es
left join public.content_items ci on ci.id = es.content_item_id
where ci.id is null
union all select 'all_resource_parent_orphans', count(*)
from public.resources r
left join public.content_items ci on ci.id = r.content_item_id
where ci.id is null
union all select 'all_resource_scope_orphans', count(*)
from public.resources r
left join public.exam_subjects es
  on es.id = r.exam_subject_id and es.content_item_id = r.content_item_id
where r.exam_subject_id is not null and es.id is null
union all select 'public_content_items_active', count(*) from public.content_items where is_active
union all select 'public_exams_with_active_parent', count(*)
from public.exams e join public.content_items ci on ci.id = e.content_item_id
where ci.is_active
union all select 'public_exam_subjects_active_chain', count(*)
from public.exam_subjects es join public.content_items ci on ci.id = es.content_item_id
where es.is_active and ci.is_active
union all select 'public_resources_active_chain', count(*)
from public.resources r join public.content_items ci on ci.id = r.content_item_id
where r.is_active and ci.is_active
order by metric;
```

The Owner’s returned aggregate result is `PUBLISHED_COMPLETE`; the integrity aggregate
checks are all zero. The SQL remains a `SELECT`-only historical and repeat-validation
package. If it is run again later, any nonzero integrity aggregate remains an
investigation item, not permission for an automated repair.

### Historical or stale-language handling

The following language remains useful as historical evidence but must not be used as
a current production fact without a later verification. `day-9-ingestion.md` and
`day-9-pilot-c-package.md` retain inactive/no-publication wording from earlier Pilot
stages. `database.md` and the opening section of `ingestion.md` retain an earlier
empty-table fixture-cleanup baseline. The Owner-validated Phase 0 result above and
`current-status.md` now establish the current Pilot C publication state. This
consolidation does **not** rewrite historical package text.

The practical rule is: use historical package documents to understand their exact
guardrail and transaction design; use `current-status.md` plus an authorized fresh
read-only check when current state needs revalidation; and never treat a migration file
or a research recommendation as deployment evidence.

### Daily Sync recommendation and non-negotiable contract

The research recommendation is **Supabase Cron → private authenticated Edge Function coordinator → Supabase run/stage/review control plane**. This is `RECOMMENDED`, not approved or implemented. It is preferred because the same control plane can own the run claim, lease, checkpoints, staged changes, review decision, and promotion audit.

GitHub Actions remains a candidate for controlled dry run or reconciliation because it can execute the existing Python code, but scheduled delivery may be delayed or dropped. Cloudflare Workers remains an alternative only if a deliberate TypeScript port and separate operational ownership are chosen. Neither alternative is a reason to create a second independent production writer.

The canonical daily-sync contract is: at-least-once observation; effectively-once promotion; evidence preservation; no destructive inference; source time as Home ordering truth; ordinary attachment-download prohibition; observe first and publish later; durable quarantine; verified-mapping protection; and idempotent promotion. The source worker may not make a public visibility change merely because a hash changed.

### Phase plan

| Phase | Status | Dependency / Owner gate | Code area | Test gate | Production mutation |
| --- | --- | --- | --- | --- | --- |
| **0. Baseline and policy** | `PASS` | Owner completed the aggregate-only baseline validation as `PUBLISHED_COMPLETE`. Runtime, daily window, publication boundary, and absence semantics remain later decisions. | No code. | Reported aggregate/integrity result. | None. |
| **1. Deterministic source/delta core** | `READY` | Preserve existing parser contracts and implement the [offline Phase 1 package](daily-sync-phase-1-deterministic-delta-package.md). Python is the recommended Phase 1 core; no Deno port is required. | Source adapter, crawler/parser/normalizer/pipeline, offline fixtures. | Old-post edit, signature rotation, malformed source, deterministic output, and no-download tests. | Dry run only. |
| **2. Private operations state** | `BLOCKED BY OWNER/MIGRATION` | Owner reviews an additive migration and service boundary. | Run ledger, lease/fencing, endpoint state, observations, stages, review requests. | RLS/grant, claim, stale-lease, redaction, and transaction tests. | Schema only after explicit approval; no scheduler. |
| **3. General staged writer** | `BLOCKED BY PHASE 2` | Owner confirms permitted private promotion scope. | New staged writer/diff layer, not a mutation of historical Pilot writer. | Idempotency, updated title, added answer/audio, partial fetch, verified mapping, race tests. | Private staging only initially. |
| **4. Review/publication gate** | `BLOCKED BY OWNER` | Owner defines approval and soft-deactivation policy. | Review report/query, preflight, scoped promotion/rollback. | New, already-published, mixed-state, and rollback tests. | Owner-approved action only. |
| **5. Scheduler rollout** | `BLOCKED BY PHASE 2–4` | Owner approves runtime, secret ownership, operational window, alerts. | Private coordinator, runbook, alert path. | Duplicate, missed run, outage, source-policy and log-redaction drills. | Daily observe/stage; no automatic publication. |
| **6. Bounded reconciliation** | `FUTURE AFTER ROLLOUT` | Owner accepts source budget and coverage objective. | Cursor/shards, cooldown, anomaly rule, recovery runbook. | Full-cycle/recovery/source-load evidence. | Review-only for absence/removal. |

## Release, Community, AI, Notifications, and Monetization

### Release gate summary

`P0` is required evidence before a general store release: data map and truthful store declarations, account deletion, review access/support, minor/student protection, and claim accuracy. `P1` applies before enabling social login, community, AI, admissions personal data, ads/payment, or notifications. `P2` covers longer-term operational maturity such as deletion propagation, administrator audit, incident response, vendor/subprocessor review, and feature drills.

### Community and AI essay gates

Community is **not implemented**. Before any public board, meal community, profile-sharing, comment, or direct-message feature, report, block, moderation, support/contact, terms/policy, and deletion/access-exclusion operations must exist and be tested. A public community shell without those controls is not an acceptable incremental release.

AI Essay feedback remains a planned direction. It is not deleted by this research. Before launch it needs disclosure that feedback is AI-assisted, a privacy/retention and AI-vendor boundary, a source/evaluation-package boundary, output limitation language, safety/reporting/appeal controls, and quality evidence. No result may be presented as a university decision or admission guarantee.

### Notification and achievement dependency

`NOTIFICATION_CENTER` is **PLANNED** and has no implementation claim. New-material notices occur only after a validated/reviewed/published content event. An achievement notice such as “10 hours badge까지 8시간” is **blocked** until an Achievement Engine defines catalogue, threshold, verified event source, persistence, account isolation, and notification permission semantics.

### Monetization

Existing free-with-ads and one-time supporter/ad-removal direction remains distinct from future Essay Lab credit/package planning. Payment and ads are feature-specific release gates; research does not authorize a pricing, subscription, entitlement, or ad-SDK implementation.

## Codex next implementation package

### Ready now — no production mutation

| Priority | Title | Why | Files/domain | DB change | Owner action | Acceptance / test |
| --- | --- | --- | --- | --- | --- | --- |
| **P0** | Daily Sync Phase 0 read-only baseline runner documentation | Historical validation package. The Owner has completed it as `PUBLISHED_COMPLETE`. | Wiki/runbook only. | No. | None. | SQL remains SELECT-only and may be reused for a later factual recheck. |
| **P1** | [Daily Sync deterministic source/delta core](daily-sync-phase-1-deterministic-delta-package.md) | Adds deterministic source classification and safe evidence without a writer. | Existing Python `tool/ingestion` core plus metadata-only fixtures. | No. | None. | New/unchanged/modified/malformed/ambiguous fixtures, no-download, no destructive inference, and redaction pass. |
| **P0** | Daily Sync contract regression inventory | Locks the existing source identity, source-time feed, safe opening, no-delete, and verified-map rules before future work. | Offline tests around `tool/ingestion` and existing Flutter resource/feed contracts. | No. | None. | Tests cover unknown/landing/file target and no timestamp bump on no-op. |
| **P0** | Release evidence inventory | Converts P0 release blockers into a verifiable checklist without pretending features exist. | Wiki/testing plan only. | No. | Select release scope/target age later. | Data-map and deletion evidence are marked missing, not passed. |
| **P1** | Analytics surface contract | Translate MY/Mobile LAB/Web LAB boundary into UI/data design with deterministic missing-data states. | Product/UI specification and synthetic fixtures. | No. | Approve initial analytics scope. | No fabricated score comment or probability label. |
| **P1** | Admissions source-registry prototype | Build an offline, provenance-first source/document model and review fixture set for a narrow approved university set. | New isolated design/test package. | Not until migration review. | Choose initial universities/track types. | Every proposed fact has source/version/locator and verification state. |

### Blocked by Owner or baseline

| Priority | Title | Blocking dependency | Future acceptance |
| --- | --- | --- | --- |
| **P1** | Daily Sync operational schema and staged writer | Owner-approved additive migration, private service boundary, and automation scope. | Run/lease/stage/review controls prevent duplicate or stale promotion. |
| **P1** | Daily Sync scheduler | Runtime/secret ownership, source budget, alert recipient, and Phases 1–4. | Daily observation/stage succeeds safely; no auto publication. |
| **P2** | Admissions deterministic rule checker | Human-verified source model, privacy/deletion decision, and approved target scope. | Reproducible result with source version and no probability claim. |
| **P2** | Notification foundation | Event taxonomy, consent/opt-out, delivery backend, and achievement/data-source contracts. | No fake data; only approved published events notify. |
| **FUTURE** | Probability model, full community, full achievement engine, B2B school features | Separate evidence, legal, moderation, calibration, and Owner approvals. | Individual programme-specific criteria. |

## Owner decisions required

The following are the only material decisions currently requested. Existing decisions are not re-opened.

1. **Daily Sync runtime:** whether to approve the recommended Supabase Cron/private Edge control-plane target after Phase 0, or choose an explicitly owned alternative.
2. **Daily Sync publication boundary:** whether automation may only observe/stage/quarantine, or may also create/update inactive canonical rows; activation, deactivation, and verified-mapping changes remain separate human decisions by default.
3. **Academic Analytics surface boundary:** approve the MY Snapshot → Mobile LAB → Web LAB three-layer direction as a product architecture decision.
4. **Admissions claim boundary:** approve an initial experience centered on rule states and historical reference rather than probability or automatic special-admissions eligibility.
5. **Notification Center initial scope:** decide whether it is a post-core planned foundation or an earlier product priority; no backend starts from this document.
6. **Community phase:** keep community after core release gates until the full report/block/moderation/support operation is approved.

## Handoff self-test

| Request received by a future agent | Required route | Result |
| --- | --- | --- |
| “사이트에 새 글 올렸는데 앱에 안 보여.” | [Ingestion Strategy](ingestion.md) → this page → Phase 0/implementation gates → `current-status.md`. | **PASS.** It identifies daily sync as not implemented and prevents unsafe publication. |
| “내 성적으로 농어촌 OO대 가능?” | [Academic Analytics Roadmap](roadmap-academic-analytics.md) → special-admissions boundary → source/version check. | **PASS.** It prevents automatic eligibility confirmation. |
| “합격 가능성을 5단계로 보여줘.” | [Academic Analytics Roadmap](roadmap-academic-analytics.md) → admission-probability gate. | **PASS.** It preserves the idea as future while requiring evidence/model validation. |
| “급식 게시판 Community 만들자.” | [Privacy and Account Deletion](account-deletion-privacy.md) → community gate. | **PASS.** It requires report/block/moderation/support before release. |
| “10시간 배지까지 남은 시간 알림.” | [Product Architecture](product-architecture.md) → notification/achievement boundary. | **PASS.** It requires catalogue/persistence/verified-event foundations. |
| “논술 AI 첨삭 출시.” | [Essay Lab Roadmap](roadmap-essay-lab.md) → [Privacy and Account Deletion](account-deletion-privacy.md). | **PASS.** It routes to AI privacy, disclosure, quality, and release gates. |

## References

[1]: current-status.md "LegendStudy current implementation status"
[2]: decisions.md "LegendStudy durable decisions"
[3]: ingestion.md "LegendStudy ingestion identity, source-time, quarantine, and publication contracts"
[4]: product-architecture.md "LegendStudy product surfaces and evidence boundaries"
[5]: roadmap-academic-analytics.md "Academic analytics and admissions roadmap"
[6]: account-deletion-privacy.md "Privacy, deletion, and conditional release gates"
[7]: roadmap-essay-lab.md "Essay Lab roadmap and priority"
[8]: roadmap-monetization-and-in-app-learning.md "Monetization and in-app learning boundary"
