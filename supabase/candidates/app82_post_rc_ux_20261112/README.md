# APP82 Post-RC — read-only RPC candidates

**NOT DEPLOYED. Owner approval required.** This directory is a review package,
not evidence that a migration ran. LegendStudy only. No Auth, tables, records,
RLS policies, existing functions, Credit, Worker, or LAB changes.

## Audited baseline

`baseline.json` and `private_baseline.json` contain the 2026-11-12 read-only
production function definitions. `apply.sql` rejects baseline drift or an
already-existing candidate. Existing school policy is **3** active recorders for
total/average and **1** for participation; the brief's public-rank threshold of
5 does not match production. No threshold change is included.

## Added contracts

1. `student_school_ranking_page(period, metric, scope, offset, limit, as_of, revision)`:
   identical existing per-user interval union and school aggregation; first 10
   ranked rows, first 10 active unqualified schools, own school and next offsets.
   No-record schools are excluded from the outside list. Other-school counts
   remain NULL; outside times and ranks remain NULL. Ties use `rank()` and
   ordering uses the existing metric, office code, school code.
   Subsequent pages reuse the server timestamp and public-projection digest.
   If authorized projection/membership changes, `PT409` requires refresh instead
   of mixing snapshots. A snapshot expires after 15 minutes. The digest never
   includes suppressed counts or individual records. Limit is fixed at 10.
   Offset is over a fully ranked aggregate, not an unbounded raw-row scan;
   keyset pagination would not avoid the global rank aggregation here.
2. `my_study_percentile()`: authenticated caller only, one statement timestamp,
   completed synced valid intervals (overlaps unioned) for allowed users.
   Users without a positive total do not enter the comparison population.
   Candidate minimum population **20**. `rank = greater_count + 1`;
   `top_percent = ceil(100 × (greater_count + tie_count) / population)`.
   Tied students share the conservative upper boundary of their tie group.
   Example: 2 tied highest of 20 → both top10%; all equal → top100%.
   Under 20: insufficient_sample and no population/rank/percent disclosed.
   Own zero: no_records. No other user's ID or time list is returned.

Both functions authenticate `auth.uid()` + existing `account_private.allowed`,
use SECURITY DEFINER with empty search_path, revoke PUBLIC/anon execution and
grant authenticated only. Global comparisons remain inside PostgreSQL; direct
study/profile reads remain denied by existing permissions/RLS.

## Approval and application

1. Owner reviews the two new read contracts, current 3/1 policy, minimum20 and
   tie-upper-bound formula with [the report](../../../wiki/app82-post-rc-ux-20261112.md).
2. Re-read production definitions/ACL and compare the audited baseline. Do not
   bypass `BASELINE_CHANGED`; investigate differences and regenerate the package.
3. Owner applies `apply.sql` as the existing migration executor in LegendStudy.
   It is a single transaction, additive only. Do not apply it to other projects.
4. Run `verify.sql`, then read-only authenticated app requests with the Owner's
   existing account. Compare first page and own rank with v1 for each filter,
   inspect privacy and page loading; zero/sample states need isolated fixtures.
5. Production performance/load and physical-device live flow remain NOT TESTED
   until this separately approved application. No repeated Provider calls.

## Verification and rollback

`python3 tool/test_app82_post_rc_sql.py` uses a disposable PostgreSQL17 instance
on a temporary Unix socket, no remote URL, isolated accounts/sessions, and checks
permissions, ties, thresholds, pages, snapshot changes, record overlap/exclusions,
baseline/data preservation and rollback. No production fixtures are inserted.

`rollback.sql` drops only the two additive functions. Confirm they have not been
changed by a later task before executing. Old RPCs are untouched; the app falls
back to existing TOP10 when the new ranking RPC is absent and suppresses a missing
percentile instead of inventing a value. Do not roll back data or existing grants.

References: [Supabase database functions](https://supabase.com/docs/guides/database/functions),
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
