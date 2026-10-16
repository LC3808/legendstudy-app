import { handler, type RefundEvent } from './core.ts';
import { verifyApple, verifyGoogle } from './stores.ts';
const env = (key: string): string => { const v = Deno.env.get(key); if (!v) throw Error('UNCONFIGURED'); return v; };
// This function's own project (Supabase injects SUPABASE_URL); prod fallback kept safe.
const project = Deno.env.get('SUPABASE_URL') ?? 'https://stlhijzpjfgwwdgunlsd.supabase.co';
Deno.serve(handler({
  verifyApple: s => verifyApple(s, env),
  verifyGoogle: (t, d, id) => verifyGoogle(t, d, id, env),
  async recover(e: RefundEvent) {
    const r = await fetch(`${project}/rest/v1/rpc/iap_revoke_refunded_purchase`, {
      method: 'POST',
      headers: { apikey: env('SUPABASE_SERVICE_ROLE_KEY'), Authorization: `Bearer ${env('SUPABASE_SERVICE_ROLE_KEY')}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_platform: e.platform, p_transaction: e.transaction, p_event_id: e.eventId, p_event_type: e.eventType, p_raw: e.raw ?? null }),
      signal: AbortSignal.timeout(15000),
    });
    if (!r.ok) throw Error('RECOVER_UNAVAILABLE');
    const v = await r.json();
    return { status: typeof v?.status === 'string' ? v.status : 'PROCESSED' };
  },
}, Deno.env.get('IAP_REFUND_ENABLED') === 'true'));
