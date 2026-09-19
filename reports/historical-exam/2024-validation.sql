-- SELECT-only Owner evidence collection. Not executed by Codex.
-- Run before any future batch and again after it; save the two snapshots securely.
-- Include partial sources/content and all years: zero 2024 exams is insufficient.
select s.id, s.source, s.external_post_id, s.url
from public.source_posts s where s.source = 'legendstudy'
order by s.external_post_id;

select c.id, c.source_post_id, s.source, s.external_post_id,
       c.source_content_key, c.slug, c.content_type, c.is_active,
       c.published_at, c.source_updated_at, c.feed_updated_at,
       e.year, e.grade_level, e.exam_type, e.exam_month
from public.content_items c
join public.source_posts s on s.id = c.source_post_id
left join public.exams e on e.content_item_id = c.id
where s.source = 'legendstudy'
order by s.external_post_id, c.source_content_key;

select es.id, es.content_item_id, s.source, s.external_post_id,
       c.source_content_key, es.source_subject_key, es.raw_subject_label,
       es.subject_id, es.mapping_status, es.taxonomy_version, es.is_active
from public.exam_subjects es
join public.content_items c on c.id = es.content_item_id
join public.source_posts s on s.id = c.source_post_id
where s.source = 'legendstudy'
order by s.external_post_id, es.source_subject_key;

select r.id, r.content_item_id, r.source_post_id, r.exam_subject_id,
       s.source, s.external_post_id, c.source_content_key,
       rs.source as resource_source, rs.external_post_id as resource_post,
       r.source_resource_key, r.resource_type, r.link_kind, r.link_status,
       r.file_url is not null as has_file_url, r.is_active,
       (coalesce(r.source_url, '') || coalesce(r.file_url, ''))
         ~* '(credential|signature|expires)=' as has_signing_query
from public.resources r
join public.content_items c on c.id = r.content_item_id
join public.source_posts s on s.id = c.source_post_id
join public.source_posts rs on rs.id = r.source_post_id
where s.source = 'legendstudy' or rs.source = 'legendstudy'
order by s.external_post_id, r.source_resource_key;

-- One row per quarantine/content relationship; do not infer one case per exam.
-- No raw payload or URL credentials are selected.
select q.id, q.source_post_id, s.external_post_id, q.kind, q.status,
       q.payload ->> 'count' as resource_count,
       c.id as content_item_id, e.year, e.grade_level
from public.ingestion_quarantine q
left join public.source_posts s on s.id = q.source_post_id
left join public.content_items c on c.source_post_id = s.id
left join public.exams e on e.content_item_id = c.id
where s.source = 'legendstudy' and q.status = 'open'
order by q.id, c.id;

-- Independent counts avoid multiplying subject rows by resources.
select e.year, count(*) as exams,
       sum((select count(*) from public.exam_subjects es
            where es.content_item_id = e.content_item_id)) as occurrences,
       sum((select count(*) from public.resources r
            where r.content_item_id = e.content_item_id)) as resources
from public.exams e
where e.year between 2020 and extract(year from current_date)::integer
group by e.year order by e.year;

-- Batch clock/visibility gate: require source-date parity and inactive initial rows.
select s.external_post_id, c.published_at, c.source_updated_at, c.feed_updated_at,
       c.feed_updated_at is not distinct from
         greatest(c.published_at, c.source_updated_at) as source_clock_ok,
       c.is_active,
       (select count(*) from public.exam_subjects es
        where es.content_item_id = c.id and es.is_active) as active_occurrences,
       (select count(*) from public.resources r
        where r.content_item_id = c.id and r.is_active) as active_resources
from public.content_items c
join public.source_posts s on s.id = c.source_post_id
where s.source = 'legendstudy'
  and s.external_post_id in ('1614','1617','1618','1621','1634','1646','1649')
order by s.external_post_id;
