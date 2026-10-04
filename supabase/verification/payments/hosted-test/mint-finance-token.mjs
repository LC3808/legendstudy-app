/** Offline Owner tool. Never run with Production material. No network or token output. */
import {createPrivateKey, sign} from 'node:crypto';
import {readFileSync, statSync, writeFileSync} from 'node:fs';
try {
const [keyFile, outputFile, projectRef, subject, lifetime = '3600'] = process.argv.slice(2);
if (process.argv.length > 7 || !['3600', '86400'].includes(lifetime)) throw Error('TEST_LIFETIME_REQUIRED');
const lifetimeSeconds = Number(lifetime);
if (!keyFile || !outputFile || !/^[a-z0-9]{20}$/.test(projectRef || '') || projectRef === 'stlhijzpjfgwwdgunlsd'
  || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(subject || '')) throw Error('TEST_ARGUMENTS_REQUIRED');
if ((statSync(keyFile).mode & 0o077) !== 0) throw Error('PRIVATE_KEY_FILE_PERMISSIONS');
const jwk = JSON.parse(readFileSync(keyFile,'utf8'));
if (jwk.kty !== 'EC' || jwk.crv !== 'P-256' || !jwk.d || typeof jwk.kid !== 'string' || !jwk.kid || jwk.kid.length > 100) throw Error('EXPECTED_SINGLE_ES256_PRIVATE_JWK');
const encode = x => Buffer.from(JSON.stringify(x)).toString('base64url');
const now = Math.floor(Date.now()/1000);
const input = `${encode({alg:'ES256',typ:'JWT',kid:jwk.kid})}.${encode({role:'essay_finance',sub:subject,aud:'authenticated',iss:`https://${projectRef}.supabase.co/auth/v1`,iat:now,exp:now+lifetimeSeconds})}`;
const key = createPrivateKey({key:jwk,format:'jwk'});
const signature = sign('sha256',Buffer.from(input),{key,dsaEncoding:'ieee-p1363'}).toString('base64url');
writeFileSync(outputFile,`${input}.${signature}`,{mode:0o600,flag:'wx'});
console.log(`TEST finance token written to private file; expires in ${lifetimeSeconds} seconds. Token not printed.`);

} catch { console.error('TOKEN_GENERATION_FAILED: check TEST arguments, private file permissions and imported ES256 key; no credentials printed.'); process.exitCode = 1; }
