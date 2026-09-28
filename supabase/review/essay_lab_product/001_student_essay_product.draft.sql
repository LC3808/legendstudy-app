-- DRAFT ONLY / NOT APPLIED. Owner review + local runtime/RLS tests + server RPCs required.
-- No seed. Existing tables unmodified. All bodies private; text-first MVP.
begin;

create table public.essay_questions (
 id uuid primary key default gen_random_uuid(),
 essay_exam_id uuid not null references public.essay_exams(id) on delete restrict,
 question_key text not null check (btrim(question_key) <> ''),
 label text not null,
 display_order smallint not null check (display_order >= 0),
 length_min integer check (length_min >= 0),
 length_max integer check (length_max > 0),
 length_count_rule text, -- verified counting convention, not an invented count policy
 time_limit_seconds integer check (time_limit_seconds > 0), -- ONLY official question-specific limit
 metadata_version text not null,
 is_published boolean not null default false,
 created_at timestamptz not null default now(),
 unique (essay_exam_id,question_key), unique(id,essay_exam_id),
 check (length_max is null or length_min is null or length_max >= length_min),
 check ((length_min is null and length_max is null) or length_count_rule is not null)
);

-- Selects a precise segment of an EXISTING exam-resource mapping. Never copies a PDF/body.
create table public.essay_question_evidence (
 id uuid primary key default gen_random_uuid(),
 question_id uuid not null,
 essay_exam_id uuid not null,
 resource_id uuid not null,
 role text not null,
 source_locator text not null check (btrim(source_locator) <> ''),
 mapping_version text not null,
 source_sha256 text not null check (source_sha256 ~ '^[0-9a-f]{64}$'),
 created_at timestamptz not null default now(),
 foreign key(question_id,essay_exam_id) references public.essay_questions(id,essay_exam_id) on delete restrict,
 foreign key(essay_exam_id,resource_id,role) references public.essay_exam_resources(essay_exam_id,resource_id,role) on delete restrict,
 unique(question_id,resource_id,role,source_locator,mapping_version), unique(id,question_id)
);

create table public.essay_evaluation_criteria (
 id uuid primary key default gen_random_uuid(),
 question_id uuid not null references public.essay_questions(id) on delete restrict,
 criterion_key text not null check (btrim(criterion_key) <> ''),
 definition_version text not null,
 label text not null,
 description text not null, -- short verified structured definition, not a duplicate whole PDF
 origin text not null check (origin in ('official','legendstudy_derived')),
 source_evidence_id uuid not null,
 official_weight_percent numeric(5,2) check (official_weight_percent > 0 and official_weight_percent <= 100),
 display_order smallint not null check (display_order >= 0),
 verified_at timestamptz not null,
 created_at timestamptz not null default now(),
 foreign key(source_evidence_id,question_id) references public.essay_question_evidence(id,question_id),
 unique(question_id,criterion_key,definition_version), unique(id,question_id),
 check (origin = 'official' or official_weight_percent is null)
);

create table public.student_target_universities (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 university_id uuid not null references public.universities(id) on delete restrict,
 admission_year smallint check (admission_year between 1900 and 2200),
 admission_type text,
 intended_division text,
 priority smallint check (priority > 0),
 status text not null default 'interested' check (status in ('interested','considering','planned')),
 source text not null check (source in ('onboarding','my','essay_lab')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique nulls not distinct(user_id,university_id,admission_year)
);

create table public.essay_practice_sessions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 question_id uuid not null references public.essay_questions(id) on delete restrict,
 created_at timestamptz not null default now(),
 unique(id,question_id)
 -- No unique(user,question): a later independent practice cycle is legitimate.
);
create index essay_sessions_owner_recent on public.essay_practice_sessions(user_id,created_at desc,id);

create table public.essay_drafts (
 session_id uuid primary key references public.essay_practice_sessions(id) on delete cascade,
 body text not null default '',
 revision bigint not null default 1 check (revision > 0),
 mode text not null default 'practice' check (mode in ('practice','timed','exam_simulation')),
 device_class text not null check (device_class in ('web_desktop','web_mobile','app_mobile','tablet')),
 started_at timestamptz not null default now(),
 active_writing_seconds integer check (active_writing_seconds >= 0),
 updated_at timestamptz not null default now()
);

