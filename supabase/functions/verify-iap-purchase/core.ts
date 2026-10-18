/** Store verification only; no client-supplied quantity, identity or grant. */
export type Purchase = { platform: 'apple' | 'google'; product_id: string; transaction_id: string; verification_data: string };
export type VerifiedPurchase = { platform: 'apple' | 'google'; productId: string; transactionId: string; accountId: string; purchasedAt: string; environment: 'Production' | 'Sandbox'; revoked: boolean };
export const products: Readonly<Record<string, number>> = Object.freeze({
  'com.legendstudy.essay.credit1': 1, 'com.legendstudy.essay.credit3': 3,
  'com.legendstudy.essay.credit5': 5, 'com.legendstudy.essay.credit10': 10,
});
export class Rejected extends Error {}
export type Ports = {
  authenticate(token: string): Promise<string | null>;
  verify(purchase: Purchase): Promise<VerifiedPurchase | null>;
  grant(user: string, verified: VerifiedPurchase): Promise<'granted' | 'already_processed'>;
};

/** The production Supabase project ref. Hard-denylisted for Sandbox grants so a
 * mis-set flag in production can never post spendable Credit from a Sandbox tx. */
export const PRODUCTION_PROJECT_REF = 'stlhijzpjfgwwdgunlsd';

/** Extract the `<ref>` from `https://<ref>.supabase.co` (server-side only). */
export function projectRef(url: string | undefined | null): string | null {
  return url?.match(/^https:\/\/([a-z0-9]+)\.supabase\.co\/?$/)?.[1] ?? null;
}

/** Fail-closed gate for granting Credit on a **Sandbox** transaction.
 *
 * Requires ALL of (no single variable enables it; every input is server-side,
 * never client-supplied):
 *  - `IAP_ALLOW_SANDBOX_GRANT === 'true'` (off by default),
 *  - `IAP_APPLE_ENVIRONMENT === 'Sandbox'` (verifier is pointed at Apple sandbox),
 *  - the function's own project ref resolves AND is NOT the production ref
 *    (denylist — production can never grant a Sandbox tx even if the flag is set),
 *  - that same project ref equals the explicit `IAP_SANDBOX_PROJECT_REF` allowlist.
 *
 * Production transactions are unaffected and still grant via the normal path. */
export function sandboxGrantAllowed(get: (key: string) => string | undefined): boolean {
  const self = projectRef(get('SUPABASE_URL'));
  return get('IAP_ALLOW_SANDBOX_GRANT') === 'true' &&
    get('IAP_APPLE_ENVIRONMENT') === 'Sandbox' &&
    self !== null &&
    self !== PRODUCTION_PROJECT_REF &&
    self === get('IAP_SANDBOX_PROJECT_REF');
}

const reply = (status: string, code = 200) => Response.json({ status }, { status: code, headers: { 'Cache-Control': 'no-store' } });

/** `sandboxGrant` (default false) is the fail-closed decision from
 * [sandboxGrantAllowed], computed once from server env in index.ts. When false,
 * a Sandbox transaction stays `pending` and only Production transactions grant —
 * i.e. production behavior is identical to before. */
export function handler(ports: Ports, enabled: boolean, sandboxGrant = false) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== 'POST') return reply('rejected', 405);
    const token = request.headers.get('Authorization')?.match(/^Bearer (\S+)$/)?.[1];
    if (!token) return reply('rejected', 401);
    let user: string | null;
    try { user = await ports.authenticate(token); } catch { return reply('pending', 503); }
    if (!user) return reply('rejected', 401);
    if (!enabled) return reply('pending', 503);
    try {
      // Bounded streaming read: Content-Length alone is not trustworthy.
      const reader = request.body?.getReader();
      if (!reader) return reply('rejected', 400);
      let bytes = 0; const chunks: Uint8Array[] = [];
      while (true) { const part = await reader.read(); if (part.done) break; bytes += part.value.length; if (bytes > 65536) { await reader.cancel(); return reply('rejected', 413); } chunks.push(part.value); }
      const buffer = new Uint8Array(bytes); let offset = 0;
      for (const part of chunks) { buffer.set(part, offset); offset += part.length; }
      const p = JSON.parse(new TextDecoder().decode(buffer)) as Purchase;
      if (!p || !['apple', 'google'].includes(p.platform) || !Object.hasOwn(products, p.product_id) ||
        typeof p.transaction_id !== 'string' || !/^[A-Za-z0-9._-]{1,256}$/.test(p.transaction_id) ||
        typeof p.verification_data !== 'string' || !p.verification_data.length || p.verification_data.length > 60000) return reply('rejected', 400);
      const v = await ports.verify(p);
      if (!v) return reply('pending');
      if (v.accountId !== user || v.productId !== p.product_id || v.platform !== p.platform ||
          v.transactionId !== p.transaction_id || v.revoked) return reply('rejected', 422);
      // Grant only a verified Production tx, or a Sandbox tx when the fail-closed
      // test gate is on (isolated test project only). Any other environment, or a
      // Sandbox tx without the gate, stays pending — never a Production grant.
      if (v.environment !== 'Production' && !(v.environment === 'Sandbox' && sandboxGrant)) return reply('pending');
      const paid = Date.parse(v.purchasedAt);
      if (!Number.isFinite(paid) || paid > Date.now() + 60000) return reply('rejected', 422);
      return reply(await ports.grant(user, v));
    } catch (e) {
      if (e instanceof Rejected || e instanceof SyntaxError) return reply('rejected', 422);
      // Store outage / auth / unconfigured credentials / ledger failure: never settle.
      return reply('pending', 503);
    }
  };
}
