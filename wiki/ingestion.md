# Ingestion Strategy — Unified Content v0.1

## Status and source boundary

The ingestion pipeline remains design-only: no production crawler/backfill or
Flutter runtime scraping. The owner reports the dedicated LegendStudy initial
schema applied and runtime fixtures cleaned up (all 10 application tables empty).
See current-status.md/database.md for deployment evidence; this docs task did not
connect to the DB. Preserve the applied initial migration; future DB changes use
new migration files. The contracts below still await ingestion implementation.

Representative pages read on 2026-09-12: [exam 1705](https://legendstudy.com/1705),
[historical exam 1415](https://legendstudy.com/1415), [practice collection 991](https://legendstudy.com/991),
[admissions column 927](https://legendstudy.com/927), [Yonsei essay 1612](https://legendstudy.com/1612)
and [multi-year essay 1610](https://legendstudy.com/1610). These show why not every
post is one exam. Actual links/text were inspected, not attachment bytes, MIME,
playback or archive completeness. The old 1,673 count is a dated observation,
not a hard-coded import boundary. Revalidate sitemap/RSS/robots before implementation.

## Detection → classification → publication

1. Detect new/modified source posts using reliable source timestamps plus meaningful
   content hash; last_crawled_at records observation only. A timestamp alone may
   miss edits, so bounded periodic reconciliation remains necessary.
2. Upsert source_posts on `(source, external_post_id)` with private raw evidence,
   source title/location, source publication/update timestamps and crawl status.
   Mandatory LegendStudy numeric post ID; no canonical-URL identity fallback.
3. Classify source blocks into stable content items. Types are exam, study_material,
   education_column, university_essay, admissions_info, other. Exam subtypes belong
   only to exams.exam_type. Uncertain category/segmentation creates durable
   quarantine; it is not silently published as other. Keep raw category, proposed
   type, parser/rule version and rationale in private raw_metadata keyed by content key.
4. Upsert content_items on `(source_post_id, source_content_key)`, preserving UUID
   and slug. Map reviewed public title/summary/source_url and known source times;
   thumbnails are optional. Source_posts itself never becomes the public search API.
5. Run the type parser: exam → shared-ID exams + occurrences/resources; study_material
   or university_essay → general resources, no exam extension; columns/admissions
   → parent alone is valid, optional observed resources. No full article requirement.
6. Validate complete parent/child batch, FK/type consistency, public-safe fields,
   stable attachment identities, mapping exclusions and classification evidence.
   Persist ambiguity in quarantine; publish only accepted items via content_items.is_active.
   An exam item must have its reviewed exam extension before publishing. Subject
   and resource flags remain independent child controls; taxonomy activity does not
   determine occurrence/resource publication.

These are future implementation contracts, not an implemented ingestion service.
Trusted credentials stay server-side and never come from another application.

## Identity and reruns

- source_posts uses `ON CONFLICT (source, external_post_id)` only. URL is location/
  provenance; update the same row after verified redirect/alias evidence. URL UNIQUE
  detects collisions, not an alternate upsert identity. Missing IDs can quarantine
  without a source FK; future ID-less source support needs a separate migration.
- Single content key is main. Multi-content keys represent stable source semantics,
  e.g. grade3, morning, essay-2019. They match `^[a-z0-9]+(-[a-z0-9]+)*$` and never
  derive from array index, display order, title hash or mutable taxonomy. Record
  segmentation evidence and explicitly reconcile splits/merges.
- First slug is `legendstudy-{external_post_id}-{source_content_key}` and never
  changes on automatic rerun. The previous exam key becomes the common content key;
  existing assigned route values are preserved, e.g. legendstudy-1705-main.
- Exam upsert target is content_item_id (shared PK), obtained from the parent.
  Do not send generated content_type or sort_date. No independent exam id/source key.
- Occurrences use `(content_item_id, source_subject_key)`. Persist verified original
  occurrence identifiers or an evidence-backed assigned key; duplicate/NULL taxonomy
  mappings must not collapse distinct raw labels.
- Resources use `(content_item_id, source_post_id, source_resource_key)`. Stable
  original attachment identity (e.g. verified provider file ID) must be deterministic
  across reruns; no title/order/signed-query keys. Ambiguous identity is quarantined,
  not assigned a fresh random key. Optional scope points to an occurrence of the
  same content and therefore the same exam; non-exam attachments leave scope NULL.
- A changed provenance source_post_id is explicitly reconciled to the same resource
  UUID after review; blindly upserting a new conflict tuple would create duplicates.
- Distinct resource identities with same content + normalized source URL go to
  quarantine. Normalization uses verified provider rules for scheme/host/ephemeral
  query fields, never strips unknown meaningful query data. Original source_url
  remains as observed. No content/URL UNIQUE until legitimate reuse is understood.

## Modified posts, clocks and soft states

A later answer/explanation or grade-cut attachment on an existing exam post updates
the same source and content item and adds/upserts its resource. It does not create
a new content item just because title/hash/resource count changed. The same rule
covers updated columns, additional essay PDFs and revised study collections.
Known modification time is synchronized to the corresponding content projection;
feed_updated_at derives from the later known source publication/modification time.

Home is source-time-based, not app-ingestion-time-based. Do not write generated
feed_updated_at or substitute now()/last_crawled_at/local updated_at as a source
modification time. With no reliable source update timestamp, preserve publication
fallback; the contents can change without an artificial Home bump. Missing both
source times means a NULL-tail card. Preserve exact timestamp precision/timezone
only when source evidence supports it; avoid inferring it from a search snippet.

Prepare a complete batch and commit source success metadata, parent public
projections and accepted children atomically. Lock/serialize same-source workers;
when secondary sources attach to shared content, also serialize on the content
in deterministic order to prevent duplicate-normalized-URL races. Persist success
hash/parser version only after the accepted batch succeeds. An unchanged hash is
skippable only if parser/classification/mapping versions and pending review state
also permit skipping. Do not bump source feed time just because parsing reran.

Partial fetch/parse never interprets omitted resources as deletions or advances
success metadata. Source deletion/link failure sets source_status/link_status and
queues review. Reviewed unpublication sets content_items.is_active=false; all
children become invisible through parent RLS. A single missing/broken response
never hard-deletes or automatically unpublishes established content. Individual
resources/occurrences can be hidden separately. Do not re-publish a merged duplicate.

Type reclassification of an existing item is trusted reconciliation on the same
identity, not a new row. The exam discriminator FK blocks changing type while its
extension exists. Stop and quarantine incompatible existing children; a later
reviewed transaction handles conversion, scope cleanup and republishing. No blind
cascade, automatic extension deletion or user-reference loss. Preserve before/after
evidence; complete revision/event history is a later requirement.

## Raw taxonomy and public evidence

Retain raw_subject_label/source_label exactly, NULL if absent, not fabricated text.
Raw date/year/grade/type, displayed size, curriculum uncertainty and classification
notes remain private evidence. Distinguish calendar year/academic year/nominal month;
bound-check known values rather than inventing facts to satisfy CHECKs.

Unmapped/unmappable have NULL subject/version/confidence; provisional needs a valid
mapping and confidence; verified permits NULL confidence but requires verified_at.
Human unmappable rationale/time belongs in quarantine resolution. Historical
가형/나형 are never automatically modern electives. Released taxonomy meaning and
hierarchy require separate review/cycle checks. Inactive taxonomy master details
may disappear from a left join, but raw active occurrences and PDFs remain visible.

Automated ingestion MUST NOT update any existing exam_subjects row whose mapping_status is verified.

This excludes the entire verified row, including raw label, mapping, confidence,
notes, verified_at and publication fields. Conflicting new evidence is quarantined.
Lock/recheck status within the transaction to avoid races with human verification.
No service_role override GUC/protection trigger is added now. Before implementing
an update path, review separate DB enforcement/management workflow. The checker
requires this document rule and ingestion_contract.json; it cannot prove a future
parser obeys them. Re-review of human unmappable decisions should also be explicit.

## URL fetch gate and durable quarantine

Preserve original source links; a Box share page is not proven MP3 bytes. file_url,
MIME/byte size stay NULL unless verified. No mirroring/Storage/downloads in Day 3.
Case-insensitive HTTP(S) CHECKs cover shape and reject non-HTTP schemes, not SSRF.
Before future fetching, validate allowlisted hosts, every redirect and resolved IP,
reject private/link-local destinations and defend against resolution changes.
Do not persist expiring secrets/cookies/bearer tokens in public URLs or metadata.

Quarantine stores bounded JSON objects with kind, source_post_id if known,
status=open, note and created_at. When a normalized transaction fails, persist the
case in a separate trusted transaction so rollback cannot erase evidence. Human
resolution marks resolved/ignored with resolved_at and rationale; retry on explicit
reprocessing or resolved evidence. No app grants/policies. File-based run reports
record parser versions/counts/timing/errors; no ingestion_runs table yet.

## Trusted content soft merge

Merge is common to all content types; the old merged_into_exam_id moves to
content_items.merged_into_content_item_id. Determine compatible canonical content,
lock/serialize competing merges/writes, resolve roots and reject all cycles. The
DB rejects self-reference and active duplicates, not arbitrary long cycles.

Reconcile bookmarks by user/canonical content with insert/do-nothing. Reconcile
recent rows by user/content using the existing server-time merge stamp (the clock
trigger stamps now; it cannot preserve an old maximum viewed_at). If original view
time retention is required, design a separate reviewed workflow before implementing
merge. Never UPDATE a recent row's content_item_id: the trigger forbids key changes.
After successful canonical inserts remove only the reconciled duplicate personal
rows, set duplicate inactive and record pointer, atomically. Retain the duplicate
content and provenance; scope/resource movement requires explicit same-content FK
reconciliation, not a pointer side effect or automatic hard delete.

## Future ingestion acceptance

Test same input twice, corrected titles, new answer/grade-cut files, reordered
attachments, signed query changes, known/unknown source update time, unknown type,
multiple semantic items, type correction, historical mapping, verified-row races,
secondary provenance, partial failures, concurrent workers and merge cycles. Expect
stable parents/slugs/resource identities, durable quarantine and no accidental
content loss. Test column/study/essay ingestion without exam rows and native
search/save/recent contracts on all types. No implementation/runtime claim here.
