# Daily Sync Phase 1 — Deterministic Source and Delta Core

**Status:** `READY FOR CODEX — OFFLINE / DRY-RUN ONLY`

**Prepared:** 2026-09-24

**Scope:** deterministic source observation, change classification, safe evidence, local state, and offline fixtures.
**Out of scope:** Production writes, database migrations, schedule creation, Edge Functions, Cron, staging tables, review queues, publication, activation/deactivation, and attachment download.

> **Phase 1 is a source-observation package.** It may identify a candidate as new or modified relative to a local accepted snapshot. It must not infer that a candidate is safe to write, active, inactive, published, unpublished, or deleted in Production.

## 1. Canonical Phase 0 baseline

The Product Owner directly ran the Phase 0 aggregate-only validation on 2026-09-24 and recorded `PUBLISHED_COMPLETE`, with the reported integrity checks passing. The fixed Pilot C aggregate counts and current published state are recorded once in the consolidation’s Phase 0 result and the current-status publication entry.

The count details live in the Phase 0 result and the current Pilot C status record rather than being repeated throughout this package. This document uses the result only as the factual starting point for Phase 1. It does not query Production, alter the baseline, or authorize a writer.[1] [2]

Historical records that describe an inactive or pre-publication Pilot C remain valid evidence of the then-current gate and transaction design. They are not current Production assertions.[3] [4]

## 2. Quarantine 23 — confirmed interpretation

| Required question | Factual answer |
| --- | --- |
| `QUARANTINE_23_EXPECTED` | **Yes.** The exact Pilot C plan produced one advisory case per each of its 23 source posts. |
| `WHY` | Each Pilot C post has modern Kakao CDN attachments whose page links contain a rolling signing query. The pipeline stores only the unsigned path as identity, marks the resource `link_kind='unknown'`, and creates `resource_url_expiring` as an advisory case. |
| `LIFECYCLE` | A quarantine row is private. Its schema supports `open`, `resolved`, and `ignored`; resolution requires `resolved_at`. The Pilot apply path inserts advisory rows separately from canonical rows so rollback of a failed canonical transaction cannot erase evidence. |
| `PUBLICATION_RELATION` | The advisory does not block a high-confidence Pilot C candidate. Publication activates only `content_items`, `exam_subjects`, and `resources`; it does not activate, resolve, delete, or expose quarantine. Therefore published Pilot content and an open advisory quarantine row can coexist. |
| `SAFE_TO_KEEP` | **Yes.** Keeping the 23 rows preserves the evidence that a current Kakao locator is identity only, not a verified direct file URL. |
| `SAFE_TO_DELETE` | **No automatic deletion is safe.** Phase 1 must not update or delete these rows. Any later human resolution must preserve an explicit rationale and the current schema lifecycle; it is not a cleanup task. |
| `FUTURE_DAILY_SYNC_BEHAVIOR` | Treat the existing rows as a known advisory baseline. A signed-query rotation alone is not `MODIFIED` and must not create a new advisory duplicate. A newly observed modern post may report the same advisory in dry-run output, but Phase 1 performs no database write. |

This conclusion follows the deterministic `resource_url_expiring` code, its advisory classification, the Pilot C expected-row table, and the applied-schema lifecycle. It is not based on an assumption that every open quarantine is blocking.[3] [4] [5]

## 3. Current pipeline inventory and Phase 1 reuse decision

The existing Python pipeline is a usable source and normalization core. It already separates source retrieval, raw parsing, canonical planning, change hashing, and the tightly scoped Pilot writer. It must be extended in place rather than replaced by a new ingestion system.[3]

