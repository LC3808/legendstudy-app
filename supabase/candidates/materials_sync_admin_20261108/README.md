# 72-hour schedule and administrator controls — additional approval candidate

Depends on deployed `materials_daily_sync_operations_20261108`. Do not reinstall it.
Current first execution finished: 390 ok,90 review,0 failed; 7 posts/31 attachments added,
all original450 source/10635 resource identities preserved. Original daily repo variable
is false during policy transition. Existing data is already visible to APP67.

## Proposed deployment order

1. Verify no active worker, original IDs and enabled=false GitHub gate.
2. Apply install.sql: extend existing ops config/runs/observations, add active/run lookup
   indexes and two admin-only public invoker RPCs backed by private definer functions.
   Use existing admin_operator() AND account_private.allowed(auth.uid()). No general
   user table access. Worker gets schedule-state column UPDATE only; no finance/Auth writes.
3. Publish minimal24 runtime files, preserving unrelated APP main source. Same Secret,
   verified TLS CA and main-only GitHub environment. No new server or GitHub token.
4. Publish WEB route `/admin/material-sync/` and common admin menu, preserving current
   production Functions/settings/assets outside this change. Build and route manifest
   must be compared with the latest deployment immediately before publication.
5. Enable existing repo variable. GitHub polls DB every5min; crawler executes only for
   due or queued requests. First due is next04:00 KST after SQL installation. After a
   completed automatic run with0 failed sources, next_due=actual completion+72hours.
   Review holds count separately and preserve existing data. Failed automatic execution
   retains due time and retries after1hour. Manual runs do not shift automatic due.
6. Use actual admin session to request one refresh; verify duplicate suppression,
   queued/running/completed state, metrics, source preservation and APP public API.
   No production fixture/user/financial action. Verify automatic due claim in isolated
   DB; report actual first cron event separately, never claim a future event already ran.

A GitHub schedule is best effort: exact04:00 wall-clock dispatch is not guaranteed.
The persistent72h due timestamp prevents calendar-month cron errors and early repeat
collection. UI explicitly displays queue/poll delay and actual completion/next basis.

Unchanged source fingerprints skip Registry reconciliation/writes. HTML change checks
remain necessary because source sitemap lastmod is not a reliable attachment-deletion
signal. Full article text is included; signed delivery URLs are excluded. First v2 run
establishes the richer fingerprint baseline; later identical sources update only ops
observation records. Existing parser/normalizer/UUID and transactional apply are reused.

Metrics: new parent source count; changed existing post count; added resource count;
existing resource URL replacements; resource soft-deactivations. A different source
attachment identity is counted as add+remove, not asserted as the same file. Older run
metrics are derived read-only from existing before/after audit, never guessed as0.

## Stop / rollback

Set GitHub MATERIAL_SYNC_ENABLED=false, execute disable.sql, then wait for worker to
stop at next source boundary and release lock. Restore previous WEB artifact if needed.
Keep scheduler disabled when restoring older runtime (old daily policy is superseded).
Do not drop new ops columns/logs or delete source data. A specific incorrect content run
can use the existing conditional before/after rollback command in reverse run order;
conflicting later edits abort rollback. Existing new IDs are deactivated, not deleted.

Approval covers new SQL/RPC permissions,24 runtime files/GitHub72h gate,WEB UI deployment
and one real administrator manual refresh/read-only verification. APP67/store/evaluation/
credit/payment/refund remain excluded.
