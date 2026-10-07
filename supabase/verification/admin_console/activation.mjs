// Local PostgreSQL engine only. No hosted URL, key, account, email or financial write.
// PGLITE_MODULE points to the already installed @electric-sql/pglite dist/index.js.
import {readFile,readdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
const moduleUrl=process.env.PGLITE_MODULE;
if(!moduleUrl)throw new Error('Set PGLITE_MODULE to an installed PGlite dist/index.js');
const {PGlite}=await import(moduleUrl);
const {pgcrypto}=await import(moduleUrl.replace(/index\.js$/,'contrib/pgcrypto.js'));
const root=new URL('../../migrations/',import.meta.url);
const db=new PGlite({extensions:{pgcrypto}});
let checks=0;
function check(v){assert.ok(v);checks++;}
const query=async sql=>(await db.query(sql)).rows;
const admin=`select set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,false)`;
try {
 await db.exec(`create role anon;create role authenticated;create role service_role;create role math_executor;create role math_extraction_worker;create role math_evaluation_worker;create role supabase_admin;create role authenticator;create role essay_executor bypassrls;create role essay_worker nobypassrls;create role essay_finance nobypassrls;`);
 const harness=await readFile(new URL('harness.sh',import.meta.url),'utf8');
 await db.exec(harness.split("cat > /tmp/shim.sql <<'SQL'\n")[1].split('\nSQL')[0]);
 await db.exec(`alter table auth.users add column email_confirmed_at timestamptz;
 create table auth.identities(user_id uuid references auth.users(id),provider text,primary key(user_id,provider));`);
 // Same absent-subsystem posture as the original harness; includes the current
 // profile-field migration. These exclusions are not a hosted topology claim.
 for(const name of (await readdir(root)).filter(x=>x.endsWith('.sql')).sort()){
  if(/^(20261001000300|20261002000[123]00|20261003000100|20261004000100|20261005000100|20261006000100|20261008000100)/.test(name))continue;
  await db.exec(await readFile(new URL(name,root),'utf8'));
 }
 const catalog=()=>query(`select oid,proname,proowner,proacl::text,prosecdef,provolatile,proconfig from pg_proc where pronamespace='public'::regnamespace and proname in ('admin_credit_snapshot','admin_dashboard','admin_member_credit','admin_inquiry_detail','admin_member_detail') order by proname`);
 const before=await catalog();
 const correction=await readFile(new URL('20261008000100_admin_credit_read_reconciliation.sql',root),'utf8');
 await db.exec(correction);assert.deepEqual(await catalog(),before);checks++;
 for(const name of ['behavior.sql','behavior_p0b.sql','behavior_p0c.sql'])await db.exec((await readFile(new URL(name,import.meta.url),'utf8')).replace(/^\\.*$/gm,''));
 const old=(await query('select count(*)::int total,count(*) filter(where not ok)::int failed from admin_verify'))[0];check(old.failed===0);
 await db.exec(admin);
 // Existing suites remove optional stand-ins. Add only the Payment relation's
 // exact columns this correction reads. No Payment function or schema changes.
 await db.exec(`create table if not exists public.payment_orders(id uuid primary key default gen_random_uuid(),subject_id uuid,grant_id uuid,state text);
 insert into public.payment_orders(subject_id,grant_id,state) values('22222222-2222-4222-8222-222222222222','b2222222-2222-4222-8222-222222222222','CANCEL_PENDING');`);
 const snapshot=async()=>JSON.parse(JSON.stringify((await query("select public.admin_credit_snapshot('a1111111-1111-4111-8111-111111111111') x"))[0].x));
 let s=await snapshot();check(s.paid===0);check(s.free===3);check(s.reserved===0);
 let detail=(await query("select public.admin_member_credit('22222222-2222-4222-8222-222222222222') x"))[0].x;
 check(detail.grants.find(g=>g.grant_id==='b2222222-2222-4222-8222-222222222222').available===0);
 const dashboard=(await query('select public.admin_dashboard() x'))[0].x;
 check(dashboard.credit.available_by_origin.purchase===0);
 // Compare the actual canonical credit_summary body, under local-only lifecycle
 // shims, rather than a second copy of its arithmetic. This is not lifecycle E2E.
 await db.exec(`create schema if not exists account_private;
 create function account_private.lock_subject(uuid) returns void language sql as $$select$$;
 create function account_private.allowed(uuid) returns boolean language sql as $$select true$$;`);
 const payment=await readFile(new URL('20261004000100_payment_runtime.sql',root),'utf8');
 await db.exec(payment.match(/create function public.credit_summary\(\)[\s\S]*?end\$\$;/)[0]);
 await db.exec(`select set_config('request.jwt.claims',json_build_object('sub','22222222-2222-4222-8222-222222222222','role','authenticated','exp',extract(epoch from now())+600)::text,false)`);
 const canonical=async()=> (await query('select public.credit_summary() x'))[0].x;
 for(const k of ['spendable','paid','free','other','reserved','next_expiry'])check(s[k]===(await canonical())[k]);
 await db.exec(`update public.payment_orders set state='PAID';`);
 s=await snapshot();check(s.paid===4);
 await db.exec(`insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
 values('a1111111-1111-4111-8111-111111111111','b2222222-2222-4222-8222-222222222222',(select id from public.essay_billing_decisions where account_id='a1111111-1111-4111-8111-111111111111' limit 1),'reserve',0,2,'activation-reserve','test');`);
 s=await snapshot();check(s.paid===2);check(s.reserved===2);
 for(const k of ['spendable','paid','free','other','reserved','next_expiry'])check(s[k]===(await canonical())[k]);
 await db.exec(`update public.payment_orders set state='CANCEL_PENDING';`);
 s=await snapshot();check(s.paid===0);check(s.reserved===0);
 await db.exec(admin);
 const inquiry=(await query("select id from public.inquiries where user_id='22222222-2222-4222-8222-222222222222' limit 1"))[0];
 check(!!inquiry);
 const inquiryData=(await db.query("select public.admin_inquiry_detail(jsonb_build_object('dto_version','admin-v1','id',$1::text)) x",[inquiry.id])).rows[0].x;
 check(inquiryData.member.spendable===s.spendable); // Auth UUID != credit account UUID.
 await db.exec(`update public.profiles set intended_major='공학' where id='22222222-2222-4222-8222-222222222222';
 insert into auth.identities values('22222222-2222-4222-8222-222222222222','email');`);
 detail=(await query("select public.admin_member_detail('22222222-2222-4222-8222-222222222222') x"))[0].x;
 check(detail.member.intended_major==='공학');check(detail.member.auth_providers[0]==='email');check(detail.member.email_confirmed===false);
 await db.exec(`insert into public.universities(id,slug,name,is_active) values('66666666-6666-4666-8666-666666666666','activation-university','검증대학교',true);
 insert into public.student_target_universities(user_id,university_id,intended_division,source) values
 ('22222222-2222-4222-8222-222222222222','66666666-6666-4666-8666-666666666666','컴퓨터공학과','my'),
 ('33333333-3333-4333-8333-333333333333','66666666-6666-4666-8666-666666666666','다른 회원 학과','my');`);
 detail=(await query("select public.admin_member_detail('22222222-2222-4222-8222-222222222222') x"))[0].x;
 check(detail.member.target_universities.some(t=>t.intended_division==='컴퓨터공학과'));
 check(!JSON.stringify(detail.member).includes('다른 회원 학과'));
 await db.exec(`select set_config('request.jwt.claims',json_build_object('sub','22222222-2222-4222-8222-222222222222','role','authenticated','exp',extract(epoch from now())+600)::text,false);set role authenticated;`);
 check((await query("select count(*)::int n from public.student_target_universities where user_id='33333333-3333-4333-8333-333333333333'"))[0].n===0);
 check((await query("update public.student_target_universities set intended_division='FORBIDDEN' where user_id='33333333-3333-4333-8333-333333333333' returning id")).length===0);
 await db.exec("update public.student_target_universities set intended_division='교육학과' where university_id='66666666-6666-4666-8666-666666666666';update public.profiles set intended_major='교육' where id='22222222-2222-4222-8222-222222222222'");
 check((await query("select intended_division from public.student_target_universities where university_id='66666666-6666-4666-8666-666666666666'"))[0].intended_division==='교육학과');
 check((await query("select intended_major from public.profiles where id='22222222-2222-4222-8222-222222222222'"))[0].intended_major==='교육');
 check((await query("update public.profiles set intended_major='FORBIDDEN' where id='33333333-3333-4333-8333-333333333333' returning id")).length===0);
 await db.exec('reset role');
 // Canonical grant function, verified gate, retry identity and no intrinsic expiry.
 const uid='55555555-5555-4555-8555-555555555555';
 await db.exec(`insert into auth.users(id,email) values('${uid}','activation@example.test');insert into public.profiles(id) values('${uid}');
 select set_config('request.jwt.claims',json_build_object('sub','${uid}','role','authenticated','exp',extract(epoch from now())+600)::text,false);set role authenticated;`);
 await assert.rejects(db.query('select public.essay_claim_signup_credit()'),/SIGNUP_NOT_ELIGIBLE/);checks++;
 await db.exec(`reset role;update auth.users set email_confirmed_at=now() where id='${uid}';set role authenticated;`);
 const first=(await query('select public.essay_claim_signup_credit() id'))[0].id;
 for(let i=0;i<5;i++)check((await query('select public.essay_claim_signup_credit() id'))[0].id===first);
 await db.exec(`reset role;insert into auth.identities values('${uid}','email'),('${uid}','google');set role authenticated;`);
 check((await query('select public.essay_claim_signup_credit() id'))[0].id===first);
 await db.exec('reset role');
 const grants=await db.query('select count(*)::int n,max(expires_at) expiry from public.credit_grants where id=$1',[first]);check(grants.rows[0].n===1&&grants.rows[0].expiry===null);
 check((await db.query('select sum(balance_delta)::int n from public.credit_transactions where grant_id=$1',[first])).rows[0].n===3);
 // Repeat-apply rejects an unexpected body rather than overwriting later work.
 await assert.rejects(db.exec(correction),/ADMIN_AUTHORITY_MISMATCH/);checks++;await db.exec('rollback');
 console.log(JSON.stringify({existing_checks:old.total,correction_checks:checks,failed:0,concurrency:'NOT_TESTED: single-connection engine',hosted:false}));
} finally {await db.close();}
