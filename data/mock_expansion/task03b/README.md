# TASK03-B reviewed local corpus — NOT DEPLOYED

Baseline: `1556b0f`. Existing TASK03-A files and all 412 paper objects are unchanged.
Read [review and remaining work](../../../wiki/task03b-ready-candidate-20261111.md)
and [approval-only SQL instructions](../../../supabase/candidates/task03b_ready_20261111/README.md).

- `verified_papers.json`: 443 paper variants / 11,170 questions / 396 READY Registry subjects.
- `verification_report.json`: all 417 IDs, 396 READY / 12 PARTIAL umbrella rows / 9 NOT_READY foreign/Hanmun.
- `2025_image_papers.json`: 31 reviewed image-table forms for 24 new subjects. Odd/common answers
  independently match 24 LegendStudy native-text explanation PDFs; even forms use the official even table.
- `image_cell_audit.json`: source/page/member hashes, source pixel boxes at 3× rendering, glyph scores,
  92 visually resolved number OCR exceptions and all 21 distinct odd/even changed answer cells.
- `alias_mapping.json`: 12 verified 1:N elective umbrellas, **not** identical subjects to merge.
- `foreign_mapping_review.json`: nine official name/answer matches; internal recognition key is not
  an official numeric code or a canonical `subjects` row. NOT_READY; no guessed mapping is seeded.
- `raw_percentile_review.json`: 114 source tables, 1,280 reviewed cells: 816 raw + 304 percentile
  numeric cells, 160 source dashes retained as null. 387 discrepant/blank cells visually reviewed.
  Five original numeric OCR errors corrected in this new artifact only; original OCR remains untouched.
  Source transcription is not official raw-to-grade conversion. No numeric value is inferred.
- `load_data.json`: exact draft key/question/reference inputs; `grade_cutoff_versions=[]` deliberately.
- `load_evidence.json`: each key/reference links to provenance; 114 `<` grade-9 facts and three official
  unassigned grade-8 facts are retained but excluded from the scalar reference table.
- `production_preflight.json`: read-only observed counts, function/ACL fingerprints, unchanged 417-ID mapping.
- `production_schema_contract.json`: relevant public schema/function/ACL contract, no customer rows/secrets.
  Includes existing account eligibility/lock dependencies **for isolated testing only**; rollout does not modify them.
- `preservation_manifest.json`: immutable baseline file hashes.
- `test_results.json`: executed checks and log hashes; runtime/production limits are explicit.
- `sql_manifest.json`: generated approval candidate hashes and counts.

## Rebuild and validate (offline, repository root)

```sh
python3 tool/build_task03b_candidate.py
python3 tool/build_task03b_sql.py
python3 -m unittest discover -s tool -p 'test_task03b_candidate.py'
python3 tool/test_task03b_sql.py
flutter test test/task03b_official_scoring_test.dart
```

Builder inputs are **reviewed frozen artifacts**, not live OCR. The SQL integration test creates
and deletes a temporary PG17 cluster, TCP disabled, synthetic users only, no DSN argument.
The exact official Registry IDs are local fixtures; they do not grant production access.

## Source extraction/review reproduction (not automatic approval)

Use the existing TASK03-A public source cache/reproduction first. Dependencies: PyMuPDF,
Pillow, NumPy, BeautifulSoup; Apple Vision requires macOS. Run from repository root:

```sh
python3 tool/task03b_fetch_sources.py
python3 tool/task03b_image_cells.py
swift tool/task03b_local_vision.swift .local/task03b/cells
python3 tool/task03b_image_transcribe.py
python3 tool/task03b_legendstudy_compare.py
python3 tool/task03b_cutoff_cells.py
swift tool/task03b_local_vision.swift .local/task03b/cutoffs
python3 tool/task03b_cutoff_compare.py
```

The fetcher reuses `.local/task03a/official/extracted.json` image failures and current LegendStudy1649
attachments. Check every PDF/ZIP/member SHA against the committed review before using extraction.
Changed sources, unresolved numeric/glyph cells, ambiguous mapping and source corrections require
new review; scripts do not replace the frozen approved transcription or promote production READY.
Image/PDF caches and generated review contact sheets are not committed. TLS verification remains enabled.

Verified data are not bundled as Flutter assets. App behavior changes only after separately approved
server key publication and a compatible app release/internal installation. No store submission here.
