# Subjects Taxonomy v1

Status: **designed, seed package prepared, NOT applied.** Owner applies the
seed; automated ingestion never creates or edits a `subjects` row.

## Owner decisions this implements

- Modern attachment access: option **(a)** — production carries searchable
  metadata; a modern kakaocdn signed URL is not treated as a permanent PDF
  link. Actual reading goes to the original legendstudy.com post opened in the
  external browser. WebView stays forbidden. No Supabase Storage mirror.
- Production pilot **C** approved: 2025–2026, all grades.
- `subjects` taxonomy is seeded **before** the pilot.
- The ~1,400 legacy posts are deferred.
- The 36 raw tokens found in the Day 9-B dry-run are **not** turned into 36
  subjects.

## Why not one subject per raw token

Three pieces of existing contract decide this, not preference.

1. **The schema already separates taxonomy from occurrence.** `exam_subjects`
   carries `source_subject_key` and `raw_subject_label` per paper, and
   `UNIQUE(content_item_id, source_subject_key)` — `database.md` states this is
   deliberately not keyed on `subject_id` so that "separate raw occurrences
   cannot collapse into one broad mapping". A 선택과목 variant is therefore a
   property of the paper, and the taxonomy row is the 영역/과목.
2. **Day 9-A's 과목 filter is flat.** `supabase_search_repository.dart` resolves
   an exact public subject name to a set of ids and then tests
   `subjectIds.contains(o['subject_id'])`. There is no parent expansion, and
   `day-9-search-explore.md` lists hierarchical taxonomy UX as LATER. If
   `국어(언매)` became its own subject, a 국어 filter would miss two thirds of
   the 국어 papers in the pilot.
3. **The measured distribution says which tokens are variants.** Over the 609
   dry-run occurrences: 사회 / 과학 / 사회탐구 / 과학탐구 occur **only at grade 1**
   and 통합사회 / 통합과학 at grades 1–2 — the site's spellings of one combined
   paper. 물리학 / 화학 / 생명과학 / 지구과학 without a numeral occur **only at
   grade 2**. 국어(…) and 수학(…) occur **only at grade 3**. None of these is a
   separate subject; each is a spelling or a scope of an existing one.

Conversely the nine 사회탐구 and eight 과학탐구 details **are** separate
subjects: a student's 응시 과목 is 생활과윤리, not "사회탐구". They stay distinct.

## Shape

- `taxonomy_version = 'v1'` — the LegendStudy taxonomy release id.
  `database.md` requires released meaning to be immutable, so a semantic change
  becomes `v2` rather than an edit. `subjects` already keys on
  `UNIQUE(taxonomy_version, code)`, and `exam_subjects` links through the
  composite `(subject_id, taxonomy_version)` MATCH FULL FK, so versions coexist.
- `curriculum_version = NULL`. The pilot spans a curriculum transition and no
  post states which curriculum its paper follows. Asserting one would be an
  invention; the column stays free for a later reviewed release.
- `parent_id = NULL` on every v1 row. `category` already carries the grouping
  as a **public** column (공통 / 통합 / 사회탐구 / 과학탐구) and costs no extra
  rows. Leaving the parent FK unused keeps a hierarchical v2 possible without
  re-releasing v1 meaning, and avoids seeding rows the flat filter would have
  to hide.
- `is_active = true` on all 23 rows. A subject master row is not user content;
  the publication gate applies to `content_items` / `exam_subjects` /
  `resources`, which the pilot plans as `is_active=false`.
- `sort_order` follows 수능 영역 order and is spaced by 10 so a later release
  can insert without renumbering.

### Deterministic identity

`subjects.id` defaults to `gen_random_uuid()`, which would produce different
ids on a re-seed. The seed therefore supplies the id explicitly:

```
NAMESPACE = uuid5(NAMESPACE_URL, 'https://legendstudy.com/taxonomy')
id        = uuid5(NAMESPACE, f'{taxonomy_version}:{code}')
```

`uuid5('v1:korean')` is `9ae14424-dad0-593c-bf7e-96dca10e719f` on every machine
and every run, and is asserted in `tool/test_ingestion.py`. This needs **no
schema change**: `id` is an ordinary insertable column. A v2 row for the same
code gets a different id because the version is part of the name, which is
exactly what the composite FK expects.

## Taxonomy v1 — 23 subjects

