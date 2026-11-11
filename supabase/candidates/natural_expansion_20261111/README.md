# Natural expansion 2026-11-11 — OFFLINE / NOT FOR PRODUCTION APPLY

**Latest Owner scope and delivered follow-up: [connection/README.md](connection/README.md).**
The material below records the original v1 preparation. Normalization/Provider quality is no longer a completion gate. The v1 locator was incompatible with the existing Worker; use the hash-preserving connection follow-up, not the old SQL.

[Canonical report](../../../wiki/essay-natural-expansion-20261111.md).
The original offline preparation and connection-only follow-up make no new schema/RPC, production writes, Storage uploads or Provider calls. The interrupted earlier quality experiment is recorded separately in the Wiki.
Existing IDs only. Central69 completed math packages and science11 HOLD unchanged.

## Files

- `registry-readonly.sql`: exact metadata SELECT used for live inventory. No user data.
- `input-provenance.json`: base commits/source hashes, including Owner's Nov7 audit references.
- `registry-reconciliation.json`: source93→existing90 exact matches;3 unresolved, no UUID creation.
- `owner-audit-reconciliation.json`: Nov7 exam table390 rows→current counts; no registered-count drift.
- `natural-gap-inventory.json`, `review-metadata.json`: explicit natural/science track IDs and direct Math bindings, review approval metadata. Direct FK absence alone does not prove no legacy/Essay service.
- `university-candidates.json`: existing Catalog10 service expansion candidates. No new university rows, no activation.
- `release-catalog-metadata.json`: current Math Backend catalog counts; Inha medical9/27 ACTIVE but not in release scope. No automatic publication.
- `central-live-verification.json`: existing20 exams/69 ACTIVE math bindings/11 Q4 HOLD.
- `kau-source-plan.json`:6 existing exams/12 questions, original SHA, physical page/crop mapping.
- `kau-draft-manifest.json`:12 private DRAFT/172 rows,6 problem-only PDFs/25 pages,12 worker inputs. Formula text has PUA; not publication-ready.
- `isolated-contract-report.json`, `verification.json`: actual local results; synthetic evaluation is not Provider quality.

Private body/PNG/base64/PDF/SQL remain ignored under `.local/natural-expansion-20261111/kau-verified/`.
No deployable activation SQL. `register-draft.private.sql` is a review artifact using the existing TASK20 renderer. Do not apply it to production without the corrected connection metadata, fresh preflight and separate Owner authorization.

## Reproduce offline

Use Python with PyMuPDF for prepare, psycopg and PG17 for opt-in DB rehearsal. Inputs contain only approved local original paths; do not add paths/secrets to Git. The compiler never contacts a network or DB.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tool -p test_natural_expansion.py -v

PYTHONPATH=tool python3 tool/essay_lab/natural_expansion.py \
  --registry .local/natural-expansion-20261111/registry-snapshot.private.json \
  --source-registry /absolute/path/to/web/src/data/essay-source-registry.json \
  --output /tmp/registry-reconciliation.json

PYTHONPATH=tool python3 tool/essay_lab/natural_expansion.py \
  --registry .local/natural-expansion-20261111/registry-snapshot.private.json \
  --plan supabase/candidates/natural_expansion_20261111/kau-source-plan.json \
  --source-paths /private/path/to/source-paths.json \
  --output .local/natural-expansion-review-new

NATURAL_EXPANSION_PACKAGES=.local/natural-expansion-review-new \
  python3 tool/test_natural_expansion_contract.py \
  --pg-bin /opt/homebrew/opt/postgresql@17/bin
```

`source-paths.json` maps each source SHA256 to its absolute local PDF path. Output must be a **new** ignored `.local` directory; partial/stale output cannot overwrite a prior successful manifest. Validate hashes, all crops and live identity before generating. Re-render all problem PDF pages and inspect equations/figures/leak boundaries.

The PG runner starts a disposable server with `listen_addresses=''` under `/private/tmp`, installs existing migrations and synthetic fixtures, then stops/removes it. It accepts no production DSN. It temporarily activates fixture content solely to exercise existing submission/result RPCs. It never creates an activation artifact or sends a Provider request.

Before any future production use, repeat the live SELECT and compare with current source/current catalog, not this historical snapshot. Preserve existing content versions and user histories; refuse duplicate/changed rows. Publication is a separate Owner-controlled action.