create table public.essay_attempts (
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references public.essay_practice_sessions(id) on delete cascade,
 attempt_no integer not null check (attempt_no > 0),
 body text not null check (btrim(body) <> ''),
 body_sha256 text not null check (body_sha256 ~ '^[0-9a-f]{64}$'),
 input_method text not null check (input_method in ('typed','pasted','mixed')),
 device_class text not null check (device_class in ('web_desktop','web_mobile','app_mobile','tablet')),
 mode text not null check (mode in ('practice','timed','exam_simulation')),
 started_at timestamptz not null,
 submitted_at timestamptz not null default now(),
 active_writing_seconds integer check (active_writing_seconds >= 0),
 character_count integer not null check (character_count > 0),
 count_rule_version text not null,
 question_metadata_version text not null,
 conditions_snapshot jsonb not null check (jsonb_typeof(conditions_snapshot) = 'object'), -- limits/count rule only
 submission_key uuid not null unique,
 unique(session_id,attempt_no), unique(id,session_id),
 check (submitted_at >= started_at),
 check (active_writing_seconds is null or active_writing_seconds <= extract(epoch from submitted_at-started_at))
);

-- One logical request/result row. Provider retries are separate operational runs.
create table public.essay_evaluations (
 id uuid primary key default gen_random_uuid(),
 attempt_id uuid not null,
 session_id uuid not null,
 question_id uuid not null,
 idempotency_key uuid not null unique,
 request_hash text not null check (request_hash ~ '^[0-9a-f]{64}$'),
 status text not null default 'requested' check (status in ('requested','processing','completed','failed','cancelled')),
 evaluation_version text not null,
 contract_version text not null,
 regime_key text not null, -- criterion/scale/prompt/model/evidence/comparison regime version
 evidence_manifest_sha256 text not null check (evidence_manifest_sha256 ~ '^[0-9a-f]{64}$'),
 evidence_completeness text not null check (evidence_completeness in ('complete','limited')),
 overall_summary text,
 strengths text[],
 rewrite_checklist text[],
 uncertainty_note text,
 input_sha256 text check (input_sha256 ~ '^[0-9a-f]{64}$'),
 output_sha256 text check (output_sha256 ~ '^[0-9a-f]{64}$'),
 error_code text,
 requested_at timestamptz not null default now(),
 completed_at timestamptz,
 foreign key(attempt_id,session_id) references public.essay_attempts(id,session_id) on delete cascade,
 foreign key(session_id,question_id) references public.essay_practice_sessions(id,question_id) on delete cascade,
 unique(id,question_id), unique(id,session_id), unique(id,attempt_id),
 check (status <> 'completed' or (completed_at is not null and overall_summary is not null and input_sha256 is not null and output_sha256 is not null)),
 check (completed_at is null or completed_at >= requested_at)
);
create index essay_evaluations_attempt_recent on public.essay_evaluations(attempt_id,requested_at desc);
create index essay_evaluations_pending on public.essay_evaluations(requested_at) where status in ('requested','processing');

create table public.essay_evaluation_dimensions (
 id uuid primary key default gen_random_uuid(),
 evaluation_id uuid not null,
 question_id uuid not null,
 criterion_id uuid not null,
 created_at timestamptz not null default now(),
 level_1_to_5 smallint check (level_1_to_5 between 1 and 5),
 explanation text not null,
 uncertainty_note text,
 display_order smallint not null check (display_order >= 0),
 foreign key(evaluation_id,question_id) references public.essay_evaluations(id,question_id) on delete cascade,
 foreign key(criterion_id,question_id) references public.essay_evaluation_criteria(id,question_id) on delete restrict,
 unique(evaluation_id,criterion_id), unique(id,evaluation_id),
 check (level_1_to_5 is not null or nullif(btrim(uncertainty_note),'') is not null)
);

