# TASK03-B — Owner approval candidate (NOT APPLIED)

**Do not execute against production without Owner approval.**
Scope: existing mixed-v2 schema/RPC extension, 443 keys / 11,170 questions / 1,029 new reference
cutoffs. No Registry merges, no taxonomy writes, no actual student submissions, no Credit/Ledger/payment
operations, no app/store deployment. Unverified 12 umbrella IDs and nine null-code IDs get no keys.

[Full evidence/report](../../../wiki/task03b-ready-candidate-20261111.md) ·
[Data inputs](../../../data/mock_expansion/task03b/load_data.json).

## Live read-only preflight and impact

2026-11-11: LegendStudy `stlhijzpjfgwwdgunlsd`, PG17.6. Existing keys/questions/attempts/answers/
scoring-grade-versions each0; reference cutoffs2,457. Registry417 rows match exactly. All six scoring/
reference tables have RLS. Captured definitions/ACL/constraints are pinned in the preflight.
This snapshot is not a permanent guarantee: run `00_preflight.sql` again immediately before applying.

- `01_engine.sql` extends the existing MCQ engine with the already tested mixed-v2 path. It adds typed
  snapshots and question IDs, changes generated score expressions and count constraints, and replaces
  scoring dispatch/publication/submission/view definitions. **Preserves the production account lifecycle
  lock and eligibility guard** found missing from the old initial-schema candidate. Account functions,
  Auth tables/policies and Credit/Ledger/payment code are not changed.
- Existing MCQ results remain valid. All-credit blanks may count as both correct and unanswered.
- Existing published-answer read policy remains: anon/auth may read published official question keys,
  but cannot mutate them. Draft/withdrawn keys are hidden by existing RLS. Results remain owner-only;
  existing owner deletion permission and restrictive lifecycle policy are preserved.
- `grade_cutoff_lookup` is not replaced. The underlying references stay private; callers use the existing
  scoped RPC. Reference raw/percentile values are marked unspecified and never inserted into automatic
  raw-grade versions. Standard scores are official confirmed values.
- No original rows are rewritten by data seed. Family conflicts or changed data stop the transaction.
  Generated-column changes can take table locks/rewrite data: capture current schema/data backups and
  actual row counts/lock budget before approval/application, even though this read-only snapshot had0 attempts.

## Reviewed operational sequence — psql, not SQL-editor pasting

All scripts use `\ir` relative to the script location. Use `psql -X -v ON_ERROR_STOP=1 -f FILE` with
an already approved connection; never put credentials in Git or command output.

1. Capture schema backup plus hashes/counts of keys/questions/results/cutoffs. Run `00_preflight.sql`.
   Compare current Registry and existing reference digest with the captured report. If newer changes
   exist, stop and re-review rather than editing expected fingerprints to force passage.
2. Apply `01_engine.sql` once. It is deliberately **not** blindly idempotent; unexpected installed columns
   or function/ACL/constraint drift abort. Do not directly apply the older `task03_scoring_v2/candidate.sql`.
3. `02_seed_drafts.sql`: inserts exactly443 READY-but-draft keys,11,170 question rows,1,029 draft references.
   Existing family/identity/content mismatches abort. Identical reruns do not update anything, including
   already published rows. No arbitrary `ON CONFLICT` overwrite.
4. `04_validate.sql` checks exact bidirectional equality of expected questions/keys/references.
   Before publication the printed public counts should0. Compare original2,457 reference rows/hash.
5. `03_publish.sql`: only the exact reviewed batch becomes current/published. READY/count/points/source
   checks, active Registry, duplicate families and withdrawn versions are guarded. Identical rerun is a no-op.
6. `04_validate.sql` again:443 current READY keys and1,029 current references. Read scoped anon/auth API,
   verify17 exams and per-subject gates. No real student scoring/payment action is needed for rollout.
7. Owner-controlled internal iOS/Android validation after separate installation/build decision. Store submission excluded.

Expected after first application: keys443, questions11,170, references3,486 (2,457+1,029), scoring-grade
versions0. Actual student attempts/answers remain unchanged during deployment. Student scoring responses
have raw points and per-item correctness; official grade remains unavailable without a separate valid grade basis.

## Stop / rollback

Before commit: transaction `ROLLBACK`. After publication: `05_rollback_visibility.sql` withdraws only
this exact batch and marks it non-current, preserving all keys/questions/reference evidence and student
attempt/answer snapshots. It still works if an exam was made inactive afterward. Repeated stop is safe.
An identical saved retry retains points/answers; the source status correctly becomes `withdrawn`.
Re-publication of a withdrawn batch is blocked pending new review.

Do **not** drop typed columns, restore the old disjoint-count constraint, or delete published keys after
students have submitted. A structural reverse migration requires separate analysis/approval. Returning to
previous app code is optional after stopping new mixed-v2 entries; preserve immutable results.

## Validation and limits

- Read-only captured target function/ACL/column/constraint contract reproduced in a disposable PG17 DB.
- Exact batch seed/publish twice, conflict rejection, 1,329 stored full/wrong/blank vectors, concurrent retry,
  changed payload rejection, independent resubmission, two-user isolation, lifecycle pending/erasing denial,
  old2,457 reference hash preservation, withdrawal with old results retained.
- The fixture includes minimal synthetic account-deletion dependency rows; it is **not a full Supabase
  production clone** and makes no claim about every unrelated app trigger/service.
- Production changes, end-to-end live submission and store release have not occurred.
