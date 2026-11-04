-- Production definition, read-only capture; TEST fixture uses synthetic admin_users.
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
end$function$
;
