# Day 8-D1 — actual JWT/RPC acceptance verifier

Production migration/Postflight and actual A/B scoring JWT/RPC acceptance are
**Owner-reported PASS. Day 8-D1 = COMPLETE.** Codex did not execute this production run.

## Owner execution

`tool/verify_mock_scoring_jwt.py` needs Python 3.10+ and the pinned dependency in
`tool/requirements-scoring-verifier.txt`, installed outside the repository. The current
external environment is `/private/tmp/legendstudy-scoring-verifier-venv`; if removed,
recreate an external venv and install that requirements file before execution.

Run from the repository with that environment's Python, passing the external public
config path `/Users/woojinchang/legendstudy-local.json`. Optional `--preflight-only`
logs in, verifies the global empty scoring baseline/admin identity/trigger ownership,
and logs out without creating fixtures. It does not claim full acceptance PASS.

The tool prompts for:

1. A/B passwords with getpass, hidden and never written to disk.
2. Supabase Dashboard -> LegendStudy -> Connect -> **Session pooler** host only,
   e.g. the hostname from the session connection settings, without password/URI.
   Port is fixed at 5432; pooler username is constructed as `postgres.<LegendStudy ref>`.
   Blank chooses the project-pinned direct DB hostname (requires working IPv6).
3. LegendStudy **database password** via getpass. This is not an Auth-user password
   or API/service-role key. The administrator must own the three cleanup tables.

The target ref is printed before credentials. Hostnames are allowlisted, credentials
stay in memory, TLS is required, and the administrator connection must see the same
A/B UUID/email pairs as the project-pinned Auth endpoint before fixture creation.
No service-role key is needed. No credentials in command arguments, shell history,
Wiki, fixtures or stdout. HTTP redirects are refused. Errors show stage/status and
an allowlisted SQLSTATE only, never raw response/exception text.

## Separation and fixture contract

`Acceptance` calls real HTTPS Auth/REST/RPC with A/B JWTs. `AdminFixtures` uses a
separate PostgreSQL connection only for fixture lifecycle, baseline and scope checks.
SQL role switching is not used by the production verifier.

All five scoring tables must be globally empty; existing scoring rows cause STOP.
All public table counts and sorted row digests are retained in memory. Existing
profiles, NEIS, D-Day, Study and source/content rows may exist and are preserved.
Random UUIDs are checked absent and registered before dispatch. Sources are marked
synthetic with example.invalid provenance: these are not official answers or grades.
Temporary active content is visible during the test; complete the run uninterrupted.

Fixtures include source_post, content/exam, subject/occurrence, two complete key and
cutoff versions, an incomplete draft key, an incompatible cutoff, run-owned attempts
and one mock Study row. Public availability, scoring totals and each snapshot are
verified. Current version switching, stale rejection, historical retry, conflicts,
malformed input, direct forgery, owner isolation, Study unlink and owner cascade are
checked using actual returned rows, not HTTP status alone.

## Owner-approved cleanup exception

This exception is **only for this verifier's generated fixture UUIDs**. Ordinary
published key/cutoff immutability and the app's operating contract do not change.

Cleanup runs in one PostgreSQL transaction:

- Check the public table inventory; acquire SHARE ROW EXCLUSIVE locks on baseline
  tables, and ACCESS EXCLUSIVE locks on the three trigger-bearing tables. Lock and
  statement timeouts fail closed. These short cleanup locks can briefly block traffic.
- Require all trigger catalog states unchanged, non-fixture counts/digests identical
  to preflight, and fixture counts/digests equal to the in-memory manifest. Verify
  attempt owner/key scope and Study owner. Unknown changes cause STOP, not deletion.
- Disable only `answer_key_versions.scoring_key_publication`,
  `grade_cutoff_versions.scoring_cutoff_publication`, and
  `exam_questions.scoring_question_guard` (ordinary USER triggers, initially enabled).
