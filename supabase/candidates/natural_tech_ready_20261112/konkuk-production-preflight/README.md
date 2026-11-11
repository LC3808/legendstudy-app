# Konkuk only — Stage1 DRAFT approval package

**PREPARED / NOT APPLIED / OWNER APPROVAL REQUIRED.** Replaces the broad53-question proposal for the next operation only. Existing KAU7/106-row approval is not reused as authorization.

Scope:6 exams24 questions, existing Registry IDs unchanged. Math8 tables275 rows + private Worker source24 rows = **299 INSERT rows**. No RPC/engine/Worker activation/credit/publication/WEB/APP deployment, no prior data UPDATE/DELETE. Existing Konkuk4/Kyunghee3 ACTIVE bindings and KAU7 DRAFT are preserved.

Exact executable remains private: `.local/konkuk-production-preflight-20261112/apply-draft.private.sql`.
SHA256 **7fc4488f70516807b016e60130bf8906be49a7f6e6bf3d4d580398f8735d74aa**. `sql-receipt.json` pins package/source/SQL hashes; `scope.json` lists exact IDs and object row counts.

Production read-only preflight: **116/116 PASS**, timestamp in `production-select-results.json`. Re-run immediately before any authorized execution; a changed condition stops the operation. The SQL independently repeats guards inside a repeatable-read transaction, rejects duplicates/foreign binding/publication/definition/RLS/ACL drift, snapshots prior content/answers/results/credit/functions/ACL/RLS, verifies139 postconditions and compares20 preservation groups before commit. No external SELECT authorizes a write.

Disposable PG17 exact apply/verify/retire: **124 named checks PASS**. Fixture first recreates prior KAU7 DRAFT106 rows and7 older ACTIVE bindings, then applies only Konkuk24. Tests include failed preconditions, late Worker failure atomic rollback, preservation-drift atomic rollback, duplicate apply rejection,24x2 DRAFT submission denial,24 Worker exact mappings, HOLD5/NOTREADY16/other22 exclusion, prior KAU data preservation, retirement replay, existing result/history preservation. Provider0/production writes0.

Rollback: `rollback-retire.sql` changes only candidate4 versioned tables96 rows DRAFT→RETIRED. No sources/Registry/answers/results are deleted; repeat execution preserves history. It refuses if later activation changed scope. On unexpected drift stop and ask Owner; do not expand recovery. `verify-retired.sql` verifies expected retained objects and retired state.

Apply only after separate Owner authorization for these24 questions/299 rows. Stage1 ends in private DRAFT, not REVIEW READY or SERVICE READY. Shared Owner access remains a separate disabled candidate and is not part of this approval request.
