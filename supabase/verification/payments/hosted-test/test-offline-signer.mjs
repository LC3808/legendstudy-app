/** Ephemeral synthetic keys only; no network, tokens or private keys in output/artifacts. */
import assert from 'node:assert/strict';
import {generateKeyPairSync,verify} from 'node:crypto';
import {mkdtempSync,writeFileSync,readFileSync,statSync,rmSync,existsSync,chmodSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
const root=mkdtempSync('/private/tmp/payment-signer-');
const script=new URL('./mint-finance-token.mjs',import.meta.url);
try {
 const {privateKey,publicKey}=generateKeyPairSync('ec',{namedCurve:'P-256'});
 const jwk=privateKey.export({format:'jwk'});jwk.kid='synthetic-only';
 writeFileSync(root+'/key',JSON.stringify(jwk),{mode:0o600});
 const run=(ref='syntheticprojecttest',out='token',...extra)=>spawnSync(process.execPath,[script.pathname,root+'/key',root+'/'+out,ref,'00000000-0000-4000-8000-000000000001',...extra],{encoding:'utf8'});
 assert.equal(run().status,0);
 const token=readFileSync(root+'/token','utf8');const[h,p,s]=token.split('.');
 const claims=JSON.parse(Buffer.from(p,'base64url'));
 assert(verify('sha256',Buffer.from(h+'.'+p),{key:publicKey,dsaEncoding:'ieee-p1363'},Buffer.from(s,'base64url')));
 assert.equal(claims.role,'essay_finance');assert.equal(claims.exp-claims.iat,3600);assert.equal(statSync(root+'/token').mode&0o777,0o600);
 assert.equal(run('syntheticprojecttest','day','86400').status,0);
 const dayToken=readFileSync(root+'/day','utf8');const[dh,dp,ds]=dayToken.split('.');
 const dayClaims=JSON.parse(Buffer.from(dp,'base64url'));
 assert.equal(dayClaims.exp-dayClaims.iat,86400);assert.equal(dayClaims.role,'essay_finance');
 assert.equal(dayClaims.iss,claims.iss);assert.equal(dayClaims.aud,claims.aud);assert.equal(dayClaims.sub,claims.sub);
 assert(verify('sha256',Buffer.from(dh+'.'+dp),{key:publicKey,dsaEncoding:'ieee-p1363'},Buffer.from(ds,'base64url')));
 assert.equal(statSync(root+'/day').mode&0o777,0o600);
 for (const ttl of ['0','-1','3600.5','86401','Infinity','NaN','86400x','']) {
  const result=run('syntheticprojecttest','invalid-ttl',ttl);
  assert.notEqual(result.status,0);assert(!existsSync(root+'/invalid-ttl'));
 }
 assert.notEqual(run('syntheticprojecttest','extra','86400','extra').status,0);assert(!existsSync(root+'/extra'));
 assert.notEqual(run('stlhijzpjfgwwdgunlsd','forbidden-day','86400').status,0);assert(!existsSync(root+'/forbidden-day'));
 assert.notEqual(run().status,0);assert.equal(readFileSync(root+'/token','utf8'),token);
 assert.notEqual(run('stlhijzpjfgwwdgunlsd','forbidden').status,0);assert(!existsSync(root+'/forbidden'));
 // Production denial stays the default. The opt-in is the only way in, it is bounded, and it
 // unlocks one named project rather than the guard itself.
 assert.notEqual(run('stlhijzpjfgwwdgunlsd','review-no-opt-in','604800').status,0);assert(!existsSync(root+'/review-no-opt-in'));
 assert.equal(run('stlhijzpjfgwwdgunlsd','review','604800','--allow-production-review').status,0);
 const reviewToken=readFileSync(root+'/review','utf8');const[rh,rp,rs]=reviewToken.split('.');
 const reviewClaims=JSON.parse(Buffer.from(rp,'base64url'));
 assert.equal(reviewClaims.role,'essay_finance');assert.equal(reviewClaims.exp-reviewClaims.iat,604800);
 assert.equal(reviewClaims.iss,'https://stlhijzpjfgwwdgunlsd.supabase.co/auth/v1');assert.equal(reviewClaims.aud,'authenticated');
 assert.deepEqual(Object.keys(reviewClaims).sort(),['aud','exp','iat','iss','role','sub']);
 assert(verify('sha256',Buffer.from(rh+'.'+rp),{key:publicKey,dsaEncoding:'ieee-p1363'},Buffer.from(rs,'base64url')));
 assert.equal(statSync(root+'/review').mode&0o777,0o600);
 assert.equal(run('stlhijzpjfgwwdgunlsd','review-hour','3600','--allow-production-review').status,0);
 for (const ttl of ['604801','31536000']) {
  assert.notEqual(run('stlhijzpjfgwwdgunlsd','review-ttl-'+ttl,ttl,'--allow-production-review').status,0);
  assert(!existsSync(root+'/review-ttl-'+ttl));
 }
 // The opt-in is scoped: it does not widen another project's lifetime, and the token carries
 // the single finance capability and nothing else.
 assert.notEqual(run('syntheticprojecttest','review-widened','604800','--allow-production-review').status,0);
 assert(!existsSync(root+'/review-widened'));
 chmodSync(root+'/key',0o644);assert.notEqual(run('syntheticprojecttest','insecure').status,0);
 chmodSync(root+'/key',0o600);writeFileSync(root+'/key','PRIVATE_SYNTHETIC_INVALID_JSON');const bad=run('syntheticprojecttest','bad');assert.notEqual(bad.status,0);assert(!bad.stderr.includes('PRIVATE_SYNTHETIC_INVALID_JSON'));
 console.log('OFFLINE_SIGNER: signature, role/default1h/explicit24h/invalid-TTL, private mode, overwrite denial, Production denial, REVIEW opt-in (bounded TTL, scoped, single capability), insecure-file denial, sanitized-error PASS');
} finally {rmSync(root,{recursive:true,force:true});}
