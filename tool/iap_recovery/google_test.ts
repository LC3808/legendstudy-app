import { strict as assert } from 'node:assert';
import { googlePurchase, verifyStore } from '../../supabase/functions/verify-iap-purchase/stores.ts';
import { GoogleFailure, Rejected, handler } from '../../supabase/functions/verify-iap-purchase/core.ts';
const purchase={platform:'google' as const,product_id:'com.legendstudy.essay.credit1',transaction_id:'GPA.synthetic',verification_data:'synthetic-token'};
const valid={purchaseState:0,quantity:1,orderId:purchase.transaction_id,obfuscatedExternalAccountId:'synthetic-user',purchaseTimeMillis:String(Date.now())};
Deno.test('Google exact rejection reasons preserve entitlement gates',()=>{
 for(const [change,reason] of [
  [{purchaseState:1},'GOOGLE_PURCHASE_STATE'],[{quantity:2},'GOOGLE_QUANTITY'],[{orderId:'other'},'GOOGLE_ORDER_MISMATCH'],[{obfuscatedExternalAccountId:undefined},'GOOGLE_ACCOUNT_MISSING'],[{purchaseTimeMillis:undefined},'GOOGLE_TIME_MISSING']
 ] as const) assert.throws(()=>googlePurchase(purchase,{...valid,...change}),e=>e instanceof Rejected&&e.reason===reason);
 assert.equal(googlePurchase(purchase,{...valid,purchaseState:2}),null);
 assert.equal(googlePurchase(purchase,{...valid,purchaseType:0})?.environment,'Sandbox');
});
Deno.test('Google OAuth and purchase failures separated; raw errors never logged',async()=>{
 const keys=await crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
 const body=btoa(String.fromCharCode(...new Uint8Array(await crypto.subtle.exportKey('pkcs8',keys.privateKey))));
 const env=(n:string)=>n==='IAP_GOOGLE_SERVICE_ACCOUNT_JSON'?JSON.stringify({client_email:'synthetic@example.invalid',private_key:'-----BEGIN PRIVATE KEY-----\n'+body+'\n-----END PRIVATE KEY-----'}):'com.legendstudy.app';
 let oauth=200, product=200, data:Record<string,unknown>={...valid}, grants=0;
 const fetcher:typeof fetch=async(url,init)=>{
  assert.equal(init?.redirect,'error');
  if(String(url)==='https://oauth2.googleapis.com/token')return oauth===200?Response.json({access_token:'synthetic'}):new Response('DO_NOT_LOG_RESPONSE',{status:oauth});
  assert.ok(String(url).startsWith('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.legendstudy.app/'));
  return product===200?Response.json(data):new Response('DO_NOT_LOG_RESPONSE',{status:product});
 };
 const service=handler({authenticate:async()=>valid.obfuscatedExternalAccountId,verify:p=>verifyStore(p,env,fetcher),grant:async()=>{grants++;return 'granted'}},true);
 const request=()=>new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer synthetic'},body:JSON.stringify(purchase)});
 for(product of [404,410])assert.equal((await service(request())).status,422);
 product=403;await assert.rejects(()=>verifyStore(purchase,env,fetcher),e=>e instanceof GoogleFailure&&e.stage==='PURCHASE'&&e.httpStatus===403);
 product=200;oauth=401;await assert.rejects(()=>verifyStore(purchase,env,fetcher),e=>e instanceof GoogleFailure&&e.stage==='OAUTH'&&e.httpStatus===401);
 oauth=200;data={...valid,purchaseType:0};assert.equal((await (await service(request())).json()).status,'pending');assert.equal(grants,0);
 data={...valid,purchaseState:1,purchaseType:0};assert.equal((await service(request())).status,422);assert.equal(grants,0);
 data={...valid};assert.equal((await (await service(request())).json()).status,'granted');assert.equal(grants,1);
});