-- Session-scoped stable root issue. Text is not identity; no universal AI issue taxonomy.
create table public.essay_improvement_items (
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references public.essay_practice_sessions(id) on delete cascade,
 issue_key text not null check (btrim(issue_key) <> ''),
 category text not null check (category in ('task_fulfillment','passage_understanding','reasoning','evidence_use','structure','expression','format','other')),
 created_at timestamptz not null default now(),
 unique(session_id,issue_key), unique(id,session_id)
);

create table public.essay_improvement_progress (
 id uuid primary key default gen_random_uuid(),
 issue_id uuid not null,
 session_id uuid not null,
 evaluation_id uuid not null,
 created_at timestamptz not null default now(),
 status text not null check (status in ('open','improved','resolved','recurring')),
 title text not null,
 explanation text not null,
 next_action text not null,
 priority smallint not null check (priority > 0),
 foreign key(issue_id,session_id) references public.essay_improvement_items(id,session_id) on delete cascade,
 foreign key(evaluation_id,session_id) references public.essay_evaluations(id,session_id) on delete cascade,
 unique(issue_id,evaluation_id), unique(id,evaluation_id)
);
create index essay_improvement_progress_evaluation on public.essay_improvement_progress(evaluation_id);

create table public.essay_evaluation_evidence (
 id uuid primary key default gen_random_uuid(),
 evaluation_id uuid not null,
 question_id uuid not null,
 evidence_id uuid not null,
 dimension_id uuid,
 improvement_progress_id uuid,
 created_at timestamptz not null default now(),
 foreign key(evaluation_id,question_id) references public.essay_evaluations(id,question_id) on delete cascade,
 foreign key(evidence_id,question_id) references public.essay_question_evidence(id,question_id) on delete restrict,
 foreign key(dimension_id,evaluation_id) references public.essay_evaluation_dimensions(id,evaluation_id) on delete cascade,
 foreign key(improvement_progress_id,evaluation_id) references public.essay_improvement_progress(id,evaluation_id) on delete cascade,
 check (num_nonnulls(dimension_id,improvement_progress_id) <= 1),
 unique nulls not distinct(evaluation_id,evidence_id,dimension_id,improvement_progress_id)
);

create table public.essay_generated_rewrites (
 id uuid primary key default gen_random_uuid(),
 evaluation_id uuid not null unique references public.essay_evaluations(id) on delete cascade,
 status text not null default 'requested' check (status in ('requested','processing','completed','failed','cancelled')),
 generation_version text not null,
 contract_version text not null,
 origin text not null default 'ai_generated' check (origin = 'ai_generated'),
 body text,
 input_sha256 text check (input_sha256 ~ '^[0-9a-f]{64}$'),
 output_sha256 text check (output_sha256 ~ '^[0-9a-f]{64}$'),
 error_code text,
 created_at timestamptz not null default now(),
 completed_at timestamptz,
 check (status <> 'completed' or (body is not null and input_sha256 is not null and output_sha256 is not null and completed_at is not null))
);

-- No generic JSON payload; no bodies, raw UA, email, school name or prompt.
create table public.essay_learning_events (
 id uuid primary key default gen_random_uuid(),
 event_key uuid not null unique,
 session_id uuid not null references public.essay_practice_sessions(id) on delete cascade,
 attempt_id uuid,
 evaluation_id uuid,
 event_type text not null check (event_type in ('essay_rewrite_started','essay_example_rewrite_viewed','essay_official_source_opened')),
 occurred_at timestamptz not null default now(),
 foreign key(attempt_id,session_id) references public.essay_attempts(id,session_id) on delete cascade,
 foreign key(evaluation_id,attempt_id) references public.essay_evaluations(id,attempt_id) on delete cascade,
 check (evaluation_id is null or attempt_id is not null),
 check (event_type <> 'essay_example_rewrite_viewed' or evaluation_id is not null)
);
create index essay_events_session_time on public.essay_learning_events(session_id,occurred_at);

