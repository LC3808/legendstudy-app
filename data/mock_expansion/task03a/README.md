# TASK03-A local review candidates — NOT DEPLOYED

Canonical status: [Wiki](../../../wiki/task03a-official-ready-20261111.md).

- `verified_papers.json`: compact paper-level evidence; per-question overrides win.
  IDs are stable internal UUID5 identifiers, not KICE-issued IDs. Never put answers in Flutter assets.
- `verification_report.json`: all417 original Registry occurrences, including unresolved aliases/code-null rows.
- `source_manifest.json`: pinned public source hashes/URLs; LegendStudy inventory remains in task03.
- `cutoff_review.json`: standard-score-only audit, not a raw-score cutoff seed.
- Historical task03 snapshots remain unchanged. Current review is in task03a.

Reproduce with Python3 + PyMuPDF/pdfplumber (tested in local task03 venv):

```sh
python3 tool/fetch_task03a_sources.py
python3 tool/extract_task03a_official_answers.py
python3 tool/review_task03a_cutoffs.py
python3 tool/build_task03a_verified_packages.py
python3 tool/test_task03a_packages.py
python3 tool/test_task03_scoring_package.py
python3 tool/test_task03_scoring_v2.py
flutter test test/task03a_official_scoring_test.dart test/task03_mixed_scoring_test.dart
```

The fetch step uses only pinned public official URLs and normal TLS verification.
Changed source bytes require re-review, never silent replacement. Original PDFs/ZIPs/XLSX/HTML
remain in ignored `.local/task03a/official/`; no credentials or student data are involved.
The PostgreSQL test creates its own temporary PG17 cluster with TCP disabled and no DSN;
it never connects to Supabase. It may need permission to launch local processes on macOS.

READY is a **local verification candidate**, not permission to publish. Production mutations,
app installation and store submission are outside this task. Partial/unknown source data stay gated.
