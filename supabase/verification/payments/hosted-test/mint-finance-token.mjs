/** Offline Owner tool. No network and no token output. */
import {createPrivateKey, sign} from 'node:crypto';
import {readFileSync, statSync, writeFileSync} from 'node:fs';
try {
// Production is denied by default and stays denied by default. `--allow-production-review`
// is the explicit opt-in the card review needs: it unlocks exactly one named project and
// widens the lifetime only for that project, up to a bounded seven days. It never removes
// the denial for anything else, and a token minted this way is disposable — revoke it by
// removing it from the payment environment.
const productionRef = 'stlhijzpjfgwwdgunlsd';
const productionReview = process.argv.includes('--allow-production-review');
const args = process.argv.slice(2).filter(arg => arg !== '--allow-production-review');
const [keyFile, outputFile, projectRef, subject, lifetime = '3600'] = args;
const lifetimes = productionReview && projectRef === productionRef ? ['3600', '86400', '604800'] : ['3600', '86400'];
if (args.length > 5 || !lifetimes.includes(lifetime)) throw Error('TEST_LIFETIME_REQUIRED');
const lifetimeSeconds = Number(lifetime);
if (!keyFile || !outputFile || !/^[a-z0-9]{20}$/.test(projectRef || '')
  || (projectRef === productionRef && !productionReview)
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
console.log(`${productionReview ? 'REVIEW' : 'TEST'} finance token written to private file; expires in ${lifetimeSeconds} seconds. Token not printed.`);

} catch { console.error('TOKEN_GENERATION_FAILED: check arguments, private file permissions and imported ES256 key; no credentials printed.'); process.exitCode = 1; }