-- Operator-only telemetry; one row per actual provider attempt, not one per student click.
create table public.essay_ai_processing_runs (
 id uuid primary key default gen_random_uuid(),
 evaluation_id uuid references public.essay_evaluations(id) on delete cascade,
 rewrite_id uuid references public.essay_generated_rewrites(id) on delete cascade,
 run_no integer not null check (run_no > 0),
 provider text not null, model_name text not null, model_version text,
 prompt_version text not null,
 status text not null check (status in ('processing','completed','failed','unknown')),
 selected_result boolean not null default false,
 started_at timestamptz not null default now(), completed_at timestamptz,
 input_tokens bigint check (input_tokens >= 0), output_tokens bigint check (output_tokens >= 0),
 image_count integer check (image_count >= 0), latency_ms bigint check (latency_ms >= 0),
 cost_amount numeric(16,8) check (cost_amount >= 0), currency text,
 cost_basis text check (cost_basis in ('provider_reported','estimate')),
 input_sha256 text check (input_sha256 ~ '^[0-9a-f]{64}$'), output_sha256 text check (output_sha256 ~ '^[0-9a-f]{64}$'),
 error_code text,
 check (num_nonnulls(evaluation_id,rewrite_id) = 1),
 check (not selected_result or (status = 'completed' and output_sha256 is not null)),
 check ((cost_amount is null and currency is null and cost_basis is null) or (cost_amount is not null and currency is not null and cost_basis is not null)),
 unique(evaluation_id,run_no), unique(rewrite_id,run_no)
);
create unique index essay_ai_selected_evaluation on public.essay_ai_processing_runs(evaluation_id) where selected_result;
create unique index essay_ai_selected_rewrite on public.essay_ai_processing_runs(rewrite_id) where selected_result;
create index essay_ai_runs_started on public.essay_ai_processing_runs(started_at desc);

-- Completed results and submitted/canonical versions never UPDATE. Explicit deletion is
-- via the separately authorized erasure service, not a student DELETE grant.
create function public.essay_product_reject_update() returns trigger language plpgsql set search_path = '' as $$
begin raise exception 'immutable version: create a new record'; end;
$$;
create function public.essay_product_terminal_guard() returns trigger language plpgsql set search_path = '' as $$
begin
 if old.status in ('completed','failed','cancelled') then raise exception 'terminal result is immutable'; end if;
 return new;
end;
$$;
create function public.essay_product_child_guard() returns trigger language plpgsql set search_path = '' as $$
begin
 -- Lock serializes child insertion/update against finalization. Erasure uses DELETE.
 perform 1 from public.essay_evaluations e where e.id = new.evaluation_id and e.status in ('requested','processing') for update;
 if not found then raise exception 'evaluation is absent or frozen'; end if;
 if tg_op = 'UPDATE' and old.evaluation_id <> new.evaluation_id then raise exception 'cannot move result'; end if;
 return new;
end;
$$;

create trigger essay_sessions_identity_frozen before update on public.essay_practice_sessions for each row execute function public.essay_product_reject_update();
create trigger essay_issue_identity_frozen before update on public.essay_improvement_items for each row execute function public.essay_product_reject_update();
create trigger essay_attempts_frozen before update on public.essay_attempts for each row execute function public.essay_product_reject_update();
create trigger essay_criteria_frozen before update on public.essay_evaluation_criteria for each row execute function public.essay_product_reject_update();
create trigger essay_question_evidence_frozen before update on public.essay_question_evidence for each row execute function public.essay_product_reject_update();
create trigger essay_evaluations_frozen before update on public.essay_evaluations for each row execute function public.essay_product_terminal_guard();
create trigger essay_rewrites_frozen before update on public.essay_generated_rewrites for each row execute function public.essay_product_terminal_guard();
create trigger essay_dimensions_guard before insert or update on public.essay_evaluation_dimensions for each row execute function public.essay_product_child_guard();
create trigger essay_progress_guard before insert or update on public.essay_improvement_progress for each row execute function public.essay_product_child_guard();
create trigger essay_result_evidence_guard before insert or update on public.essay_evaluation_evidence for each row execute function public.essay_product_child_guard();