| code | name | category | sort |
|---|---|---|---|
| `korean` | 국어 | 공통 | 10 |
| `math` | 수학 | 공통 | 20 |
| `english` | 영어 | 공통 | 30 |
| `korean_history` | 한국사 | 공통 | 40 |
| `integrated_social` | 통합사회 | 통합 | 50 |
| `integrated_science` | 통합과학 | 통합 | 60 |
| `life_ethics` | 생활과 윤리 | 사회탐구 | 110 |
| `ethics_thought` | 윤리와 사상 | 사회탐구 | 120 |
| `korean_geography` | 한국지리 | 사회탐구 | 130 |
| `world_geography` | 세계지리 | 사회탐구 | 140 |
| `east_asian_history` | 동아시아사 | 사회탐구 | 150 |
| `world_history` | 세계사 | 사회탐구 | 160 |
| `economics` | 경제 | 사회탐구 | 170 |
| `politics_law` | 정치와 법 | 사회탐구 | 180 |
| `society_culture` | 사회·문화 | 사회탐구 | 190 |
| `physics_1` | 물리학Ⅰ | 과학탐구 | 210 |
| `chemistry_1` | 화학Ⅰ | 과학탐구 | 220 |
| `life_science_1` | 생명과학Ⅰ | 과학탐구 | 230 |
| `earth_science_1` | 지구과학Ⅰ | 과학탐구 | 240 |
| `physics_2` | 물리학Ⅱ | 과학탐구 | 250 |
| `chemistry_2` | 화학Ⅱ | 과학탐구 | 260 |
| `life_science_2` | 생명과학Ⅱ | 과학탐구 | 270 |
| `earth_science_2` | 지구과학Ⅱ | 과학탐구 | 280 |

Names use the official printed forms: the space in 생활과 윤리 / 윤리와 사상 /
정치와 법, the interpunct in 사회·문화, and the Roman numeral in 물리학Ⅰ. The
source writes all of these without the space or with an Arabic numeral, which
is why those raw spellings are aliases rather than names. A UI follow-up is
recorded below for typed input.

## Raw → canonical mapping

Every occurrence is planned `mapping_status='provisional'` with a confidence.
`verified` is never produced by automated ingestion — a human promotes a row,
and `ingestion.md` forbids ingestion from touching a verified row at all.

| confidence | meaning |
|---|---|
| 1.000 | raw token is exactly the canonical name |
| 0.950 | documented source spelling of the same subject |
| 0.800 | resolved only with the grade of the sitting |

### Pilot C — all 32 raw tokens, all resolved

| raw token | canonical | code | 구분 | conf | 학년 | n |
|---|---|---|---|---|---|---|
| `영어` | 영어 | `english` | exact | 1.000 | 1,2,3 | 23 |
| `한국사` | 한국사 | `korean_history` | exact | 1.000 | 1,2,3 | 22 |
| `국어` | 국어 | `korean` | exact | 1.000 | 1,2,3 | 16 |
| `수학` | 수학 | `math` | exact | 1.000 | 1,2,3 | 16 |
| `경제` | 경제 | `economics` | exact | 1.000 | 2,3 | 15 |
| `동아시아사` | 동아시아사 | `east_asian_history` | exact | 1.000 | 2,3 | 15 |
| `세계사` | 세계사 | `world_history` | exact | 1.000 | 2,3 | 15 |
| `한국지리` | 한국지리 | `korean_geography` | exact | 1.000 | 2,3 | 15 |
| `세계지리` | 세계지리 | `world_geography` | exact | 1.000 | 2,3 | 14 |
| `생활과윤리` | 생활과 윤리 | `life_ethics` | alias (space) | 0.950 | 2,3 | 15 |
| `윤리와사상` | 윤리와 사상 | `ethics_thought` | alias (space) | 0.950 | 2,3 | 15 |
| `정치와법` | 정치와 법 | `politics_law` | alias (space) | 0.950 | 2,3 | 15 |
| `사회문화` | 사회·문화 | `society_culture` | alias (interpunct) | 0.950 | 2,3 | 15 |
| `물리학1` | 물리학Ⅰ | `physics_1` | alias (numeral) | 0.950 | 2,3 | 15 |
| `화학1` | 화학Ⅰ | `chemistry_1` | alias (numeral) | 0.950 | 2,3 | 15 |
| `생명과학1` | 생명과학Ⅰ | `life_science_1` | alias (numeral) | 0.950 | 2,3 | 15 |
| `지구과학1` | 지구과학Ⅰ | `earth_science_1` | alias (numeral) | 0.950 | 2,3 | 15 |
| `물리학2` | 물리학Ⅱ | `physics_2` | alias (numeral) | 0.950 | 3 | 9 |
| `화학2` | 화학Ⅱ | `chemistry_2` | alias (numeral) | 0.950 | 3 | 9 |
| `생명과학2` | 생명과학Ⅱ | `life_science_2` | alias (numeral) | 0.950 | 3 | 9 |
| `지구과학2` | 지구과학Ⅱ | `earth_science_2` | alias (numeral) | 0.950 | 3 | 9 |
| `국어(화작)` | 국어 | `korean` | 선택과목 variant | 0.950 | 3 | 8 |
| `국어(언매)` | 국어 | `korean` | 선택과목 variant | 0.950 | 3 | 8 |
| `수학(확통)` | 수학 | `math` | 선택과목 variant | 0.950 | 3 | 8 |
| `수학(미적)` | 수학 | `math` | 선택과목 variant | 0.950 | 3 | 8 |
| `수학(기하)` | 수학 | `math` | 선택과목 variant | 0.950 | 3 | 8 |
| `통합사회` | 통합사회 | `integrated_social` | exact | 1.000 | 1,2 | 5 |
| `통합과학` | 통합과학 | `integrated_science` | exact | 1.000 | 1,2 | 4 |
| `과학` | 통합과학 | `integrated_science` | alias (grade 1) | 0.950 | 1 | 3 |
| `사회` | 통합사회 | `integrated_social` | alias (grade 1) | 0.950 | 1 | 2 |
| `과학탐구` | 통합과학 | `integrated_science` | alias (grade 1) | 0.950 | 1 | 1 |
| `사회탐구` | 통합사회 | `integrated_social` | alias (grade 1) | 0.950 | 1 | 1 |

