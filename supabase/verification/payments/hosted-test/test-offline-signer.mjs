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
 const run=(ref='syntheticprojecttest',out='token')=>spawnSync(process.execPath,[script.pathname,root+'/key',root+'/'+out,ref,'00000000-0000-4000-8000-000000000001'],{encoding:'utf8'});
 assert.equal(run().status,0);
 const token=readFileSync(root+'/token','utf8');const[h,p,s]=token.split('.');
 const claims=JSON.parse(Buffer.from(p,'base64url'));
 assert(verify('sha256',Buffer.from(h+'.'+p),{key:publicKey,dsaEncoding:'ieee-p1363'},Buffer.from(s,'base64url')));
 assert.equal(claims.role,'essay_finance');assert.equal(claims.exp-claims.iat,3600);assert.equal(statSync(root+'/token').mode&0o777,0o600);
 assert.notEqual(run().status,0);assert.equal(readFileSync(root+'/token','utf8'),token);
 assert.notEqual(run('stlhijzpjfgwwdgunlsd','forbidden').status,0);assert(!existsSync(root+'/forbidden'));
 chmodSync(root+'/key',0o644);assert.notEqual(run('syntheticprojecttest','insecure').status,0);
 chmodSync(root+'/key',0o600);writeFileSync(root+'/key','PRIVATE_SYNTHETIC_INVALID_JSON');const bad=run('syntheticprojecttest','bad');assert.notEqual(bad.status,0);assert(!bad.stderr.includes('PRIVATE_SYNTHETIC_INVALID_JSON'));
 console.log('OFFLINE_SIGNER: signature, role/expiry, private mode, overwrite denial, Production denial, insecure-file denial, sanitized-error PASS');
} finally {rmSync(root,{recursive:true,force:true});}
