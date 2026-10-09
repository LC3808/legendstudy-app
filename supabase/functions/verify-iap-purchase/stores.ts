import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from 'npm:@apple/app-store-server-library@2.0.0';
import { Buffer } from 'node:buffer';
import { Rejected, type Purchase, type VerifiedPurchase } from './core.ts';
type Env = (name: string) => string;
const json = async (response: Response) => { if (!response.ok) { if (response.status === 404 || response.status === 410) throw new Rejected(); throw Error('STORE_UNAVAILABLE'); } return await response.json(); };
const b64 = (v: Uint8Array) => Buffer.from(v).toString('base64url');
export async function googleAccessToken(env: Env): Promise<string> {
  const credentials = JSON.parse(env('IAP_GOOGLE_SERVICE_ACCOUNT_JSON'));
  if (typeof credentials.client_email !== 'string' || typeof credentials.private_key !== 'string') throw Error('STORE_UNCONFIGURED');
  const now = Math.floor(Date.now() / 1000);
  const input = b64(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))) + '.' + b64(new TextEncoder().encode(JSON.stringify({ iss: credentials.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 300 })));
  const key = await crypto.subtle.importKey('pkcs8', Buffer.from(credentials.private_key.replace(/-----[^-]+-----|\s/g, ''), 'base64'), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const assertion = input + '.' + b64(new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(input))));
  const result = await json(await fetch('https://oauth2.googleapis.com/token', { method: 'POST', body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }), signal: AbortSignal.timeout(15000) }));
  if (typeof result.access_token !== 'string') throw Error('STORE_UNAVAILABLE');
  return result.access_token;
}
export function googlePurchase(p: Purchase, data: Record<string, unknown>): VerifiedPurchase | null {
  if (data.purchaseState === 2) return null;
  if (data.purchaseState !== 0 || data.quantity !== undefined && data.quantity !== 1 ||
      data.orderId !== p.transaction_id || typeof data.obfuscatedExternalAccountId !== 'string' ||
      typeof data.purchaseTimeMillis !== 'string') throw new Rejected();
  return { platform: 'google', productId: p.product_id, transactionId: data.orderId as string,
    accountId: data.obfuscatedExternalAccountId, purchasedAt: new Date(Number(data.purchaseTimeMillis)).toISOString(),
    environment: data.purchaseType === 0 ? 'Sandbox' : 'Production', revoked: false };
}
export async function verifyStore(p: Purchase, env: Env): Promise<VerifiedPurchase | null> {
  if (p.platform === 'google') {
    const token = await googleAccessToken(env);
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(env('IAP_GOOGLE_PACKAGE_ID'))}/purchases/products/${encodeURIComponent(p.product_id)}/tokens/${encodeURIComponent(p.verification_data)}`;
    return googlePurchase(p, await json(await fetch(url, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(15000) })));
  }
  const environment = env('IAP_APPLE_ENVIRONMENT') === 'Production' ? Environment.PRODUCTION : Environment.SANDBOX;
  const bundle = env('IAP_APPLE_BUNDLE_ID');
  const appId = Number(env('IAP_APPLE_APP_ID'));
  if (!Number.isSafeInteger(appId) || appId <= 0) throw Error('STORE_UNCONFIGURED');
  const api = new AppStoreServerAPIClient(env('IAP_APPLE_PRIVATE_KEY'), env('IAP_APPLE_KEY_ID'), env('IAP_APPLE_ISSUER_ID'), bundle, environment);
  // Always query Apple; never trust client receipt/JWS claims.
  const transaction = await api.getTransactionInfo(p.transaction_id);
  if (!transaction.signedTransactionInfo) throw Error('STORE_UNAVAILABLE');
  const roots = JSON.parse(env('IAP_APPLE_ROOT_CERTIFICATES_BASE64')) as string[];
  if (!Array.isArray(roots) || !roots.length) throw Error('STORE_UNCONFIGURED');
  const verifier = new SignedDataVerifier(roots.map(r => Buffer.from(r, 'base64')), true, environment, bundle, appId);
  const t = await verifier.verifyAndDecodeTransaction(transaction.signedTransactionInfo);
  if (t.type !== 'Consumable' || t.quantity !== 1 || !t.appAccountToken || !t.purchaseDate || !t.transactionId || !t.productId || t.inAppOwnershipType !== 'PURCHASED') throw new Rejected();
  return { platform: 'apple', productId: t.productId, transactionId: t.transactionId,
    accountId: t.appAccountToken.toLowerCase(), purchasedAt: new Date(t.purchaseDate).toISOString(),
    environment: t.environment === 'Production' ? 'Production' : 'Sandbox', revoked: t.revocationDate !== undefined };
}
