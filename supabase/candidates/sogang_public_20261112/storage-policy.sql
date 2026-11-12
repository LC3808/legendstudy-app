begin;
set local lock_timeout='5s';
do $g$ begin
 if not exists(select 1 from storage.buckets where id='essay-material-originals' and public=false and allowed_mime_types=array['application/pdf']) then raise exception 'BUCKET_DRIFT';end if;
 if exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='sogang_problem_q2_complete_20261112_read') then raise exception 'sogang_problem_q2_complete_20261112_read_ALREADY_EXISTS';end if;
 if (select count(*) from storage.objects where bucket_id='essay-material-originals' and name='2bbadaf676cb022a98e4b81ea527332940b7862a95d95c38ff392c665ef8bc5a.pdf' and (metadata->>'size')::bigint=349986)<>1 then raise exception 'PDF_NOT_VERIFIED';end if;
 if md5(pg_get_functiondef('public.account_service_allowed()'::regprocedure))<>'4bc4e4ef8067186bbfb20e6460070cd7' then raise exception 'ACCOUNT_CHECK_DRIFT';end if;
end $g$;
create temp table _policy_before on commit drop as select schemaname,tablename,policyname,md5(to_jsonb(p)::text) digest from pg_policies p;
create policy sogang_problem_q2_complete_20261112_read on storage.objects for select to authenticated using ((select public.account_service_allowed()) and bucket_id='essay-material-originals' and name='2bbadaf676cb022a98e4b81ea527332940b7862a95d95c38ff392c665ef8bc5a.pdf');
 do $p$ begin if exists(select * from _policy_before except select schemaname,tablename,policyname,md5(to_jsonb(p)::text) from pg_policies p) or (select count(*) from pg_policies)<>(select count(*)+1 from _policy_before) then raise exception 'EXISTING_sogang_problem_q2_complete_20261112_read_DRIFT';end if;end $p$;
commit;
