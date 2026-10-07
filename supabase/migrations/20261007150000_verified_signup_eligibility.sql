-- Owner-approved verified-signup policy. No grant/backfill or ledger mutation.
-- Preserve the installation-time cohort cutoff and original owner/ACL/OID.
begin;
do $guard$
declare original text; patched text; fn record;
begin
 select p.prosrc,p.prosecdef,p.provolatile,l.lanname into fn
 from pg_proc p join pg_language l on l.oid=p.prolang
 where p.oid=to_regprocedure('essay_private.credit_signup_eligible(uuid)');
 if not found or not fn.prosecdef or fn.provolatile <> 's' or fn.lanname <> 'sql' then
   raise exception 'SIGNUP_ELIGIBILITY_AUTHORITY_MISMATCH';
 end if;
 original := fn.prosrc;
 if original ~ 'email_confirmed_at is not null' then
   raise exception 'SIGNUP_VERIFICATION_ALREADY_PRESENT_REVIEW_REQUIRED';
 end if;
 if original !~ '^\s*select exists\(select 1 from auth.users where id=p_user and created_at >= ''[^'']+''::timestamptz\)\s*$' then
   raise exception 'SIGNUP_ELIGIBILITY_BODY_MISMATCH';
 end if;
 patched := replace(original,'where id=p_user and created_at >=',
   'where id=p_user and email_confirmed_at is not null and created_at >=');
 execute format('create or replace function essay_private.credit_signup_eligible(p_user uuid) returns boolean language sql stable security definer set search_path='''' as %L',patched);
end $guard$;
commit;
