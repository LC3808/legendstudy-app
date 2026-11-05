-- TASK19 candidate. Production requires Owner approval.
-- Companion to the existing raw-score grading versions, not a new exam Registry.
-- A reference may contain an estimated raw range and a differently sourced standard score.
create table public.grade_cutoff_references (
 id uuid primary key default gen_random_uuid(),
 content_item_id uuid not null,
 exam_subject_id uuid not null,
 elective_key text not null default '' check(length(elective_key)<=80),
 elective_label text not null default '' check(length(elective_label)<=80),
 grade smallint not null check(grade between 1 and 9),
 revision integer not null check(revision>0),
 is_current boolean not null default false,
 status text not null default 'draft' check(status in ('draft','published','withdrawn')),
 raw_score smallint check(raw_score between 0 and 100),
 raw_score_min smallint check(raw_score_min between 0 and 100),
 raw_score_max smallint check(raw_score_max between 0 and 100),
 standard_score smallint check(standard_score between 0 and 200),
 percentile numeric check(percentile between 0 and 100),
 assessment_method text not null check(assessment_method in ('absolute','relative')),
 raw_certainty text not null check(raw_certainty in ('confirmed','estimated','unspecified')),
 standard_certainty text not null check(standard_certainty in ('confirmed','estimated','unspecified')),
 source_url text not null check(source_url like 'https://%'),
 raw_source_url text check(raw_source_url like 'https://%'),
 standard_source_url text check(standard_source_url like 'https://%'),
 source_digest text not null check(source_digest ~ '^[0-9a-f]{64}$'),
 source_name text not null,
 fetched_at timestamptz not null,
 verified_at timestamptz,
 created_at timestamptz not null default now(),
 correction_note text,
 foreign key(exam_subject_id,content_item_id) references public.exam_subjects(id,content_item_id) on delete restrict,
 unique(content_item_id,exam_subject_id,elective_key,grade,revision),
 check((raw_score_min is null)=(raw_score_max is null)),
 check(raw_score_min<=raw_score_max),
 check(raw_score is null or raw_score_min is null),
 check(not is_current or status='published'),
 check(status<>'published' or verified_at is not null),
 check((raw_score is null and raw_score_min is null) or raw_source_url is not null),
 check(standard_score is null or standard_source_url is not null)
);
create unique index grade_cutoff_references_current on public.grade_cutoff_references(content_item_id,exam_subject_id,elective_key,grade) where is_current;
alter table public.grade_cutoff_references enable row level security;
revoke all on public.grade_cutoff_references from public,anon,authenticated;
-- Public callers use only the scoped read RPC; underlying tables remain private.
create function public.guard_grade_cutoff_reference() returns trigger language plpgsql set search_path='' as $$
begin
 if old.status in ('published','withdrawn') then
  if tg_op='DELETE' then raise exception 'Published cutoff evidence is immutable'; end if;
  if (to_jsonb(old)-'is_current'-'status') is distinct from (to_jsonb(new)-'is_current'-'status')
    or new.status not in ('published','withdrawn') then
   raise exception 'Publish a new revision instead of rewriting cutoff evidence';
  end if;
 end if;
 if tg_op='DELETE' then return old; end if;
 return new;
end $$;
revoke all on function public.guard_grade_cutoff_reference() from public,anon,authenticated;
create trigger grade_cutoff_reference_immutable before update or delete on public.grade_cutoff_references for each row execute function public.guard_grade_cutoff_reference();
create function public.grade_cutoff_lookup(p_content_item_id uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(to_jsonb(r) || jsonb_build_object(
  'academic_year',e.academic_year,'exam_month',e.exam_month,'institute','한국교육과정평가원',
  'subject_id',s.subject_id,'subject_label',s.raw_subject_label)
  order by s.display_order,r.elective_key,r.grade),'[]'::jsonb)
 from public.grade_cutoff_references r join public.exams e on e.content_item_id=r.content_item_id
 join public.exam_subjects s on s.id=r.exam_subject_id and s.is_active
 join public.content_items c on c.id=r.content_item_id and c.is_active
 where r.content_item_id=p_content_item_id and r.is_current and r.status='published' and r.verified_at is not null
 and e.grade_level=3 and e.exam_type in ('evaluation_mock','csat');
$$;
revoke all on function public.grade_cutoff_lookup(uuid) from public;
grant execute on function public.grade_cutoff_lookup(uuid) to anon,authenticated;
