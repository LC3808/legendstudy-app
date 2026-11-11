# Task03 — mixed-v2 LOCAL candidate

**Not applied / not approved for production. No real answer/cutoff seeds.**
Owner forbids production DB/RPC changes and store submission for this task.

Existing `mcq5-v1`, attempt/RPC identity, retry locks, RLS and version immutability
remain. New engine accepts one MCQ choice (1–5) or one integer (0–999), multiple
accepted official answers, and an explicit all-credit flag. Blank remains null.
All-credit awards points even to a blank; the blank input is still recorded.
Only reviewed READY keys can newly publish. Existing published v1 keys retain
their earlier publication/verification guard and derived READY availability;
no historic source digest or attempt is rewritten. PARTIAL is review progress,
not permission to offer a subset of a paper as a complete scored paper.

## Isolated verification

`python3 tool/test_task03_scoring_v2.py` provisions a disposable PostgreSQL17
cluster over a private Unix socket with TCP disabled. It loads only original
content/scoring migrations and synthetic users/papers. It has no DSN argument,
reads no production credential, and stops/removes the cluster afterward.

- v1 attempt created before candidate: existing attempt JSON identical after;
  existing answer fields/results unchanged (additive nullable columns excluded).
- Shared `synthetic_vectors.json`: Dart and SQL mixed/all-credit/blank/zero/999,
  confirmed/estimated grade handling. No raw-to-standard conversions.
- READY publication, unpublished RLS, immutable keys, ownership, retry conflict,
  invalid answer ranges, stale new request, historical retry.
- Existing timer/local persistence remain in Flutter regression suite.

This is an initial-schema integration test, **not a full production clone test**.
PostgreSQL17+ is required for stored-generated-column SET EXPRESSION. Production
version, later triggers and grants must be compared before any future approval.

## Future application preflight (not executed)

1. Compare live definitions/grants/triggers for all affected objects to the
   candidate; do not replace a more recent function blindly. Confirm PG17+.
2. Export schema plus counted/digested answer keys, questions, attempts, answers
   and cutoff versions; verify reference IDs and existing owner RLS. Record
   available disk/lock budget: generated-column changes may rewrite answer rows.
3. Validate official source package with `tool/validate_task03_scoring_package.py`;
   separately inspect source documents, corrections, points and elective mapping.
   A checklist/digest is not a substitute for actual source review. Candidate
   OCR files are never suitable input. Preserve question IDs across corrected keys.
4. Test against a sanitized schema clone with all later migrations, test roles,
   old/new clients and concurrent retries. Review application/rollback with Owner.
5. Only after explicit approval, use one transaction for candidate SQL; do not
   seed or publish automatically. Review each immutable data version separately.

## Rollback / stop

Before commit, transaction ROLLBACK restores everything. After application, stop
new mixed-v2 submissions by setting **only the newly introduced reviewed key IDs**
`is_current=false` (or withdraw them), and return to the previous app. Identical
historic retries continue returning the saved original result. Preserve typed
attempts, keys, audit evidence and IDs. Do not drop new columns, erase numeric
answers, reinterpret them as MCQ or bulk demote all keys. A structural reverse
migration requires checking no typed attempts exist and its own approval; it is
not provided as an unsafe generic DROP script. No Auth/Credit/Ledger/payment changes.

## Data contract

See [Task03 contract and preservation review](../../../wiki/task03-mixed-scoring-20261111.md).
Question UUIDs are additive: legacy records are not backfilled with invented IDs.
Academic context snapshot and cross-attempt wrong-answer queries remain a reviewed
future contract, not a newly deployed notebook API. No notebook UI/subscription.

## TASK03-A follow-up — local only

Official all-credit papers exposed `correct_count + unanswered_count > question_count`
for otherwise perfect attempts with the all-credit question blank. The candidate now keeps
both individual bounds and the legacy mcq5-v1 disjoint bound; mixed-v2 exact counts remain
validated by the deferred snapshot consistency trigger. No production application occurred.
Do not restore the old disjoint bound while mixed-v2 all-credit attempts exist.
[Official-data validation and rollout limits](../../../wiki/task03a-official-ready-20261111.md).
