# Ingestion Strategy — Data Model v0.1

## Status

Design only. No crawler, ingestion writes, SQL execution, deployed schema or
Supabase project creation occurred in Day 3. `wiki/database.md` is the canonical
model; the draft migration is not a deployed database. Website reading for design
was limited to representative public pages, not a backfill or file download.

## Source observations

Day 1 recorded an archive count of 1,673 and mixed exam/논술 content; that count
is a dated observation, not a hard-coded ingestion boundary or completeness claim.
Day 3 read [post 1705](https://legendstudy.com/1705),
[post 1686](https://legendstudy.com/1686), and
[post 1415](https://legendstudy.com/1415). They demonstrate modern elective labels,
calendar/academic-year differences, historical math variants, and audio/script
links. Attachment bytes, redirects, MIME, URL permanence and archive completeness
remain unverified. Source-heading errors are possible; never infer taxonomy from
a single inconsistent heading when filenames disagree.

## Flow and table mapping

`legendstudy.com → trusted parser/review → normalized tables → native app`

| Parsed signal | Destination |
| --- | --- |
| Stable post ID, canonical URL, source title/category/timestamps | source_posts |
| Fetch outcome, normalized content hash, parser version, uncertainty | private source_posts metadata + persistent ingestion_quarantine + run report |
| Exam/session blocks and reviewed date/type/grade metadata | exams (possibly several per post) |
| Curated taxonomy releases | subjects, managed separately from arbitrary scrape labels |
| Subject occurrences, original labels and proposed mappings | exam_subjects |
| Attachment/link occurrences, purpose, raw label, scope and original href | resources |
| Optional personal profile/save/view action | profiles/bookmarks/recent_views via authenticated client later; never crawler |

Only trusted ingestion may write content; it can use a service-role context later.
Keys stay server-side. Public app reads never scrape source HTML. Do not borrow
another application's project, schema, OAuth configuration or credentials.

## Source identity and stable keys

1. LegendStudy requires source=`legendstudy` and the numeric post path as nonempty
   external_post_id text. The sole canonical conflict target is
   `ON CONFLICT (source, external_post_id)`. Missing ID is a quarantine failure,
   never a URL fallback. URL is provenance/location; a verified URL change updates
   the same row. URL uniqueness only detects collisions. Aliases require evidence.
2. First slug assignment: `legendstudy-{external_post_id}-{source_exam_key}`.
   A single exam uses `main` (`legendstudy-1705-main`). Multiple exams use semantic
   stable keys such as `grade1`, `grade2`, `grade3`, `morning`, `afternoon`.
   Keys match `^[a-z0-9]+(-[a-z0-9]+)*$`. No positional numbers, display order,
   title/romanization, normalized taxonomy or mutable metadata. Persist segmentation
   evidence; uncertain segmentation goes to quarantine. Never change an assigned slug.
3. Match subject occurrences by established source identifiers or persist an
   allocated source_subject_key with evidence. Identical/NULL mappings must not
   collapse separate raw occurrences. Reorder/remapping preserves keys and UUIDs.
4. source_resource_key deterministically represents stable original attachment
   identity within its source post (e.g. verified provider file ID). It does not
   depend on title, display order or signed URL query. If no stable attachment
   identity can be established, persist a quarantine case for human reconciliation;
   do not silently allocate a fresh random key on each run.
5. Upsert exams on `(source_post_id, source_exam_key)`, occurrences on
   `(exam_id, source_subject_key)`, resources on
   `(exam_id, source_post_id, source_resource_key)`. Preserve slugs and UUIDs.
   Provenance correction explicitly reconciles the same resource UUID and checks
   conflicts before changing source_post_id; a blind upsert would duplicate it.
6. Before resource writes, compare same-exam normalized source URLs against existing
   and proposed rows. A distinct identity collision goes to ingestion_quarantine.
   Keep original href unchanged; normalization uses verified provider-specific
   identity rules (scheme/host casing, known ephemeral query fields), never drops
   arbitrary meaningful query data. Identical existing identity is a normal rerun.
   No `(exam_id, source_url)` UNIQUE is imposed without evidence that URL reuse is
   impossible. Serialize workers for the same exam as well as source when resources
   can originate in different posts; otherwise this application check races.

An exam can collect resources from secondary posts, each retaining provenance.
Cross-post exam matching is explicit and evidence-based; do not globally equate
same year/month/grade because source naming can be wrong and several sessions may
exist. Initial ingestion needs a reconciliation manifest in private metadata; the
unique keys alone cannot make a nondeterministic parser idempotent.

## Raw evidence and uncertainty

- Store every observed subject label in `raw_subject_label`, every attachment label
  in `source_label`; never substitute a normalized code for source text. If a label
  is absent, use NULL, not invented “unknown” source text. Source-level raw date,
  grade, year, size strings and parser evidence live in raw_metadata.
- Separate calendar `year` from source `academic_year`; a publication date is not
  an exam date. Preserve the nominal `exam_month` even if an exam was postponed to
  another month; `exam_date` is nullable until an actual date is supported.
- `raw_exam_type`, `raw_grade_label`, `curriculum_version` and normalization notes
  preserve meaning/uncertainty. Unknown normalized type/grade/date remain NULL.
  Bound-check values; hold conflicting year/date for review rather than changing
  the source evidence to satisfy constraints.
- Unknown subject → NULL subject and taxonomy version, unmapped status, NULL
  confidence, note explaining why. Proposed mapping → provisional status with
  version, confidence and rule version. A reviewer can mark verified with verified_at;
  confidence is optional then. No automatic confidence threshold. Human-reviewed
  unmappable means NULL subject/version/confidence, with review context in quarantine.
  verified_at is reserved for verified state. Raw labels remain after confirmation.
- Historical 가형/나형 can later map to reviewed historical master entries; do not
  map them to present-day electives just to fill a foreign key. Taxonomy releases
  and their hierarchies need a separate review (including cycle checks).
- Public exam/subject/resource labels contain only publishable material; diagnostic notes are private.
  Private run errors stay in source_posts or restricted reports. Do not collect
  comments, account information, cookies, bearer tokens or full HTML by default.
- For unverified rows, a changed source label updates evidence with a diagnostic note/report
  of the change; full revision/event history is deferred, not silently promised.

## URLs, checks and publication

Preserve every original `source_url` exactly as observed. A Box share link is a
landing-page resource; it is not a direct audio URL merely because its label says
MP3. `file_url` remains NULL until independently verified. No file-size/MIME guess
from rounded labels. No downloads/mirroring/Storage buckets are part of Day 3.

Before any future network fetcher, validate allowed hosts, redirects and resolved
IP ranges, including every redirect hop and private/link-local destinations, to prevent
server-side URL abuse. Case-insensitive HTTP(S) DB URL CHECKs only validate shape.
Do not strip attachment query parameters from stored source_url or put expiring
signed credentials into durable public metadata. Report links requiring such
credentials and decide a stable source-link strategy separately.

All four public content tables default inactive. For each post, prepare/review a
complete normalized batch and commit its upserts atomically in the future trusted
pipeline, locking the source row or otherwise serializing same-post workers.
Update content_hash/parser_version only after that normalized transaction succeeds.
Hash changes are based on meaningful normalized source content, excluding transient
ads/timestamps; identical hash is skippable only when parser and mapping versions
are unchanged and there is no pending reprocessing/review need.

Publish reviewed exams, source occurrences and resources independently of taxonomy
activation. An inactive taxonomy row never hides an active occurrence/resource;
the app uses a left join and raw-label fallback. A broken
link or temporary source error updates source_status/link_status and a report;
it must not immediately delete/deactivate all previously good material. Missing
items are reconciled only after a successful complete parse. Partial fetch/parse
must not advance success metadata or treat omitted attachments as deletions.

## Reporting and future validation

No ingestion_runs table in v0.1. The initial parser should emit a restricted
structured run report (run ID, parser/mapping version, start/end, processed,
inserted, updated, skipped, failed counts, bounded non-sensitive error summaries).
Source-level status/hash/version are persisted; durable run history can be added
when operations require it.

Before backfill implementation, revalidate sitemap/RSS/robots, archive pagination,
attachment behavior, older curricula, duplicate/redirect handling, bounded retries
and missing-source grace periods. Test same input twice, reordered subjects/files,
corrected raw labels, changed taxonomy, signed-query changes, partial failure,
concurrent workers, multi-exam posts and secondary source reconciliation. Expected
result is stable identities and no accidental deletion/duplication, not merely
passing a unique constraint. Representative mappings are in `wiki/database.md`.

## Verified mapping invariant and persistent review

Automated ingestion MUST NOT update any existing exam_subjects row whose mapping_status is verified.

This excludes the entire existing row from automatic upsert/update, including raw
label, mapping pair, confidence, rule/note, verified_at and publication fields.
New conflicting evidence creates a quarantine item; a later human workflow decides
changes. Future code must lock/recheck the stored status within its transaction,
not trust an earlier read that can race with verification. No service_role override
GUC/protection trigger is added now. Before implementing a verified update path,
review a separate enforcement migration and management workflow. The checked-in
`supabase/review/ingestion_contract.json` and checker require this rule and its
schema fields; they do not prove that a future ingestion implementation obeys it.

Quarantine is durable: persist a bounded JSON object with kind, source_post_id when
known, status=open, note and created_at. If the normalized batch rolls back, record
the failure in a separate trusted transaction so evidence is not rolled back with
it. Store no tokens, cookies, private student data or unbounded HTML. Human review
marks resolved/ignored with resolved_at and rationale; retry only after resolution
or an explicit reprocessing decision. No public API or client policy exists.

## Trusted duplicate exam soft merge (future implementation)

1. Lock relevant exams/personal rows in deterministic order and serialize competing
   merges/writes. Resolve canonical root; reject self-reference and all longer cycles.
2. Reconcile bookmarks by owner/canonical exam with conflict-safe insert/do-nothing.
   Reconcile recent rows explicitly; use a documented server-time merge stamp in
   v0.1 (the clock trigger will stamp now, so it cannot preserve an old maximum time).
   If preserving original view time is required, design a separate reviewed workflow
   before implementing merge. Do not UPDATE recent_views.exam_id: its trigger forbids it.
3. After successful canonical inserts, remove only the corresponding duplicate
   personal rows, then mark duplicate inactive and set merged_into_exam_id. Commit
   atomically; retain the duplicate exam and its provenance. No automatic hard delete.
4. Reconcile any content-resource movement explicitly with same-exam composite FKs
   and attachment collision review. Never assume a merge pointer reassigns children.

Reprocessing tests must cover immutable slug, post URL changes, semantic multi-exam
keys, missing IDs, verified-row protection, duplicate normalized URL quarantine,
provenance correction, parallel workers, merge conflicts/cycles and taxonomy
inactivity without lost PDFs. No ingestion code or DB execution is included here.
