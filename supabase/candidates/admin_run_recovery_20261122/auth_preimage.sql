CREATE OR REPLACE FUNCTION math_private.require_active(uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid; permitted boolean;
begin
 if $1 is null or cardinality($1)=0 or array_position($1,null) is not null then raise insufficient_privilege;end if;
 if to_regprocedure('account_private.allowed(uuid)') is null or to_regprocedure('account_private.lock_subject(uuid)') is null then raise insufficient_privilege using message='MATH_LIFECYCLE_DEPENDENCY_MISSING';end if;
 for u in select distinct x from unnest($1) x order by x loop
  execute 'select account_private.lock_subject($1)' using u;
  execute 'select account_private.allowed($1)' into permitted using u;
  if permitted is distinct from true then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 end loop;
end$function$;

CREATE OR REPLACE FUNCTION public.admin_operator()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare claims jsonb; expiry numeric;
begin
 -- Identity is always auth.uid(); API JWT signature validation remains at the gateway.
 -- Require an unexpired verified request context, also denying missing/malformed context.
 claims := nullif(current_setting('request.jwt.claims',true),'')::jsonb;
 if auth.uid() is null or claims->>'sub' is distinct from auth.uid()::text or claims->>'role' is distinct from 'authenticated' or jsonb_typeof(claims->'exp') is distinct from 'number' then return false; end if;
 expiry := (claims->>'exp')::numeric;
 if expiry <= extract(epoch from statement_timestamp()) then return false; end if;
 return exists(select 1 from public.admin_users a where a.user_id=auth.uid());
exception when invalid_text_representation or numeric_value_out_of_range then return false;
end$function$;

CREATE OR REPLACE FUNCTION essay_ops_private.require_admin()
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or public.admin_operator() is not true or account_private.allowed(auth.uid()) is not true then raise exception 'ADMIN_REQUIRED' using errcode='42501';end if;
end $function$;
