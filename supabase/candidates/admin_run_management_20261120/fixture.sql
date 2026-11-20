-- Disposable local DB only. Structural fixture for the inspected Production contracts.
do $$declare n text;begin foreach n in array array['anon','authenticated','service_role','essay_worker'] loop if not exists(select 1 from pg_roles where rolname=n) then execute format('create role %I',n);end if;end loop;end$$;
create schema auth;create schema essay_ops_private;create schema essay_exam_private;create schema math_private;create schema feedback_private;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('test.actor',true),'')::uuid$$;
create function essay_ops_private.require_admin() returns void language plpgsql as $$begin if auth.uid() is distinct from '00000000-0000-4000-8000-000000000001'::uuid then raise exception 'ADMIN_REQUIRED' using errcode='42501';end if;end$$;
create function math_private.require_active(uuid[]) returns void language plpgsql as $$begin if current_setting('test.suspended',true)='true' then raise insufficient_privilege;end if;end$$;
create table public.credit_accounts(id uuid primary key,user_id uuid not null);
create table public.essay_billing_decisions(id uuid primary key,account_id uuid,credits_required int,status text);
create table public.credit_transactions(id uuid primary key,decision_id uuid, balance_delta int,reserved_delta int);
create table essay_exam_private.runs(id uuid primary key,account_id uuid not null references public.credit_accounts,exam_id uuid not null,parent_id uuid references essay_exam_private.runs,decision_id uuid not null references public.essay_billing_decisions,request_key uuid not null,snapshot jsonb not null,state text not null,result jsonb,created_at timestamptz not null default now(),completed_at timestamptz,dispatch_key uuid,lease_token uuid,lease_until timestamptz,previous_paid_run_id uuid references essay_exam_private.runs,submission_index int);
create table essay_exam_private.checkpoints(run_id uuid references essay_exam_private.runs on delete cascade,key text,writer uuid,state text,payload jsonb,primary key(run_id,key));
create table essay_ops_private.hidden_runs(run_id uuid primary key,hidden boolean,changed_by uuid,changed_at timestamptz default now());
create table essay_ops_private.calls(evaluation_id uuid);
create table public.human_quality_judgments(exam_run_id uuid references essay_exam_private.runs on delete cascade);
create table math_private.mixed_coaching_disclosures(run_id uuid references essay_exam_private.runs on delete cascade);
create table math_private.mixed_coaching_hints(run_id uuid references essay_exam_private.runs on delete cascade);
create table feedback_private.essay_context(run_id uuid);
create function public.admin_lab_set_run_hidden(p_run uuid,p_hidden boolean) returns jsonb language plpgsql security definer set search_path='' as $$begin perform essay_ops_private.require_admin();insert into essay_ops_private.hidden_runs(run_id,hidden,changed_by) values(p_run,p_hidden,auth.uid()) on conflict(run_id) do update set hidden=excluded.hidden,changed_by=excluded.changed_by,changed_at=now();return jsonb_build_object('hidden',p_hidden);end$$;
grant usage on schema public,auth to authenticated,anon;
create function public.check_true(ok boolean,label text) returns void language plpgsql as $$begin if ok is distinct from true then raise exception 'ASSERTION: %',label;end if;end$$;
create function public.expect_failure(sql text,code text) returns void language plpgsql as $$begin execute sql;raise exception 'EXPECTED_FAILURE_NOT_RAISED';exception when others then if sqlerrm='EXPECTED_FAILURE_NOT_RAISED' or (sqlerrm<>code and sqlstate<>code) then raise;end if;end$$;
create function public.make_run(n integer,kind text default 'stalled') returns uuid language plpgsql as $$declare r uuid=('10000000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid;b uuid=('20000000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid;begin
 insert into public.essay_billing_decisions values(b,'00000000-0000-4000-8000-000000000002',case when kind='test' then 0 else 1 end,case when kind='test' then 'rejected' else 'reserved' end);
 insert into essay_exam_private.runs(id,account_id,exam_id,decision_id,request_key,snapshot,state,created_at,lease_token,lease_until) values(r,'00000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000003',b,r,'{"answers":[{"questionId":"fixture-q","body":"SYNTHETIC"}]}','reserved',now()-interval '1 day',gen_random_uuid(),now()+case when kind='active' then interval '1 hour' else interval '-1 hour' end);
 insert into essay_exam_private.checkpoints values(r,'q0',gen_random_uuid(),'checkpoint','{"state":"failed"}');return r;end$$;
insert into public.credit_accounts values('00000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000002');
