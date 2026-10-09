# Canonical component persistence candidate — 2026-10-09

LOCAL_VERIFIED / NOT_APPLIED. This directory is deliberately outside migrations;
no migration number reserved, no schema_migrations record, no db push authorization.

`install.sql` adds one immutable child of existing essay_evaluations and three RPCs:
- essay_claim_components: canonical essay_claim + DB-computed frozen input hash.
- essay_finalize_components: validate bounded manifest/results, then call unchanged
  essay_finalize_success and insert component result in ONE transaction.
- essay_component_result: existing owner/session and account-active boundary,
  completed/non-invalidated result only. Null means legacy result without extension.

No new attempt, identity, wallet, charge policy, history store or worker role.
The existing parent evaluation is the history identity and sole billing decision.
A child insertion failure rolls back canonical finalization and Credit consumption.
Existing finalizer/claim hashes are pinned to the last Owner inventory; drift aborts.
The temporary existing-role ownership bridge follows canonical non-superuser install
patterns and restores grants in the same transaction; existing function ACLs unchanged.

The trusted worker must resolve a reviewed versioned capability manifest and supply a
valid canonical1.3 parent output. THIS DOES NOT INVENT A SCIENCE→LEVEL1–5 MAPPING.
Science verdicts remain in component feedback; a real reviewed canonical parent rubric
and output are still prerequisites. Fixture rubric/answers must never be published.
Mixed text-only, quantitative-only or combined sections share the same parent lifecycle.
Raw Math hints/generated solutions are excluded from the LAB composed projection.

Tests: tool/test_essay_components.py on disposable PG17, canonical runtime/lifecycle,
non-superuser migration role,38 checks. Includes interrupted install rollback, unchanged
core bodies/ACLs, worker/student grants, RLS/no direct table access, concurrent completion,
changed replay/stale fence rejection, actual1Credit, included rewrite0, atomic insert
failure, owner history, foreign/anonymous denial, failure/no consumption, essay erasure,
pending-deletion read denial and auth-user FK cascade. No Production test data or payment.

Deployment remains BLOCKED_NO_PRIVILEGE; no direct migration tool/credential/CI exists
in this cloud context. Fresh installed-function/topology/collision inventory is required
before any future promotion. Current runtime gates stay closed. No rollback script that
might erase recorded learning facts is supplied; failed installation is transactional.