| Area | Current verified behavior | Phase 1 decision |
| --- | --- | --- |
| `crawler.py` | Serial fetcher; `robots.txt` route gate; 1.5-second default delay; 20-second timeout; two retries; optional request budget; sitemap numeric-ID extraction. | **EXTEND.** Preserve all controls. Add structured sitemap `lastmod` extraction, RSS candidate parsing, explicit bounded candidate selection, and a state-backed reconciliation cursor. Do not increase concurrency. |
| `parser.py` | Canonical numeric post ID; source times; title/category; modern/legacy provider identity; safe Kakao signing-query removal; body text extraction; attachment metadata only. | **EXTEND.** Add a redacted, deterministic body/metadata fingerprint and provider-specific query canonicalization. Do not persist source HTML, attachment bytes, or signed queries. |
| `normalizer.py` | Canonical `(source, external_post_id)` plan, content/resource identities, source-time fields, content hash, resource classification, quarantine, and inactive planned rows. | **EXTEND.** Keep the canonical hash as the projection-comparison basis. Add a versioned safe observation fingerprint and resource-level before/after change-set builder. |
| `pipeline.py` | Plans posts, records parse errors, detects a digest difference, emits `source_missing`, and never treats absence as deletion. | **EXTEND.** Replace the ambiguous binary `changed` list with deterministic `NEW`, `UNCHANGED`, `MODIFIED`, `MALFORMED`, `AMBIGUOUS`, and observation-only failure states. Preserve the existing no-delete behavior. |
| `models.py` | `RawPost`, `RawAttachment`, `PlannedPost`, and `QuarantineCase` are offline plan objects. | **EXTEND.** Add versioned local-state and safe-delta data models only. No DB model or service credential. |
| `ingest_legendstudy.py` | Sample/network dry-run, artifacts, optional JSON digest state, smoke, survey, and bounded Pilot C apply entry points. | **EXTEND.** Add a Phase 1 dry-run mode and redacted delta artifacts. The new mode must reject `--apply`, `--postflight`, and database settings. |
| `subjects.py` and `taxonomy.py` | Deterministic source-label mapping; no automated `verified` mapping; historical ambiguity remains held. | **REUSE / DO NOT BROADEN.** Reuse existing mapping results as evidence. Do not add taxonomy releases or change mapping rules as part of source/delta work. |
| `writer.py`, `apply.py`, `publish_pilot_c.py` | Pilot C is bounded. The apply path is insert-only and fails closed; the publication path activates only the fixed Pilot scope. | **DO NOT TOUCH.** Phase 1 must not call, import for execution, generalize, or copy these Production paths. |
| Supabase migrations, RLS, Flutter repositories, resource resolver | Existing schema and client publication/safe-open contracts are already independent of dry-run observation. | **DO NOT TOUCH.** There is no Phase 1 schema, client, or publication change. |

### Existing gap that Phase 1 closes

Today `pipeline.run()` labels every digest mismatch as `changed`, including a first observation. Its persisted state is only `external_post_id → content_hash`. The summary cannot distinguish a new candidate from an edited known post, cannot explain a resource-level change, cannot use sitemap `lastmod`, and cannot safely represent partial source observation. Phase 1 closes only these source/delta gaps. It does not close the later run-ledger, lease, staging, review, general-writer, or scheduler gaps.[3] [6]

## 4. Immutable contracts

The following rules are regression contracts, not optional implementation choices.

1. **Source identity:** `source_posts` identity remains `(source, external_post_id)`. A title, canonical URL, attachment set, resource count, subject, or category change must not create a new source identity.
2. **Content identity:** an existing post retains its `source_content_key`, slug, parent identity, and stable resource identities. A changed post is a revision candidate, not an automatic new content item.
3. **Source time:** `article:published_time` is the source creation/publication time. `article:modified_time` is the source update time where provided. `last_crawled_at` is only the time LegendStudy observed the page. No Phase 1 code may use crawl time as a source update time.
4. **Home ordering:** `feed_updated_at` remains generated from source publication/update time. A re-fetch, reparse, unchanged observation, state-file rewrite, or dry-run report must never move a Home card.
5. **Attachment safety:** routine observation fetches landing pages only. It never downloads attachment bytes, replays Kakao signing material, or persists full signed URLs. `unknown`, `landing_page`, and `file` keep their existing safe-open distinction.
6. **Verified mappings:** automation never updates an existing `exam_subjects` row with `mapping_status='verified'`. A conflict is an `AMBIGUOUS` review condition.
7. **No destructive inference:** timeout, HTTP failure, partial HTML, parser failure, one missing sitemap entry, or an absent attachment in one otherwise complete parse never deletes, deactivates, unpublishes, or removes a canonical resource.
8. **No automatic publication:** every Phase 1 output is a local dry-run candidate. It must not alter `is_active`, call a write tool, or notify users.

