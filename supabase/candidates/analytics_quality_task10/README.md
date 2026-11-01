# TASK10 satisfaction extension — approval candidate

Reuses TASK05 feedback submissions/context, ownership, request hash, per-user advisory lock, 10/hour limit, official admin gate. No new behavioral/evaluation/Credit ledger. Binary legacy ratings remain separate; no backfill or conversion.

Dependencies: feedback_operations migration → essay_feedback_v1/install.sql → this feedback.sql (single transaction). Run precheck.sql and compare installed submit definition against the TASK05 base; stop on unexpected drift or partial/existing v2. Owner approval required for any deployed DB.

After install run postcheck.sql, authenticated ownership/admin and anonymous acceptance checks. No client activation until successful. WEB requires existing NEXT_PUBLIC_ESSAY_FEEDBACK_V1_ENABLED plus new NEXT_PUBLIC_ESSAY_SATISFACTION_V2_ENABLED=true; latter defaults off. Existing APP remains binary compatible. Numeric modal opens only at user request, never automatically. This candidate does not claim APP numeric UI or GA4 receipt.

Local tests only: localhost:55439 task10_feedback, TASK05 local_fixture.sql → ../../migrations/20260917000100_feedback_operations.sql → TASK05 install.sql → feedback.sql → TASK05 test.sql → test.sql. Synthetic fixtures, auth/admin stubs; not real authorization acceptance. All test.sql transactions roll back. Never run fixtures on deployed DBs.

Rollback: first disable v2 flag/restore previous WEB artifact, then reviewed rollback.sql restores original submit and revokes report access. Retain new columns and all feedback for lossless recovery. Do not drop or backfill historical feedback. Re-enable only through a reviewed forward script, not blind reinstall.

Remaining: hosted role/ownership acceptance, APP numeric UI, review of retention/aggregation at scale. No operational changes authorized by this candidate.
