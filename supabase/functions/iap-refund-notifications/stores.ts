import { Environment, SignedDataVerifier } from 'npm:@apple/app-store-server-library@2.0.0';
import { Buffer } from 'node:buffer';
import { appleEventType, Rejected, type RefundEvent } from './core.ts';
type Env = (name: string) => string;

/** Verify an Apple App Store Server Notification V2 and map a refund to our event. */
export async function verifyApple(signedPayload: string, env: Env): Promise<RefundEvent | null> {
  const environment = env('IAP_APPLE_ENVIRONMENT') === 'Production' ? Environment.PRODUCTION : Environment.SANDBOX;
  const bundle = env('IAP_APPLE_BUNDLE_ID');
  const appId = Number(env('IAP_APPLE_APP_ID'));
  if (!Number.isSafeInteger(appId) || appId <= 0) throw Error('STORE_UNCONFIGURED');
  const roots = JSON.parse(env('IAP_APPLE_ROOT_CERTIFICATES_BASE64')) as string[];
  if (!Array.isArray(roots) || !roots.length) throw Error('STORE_UNCONFIGURED');
  const verifier = new SignedDataVerifier(roots.map(r => Buffer.from(r, 'base64')), true, environment, bundle, appId);
  let payload;
  try { payload = await verifier.verifyAndDecodeNotification(signedPayload); }
  catch { throw new Rejected(); } // bad signature / wrong bundle / wrong environment
  const type = appleEventType(String(payload.notificationType));
  if (!type) return null; // not a refund notification — acknowledge & ignore
  const signed = payload.data?.signedTransactionInfo;
  if (!signed) throw new Rejected();
  const t = await verifier.verifyAndDecodeTransaction(signed);
  if (!t.transactionId) throw new Rejected();
  return {
    platform: 'apple', transaction: t.transactionId, eventId: String(payload.notificationUUID), eventType: type,
    raw: { notificationType: payload.notificationType, subtype: payload.subtype ?? null, productId: t.productId ?? null },
  };
}

const b64urlToJson = (s: string) => JSON.parse(new TextDecoder().decode(Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64')));

/** Verify the Google Pub/Sub push OIDC token, then map a voided purchase. */
export async function verifyGoogle(authToken: string | null, messageData: string, messageId: string, env: Env): Promise<RefundEvent | null> {
  if (!authToken) throw new Rejected();
  const [h, p, sig] = authToken.split('.');
  if (!h || !p || !sig) throw new Rejected();
  const header = b64urlToJson(h) as { kid?: string; alg?: string };
  const claims = b64urlToJson(p) as { iss?: string; aud?: string; email?: string; email_verified?: boolean; exp?: number };
  if (header.alg !== 'RS256' || !header.kid) throw new Rejected();
  // Verify signature against Google's published OIDC keys.
  const certs = await (await fetch('https://www.googleapis.com/oauth2/v3/certs', { signal: AbortSignal.timeout(10000) })).json();
  const jwk = (certs.keys as Array<Record<string, string>>).find(k => k.kid === header.kid);
  if (!jwk) throw new Rejected();
  const key = await crypto.subtle.importKey('jwk', jwk as JsonWebKey, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key,
    Buffer.from(sig.replace(/-/g, '+').replace(/_/g, '/'), 'base64'), new TextEncoder().encode(`${h}.${p}`));
  if (!valid) throw new Rejected();
  // Claim checks: Google-issued, our audience + push service account, unexpired.
  const iss = claims.iss ?? '';
  if (!(iss === 'accounts.google.com' || iss === 'https://accounts.google.com')) throw new Rejected();
  if (claims.aud !== env('IAP_GOOGLE_RTDN_AUDIENCE')) throw new Rejected();
  if (claims.email !== env('IAP_GOOGLE_RTDN_SA_EMAIL') || claims.email_verified !== true) throw new Rejected();
  if (typeof claims.exp !== 'number' || claims.exp * 1000 < Date.now()) throw new Rejected();

  const note = b64urlToJson(messageData) as {
    packageName?: string;
    voidedPurchaseNotification?: { purchaseToken?: string; orderId?: string; productType?: number; refundType?: number };
  };
  if (note.packageName !== env('IAP_GOOGLE_PACKAGE_ID')) throw new Rejected();
  const v = note.voidedPurchaseNotification;
  if (!v || typeof v.orderId !== 'string' || !v.orderId) return null; // not a void (e.g. a purchase notification)
  // refundType 1 = full refund (auto-recover unused). 2 = quantity/partial → manual.
  if (v.refundType !== undefined && v.refundType !== 1) return null;
  return {
    platform: 'google', transaction: v.orderId, eventId: messageId, eventType: 'VOIDED',
    raw: { productType: v.productType ?? null, refundType: v.refundType ?? 1 },
  };
}
