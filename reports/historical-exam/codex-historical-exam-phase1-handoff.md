# Codex Handoff — Historical Exam Phase 1

Status: **NOT READY — blocked on Production read-only coverage query**

## 1. Current Production coverage

Unknown. The required SELECT-only query could not be authenticated. Do not
use the historical Wiki's old cleanup or Pilot C reports as current coverage.

## 2. Exact source locations

- Schema and year semantics: `supabase/migrations/20260912000100_initial_content_schema.sql`
- Ingestion contracts: `wiki/ingestion.md`, `tool/ingestion/`
- Candidate posts: `tool/ingestion/samples/day9b_exam_posts.jsonl`
- Candidate dry-run: `tool/ingestion/samples/dryrun-2026-09-15/`
- Taxonomy and alias rules: `tool/ingestion/taxonomy.py`, `tool/ingestion/subjects.py`, `wiki/legacy-subject-aliases.md`

## 3. External discovery needed

After Production counts are known, discover only gaps for 2020–2023 and any
2024–current missing family/grade/resource combinations. Do not mass crawl or
download before a bounded batch is approved. Preserve raw source labels and
separate calendar year from academic year.

## 4. Risks and contracts

- Historical subject labels and elective structures must not be silently
  remapped; quarantine ambiguous mappings.
- Use the deterministic keys in the inventory report; never use title, array
  position or signed URL query strings as identity.
- `SOURCE_UNAVAILABLE`, `REVIEW_REQUIRED`, `QUESTION_ONLY` and
  `QUESTION_ANSWER` must be distinguished from a true missing resource.
- Rights/source readiness, evaluation readiness and publication readiness are
  separate gates.

## 5. Recommended first ingestion batch

After the SELECT postflight, start with one year × grade × exam-family batch.
Recommended first candidate is 2024 grade 3 national/evaluation mock data,
because it is represented in the existing dry-run and exercises mixed exam
families, subject aliases and answer/explanation resources. Validate and
quarantine the batch before any publication. Do not ingest all years at once.

## 6. Validation SQL — read-only

Run on the exact LegendStudy Production project:

```sql
select 'exams' as relation, count(*) as rows,
       min(year) as min_year, max(year) as max_year
from public.exams
where year between 2020 and extract(year from current_date)::smallint
union all
select 'exam_subjects', count(*), null, null
from public.exam_subjects es
join public.exams e on e.content_item_id = es.content_item_id
where e.year between 2020 and extract(year from current_date)::smallint
union all
select 'resources', count(*), null, null
from public.resources r
join public.exams e on e.content_item_id = r.content_item_id
where e.year between 2020 and extract(year from current_date)::smallint;

select e.year, e.grade_level, e.exam_type, e.exam_month,
       count(distinct e.content_item_id) as exams,
       count(distinct es.id) as exam_subjects,
       count(distinct r.id) as resources
from public.exams e
left join public.exam_subjects es on es.content_item_id = e.content_item_id
left join public.resources r on r.content_item_id = e.content_item_id
where e.year between 2020 and extract(year from current_date)::smallint
group by e.year, e.grade_level, e.exam_type, e.exam_month
order by e.year, e.grade_level, e.exam_month, e.exam_type;

select e.year, e.grade_level, e.exam_type,
       coalesce(es.raw_subject_label, es.source_subject_key) as raw_subject,
       r.resource_type, count(*) as rows
from public.exams e
left join public.exam_subjects es on es.content_item_id = e.content_item_id
left join public.resources r on r.content_item_id = e.content_item_id
where e.year between 2020 and extract(year from current_date)::smallint
group by e.year, e.grade_level, e.exam_type,
         coalesce(es.raw_subject_label, es.source_subject_key), r.resource_type
order by e.year, e.grade_level, raw_subject, r.resource_type;
```

## 7. Publication gate and rollback

Publication requires a reviewed source inventory, deterministic-key duplicate
check, taxonomy review, resource-link review, quarantine resolution, bounded
postflight and explicit Owner approval. Use the existing batch transaction and
exact deterministic IDs. If a batch is rejected, rollback only that batch's
identified IDs in dependency order; never broad-delete by year or title.

## 8. Product impact

Historical rows must not flood Home Recent Updates. The current source-time
`feed_updated_at` contract is correct only if old source publication/update
timestamps are preserved and ingestion time is not substituted. Search should
be benchmarked as the dataset grows; Recent Views needs no historical-ingestion
change.
