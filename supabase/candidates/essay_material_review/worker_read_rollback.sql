-- Preserve every review, PDF, Package and student record.
begin;
revoke execute on function public.essay_material_runtime_package(uuid,text) from essay_worker;
commit;
