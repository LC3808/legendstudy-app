# Essay service contracts — local candidate, 2026-10-21

Owner authorizes local migration/implementation/tests only. No Production application,
Provider request, real Credit transaction, deployment or store build. Existing 97 exams,
382 questions, 150 private PDFs and 2,484 evidence links are not modified.

## Metadata contract

`20261021071701_essay_browse_metadata.sql`: `essay_browse_catalog(text)` is an explicit
metadata-only SECURITY DEFINER capability for anon/authenticated. Catalog scope is the
existing 42 verified identities from LAB public catalog. Existing non-null UUIDs are
pinned; otherwise slug AND official name must match. Unknown identity returns [].
Returns exam/question IDs, labels, year, kind and track/title; evaluationReady is always
false. Does not expose source URLs, paths, PDF, solution, scoring, evidence or student data.
Base table grants and RLS policies are unchanged. This is a bounded projection, not
service-role access from a browser. Existing reviewed/public draft path remains intact.

## Confirmed image contract

`20261021071702_essay_confirmed_math_input.sql`: nullable unique FK
`math_subproblems.essay_question_id` maps ONE existing essay answer unit to ONE Math
leaf. A question with subparts is not automatically split or assigned guessed IDs.
Same-exam relationship is checked at write and submission. Used leaf identity cannot
be remapped. No mapping rows are populated by this migration; separately reviewed
mapping/content readiness remains an activation prerequisite.

Existing submit and continuous-cycle RPC accept either text or
`{questionId,revision,mathInput:{attemptId,confirmedRunId}}`. Client text/storage fields
cannot accompany a Math reference. Existing lifecycle/admission/package/model gates
run first. Resolver requires owned attempt, matching canonical question/exam, latest
completed candidate, student-confirmed completed extraction, 1–6 PRESENT images with
contiguous positions and hashes. Copies ordered confirmed text (and existing typed
text for MIXED input) into immutable answer body; preserves attempt/run/leaf/artifact
references and order in snapshot. No Storage paths in snapshot.

Existing reserve/finish/Credit bodies unchanged. Exact key replay reuses frozen input,
including after later extraction retry. New submissions reject stale confirmation.
History reads existing journal snapshot. Existing runtime evaluation-type allowlist is
unchanged; mathematical evaluator activation is NOT implied by this input adapter.
Existing Math upload/confirmation UI remains the input authority; this change supplies
the submit consumer's typed confirmed-reference contract, not a new upload UI.

## Verification and scope

`tool/test_essay_service_contracts.py` reuses Unix-socket-only PG17 bootstrap, actual
canonical Math DDL and actual journal/API/cycle functions. Synthetic package/model
approval fixtures; no remote DSN or Provider. 19 local checks PASS: anonymous/auth
projection, base RLS unchanged, private resolver denied, ownership, six-image order,
seventh image, partial upload, immutable identity, client override, HOLD, replay,
one reservation, single local fixture consumption, History and guarded rollback.
These are local DB integration results, not live service E2E. Existing ordered upload,
partial retry, Math confirmation and history unit tests reused in LAB.

## Apply / rollback plan (separate Owner approval required)

1. Read-only preflight: current function definitions/ACL and Math schema vs canonical
   migration prerequisites; retain current run/table/policy fingerprints. Stop on drift.
2. Apply the two migrations in order using canonical APP migration authority. Each is
   transactional. No data backfill or activation. Re-running an already recorded
   migration is unnecessary; duplicate DDL aborts atomically, not duplicate records.
3. Verify fixed catalog identities (especially null-ID catalog entries), metadata only,
   normal-user private-data denial and existing counts/IDs/RLS fingerprint.
4. Deploy LAB only under separate approval; retain legacy reviewer fallback while RPC
   is absent. Verify actual browser query separately from API/DB verification.
5. `supabase/verification/essay_service_contracts/rollback.sql` restores prior submit
   bodies and removes new metadata/mapping contracts ONLY while unused. If any mapping
   or confirmed-input journal exists, rollback aborts; preserve all history and review
   forward fix. No cascade or student data deletion.

## Longitudinal preservation review

1. Raw confirmed text and immutable identity references preserved; no inferred facts.
2. Existing essay/Math/account IDs retained; no duplicate identity domain.
3. Append-only journal/rewrite/history reused; no overwrite of prior answers.
4. Existing lifecycle/authentication and owned attempt checks retained.
5. Learning input, evaluation output and billing decisions remain separate.
6. Existing private Storage/RLS/deletion path retained; no public raw documents.
7. No AI-derived score/insight persisted as source evidence or official criteria.
