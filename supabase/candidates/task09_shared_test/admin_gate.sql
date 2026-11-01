-- TEST ONLY: kpqbedylxlyntrrfybpn. Reuses the verified operational admin gate.
-- No role membership, account, Credit or evaluation data is changed.
begin;
do $$ begin
 if to_regprocedure('public.admin_operator()') is not null then
  raise exception 'ADMIN_GATE_EXISTS_REVIEW_BEFORE_APPLY';
 end if;
 if to_regclass('public.admin_users') is null then raise exception 'ADMIN_USERS_MISSING';end if;
end $$;
CREATE FUNCTION public.admin_operator()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare claims jsonb; expiry numeric;
begin
 claims := nullif(current_setting('request.jwt.claims',true),'')::jsonb;
 if auth.uid() is null or claims->>'sub' is distinct from auth.uid()::text or claims->>'role' is distinct from 'authenticated' or jsonb_typeof(claims->'exp') is distinct from 'number' then return false; end if;
 expiry := (claims->>'exp')::numeric;
 if expiry <= extract(epoch from statement_timestamp()) then return false; end if;
 return exists(select 1 from public.admin_users a where a.user_id=auth.uid());
exception when invalid_text_representation or numeric_value_out_of_range then return false;
end$function$;
revoke all on function public.admin_operator() from public,anon,authenticated,service_role;
grant execute on function public.admin_operator() to authenticated;
commit;
