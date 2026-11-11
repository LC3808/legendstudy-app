# Owner review admission prototype — LOCAL ONLY / NOT APPROVED

The Owner-designated account was checked read-only (exists, verified, active lifecycle, profile present). Its subject is held only in ignored `.local/kau-owner-review-20261112/owner.private.json`; committed receipt contains a digest. No password/session was collected.

`prepare_kau_review.py` generates an exact seven-leaf, **disabled** admission prototype. One private control table/helper and four function patches (`resolve_profile`, `release_catalog`, evaluation/extraction claim) preserve existing owners/ACLs and engine/billing/finalizers. `function-diff.json` is the review diff; `production-runtime-functions.json` is read-only evidence, not an executable migration. No activation or publication script is provided. Production remains the separately approved 106-row DRAFT state.

**2026-11-12 revised Owner policy:** this is a seven-leaf proof of the authorization boundary, not the finished cross-university review facility. Do not install it as a per-university rollout. Reusable review scopes and a server-verified WEB/APP preview path must be prepared for integrated review after TECH READY work. The current public WEB allowlists still exclude these leaves. This prototype must not delay the next university.

## Isolated verification

`tool/test_kau_review.py --pg-bin /opt/homebrew/opt/postgresql@17/bin` uses disposable Unix-only PostgreSQL17, synthetic subjects/history, copied production admission definitions, and the existing local persistence/finalizer fixture. It cannot accept a remote DSN. `isolated-results.json`: 53 named checks PASS; Provider/production writes0; WEB/APP real-account E2E NOT TESTED.

Checks cover closed default, seven-owner-only submissions, ordinary/anonymous denial, expiry, pending deletion, queued evaluation/extraction claim denial after closure, original RPC ACLs, original content/credit preservation, existing result ownership, idempotent replay, exact restore and result retention. No model-quality conclusion. Successful image extraction, deletion ERASING race, simultaneous close/claim, full production session/WEB/APP integration are not covered here.

`close.sql` disables only this prototype's admission; no global RPC revocation or history deletion. Claims admitted before closure may still complete with their existing lease. Closure is not Provider cancellation. `restore-functions.sql` refuses restoration unless all seven parent/problem versions are DRAFT and patched function hashes match; it restores four original definitions and keeps the private control disabled. Synthetic result bytes remain unchanged, while availability projections can change when content becomes DRAFT.

Before any future approval: replace seven-specific admission with reviewed reusable scope handling, verify full current function/ACL/lifecycle/Registry/content snapshots, review races and claimed-job policy, verify real preview routes, and prepare exact bounded enable/expiry/close/rollback SQL. Current prototype is **not execution-ready production approval material**.
