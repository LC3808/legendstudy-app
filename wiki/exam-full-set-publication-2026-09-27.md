# Phase3 FULL_SET Production publication — 2026-09-27

Status: **Production apply/activation COMPLETE; Owner device spot-check pending.**

Owner approved exactly22 posts from HEAD `6ec893d`, in four sequential groups.
Each group independently passed fresh source/resource checks, unchanged FULL_SET
classification, scoped private preflight, then apply/activation and public checkpoint.
No later group started before the preceding checkpoint passed.

[Preflight baseline](exam-full-set-publication-preflight-2026-09-27.md) ·
[Inspectable publication result](../tool/ingestion/samples/exam-full-set-publication-2026-09-27.json)

## Group checkpoints

Table order below: source_posts / content_items / exams / exam_subjects / resources / ingestion_quarantine.

| Group | Approved post IDs | Planned = actual inserts | Total | Apply / activation / checkpoint | Active content / exams |
|---|---|---|---:|---|---|
|1|1480, 1481, 1494, 1497, 1499|5 / 5 / 5 / 52 / 111 / 5|183|PASS / PASS / PASS|56 / 38|
|2|1502, 1503, 1504, 1505, 1511|5 / 5 / 5 / 72 / 151 / 5|243|PASS / PASS / PASS|61 / 43|
|3|1512, 1514, 1515, 1523, 1524, 1609|6 / 6 / 6 / 58 / 126 / 6|208|PASS / PASS / PASS|67 / 49|
|4|1615, 1616, 1619, 1620, 1636, 1648|6 / 6 / 6 / 58 / 127 / 6|209|PASS / PASS / PASS|73 / 55|

Each private preflight had collision0, existing active0, existing inactive0,
planned update0 and noop0. Post-by-post actual insert counts matched the plan.
The unchanged `apply_pilot` inserts each post’s five canonical tables atomically
while inactive; existing `apply_quarantine` records advisory evidence in its
separate transaction. The unchanged `publish_scope` then activates content,
occurrences and resources atomically with affected-row guards. No new publication
path, blanket cleanup, deletion or deactivation was used.

Every checkpoint verified active canonical rows exactly, no scoped duplicate
exam identity/resource key, exam/subject/resource invariants, outside-scope six-table
row digests, FULL_SET coverage, public search/detail/resources/subject lists, grade
filters, published_at ordering and the existing Pilot4 + Batch1 twenty posts.

## Final delta and Production state

| Table | Inserted | Final canonical rows |
|---|---:|---:|
|source_posts|22|73|
|content_items|22|73|
|exams|22|55|
|exam_subjects|240|736|
|resources|515|1566|
|ingestion_quarantine|22|76|
|TOTAL|843|2579|

New active content22 / exams22. Final active content73 / exams55.
New active occurrences240 and resources515. All22 quarantine rows are the
previously reviewed `resource_url_expiring` advisory, not a new blocking hold.
Final read-only table counts confirm the exact scoped delta and unchanged baseline digests.

## Resource and App verification

- Fresh source and canonical plans unchanged22/22; FULL_SET preserved22/22.
- 515 unique new source_resource_keys; no scoped canonical duplicates or collisions.
- 240 question +240 answer_explanation PDFs pass the existing direct-open contract.
- All493 Kakao PDFs (including13 scripts) passed fresh bounded HTTP/PDF signature checks.
- Box22 returned GET200 with MP3 metadata; no full audio-playback claim.
- Owner explicitly accepted script13 + Box22 source fallback for this publication.
  Kinds, resolver, audio UX and signed-target persistence policy are unchanged.
- Actual public/guest App projections pass keyword/exam search, detail, occurrence
  lists and active resource embeddings. Grade filters expose exactly G1:13/G2:8/G3:1
  from this new scope; question/answer relationships match the fresh verified plans.
- Recent published_at DESC,id DESC still starts1712→1711→1710. Historical source
  publication timestamps remain unchanged; new imports are not stamped “recent”.
- Production resolver endpoint was not invoked, avoiding unrelated quota mutation;
  its observer/security/PDF contract ran locally against fresh delivery targets.
  Persisted public resource rows were separately compared exactly. Owner device
  PDF spot-check remains the final UX acceptance, not claimed completed here.

## Protected scope and remaining inventory

REVIEW35 and identity-review52 remain HOLD. Active1474/1447 are unchanged;
1431/1404 replacements were not attempted. This does not make the entire catalog
duplicate-free. 1710 A1 remains PENDING; accepted-state hash unchanged. Busan1593
guidebook remains separate and exact preserved. No source/archive deletion.

Remaining technical writer-ready inventory:171 = exam35 + university_essay127 +
study_material9 + education_column0. All35 remaining exams are canonical REVIEW,
not automatically publication-ready. No next batch is selected or authorized.

Owner iOS changes and pre-existing untracked files remain untouched/unstaged.
No schema, migration, classifier, registry, writer, resolver or Flutter code changes.

## Validation and closeout

- Python384 and resolver37 tests PASS before publication; native PostgreSQL25
  NOT_RUN because the prerequisite is unavailable. No Flutter tests: no UI/code edit.
- Same fresh source input/plan generation deterministic; exact DB and guest checks
  passed at all four checkpoints. No regression observed in executed checks.
- Diff/secret/Wiki handoff and protected-file hash checks performed before commit.

NEXT: **Owner device spot-check, then Phase3 publication closeout.**
No automatic subsequent publication, replacement, A1 reconciliation or resolver change.
