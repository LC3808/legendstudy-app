-- Owner apply only: capability/writes off, data and immutable image history retained.
begin;
revoke execute on function public.notice_editor_capability(),public.notice_admin_save_rich(jsonb) from authenticated;
drop policy notice_media_insert on storage.objects;
alter policy notice_media_insert_guard on storage.objects with check (bucket_id <> 'notice-media');
-- Keep restrictive guards and read policies: existing notices/images continue to display.
commit;
