-- Owner applies separately. No profiles/public-profile schema expansion.
-- One private PNG object per owner is the canonical avatar reference.
begin;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-avatars', 'profile-avatars', false, 1048576, array['image/png']);

create policy "avatar_owner_read" on storage.objects for select to authenticated
using (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
create policy "avatar_owner_insert" on storage.objects for insert to authenticated
with check (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
create policy "avatar_owner_update" on storage.objects for update to authenticated
using (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png')
with check (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
create policy "avatar_owner_delete" on storage.objects for delete to authenticated
using (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
commit;
