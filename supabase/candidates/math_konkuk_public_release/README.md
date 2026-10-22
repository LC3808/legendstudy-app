# Existing Konkuk Math release — 2026-10-23

Owner explicitly authorized E2E-passed question activation. Existing initial/rewrite/History/Credit1/0 and cross-client real Provider evidence is reused; no duplicate evaluation.

Exact scope: existing admission trigger function restricts evaluation inserts to reviewed Konkuk leaf and authenticated attempt owner; existing catalog exposes that leaf only; existing runtime control enables evaluations. No new tables, triggers, IDs, profiles, evidence, RLS or migration history. Existing status function is unchanged. Gateway separately checks the owned leaf before upload/extraction/evaluation; operator diagnostics retain allowlist.

Before applying, current function definitions were compared exactly with private backup. One transaction applied two function replacements and one existing switch. Full restore SQL retained; rollback closes switch and restores functions, never removes attempts/results/Ledger. Pages flags must also close on rollback. The candidate file records the intended SQL; it is not proof of future deployment state.

Local PostgreSQL exact trigger checks: own released leaf accepted; held leaf, foreign owner, anonymous and paused switch rejected, rejected rows absent. Existing runtime suite plus new server-scope checks71 PASS. Actual public runtime verification is recorded in wiki/phase3-service-20261022.md.
