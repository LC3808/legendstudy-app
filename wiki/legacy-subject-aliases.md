# Legacy Subject Alias Foundation

Status: **minimum foundation implemented; historical ingestion is not started.**

This document separates source wording, released taxonomy, search aliases and
display wording before the deferred legacy archive (about 1,400 posts) is
ingested. It does not apply a Supabase migration or change the published 23
subject rows.

## Architecture

- `subjects` remains the bounded v1 canonical taxonomy. The filter list uses
  only these canonical rows; aliases do not create chips or subject rows.
- `exam_subjects.source_subject_key` and `raw_subject_label` remain the exact
  source value. The resolver never overwrites the raw value.
- `tool/ingestion/subjects.py` owns the deterministic vocabulary and exposes
  `resolve_legacy_subject()`. Its status is intentionally separate from the
  ingestion `mapping_status`: a useful search/display alias is not permission
  to create a verified mapping.
- The resolver accepts `year`, `curriculum_version` and `grade_level` as future
  context hooks. The current implementation does not use ambiguous context to
  promote a mapping.
- Flutter search folds only released full-name aliases to the canonical
  subject lookup. It does not widen the canonical filter list. Display labels
  may add a short, user-facing historical name in parentheses.

No `subject_aliases` table is needed for this minimum foundation. A later
reviewed historical release can move versioned, operational aliases to a
database table without changing the raw occurrence contract.

## Observed inventory

The checked-in Day 9 survey artifacts contain 36 distinct raw tokens:

`경제`, `과학`, `과학탐구`, `국어`, `국어(언매)`, `국어(화작)`, `동아시아사`,
`물리학`, `물리학1`, `물리학2`, `사회`, `사회문화`, `사회탐구`, `생명과학`,
`생명과학1`, `생명과학2`, `생활과윤리`, `세계사`, `세계지리`, `수학`,
`수학(기하)`, `수학(미적)`, `수학(확통)`, `영어`, `윤리와사상`, `정치와법`,
`지구과학`, `지구과학1`, `지구과학2`, `통합과학`, `통합사회`, `한국사`,
`한국지리`, `화학`, `화학1`, `화학2`.

The broader historical vocabulary also explicitly calls out `물리1/2`,
`생물/생물1/2`, `국사`, `한국근현대사`, `법과사회`, `법과정치`, `경제지리`,
`윤리`, and `수학 가형/나형`. These are not evidence that they mean a current
v1 elective.

## Resolution policy

### SAFE_ALIAS

Safe aliases are formatting-equivalent or observed full-name source spellings:

- `물리학1/Ⅰ`, `화학1/Ⅰ`, `생명과학1/Ⅰ`, `지구과학1/Ⅰ`
- the corresponding `2/Ⅱ` forms
- `생활과윤리` → 생활과 윤리
- `윤리와사상` → 윤리와 사상
- `정치와법` → 정치와 법
- `사회문화` → 사회·문화

The numeric forms are the observed source spellings in the Day 9 artifacts.
Whitespace, NFC, interpunct and Arabic/Roman numeral folding is formatting
normalization only; it does not infer a curriculum.

### REVIEW_REQUIRED

`물리1`, `물리2`, `생물`, `생물1`, and `생물2` remain unmapped until a reviewed
year/curriculum rule establishes their identity. Search does not turn these
ambiguous labels into a modern subject filter.

### HISTORICAL_DISTINCT

`수학 가형`, `수학 나형`, `국사`, `한국근현대사`, `법과사회`, `법과정치`,
`경제지리`, and `윤리` remain separate historical identities. In particular,
가형/나형 is never converted to 미적분/기하, and 법과정치 is not silently
converted to current 정치와 법.

Unknown labels are retained as raw text and remain `UNKNOWN` to the resolver.

## Search and display

Typed search for an observed full-name alias such as `물리학1` resolves the
canonical `물리학Ⅰ` subject ID, so modern mapped occurrences are found without
adding an alias filter. The same applies to the other SAFE_ALIAS entries.
`물리1` and `생물1` remain ordinary raw-text searches until review; this avoids
returning unrelated modern material from an ambiguous historical token.

The filter menu remains canonical and bounded to 23 subjects. Resource group
display may show:

- `물리학Ⅰ (물리Ⅰ)` / `물리학Ⅱ (물리Ⅱ)`
- `생명과학Ⅰ (생물Ⅰ)` / `생명과학Ⅱ (생물Ⅱ)`

No alias creates a new database row or filter chip.

## Historical ingestion contract

For a future legacy run:

```
raw label → formatting resolver → candidate/status → year/curriculum review
           → SAFE_ALIAS provisional mapping only
           → REVIEW_REQUIRED / HISTORICAL_DISTINCT quarantine or hold
```

Raw labels remain on every occurrence. Automated ingestion never creates a
`verified` mapping. A reviewed historical taxonomy should be a new version
(`v2` or a dedicated historical release), not a silent edit of v1.

## Deferred work

- Inventory the legacy posts by year and curriculum before approving any
  REVIEW_REQUIRED token.
- Define historical taxonomy/version rows and reviewer evidence.
- Decide whether operational, versioned aliases justify a future
  `subject_aliases` table.
- Add a reviewed resolver pass to the quarantine workflow; do not bulk-ingest
  the archive as part of this foundation.

