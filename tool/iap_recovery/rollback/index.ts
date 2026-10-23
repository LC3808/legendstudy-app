import { handler, type VerifiedPurchase } from './core.ts';
import { verifyStore } from './stores.ts';
const env = (key: string): string => { const v = Deno.env.get(key); if (!v) throw Error('UNCONFIGURED'); return v; };
const project = 'https://stlhijzpjfgwwdgunlsd.supabase.co';
Deno.serve(handler({
  async authenticate(token: string) {
    const r = await fetch(`${project}/auth/v1/user`, { headers: { apikey: env('SUPABASE_ANON_KEY'), Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(10000) });
    if (r.status === 401 || r.status === 403) return null;
    if (!r.ok) throw Error('AUTH_UNAVAILABLE');
    const user = await r.json(); return typeof user.id === 'string' ? user.id : null;
  },
  verify: p => verifyStore(p, env),
  async grant(user: string, p: VerifiedPurchase) {
    const r = await fetch(`${project}/rest/v1/rpc/iap_post_verified_purchase`, {
      method: 'POST', headers: { apikey: env('SUPABASE_SERVICE_ROLE_KEY'), Authorization: `Bearer ${env('SUPABASE_SERVICE_ROLE_KEY')}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_user: user, p_platform: p.platform, p_product: p.productId, p_transaction: p.transactionId, p_purchased_at: p.purchasedAt }), signal: AbortSignal.timeout(15000),
    });
    if (!r.ok) throw Error('GRANT_UNAVAILABLE');
    const v = await r.json(); if (!['granted', 'already_processed'].includes(v)) throw Error('GRANT_UNAVAILABLE'); return v;
  },
}, Deno.env.get('IAP_ENABLED') === 'true'));
