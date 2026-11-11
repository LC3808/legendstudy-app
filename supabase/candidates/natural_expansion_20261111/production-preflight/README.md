# Stage 1: 53 DRAFT connections — NOT APPLIED

[Canonical report](../../../../wiki/essay-four-university-production-preflight-20261112.md) · [81-row Registry scope](../../../../wiki/essay-four-university-application-scope-20261112.md).

Base commit `536a2fc22c5fa763d31fa59fe239460cef93d794`. Proposal, not Owner authorization.
53 questions /18 exams: KAU7, Konkuk24, Kyunghee7 (partial4), SKKU15 (PDF pending15).
Preserve existing7, exclude HOLD5 and NOT READY16; Central science11 remains outside this scope.

## Exact files

- `scope.json`: UUID decisions, PDF state, leaf identities, table counts, seven expected function hashes.
- `production-registry.json`, `production-acl.json`, `production-functions.json`: SELECT-only metadata/function evidence. Function definitions are **fixtures for local rehearsal, never migration SQL**.
- `production-preflight-result.json`:116 live SELECT checks PASS at2026-11-12 00:05:50 KST and point-in-time preservation hashes. No raw student answers/identities.
- `preflight.sql`:read-only conditions and preservation snapshot. Any non-true condition forbids application.
- `verify.sql`:read-only post-application checks, DRAFT687+Worker53, identities/digests/permissions/public scope.
- `rollback-retire.sql`:exact non-destructive Stage1 rollback, only212 new DRAFT version rows→RETIRED. Sources and histories retained. Rejects later ACTIVE state; not a Stage2/3 emergency script.
- `verify-retired.sql`:read-only retirement verification.
- `isolated-results.json`:238 named local checks, production writes0/Provider0.
- `sql-receipt.json`:exact apply SHA, sizes, package/source hashes and supporting SQL hashes.
- Private apply: `/Users/woojinchang/.codex/worktrees/app-ga4-usage-20261105/legendstudy-service-app-20261022/.local/natural-production-preflight-20261112/apply-draft.private.sql`
- SHA256: `6d5aaba16a0bdf1707935cf9f9976421055646a9b07051d0c7ac7a5d7e7fc708`
- Size: 17,767,282 bytes. Official text/images embedded; keep ignored, do not paste into public issue/wiki.

## Owner execution AFTER separate Stage1 approval

1. Confirm exact53 scope and pending/partial distinctions; preserve this receipt and current checkout.
2. Verify all file SHA256 values. Re-run `preflight.sql` against LegendStudy Production only; inspect every116 boolean as true. Any changed identity/connection/ACL/function/public state requires re-review, not an override.
3. Execute **only** the private combined apply SQL in a client configured to stop on errors, e.g. `psql -X -v ON_ERROR_STOP=1 -f <private-apply-path>` with the already verified LegendStudy production connection supplied securely. No DSN/secret is stored here. Do not separately execute old university register/Worker files or all58 candidates.
4. The single Repeatable Read transaction rejects nonempty targets, preserves all existing content/Registry and essay/math/credit history, checks function/ACL/RLS invariance, and commits only the exact53 DRAFT additions. The reference snapshot is captured inside the transaction; legitimate concurrent user writes do not change its visibility. Lock timeout5s; registration statement timeout60s. On uncertainty after connection loss, read verification before retry; duplicate apply deliberately rejects.
5. Run `verify.sql`; all boolean checks true. Compare old content/security fingerprints. User history counts may grow legitimately outside this transaction—do not overwrite/reset records to match the earlier SELECT snapshot.
6. Record actual KST time, operator, receipt, transaction result and postchecks. No Migration history was written during preparation; after approval use the established migration/evidence workflow rather than assuming the candidate is deployed.
7. Any Stage1 malfunction: run exact `rollback-retire.sql`, then `verify-retired.sql`. Keep all source/history rows. Repeated rollback is safe. RETIRED records make fresh apply fail; no deletion/re-registration to bypass this.

## Stage2 is a separate GAP

DRAFT denies both Owner and other users. Current ACTIVE admission has no leaf-specific Owner gate: local tests reproduce submission by another authenticated subject even without adding the leaf to release catalog. WEB allowlists alone do not cover direct RPC. **Do not activate these rows as an Owner-only test shortcut.** A separately approved DB-level subject/leaf check and isolated WEB/APP review path must be verified first. Provider/Credit/publication unchanged here.

## Offline reproduction

From APP checkout, with existing private packages and PyMuPDF/psycopg installed:

```sh
/tmp/legendstudy-task03-venv/bin/python tool/prepare_natural_preflight.py
/tmp/legendstudy-task03-venv/bin/python tool/test_natural_preflight.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
PYTHONPATH=tool /tmp/legendstudy-task03-venv/bin/python -m unittest tool/test_natural_expansion.py tool/test_natural_connection.py tool/test_four_university_connection.py
python3 tool/check_wiki_handoff.py
```

No database connector in the builder. The test starts a disposable Unix-socket-only PG17 instance with synthetic accounts and copies read-only production function definitions into that instance; it accepts no remote DSN. The temporary ACTIVE probe demonstrates the Stage2 gap locally and is never emitted as rollout SQL. Existing Worker references are resolved without Provider calls. Old7 test payloads are synthetic, not production answer material.
