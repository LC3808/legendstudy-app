# Historical Exam Expansion — Phase 1-A Inventory

Status: **PARTIAL / Production read-only query blocked**

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

## Production status

The exact Production REST endpoint was reachable but returned
`401 UNAUTHORIZED_MISSING_API_KEY`. No publishable key, database password or
service-role credential is present in the repository/environment. Therefore
the Production counts for `exams`, `exam_subjects` and `resources` are
**UNVERIFIED**, and the missing matrix intentionally uses
`REVIEW_REQUIRED` rather than `MISSING`.

Owner must run the read-only SQL in the handoff with a Production credential
and return its result before this inventory can become ingestion-ready.

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
