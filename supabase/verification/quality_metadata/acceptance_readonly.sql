-- Read-only privileged audit; output is aggregate-only. Does not apply RPC changes.
with candidate as (
select e.id evaluation_id,e.completed_at,jsonb_build_object(
 'version','quality-metadata-v1',
 'student_reference','qs1_'||pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
   'legendstudy:quality:subject:v1:'||a.student_id::text,'UTF8')),'hex'),
 'attempt_id',a.id,'lineage_id',case when root.id is not null then a.lineage_id end,
 'root_attempt_id',root.id,'predecessor_attempt_id',case when pa.id is not null then a.predecessor_id end,
 'prior_evaluation_id',case when pa.id is not null and prior.leaf_id=e.leaf_id then a.prior_evaluation_id end,
 'relationship_state',case when root.id is null then 'UNLINKED'
   when a.kind='INITIAL' and a.id=root.id then 'ROOT'
   when pa.id is not null and prior.leaf_id=e.leaf_id then 'LINKED' else 'UNLINKED' end,
 'problem_set_id',ps.id,'problem_id',p.id,'leaf_id',e.leaf_id,
 'problem_label',case when ps.label is not null and p.display_order is not null
   then ps.label||' · 문항 '||p.display_order::text end,
 'essay_type','math','exam_id',ex.id,'university_id',ex.university_id,
 'university_name',case when ex.verification_status='verified' and ex.verified_at is not null then u.name end,
 'academic_year',case when ex.verification_status='verified' and ex.verified_at is not null then ex.admission_year end,
 'exam_metadata_verified',coalesce(ex.verification_status='verified' and ex.verified_at is not null,false),
 'evaluation_profile_id',e.profile_id,'rubric_version',ep.rubric_version) quality_metadata from public.math_evaluations e
join public.math_attempts a on a.id=e.attempt_id
 left join public.math_attempts root on root.id=a.lineage_id and root.student_id=a.student_id
   and root.leaf_id=a.leaf_id and root.kind='INITIAL' and root.lineage_id=root.id
 left join public.math_evaluations prior on prior.id=a.prior_evaluation_id
 left join public.math_attempts pa on pa.id=prior.attempt_id and pa.id=a.predecessor_id
   and pa.student_id=a.student_id and pa.leaf_id=a.leaf_id and pa.lineage_id=a.lineage_id
 left join public.math_subproblems l on l.id=e.leaf_id
 left join public.math_problems p on p.id=l.problem_id
 left join public.math_problem_sets ps on ps.id=p.problem_set_id
 left join public.essay_exams ex on ex.id=ps.essay_exam_id
 left join public.universities u on u.id=ex.university_id
 left join public.math_evaluation_profiles ep on ep.id=e.profile_id where e.state='COMPLETED' order by e.completed_at desc,e.id desc
)
select count(*) evaluations,
 count(distinct quality_metadata->>'student_reference') pseudonymous_users,
 count(distinct quality_metadata->>'root_attempt_id') independent_lineages,
 count(*) filter(where quality_metadata->>'relationship_state'='ROOT') roots,
 count(*) filter(where quality_metadata->>'relationship_state'='LINKED') reevaluation_pairs,
 count(*) filter(where quality_metadata->>'relationship_state'='UNLINKED') unlinked,
 count(*) filter(where quality_metadata->>'university_name' is not null or quality_metadata->>'academic_year' is not null) verified_exam_labels,
 count(*) filter(where quality_metadata->>'prior_evaluation_id' is not null and not exists(
 select 1 from candidate p where p.evaluation_id::text=candidate.quality_metadata->>'prior_evaluation_id'
 and p.quality_metadata->>'student_reference'=candidate.quality_metadata->>'student_reference'
 and p.quality_metadata->>'root_attempt_id'=candidate.quality_metadata->>'root_attempt_id'
 and p.quality_metadata->>'leaf_id'=candidate.quality_metadata->>'leaf_id'
 and p.quality_metadata->>'rubric_version'=candidate.quality_metadata->>'rubric_version')) invalid_links from candidate;
