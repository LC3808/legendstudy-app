-- Disposable fixture only, synthetic official admin gate.
create schema auth;create schema account_private;create schema essay_exam_private;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('test.actor',true),'')::uuid$$;
create function public.admin_operator() returns boolean language sql as $$select coalesce(nullif(current_setting('test.admin',true),''),'false')::boolean$$;
create function account_private.allowed(uuid) returns boolean language sql as $$select coalesce(nullif(current_setting('test.allowed',true),''),'true')::boolean$$;
create table public.universities(id uuid primary key,name text);
create table public.essay_exams(id uuid primary key,university_id uuid,exam_name text);
create table essay_exam_private.runs(id uuid primary key,exam_id uuid,parent_id uuid,decision_id uuid,created_at timestamptz,completed_at timestamptz,state text,snapshot jsonb);
create table essay_exam_private.retry_requests(run_id uuid,request_key uuid,generation int,attempts jsonb,created_at timestamptz,lease_until timestamptz);
create table essay_exam_private.checkpoints(run_id uuid,key text,state text,payload jsonb,primary key(run_id,key));
create table public.credit_grants(id uuid primary key,origin text);
create table public.credit_transactions(id uuid primary key,grant_id uuid,decision_id uuid,transaction_type text,balance_delta int,reserved_delta int,created_at timestamptz);
create table public.essay_ai_processing_runs(id uuid primary key,evaluation_id uuid,started_at timestamptz,provider text,model_name text,input_tokens bigint,output_tokens bigint,latency_ms bigint,cost_basis text,currency text,cost_amount numeric,status text,run_no int);
