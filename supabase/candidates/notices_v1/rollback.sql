-- Disable APP/WEB notice entry first. Preserve all content, revisions and reads.
begin;
revoke execute on function public.notice_list(text,integer,integer),public.notice_detail(uuid,text),public.notice_mark_read(uuid,text,timestamptz),public.notice_admin_list(integer),public.notice_admin_save(jsonb) from anon,authenticated,service_role,public;
commit;
