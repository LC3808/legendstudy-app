-- Disable endpoints while retaining private review data and immutable audit history.
begin;
revoke all on function public.essay_material_list(),public.essay_material_detail(uuid),public.essay_material_save(uuid,integer,jsonb,text,boolean) from authenticated,anon,public;
revoke all on function public.essay_material_register(text,text,integer),public.essay_material_documents() from authenticated,anon,public;
drop policy if exists essay_material_operator_read on storage.objects;
drop policy if exists essay_material_operator_insert on storage.objects;
commit;
