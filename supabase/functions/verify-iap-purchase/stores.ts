import { verifyApple } from './apple.ts';
import { Buffer } from 'node:buffer';
import { GoogleFailure, Rejected, type Purchase, type VerifiedPurchase } from './core.ts';
type Env = (name: string) => string;
async function googleJson(response: Response, stage: 'OAUTH' | 'PURCHASE') {
  if (!response.ok) {
    await response.body?.cancel();
    if (stage === 'PURCHASE' && response.status === 404) throw new Rejected('GOOGLE_TOKEN_NOT_FOUND');
    if (stage === 'PURCHASE' && response.status === 410) throw new Rejected('GOOGLE_TOKEN_GONE');
    throw new GoogleFailure(stage, response.status);
  }
  try { return await response.json(); } catch { throw new GoogleFailure(stage, response.status); }
}
const b64 = (v: Uint8Array) => Buffer.from(v).toString('base64url');
export async function googleAccessToken(env: Env, fetcher: typeof fetch = fetch): Promise<string> {
  let credentials;
  try { credentials = JSON.parse(env('IAP_GOOGLE_SERVICE_ACCOUNT_JSON')); } catch { throw new GoogleFailure('CONFIG'); }
  if (typeof credentials.client_email !== 'string' || typeof credentials.private_key !== 'string') throw new GoogleFailure('CONFIG');
  const now = Math.floor(Date.now() / 1000);
  const input = b64(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))) + '.' + b64(new TextEncoder().encode(JSON.stringify({ iss: credentials.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 300 })));
  let key: CryptoKey;
  try { key = await crypto.subtle.importKey('pkcs8', Buffer.from(credentials.private_key.replace(/-----[^-]+-----|\s/g, ''), 'base64'), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']); } catch { throw new GoogleFailure('KEY_IMPORT'); }
  let assertion: string;
  try { assertion = input + '.' + b64(new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(input)))); } catch { throw new GoogleFailure('SIGN'); }
  const result = await googleJson(await fetcher('https://oauth2.googleapis.com/token', { method: 'POST', body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }), redirect: 'error', signal: AbortSignal.timeout(15000) }).catch(() => {throw new GoogleFailure('OAUTH')}), 'OAUTH');
  if (typeof result.access_token !== 'string') throw new GoogleFailure('OAUTH');
  return result.access_token;
}
export function googlePurchase(p: Purchase, data: Record<string, unknown>): VerifiedPurchase | null {
  if (data.purchaseState === 2) return null;
  if (data.purchaseState !== 0) throw new Rejected('GOOGLE_PURCHASE_STATE');
  if (data.quantity !== undefined && data.quantity !== 1) throw new Rejected('GOOGLE_QUANTITY');
  if (data.orderId !== p.transaction_id) throw new Rejected('GOOGLE_ORDER_MISMATCH');
  if (typeof data.obfuscatedExternalAccountId !== 'string') throw new Rejected('GOOGLE_ACCOUNT_MISSING');
  if (typeof data.purchaseTimeMillis !== 'string') throw new Rejected('GOOGLE_TIME_MISSING');
  return { platform: 'google', productId: p.product_id, transactionId: data.orderId as string,
    accountId: data.obfuscatedExternalAccountId, purchasedAt: new Date(Number(data.purchaseTimeMillis)).toISOString(),
    environment: data.purchaseType === 0 ? 'Sandbox' : 'Production', revoked: false };
}
export async function verifyStore(p: Purchase, env: Env, fetcher: typeof fetch = fetch): Promise<VerifiedPurchase | null> {
  if (p.platform === 'google') {
    const token = await googleAccessToken(env, fetcher);
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(env('IAP_GOOGLE_PACKAGE_ID'))}/purchases/products/${encodeURIComponent(p.product_id)}/tokens/${encodeURIComponent(p.verification_data)}`;
    return googlePurchase(p, await googleJson(await fetcher(url, { headers: { Authorization: `Bearer ${token}` }, redirect: 'error', signal: AbortSignal.timeout(15000) }).catch(() => {throw new GoogleFailure('PURCHASE')}), 'PURCHASE'));
  }
  return await verifyApple(p, env, fetcher);
}