These rules are established in the canonical ingestion contract and are independently compatible with the active-only, source-time Home query.[3] [7]

## 5. Deterministic delta model

### 5.1 State and input boundary

Phase 1 reads a **local, versioned, redacted state file**. It does not read or write Production. Its initial state may be built from a reviewed dry-run artifact; it is not proof of database presence. Therefore `NEW` means **new relative to the accepted Phase 1 state**, not “safe to insert into the canonical database.” A later general writer must re-check `(source, external_post_id)` under its own lock before any write.

The state format must preserve these fields per source identity:

- `external_post_id`, canonical post URL, accepted canonical hash, observation fingerprint, parser version, mapping-rule version, and safe source publication/update timestamps;
- deterministic safe projection evidence: title hash, normalized category, derived content/exam summary, and resource descriptors keyed by provider + stable resource key;
- last successful complete observation timestamp, sitemap `lastmod` when available, and reconciliation cursor metadata; and
- no source HTML, body excerpt, attachment bytes, signed query, raw response header/cookie, credential, database setting, or user data.

A state-format version mismatch is `AMBIGUOUS` until a deterministic migration or bootstrap operation is supplied. Silent reinterpretation of old hashes is not allowed.

### 5.2 Canonical and observation fingerprints

The existing canonical content hash already ignores Kakao signing-query rotation because attachments are represented by provider identity, display name, and unsigned URL. Phase 1 must preserve that behavior for known Kakao signing material.[3]

Phase 1 adds two versioned fingerprints:

1. **Canonical projection hash.** This continues to cover title, category, source times, parser/mapping versions, and sorted canonical attachment descriptors. It is the primary `UNCHANGED`/`MODIFIED` comparison.
2. **Safe observation fingerprint.** This is a hash of normalized non-secret page text/metadata that could affect review but is not otherwise projected. It must be built from a normalized body representation and selected recognized metadata, then retain only its hash and length/count diagnostics. It detects body/metadata edits without storing raw article text.

Provider canonicalization must be explicit. Strip only documented ephemeral Kakao signing fields for Kakao CDN. Do not use the current broad query stripping as a new general rule for an unfamiliar provider. A changed query whose provider semantics are not verified is `AMBIGUOUS`, not silently ignored or treated as a new stable resource identity.

### 5.3 Primary classifications

The primary classification is mutually exclusive and deterministic. A candidate also carries `review_flags`, `change_categories`, and `observation_status` so that a safe review can see both a content delta and a non-blocking advisory.

| Primary classification | Required condition | State advance | Required output behavior |
| --- | --- | --- | --- |
| `NEW` | A complete, non-ambiguous canonical observation has no prior identity in the accepted local state. | May add the local state record only after artifacts and tests succeed. | Report a candidate. Do not insert canonical rows. |
| `UNCHANGED` | Same identity and same canonical projection hash/version; a changed crawl timestamp alone is ignored. | Record a successful observation time only. | Report no projection change. Do not change source time or Home order. |
| `MODIFIED` | Same identity, complete non-ambiguous observation, and canonical projection hash differs. | May replace the accepted local snapshot only after the complete dry-run succeeds. | Report a resource/parent change set. Do not update Production. |
| `MALFORMED` | Page was retrieved but required source facts cannot be parsed or an invariant fails, including partial HTML with missing required fields. | **No accepted-hash advance.** | Report a safe failure class and retain last known-good snapshot. |
| `AMBIGUOUS` | A complete enough observation has unsafe identity/provider/query/mapping/type semantics, duplicate same-run identities, or a conflict that must be reviewed. | **No accepted-hash advance** unless a future explicit resolution policy exists. | Quarantine-style dry-run candidate with safe evidence. No coercion to `other`. |

