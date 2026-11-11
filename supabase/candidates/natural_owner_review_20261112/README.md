# Shared Owner review access — LOCAL CANDIDATE ONLY

NOT DEPLOYED / NOT REVIEW READY / NOT APPROVED FOR EXECUTION.

This supersedes the KAU-only7-leaf prototype for future design; neither prototype is installed. `tool/prepare_natural_review_scope.py` derives the exact186 TECH_READY leaves from234 reviewed Registry questions across10 universities. HOLD6, partial7, NOT_READY22 and existing13 are excluded. Central science11 is outside this expansion and remains HOLD. PDF-pending97 leaves remain disabled, as does every other leaf.

`tool/prepare_natural_review_access.py` creates private control/scope tables2, a helper1 and exact guarded amendments to4 existing admission functions. There is no evaluator, Provider, Credit, activation or publication change. The same owner/expiry check applies across universities. Global enabled=false AND every approved_for_review=false initially; both are required with existing account lifecycle permission. Scope is exact Registry+leaf identity, never email supplied by a client. Owner subject is in ignored private SQL only.

- Install: ignored `.local/natural-owner-review-20261112/install-closed.private.sql`; receipt SHA binds exact candidate.
- Scope/hash: `../natural_tech_ready_20261112/integrated-review-scope.json` and `receipt.json`.
- Diff: `function-diff.json`; guard checks all4 original definitions and186 DRAFT leaves, then exact Registry binding. Entire install transaction rolls back on mismatch.
- Close: `close.sql` disables new admission/claims without deleting answers or sources.
- Restore: `restore-functions.sql` checks candidate function hashes and all186 leaves back in DRAFT before restoring original definitions. Disabled private control/scope history is retained. This is not permission to change production content states.

`tool/test_natural_review_access.py` reuses the established KAU boundary fixture in disposable PG17 and loads186 exact packages. **602 named checks PASS**: closed defaults, every leaf owner/other isolation, exact catalog, per-leaf revocation, global flag cannot bypass leaf approval, HOLD/NOT_READY/partial exclusion, expiry, deletion pending/ERASING, queued claim refusal after close, admitted lease completion, existing idempotent replay, result/ACL preservation, guarded restore. Mock data only; Provider0/production writes0.

Initial rehearsal failed while seeding the local fixture because JSON table order put solution steps before their referenced solutions. Fixture now uses the existing canonical8-table order; final602 checks pass. Candidate install SQL and production were not executed by that failure.

Still required before execution approval: latest per-object RLS/ACL/default-privilege snapshots, approved bounded DRAFT loading, PDF approvals and per-leaf enable manifest, operational rollback rehearsal with final deployment contract. Concurrent claim/revoke race and successful image extraction are NOT TESTED. Existing admitted leases may finish after revocation; close is not a cancellation of work already admitted.

WEB/APP actual Owner entry, server allowlist exception and session wrapper E2E remain NOT TESTED/NOT IMPLEMENTED for this scope. The old read-only owner-results preview is not an input path. Do not open public allowlists as a workaround. All186 database sources are not yet installed: final read-only check found7 existing KAU bindings and179 unbound, publication0. Do not run this candidate now.
