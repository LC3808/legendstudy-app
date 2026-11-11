# Four-university connection candidates — NOT DEPLOYED

[Canonical report](../../../../wiki/essay-four-university-connection-20261111.md) · [Question matrix](../../../../wiki/essay-four-university-question-review-20261111.md).

No remote writes, deployment, Provider calls or new publication. Existing Registry IDs, source contents, active seven Math leaves and approved student PDF metadata are preserved.

## Review artifacts

- `*-source-plan.json`: reviewed original file SHA/physical page/role maps for Konkuk24, Kyunghee7, Sungkyunkwan15. KAU12 uses `../kau-source-plan.json` unchanged.
- `question-review.json`: 81 existing questions, all20 required connection fields. `registry-metadata.json` contains only non-user production metadata from SELECT.
- Per-university `manifest.json`: private DRAFT package digests/leaf IDs/row counts. No official text/images committed.
- `web-source-registry-patch.json`: exact before/after source exam metadata; KAU uses additions. Apply to a reviewed copy only after checking prior equality. Reverse by checking candidate equality. Never replace the complete live registry with a stale file.
- `web-expansion-candidate.json`: complete18 exam candidate entries in total; Kyunghee2 medical exams remain in `blockedExams`. No live scope is opened.
- `leaf-contract-candidate.json`: all58 leaf IDs for isolated Flutter tests. **Not a public expansion allowlist.**
- `web-pdf-existing-reuse.json`: final PDF reference, existing43 approved/15 pending unchanged. `web-pdf-candidate.json` is only an unapproved local derivative comparison, NOT a replacement rollout.
- `existing-pdf-reuse-verification.json`:20 existing asset hashes and58 page bounds verified locally. Current remote Storage reads NOT TESTED.
- `sql-receipt.json`: exact private apply SQL hash/path. `preflight.sql`, `verify.sql`, `rollback-retire.sql` are metadata-only review scripts. Do not execute on production in this task.

## Private SQL locations (relative to APP checkout)

|University|Directory|DRAFT rows|Private Worker rows|
|---|---|---:|---:|
|KAU|`.local/natural-connection-20261111/kau`|172|12|
|Konkuk|`.local/four-university-20261111/konkuk`|275|24|
|Kyunghee|`.local/four-university-20261111/kyunghee`|85|7|
|Sungkyunkwan|`.local/four-university-20261111/sungkyunkwan`|228|15|

Each directory has `apply-draft.private.sql` (atomic combined apply), `register-draft.private.sql`, `worker-source.private.sql`, `preflight.sql`, `verify.sql`, `rollback-retire.sql`. Exact SQL is present locally, not just pseudocode. Official content remains private.

Candidate writes only existing `math_problem_sets`, `math_problems`, `math_subproblems`, `math_source_artifacts`, `math_evaluation_profiles`, `math_scoring_criteria`, `math_canonical_solutions`, `math_canonical_solution_steps`, `math_private.task20_hanyang_source_pages`. No new RPC/table/column, no grant changes, no activation/publication SQL.

After separate authorization: run preflight, compare receipts and existing state, apply the single combined transaction, run verification. Apply rejects mismatched Registry/leaf/content/helper/ACL/publication, inserts new DRAFT rows, and compares existing essay answers/results/credit hashes within the same transaction. Worker INSERT conflicts abort; do not rerun blindly. It does not make content available without separate release admission/metadata/Storage approval and account validation.

Rollback: remove only newly approved release scope first, then retire only the candidate's four versioned content tables. Keep source rows and all history; no DELETE/DROP/global RPC revocation. Exact rollback and its repeat execution were verified in disposable PG with existing results still readable.

## Offline reproduction

Run from APP root with Python PyMuPDF/psycopg installed. No production DSN is accepted by the harness.

```sh
PYTHONPATH=tool python3 -m unittest tool/test_natural_expansion.py tool/test_natural_connection.py tool/test_four_university_connection.py
NATURAL_EXPANSION_PACKAGES=.local/four-university-20261111/konkuk /tmp/legendstudy-task03-venv/bin/python tool/test_natural_expansion_contract.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
python3 tool/test_natural_connection_web.py --web-root /absolute/approved/web/checkout --candidate-root .local/four-university-20261111/konkuk
flutter test test/kau_connection_test.dart --dart-define=NATURAL_CANDIDATE=supabase/candidates/natural_expansion_20261111/four-university/leaf-contract-candidate.json
```

`tool/essay_lab/four_university_connection.py` builds private review packages from explicit source paths and an exact live metadata snapshot; its derivative PDFs are local audit artifacts. `tool/stage_natural_web_candidate.py` stages existing Source Registry + reviewed candidate in ignored `.local`, retaining catalog aliases (SKKU DB slug differs). `tool/essay_lab/natural_candidate_sql.py` builds exact review SQL without any DB connector.

New source materials/changed source hashes require a fresh review, not silent regeneration. Do not use the superseded KAU quality experiment or Provider script. Provider0 is a hard boundary for this task.
