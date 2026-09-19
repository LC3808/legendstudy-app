# 2024 reconciliation — revalidated 2026-09-20

Starting HEAD: `6474b4e`, branch `codex/day-7-school-neis`. Initial tracked tree
clean; existing Claude outputs/, supabase/.temp/ and two Python cache directories
preserved. Earlier interrupted output was not used as evidence.

## Resource drift: VERIFIED / LEGITIMATE RESOURCE EXPANSION

Baseline artifact `dryrun-2026-09-15/dryrun-summary.json` was created by
`77e2b13`. Its parser and sample were replayed from Git into a temporary isolated
folder. Current parser and sample were separately replayed; no network was used.

| Parser | Sample | Resources |
|---|---|---:|
| 77e2b13 | 77e2b13 | 1,205 |
| 77e2b13 | current | 1,205 |
| current | 77e2b13 | 1,205 |
| current | current | 1,228 |

`bf89548` added 23 explicit `bx` share-ID/label entries to the fixture,
`parse_record` support for them, and normalization of the Korean Box action
suffix. All 1,205 old resource projections are unchanged. Exactly 23 new
resources are labeled listening audio, have unique Box keys AND unique Box
locators, and are source-label-classified landing pages. No removed resources,
query/signature variants, same-content URL collisions or duplicate compound
keys. This is both fixture enrichment and intentional parser recognition, not
nondeterminism. Binary/media identity and live availability remain unverified;
23 distinct share IDs are not proof of 23 downloadable MP3 payloads.

`2024-resource-drift.csv` contains the exact 23 additions (its requested name
covers the investigation; **none belongs to 2024**).

| Scope | Before | Current | Delta |
|---|---:|---:|---:|
| 2024 | 489 | 489 | 0 |
| 2025 | 492 | 507 | 15 |
| 2026 | 224 | 232 | 8 |
| Grade 1, all years | 120 | 126 | 6 |
| Grade 2, all years | 299 | 305 | 6 |
| Grade 3, all years | 786 | 797 | 11 |

Before resource types: question 601, answer_explanation 594, listening_script 10.
Current: same plus listening_audio 23; other/standalone answer/explanation 0.
Current totals **38 exams / 609 occurrences / 1,228 resources**.
Source sample SHA-256: `2fe68c345c714524f354e63b6a4c3406afe7a41f2496809a09ec630ce8ccc371`.

## Exact 2024 candidates

**15 exams / 246 occurrences / 489 resources**, directly filtered by actual
calendar year, not 38 minus 23. Grades 1/2/3: 4/4/7. Families: national_mock 12,
evaluation_mock 2, csat 1. Grade 1/2 months: 3,6,9,10; grade 3 months:
3,5,6,7,9,10,11. Per-post facts: `2024-candidate-reconciliation.csv`.

Schema rechecked in `20260912000100_initial_content_schema.sql`:
source (source,external_post_id); content (source_post_id,source_content_key);
exam shared content PK; occurrence (content_item_id,source_subject_key);
resource (content_item_id,source_post_id,source_resource_key). Source URL and
content slug also have UNIQUE collision guards. Resource URL is not its identity.
`2024-candidate-keys.csv` expands parent natural identities rather than assuming
candidate uuid5 IDs equal existing Production IDs. Full 38-candidate local
natural-key, slug, source-URL, same-content resource-URL and merge checks pass.

## Production evidence limits

Owner-confirmed exam-scope totals remain 23/363/739: 2025 15/246/507,
2026 8/117/232; 2020–2024 zero. Future/unpublished 2026 combinations are not
MISSING. No row-level Production key extract was found in the tracked historical
reports; no credentials were requested and no live DB connection was attempted.

| Scope | MATCH | CANDIDATE_ONLY | PRODUCTION_ONLY | CONFLICT |
|---|---|---|---|---|
| 2024 exam-year coverage only | 0 | 15 local candidates vs zero Owner exams | 0 | exact keys unknown |
| Exact Production natural keys, all tables | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED |

Zero 2024 exams does NOT rule out source posts, partial content or the same key
under a different year. Equal 2025/2026 counts do NOT establish MATCH.

## Validation

Existing ingestion suite: **146 PASS**, plus **4 new historical regression tests PASS**
(**150 total PASS**). Additional offline
assertions: 4-way historical replay, unchanged 1,205 resource projections,
23 distinct new keys/URLs, no parse errors or merge candidates, all compound
keys unique, full resolved semantic projection identical under 2026/2030 crawl
times after removing only source.last_crawled_at, raw labels retained, inactive
rows, no query-bearing resource locators. CSV read-back counts checked.

Inventory/reconciliation/dry-run: COMPLETE within explicit evidence limits.
Production exact-key reconciliation and publication: NOT COMPLETE / NOT READY.
