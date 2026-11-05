begin read only;
select math_private.release_catalog('25dc068b-4672-56e1-b8df-08ee8800e2f6'::uuid) as konkuk_four,math_private.release_catalog('0a331c3e-d46b-5af3-b787-e3342e8a1ae8'::uuid) as kyunghee_three;
select count(*) as released_total from jsonb_array_elements(math_private.release_catalog(null));
select l.id,l.essay_question_id,p.state problem_state,s.state set_state,ep.state profile_state from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id join public.math_evaluation_profiles ep on ep.leaf_id=l.id where l.id in ('11b0d01b-c247-54a5-88b5-368440f68c6f'::uuid,'6b655a53-7b90-5f83-aed4-58a7d3cbeaae'::uuid,'746b66ff-064c-5498-9cf7-7c44067909c1'::uuid,'9caa0c67-a6d8-59c8-b5d6-68a24d7f3e5a'::uuid,'873c9757-2fcb-515f-b611-c78545d7a838'::uuid,'9552766f-0785-54f6-86d4-c8c70c5da1b8'::uuid);
rollback;
