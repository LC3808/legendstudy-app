import { handler, PRODUCTION_PROJECT_REF, Rejected, sandboxGrantAllowed, type VerifiedPurchase } from './core.ts';
import { googlePurchase } from './stores.ts';
import { strict as assert } from 'node:assert';
const purchase = { platform: 'google', product_id: 'com.legendstudy.essay.credit3', transaction_id: 'GPA.1234', verification_data: 'test-token' };
const verified: VerifiedPurchase = { platform: 'google', productId: purchase.product_id, transactionId: purchase.transaction_id, accountId: 'owner', purchasedAt: new Date().toISOString(), environment: 'Production', revoked: false };
function fixture(options: { user?: string | null; enabled?: boolean; verified?: VerifiedPurchase | null; fail?: boolean; sandboxGrant?: boolean; verifyThrows?: Error } = {}) {
  let grants = 0;
  const run = handler({ authenticate: async () => options.user === undefined ? 'owner' : options.user, verify: async () => { if (options.verifyThrows) throw options.verifyThrows; return options.verified === undefined ? verified : options.verified; }, grant: async () => { if (options.fail) throw Error('network'); return ++grants === 1 ? 'granted' : 'already_processed'; } }, options.enabled ?? true, options.sandboxGrant ?? false);
  return { grants: () => grants, call: (body: unknown = purchase) => run(new Request('https://test.invalid', { method: 'POST', headers: { Authorization: 'Bearer user-token' }, body: JSON.stringify(body) })) };
}
Deno.test('verified account-bound store purchase grants; retry settles idempotently', async () => { const f = fixture(); assert.equal((await (await f.call()).json()).status, 'granted'); assert.equal((await (await f.call()).json()).status, 'already_processed'); });
for (const [name, options] of Object.entries({ loggedOut: { user: null }, disabled: { enabled: false }, pending: { verified: null }, anotherAccount: { verified: { ...verified, accountId: 'other' } }, sandbox: { verified: { ...verified, environment: 'Sandbox' as const } }, revoked: { verified: { ...verified, revoked: true } }, skuMismatch: { verified: { ...verified, productId: 'other' } }, txMismatch: { verified: { ...verified, transactionId: 'other' } }, futureDate: { verified: { ...verified, purchasedAt: '2999-01-01' } } })) {
 Deno.test(`${name}: no ledger call`, async () => { const f = fixture(options); const result = await (await f.call()).json(); assert.notEqual(result.status, 'granted'); assert.equal(f.grants(), 0); });
}
Deno.test('ledger transport failure stays pending, never settled', async () => { const f = fixture({ fail: true }); assert.equal((await (await f.call()).json()).status, 'pending'); });
Deno.test('forged/invalid store transaction (Rejected) is rejected, never granted', async () => { const f = fixture({ verifyThrows: new Rejected() }); assert.equal((await (await f.call()).json()).status, 'rejected'); assert.equal(f.grants(), 0); });

// --- Sandbox isolated-test grant gate (fail-closed) ---
const sandbox: VerifiedPurchase = { ...verified, environment: 'Sandbox' };
Deno.test('Sandbox tx grants ONLY when the test gate is on; replay is idempotent', async () => {
  const on = fixture({ verified: sandbox, sandboxGrant: true });
  assert.equal((await (await on.call()).json()).status, 'granted');
  assert.equal((await (await on.call()).json()).status, 'already_processed');
});
Deno.test('Sandbox tx with the gate OFF stays pending (no grant)', async () => {
  const off = fixture({ verified: sandbox, sandboxGrant: false });
  assert.equal((await (await off.call()).json()).status, 'pending');
  assert.equal(off.grants(), 0);
});
Deno.test('Production tx is unaffected by the sandbox gate (still grants)', async () => {
  const f = fixture({ verified, sandboxGrant: true });
  assert.equal((await (await f.call()).json()).status, 'granted');
});

// --- Fail-closed sandboxGrantAllowed: every condition required; production denylisted ---
const testRef = 'testprojref0000';
const ok: Record<string, string> = { IAP_ALLOW_SANDBOX_GRANT: 'true', IAP_APPLE_ENVIRONMENT: 'Sandbox', SUPABASE_URL: `https://${testRef}.supabase.co`, IAP_SANDBOX_PROJECT_REF: testRef };
const get = (e: Record<string, string>) => (k: string) => e[k];
Deno.test('sandboxGrantAllowed: true only when all server-side conditions hold', () => {
  assert.equal(sandboxGrantAllowed(get(ok)), true);
  assert.equal(sandboxGrantAllowed(get({ ...ok, IAP_ALLOW_SANDBOX_GRANT: 'false' })), false); // flag off
  assert.equal(sandboxGrantAllowed(get({ ...ok, IAP_APPLE_ENVIRONMENT: 'Production' })), false); // not sandbox env
  assert.equal(sandboxGrantAllowed(get({ ...ok, IAP_SANDBOX_PROJECT_REF: 'otherref' })), false); // allowlist mismatch
  const { SUPABASE_URL: _drop, ...noUrl } = ok; assert.equal(sandboxGrantAllowed(get(noUrl)), false); // ref unresolved
});
Deno.test('sandboxGrantAllowed: production project ref can NEVER grant sandbox (fail-closed denylist)', () => {
  // Even with flag on, sandbox apple env, and the allowlist mistakenly set to production.
  const prod = { IAP_ALLOW_SANDBOX_GRANT: 'true', IAP_APPLE_ENVIRONMENT: 'Sandbox', SUPABASE_URL: `https://${PRODUCTION_PROJECT_REF}.supabase.co`, IAP_SANDBOX_PROJECT_REF: PRODUCTION_PROJECT_REF };
  assert.equal(sandboxGrantAllowed(get(prod)), false);
});
Deno.test('malformed/unapproved/oversize payload denied', async () => { const f = fixture(); for (const p of [null, {}, { ...purchase, product_id: 'com.legendstudy.essay.credit20' }, { ...purchase, verification_data: 'x'.repeat(70000) }]) assert.equal((await (await f.call(p)).json()).status, 'rejected'); assert.equal(f.grants(), 0); });
Deno.test('Google pending/cancelled/multiquantity/unbound receipts cannot grant', () => {
 assert.equal(googlePurchase(purchase as never, { purchaseState: 2 }), null);
 for (const data of [{ purchaseState: 1 }, { purchaseState: 0 }, { purchaseState: 0, quantity: 2 }]) assert.throws(() => googlePurchase(purchase as never, data));
 const data = { purchaseState: 0, orderId: purchase.transaction_id, obfuscatedExternalAccountId: 'owner', purchaseTimeMillis: String(Date.now()), quantity: 1 };
 assert.equal(googlePurchase(purchase as never, data)?.accountId, 'owner');
 assert.equal(googlePurchase(purchase as never, { ...data, purchaseType: 0 })?.environment, 'Sandbox');
});
