-- LOCAL candidate: reuse Provider005 policy validation only. No legacy wrapper replacement.
begin;
create function essay_private.provider_policy(p_regime text) returns jsonb
language sql immutable set search_path='' as $$select null::jsonb$$;

-- Content-addressed relation prevents changing a model while retaining the same regime.
create function essay_private.provider_binding_valid(p_regime text,b jsonb) returns boolean
language plpgsql immutable set search_path='' as $$
declare k text;
begin
 if b is null or jsonb_typeof(b)<>'object' or b-array['policy_version','provider','model','model_version','prompt_version','contract_version']<>'{}'::jsonb
 or b->>'contract_version' is distinct from '1.3' then return false;end if;
 foreach k in array array['policy_version','provider','model','model_version','prompt_version','contract_version'] loop
  if jsonb_typeof(b->k) is distinct from 'string' or not ((b->>k) ~ '^[A-Za-z0-9][A-Za-z0-9._:/+-]{0,159}$') then return false;end if;
 end loop;
 if b->>'provider'='unconfigured' or b->>'model'='unconfigured' then return false;end if;
 return coalesce(p_regime='essay-v1.3/policy/'||pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(b::text,'UTF8')),'hex'),false);
end$$;


revoke all on function essay_private.provider_policy(text),essay_private.provider_binding_valid(text,jsonb) from public,anon,authenticated,service_role,essay_worker;
commit;
