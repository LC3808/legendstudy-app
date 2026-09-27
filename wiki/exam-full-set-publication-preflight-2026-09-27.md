# Exam FULL_SET Phase3 publication preflight — 2026-09-27

Status: **Historical preflight PASS.** Subsequent Owner approval and
[Production publication closeout](exam-full-set-publication-2026-09-27.md) supersede
the pending gate below; this document preserves the original read-only result.

Starting HEAD `82fac2d`; branch `codex/day-7-school-neis`, local/origin matched.
Exactly the22 Phase3 FULL_SET candidates were freshly read. All22 remain FULL_SET;
REVIEW/partial downgrades0, semantic source/resource/plan changes0. This is a
publication proposal, not authority to apply or activate.

[Inspectable result artifact](../tool/ingestion/samples/exam-full-set-publication-preflight-2026-09-27.json)
contains per-post source timestamps/hash, identity, named expected/actual papers,
coverage reasons, all515 stable resource keys and HTTP/contract results, scoped DB
counts, preservation digests and proposed groups. No signed delivery URLs are stored.

## Fresh identity and coverage

Existing crawler/parser/normalizer, Phase3 registry/classifier and controlled writer
were reused without code changes. Each fresh resolved canonical plan matches the
previous plan across content/exam/occurrences/resources/quarantine. Exam year, grade,
nominal month and family also match the registry identity. Source published_at is
preserved in full; no inference from a sitemap/modified timestamp.

