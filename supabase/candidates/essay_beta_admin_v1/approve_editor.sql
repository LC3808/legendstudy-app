-- Owner-only approval template. NEVER infer an Owner from an email or JWT metadata.
-- Replace NULL/empty only after independently verifying official admin_operator.
begin;
do $$declare editor uuid:=null; approval text:='';begin
 if editor is null or length(trim(approval))<3 then raise exception 'OWNER_APPROVAL_REQUIRED';end if;
 if not exists(select 1 from auth.users where id=editor) then raise exception 'USER_NOT_FOUND';end if;
 -- This never creates an official admin. Runtime requires admin_operator() too.
 insert into essay_beta_private.settings_editors(user_id,approval_reference) values(editor,approval);
end $$;
commit;
