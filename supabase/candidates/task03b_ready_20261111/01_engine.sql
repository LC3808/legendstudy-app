-- LOCAL CANDIDATE ONLY. Not approved for production. No exam data or publication.
-- Requires the existing scoring schema; preserves mcq5-v1 and versioned results.
begin;
set local lock_timeout='5s';
do $guard$ begin
if current_setting('server_version_num')::int < 170000 then raise exception 'TASK03B_PG17_REQUIRED'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_cutoffs_valid(smallint[],integer)'))) is distinct from 'fe6cb8d1f897dd99835e6e7aa564f92c' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_cutoffs_valid(smallint[],integer)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_cutoffs_valid(smallint[],integer)')) is distinct from '["postgres=X/postgres", "service_role=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_cutoffs_valid(smallint[],integer)'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_text(text,integer)'))) is distinct from '2f41cd23b1551dc45c1c124a3ee1ea99' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_text(text,integer)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_text(text,integer)')) is distinct from '["postgres=X/postgres", "service_role=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_text(text,integer)'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_source_url(text)'))) is distinct from 'eebd591d254d6a3fd9973ae5a915fc92' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_source_url(text)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_source_url(text)')) is distinct from '["postgres=X/postgres", "service_role=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_source_url(text)'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_answer_guard()'))) is distinct from 'bd1763a58680d8b7ee0cb3adbf320809' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_answer_guard()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_answer_guard()')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_answer_guard()'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_normalize_answers(jsonb,integer)'))) is distinct from '8ed9a92191521d1138ca0b7382e32202' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_normalize_answers(jsonb,integer)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_normalize_answers(jsonb,integer)')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_normalize_answers(jsonb,integer)'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_mcq5(jsonb,jsonb,smallint[],text)'))) is distinct from '684f35cbe7389a1cee473e0a558a2234' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_mcq5(jsonb,jsonb,smallint[],text)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_mcq5(jsonb,jsonb,smallint[],text)')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_mcq5(jsonb,jsonb,smallint[],text)'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_question_guard()'))) is distinct from 'ba11dd39c73af83ec8419d821bc7b85e' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_question_guard()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_question_guard()')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_question_guard()'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_publication_guard()'))) is distinct from '48fb47fd23ae2a171ca208f99bb6ec3e' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_publication_guard()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_publication_guard()')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_publication_guard()'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_attempt_guard()'))) is distinct from '1553a4ca46d68421e3c716e0667b56ea' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_attempt_guard()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_attempt_guard()')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_attempt_guard()'; end if;
if md5(pg_get_functiondef(to_regprocedure('scoring_attempt_consistency()'))) is distinct from '0083bf0a5fc5f7272161a1c2168e22bb' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','scoring_attempt_consistency()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('scoring_attempt_consistency()')) is distinct from '["postgres=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','scoring_attempt_consistency()'; end if;
if md5(pg_get_functiondef(to_regprocedure('submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb)'))) is distinct from '06f52fd93a0f2cc68e18ce99f5959165' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb)')) is distinct from '["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb)'; end if;
if md5(pg_get_functiondef(to_regprocedure('guard_grade_cutoff_reference()'))) is distinct from '97d33ee55426c5ebcd8c13d6748edeb3' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','guard_grade_cutoff_reference()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('guard_grade_cutoff_reference()')) is distinct from '["postgres=X/postgres", "service_role=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','guard_grade_cutoff_reference()'; end if;
if md5(pg_get_functiondef(to_regprocedure('grade_cutoff_lookup(uuid)'))) is distinct from '47c0193fcc719a412c28041686999b96' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','grade_cutoff_lookup(uuid)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('grade_cutoff_lookup(uuid)')) is distinct from '["postgres=X/postgres", "anon=X/postgres", "authenticated=X/postgres", "service_role=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','grade_cutoff_lookup(uuid)'; end if;
if md5(pg_get_functiondef(to_regprocedure('account_private.lock_subject(uuid)'))) is distinct from 'e48a7203c22b570c80e65ed51a7d20c9' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','account_private.lock_subject(uuid)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('account_private.lock_subject(uuid)')) is distinct from '["postgres=X/postgres", "essay_executor=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','account_private.lock_subject(uuid)'; end if;
if md5(pg_get_functiondef(to_regprocedure('account_private.allowed(uuid)'))) is distinct from '5bb28e0026f17746239e4369a772a5ce' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','account_private.allowed(uuid)'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('account_private.allowed(uuid)')) is distinct from '["postgres=X/postgres", "essay_executor=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','account_private.allowed(uuid)'; end if;
if md5(pg_get_functiondef(to_regprocedure('account_service_allowed()'))) is distinct from '4bc4e4ef8067186bbfb20e6460070cd7' then raise exception 'TASK03B_LIVE_FUNCTION_DRIFT: %','account_service_allowed()'; end if;
if (select to_jsonb(proacl) from pg_proc where oid=to_regprocedure('account_service_allowed()')) is distinct from '["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb then raise exception 'TASK03B_LIVE_ACL_DRIFT: %','account_service_allowed()'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_content_digest_check') is distinct from 'CHECK ((content_digest ~ ''^[0-9a-f]{64}$''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_content_digest_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_corrected_at_check') is distinct from 'CHECK (isfinite(corrected_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_corrected_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_correction') is distinct from 'CHECK ((((corrected_at IS NULL) AND (correction_note IS NULL)) OR ((corrected_at IS NOT NULL) AND (correction_note IS NOT NULL) AND scoring_text(correction_note, 1000))))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_correction'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_created_at_check') is distinct from 'CHECK (isfinite(created_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_created_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_current') is distinct from 'CHECK (((NOT is_current) OR (status = ''published''::text)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_current'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_draft_revision_check') is distinct from 'CHECK ((draft_revision >= 0))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_draft_revision_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_family') is distinct from 'UNIQUE (exam_subject_id, paper_variant, version)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_family'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_fetched_at_check') is distinct from 'CHECK (isfinite(fetched_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_fetched_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_max_score_check') is distinct from 'CHECK (((max_score >= 1) AND (max_score <= 1000)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_max_score_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_paper_variant_check') is distinct from 'CHECK (scoring_text(paper_variant, 80))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_paper_variant_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_parent') is distinct from 'FOREIGN KEY (exam_subject_id, content_item_id) REFERENCES exam_subjects(id, content_item_id) ON DELETE RESTRICT' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_parent'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_pkey') is distinct from 'PRIMARY KEY (id)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_pkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_points_source') is distinct from 'CHECK ((((points_source_name IS NULL) AND (points_source_url IS NULL) AND (points_source_digest IS NULL)) OR ((points_source_name IS NOT NULL) AND (points_source_url IS NOT NULL) AND (points_source_digest IS NOT NULL) AND scoring_text(points_source_name, 200) AND scoring_source_url(points_source_url) AND (points_source_digest ~ ''^[0-9a-f]{64}$''::text))))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_points_source'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_publication') is distinct from 'CHECK ((((status = ''draft''::text) AND (published_at IS NULL) AND (content_digest IS NULL)) OR ((status = ANY (ARRAY[''published''::text, ''withdrawn''::text])) AND (verified_at IS NOT NULL) AND (published_at IS NOT NULL) AND (content_digest IS NOT NULL) AND (fetched_at <= verified_at) AND (verified_at <= published_at))))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_publication'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_published_at_check') is distinct from 'CHECK (isfinite(published_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_published_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_question_count_check') is distinct from 'CHECK (((question_count >= 1) AND (question_count <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_question_count_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_scope') is distinct from 'UNIQUE (id, exam_subject_id, paper_variant, max_score)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_scope'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_source_digest_check') is distinct from 'CHECK ((source_digest ~ ''^[0-9a-f]{64}$''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_source_digest_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_source_name_check') is distinct from 'CHECK (scoring_text(source_name, 200))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_source_name_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_source_url_check') is distinct from 'CHECK (scoring_source_url(source_url))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_source_url_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_status_check') is distinct from 'CHECK ((status = ANY (ARRAY[''draft''::text, ''published''::text, ''withdrawn''::text])))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_status_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_verified_at_check') is distinct from 'CHECK (isfinite(verified_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_verified_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.answer_key_versions') and conname='answer_key_versions_version_check') is distinct from 'CHECK ((version > 0))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','answer_key_versions_version_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.exam_questions') and conname='exam_questions_answer_key_version_id_fkey') is distinct from 'FOREIGN KEY (answer_key_version_id) REFERENCES answer_key_versions(id) ON DELETE RESTRICT' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','exam_questions_answer_key_version_id_fkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.exam_questions') and conname='exam_questions_answer_type_check') is distinct from 'CHECK ((answer_type = ''multiple_choice''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','exam_questions_answer_type_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.exam_questions') and conname='exam_questions_correct_answer_check') is distinct from 'CHECK (((correct_answer >= 1) AND (correct_answer <= 5)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','exam_questions_correct_answer_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.exam_questions') and conname='exam_questions_pkey') is distinct from 'PRIMARY KEY (answer_key_version_id, question_number)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','exam_questions_pkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.exam_questions') and conname='exam_questions_points_check') is distinct from 'CHECK (((points >= 1) AND (points <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','exam_questions_points_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.exam_questions') and conname='exam_questions_question_number_check') is distinct from 'CHECK (((question_number >= 1) AND (question_number <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','exam_questions_question_number_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_check') is distinct from 'CHECK (((raw_score >= 0) AND (raw_score <= max_score)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_correct_count_check') is distinct from 'CHECK ((correct_count >= 0))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_correct_count_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_counts') is distinct from 'CHECK (((correct_count + unanswered_count) <= question_count))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_counts'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_created_at_check') is distinct from 'CHECK (isfinite(created_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_created_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_cutoff') is distinct from 'FOREIGN KEY (grade_cutoff_version_id, exam_subject_id, paper_variant, max_score) REFERENCES grade_cutoff_versions(id, exam_subject_id, paper_variant, max_score) ON DELETE RESTRICT' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_cutoff'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_grade') is distinct from 'CHECK ((((grade IS NULL) AND (grade_status = ''unavailable''::text) AND (grade_cutoff_version_id IS NULL)) OR ((grade IS NOT NULL) AND (grade_status = ANY (ARRAY[''estimated''::text, ''confirmed''::text])) AND (grade_cutoff_version_id IS NOT NULL))))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_grade'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_grade_check') is distinct from 'CHECK (((grade >= 1) AND (grade <= 9)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_grade_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_grade_status_check') is distinct from 'CHECK ((grade_status = ANY (ARRAY[''unavailable''::text, ''estimated''::text, ''confirmed''::text])))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_grade_status_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_id_key') is distinct from 'UNIQUE (id, answer_key_version_id)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_id_key'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_key') is distinct from 'FOREIGN KEY (answer_key_version_id, exam_subject_id, paper_variant, max_score) REFERENCES answer_key_versions(id, exam_subject_id, paper_variant, max_score) ON DELETE RESTRICT' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_key'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_max_score_check') is distinct from 'CHECK (((max_score >= 1) AND (max_score <= 1000)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_max_score_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_pkey') is distinct from 'PRIMARY KEY (id)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_pkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_question_count_check') is distinct from 'CHECK (((question_count >= 1) AND (question_count <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_question_count_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_request_payload_check') is distinct from 'CHECK ((jsonb_typeof(request_payload) = ''object''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_request_payload_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_scoring_version_check') is distinct from 'CHECK ((scoring_version = ''mcq5-v1''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_scoring_version_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_study') is distinct from 'FOREIGN KEY (study_session_id, user_id) REFERENCES study_sessions(id, user_id) ON DELETE SET NULL (study_session_id)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_study'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_study_session_id_key') is distinct from 'UNIQUE (study_session_id)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_study_session_id_key'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_submitted_at_check') is distinct from 'CHECK (isfinite(submitted_at))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_submitted_at_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_unanswered_count_check') is distinct from 'CHECK ((unanswered_count >= 0))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_unanswered_count_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='mock_exam_attempts_user_id_fkey') is distinct from 'FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_attempts_user_id_fkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_attempts') and conname='scoring_attempt_consistency') is distinct from 'TRIGGER DEFERRABLE INITIALLY DEFERRED' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','scoring_attempt_consistency'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='mock_exam_answers_attempt') is distinct from 'FOREIGN KEY (attempt_id, answer_key_version_id) REFERENCES mock_exam_attempts(id, answer_key_version_id) ON DELETE CASCADE' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_answers_attempt'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='mock_exam_answers_correct_answer_snapshot_check') is distinct from 'CHECK (((correct_answer_snapshot >= 1) AND (correct_answer_snapshot <= 5)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_answers_correct_answer_snapshot_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='mock_exam_answers_pkey') is distinct from 'PRIMARY KEY (attempt_id, question_number)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_answers_pkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='mock_exam_answers_points_snapshot_check') is distinct from 'CHECK (((points_snapshot >= 1) AND (points_snapshot <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_answers_points_snapshot_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='mock_exam_answers_question') is distinct from 'FOREIGN KEY (answer_key_version_id, question_number) REFERENCES exam_questions(answer_key_version_id, question_number) ON DELETE RESTRICT' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_answers_question'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='mock_exam_answers_submitted_answer_check') is distinct from 'CHECK (((submitted_answer >= 1) AND (submitted_answer <= 5)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','mock_exam_answers_submitted_answer_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.mock_exam_answers') and conname='scoring_answers_consistency') is distinct from 'TRIGGER DEFERRABLE INITIALLY DEFERRED' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','scoring_answers_consistency'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_assessment_method_check') is distinct from 'CHECK ((assessment_method = ANY (ARRAY[''absolute''::text, ''relative''::text])))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_assessment_method_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check') is distinct from 'CHECK (((raw_score_min IS NULL) = (raw_score_max IS NULL)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check1') is distinct from 'CHECK ((raw_score_min <= raw_score_max))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check1'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check2') is distinct from 'CHECK (((raw_score IS NULL) OR (raw_score_min IS NULL)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check2'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check3') is distinct from 'CHECK (((NOT is_current) OR (status = ''published''::text)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check3'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check4') is distinct from 'CHECK (((status <> ''published''::text) OR (verified_at IS NOT NULL)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check4'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check5') is distinct from 'CHECK ((((raw_score IS NULL) AND (raw_score_min IS NULL)) OR (raw_source_url IS NOT NULL)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check5'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_check6') is distinct from 'CHECK (((standard_score IS NULL) OR (standard_source_url IS NOT NULL)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_check6'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_content_item_id_exam_subject_id_ele_key') is distinct from 'UNIQUE (content_item_id, exam_subject_id, elective_key, grade, revision)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_content_item_id_exam_subject_id_ele_key'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_elective_key_check') is distinct from 'CHECK ((length(elective_key) <= 80))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_elective_key_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_elective_label_check') is distinct from 'CHECK ((length(elective_label) <= 80))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_elective_label_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_exam_subject_id_content_item_id_fkey') is distinct from 'FOREIGN KEY (exam_subject_id, content_item_id) REFERENCES exam_subjects(id, content_item_id) ON DELETE RESTRICT' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_exam_subject_id_content_item_id_fkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_grade_check') is distinct from 'CHECK (((grade >= 1) AND (grade <= 9)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_grade_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_percentile_check') is distinct from 'CHECK (((percentile >= (0)::numeric) AND (percentile <= (100)::numeric)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_percentile_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_pkey') is distinct from 'PRIMARY KEY (id)' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_pkey'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_raw_certainty_check') is distinct from 'CHECK ((raw_certainty = ANY (ARRAY[''confirmed''::text, ''estimated''::text, ''unspecified''::text])))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_raw_certainty_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_raw_score_check') is distinct from 'CHECK (((raw_score >= 0) AND (raw_score <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_raw_score_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_raw_score_max_check') is distinct from 'CHECK (((raw_score_max >= 0) AND (raw_score_max <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_raw_score_max_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_raw_score_min_check') is distinct from 'CHECK (((raw_score_min >= 0) AND (raw_score_min <= 100)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_raw_score_min_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_raw_source_url_check') is distinct from 'CHECK ((raw_source_url ~~ ''https://%''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_raw_source_url_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_revision_check') is distinct from 'CHECK ((revision > 0))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_revision_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_source_digest_check') is distinct from 'CHECK ((source_digest ~ ''^[0-9a-f]{64}$''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_source_digest_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_source_url_check') is distinct from 'CHECK ((source_url ~~ ''https://%''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_source_url_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_standard_certainty_check') is distinct from 'CHECK ((standard_certainty = ANY (ARRAY[''confirmed''::text, ''estimated''::text, ''unspecified''::text])))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_standard_certainty_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_standard_score_check') is distinct from 'CHECK (((standard_score >= 0) AND (standard_score <= 200)))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_standard_score_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_standard_source_url_check') is distinct from 'CHECK ((standard_source_url ~~ ''https://%''::text))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_standard_source_url_check'; end if;
if (select pg_get_constraintdef(oid) from pg_constraint where conrelid=to_regclass('public.grade_cutoff_references') and conname='grade_cutoff_references_status_check') is distinct from 'CHECK ((status = ANY (ARRAY[''draft''::text, ''published''::text, ''withdrawn''::text])))' then raise exception 'TASK03B_CONSTRAINT_DRIFT: %','grade_cutoff_references_status_check'; end if;
if not coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.answer_key_versions')),false) then raise exception 'TASK03B_RLS_DISABLED: %','answer_key_versions'; end if;
if not coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.exam_questions')),false) then raise exception 'TASK03B_RLS_DISABLED: %','exam_questions'; end if;
if not coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.grade_cutoff_versions')),false) then raise exception 'TASK03B_RLS_DISABLED: %','grade_cutoff_versions'; end if;
if not coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.mock_exam_attempts')),false) then raise exception 'TASK03B_RLS_DISABLED: %','mock_exam_attempts'; end if;
if not coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.mock_exam_answers')),false) then raise exception 'TASK03B_RLS_DISABLED: %','mock_exam_answers'; end if;
if not coalesce((select relrowsecurity from pg_class where oid=to_regclass('public.grade_cutoff_references')),false) then raise exception 'TASK03B_RLS_DISABLED: %','grade_cutoff_references'; end if;
end $guard$;

alter table public.answer_key_versions add column scoring_version text not null default 'mcq5-v1'
 check(scoring_version in ('mcq5-v1','mixed-v2'));
alter table public.answer_key_versions add column verification_status text not null default 'NOT_READY'
 check(verification_status in ('READY','PARTIAL','NOT_READY'));
alter table public.exam_questions drop constraint exam_questions_answer_type_check;
alter table public.exam_questions drop constraint exam_questions_correct_answer_check;
alter table public.exam_questions alter column correct_answer drop not null;
alter table public.exam_questions add column accepted_answers smallint[];
alter table public.exam_questions add column all_credit boolean not null default false;
alter table public.exam_questions add column question_id uuid;
alter table public.exam_questions add column unit text;
alter table public.exam_questions add column domain text;
alter table public.exam_questions add column item_type text;
create function public.scoring_typed_question_valid(t text, a smallint[], all_credit boolean)
returns boolean language plpgsql immutable security invoker set search_path='' as $$
declare v smallint;
begin
 if t is null or t not in ('multiple_choice','numeric') or a is null or all_credit is null then return false; end if;
 if all_credit then return cardinality(a)=0; end if;
 if cardinality(a) not between 1 and (case when t='multiple_choice' then 5 else 1000 end)
   or array_ndims(a)<>1 or array_lower(a,1)<>1
   or cardinality(a)<>(select count(distinct x) from unnest(a) x) then return false; end if;
 foreach v in array a loop
  if v is null or (t='multiple_choice' and v not between 1 and 5)
   or(t='numeric' and v not between 0 and 999) then return false; end if;
 end loop;
 return true;
end $$;
revoke all on function public.scoring_typed_question_valid(text,smallint[],boolean) from public,anon,authenticated;
grant execute on function public.scoring_typed_question_valid(text,smallint[],boolean) to service_role;
alter table public.exam_questions add constraint typed_question_valid check (
 (accepted_answers is null and answer_type='multiple_choice' and correct_answer between 1 and 5 and correct_answer is not null and not all_credit and question_id is null)
 or(accepted_answers is not null and correct_answer is null and question_id is not null and public.scoring_typed_question_valid(answer_type,accepted_answers,all_credit)));
create unique index exam_questions_version_identity on public.exam_questions(answer_key_version_id,question_id);
alter table public.mock_exam_answers drop constraint mock_exam_answers_submitted_answer_check;
alter table public.mock_exam_answers drop constraint mock_exam_answers_correct_answer_snapshot_check;
alter table public.mock_exam_answers alter column correct_answer_snapshot drop not null;
alter table public.mock_exam_answers add column answer_type text not null default 'multiple_choice';
alter table public.mock_exam_answers add column accepted_answers_snapshot smallint[];
alter table public.mock_exam_answers add column all_credit_snapshot boolean not null default false;
alter table public.mock_exam_answers add column question_id uuid;
alter table public.mock_exam_answers add column unit text;
alter table public.mock_exam_answers add column domain text;
alter table public.mock_exam_answers add column item_type text;
alter table public.mock_exam_answers add constraint typed_snapshot_valid check (
 (accepted_answers_snapshot is null and answer_type='multiple_choice' and correct_answer_snapshot between 1 and 5 and correct_answer_snapshot is not null and not all_credit_snapshot and question_id is null and (submitted_answer is null or submitted_answer between 1 and 5))
 or(accepted_answers_snapshot is not null and question_id is not null and public.scoring_typed_question_valid(answer_type,accepted_answers_snapshot,all_credit_snapshot)
 and correct_answer_snapshot is not distinct from case when cardinality(accepted_answers_snapshot)=1 then accepted_answers_snapshot[1] else null end
 and(submitted_answer is null or(answer_type='multiple_choice' and submitted_answer between 1 and 5)or(answer_type='numeric' and submitted_answer between 0 and 999))));
alter table public.mock_exam_answers alter column is_correct set expression as
 (all_credit_snapshot or coalesce(submitted_answer=any(accepted_answers_snapshot),submitted_answer=correct_answer_snapshot,false));
alter table public.mock_exam_answers alter column awarded_points set expression as
 (case when all_credit_snapshot or coalesce(submitted_answer=any(accepted_answers_snapshot),submitted_answer=correct_answer_snapshot,false) then points_snapshot else 0 end);
alter table public.mock_exam_attempts drop constraint mock_exam_attempts_scoring_version_check;
alter table public.mock_exam_attempts add constraint mock_exam_attempts_scoring_version_check check(scoring_version in ('mcq5-v1','mixed-v2'));
-- all-credit unanswered questions belong to BOTH counters. Preserve the actual
-- blank answer; the deferred consistency trigger recomputes both exact counts.
-- Legacy mcq5-v1 retains its disjoint-count invariant.
alter table public.mock_exam_attempts drop constraint mock_exam_attempts_counts;
alter table public.mock_exam_attempts add constraint mock_exam_attempts_counts check (
 correct_count <= question_count and unanswered_count <= question_count
 and (scoring_version='mixed-v2' or correct_count+unanswered_count <= question_count)
);

create function public.scoring_normalize_answers_v2(p_answers jsonb, p_count integer)
returns jsonb language plpgsql immutable security invoker set search_path = ''
as $$
declare item jsonb; n integer; c integer; seen integer[] := '{}';
  result jsonb;
begin
  if p_count is null or p_count not between 1 and 100 or p_answers is null
     or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
  if jsonb_array_length(p_answers) > p_count then
    raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
  select jsonb_agg('null'::jsonb) into result from generate_series(1,p_count);
  for item in select value from jsonb_array_elements(p_answers) loop
    if jsonb_typeof(item) <> 'object' then
      raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
    if not (item ? 'question_number' and item ? 'choice')
       or item - array['question_number','choice'] <> '{}'::jsonb
       or jsonb_typeof(item->'question_number') <> 'number'
       or (item->>'question_number') !~ '^[0-9]{1,3}$'
       or jsonb_typeof(item->'choice') not in ('number','null') then
      raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
    n := (item->>'question_number')::integer;
    if n not between 1 and p_count or n = any(seen) then
      raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
    seen := array_append(seen,n);
    if item->'choice' <> 'null'::jsonb then
      if (item->>'choice') !~ '^[0-9]{1,3}$' then
        raise exception 'INVALID_ANSWERS' using errcode='22023'; end if;
      c := (item->>'choice')::integer;
      result := jsonb_set(result,array[(n-1)::text],to_jsonb(c));
    end if;
  end loop;
  return result;
end;
$$;

create function public.scoring_mixed_v2(p_questions jsonb,p_answers jsonb,p_cutoffs smallint[],p_certainty text)
returns jsonb language plpgsql immutable security invoker set search_path='' as $$
declare q jsonb; i int:=0; v int; pts int; accepted smallint[]; ac boolean; ok boolean;
 raw int:=0; maximum int:=0; correct_n int:=0; wrong jsonb:='[]'; blank jsonb:='[]'; grade int; ids text[]:='{}';
begin
 if jsonb_typeof(p_questions) is distinct from 'array' or jsonb_typeof(p_answers) is distinct from 'array'
 or jsonb_array_length(p_questions) not between 1 and 100 or jsonb_array_length(p_answers)<>jsonb_array_length(p_questions) then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
 for q in select value from jsonb_array_elements(p_questions) loop
  i:=i+1;
  if jsonb_typeof(q) is distinct from 'object' or q->>'question_number' is distinct from i::text
   or jsonb_typeof(q->'points') is distinct from 'number' or q->>'points' !~ '^[0-9]{1,3}$'
   or jsonb_typeof(q->'accepted_answers') is distinct from 'array' or jsonb_typeof(q->'all_credit') is distinct from 'boolean'
   or jsonb_typeof(q->'question_id') is distinct from 'string' or length(q->>'question_id')=0 or q->>'question_id'=any(ids)
   then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  ids:=array_append(ids,q->>'question_id');
  if exists(select 1 from jsonb_array_elements(q->'accepted_answers') a where jsonb_typeof(a)<>'number' or a::text !~ '^[0-9]{1,3}$') then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  select coalesce(array_agg(a::text::smallint),'{}') into accepted from jsonb_array_elements(q->'accepted_answers') a;
  ac:=(q->>'all_credit')::boolean; pts:=(q->>'points')::int;
  if pts not between 1 and 100 or not public.scoring_typed_question_valid(q->>'answer_type',accepted,ac) then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  v:=null;
  if p_answers->(i-1)='null'::jsonb then blank:=blank||to_jsonb(i);
  else
   if jsonb_typeof(p_answers->(i-1))<>'number' or p_answers->>(i-1) !~ '^[0-9]{1,3}$' then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
   v:=(p_answers->>(i-1))::int;
   if (q->>'answer_type'='multiple_choice' and v not between 1 and 5) or(v not between 0 and 999) then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023'; end if;
  end if;
  ok:=ac or coalesce(v=any(accepted),false); maximum:=maximum+pts;
  if ok then raw:=raw+pts;correct_n:=correct_n+1; elsif v is not null then wrong:=wrong||to_jsonb(i);end if;
 end loop;
 if maximum>1000 then raise exception 'INVALID_ENGINE_INPUT' using errcode='22023';end if;
 if p_cutoffs is null then
  if p_certainty is distinct from 'unavailable' then raise exception 'INVALID_GRADE_INPUT' using errcode='22023';end if;
 else
  if not public.scoring_cutoffs_valid(p_cutoffs,maximum) or p_certainty is null or p_certainty not in('confirmed','estimated') then raise exception 'INVALID_GRADE_INPUT' using errcode='22023';end if;
  for i in 1..9 loop if raw>=p_cutoffs[i] then grade:=i;exit;end if;end loop;
 end if;
 return jsonb_build_object('raw_score',raw,'max_score',maximum,'question_count',jsonb_array_length(p_questions),'correct_count',correct_n,'incorrect_questions',wrong,'unanswered_questions',blank,'unanswered_count',jsonb_array_length(blank),'grade',grade,'grade_status',p_certainty);
end $$;
create function public.scoring_key_questions(p_id uuid) returns jsonb language sql stable security invoker set search_path='' as $$
 select jsonb_agg(case when k.scoring_version='mcq5-v1' then jsonb_build_array(q.question_number,q.correct_answer,q.points)
 else jsonb_build_object('question_number',q.question_number,'question_id',q.question_id,'answer_type',q.answer_type,'accepted_answers',q.accepted_answers,'all_credit',q.all_credit,'points',q.points,'unit',q.unit,'domain',q.domain,'item_type',q.item_type) end order by q.question_number)
 from public.exam_questions q join public.answer_key_versions k on k.id=q.answer_key_version_id where k.id=p_id;
$$;
create function public.scoring_dispatch(engine text,q jsonb,a jsonb,c smallint[],certainty text) returns jsonb language plpgsql immutable security invoker set search_path='' as $$
begin
 if engine='mcq5-v1' then return public.scoring_mcq5(q,a,c,certainty);
 elsif engine='mixed-v2' then return public.scoring_mixed_v2(q,a,c,certainty);
 else raise exception 'INVALID_ENGINE' using errcode='22023';end if;
end $$;
create or replace function public.scoring_publication_guard()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
declare n integer; max_n integer; total integer; questions jsonb;
begin
  if TG_OP='DELETE' then
    if old.published_at is not null then raise exception 'PUBLISHED_IMMUTABLE' using errcode='23514'; end if;
    return old;
  end if;
  if TG_OP='INSERT' then
    if new.status <> 'draft' or new.published_at is not null or new.is_current
       or new.content_digest is not null then
      raise exception 'DRAFT_REQUIRED' using errcode='23514'; end if;
    return new;
  end if;
  if old.published_at is not null then
    if (to_jsonb(new)-array['status','is_current']) is distinct from
       (to_jsonb(old)-array['status','is_current']) or new.status='draft' then
      raise exception 'PUBLISHED_IMMUTABLE' using errcode='23514'; end if;
    return new;
  end if;
  if new.status='withdrawn' then raise exception 'PUBLISH_FIRST' using errcode='23514'; end if;
  if new.status='published' then
    if new.verified_at is null or new.verified_at > statement_timestamp() then
      raise exception 'VERIFICATION_REQUIRED' using errcode='23514'; end if;
    perform 1 from public.exam_subjects es join public.content_items c on c.id=es.content_item_id
      where es.id=new.exam_subject_id and es.content_item_id=new.content_item_id
        and es.is_active and c.is_active for share of es,c;
    if not found then raise exception 'INACTIVE_EXAM' using errcode='23514'; end if;
    if TG_TABLE_NAME='answer_key_versions' then
      select count(*),max(question_number),sum(points),
        jsonb_agg(jsonb_build_array(question_number,correct_answer,points) order by question_number)
        into n,max_n,total,questions from public.exam_questions where answer_key_version_id=new.id;
      if exists(select 1 from public.exam_questions where answer_key_version_id=new.id and
 ((new.scoring_version='mcq5-v1' and accepted_answers is not null) or(new.scoring_version='mixed-v2' and accepted_answers is null)))
 or new.verification_status<>'READY' then raise exception 'KEY_NOT_READY' using errcode='23514';end if;
      if new.scoring_version is distinct from old.scoring_version then
        raise exception 'ENGINE_CHANGE_REQUIRES_DRAFT_UPDATE' using errcode='23514'; end if;
      questions:=public.scoring_key_questions(new.id);
      if n <> new.question_count or max_n is distinct from n or total is distinct from new.max_score then
        raise exception 'INCOMPLETE_KEY' using errcode='23514'; end if;
    else questions := to_jsonb(new.minimum_scores); end if;
    new.published_at := statement_timestamp();
    -- SHA256 in pg_catalog; no extension dependency. Digest describes database JSONB serialization.
    new.content_digest := encode(sha256(convert_to(jsonb_build_object(
      'header',to_jsonb(new)-array['content_digest','status','is_current','draft_revision','created_at','published_at'],
      'data',questions)::text,'UTF8')),'hex');
  end if;
  return new;
end;
$$;
create or replace function public.scoring_attempt_consistency()
returns trigger language plpgsql volatile security definer set search_path = ''
as $$
declare a public.mock_exam_attempts; k public.answer_key_versions; g public.grade_cutoff_versions;
  target_id uuid; questions jsonb; answers jsonb; result jsonb; n integer;
begin
  if TG_TABLE_NAME='mock_exam_attempts' then target_id := new.id;
  else target_id := new.attempt_id; end if;
  select * into a from public.mock_exam_attempts where id=target_id;
  if not found then return null; end if;
  select * into k from public.answer_key_versions where id=a.answer_key_version_id;
  select count(*),jsonb_agg(jsonb_build_array(q.question_number,q.correct_answer,q.points) order by q.question_number),
    jsonb_agg(to_jsonb(v.submitted_answer) order by q.question_number)
    into n,questions,answers from public.exam_questions q
    join public.mock_exam_answers v on v.answer_key_version_id=q.answer_key_version_id
      and v.question_number=q.question_number and v.attempt_id=a.id
    where q.answer_key_version_id=k.id
      and v.correct_answer_snapshot is not distinct from case when k.scoring_version='mcq5-v1' then q.correct_answer when cardinality(q.accepted_answers)=1 then q.accepted_answers[1] else null end and v.points_snapshot=q.points
      and v.answer_type=q.answer_type and v.accepted_answers_snapshot is not distinct from q.accepted_answers and v.all_credit_snapshot=q.all_credit and v.question_id is not distinct from q.question_id
      and v.unit is not distinct from q.unit and v.domain is not distinct from q.domain and v.item_type is not distinct from q.item_type;
  questions:=public.scoring_key_questions(k.id);
  if a.scoring_version<>k.scoring_version then raise exception 'ENGINE_MISMATCH' using errcode='23514';end if;
  if n <> k.question_count then raise exception 'INCONSISTENT_ATTEMPT' using errcode='23514'; end if;
  if a.grade_cutoff_version_id is not null then select * into g from public.grade_cutoff_versions where id=a.grade_cutoff_version_id; end if;
  result := public.scoring_dispatch(k.scoring_version,questions,answers,g.minimum_scores,coalesce(g.certainty,'unavailable'));
  if a.request_payload->'answers' is distinct from answers
    or a.request_payload->>'key' is distinct from a.answer_key_version_id::text
    or a.request_payload->>'cutoff' is distinct from a.grade_cutoff_version_id::text
    or a.request_payload->>'engine' is distinct from a.scoring_version then
    raise exception 'INCONSISTENT_REQUEST' using errcode='23514'; end if;
  if a.raw_score <> (result->>'raw_score')::integer or a.max_score <> (result->>'max_score')::integer
    or a.correct_count <> (result->>'correct_count')::integer or a.question_count <> n
    or a.unanswered_count <> (result->>'unanswered_count')::integer
    or a.grade is distinct from (result->>'grade')::smallint
    or a.grade_status <> result->>'grade_status' then
    raise exception 'INCONSISTENT_ATTEMPT' using errcode='23514'; end if;
  return null;
end;
$$;
create or replace function public.submit_mock_attempt(p_attempt_id uuid, p_study_session_id uuid,
  p_answer_key_version_id uuid, p_grade_cutoff_version_id uuid, p_scoring_version text, p_answers jsonb)
returns jsonb language plpgsql volatile security definer set search_path = ''
as $$
declare owner_id uuid := auth.uid(); k public.answer_key_versions; g public.grade_cutoff_versions;
  prior public.mock_exam_attempts; normalized jsonb; request jsonb; questions jsonb; result jsonb;
begin
  perform account_private.lock_subject(owner_id); if not account_private.allowed(owner_id) then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;
  if p_attempt_id is null or p_answer_key_version_id is null or (p_scoring_version is null or p_scoring_version not in ('mcq5-v1','mixed-v2')) then
    raise exception 'INVALID_REQUEST' using errcode='22023'; end if;
  -- UUID-scoped lock makes identical concurrent retry atomic; collision only serializes.
  perform pg_advisory_xact_lock(hashtextextended(p_attempt_id::text,0));
  select * into prior from public.mock_exam_attempts where id=p_attempt_id;
  if found then
    if prior.user_id <> owner_id then raise exception 'ATTEMPT_CONFLICT' using errcode='23505'; end if;
    normalized := case when prior.scoring_version='mixed-v2' then public.scoring_normalize_answers_v2(p_answers,prior.question_count) else public.scoring_normalize_answers(p_answers,prior.question_count) end;
  else
    -- New submissions require the current published key; the lock serializes demotion.
    select * into k from public.answer_key_versions
      where id=p_answer_key_version_id and status='published' and is_current for share;
    if not found then raise exception 'KEY_UNAVAILABLE' using errcode='23514'; end if;
    if k.scoring_version<>p_scoring_version or(k.scoring_version='mixed-v2' and k.verification_status<>'READY') then raise exception 'KEY_NOT_READY' using errcode='23514';end if;
    normalized := case when k.scoring_version='mixed-v2' then public.scoring_normalize_answers_v2(p_answers,k.question_count) else public.scoring_normalize_answers(p_answers,k.question_count) end;
  end if;
  request := jsonb_build_object('study_session_id',p_study_session_id,'key',p_answer_key_version_id,
    'cutoff',p_grade_cutoff_version_id,'engine',p_scoring_version,'answers',normalized);
  -- Existing identical retries keep their original key/cutoff, even after a current switch.
  if prior.id is not null then
    if prior.request_payload <> request then raise exception 'ATTEMPT_CONFLICT' using errcode='23505'; end if;
    return public.fetch_own_mock_attempt(prior.id);
  end if;
  if p_grade_cutoff_version_id is not null then
    select * into g from public.grade_cutoff_versions where id=p_grade_cutoff_version_id and status='published' and is_current
      and exam_subject_id=k.exam_subject_id and paper_variant=k.paper_variant and max_score=k.max_score for share;
    if not found then raise exception 'CUTOFF_UNAVAILABLE' using errcode='23514'; end if;
  end if;
  select jsonb_agg(jsonb_build_array(question_number,correct_answer,points) order by question_number)
    into questions from public.exam_questions where answer_key_version_id=k.id;
  questions:=public.scoring_key_questions(k.id);
  result := public.scoring_dispatch(k.scoring_version,questions,normalized,g.minimum_scores,coalesce(g.certainty,'unavailable'));
  insert into public.mock_exam_attempts(id,user_id,study_session_id,exam_subject_id,paper_variant,
    answer_key_version_id,grade_cutoff_version_id,scoring_version,raw_score,max_score,
    question_count,correct_count,unanswered_count,grade,grade_status,request_payload)
  values(p_attempt_id,owner_id,p_study_session_id,k.exam_subject_id,k.paper_variant,k.id,g.id,p_scoring_version,
    (result->>'raw_score')::integer,(result->>'max_score')::integer,k.question_count,
    (result->>'correct_count')::smallint,(result->>'unanswered_count')::smallint,
    (result->>'grade')::smallint,result->>'grade_status',request);
  insert into public.mock_exam_answers(attempt_id,question_number,answer_key_version_id,
    submitted_answer,correct_answer_snapshot,points_snapshot,answer_type,accepted_answers_snapshot,all_credit_snapshot,question_id,unit,domain,item_type)
  select p_attempt_id,question_number,k.id,(normalized->>(question_number-1))::smallint,case when k.scoring_version='mcq5-v1' then correct_answer when cardinality(accepted_answers)=1 then accepted_answers[1] else null end,points,answer_type,accepted_answers,all_credit,question_id,unit,domain,item_type
    from public.exam_questions where answer_key_version_id=k.id;
  return public.fetch_own_mock_attempt(p_attempt_id);
end;
$$;
create or replace view public.mock_exam_scoring_availability with (security_invoker=true) as
select es.id as exam_subject_id, k.paper_variant, k.id as answer_key_version_id,
  k.version as answer_key_version, k.content_digest, k.question_count, k.max_score,
  case when k.id is null or(k.scoring_version='mixed-v2' and k.verification_status<>'READY') then 'timer_only' else 'scoring_available' end as availability,
  g.id as grade_cutoff_version_id, g.version as grade_cutoff_version,
  coalesce(g.certainty,'unavailable') as grade_status, coalesce(k.scoring_version,'mcq5-v1') as scoring_version, case when k.id is null then 'NOT_READY' when k.scoring_version='mcq5-v1' then 'READY' else k.verification_status end as verification_status
from public.exam_subjects es
left join public.answer_key_versions k on k.exam_subject_id=es.id and k.is_current and k.status='published'
left join public.grade_cutoff_versions g on g.exam_subject_id=k.exam_subject_id
  and g.paper_variant=k.paper_variant and g.max_score=k.max_score and g.is_current and g.status='published';
revoke all on function public.scoring_normalize_answers_v2(jsonb,integer) from public,anon,authenticated;
revoke all on function public.scoring_mixed_v2(jsonb,jsonb,smallint[],text) from public,anon,authenticated;
revoke all on function public.scoring_key_questions(uuid) from public,anon,authenticated;
revoke all on function public.scoring_dispatch(text,jsonb,jsonb,smallint[],text) from public,anon,authenticated;
grant select(scoring_version,verification_status) on public.answer_key_versions to anon,authenticated;
commit;
