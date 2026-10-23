// Build-only diagnostic. Never creates an artifact or permits deployment.
// Fixed destinations; no secret value, fingerprint, claims or upstream body logged.
const names = ['ESSAY_REGISTRY_WORKER_JWT', 'ESSAY_WORKER_SERVICE_TOKEN',
  'MATH_EVALUATION_WORKER_JWT', 'MATH_EXTRACTION_WORKER_JWT', 'MATH_PROVIDER_API_KEY'];
async function probe(env, request = fetch) {
  const results = [];
  const origin = 'https://stlhijzpjfgwwdgunlsd.supabase.co';
  for (const name of names) {
    const present = Object.prototype.hasOwnProperty.call(env, name);
    const value = env[name];
    if (!present || !value) {
      results.push({name, state: present ? 'EMPTY_VALUE' : 'NOT_IN_BUILD_ENV', http: null});
      continue;
    }
    if (name === 'ESSAY_WORKER_SERVICE_TOKEN') {
      results.push({name, state: value.length < 32 ? 'INVALID_LENGTH' : 'SERVICE_BINDING_PROBE_REQUIRED', http:null});
      continue;
    }
    const provider = name === 'MATH_PROVIDER_API_KEY';
    const rpc = name === 'ESSAY_REGISTRY_WORKER_JWT' ? 'essay_registered_questions'
      : name === 'MATH_EVALUATION_WORKER_JWT' ? 'math_evaluation' : 'math_extraction';
    const body = rpc === 'essay_registered_questions'
      ? {p_subject:'ddc5ae63-acbb-490b-a423-c996b811dea8'} : {p_request:null};
    try {
      const response = await request(provider ? 'https://api.openai.com/v1/models' : origin+'/rest/v1/rpc/'+rpc,
        {method:provider?'GET':'POST', redirect:'error',signal:AbortSignal.timeout(15000),
          headers: {Authorization:'Bearer '+value,...(!provider?{apikey:env.MATH_SUPABASE_PUBLISHABLE_KEY,
            'Content-Type':'application/json'}:{})},...(!provider?{body:JSON.stringify(body)}:{})});
      let code = null;
      if (!provider) {
        const data = await response.json();
        if (typeof data?.code === 'string' && /^[A-Z0-9]{5,12}$/.test(data.code)) code=data.code;
      } else if (response.body) await response.body.cancel();
      const accepted = response.ok || (!provider && rpc !== 'essay_registered_questions' && response.status===400 && code==='22023');
      results.push({name,state:accepted?'AUTH_ACCEPTED':response.status===401?'AUTH_REJECTED':'REVIEW_RESPONSE',http:response.status,code});
    } catch { results.push({name,state:'TRANSPORT_ERROR',http:null}); }
  }
  return {kind:'LEGENDSTUDY_SECRET_AUTH_BUILD_ONLY',branch:env.CF_PAGES_BRANCH==='main'?'main':'UNEXPECTED',
    projectMatches:env.MATH_PROJECT_REF==='stlhijzpjfgwwdgunlsd',results,provider_generation_calls:0};
}
module.exports={probe};
if(require.main===module) {
  probe(process.env).then(result=>{console.log(JSON.stringify(result));process.exit(73);},
    ()=>{console.log('LEGENDSTUDY_DIAGNOSTIC_FAILED');process.exit(74);});
}