- Delete run UUIDs in dependency order: attempts (answers FK cascade checked), Study,
  questions, cutoffs, keys, occurrence, exam, subject, content, source. Every DELETE
  uses `WHERE <fixture-id-column> = ANY(%s::uuid[])`; exact affected count is checked.
- Re-enable the three triggers, compare the full trigger catalog, verify fixture
  disappearance and all baseline counts/digests, then COMMIT.
- Any error rolls back the entire transaction, including temporary trigger state.
  No independent COMMIT on failure; no ALL/FK/constraint-trigger disable and no
  replication-role bypass. PASS cleanup stages are emitted only after commit.

The manifest is refreshed after each dispatched REST write, including a lost HTTP
response, via the separate admin connection. Thus a committed but unacknowledged
attempt can be removed by its pre-registered UUID. Any later count/digest change
causes STOP. If the admin connection fails or a fixture commit is uncertain and its
manifest cannot be reconciled, cleanup cannot be claimed: investigate before rerun.
Process kill/power loss cannot execute Python finally; do not start another run to
purge residue. A later preflight stops on scoring residue. Never delete unrelated rows.
Auth users are only read and their test login sessions logged out; no user deletion.

## Validation evidence

Offline suite: 16 scoring tests PASS; 29 existing JWT tests also PASS (45 total), including the full SQL-backed transport flow, exact rejection
checks, credential-output canaries, project pinning, main/finally cleanup on failure,
preflight-only, committed-response-loss recovery, pre-existing rows/identity mismatch,
external data/FK-reference/trigger/count drift STOP, and rollback injections after
trigger disable, each deletion step and immediately before commit. The private native
PostgreSQL cluster uses Unix sockets with TCP disabled and is removed after tests.

These tests simulate REST routing with real local role permissions. They are **not**
production JWT/REST evidence. Python syntax, credential scan and diff checks accompany
this preparation; migration files remain unchanged. Production acceptance must print
all stages including fixture_scope_verified, fixture_cleanup, cleanup_triggers_restored,
scoring_baseline_restored, existing_data_preserved, auth_users_retained and acceptance.
No Flutter scoring, production schema change, Push, PR or Merge.

## Owner-reported production result — 2026-09-14

Owner reports actual A/B JWT/RPC acceptance PASS: server-side scoring, own result
and snapshots, direct score/grade forgery denial, owner isolation, idempotent retry,
current version switch and stale key/cutoff rejection, invalid inputs, Study deletion
retaining attempts/answers with a NULL link, and owner attempt deletion/cascade.
Fixture scope/cleanup, cleanup trigger restoration, scoring baseline restoration,
existing data preservation and Auth user retention all PASS.

**Day 8-D1 = COMPLETE. Next: Day 8-D2 Flutter Answer Entry + Raw Score.**
Day 8 overall is not COMPLETE; Day 8-B/8-C physical-device gates remain pending.
Flutter scoring/Dart parity and real source ingestion are not verified by this result.
This is Owner-run production evidence; this documentation closeout made no DB requests.

```text
SCORING_RUNTIME PASS login_preflight
SCORING_RUNTIME PASS publish_fixture
SCORING_RUNTIME PASS valid_submit
SCORING_RUNTIME PASS fetch_own
SCORING_RUNTIME PASS direct_forgery_denied
SCORING_RUNTIME PASS ownership_isolation
SCORING_RUNTIME PASS idempotent_retry
SCORING_RUNTIME PASS current_version
SCORING_RUNTIME PASS invalid_inputs
SCORING_RUNTIME PASS study_delete_semantics
SCORING_RUNTIME PASS owner_delete
SCORING_RUNTIME PASS fixture_scope_verified
SCORING_RUNTIME PASS fixture_cleanup
SCORING_RUNTIME PASS cleanup_triggers_restored
SCORING_RUNTIME PASS scoring_baseline_restored
SCORING_RUNTIME PASS existing_data_preserved
SCORING_RUNTIME PASS auth_users_retained
SCORING_RUNTIME PASS acceptance
```
