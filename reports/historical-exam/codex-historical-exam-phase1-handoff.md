# Historical Phase 1 handoff — revalidated 2026-09-20

**Phase 1-A1 inventory/reconciliation/bounded dry-run: COMPLETE.**
**Phase 1-A2 structural preflight COMPLETE (Owner probe scope).**
**2024 PUBLICATION READY: NO. No observed candidate natural-key/provenance overlap.**
Starting HEAD `6474b4e`. This supersedes the interrupted September 18 run;
its temporary output was neither available nor accepted as evidence.

## Evidence

- Current sample: 38 exams / 609 occurrences / 1,228 resources. Original
  1,205-resource artifact remains a dated snapshot. Exact 23-row expansion
  explained and replayed in `2024-reconciliation.md` / `2024-resource-drift.csv`.
- 2024: 15 exams / 246 occurrences / 489 resources. Grade 1/2/3: 4/4/7.
- First bounded reference: grade 3, posts 1614/1617/1618/1621/1634/1646/1649;
  7 exams / 151 occurrences / 299 resources / 10 planned quarantine cases.
- All planned rows inactive; mappings provisional. Raw labels preserved.
  Three resources remain unscoped for human review; no guessed correction.
- Owner Production baseline: 2020–2024 0/0/0; 2025 15/246/507;
  2026 8/117/232; total 23/363/739. 23 open expiration cases are not assumed
  to map one-to-one to exams. Future/unpublished 2026 sessions are not missing.
- Subsequent Owner 15-row probe found no candidate source/content/provenance
  overlap and zero exact canonical foreign URL/slug conflicts. This is scoped
  natural-key evidence, not semantic/file verification or publication approval.

## Phase 1-A2 evidence update — 2026-09-20

Owner executed both SELECT packages. Baseline remains 23/363/739 with no 2024
exams. The first final empty query covered only seven grade-3 content parents.
The later `2024-preflight-probe.sql` returned all 15 candidates: source/content
IDs NULL; all occurrence/resource/content-key/provenance and exact foreign
canonical URL/slug conflict counts zero. **A2 structural preflight COMPLETE**
within that scope. See [A2 report](2024-production-preflight.md) for all fields,
parent-absence reasoning, exact-string limits and independent publication gates.
The earlier A1 CSV UNVERIFIED fields remain historical snapshot evidence.

## Exact next step — semantic/quarantine/file validation only

Owner confirms meaning or HOLD for the three ambiguous files (1618/1646/1649).
Review raw subject pairings and actual linked-file/type/availability evidence in
an explicitly bounded follow-up. All 10 grade-3 candidate quarantine cases remain
unresolved; mappings provisional; initial rows inactive. No semantic decision is
automatically inferred from the clean identity probe. No publication approval.
Recheck structural preflight and exact write-manifest guards before any future
separately authorized write; preserve existing 2025/2026 data. No credentials or
raw signed URLs in reports, no downloads/mirroring/viewer implementation here.

## Future controlled procedure — separate authorization/task

1. **Preflight:** fresh baseline/key comparison, source-date provenance,
   active flags, taxonomy presence, raw variant review, URL durability/rights
   review. Resolve ambiguous files from 1618/1646/1649. Review all raw-key
   incomplete pairs in `2024-grade3-subject-pairing.csv`.
2. **Backup/reference snapshot:** capture exact preexisting natural keys, IDs,
   row values/active and verified states, counts and Home top-feed ordering.
   Keep Owner backup outside Git; hash the reviewed candidate manifest.
3. **Controlled inactive ingestion:** design/review a dedicated 2024 scope;
   current Pilot C CLI gates exclude this year. No bypass of guards or reuse of
   Pilot C fixed expected counts. Canonical batch transaction, exact expected
   deltas, fail closed on error/partial state; quarantine separately idempotent.
   Only an explicitly all-absent reference would yield 7/7/7/151/299 canonical
   inserts and 10 quarantine inserts. Actual actions require step 1.
4. **Postflight:** rerun SELECT snapshots, compare exact keys and semantic
   values, ensure no baseline rows changed; zero active new rows; source clocks,
   signing-query absence, counts and raw-label preservation. Verify quarantine
   separately if its transaction fails. A failed canonical transaction must
   leave zero canonical deltas; do not assume quarantine was persisted.
5. **Search acceptance:** initial inactive batch must remain invisible. A later
   separately authorized publication must verify year/grade/family/subject/
   resource filters, details, scoped-resource counts and safe opening behavior.
   Benchmark page size 24, offset limit 10,000, facets and deep filtered pages
   with representative historical volume; no refactor was done here.
6. **Home acceptance:** inactive batch leaves feed unchanged. Later activation
   must retain source dates (2024 in current fixtures), never crawl/ingestion
   time. Review genuine later source updates rather than rewriting dates.
7. **Rollback criteria:** wrong delta/identity/visibility/mapping/feed/URL,
   partial apply or changed preexisting rows stops further work. Before commit,
   transaction rollback; after commit, Owner-reviewed exact inserted-ID rollback
   in dependency order from the snapshot, preserving existing data and mappings.
   No broad year/title deletion, no automatic retry/repair of partial state.

Ingestion and public activation are separate decisions. No mutation SQL is
provided or executed in this task. Production mutation = 0; no credentials,
Auth/Storage/Edge/Cron changes, live downloads, publication, or push.

## Pilot product refinement — independent engine and Viewer tracks

Recent three years' grade-3 June/September evaluation mocks and CSAT remain the
Pilot; 2024 reference posts are 1618/1634/1649. Core success is validated Exam
identity → Answer entry → Submission → Server scoring → Grade → Academic Record,
not perfect rendering of every PDF. Paper-first users need no Viewer to attempt.
Semantic/key/subject/cutoff gates remain binding for the engine. URL/file cases
remain unresolved, but inability to deliver PDFs alone is not an answer-only
engine blocker. Rights still gate mirrors/Storage/access; no quarantine resolution
or publication is implied. Viewer memory/rights/availability acceptance is separate.
See [canonical architecture](../../wiki/architecture-in-app-exam.md). No download,
mirror, Storage or Viewer implementation has occurred.

## Evidence files

- `2024-reconciliation.md`: drift replay, exact scope, limits and validation.
- `2024-resource-drift.csv`: 23 unique source-backed Box additions outside 2024.
- `2024-candidate-reconciliation.csv`, `2024-candidate-keys.csv`: 2024 facts/keys.
- `2024-grade3-dry-run.md`, `2024-grade3-batch.csv`: reviewable dry-run rows.
- `2024-grade3-subject-pairing.csv`: raw-key material pairing, not readiness.
- `2024-validation.sql`: executed by Owner; only summarized results supplied.
- `2024-production-preflight.md`, `2024-preflight-probe.sql`: A2 limits and next evidence.
