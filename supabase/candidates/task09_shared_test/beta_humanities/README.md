# TASK09-B: humanities-only TEST beta prerequisite

Only for the existing `kpqbedylxlyntrrfybpn` sandbox. Not a production migration. Never run this against production. SQL cannot establish the remote project hostname; the runner must pin the project separately. `build.py` reconstructs the candidate from the existing versioned precursor and pinned TEST math allocator. No runtime/provider implementation is replaced.

## Cause and minimal separation

The 2026-10-27 beta precursor was built against six billing entry points, including `public.math_session_submit(uuid,uuid,uuid[],uuid)`. Its exact-definition precheck rejects TEST where this math-only session subsystem is absent. Humanities exam reservation does not call that entry point. The candidate removes only its absent-function precheck/body, explicitly rejects an unexpectedly present math-session function, and retains the remaining baseline guards.

TEST already has `math_private.authorize_billing`. Replacing it with the newer production definition would introduce unrelated dependencies. Its pinned TEST body instead gets exactly one beta-grant exclusion. This protects beta grants even if an old math entry point is invoked directly; it does not activate math or install math sessions. Existing APP/WEB math gates remain unchanged.

## Verified installation order (TEST only, 2026-11-01)

1. `install.sql` — predecessor, inactive, no grants/campaigns.
2. `../../essay_credit_source_confirmation_20261027/apply.sql`.
3. `../../essay_beta_daily_v2/precheck.sql`, `install.sql`.
4. `v2-acl-order.sql`, then canonical v2 `verify.sql`.
5. `../../essay_session_retry/install.sql` — existing humanities retry contract; provides `retry_requests` needed by admin reporting.
6. `../../essay_beta_admin_v1/install.sql`, `verify.sql`.
7. `clock-acl.sql` — postgres-owned definer claim needs EXECUTE on the TEST essay_executor-owned clock helper. No public/client grant; clock implementation unchanged.

Steps 1–6 first passed against an owner-preserving TEST schema clone on local PostgreSQL17 (`task09_owned`, port55440). Then applied to the pinned remote TEST project. Step7 was separately validated locally and remotely after a real authenticated RPC exposed the missing helper grant. Production was not touched.

TEST default privileges put authenticated first in ACL arrays; canonical v2 checks require owner first. The ACL adapter revokes/regrants the same authenticated privilege to meet the existing exact guard. It does not relax the guard or add anon/service_role execution.

## Evidence

- Candidate regeneration/unit checks: 4 PASS; existing retry/failure/stage tests: 20 PASS.
- Canonical v2 and admin verify SQL executed without error.
- Real TEST Auth: Owner admin config HTTP200; student403; anonymous401.
- Real student beta claim initially failed403 (`permission denied for function clock`), then returned inactive after the scoped helper grant. No grant issuance.
- Credit transactions: 3, full-row ordered MD5 `9fa7f6d704237ce9eb628c6d43b10d17` before/after initial install. Runs0, campaigns0, daily grants0. No evaluation/Provider call.
- Math allocator before/after definition MD5 in `manifest.json`; original body in `math-before.sql`.

## Rollback / incomplete scope

Keep beta disabled and evaluation flags off. Do not delete ledgers, grants, requests, results or history. If rollback becomes necessary, inspect any newly accepted TEST requests first, disable beta through the canonical admin contract, and reverse dependent APIs using their reviewed rollback packages. Full remote rollback was not executed. Do not blindly restore allocator bodies while beta grants might exist. This package is not a production rollback authorization.

The TEST Gateway/queue/worker credential and provider policy, supported exam/package seeding, matching native API origin and shared evaluation E2E remain incomplete. Existing signed build33 is a disabled evaluation candidate, not a completed TASK09-B build. Provider execution still requires Owner approval; do not mark Owner evaluation review ready from SQL installation alone.
