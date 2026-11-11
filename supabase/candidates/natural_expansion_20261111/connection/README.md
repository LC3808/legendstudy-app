# Connection-only candidates — NOT APPLIED

Canonical status: [Wiki](../../../../wiki/essay-natural-expansion-20261111.md).
Version `kau-connection-20261111-v1`; public approval is false for every package.
No production/remote TEST write, Storage upload, new engine, Provider call or deployment.
The earlier quality experiment is stopped/archival; it is not an input to this version.

## Review artifacts

- [kau-readiness.json](kau-readiness.json): twelve exact existing question IDs, source/criteria/input/request/result/rewrite status, Owner issues and runtime boundary.
- [official-source-issues.json](official-source-issues.json): five parent questions with known source observations. No official correction, inferred point changes or automatic exam HOLD.
- [manifest.json](manifest.json): 12 DRAFT packages/172 rows, internal leaf IDs, immutable input hashes and six unchanged student PDFs/25 pages.
- [web-expansion-candidate.json](web-expansion-candidate.json), [web-pdf-candidate.json](web-pdf-candidate.json), [web-input-candidate.json](web-input-candidate.json): existing WEB/APP metadata contracts. They do not enable release scopes/Storage. PDF remains `OWNER_APPROVAL_REQUIRED`/`NOT_APPLIED`.
- [worker-contract-report.json](worker-contract-report.json), [contract-report.json](contract-report.json), [verification.json](verification.json): actual local evidence; Mock results are not AI-quality findings.
- [ten-university-registry.json](ten-university-registry.json): read-only existing ID/key metadata, no user data or official content. `kyungpook`/`pusan` DB slugs correspond to source `knu`/`pnu`.
- [ten-university-readiness.json](ten-university-readiness.json): 28/94 shared connector matches, no new ten-university runtime package, existing HOLD retained.

Private original text/images/PDF/SQL stay at ignored `.local/natural-connection-20261111/kau/`.
`register-draft.private.sql` uses the existing eight-table INSERT renderer with immutable/duplicate guards.
`worker-source.private.sql` INSERTs into the **existing** private source table and rejects duplicate rows.
It is deliberately not an overwrite/upsert; do not blindly replay it. No activation/RPC patch is provided.

The source locator now exactly matches the existing read-only Worker helper (`filename PDF 1,2쪽`).
Original v1 text/rubric/solution/points/PDF/image bytes are retained; only internal candidate IDs and locators change.
The older general preparer also uses the corrected format and a fresh namespace for future builds.
The twelve delivered candidates instead reuse the pinned old private files, avoiding PDF re-authoring.

## Reproduce the delivered candidates

Run from APP checkout, with the ignored v1 originals available. Always use a fresh output folder.

```sh
PYTHONPATH=tool python3 -m essay_lab.natural_connection \
  --plan supabase/candidates/natural_expansion_20261111/kau-source-plan.json \
  --registry .local/natural-expansion-20261111/registry-snapshot.private.json \
  --previous .local/natural-expansion-20261111/kau-verified \
  --pinned supabase/candidates/natural_expansion_20261111/kau-draft-manifest.json \
  --output .local/natural-connection-review-new

PYTHONPATH=tool python3 -m unittest tool/test_natural_connection.py tool/test_natural_expansion.py

NATURAL_EXPANSION_PACKAGES=.local/natural-connection-review-new \
  python3 tool/test_natural_expansion_contract.py --pg-bin /opt/homebrew/opt/postgresql@17/bin

python3 tool/test_natural_connection_web.py \
  --web-root /absolute/path/to/reference-web-checkout \
  --candidate-root supabase/candidates/natural_expansion_20261111/connection

flutter test --no-pub test/kau_connection_test.dart test/math_exam_session_test.dart \
  test/math_history_navigation_test.dart test/approved_essay_result_test.dart
flutter test --no-pub test/math_scaffolding_widgets_test.dart \
  test/math_coaching_history_sources_test.dart test/math_coaching_history_refresh_test.dart
flutter analyze --no-pub
python3 tool/check_wiki_handoff.py
```

Use the repository Flutter SDK (validated with3.47.6), psycopg3 and local PostgreSQL17.
The PG harness accepts no production DSN. It temporarily activates only disposable fixture packages,
uses synthetic accounts/results and destroys the temporary server. Worker fixture SQL is the exact
SELECT-exported production definition (MD5 `54acd2a1914f360e6ecd62e39acc8222`), **for local tests only**.
WEB runner creates an ignored test under the explicitly supplied checkout; transports are mocked.
The additional existing WEB regression commands run `exam-bridge.test.ts` and `exam-rewrite.test.tsx`.

## Approval boundary

First decide the exact public question subset and source-issue handling. Parent Q1/Q2 are the current
Registry granularity; isolated subquestion publishing requires a separate mapping decision.
Before any later change, re-read current DB identities/bindings/function hashes and preserve all existing
answers/results/credits. Register only the approved subset, verify private sources, upload only the
student derivative, then enable existing runtime/Storage/WEB scope under separate approval.
Disable only the newly enabled scope on failure; retain every source and student history.
Central science11 and existing Yonsei/Hongik/UOS holds remain untouched.
