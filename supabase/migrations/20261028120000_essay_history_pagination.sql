-- Owner application required. Read-only extension; no ledger/run UPDATE.
-- Preserve the established owner check and redaction by reusing the exact-run RPC.
begin;
create function public.essay_exam_history_page(
  p_before_at timestamptz default null,
  p_before_id uuid default null,
  p_limit integer default 50
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  u uuid = auth.uid(); account uuid; rows jsonb; more boolean;
begin
  perform math_private.require_active(array[u]);
  if u is null then raise exception 'ACCOUNT_UNAVAILABLE'; end if;
  if (p_before_at is null) <> (p_before_id is null) or p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'INVALID_PAGE';
  end if;
  select id into account from public.credit_accounts where user_id=u;
  with candidates as materialized (
    select r.id,r.created_at from essay_exam_private.runs r
    where r.account_id=account
      and (p_before_at is null or (r.created_at,r.id)<(p_before_at,p_before_id))
    order by r.created_at desc,r.id desc limit p_limit+1
  ), page as (
    select * from candidates order by created_at desc,id desc limit p_limit
  )
  select coalesce(jsonb_agg(
    ((public.essay_exam_history(p.id)->'runs'->0)-'answers'-'result')
    order by p.created_at desc,p.id desc),'[]'::jsonb),
    (select count(*)>p_limit from candidates)
  into rows,more from page p;
  return jsonb_build_object('version','essay-exam-history-page-v1','runs',rows,
    'next',case when more then jsonb_build_object('at',rows->-1->>'created_at','id',rows->-1->>'id') else null end);
end $$;
revoke all on function public.essay_exam_history_page(timestamptz,uuid,integer) from public,anon;
grant execute on function public.essay_exam_history_page(timestamptz,uuid,integer) to authenticated;
commit;
-- Rollback: DROP FUNCTION public.essay_exam_history_page(timestamptz,uuid,integer);
-- Existing essay_exam_history(uuid) and all stored history remain unchanged.
