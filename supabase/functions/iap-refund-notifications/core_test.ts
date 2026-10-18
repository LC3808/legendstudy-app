import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { appleEventType, handler, Rejected, type Ports, type RefundEvent } from './core.ts';

const APPLE: RefundEvent = { platform: 'apple', transaction: 'TX1', eventId: 'UUID1', eventType: 'REFUND' };
const GOOGLE: RefundEvent = { platform: 'google', transaction: 'GPA.1', eventId: 'MID1', eventType: 'VOIDED' };

function ports(over: Partial<Ports> = {}): Ports {
  return {
    verifyApple: () => Promise.resolve(APPLE),
    verifyGoogle: () => Promise.resolve(GOOGLE),
    recover: (e) => Promise.resolve({ status: e.platform === 'apple' ? 'PROCESSED' : 'UNMATCHED' }),
    ...over,
  };
}
const post = (body: unknown, headers: Record<string, string> = {}) =>
  new Request('https://x/', { method: 'POST', headers, body: JSON.stringify(body) });

async function status(res: Response) { return { code: res.status, status: (await res.json()).status }; }

Deno.test('non-POST is rejected', async () => {
  const res = await handler(ports(), true)(new Request('https://x/', { method: 'GET' }));
  assertEquals(res.status, 405);
});

Deno.test('disabled flag short-circuits before any verification', async () => {
  let called = false;
  const res = await handler(ports({ verifyApple: () => { called = true; return Promise.resolve(APPLE); } }), false)(post({ signedPayload: 'x' }));
  assertEquals(res.status, 503);
  assertEquals(called, false);
});

Deno.test('Apple signedPayload → verify → recover → 200 PROCESSED', async () => {
  assertEquals(await status(await handler(ports(), true)(post({ signedPayload: 'jws' }))), { code: 200, status: 'PROCESSED' });
});

Deno.test('Google Pub/Sub push → verify → recover', async () => {
  const res = await handler(ports(), true)(post({ message: { data: 'ZGF0YQ==', messageId: 'MID1' } }, { Authorization: 'Bearer tok' }));
  assertEquals(await status(res), { code: 200, status: 'UNMATCHED' });
});

Deno.test('Google push missing messageId → 400', async () => {
  const res = await handler(ports(), true)(post({ message: { data: 'ZGF0YQ==' } }, { Authorization: 'Bearer tok' }));
  assertEquals(res.status, 400);
});

Deno.test('bad store signature (Rejected) → 401, recover never called', async () => {
  let recovered = false;
  const res = await handler(ports({ verifyApple: () => { throw new Rejected(); }, recover: () => { recovered = true; return Promise.resolve({ status: 'x' }); } }), true)(post({ signedPayload: 'bad' }));
  assertEquals(res.status, 401);
  assertEquals(recovered, false);
});

Deno.test('valid non-refund notification → 200 ignored, no recover', async () => {
  let recovered = false;
  const res = await handler(ports({ verifyApple: () => Promise.resolve(null), recover: () => { recovered = true; return Promise.resolve({ status: 'x' }); } }), true)(post({ signedPayload: 'renewal' }));
  assertEquals(await status(res), { code: 200, status: 'ignored' });
  assertEquals(recovered, false);
});

Deno.test('unknown body shape → 400', async () => {
  assertEquals((await handler(ports(), true)(post({ hello: 'world' }))).status, 400);
});

Deno.test('transient recover failure → 503 (store redelivers)', async () => {
  const res = await handler(ports({ recover: () => { throw new Error('db down'); } }), true)(post({ signedPayload: 'jws' }));
  assertEquals(res.status, 503);
});

Deno.test('appleEventType maps only refund types', () => {
  assertEquals(appleEventType('REFUND'), 'REFUND');
  assertEquals(appleEventType('REVOKE'), 'REVOKE');
  assertEquals(appleEventType('REFUND_REVERSED'), 'REFUND_REVERSED');
  assertEquals(appleEventType('DID_RENEW'), null);
  assertEquals(appleEventType('CONSUMPTION_REQUEST'), null);
});