`SOURCE_MISSING` is an **observation-only state**, not a primary success classification. A previously accepted ID absent from a complete sitemap/feed inventory yields `source_missing` evidence and no state removal. Transport failures use `observation_status='FETCH_FAILED'`; they are counted under `failed`, retain the last known-good snapshot, and must never be reclassified as removal.

### 5.4 Required change categories

A `MODIFIED` candidate must expose one or more of these stable category names:

- `title_changed`, `category_changed`, `source_published_time_changed`, `source_updated_time_changed`, `body_or_metadata_changed`;
- `exam_metadata_changed` for year, month, grade, type, academic-year evidence, or source content type;
- `subject_mapping_changed` for an occurrence-key or planned scope/mapping difference; and
- `resource_added`, `resource_changed`, or `resource_unconfirmed_absent`.

The resource comparison key is `(provider, source_resource_key)`. The comparator must report resource type, normalized display-label fingerprint, occurrence subject key, link kind, safe unsigned locator fingerprint, and extension/count differences. A resource that is absent from one otherwise complete parse is `resource_unconfirmed_absent`; it is not a deletion request. A Kakao signature-only rotation produces no change category.

## 6. Discovery, old-post reconciliation, and source budget

Phase 1 defines an executable dry-run selection algorithm but creates no scheduler.

1. Read only allowed source endpoints after the existing robots path gate. Parse numeric IDs from the sitemap and use RSS/feed only as a recent-discovery accelerator.
2. Extend sitemap parsing to retain `external_post_id → lastmod`; union new IDs, changed `lastmod`, recent feed IDs, pending local retry IDs, and the next reconciliation shard.
3. Select candidates in deterministic priority order: pending bounded retry; new source identity; changed sitemap `lastmod`; recent feed-only discovery; then the oldest unobserved reconciliation segment. Break ties by numeric post ID and store the selected order in the artifact.
4. Fetch only selected canonical landing pages. Do not discover posts by guessing a next integer and do not fetch attachment targets.
5. Advance the local reconciliation cursor only after a complete dry-run artifact has been written. A failed candidate does not make another source absent.

The initial implementation default should be intentionally small: one `robots.txt`, one sitemap, one feed, and at most five landing pages. With up to two retries per request, the hard request ceiling is **24** requests: three endpoints × three attempts plus five pages × three attempts. It retains the existing serial 1.5-second minimum interval and 20-second timeout. Backoff is existing exponential backoff; a valid `Retry-After` support may be added only with fixture coverage.

The bounded old-post pass must use a persisted deterministic cursor over actual sitemap IDs or stable shards, not a range of guessed integers. It is a dry-run planning capability in Phase 1. The daily cadence, execution environment, alerting, and stored operational cursor belong to Phase 2 or later.[6]

## 7. Python versus Deno/TypeScript

| Option | Implementation risk | Existing test reuse | Future hosted-runtime fit | Maintenance and drift |
| --- | --- | --- | --- | --- |
| **A. Keep Python source/delta core for Phase 1** | Low. It extends the current stdlib pipeline and its 146 passing offline tests. | High. Existing fixtures, parser, normalizer, crawler, signature handling, and safe apply exclusion are directly reusable. | It is not directly runnable inside a Deno Edge Function. A later runner needs a deliberately selected Python-capable environment or a tested adapter. | One canonical implementation now; lowest immediate behavior-drift risk. |
| **B. Create Deno/TypeScript parity now** | High. It duplicates source parsing, hashing, provider canonicalization, subject mapping, and all fail-safe behavior before Phase 1 has a complete fixture contract. | Low at first. Tests must be re-authored and cross-language parity proven. | Better fit for a future Supabase Edge Function. | Two implementations immediately increase drift risk unless every fixture runs against both. |