-- RLS/grants generated explicitly below. No security-definer owner bypass helper.
alter table public.essay_questions enable row level security;
revoke all on public.essay_questions from public, anon, authenticated;
grant select, insert, update, delete on public.essay_questions to service_role;
grant select on public.essay_questions to anon, authenticated;
create policy essay_questions_read on public.essay_questions for select to anon, authenticated using (is_published and exists (select 1 from public.essay_exams e where e.id = essay_questions.essay_exam_id));
alter table public.essay_question_evidence enable row level security;
revoke all on public.essay_question_evidence from public, anon, authenticated;
grant select, insert, update, delete on public.essay_question_evidence to service_role;
grant select on public.essay_question_evidence to anon, authenticated;
create policy essay_question_evidence_read on public.essay_question_evidence for select to anon, authenticated using (exists (select 1 from public.essay_questions q where q.id = essay_question_evidence.question_id) and exists (select 1 from public.essay_exam_resources m where m.essay_exam_id = essay_question_evidence.essay_exam_id and m.resource_id = essay_question_evidence.resource_id and m.role = essay_question_evidence.role and m.provenance = 'official'));
alter table public.essay_evaluation_criteria enable row level security;
revoke all on public.essay_evaluation_criteria from public, anon, authenticated;
grant select, insert, update, delete on public.essay_evaluation_criteria to service_role;
grant select on public.essay_evaluation_criteria to anon, authenticated;
create policy essay_evaluation_criteria_read on public.essay_evaluation_criteria for select to anon, authenticated using (exists (select 1 from public.essay_question_evidence e where e.id = essay_evaluation_criteria.source_evidence_id));
alter table public.student_target_universities enable row level security;
revoke all on public.student_target_universities from public, anon, authenticated;
grant select, insert, update, delete on public.student_target_universities to service_role;
grant select on public.student_target_universities to authenticated;
create policy student_target_universities_read on public.student_target_universities for select to authenticated using (user_id = (select auth.uid()));
grant insert, update, delete on public.student_target_universities to authenticated;
create policy student_target_universities_insert on public.student_target_universities for insert to authenticated with check (user_id = (select auth.uid()));
create policy student_target_universities_update on public.student_target_universities for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy student_target_universities_delete on public.student_target_universities for delete to authenticated using (user_id = (select auth.uid()));
alter table public.essay_practice_sessions enable row level security;
revoke all on public.essay_practice_sessions from public, anon, authenticated;
grant select, insert, update, delete on public.essay_practice_sessions to service_role;
grant select on public.essay_practice_sessions to authenticated;
create policy essay_practice_sessions_read on public.essay_practice_sessions for select to authenticated using (user_id = (select auth.uid()));
alter table public.essay_drafts enable row level security;
revoke all on public.essay_drafts from public, anon, authenticated;
grant select, insert, update, delete on public.essay_drafts to service_role;
grant select on public.essay_drafts to authenticated;
create policy essay_drafts_read on public.essay_drafts for select to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_drafts.session_id and s.user_id = (select auth.uid())));
grant insert, update, delete on public.essay_drafts to authenticated;
create policy essay_drafts_insert on public.essay_drafts for insert to authenticated with check (exists (select 1 from public.essay_practice_sessions s where s.id = essay_drafts.session_id and s.user_id = (select auth.uid())));
create policy essay_drafts_update on public.essay_drafts for update to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_drafts.session_id and s.user_id = (select auth.uid()))) with check (exists (select 1 from public.essay_practice_sessions s where s.id = essay_drafts.session_id and s.user_id = (select auth.uid())));
create policy essay_drafts_delete on public.essay_drafts for delete to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_drafts.session_id and s.user_id = (select auth.uid())));
alter table public.essay_attempts enable row level security;
revoke all on public.essay_attempts from public, anon, authenticated;
grant select, insert, update, delete on public.essay_attempts to service_role;
grant select on public.essay_attempts to authenticated;
create policy essay_attempts_read on public.essay_attempts for select to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_attempts.session_id and s.user_id = (select auth.uid())));
alter table public.essay_evaluations enable row level security;
revoke all on public.essay_evaluations from public, anon, authenticated;
grant select, insert, update, delete on public.essay_evaluations to service_role;
grant select on public.essay_evaluations to authenticated;
create policy essay_evaluations_read on public.essay_evaluations for select to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_evaluations.session_id and s.user_id = (select auth.uid())));
alter table public.essay_evaluation_dimensions enable row level security;
revoke all on public.essay_evaluation_dimensions from public, anon, authenticated;
grant select, insert, update, delete on public.essay_evaluation_dimensions to service_role;
grant select on public.essay_evaluation_dimensions to authenticated;
create policy essay_evaluation_dimensions_read on public.essay_evaluation_dimensions for select to authenticated using (exists (select 1 from public.essay_evaluations e where e.id = essay_evaluation_dimensions.evaluation_id));
alter table public.essay_improvement_items enable row level security;
revoke all on public.essay_improvement_items from public, anon, authenticated;
grant select, insert, update, delete on public.essay_improvement_items to service_role;
grant select on public.essay_improvement_items to authenticated;
create policy essay_improvement_items_read on public.essay_improvement_items for select to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_improvement_items.session_id and s.user_id = (select auth.uid())));
alter table public.essay_improvement_progress enable row level security;
revoke all on public.essay_improvement_progress from public, anon, authenticated;
grant select, insert, update, delete on public.essay_improvement_progress to service_role;
grant select on public.essay_improvement_progress to authenticated;
create policy essay_improvement_progress_read on public.essay_improvement_progress for select to authenticated using (exists (select 1 from public.essay_evaluations e where e.id = essay_improvement_progress.evaluation_id));
alter table public.essay_evaluation_evidence enable row level security;
revoke all on public.essay_evaluation_evidence from public, anon, authenticated;
grant select, insert, update, delete on public.essay_evaluation_evidence to service_role;
grant select on public.essay_evaluation_evidence to authenticated;
create policy essay_evaluation_evidence_read on public.essay_evaluation_evidence for select to authenticated using (exists (select 1 from public.essay_evaluations e where e.id = essay_evaluation_evidence.evaluation_id));
alter table public.essay_generated_rewrites enable row level security;
revoke all on public.essay_generated_rewrites from public, anon, authenticated;
grant select, insert, update, delete on public.essay_generated_rewrites to service_role;
grant select on public.essay_generated_rewrites to authenticated;
create policy essay_generated_rewrites_read on public.essay_generated_rewrites for select to authenticated using (exists (select 1 from public.essay_evaluations e where e.id = essay_generated_rewrites.evaluation_id));
alter table public.essay_learning_events enable row level security;
revoke all on public.essay_learning_events from public, anon, authenticated;
grant select, insert, update, delete on public.essay_learning_events to service_role;
grant select on public.essay_learning_events to authenticated;
create policy essay_learning_events_read on public.essay_learning_events for select to authenticated using (exists (select 1 from public.essay_practice_sessions s where s.id = essay_learning_events.session_id and s.user_id = (select auth.uid())));
alter table public.essay_ai_processing_runs enable row level security;
revoke all on public.essay_ai_processing_runs from public, anon, authenticated;
grant select, insert, update, delete on public.essay_ai_processing_runs to service_role;

create function public.essay_product_draft_guard() returns trigger language plpgsql set search_path = '' as $$
begin
 if new.session_id <> old.session_id or new.revision <> old.revision + 1 then
  raise exception 'draft conflict: reload current revision';
 end if;
 new.updated_at = now();
 return new;
end;
$$;
create trigger essay_drafts_revision before update on public.essay_drafts for each row execute function public.essay_product_draft_guard();
create trigger essay_target_updated before update on public.student_target_universities for each row execute function public.set_updated_at();
-- Mutation functions are trigger-only; never expose as RPC.
revoke all on function public.essay_product_reject_update(), public.essay_product_terminal_guard(), public.essay_product_child_guard(), public.essay_product_draft_guard() from public, anon, authenticated;
commit;
