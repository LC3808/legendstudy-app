# TASK16-L SQL candidate — TEST applied, Production approval required

Owner request: new reviewed learning levels only; preserve every old evaluation, Credit and History. Production is NOT applied.

## Fresh installation

1. Read-only preflight: current function definitions/owners/ACL, column absence, old result/ledger hashes, private helper-name absence. Export definitions and counts to private evidence.
2. Apply `20261104060714_task16l_learning_persistence.sql` transaction (nullable column, atomic finalize, read/history wrapper and comparison; uses existing math_executor boundary).
3. Apply `mixed.sql` transaction (existing completed exam child JSON, owner guard preserved).
4. Postflight: old result hash excluding nullable column unchanged, old ledger rows unchanged; no historical judgement; public facade ACL unchanged; helper inaccessible to anon/authenticated; postgres facade can execute helper; no persistent role membership/schema CREATE grants.
5. Deploy matching TEST backend with `MATH_LEARNING_ENABLED=true`; production remains disabled until separate approval.

## Existing TEST upgrade history

Initial core/mixed applied; `criterion_details.sql` added reviewed criterion notes; `executor_boundary.sql` fixes hosted postgres facade → canonical math_executor helper execution. The intermediate owner-transfer ACL fix explicitly re-granted postgres EXECUTE after owner transfer. These followups are historical for the already-installed TEST, not a fresh-install sequence. Current core includes all corrections. Never run criterion_details after executor_boundary because its earlier SECURITY INVOKER declaration would regress the boundary.

TEST: kpqbedylxlyntrrfybpn. No production SQL.

## Validation

`/private/tmp/legendstudy-final-quality-venv/bin/python tool/test_task16l_learning.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`

Disposable local Postgres tests canonical finalize, invalid packet rollback, same replay, changed replay rejection, old result preservation, same-lineage comparison, criterion evidence, free re-evaluation, mixed full-exam/owner guards, and rollback keeping saved data. Hosted ownership/ACL must additionally be checked: local superuser fixtures cannot substitute for managed Postgres privileges.

## Rollback

Disable TEST learning flag to stop new optional generation. Apply `rollback.sql`: restores facade read/finalize and mixed projection, retains nullable column and stored learning judgements/disclosure/History. No DELETE or historical overwrite. Do not blindly rerun initial migration after rollback; prepare a forward migration against actual function state.

## Remaining production gate

Inspect actual production definitions first (official-solution wrapper differs from TEST); source clones the current definitions, never replaces them from an old snapshot. Owner approval is required for exact reviewed SQL and ACL. Store/production WEB rollout is separate. Details and actual E2E verdicts: `wiki/task16l-learning-persistence-history-20261104.md`.