**Recommendation:** choose **Option A for Phase 1**. Extend the existing Python source/delta core and freeze its fixture/output contract before considering a port. This is not a decision to deploy Python on a scheduler. It simply prevents an untested Deno rewrite from becoming the first authoritative implementation. A later Owner-approved runtime decision may choose Python execution or Deno parity, but Deno must pass the same versioned fixture corpus before it can stage or promote data.[6]

## 8. Phase 1 dry-run output contract

The new mode writes a deterministic, redacted artifact directory. It may be local or CI-generated, but it is never a Production control plane.

### `delta-run-summary.json`

The summary must include schema version, parser/mapping versions, dry-run mode, safe observation timestamp, source-budget configuration and consumption, candidate selection order, input-state version/fingerprint, output-state fingerprint, and these counters:

```text
observed
new
modified
unchanged
malformed
ambiguous
source_missing
failed
skipped_by_budget
```

It must also state `production_mutation: 0`, `database_migration: 0`, `scheduler_created: 0`, and `publication: 0`.

### `delta-candidates.jsonl`

One stable-key-sorted object per observed candidate must contain:

```text
external_post_id
classification
observation_status
source_times { published_at, updated_at, sitemap_lastmod }
safe_metadata { content_type, exam_summary, attachment_counts_by_provider_and_kind }
change_categories
resource_change_summary { added, changed, unconfirmed_absent }
review_flags
before_fingerprint
after_fingerprint
```

A candidate may include its canonical numeric source URL only if the URL has no query or fragment. It must never include a signed attachment URL, query value, cookie, authorization header, database setting, raw HTML, raw body excerpt, attachment bytes, user data, or unsanitized exception text. Full cryptographic hashes may be retained; presentation may use a short prefix only if the complete hash remains in the local state.

### Safe evidence standard

The report should answer “what changed?” using field/category names, counts, provider/resource identities, public post title where necessary, and before/after safe fingerprints. It should not archive the entire source page merely to make a diff readable. For example, an added answer file can be represented as `resource_added`, provider `kakaocdn`, stable resource key, type `answer_explanation`, and subject scope without storing a signed link.

Artifacts must sort output deterministically. Repeating the same input, prior state, parser version, and configuration must produce the same candidate classifications and change categories. Only a generated observation timestamp may differ.

## 9. Codex Phase 1 package

### Files to read

- `AGENTS.md`, `wiki/index.md`, `wiki/current-status.md`, `wiki/ingestion.md`, and this package.
- `wiki/day-9-ingestion.md`, `wiki/day-9-pilot-c-package.md`, and `wiki/day-9-d1-publication-package.md` for historical guardrails.
- `tool/ingestion/{__init__,models,crawler,parser,normalizer,pipeline,subjects,taxonomy}.py`.
- `tool/ingest_legendstudy.py` and `tool/test_ingestion.py`.
- `supabase/review/ingestion_contract.json` and the initial schema for contract reference only.

### Files to change — proposed, not changed by this task

- `tool/ingestion/models.py` — versioned local-state, candidate, and safe-diff models.
- `tool/ingestion/crawler.py` — structured sitemap/RSS discovery types and bounded deterministic selection helpers.
- `tool/ingestion/parser.py` — safe body/metadata fingerprint input and provider-specific query canonicalization.
- `tool/ingestion/normalizer.py` — canonical/observation fingerprint construction and resource descriptors.
- `tool/ingestion/pipeline.py` — delta classifier, resource change-set builder, `SOURCE_MISSING` observation, local-state migration/validation, and reconciliation planning.
- `tool/ingest_legendstudy.py` — explicit Phase 1 dry-run command, bounded source arguments, deterministic artifacts, and a hard refusal to mix it with apply/postflight options.
- `tool/test_ingestion.py` or a focused `tool/test_ingestion_phase1.py` — fixture tests and regression tests.
- `tool/ingestion/samples/phase1-delta/` — metadata-only fixture records and expected redacted output snapshots.
- `wiki/ingestion.md`, `wiki/current-status.md`, and `wiki/log.md` only after Code Review validates implementation evidence.

