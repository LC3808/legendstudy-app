# Admin Quality metadata — Owner apply review packet (2026-10-10)

**READY FOR FINAL OWNER APPLY APPROVAL; PRODUCTION NOT APPLIED.**
This is the approved bounded continuation of quality traceability, not a new QA system.
Canonical migration: `../../migrations/20261010134235_quality_console_metadata.sql`.
Created with `supabase migration new quality_console_metadata`. Do not bulk-push other
pending migrations. Only this reviewed migration may enter the existing production
migration workflow after final Owner approval; verify/record its migration ledger
entry through that workflow. No migration was applied or marked applied by this task.

## Scope and impact

Only `public.qlm_list_cases(integer,timestamptz,uuid)` and
`public.qlm_case_detail(uuid)` are replaced in one transaction. Their identities,
owner, ACL, DTO version, legacy fields, sort `(completed_at,id) DESC`, paired cursor,
and 1–100 page limit are retained. `quality_metadata` is an additive JSON object.
`qlm_quality(jsonb)` is the deployed DB caller; WEB StoredMathQualityReader uses that
wrapper. APP/student surfaces use `math_evaluation_detail`/student wrappers; these
and shared `math_private.evaluation_projection` are untouched. Dependency inspection
found no other function body caller. PL/pgSQL body calls are not fully represented
in pg_depend, so both source search and production function-body search were used.
No new table/function, GRANT, policy, write API, evaluation/answer/History/backfill,
Human Review, Credit, Payment/Toss/IAP, or evaluation switch change.
The list chooses its bounded page before keyed joins (all are PK/FK joins), avoiding
row multiplication and preserving pagination. No provider or storage request occurs.

## Metadata rules

- `student_reference`: `qs1_` + SHA-256(`legendstudy:quality:subject:v1:` + Auth UUID).
  High-entropy UUID input, server computed, purpose/version scoped. This is stable
  pseudonymization **not anonymization or encryption**, not a secret, and must stay
  operator-only. Someone already knowing the UUID can recompute it. No new secret or
  mapping table is introduced. Raw Auth UID, email and name are not added to output.
- `attempt_id`, `lineage_id`, `root_attempt_id`, `predecessor_attempt_id`,
  `prior_evaluation_id`, `relationship_state`: only canonical keys; root and parent
  must match student/leaf/lineage. Missing or inconsistent edges remain UNLINKED/NULL.
  The browser also validates problem/set/profile/rubric/user/root before grouping or
  comparing. Independent roots never merge merely because a student is the same.
- Problem set/problem/leaf/exam/university IDs are canonical joins; problem label is
  the stored set label plus stored question order. Essay type is Math; rubric is the
  pinned evaluation profile's actual version. No inferred exam titles or scores.
- University name/year require `essay_exams.verification_status='verified'` and
  non-NULL `verified_at`; otherwise NULL. Current synthetic exam is `review`:
  university/year are deliberately missing despite IDs being available.

## Backup, apply and rollback sequence

1. Recheck current function definitions, owner, ACL and callers. `original_functions.sql`
   is the read-only production snapshot; no credentials/student facts in that file.
2. Owner reviews migration, this impact note, automated evidence and `rollback.sql`.
   **Stop until Owner final apply approval.** No production role/RLS change is needed.
3. Through the existing approved migration path, apply only this migration to
   LegendStudy `stlhijzpjfgwwdgunlsd` (never Muselry). Baseline MD5+ACL preflight aborts
   atomically on drift; do not bypass it. Lock timeout5s / statement timeout30s.
4. Run `postflight.sql`; with real operator session verify list/detail metadata,
   four pairs, pagination/filter/history. With anonymous/nonoperator sessions verify
   denial. Local synthetic role tests do not substitute for this post-apply check.
5. Deploy the reviewed LAB commit via the existing Pages procedure only after DB
   acceptance, verify actual runtime, then update Wiki. Public activation stays HOLD.
6. If reverting, inspect `rollback.sql` then execute through the approved operational
   path. It accepts only the exact candidate function hashes and original owner/ACL,
   and restores the original definitions atomically; drift requires a new review.
   No data rollback exists or is needed. Record rollback in migration operations;
   do not pretend a reverted migration remains active or replay an entire history.

## Verification evidence and reproducibility

`tool/test_quality_metadata.py --pg-bin /opt/homebrew/opt/postgresql@17/bin` (Python
with psycopg) creates/removes a Unix-socket-only disposable PG17 instance, reuses the
canonical schema/auth bootstrap and synthetic fixtures. No production DSN is read.
The focused checks cover original wire/ACL/OID parity, 8 evaluations/4 pairs, other
users and forged cross-user root rejection, tied cursors, limit/invalid cursors,
anonymous/nonoperator/expired/revoked/lifecycle denial, wrapper, verified/missing
exam values, student/review API equality, unrelated function and fact hashes,
non-superuser production-owner apply, exact rollback and apply/rollback drift denial.
Prior backend fixture bootstrapping is synthetic; no new real evaluation or Credit
transaction occurs. `behavior_validation.json` and candidate fingerprints are output.
WEB metadata/unit/UI tests additionally separate different problems/rubrics, missing
parents/metadata, version/pin mismatches and render the user/process hierarchy.

`production_projection_evidence.json`: actual existing rows read through candidate
SELECT expressions only: 8 evaluations,1 pseudonym,4 roots,4 pairs,0 invalid edges.
This is NOT an applied RPC or deployed UI success. No raw UUID/pseudonym/answer is
persisted in this evidence. Production anonymous/nonoperator candidate RPC tests
remain pending apply. Student/evaluation records and public HOLD remain unchanged.
