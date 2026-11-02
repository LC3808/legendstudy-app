-- Candidate only. Owner approval required; no Production application by this task.
-- Precheck existing v1 function identity and bucket absence; do not silently overwrite drift.
begin;
do $$ begin
 if md5(pg_get_functiondef('public.notice_admin_save(jsonb)'::regprocedure)) <> 'd28fcae4ef35b592fea0f2da73ca2c32' then raise exception 'NOTICE_V1_DRIFT_REVIEW_REQUIRED'; end if;
 if exists(select 1 from storage.buckets where id='notice-media') then raise exception 'NOTICE_BUCKET_EXISTS_REVIEW_REQUIRED'; end if;
end $$;
alter table notice_private.notices add column content_document jsonb;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('notice-media','notice-media',false,5242880,array['image/webp']);
-- Original notice/visibility/receipts remain canonical. Old APP41 reads content as before.
create function notice_private.invalidate_legacy_document() returns trigger language plpgsql set search_path='' as $$
begin
 if new.content is distinct from old.content and new.content_document is not distinct from old.content_document then new.content_document:=null; end if;
 return new;
end $$;
create trigger notice_legacy_content before update on notice_private.notices for each row execute function notice_private.invalidate_legacy_document();
create function public.notice_admin_save_rich(p jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare n notice_private.notices; id uuid; old_time timestamptz; doc jsonb; block jsonb; plain text := ''; image_count integer := 0;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise exception 'FORBIDDEN' using errcode='42501'; end if;

 doc:=p->'content_document';
 if doc is null or jsonb_typeof(doc) <> 'object' or doc->>'version' is distinct from '1' or jsonb_typeof(doc->'blocks') is distinct from 'array' then raise exception 'INVALID_NOTICE_DOCUMENT'; end if;
 if jsonb_array_length(doc->'blocks') not between 1 and 100 or octet_length(doc::text)>250000 then raise exception 'INVALID_NOTICE_DOCUMENT'; end if;
 for block in select value from jsonb_array_elements(doc->'blocks') loop
   if block->>'type'='text' then
     if jsonb_typeof(block->'text') is distinct from 'string' or jsonb_typeof(block->'bold') is distinct from 'boolean' or jsonb_typeof(block->'underline') is distinct from 'boolean' or block->>'size' is null or block->>'size' not in ('16','18','22','28') then raise exception 'INVALID_NOTICE_DOCUMENT'; end if;
     plain:=plain || E'\n\n' || (block->>'text');
   elsif block->>'type'='image' then
     image_count:=image_count+1;
     if image_count>8 or jsonb_typeof(block->'alt') is distinct from 'string' or length(trim(block->>'alt')) not between 1 and 300 or jsonb_typeof(block->'path') is distinct from 'string' or (block->>'path') !~ '^[a-f0-9-]{36}/[a-f0-9-]{36}\.webp$' then raise exception 'INVALID_NOTICE_DOCUMENT'; end if;
     if not exists(select 1 from storage.objects where bucket_id='notice-media' and name=block->>'path') then raise exception 'NOTICE_IMAGE_MISSING'; end if;
     plain:=plain || E'\n\n' || '[이미지: ' || (block->>'alt') || ']';
   else raise exception 'INVALID_NOTICE_DOCUMENT'; end if;
 end loop;
 if length(plain)>50000 then raise exception 'INVALID_NOTICE_DOCUMENT'; end if;
 p:=p || jsonb_build_object('content',trim(plain,E' \n\r\t'));
 id:=nullif(p->>'notice_id','')::uuid;
 if id is not null then
 select * into n from notice_private.notices where notice_id=id for update;
 if not found then raise exception 'NOT_FOUND'; end if;
 old_time:=nullif(p->>'updated_at','')::timestamptz;
 if old_time is distinct from n.updated_at then raise exception 'NOTICE_CONFLICT'; end if;
 else id:=gen_random_uuid(); end if;
 insert into notice_private.notices(notice_id,title,content,content_document,category,status,is_pinned,is_public,show_app,show_web,published_at,expires_at,created_by)
 values(id,trim(p->>'title'),trim(p->>'content'),doc,p->>'category',p->>'status',coalesce((p->>'is_pinned')::boolean,false),coalesce((p->>'is_public')::boolean,true),coalesce((p->>'show_app')::boolean,true),coalesce((p->>'show_web')::boolean,true),nullif(p->>'published_at','')::timestamptz,nullif(p->>'expires_at','')::timestamptz,auth.uid())
 on conflict(notice_id) do update set title=excluded.title,content=excluded.content,content_document=excluded.content_document,category=excluded.category,status=excluded.status,is_pinned=excluded.is_pinned,is_public=excluded.is_public,show_app=excluded.show_app,show_web=excluded.show_web,published_at=excluded.published_at,expires_at=excluded.expires_at,updated_at=clock_timestamp()
 returning * into n;
 insert into notice_private.revisions(notice_id,actor,snapshot) values(id,auth.uid(),to_jsonb(n)-'created_by');
 return to_jsonb(n);
end $$;

create function public.notice_editor_capability() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 return jsonb_build_object('version',1);
end $$;
create function public.notice_media_admin() returns boolean language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null then return false; end if;
 return public.admin_operator() and account_private.allowed(auth.uid());
end $$;
create function public.notice_media_read(object_name text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
 if public.notice_media_admin() then return true; end if;
 return exists(select 1 from notice_private.notices n where
 (notice_private.visible(n,'web') or notice_private.visible(n,'app'))
 and n.content_document->'blocks' @> jsonb_build_array(jsonb_build_object('type','image','path',object_name)));
end $$;
revoke all on function notice_private.invalidate_legacy_document() from public,anon,authenticated,service_role;
revoke all on function public.notice_admin_save_rich(jsonb),public.notice_editor_capability(),public.notice_media_admin(),public.notice_media_read(text) from public,anon,authenticated,service_role;
grant execute on function public.notice_admin_save_rich(jsonb),public.notice_editor_capability() to authenticated;
grant execute on function public.notice_media_read(text),public.notice_media_admin() to anon,authenticated;
-- Restrictive policies keep any pre-existing broad Storage policies from exposing this bucket.
create policy notice_media_select_guard on storage.objects as restrictive for select to anon,authenticated using(bucket_id<>'notice-media' or public.notice_media_read(name));
create policy notice_media_select on storage.objects for select to anon,authenticated using(bucket_id='notice-media' and public.notice_media_read(name));
create policy notice_media_insert_guard on storage.objects as restrictive for insert to anon,authenticated with check(bucket_id<>'notice-media' or (public.notice_media_admin() and name ~ '^[a-f0-9-]{36}/[a-f0-9-]{36}\.webp$' and split_part(name,'/',1)=auth.uid()::text));
create policy notice_media_insert on storage.objects for insert to authenticated with check(bucket_id='notice-media' and public.notice_media_admin() and split_part(name,'/',1)=auth.uid()::text);
create policy notice_media_update_guard on storage.objects as restrictive for update to anon,authenticated using(bucket_id<>'notice-media') with check(bucket_id<>'notice-media');
create policy notice_media_delete_guard on storage.objects as restrictive for delete to anon,authenticated using(bucket_id<>'notice-media');
commit;
