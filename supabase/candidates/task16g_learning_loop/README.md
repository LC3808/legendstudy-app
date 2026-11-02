# TASK16-G TEST integration package

This is a reviewed TEST candidate, **not an automatic Production migration**. Do not execute against Production. The targeted isolated Supabase project is `kpqbedylxlyntrrfybpn`; deployment state is recorded in [the canonical Wiki](../../../wiki/task16g-learning-loop-20261102.md).

## Components / installed sequence

1. `install.test.sql`: exact observed legacy-body hashes/owners, immutable session/member/evaluation lineage and existing Credit decision hooks. `baseline.test.sql` is the matching existing function snapshot for local replay. `install.local.sql` uses the repository baseline instead. `build_package.py` regenerates only the local package.
2. `loop.sql`: server quote and guarded continuation, previous run identity, one included rewrite per paid cycle, 14-day/beta cutoff, idempotent expected charge consent.
3. `coaching.test.sql`: existing F contract, hosted-role-compatible installation.
4. `../task16f_math_coaching/002_disclosure_boundary.sql`: legacy raw-result boundary.
5. `mixed_disclosure.sql`, `mixed_learning.sql`: mixed Math safe projection, durable reveal/hint events and owner History; pure Essay records preserved.
6. `coaching_cycles.sql`: common coaching eligibility points to exam session continuation.
7. `seed.test.sql`: reviewed official 2024 Hanyang Q1/Q2 TEST identities/evidence. `catalog.test.sql`: existing canonical FK projection. `worker_roles.test.sql`: narrowly scoped worker-role switching for the TEST opaque API credentials.
8. `question_storage.test.sql`: authenticated read of the exact official question PDF hash only. No scoring PDF/student-photo permission.
9. `mixed_history.test.sql`: incremental RPC-only upgrade for installations that already have mixed tables. Fresh installs use the updated `mixed_learning.sql`; do not run both unnecessarily.

Installation is not idempotent by design: existing objects or changed baseline fail closed. Do not replay a successful migration blindly. No provider/API Secret belongs in these files. TEST API-key role bindings and runtime switches are external configuration; never PATCH secret placeholders obtained from a GET back into the environment.

## Verification

Use the existing PG17 harness with `TASK16G_LIVE_BASELINE=1` and `test_session.py --pg-bin <PG17 bin>`. Hosted coaching/mixed checks use `TASK16G_HOSTED_COACHING=1 python tool/test_task16f_coaching.py --pg-bin <PG17 bin>` from the APP root. These use synthetic local fixtures, not a cloud DB. Canonical Wiki distinguishes them from actual TEST Provider calls and saved-output replay.

Postflight must inspect function owner/search_path/ACL, private-table privileges, user ownership denial, quoted/reserved/consumed amounts, completed-only whole-exam state, and response masking before/after explicit disclosure. Existing records are append-only. No student originals, Auth tokens or lease credentials are committed.

## Rollback / hold

`rollback.local.sql` is for an **empty local session installation only**, before adding dependent coaching/loop layers. It refuses nonempty History; it is not a rollback command for the current TEST database. Current TEST already contains actual learning/ledger evidence: do not drop tables, delete runs or restore financial function bodies over live dependencies. To hold an incident, disable new TEST Provider requests via the specific dedicated binding and retain read/history/recovery. A previous Pages deployment can be restored independently. Keep existing original evaluation, confirmation, disclosure and ledger facts. Production migration and non-destructive Production rollback require separate Owner review after TEST acceptance.
