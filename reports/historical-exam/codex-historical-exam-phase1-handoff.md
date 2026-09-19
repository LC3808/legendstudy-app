# Historical Phase 1 handoff — revalidated 2026-09-20

**Phase 1-A1 inventory/reconciliation/bounded dry-run: COMPLETE.**
**2024 PUBLICATION READY: NO. Production exact-key status: UNVERIFIED.**
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
- Aggregate counts alone do not establish MATCH/INSERT/UPDATE/NOOP/CONFLICT.
  Source/partial-content collisions remain UNVERIFIED pending row-level evidence.

## Phase 1-A2 evidence update — 2026-09-20

Owner has executed `2024-validation.sql`: baseline 23/363/739 reconfirmed,
2024 exams absent. Final empty result only rules out content attached to the
seven grade-3 source identities, not bare sources/eight other candidates/global
collision guards. See [A2 report](2024-production-preflight.md). Full exact-key
preflight remains INCOMPLETE / UNVERIFIED; publication remains NO.

## Exact next step — preflight only

Owner runs `2024-preflight-probe.sql` on LegendStudy project
`stlhijzpjfgwwdgunlsd` and provides all 15 credential-free rows, plus relevant
first-four-SELECT outputs from `2024-validation.sql` if existing rows are found.
The SQL is SELECT-only and was NOT executed here. Compare natural keys using
`2024-candidate-keys.csv`, resolving Production parent IDs through their keys;
never assume candidate UUIDs equal Production UUIDs. Also check source URL and
content slug guards. Stop on unexpected mappings, partial rows or collisions.
Do not request or paste passwords/JWTs/keys. Use a secure local snapshot outside
Git for any expanded DB export.

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

## Viewer direction (future only)

Recent three years' grade-3 June/September evaluation mocks and CSAT are the
future In-App PDF Viewer Pilot candidate. The 2024 inventory covers reference
posts 1618/1634/1649. Identity/type data is usable for planning; availability,
rights, durable binary targets and approved storage architecture remain gates.
No PDF download, mirror, upload, viewer or migration has been implemented.

## Evidence files

- `2024-reconciliation.md`: drift replay, exact scope, limits and validation.
- `2024-resource-drift.csv`: 23 unique source-backed Box additions outside 2024.
- `2024-candidate-reconciliation.csv`, `2024-candidate-keys.csv`: 2024 facts/keys.
- `2024-grade3-dry-run.md`, `2024-grade3-batch.csv`: reviewable dry-run rows.
- `2024-grade3-subject-pairing.csv`: raw-key material pairing, not readiness.
- `2024-validation.sql`: executed by Owner; only summarized results supplied.
- `2024-production-preflight.md`, `2024-preflight-probe.sql`: A2 limits and next evidence.
