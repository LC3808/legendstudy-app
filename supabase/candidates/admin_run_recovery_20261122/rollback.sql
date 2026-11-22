-- Revert Worker/WEB adapters first. Never reverse real results/ledger/audit events.
begin;
do $$declare x record;p pg_proc;begin for x in select * from (values ('essay_ops_private.recovery_key(uuid)','c02af9b6ca23370a253252e49eacc320','["postgres=X/postgres"]'::jsonb),('essay_ops_private.recovery_retry_key(uuid)','45ef4820f0d5510e5e0ef1d838a937bb','["postgres=X/postgres"]'::jsonb),('essay_ops_private.recovery_replay(jsonb)','3d20d34a666351fbf79a0ebc7884e87b','["postgres=X/postgres"]'::jsonb),('essay_ops_private.recovery_digest(uuid)','4c5a551109d709d3d39e5d54f4d703e6','["postgres=X/postgres"]'::jsonb),('essay_ops_private.recovery_diagnosis(uuid)','450075910e8aa9bd2980998370f29f64','["postgres=X/postgres"]'::jsonb),('admin_lab_run_recovery(uuid)','9daee87f76720be353eb0afe8e97d398','["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb),('essay_ops_private.recovery_receipt(uuid,uuid,jsonb,text,text,text)','63c46b13b4921b1a91aa73390924c6ac','["postgres=X/postgres"]'::jsonb),('admin_lab_recover_run(uuid,uuid,text)','6ac0528270851374c7e27fd633651725','["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb),('essay_exam_recovery_finish(uuid,text,jsonb,jsonb)','0ea34b98abb183e7fcf2324055f3958c','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb),('admin_lab_recovery_operations(timestamp with time zone,timestamp with time zone)','03bcd5d2563f2f07defc5dfc428ffbe6','["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb),('essay_ops_private.recovery_intent(uuid)','3416fdbb75a78130dd6d53ff204ae271','["postgres=X/postgres"]'::jsonb),('essay_exam_recovery_context(uuid)','c3a2cfac216c3aa5daf1b7c7766c7891','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb)) v(signature,expected_md5,expected_acl) loop select * into p from pg_proc where oid=x.signature::regprocedure;if md5(pg_get_functiondef(p.oid))<>x.expected_md5 or to_jsonb(p.proacl) is distinct from x.expected_acl or pg_get_userbyid(p.proowner)<>'postgres' then raise exception 'POSTIMAGE_CHANGED: %',x.signature;end if;end loop;end$$;
drop function public.essay_exam_recovery_context(uuid);
drop function essay_ops_private.recovery_intent(uuid);
drop function public.admin_lab_recovery_operations(timestamptz,timestamptz);
drop function public.essay_exam_recovery_finish(uuid,text,jsonb,jsonb);
drop function public.admin_lab_recover_run(uuid,uuid,text);
drop function essay_ops_private.recovery_receipt(uuid,uuid,jsonb,text,text,text);
drop function public.admin_lab_run_recovery(uuid);
drop function essay_ops_private.recovery_diagnosis(uuid);
drop function essay_ops_private.recovery_digest(uuid);
drop function essay_ops_private.recovery_replay(jsonb);
drop function essay_ops_private.recovery_retry_key(uuid);
drop function essay_ops_private.recovery_key(uuid);
do $$begin if not exists(select 1 from essay_ops_private.run_actions where action='recover') then alter table essay_ops_private.run_actions drop constraint run_actions_action_check;alter table essay_ops_private.run_actions add constraint run_actions_action_check check(action in('retry','delete','archive','restore'));end if;end$$;
notify pgrst,'reload schema';
commit;
