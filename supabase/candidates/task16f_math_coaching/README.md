# TASK16-F common coaching contract — candidate, NOT DEPLOYED

This directory is a review package, not part of automatic migration replay. It changes response contracts; do not apply to Production or an existing shared Preview without a compatibility review. Runtime/provider/billing policies are unchanged. Current full-service activation is **HOLD**.

## Scope / prerequisites

- Existing MATH persistence, runtime, learning migrations and role topology must be verified, not assumed from files.
- `001_coaching.sql`: owner-scoped `math_coaching` / `math-coaching-v1`; deterministic pre-disclosure projection; append-only first full-disclosure event attached to existing evaluation/student IDs. No duplicate History, ledger or evaluator.
- `002_disclosure_boundary.sql`: closes the old standalone `math_input.read_result`, detail, hint and learning-state response paths. Authenticated callers cannot execute the renamed raw functions. This is a breaking response change for older Math clients; coordinated rollout required.
- **Not covered:** mixed `essay_exam_history` and all deployed Math-session/WEB consumer response paths. Do not describe this as a completed global disclosure boundary.
- Role grants are temporary in the candidate. Compare grants/owners before and after. Reject topology drift; do not revoke an unrelated pre-existing grant in a live project.
- SQL table has RLS and no student table grants; disclosure key retry is idempotent, cross-owner access denied, account deletion cascades via existing student FK. It does not replace existing hint/solution exposures or persist new student classifications.

## TEST verification / apply sequence

1. Back up exact function definitions and grants from the intended **isolated TEST** database. Verify project identity and active client versions. Disable student execution while reviewing compatibility.
2. Run the disposable local harness first:
   `python tool/test_task16f_coaching.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`
3. Resolve mixed/session response boundaries and enrich reviewed criteria/concept mapping before activation. This package is not currently ready for broad TEST client rollout.
4. After Owner review, apply 001 then 002 in the isolated TEST only, then execute `postflight.sql` and authenticated two-owner behavior checks. Never use a service-role client to stand in for a student.
5. Verify raw result/hint/state/history response bodies, failed disclosure requests, retry/parallel requests, owner switch, no Provider call on read, and unchanged ledger. Run Native/WEB compatibility tests before enabling their route.
6. Production remains blocked until a separate Owner release decision. No production apply was performed for TASK16-F.

## Wire

Input `{dto_version: "math-coaching-v1", action: read|hint|reveal|history, payload: {...}}`; output `{dto_version, action, result}`. Actions use the existing evaluation ID, never caller-supplied student IDs. `hint` carries task_id, level 1/2, stable client_submission_id; `reveal` carries a stable client_submission_id. Read/history do not authorize charges or call Providers.

Before disclosure the result has diagnosis, up to five ROOT tasks, confirmed student transcription/source-region metadata, reviewed generic concept fields, and server rewrite eligibility. Provider free prose, final formula, full solution, alternative paths and progress prose are not copied. NOT_DETERMINABLE is not represented as correct. Explicit disclosure returns references and saved analysis; source provenance stays distinct.

The generic projection is a conservative safety implementation, **not final university-specific coaching quality**. Official rubric priority, precise concept selection, History task-resolution/receipt summaries, persisted source-image retrieval and paid-cycle repeat semantics remain documented in the Wiki.

## Rollback

Disable new Math routes first. Revert Native/WEB response consumers together, then use `rollback.sql` only on a database matching this package. It restores old functions/grants and retains the private disclosure records. Restoring legacy responses reopens the old server exposure limitation; do not activate them as if they satisfied TASK16-F. No credit/payment rollback is necessary because none was changed.
