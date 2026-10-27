-- New worker-only source-aware interfaces. No grants, campaign activation or new tables.
create function essay_beta_private.credit_source(p_account uuid,p_exam uuid) returns jsonb
language sql volatile set search_path='' as $$
 with available as (
 select g.id,g.origin,g.expires_at,g.created_at,essay_beta_private.is_beta(g.id) beta,
 greatest(0,(select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)) quantity
 from public.credit_grants g where g.account_id=p_account
 and (g.expires_at is null or g.expires_at>clock_timestamp())
 and not exists(select 1 from public.payment_orders o where o.grant_id=g.id and o.state='CANCEL_PENDING')
 and (not essay_beta_private.is_beta(g.id) or essay_beta_private.eligible(g.id,p_exam))
 ), selected as(select * from available where quantity>=1 order by beta desc,expires_at nulls last,created_at,id limit 1)
 select jsonb_build_object('version','essay-credit-source-v1','grant_id',(select id from selected),
 'source',(select case when beta then 'beta' else origin::text end from selected),
 'beta',coalesce(sum(quantity) filter(where beta),0),
 'signup_bonus',coalesce(sum(quantity) filter(where origin='signup_bonus' and not beta),0),
 'purchase',coalesce(sum(quantity) filter(where origin='purchase' and not beta),0),
 'other',coalesce(sum(quantity) filter(where origin not in ('signup_bonus','purchase') and not beta),0)) from available;
$$;
revoke all on function essay_beta_private.credit_source(uuid,uuid) from public,anon,authenticated,service_role;

create function public.essay_exam_quote_source(p_subject uuid,p_exam uuid,p_questions uuid[],p_parent uuid default null,p_previous uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare quote jsonb; account uuid; source jsonb;
begin
 quote=public.essay_exam_quote(p_subject,p_exam,p_questions,p_parent,p_previous);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 source=essay_beta_private.credit_source(account,p_exam);
 if (quote->>'credits')::int=0 then source=source||jsonb_build_object('grant_id',null,'source','included');end if;
 if (quote->>'credits')::int=1 and source->>'grant_id' is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT';end if;
 return quote||jsonb_build_object('credit_source',source);
end$$;
revoke all on function public.essay_exam_quote_source(uuid,uuid,uuid[],uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_quote_source(uuid,uuid,uuid[],uuid,uuid) to essay_worker;

create function public.essay_exam_submit_source(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb,p_expected_grant uuid,p_parent uuid default null,p_previous uuid default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid;
begin
 -- The existing submit verifies subject, admission, immutable answers and exact replay.
 -- Setting is transaction-local; reserve checks it under its existing account lock.
 perform set_config('legendstudy.credit_confirmation_required','true',true);
 perform set_config('legendstudy.confirmed_credit_grant',coalesce(p_expected_grant::text,''),true);
 if p_parent is not null and p_previous is not null then raise sqlstate 'PT422' using message='INVALID_PAID_CYCLE';end if;
 if p_previous is null then
 rid=public.essay_exam_submit(p_subject,p_exam,p_key,p_answers,p_parent);
 else
 rid=public.essay_exam_submit_cycle(p_subject,p_exam,p_key,p_answers,p_parent,p_previous);
 end if;
 perform set_config('legendstudy.confirmed_credit_grant','',true);
 perform set_config('legendstudy.credit_confirmation_required','',true);
 return rid;
end$$;
revoke all on function public.essay_exam_submit_source(uuid,uuid,uuid,jsonb,uuid,uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_submit_source(uuid,uuid,uuid,jsonb,uuid,uuid,uuid) to essay_worker;