### Files not to touch

- `tool/ingestion/apply.py`, `tool/ingestion/writer.py`, `tool/publish_pilot_c.py`, and `tool/test_publish_pilot_c.py`.
- `supabase/migrations/`, `supabase/seed/`, RLS, Storage, Edge Functions, Cloudflare configuration, GitHub Actions, scheduler configuration, and any production configuration.
- Flutter source, app feed queries, resource safe-open code, authentication, and publication UI.

### Implementation steps

1. Add state-v2 parsing with an explicit schema version and deterministic backwards migration from the current digest-only state. Invalid or unknown state becomes `AMBIGUOUS`; it is never guessed.
2. Add safe observation input. Hash normalized body/recognized metadata without retaining raw body in state or artifacts. Preserve existing canonical identity and source-time semantics.
3. Replace broad attachment query stripping with provider-specific canonicalization. Known Kakao signing rotation must remain invisible to canonical change detection; uncertain query semantics must become reviewable ambiguity.
4. Add exclusive delta classification and resource-level change categories. Preserve the current parser-error and `source_missing` no-delete behavior.
5. Add structured sitemap `lastmod`, feed candidates, deterministic queue ordering, local reconciliation cursor, and the 24-request maximum. Keep source access serial and attachment-free.
6. Emit the redacted summary and candidate artifacts. Reject unsafe CLI combinations and scan artifacts for signing tokens.
7. Add fixtures and repeatability tests. Run the full offline ingestion suite and the Phase 1 fixture suite without network, database, scheduler, or Flutter execution.

### Required fixture package

| Fixture | Prior state / observation | Expected classification | Required assertion |
| --- | --- | --- | --- |
| `new_post` | Complete unseen numeric post. | `NEW` | Candidate only; no DB action; stable identity. |
| `unchanged_post` | Same accepted canonical and observation fingerprints. | `UNCHANGED` | Changed crawl time does not alter result or source/Home time. |
| `edited_title` | Same ID, changed title. | `MODIFIED` | `title_changed`; no new parent identity. |
| `edited_body_metadata` | Same ID, same canonical attachment set, changed normalized body/recognized metadata. | `MODIFIED` | `body_or_metadata_changed`; no raw body artifact. |
| `edited_subject` | Same ID, stable resource key, changed parsed subject/scope evidence. | `MODIFIED` or `AMBIGUOUS` | `subject_mapping_changed` if safe; `AMBIGUOUS` if mapping/verified protection conflict. |
| `added_answer` | Same ID, new stable answer resource identity. | `MODIFIED` | `resource_added`, `answer` or `answer_explanation`. |
| `added_audio` | Same ID, new stable audio resource identity. | `MODIFIED` | `resource_added`, `listening_audio`; no byte fetch. |
| `resource_absent_complete` | Same ID, previously accepted resource not observed in a complete parse. | `MODIFIED` | `resource_unconfirmed_absent`; no deletion/deactivation instruction. |
| `signature_rotation_only` | Same Kakao path/provider key; only signed query changes. | `UNCHANGED` | Same resource key/hash; no signing material output. |
| `malformed_post` | Retrieved page lacks required identity/title/category structure. | `MALFORMED` | State does not advance; last good data retained. |
| `partial_fetch` | Truncated/partial source response. | `MALFORMED` | No inferred absent resources or accepted-hash advance. |
| `source_missing` | Prior accepted ID absent from a complete discovery inventory. | `SOURCE_MISSING` observation | No state deletion, canonical deletion, or publication change. |
| `duplicate_observation` | Same source ID appears twice in one candidate input with inconsistent facts. | `AMBIGUOUS` | No last-writer-wins behavior. |
| `unknown_provider_query_change` | Provider query semantics cannot be safely normalized. | `AMBIGUOUS` | No silent query stripping or new resource identity. |
| `fetch_timeout` | Existing ID cannot be fetched within retry/budget rules. | `FETCH_FAILED` observation | No accepted-hash advance or destructive inference. |

