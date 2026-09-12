# Durable Decisions

This file records long-lived product and architecture decisions. Routine progress belongs in `log.md` and `current-status.md`.

## 2026-09-12 — Project independence

LegendStudy is fully separate from Muselry, including repository, codebase, Supabase, secrets, OAuth setup, identifiers, wiki, and deployment.

## 2026-09-12 — Native app, not WebView

LegendStudy will not be implemented as a simple WebView wrapper around `legendstudy.com`.

## 2026-09-12 — Canonical knowledge location

The repository-local `wiki/` directory is the official long-term development knowledge base. There must be only one canonical `wiki/current-status.md`.

## 2026-09-12 — Agent role split

- Codex: main coder
- Claude: support coder / code reviewer
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

Separate source_posts, exams, exam_subjects and resources. One source post may
contain multiple exams; each exam may contain multiple raw subject occurrences
and resource links. Preserve raw labels and source provenance after normalization;
unknown values remain NULL rather than forced into modern taxonomy. Curated
subjects are versioned; historical variants require their own reviewed mappings.
Calendar year and academic/CSAT year are distinct fields.

## 2026-09-12 — Content access and personal data

Public active content is readable without login; published descendants must also
have a visible parent exam/subject occurrence. Mobile clients cannot write content
or source metadata. Personal profiles/bookmarks/recent views are auth-user-owned
under RLS. Auth-user removal cascades only personal data; content deletion is
restricted and normal unpublishing is an explicit inactive state.

## 2026-09-12 — Resource locations and ingestion identity

Preserve source URLs first; landing pages are not assumed to be direct file URLs.
No bulk mirroring or Supabase Storage setup in v0.1. Future mirrors must preserve
original provenance. Persist stable ingestion keys independent of display order,
normalized labels and mutable link queries. Ambiguous reconciliation requires
review; unique constraints alone do not make parsing idempotent.

## 2026-09-12 — Recent views and draft execution boundary

Keep one recent_views row per `(user_id, exam_id)`, upserting the server timestamp;
analytics event history is separate future scope. Day 3 produces a draft migration
and offline static review only. No SQL application, project creation, remote push
or merge is authorized by this design task.

## 2026-09-12 — Day 3 independent-review remediation

Claude's reported verdict was C (important corrections needed). Preserve the
existing entity architecture and raw evidence; add a backend quarantine queue.

1. LegendStudy's mandatory external post ID with source is the canonical ingestion
   identity. URL is provenance/location, never a fallback conflict key.
2. Assign `legendstudy-{external_post_id}-{source_exam_key}` once. main or stable
   semantic keys identify source exams; never title, taxonomy or display position.
3. Taxonomy activity does not control source-content publication. Publish reviewed
   exams/occurrences/resources independently; inactive master joins fall back to raw labels.
4. Source-link-first remains. Attachment identity must be deterministic; same-exam
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
9. Duplicate exams remain inactive with merged_into_exam_id; trusted transactional
   merges validate cycles and personal conflicts. No automatic personal migration.
10. Profile id UPDATE enables key-preserving upsert; recent UPDATE grants only its
    two conflict keys and the trigger stamps time. Both need actual API tests.

The supplied directive identifies S-7/S-8 (taxonomy), S-9 (verified protection) and
S-12 (profile upsert). It does not supply Claude's complete S-1–S-15 numbered review;
other numbers cannot be reliably assigned. Coverage is recorded by directive topic
rather than fabricating review IDs. Independent re-review has not been performed.