| Post | Exam (calendar year / grade / nominal month) | Organizer | Source date assertion | Subjects / resources | Result |
|---|---|---|---|---|---|
|[1480](https://legendstudy.com/1480)|2021 / G2 / 3|SEOUL|2021-03-24|17 / 36|FULL_SET|
|[1481](https://legendstudy.com/1481)|2021 / G1 / 3|SEOUL|2021-03-23|6 / 14|FULL_SET|
|[1494](https://legendstudy.com/1494)|2021 / G1 / 11|GYEONGGI|none; registry reference|6 / 13|FULL_SET|
|[1497](https://legendstudy.com/1497)|2022 / G1 / 3|SEOUL|none; registry reference|6 / 13|FULL_SET|
|[1499](https://legendstudy.com/1499)|2022 / G2 / 6|BUSAN|2022-06-09|17 / 35|FULL_SET|
|[1502](https://legendstudy.com/1502)|2022 / G3 / 7|INCHEON|2022-07-06|26 / 53|FULL_SET|
|[1503](https://legendstudy.com/1503)|2022 / G1 / 9|INCHEON|2022-08-31|6 / 13|FULL_SET|
|[1504](https://legendstudy.com/1504)|2022 / G2 / 9|INCHEON|2022-08-31|17 / 35|FULL_SET|
|[1505](https://legendstudy.com/1505)|2022 / G1 / 11|GYEONGGI|2022-11-23|6 / 14|FULL_SET|
|[1511](https://legendstudy.com/1511)|2023 / G2 / 3|SEOUL|2023-03-23|17 / 36|FULL_SET|
|[1512](https://legendstudy.com/1512)|2023 / G1 / 3|SEOUL|2023-03-23|6 / 14|FULL_SET|
|[1514](https://legendstudy.com/1514)|2023 / G1 / 6|BUSAN|2023-06-01|6 / 13|FULL_SET|
|[1515](https://legendstudy.com/1515)|2023 / G2 / 6|BUSAN|2023-06-01|17 / 35|FULL_SET|
|[1523](https://legendstudy.com/1523)|2023 / G1 / 9|INCHEON|none; registry reference|6 / 14|FULL_SET|
|[1524](https://legendstudy.com/1524)|2023 / G2 / 9|INCHEON|2023-09-06|17 / 36|FULL_SET|
|[1609](https://legendstudy.com/1609)|2023 / G1 / 11|GYEONGGI|2023-12-19|6 / 14|FULL_SET|
|[1615](https://legendstudy.com/1615)|2024 / G2 / 3|SEOUL|2024-03-28|17 / 36|FULL_SET|
|[1616](https://legendstudy.com/1616)|2024 / G1 / 3|SEOUL|2024-03-28|6 / 14|FULL_SET|
|[1619](https://legendstudy.com/1619)|2024 / G2 / 6|BUSAN|none; registry reference|17 / 36|FULL_SET|
|[1620](https://legendstudy.com/1620)|2024 / G1 / 6|BUSAN|none; registry reference|6 / 14|FULL_SET|
|[1636](https://legendstudy.com/1636)|2024 / G1 / 9|INCHEON|2024-09-04|6 / 13|FULL_SET|
|[1648](https://legendstudy.com/1648)|2024 / G1 / 10|GYEONGGI|none; registry reference|6 / 14|FULL_SET|

1609 retains nominal November2023 and December19 administration evidence; writer
normalization_note retains that distinction. 1503/1504 are nominal September2022,
August31 administration. Neither creates a new identity from the actual month.
All22 are education-office national_mock exams. G1:13, G2:8, G3:1 (1502).
No KICE/CSAT candidate was added. Required named papers and historical taxonomy
are exact registry entries; extra vocational/foreign/Hanmun domains are not
invented. 1502 retains evidence for the expected Korean/math elective bundles.

## Resource delivery and App limits

- 515 unique resource keys; cross-post/per-post duplicates0.
- 240 question +240 answer_explanation resources: all480 pass existing PDF kind,
  fresh observer identity, signed-target allowlist and PDF evidence contract.
- 13 listening_script PDFs also return206 and `%PDF-`, but the existing resolver
  intentionally excludes this kind. They retain source fallback; no type coercion.
- All493 Kakao PDFs passed bounded Range GET (206 + PDF signature). Delivery
  targets remain ephemeral; canonical source URLs are unsigned and file_url NULL.
- 22 Box listening links: HEAD404 was misleading; bounded GET200 with MP3 metadata
  verified all22 landing pages. Audio playback/download itself was NOT_RUN.
  Box is outside the PDF resolver contract and uses the existing source fallback.
- Production resolver endpoint was not called: it consumes quota and could write.
  Existing production observer/security/isPdfEvidence modules ran locally instead.
- No new device open claim. Server link evidence does not replace Owner device QA.

Coverage and resource delivery both pass within the current contract. Owner should
accept the existing35 fallback resources (13 scripts +22 audio), or require a
separate resolver UX task before publication. No resolver change is included here.

## Private Production preflight

Pinned LegendStudy project, transaction_read_only=on. Existing scoped preflight
SQL plus writer preflight SELECT checks were reused. No writer apply or activation
path was invoked. All planned rows are absent; natural exam identity checks pass.

| Table | Planned | Potential insert | Noop | Collision | Inactive | Active | Update |
|---|---:|---:|---:|---:|---:|---:|---:|
|source_posts|22|22|0|0|0|0|0|
|content_items|22|22|0|0|0|0|0|
|exams|22|22|0|0|0|0|0|
|exam_subjects|240|240|0|0|0|0|0|
|resources|515|515|0|0|0|0|0|
|ingestion_quarantine|22|22|0|0|0|0|0|
|TOTAL|843|843|0|0|0|0|0|

22 quarantine rows are the existing advisory `resource_url_expiring`, one per post;
no blocking quarantine/identity hold entered scope. No signing material is written.

Production baseline remains source51/content51/exam33/subjects496/resources1051/
quarantine54. Full six-table row digests match before/after. Existing Pilot4 +
Batch1 twenty posts passed exact active canonical comparison and public App
search/detail/resource queries. Active content remains51. Recent ordering by
original published_at DESC,id DESC still starts1712→1711→1710.

## Proposed bounded publication

515 resources is3.28× prior Batch1(157);843 total rows is2.98× its283. Prefer four
groups capped at that already-tested resource count, preserving whole posts and
chronological order. The resulting5/5/6/6 post counts are consequences of resource
weight, not arbitrary post limits. No apply/activation approval has been granted.

| Proposal | Post IDs | Resources | Total insert rows |
|---|---|---:|---:|
|1|1480, 1481, 1494, 1497, 1499|111|183|
|2|1502, 1503, 1504, 1505, 1511|151|243|
|3|1512, 1514, 1515, 1523, 1524, 1609|126|208|
|4|1615, 1616, 1619, 1620, 1636, 1648|127|209|

Approval should name the exact group(s), accept or address the fallback limitation,
and require a fresh source/resource recheck + private preflight immediately before
write. Execute/verify one post at a time through the existing writer and activation
paths, checkpoint between groups and stop on any delta. A failed group must not
lead to blanket deletion/rollback of user-referenced content.

## App impact and protected scopes

Existing exam search filters grade_level and active content; proposed G1/G2/G3
counts13/8/1 therefore route to the corresponding grade filters after separately
approved activation. They are currently absent, not publicly searchable yet.
No automatic canonical ranking/filter was added. Existing active partial1474/1447
will remain visible until their separately approved replacements; this preflight
does not claim the whole App catalog is already duplicate-free.

Essay/classroom/request/archive policies remain unchanged. REVIEW35 and identity52
remain HOLD. Both replacement pairs are excluded;1710 A1 remains pending; Busan1593
guidebook remains separate. Accepted-state is unchanged. No Flutter, schema, parser,
classifier, writer, Personalization/Onboarding/School/Profile/D-Day code changed.

## Validation and handoff

- Available Python suite384 PASS (includes registry40, Phase1/2 classifier33 and
  ingestion190); native PostgreSQL25 NOT_RUN, prerequisite unavailable.
- Resolver contract37 PASS. Initial local-server sandbox and Deno read-permission
  failures resolved by rerunning with the required test permissions; no code fix.
- Same fresh input repeats identical audit output; duplicate-key/identity checks PASS.
- Public and private existing24-post regression PASS; no new regression observed.
- Diff/secret/Wiki handoff checks run before commit. Flutter tests NOT_RUN, no UI edit.
- Owner iOS files and existing untracked files remain untouched and unstaged.

PRODUCTION_MUTATION/APPLY/ACTIVATION/DEACTIVATION/DELETE/MIGRATION: **NO**.
ACCEPTED_STATE_CHANGED: **NO**.

NEXT: **Owner/ChatGPT publication approval gate. STOP.**