### Phase 1 acceptance criteria

Codex may mark Phase 1 complete only when all conditions hold:

- **Production mutation: 0.** No database connection, Storage call, Scheduler/Cron creation, Edge deployment, Cloudflare change, publication, or `is_active` change occurs.
- **Schema migration: 0.** No migration, seed change, RLS/grant change, or production configuration change exists.
- **Pilot tools untouched.** `apply.py`, `writer.py`, and `publish_pilot_c.py` remain unchanged and the Phase 1 command cannot invoke their write paths.
- **Determinism.** Repeated fixture inputs produce identical classifications, candidate order, change categories, state fingerprint, and safe output apart from the declared run timestamp.
- **Identity/source time.** The same numeric post remains the same identity through title, subject, attachment, and metadata edits. Crawl time does not produce `MODIFIED` or Home-order changes.
- **Delta coverage.** Offline tests reproduce `NEW`, `UNCHANGED`, `MODIFIED`, `MALFORMED`, `AMBIGUOUS`, `SOURCE_MISSING`, and fetch failure behavior.
- **Attachment coverage.** Added answer/audio and unconfirmed absence are detected. Kakao signature rotation alone is `UNCHANGED`. No fixture downloads attachment bytes.
- **No destructive inference.** Partial fetch, parser failure, timeout, and missing source retain the last accepted snapshot and never propose deletion/unpublication.
- **Regression contracts.** Existing source identity, source-time Home ordering, unknown-resource safe opening, landing/file distinction, verified-mapping protection, and no automatic publication all pass their targeted tests.
- **Output hygiene.** Artifact scans find no `credential=`, `signature=`, `expires=`, cookie, authorization, database-password, service-role, raw HTML, or attachment-byte output.

## 10. Known gaps and Phase 2 boundary

Phase 1 intentionally leaves these capabilities absent: a durable database run ledger, lease/fencing, observation/stage tables, review queue, general update writer, promotion transaction, alerting, secret ownership, a deployed endpoint, and a schedule. It also does not decide whether source candidate changes may eventually create/update inactive canonical rows.

A Phase 2 proposal must be additive and separately reviewed. It must not reuse Phase 1 local state as a substitute for a durable run ledger, nor transform a dry-run `NEW`/`MODIFIED` result directly into a public data mutation.[6]

## 11. Owner decisions and next handoff

No additional Owner approval is needed to implement the **offline Python Phase 1 package** within this document’s boundaries. The following remain future decisions:

1. whether an eventual hosted runtime uses Python or a Deno/TypeScript implementation after fixture parity;
2. daily and reconciliation execution windows, source-budget target, alert ownership, and operational data retention;
3. whether a later staged writer may create or update inactive canonical rows; and
4. any review/publication/deactivation policy.

The next implementer should begin with the fixture contract and existing Python tests. They must not start Phase 2 merely because Phase 1 can report a candidate.

## References

[1]: current-status.md "LegendStudy Current Status — Confirmed Pilot C publication"
[2]: research-2026-09-24-product-operations-synthesis.md "Research A–D Product and Operations Consolidation — Phase 0 Owner validation"
[3]: ingestion.md "LegendStudy Ingestion Strategy — identity, clocks, quarantine, and daily synchronization handoff"
[4]: day-9-pilot-c-package.md "Day 9-B2 Production Pilot C apply package — expected rows and postflight"
[5]: ../supabase/migrations/20260912000100_initial_content_schema.sql "Initial content schema — ingestion_quarantine lifecycle"
[6]: research-2026-09-24-product-operations-synthesis.md "Research A–D Product and Operations Consolidation — daily sync recommendation and phase plan"
[7]: ../lib/features/content/data/supabase_content_repository.dart "Supabase content repository — active-only source-time recent feed"
