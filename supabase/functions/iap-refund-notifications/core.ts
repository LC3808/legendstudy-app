/** Store refund/void notifications → verified Credit recovery.
 *
 * Public endpoint (no Supabase JWT): each path authenticates the STORE itself —
 * Apple via the signed JWS (App Store Server Notifications V2), Google via the
 * Pub/Sub push OIDC token (Real-time Developer Notifications). A client refund
 * claim is never trusted. Actionable events call the idempotent recovery RPC
 * `iap_revoke_refunded_purchase`; non-refund notifications are acknowledged and
 * ignored. The ledger consistency (unused-only clawback, shortfall, idempotency)
 * lives in the RPC; this function only verifies + routes. */
export class Rejected extends Error {}

export type RefundEvent = {
  platform: 'apple' | 'google';
  transaction: string;
  eventId: string;
  eventType: 'REFUND' | 'REVOKE' | 'VOIDED' | 'REFUND_REVERSED';
  raw?: Record<string, unknown>;
};

export type Ports = {
  /** Verify an Apple ASSN V2 `signedPayload`. Throws [Rejected] on bad signature;
   * returns null for a valid non-refund notification (ignored). */
  verifyApple(signedPayload: string): Promise<RefundEvent | null>;
  /** Verify a Google RTDN Pub/Sub push: the OIDC bearer token + the message.
   * Throws [Rejected] on bad token; returns null for a non-void / partial
   * notification handled manually. */
  verifyGoogle(authToken: string | null, messageData: string, messageId: string): Promise<RefundEvent | null>;
  /** Idempotent credit recovery (service-role RPC). */
  recover(e: RefundEvent): Promise<{ status: string }>;
};

const ok = (status: string, code = 200) => Response.json({ status }, { status: code, headers: { 'Cache-Control': 'no-store' } });

/** `enabled` (IAP_REFUND_ENABLED) is a belt-and-braces off switch; store
 * verification is the real gate. Bad signature → 401; unconfigured/outage →
 * 503 (store redelivers); success/ignore/duplicate → 200 (acknowledged). */
export function handler(ports: Ports, enabled: boolean) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== 'POST') return ok('rejected', 405);
    if (!enabled) return ok('disabled', 503);
    const auth = request.headers.get('Authorization')?.match(/^Bearer (\S+)$/)?.[1] ?? null;
    try {
      const reader = request.body?.getReader();
      if (!reader) return ok('rejected', 400);
      let bytes = 0; const chunks: Uint8Array[] = [];
      while (true) { const part = await reader.read(); if (part.done) break; bytes += part.value.length; if (bytes > 262144) { await reader.cancel(); return ok('rejected', 413); } chunks.push(part.value); }
      const buffer = new Uint8Array(bytes); let offset = 0;
      for (const part of chunks) { buffer.set(part, offset); offset += part.length; }
      const body = JSON.parse(new TextDecoder().decode(buffer)) as Record<string, unknown>;

      let event: RefundEvent | null;
      if (typeof body.signedPayload === 'string') {
        event = await ports.verifyApple(body.signedPayload);
      } else if (body.message && typeof (body.message as Record<string, unknown>).data === 'string') {
        const m = body.message as { data: string; messageId?: string; message_id?: string };
        const id = typeof m.messageId === 'string' ? m.messageId : (typeof m.message_id === 'string' ? m.message_id : '');
        if (!id) return ok('rejected', 400);
        event = await ports.verifyGoogle(auth, m.data, id);
      } else {
        return ok('rejected', 400);
      }

      if (!event) return ok('ignored'); // valid but non-actionable → acknowledge
      const r = await ports.recover(event);
      return ok(r.status); // PROCESSED / ALREADY_RECOVERED / UNMATCHED / REVERSED / IGNORED
    } catch (e) {
      if (e instanceof Rejected) return ok('rejected', 401);
      if (e instanceof SyntaxError) return ok('rejected', 400);
      // Unconfigured credentials / store or DB outage → never ack; store redelivers.
      return ok('pending', 503);
    }
  };
}

/** Map an Apple ASSN V2 notificationType to our event type, or null to ignore. */
export function appleEventType(notificationType: string): RefundEvent['eventType'] | null {
  switch (notificationType) {
    case 'REFUND': return 'REFUND';
    case 'REVOKE': return 'REVOKE';
    case 'REFUND_REVERSED': return 'REFUND_REVERSED';
    default: return null; // CONSUMPTION_REQUEST, DID_RENEW, etc. — not a refund
  }
}
