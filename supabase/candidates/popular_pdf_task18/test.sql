-- ISOLATED FIXTURE ONLY. No Production test execution.
do $$ begin if current_setting('task18.fixture',true) is distinct from 'yes' then raise exception 'Isolated fixture required'; end if; end $$;
begin;
insert into public.resources values('11111111-1111-4111-8111-111111111111','c3686e6b-eee1-522a-92ee-278c81bf513e','c3686e6b-eee1-522a-92ee-278c81bf513e',null,true,'fixture/file');
do $$ begin assert public.resource_download_policy('11111111-1111-4111-8111-111111111111')->>'state'='PENDING'; end $$;
insert into material_download_private.permissions(resource_id,source_resource_key,state,filename,sha256,rights_holder,evidence_url,owner_decision) values('11111111-1111-4111-8111-111111111111','fixture/file','ALLOWED','2026_고3_9월_국어_문제지.pdf',repeat('a',64),'synthetic','https://example.invalid/test','ISOLATED TEST ONLY');
set local role anon;
do $$ begin assert public.resource_download_policy('11111111-1111-4111-8111-111111111111')->>'state'='ALLOWED'; end $$;
reset role;
update public.resources set is_active=false where id='11111111-1111-4111-8111-111111111111';
do $$ begin assert public.resource_download_policy('11111111-1111-4111-8111-111111111111')->>'state'='PENDING'; end $$;
update public.resources set is_active=true,source_resource_key='changed/file' where id='11111111-1111-4111-8111-111111111111';
do $$ begin assert public.resource_download_policy('11111111-1111-4111-8111-111111111111')->>'state'='PENDING'; end $$;
update public.resources set source_resource_key='fixture/file' where id='11111111-1111-4111-8111-111111111111';
insert into material_download_private.permissions(resource_id,source_resource_key,state) values('11111111-1111-4111-8111-111111111111','fixture/file','VIEW_ONLY');
do $$ begin assert public.resource_download_policy('11111111-1111-4111-8111-111111111111')->>'state'='VIEW_ONLY'; end $$;
do $$ begin
 begin update material_download_private.permissions set state='PENDING'; raise exception 'test failed'; exception when raise_exception then assert sqlerrm='Append a new permission revision instead'; end;
 begin insert into material_download_private.permissions(resource_id,source_resource_key,state) values('11111111-1111-4111-8111-111111111111','fixture/file','ALLOWED'); raise exception 'test failed'; exception when check_violation then null; end;
end $$;
set local role anon;
do $$ begin
 begin insert into material_download_private.permissions(resource_id,source_resource_key) values('11111111-1111-4111-8111-111111111111','x'); raise exception 'test failed'; exception when insufficient_privilege then null; end;
end $$;
reset role;
delete from material_download_private.pilot_posts;
do $$ begin assert public.resource_download_policy('11111111-1111-4111-8111-111111111111')->>'state'='PENDING'; end $$;
rollback;
