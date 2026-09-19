-- SELECT-only; prepared for Owner. Not executed by Codex.
-- Run under the same full-visibility SQL Editor role as the reported validation.
-- Every candidate returns a row even when no source/content exists.
with candidate(source, external_post_id, source_content_key) as (
  values
  ('legendstudy', '1616', 'main'),
  ('legendstudy', '1620', 'main'),
  ('legendstudy', '1636', 'main'),
  ('legendstudy', '1648', 'main'),
  ('legendstudy', '1615', 'main'),
  ('legendstudy', '1619', 'main'),
  ('legendstudy', '1635', 'main'),
  ('legendstudy', '1647', 'main'),
  ('legendstudy', '1614', 'main'),
  ('legendstudy', '1617', 'main'),
  ('legendstudy', '1618', 'main'),
  ('legendstudy', '1621', 'main'),
  ('legendstudy', '1634', 'main'),
  ('legendstudy', '1646', 'main'),
  ('legendstudy', '1649', 'main')
)
select k.source, k.external_post_id, k.source_content_key,
       s.id as existing_source_id, c.id as existing_content_id,
       c.content_type, c.is_active, e.year, e.grade_level, e.exam_type,
       (select count(*) from public.exam_subjects es
        where es.content_item_id=c.id) as existing_occurrences,
       (select count(*) from public.resources r
        where r.content_item_id=c.id) as existing_resources,
       (select count(*) from public.content_items ci
        where ci.source_post_id=s.id) as all_content_keys_on_source,
       (select count(*) from public.resources r
        where r.source_post_id=s.id) as resources_using_source_provenance,
       (select count(*) from public.source_posts other
        where other.url='https://legendstudy.com/' || k.external_post_id
          and (other.source,other.external_post_id) <>
              (k.source,k.external_post_id)) as foreign_identity_url_conflicts,
       (select count(*) from public.content_items other
        where other.slug='legendstudy-' || k.external_post_id || '-main'
          and (c.id is null or other.id <> c.id)) as foreign_identity_slug_conflicts
from candidate k
left join public.source_posts s
  on s.source=k.source and s.external_post_id=k.external_post_id
left join public.content_items c
  on c.source_post_id=s.id and c.source_content_key=k.source_content_key
left join public.exams e on e.content_item_id=c.id
order by k.external_post_id;
