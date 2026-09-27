-- READ-ONLY template. Execute under anon/authenticated so RLS hides inactive parents.
-- $1 = approved essay_exam_id. No text extraction, grading or rights authorization.
-- A missing role remains missing; generic answers never become model answers.
select m.role, m.resource_id, m.source_locator, m.official_source_url,
       r.content_item_id, r.title, r.resource_type, r.source_url,
       c.source_url as content_source_url, c.published_at as source_published_at,
       e.admission_year, e.id as essay_exam_id, e.exam_key,
       m.provenance, m.verification_status
from public.essay_exam_resources m
join public.essay_exams e on e.id = m.essay_exam_id
join public.universities u on u.id = e.university_id
join public.resources r on r.id = m.resource_id
join public.content_items c on c.id = r.content_item_id
where m.essay_exam_id = $1
  and e.is_active and e.verification_status = 'verified'
  and u.is_active and r.is_active and c.is_active
  and m.is_active and m.verification_status = 'verified'
  and m.provenance = 'official'
  and m.official_source_url is not null
  and (r.exam_subject_id is null or exists (
      select 1 from public.exam_subjects es
      where es.id = r.exam_subject_id and es.content_item_id = r.content_item_id
        and es.is_active))
order by m.role, m.resource_id;