**363 / 363 occurrences mapped provisional. 0 unmapped, 0 ambiguous, 0
taxonomy gaps.** 160 exact, 203 alias, 0 grade-inferred. All 23 v1 subjects are
used by the pilot, so the seed contains no dead row.

### Beyond the pilot

The wider 38-post dry-run adds four tokens the pilot does not contain —
`물리학`, `화학`, `생명과학`, `지구과학` at grade 2, 11 occurrences — resolved to
the Ⅰ subject at confidence 0.800 because the grade decides it. They are listed
here so the tier is exercised and reviewable, not because the pilot needs them.

### Never auto-mapped

`수학 가형/나형`, `국사`, `한국근현대사`, `법과사회`, `법과정치`, `경제지리`,
`윤리`, `물리1/2`, `생물1/2` stay `unmapped` with the raw label preserved.
`ingestion.md` requires that 가형/나형 never become modern electives, and
`법과정치` → `정치와 법` is a curriculum change, not a spelling. These belong to
the deferred legacy release.

## Seed package

`supabase/seed/subjects_taxonomy_v1.sql`, generated by

```
python3 tool/ingest_legendstudy.py --emit-subjects-seed supabase/seed/subjects_taxonomy_v1.sql
```

and asserted byte-identical to the module by `tool/test_ingestion.py`, so a
stale committed seed fails the suite.

The statement is one `INSERT … ON CONFLICT (taxonomy_version, code) DO
NOTHING` inside a transaction. It contains no `UPDATE` and no `DELETE`, so a
rerun is a no-op and **an existing released row can never be edited by it** —
which is the concrete form of "automated ingestion must not overwrite verified
mappings" at the taxonomy level. Expected: 23 rows on a clean run, 0 on a rerun.

No schema change, no migration, no new column. The pilot needs only this data
seed.

## Follow-ups

- **UI (9-C or later).** Typed subject input is matched with `ILIKE name`, so
  `물리학1` does not resolve to `물리학Ⅰ` and `생활과윤리` does not resolve to
  `생활과 윤리`. The 과목 dropdown is unaffected because it lists the canonical
  names. A small input-normalisation step (fold Arabic↔Roman numerals, ignore
  spaces and the interpunct) closes it.
- **Hierarchy (LATER).** If a 영역 filter that expands to its details is ever
  wanted, `parent_id` is free and a `v2` release can add area rows without
  touching v1.
- **Promotion to `verified`.** A reviewed pass can raise the 203 alias rows;
  the ingestion pipeline is already forbidden from touching them afterwards.
