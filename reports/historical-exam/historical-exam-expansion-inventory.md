# Historical Exam Expansion — Phase 1-A Inventory

Status: **PRODUCTION COVERAGE VERIFIED / Phase 1-A1 inventory and dry-run COMPLETE**

2026-09-20 update: the candidate table below describes the original dated
1,205-resource snapshot. Revalidated current sample is 38/609/1,228 after 23
Box additions in 2025/2026. See [2024 reconciliation](2024-reconciliation.md).
2024 is directly verified as 15/246/489 locally; Production exact-key evidence
remains UNVERIFIED and publication is NOT READY. No Production mutation.

## Scope and year semantics

This report covers 2020 through the current year only. The applied schema
defines `exams.year` as the actual calendar year, `academic_year` as the
source-labelled school/CSAT year, `exam_date` as the actual date and
`exam_month` as the nominal session month. Raw labels remain in
`raw_grade_label`, `raw_exam_type` and `exam_subjects.raw_subject_label`.

## Repository candidate inventory

The committed offline dry-run at
`tool/ingestion/samples/dryrun-2026-09-15/` contains 38 parsed exam posts:

| calendar year | exams | grade 1 / 2 / 3 | resources | months | exam families |
|---|---:|---:|---:|---|---|
| 2024 | 15 | 4 / 4 / 7 | 489 | 3, 5, 6, 7, 9, 10, 11 | national_mock, evaluation_mock, csat |
| 2025 | 15 | 4 / 4 / 7 | 492 | 3, 5, 6, 7, 9, 10, 11 | national_mock, evaluation_mock, csat |
| 2026 | 8 | 2 / 2 / 4 | 224 | 3, 5, 6, 7, 10 | national_mock, evaluation_mock |

The candidate total is 609 exam-subject occurrences and 1,205 resources:
601 `question`, 594 `answer_explanation` and 10 `listening_script`. All
resources use Kakao CDN locators and remain unverified source links. The dry
run has 35 high-confidence and 3 medium-confidence posts; all 38 have
advisory expiring-URL quarantine records, and 3 have subject ambiguity.

No committed candidate source was found for 2020–2023. This is a source
inventory gap, not a Production missing assertion.

## Production status — Owner SELECT postflight

Owner-confirmed Production coverage is:

| year | exams | exam_subjects | resources | interpretation |
|---|---:|---:|---:|---|
| 2020 | 0 | 0 | 0 | confirmed absent; discovery required |
| 2021 | 0 | 0 | 0 | confirmed absent; discovery required |
| 2022 | 0 | 0 | 0 | confirmed absent; discovery required |
| 2023 | 0 | 0 | 0 | confirmed absent; discovery required |
| 2024 | 0 | 0 | 0 | confirmed absent; reconcile candidate first |
| 2025 | 15 | 246 | 507 | existing Production coverage |
| 2026 | 8 | 117 | 232 | current-year partial coverage; future rows not missing |
| total | 23 | 363 | 739 | canonical Production total |

2025 structure is 고1/고2 March, June, September, October national mocks;
고3 March, May, July, October national mocks, June/September evaluation
mocks and November CSAT. 2026 currently contains 고1/고2 March and June, and
고3 March, May, June and July. Future/unpublished 2026 exams are not classified
as missing.

Production quarantine contains 23 open `resource_url_expiring` rows mapped to
2020–current exams. The 23 quarantine rows are not assumed to be a 1:1 match
with the 23 exams.

The 2024 candidate is now directly recounted as 15 local exams. The Owner
exam-scope zero remains valid, but source/partial-content absence and exact
Production-key action counts remain UNVERIFIED until row-level keys are compared.

## Pipeline and safety audit

The repository implements offline `DISCOVER → NORMALIZE → MAP → QUARANTINE →
VALIDATE` planning. The `--apply` path is a separate, bounded Pilot C write
path and was not run. `ingestion_quarantine` exists in the schema and stores
ambiguity/evidence; no Phase 1-A table or migration was added.

Canonical identity contracts are `(source, external_post_id)` for
`source_posts`, `(source_post_id, source_content_key)` for content items,
`content_item_id` for exams, `(content_item_id, source_subject_key)` for
occurrences and `(content_item_id, source_post_id, source_resource_key)` for
resources. URL is provenance/location, not the primary identity.

Search uses bounded pages of 24, a maximum offset of 10,000, and year/month/
grade/exam-type/subject/resource filters. It has no dedicated year facet
pagination beyond the bounded facet request and should be benchmarked before
large historical publication. Home uses source `feed_updated_at` derived from
`published_at`/`source_updated_at`, not ingestion time; bulk historical
publication must not rewrite that clock. Recent views are user-action based
and independent of ingestion.

## Phase 1 execution order

1. **1-A:** reconcile existing 2024 candidate, Batch A 고3 then Batch B 고1/고2.
2. **1-B:** discover and ingest 2023.
3. **1-C:** discover and ingest 2022.
4. **1-D:** discover and ingest 2021.
5. **1-E:** discover and ingest 2020.
6. **1-F:** reconcile 2025/2026 candidate against Production.

Every batch is gated by deterministic-key reconciliation, duplicate protection,
quarantine review, the 23 `resource_url_expiring` analysis, URL durability,
raw-label preservation, historical taxonomy review, source-time
`feed_updated_at`, batch validation and post-publication search acceptance.
