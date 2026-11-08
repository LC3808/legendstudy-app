# Daily material sync — deployment candidate, not yet deployed

Only the existing LegendStudy ingestion runtime and new scheduler files belong in
this deployment. Do not merge APP67/release history into the old remote main.
Runtime source is Python stdlib plus pinned psycopg; no Flutter/app build.

Owner approval is required for install.sql, dedicated DB credentials, GitHub
production environment/secret and activation. install.sql defaults to disabled.
The dedicated role cannot delete rows or modify existing taxonomy/exam records,
parent activation, or financial/student tables. No service_role key in Actions.

1. Record current remote main SHA and production source/content/resource counts.
2. Install SQL once; inspect ACL/RLS. Provision a dedicated random role password
   privately; never print it or commit the connection string.
3. Store MATERIAL_SYNC_DATABASE_URL in GitHub environment
   material-sync-production (restrict deployment branch to main).
   Use Supabase session pooler5432, role suffix with project
   stlhijzpjfgwwdgunlsd, sslmode=verify-full. No transaction pooler6543.
4. Import only release-manifest files as a minimal commit on remote main after
   comparing its previous SHA. No unrelated APP source commits or force pushes.
5. Run full dry-run before enabling. Review new/changed/review/failed counts.
   New posts must be newer than the existing DB baseline; ambiguous/held sources
   retain current state. All existing sources are checked daily; up to30 unseen
   IDs per run are checked newest-first. No historical sitemap-wide auto publish.
6. Enable ingestion_ops.config.enabled and repository variable
   MATERIAL_SYNC_ENABLED=true only after approval and preflight.
7. Dispatch the workflow and inspect DB runs/observations and app reads.
   Confirm schedule registration (03:17 KST) separately from observing the next
   cron-triggered execution. A manual dispatch is not evidence of a cron firing.

Stop: disable GitHub workflow/variable; execute disable.sql; verify current run
stops at the next post boundary and releases advisory lock. Already committed
normal content stays intact. Roll back an affected run with the operator-only
rollback_daily_material_sync.py in reverse run order. Current rows must still
match recorded after values; a conflict aborts rollback. New IDs are hidden,
never deleted. Keep ops audit records. Use an admin connection only for rollback,
never its credentials in the scheduled job.

Last complete success: runs.status='success'. Partial runs retain per-post
last_success_at, status and error_code in observations. Logs contain source IDs,
counts and error codes only. No raw HTML, signing URL, user or payment records.

APP67: refreshed detail/search reads new data. Home currently caches while the
app stays running and sorts by original publication time. Restart/requery sees
new posts; this deployment does not force an already-open home to refresh.
