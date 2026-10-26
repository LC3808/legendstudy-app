-- Disable the new WEB operations first. Preserve all posted grants and audit rows.
begin;
drop function public.admin_credit_recover(uuid,uuid,integer,text,uuid);
drop function public.admin_credit_grant_expiring(uuid,text,integer,text,text,date,text,uuid);
drop function public.admin_credit_operation_info(uuid,uuid);
commit;
