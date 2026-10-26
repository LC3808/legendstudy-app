-- Restore previous WEB before removing this additive read API.
begin;
drop function public.admin_credit_member_list(text,integer,integer,text);
commit;
