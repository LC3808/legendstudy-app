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
const reply = (status: string, code = 200) => Response.json({ status }, { status: code, headers: { 'Cache-Control': 'no-store' } });
export function handler(ports: Ports, enabled: boolean) {
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
      // Sandbox never issues spendable Production Credit. No environment fallback.
      if (v.environment !== 'Production') return reply('pending');
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
