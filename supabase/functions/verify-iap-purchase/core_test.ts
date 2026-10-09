import { handler, type VerifiedPurchase } from './core.ts';
import { googlePurchase } from './stores.ts';
import { strict as assert } from 'node:assert';
const purchase = { platform: 'google', product_id: 'com.legendstudy.essay.credit3', transaction_id: 'GPA.1234', verification_data: 'test-token' };
const verified: VerifiedPurchase = { platform: 'google', productId: purchase.product_id, transactionId: purchase.transaction_id, accountId: 'owner', purchasedAt: new Date().toISOString(), environment: 'Production', revoked: false };
function fixture(options: { user?: string | null; enabled?: boolean; verified?: VerifiedPurchase | null; fail?: boolean } = {}) {
  let grants = 0;
  const run = handler({ authenticate: async () => options.user === undefined ? 'owner' : options.user, verify: async () => options.verified === undefined ? verified : options.verified, grant: async () => { if (options.fail) throw Error('network'); return ++grants === 1 ? 'granted' : 'already_processed'; } }, options.enabled ?? true);
  return { grants: () => grants, call: (body: unknown = purchase) => run(new Request('https://test.invalid', { method: 'POST', headers: { Authorization: 'Bearer user-token' }, body: JSON.stringify(body) })) };
}
Deno.test('verified account-bound store purchase grants; retry settles idempotently', async () => { const f = fixture(); assert.equal((await (await f.call()).json()).status, 'granted'); assert.equal((await (await f.call()).json()).status, 'already_processed'); });
for (const [name, options] of Object.entries({ loggedOut: { user: null }, disabled: { enabled: false }, pending: { verified: null }, anotherAccount: { verified: { ...verified, accountId: 'other' } }, sandbox: { verified: { ...verified, environment: 'Sandbox' as const } }, revoked: { verified: { ...verified, revoked: true } }, skuMismatch: { verified: { ...verified, productId: 'other' } }, txMismatch: { verified: { ...verified, transactionId: 'other' } }, futureDate: { verified: { ...verified, purchasedAt: '2999-01-01' } } })) {
 Deno.test(`${name}: no ledger call`, async () => { const f = fixture(options); const result = await (await f.call()).json(); assert.notEqual(result.status, 'granted'); assert.equal(f.grants(), 0); });
}
Deno.test('ledger transport failure stays pending, never settled', async () => { const f = fixture({ fail: true }); assert.equal((await (await f.call()).json()).status, 'pending'); });
Deno.test('malformed/unapproved/oversize payload denied', async () => { const f = fixture(); for (const p of [null, {}, { ...purchase, product_id: 'com.legendstudy.essay.credit20' }, { ...purchase, verification_data: 'x'.repeat(70000) }]) assert.equal((await (await f.call(p)).json()).status, 'rejected'); assert.equal(f.grants(), 0); });
Deno.test('Google pending/cancelled/multiquantity/unbound receipts cannot grant', () => {
 assert.equal(googlePurchase(purchase as never, { purchaseState: 2 }), null);
 for (const data of [{ purchaseState: 1 }, { purchaseState: 0 }, { purchaseState: 0, quantity: 2 }]) assert.throws(() => googlePurchase(purchase as never, data));
 const data = { purchaseState: 0, orderId: purchase.transaction_id, obfuscatedExternalAccountId: 'owner', purchaseTimeMillis: String(Date.now()), quantity: 1 };
 assert.equal(googlePurchase(purchase as never, data)?.accountId, 'owner');
 assert.equal(googlePurchase(purchase as never, { ...data, purchaseType: 0 })?.environment, 'Sandbox');
});
