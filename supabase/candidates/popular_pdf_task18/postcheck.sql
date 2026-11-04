select count(*) = 18 as pilot18 from material_download_private.pilot_posts;
select count(*)=0 as no_files_enabled from material_download_private.permissions;
select public.resource_download_policy('00000000-0000-4000-8000-000000000000') = '{"state":"PENDING"}'::jsonb as unknown_denied;
select has_function_privilege('anon','public.resource_download_policy(uuid)','EXECUTE') as guest_read, not has_schema_privilege('anon','material_download_private','USAGE') as private_hidden;
