const test = require('node:test');
const assert = require('node:assert/strict');
const {probe} = require('./secret_auth_build_probe.cjs');
const names = ['ESSAY_REGISTRY_WORKER_JWT','ESSAY_WORKER_SERVICE_TOKEN',
  'MATH_EVALUATION_WORKER_JWT','MATH_EXTRACTION_WORKER_JWT','MATH_PROVIDER_API_KEY'];
test('empty and uninjected values are distinct, with no outbound requests',async()=>{
  const env=Object.fromEntries(names.map(n=>[n,'']));
  const empty=await probe(env,()=>assert.fail('unexpected network'));
  assert(empty.results.every(x=>x.state==='EMPTY_VALUE'));
  const absent=await probe({},()=>assert.fail('unexpected network'));
  assert(absent.results.every(x=>x.state==='NOT_IN_BUILD_ENV'));
});
test('fixed read-only calls; no secret or upstream body returned',async()=>{
  const env=Object.fromEntries(names.map(n=>[n,'synthetic-private-value-aaaaaaaaaaaaaa']));
  const calls=[];
  const out=await probe(env,async(url,opts)=>{
    calls.push({url,opts});
    if(url.includes('math_evaluation')||url.includes('math_extraction'))
      return Response.json({code:'22023',message:'sensitive upstream content'},{status:400});
    return Response.json([]);
  });
  assert.equal(calls.length,4);
  assert.equal(out.results.filter(x=>x.state==='AUTH_ACCEPTED').length,4);
  assert(calls.every(x=>!x.url.includes('submit')&&!x.url.includes('responses')));
  assert.equal(calls.find(x=>x.url.includes('openai')).opts.method,'GET');
  assert(!JSON.stringify(out).includes('synthetic-private'));
  assert(!JSON.stringify(out).includes('sensitive upstream'));
  assert.equal(out.results[1].state,'SERVICE_BINDING_PROBE_REQUIRED');
});
test('auth rejection and transport error never become PASS',async()=>{
  const env=Object.fromEntries(names.map(n=>[n,'synthetic-private-value-aaaaaaaaaaaaaa']));
  const out=await probe(env,async()=>Response.json({code:'PGRST303'},{status:401}));
  assert.equal(out.results.filter(x=>x.state==='AUTH_REJECTED').length,4);
  const failed=await probe(env,async()=>{throw Error('secret must not escape')});
  assert.equal(failed.results.filter(x=>x.state==='TRANSPORT_ERROR').length,4);
  assert(!JSON.stringify(failed).includes('secret must not escape'));
});
