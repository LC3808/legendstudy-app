# 2024 grade-3 bounded dry run — 2026-09-20

Offline only, current parser/sample at starting HEAD `6474b4e`.
**7 exams / 151 occurrences / 299 resources**.
Four national mocks (3/5/7/10), two evaluation mocks (6/9), one CSAT (11).
All mappings provisional; all content/occurrence/resource is_active=false.

| Post | Family | Month | Occurrences | Resources | Feed date |
|---|---|---:|---:|---:|---|
| 1614 | national_mock | 3 | 17 | 34 | 2024-03-28 |
| 1617 | national_mock | 5 | 21 | 43 | 2024-05-09 |
| 1618 | evaluation_mock | 6 | 21 | 43 | 2024-06-15 |
| 1621 | national_mock | 7 | 21 | 42 | 2024-07-24 |
| 1634 | evaluation_mock | 9 | 26 | 46 | 2024-09-07 |
| 1646 | national_mock | 10 | 21 | 42 | 2024-10-18 |
| 1649 | csat | 11 | 24 | 49 | 2024-11-16 |

Types: `{'question': 149, 'answer_explanation': 146, 'listening_script': 4}`. Other, standalone answer/explanation and audio: 0.
The whole 2024 set has `{'question': 241, 'answer_explanation': 238, 'listening_script': 10}`. Zero observed audio is not proof of source
unavailability; no new crawling/download was done.

## Resource and subject completeness

`2024-grade3-batch.csv` lists every resource with raw filenames/keys, canonical
subject codes, source dates and unsigned locators. `2024-grade3-subject-pairing.csv`
contains all 151 raw occurrences, including those without question
or answer under that exact key. Pairing: {'QUESTION_ANSWER': 141, 'QUESTION_ONLY': 7, 'REVIEW_REQUIRED': 3}.
QUESTION_ANSWER only means both materials were observed, never publication-ready.
Missing pair halves need review; do not collapse elective/variant raw keys just
because their broad canonical subject matches. No forced historical remapping
was added; existing legacy/historical safety tests pass. Canonical mappings are
provisional rather than a human verification claim.

## Candidate quarantine

{'resource_url_expiring': 7, 'resource_subject_unknown': 3} = 10 cases, distinct from Production's 23 open rows.
Three ambiguous files stay NULL/unscoped; no guessed subject:

- Post 1618: `2025학년도 6월 s_생화활과윤리 정답,해설.pdf` — resource_subject_unknown.
- Post 1646: `2024년 10월 사탐_사회문화1 문제.pdf` — resource_subject_unknown.
- Post 1649: `2025학년도 수능_수학(미정) 정답,해설.pdf` — resource_subject_unknown.

All 299 grade-3 (all 489 in 2024) locators are Kakao identity-only URLs:
source_url unsigned, file_url NULL, link_kind unknown, link_status unchecked.
Code creates one expiration advisory per parsed post with the resource count;
that behavior does not establish a 1:1 relationship for Production's 23 cases.
Production source/quarantine joins must be read before making that assertion.
Box additions outside 2024 are landing pages, never asserted direct audio files.

Durability verdict: **NOT DOWNLOAD-READY**. Review durable/rights-approved open
targets or explicit safe source-page fallback before publication. Never retain
rolling signed queries, invent direct file endpoints, or silently drop resources.
The 3 medium-confidence posts are 1618/1646/1649; 4 others are high. A parser's
publishable flag is not the product publication gate.

## Feed and inactive gates

Generated `feed_updated_at = greatest(published_at, source_updated_at)`;
normalizer copies source clocks, resolver omits generated column. Sample parser
uses p when m is absent, never crawl time. Every 2024 feed date stays in 2024
under both 2026 and 2030 crawl timestamps. Source dates are date-only fixture
observations; future bounded source verification must preserve their provenance.
All projected new rows are inactive; no automatic publication.

## Conditional actions / transaction and retry contract

Without exact Production keys, INSERT/UPDATE/NOOP/CONFLICT are UNVERIFIED.
All-absent, no-collision scenario only:

| Table | Conditional INSERT |
|---|---:|
| source_posts | 7 |
| content_items | 7 |
| exams | 7 |
| exam_subjects | 151 |
| resources | 299 |
| ingestion_quarantine | 10 |

QUARANTINE is 10 planned cases, not confirmed new DB rows. Under that scenario
only, UPDATE/NOOP/CONFLICT would be zero. Actual mutations in this task: zero.
Existing writer is INSERT-only, deterministic IDs and ON CONFLICT DO NOTHING;
canonical batch uses one transaction with expected-count validation and rollback
on exception. Quarantine has its own subsequent transaction (canonical rollback
is not a guarantee of persisted quarantine evidence). Partial existing states
fail closed; verified mappings are not overwritten. Existing offline tests cover
repeat NOOP, quarantine repeat, mid-write rollback and partial-state refusal.
This does not prove a 2024 Production rerun: different existing UUIDs/natural
keys require explicit preflight. Pilot C CLI scope excludes 2024; do not bypass
it or repurpose its fixed counts.

## Search / future Viewer

Search uses page size 24 and max offset 10,000 (plus lookahead), not unbounded
fetching. Benchmark year/grade/subject filters, deep pages and facets on realistic
historical volumes before expansion; no performance changes now. Inactive rows
remain hidden; any later activation retains source-time Home ordering.

Future separate Viewer Pilot: recent three years' grade-3 June/September
national evaluation mocks and CSAT; 2024 reference posts 1618/1634/1649. This
inventory supports that planning, not rights/availability approval. No PDF
fetching, Storage mirror, viewer implementation or file migration occurred.
