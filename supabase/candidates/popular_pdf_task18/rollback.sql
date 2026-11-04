-- Fail closed without deleting approval history. Owner execution only.
begin;
create or replace function public.resource_download_policy(p_resource_id uuid) returns jsonb language sql stable security definer set search_path='' as $$ select '{"state":"PENDING"}'::jsonb $$;
commit;
