-- Synthetic/time-boundary checks; does not claim Ledger/RPC integration coverage.
begin;
\i supabase/candidates/essay_beta_credit_20261027/policy.prototype.sql
DO $$
declare x record;
begin
 select * into x from beta_policy_prototype.daily_window('2026-10-27 14:59:59.999999+00','2026-10-27','2026-10-31');
 assert x.kst_day='2026-10-27'::date and x.expires_at='2026-10-27 15:00+00'::timestamptz,'KST last microsecond';
 select * into x from beta_policy_prototype.daily_window('2026-10-27 15:00+00','2026-10-27','2026-10-31');
 assert x.kst_day='2026-10-28'::date and x.expires_at='2026-10-28 15:00+00'::timestamptz,'next day';
 assert not exists(select from beta_policy_prototype.daily_window('2026-10-26 14:59:59+00','2026-10-27','2026-10-31')),'before start';
 assert not exists(select from beta_policy_prototype.daily_window('2026-10-31 15:00+00','2026-10-27','2026-10-31')),'end exclusive';
 assert exists(select from beta_policy_prototype.daily_window('2026-11-02 14:59+00','2026-10-27','2026-11-02')),'seven days';
 begin
  perform beta_policy_prototype.daily_window(now(),'2026-10-27','2026-11-03');
  raise exception '8 days incorrectly accepted';
 exception when raise_exception then
  if sqlerrm<>'INVALID_CAMPAIGN_WINDOW' then raise;end if;
 end;
 assert beta_policy_prototype.scope_eligible(true,true,'humanities',false,false),'humanities';
 assert beta_policy_prototype.scope_eligible(true,true,'social',false,false),'social';
 assert beta_policy_prototype.scope_eligible(true,true,'commerce',true,true),'reviewed mixed';
 assert not beta_policy_prototype.scope_eligible(true,true,'commerce',true,false),'unreviewed mixed';
 assert not beta_policy_prototype.scope_eligible(true,true,'natural',true,true),'natural';
 assert not beta_policy_prototype.scope_eligible(true,true,'medicine',true,true),'medicine';
 assert not beta_policy_prototype.scope_eligible(true,true,'science',true,true),'science';
 assert not beta_policy_prototype.scope_eligible(false,true,'humanities',false,true),'unpublished';
 assert not beta_policy_prototype.scope_eligible(true,false,'humanities',false,true),'partial';
 assert not beta_policy_prototype.scope_eligible(true,true,'social',null,true),'unknown math';
 assert beta_policy_prototype.spend_rank('promotion','daily',true,true)=0,'daily first';
 assert beta_policy_prototype.spend_rank('signup_bonus',null,true,true)=1,'signup before paid';
 assert beta_policy_prototype.spend_rank('promotion','feedback',true,false)=2,'reward after beta proposal';
 assert beta_policy_prototype.spend_rank('purchase',null,true,true)=3,'purchase last';
 assert beta_policy_prototype.spend_rank('promotion','daily',false,true) is null,'ineligible scope';
 assert beta_policy_prototype.spend_rank('promotion','daily',true,false) is null,'closed campaign';
 assert beta_policy_prototype.spend_rank('promotion','unknown',true,true) is null,'unknown scoped kind';
 raise notice '23 policy assertions PASS; no grant/settlement/concurrency tests executed';
end $$;
rollback;
