# TASK11-G production read-only reporting

Owner TASK11-G §16 authorizes verified read-only RPC additions. No operational
write candidates are installed. Production: `stlhijzpjfgwwdgunlsd` only.

Order (one atomic migration):
1. `operations_readonly.sql`: reuse TASK06 run/call projections and report signature;
   no tables, cost estimation writes, alerts, audit writes or source mutations.
2. `../analytics_admin_reporting_20261030/apply.sql`: existing TASK08-11 analytics.
3. `../admin_learning_task11/install.sql`: existing min-cohort-5 learning aggregates.

Preserve existing `admin_essay_operations(integer,text,timestamptz)` overload.
All new report functions require existing admin_operator + account_private.allowed;
empty search_path, authenticated execute only. Private views remain inaccessible.
No admin UUID, RLS, source table or existing gate changes.

Operations returns `read_only=true`; client disables estimate/check-alert mutations.
Receipt prices remain UNKNOWN; recorded legacy USD actual/estimate remain distinct.
No private raw answer/error text is projected into reports. Existing quality access
remains separate. Missing beta/notices/feedback packages remain NOT_CONNECTED.

Validation: TASK08 synthetic integration suite (exam/legacy deduplication,
KRW/LIVE/refunds, USD actual/estimated/unknown, 21 denied role calls, source digest,
rollback/reinstall); TASK11 learning fixture; TASK11G read-only operations fixture.
Also schema-only clone of existing TEST and live production dependency inspection.
Run local_operations_test.sql only in disposable local DB after TASK06 local_fixture
and operations_readonly. Never seed shared TEST/production with these fixtures.

Rollback: first revert WEB deployment. rollback.sql revokes only new RPC access;
no ledger/result/data restoration. Retain views/functions for investigation.
Production queries are additionally verified under a READ ONLY transaction.
