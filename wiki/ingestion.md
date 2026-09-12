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
| Fetch outcome, normalized content hash, parser version, uncertainty | private source_posts metadata + file-based run report |
| Exam/session blocks and reviewed date/type/grade metadata | exams (possibly several per post) |
| Curated taxonomy releases | subjects, managed separately from arbitrary scrape labels |
| Subject occurrences, original labels and proposed mappings | exam_subjects |
| Attachment/link occurrences, purpose, raw label, scope and original href | resources |
| Optional personal profile/save/view action | profiles/bookmarks/recent_views via authenticated client later; never crawler |

Only trusted ingestion may write content; it can use a service-role context later.
Keys stay server-side. Public app reads never scrape source HTML. Do not borrow
another application's project, schema, OAuth configuration or credentials.

## Source identity and stable keys

1. For current numeric post URLs use source=`legendstudy`, external_post_id equal
   to the numeric path as text. Preserve the observed URL in raw_metadata; store a
   canonical `https://legendstudy.com/<id>` URL for identity after redirect verification.
   Canonicalization must not discard an unknown meaningful path/query. A Tistory
   alias only resolves to the same post after evidence, not host-name guessing.
2. Upsert source_posts by `(source, external_post_id)` when known; fallback to the
   unique canonical URL when absent. Resolve existing rows with either key first.
   If keys identify different rows, quarantine the conflict; do not overwrite one.
3. Give a single confirmed exam block a persisted `source_exam_key` (e.g. `main`).
   For multiple blocks allocate stable keys once and save the segmentation mapping
   in minimal raw_metadata. Never recompute keys from list position or normalized
   year/grade/title. A split/merge needs explicit reconciliation, not delete/reinsert.
4. Match a subject occurrence by an established stable source identifier, or persist
   an allocated `source_subject_key` alongside source-label/attachment evidence.
   Unmapped or identically normalized subjects still have distinct keys. Preserve
   keys through remapping and reorder; ambiguous renamed/split occurrences require
   review rather than guessing equivalence.
5. For a resource prefer a verified provider attachment/file ID. Otherwise allocate
   and persist a `source_resource_key` with minimal matching evidence. Exact repeated
   href + label within a confirmed scope can identify an existing occurrence; a
   hash of a mutable signed URL is not a durable identity. If a link changes and
   identity cannot be proven, hold for review instead of auto-creating duplicates.
6. Upsert on `(source_post_id, source_exam_key)`, `(exam_id, source_subject_key)`,
   and `(exam_id, source_post_id, source_resource_key)` respectively. UUIDs, slugs,
   user bookmark references and already-reviewed mappings survive reprocessing.

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
  version, confidence and rule version. A reviewer can mark verified; no automatic
  confidence threshold is defined in v0.1. Raw labels remain after confirmation.
- Historical 가형/나형 can later map to reviewed historical master entries; do not
  map them to present-day electives just to fill a foreign key. Taxonomy releases
  and their hierarchies need a separate review (including cycle checks).
- Public exam/subject/resource labels and notes contain only publishable material.
  Private run errors stay in source_posts or restricted reports. Do not collect
  comments, account information, cookies, bearer tokens or full HTML by default.
- A changed source label updates current evidence with a diagnostic note/report
  of the change; full revision/event history is deferred, not silently promised.

## URLs, checks and publication

Preserve every original `source_url` exactly as observed. A Box share link is a
landing-page resource; it is not a direct audio URL merely because its label says
MP3. `file_url` remains NULL until independently verified. No file-size/MIME guess
from rounded labels. No downloads/mirroring/Storage buckets are part of Day 3.

Before any future network fetcher, validate allowed hosts, redirects and resolved
IP ranges to prevent server-side URL abuse. DB URL CHECKs only validate shape.
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

Publish only the reviewed exam, subject mapping and resource hierarchy. A broken
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
