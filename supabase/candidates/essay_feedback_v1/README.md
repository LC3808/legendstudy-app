# LAB feedback candidate — Owner approval required

Canonical policy: [Wiki](../../../wiki/essay-feedback-reports.md).
Production: read precheck.sql first; verify existing feedback schema, official admin gate and active-account function; review install.sql diff. Apply install.sql once only after Owner approval. Run postcheck.sql and authenticated/anonymous/other-user acceptance tests. Never execute local_fixture.sql, test.sql, result_test.sql or concurrency_test.py against Production.

Activation stays off until approved SQL + acceptance. Existing feedback email outbox is reused. No new evaluation, Credit or History write is part of this package.

Local reproducibility (PostgreSQL17, local roles anon/authenticated/service_role already exist):
1. Create an empty disposable DB `feedback_task05_<suffix>` on 127.0.0.1:55439.
2. psql with ON_ERROR_STOP=1: local_fixture.sql → ../../migrations/20260917000100_feedback_operations.sql → install.sql → test.sql → result_test.sql → postcheck.sql.
3. `FEEDBACK_TEST_DB=feedback_task05_<suffix> python3 concurrency_test.py` commits only synthetic local feedback. Unit/result SQL uses BEGIN/ROLLBACK. Auth/admin gates are stubs, not proof of Production login.

Rollback: disable client flags first, restore prior artifacts; rollback.sql revokes new RPC access without deleting submitted content or audit. Do not run rollback as an installation step. Private records and status extension remain for lossless later recovery.
