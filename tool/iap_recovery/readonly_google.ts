/** Local-only existing-order inspector. No grant/consume/ack/refund endpoints. */
import {googleAccessToken} from '../../supabase/functions/verify-iap-purchase/stores.ts';
const credential=Deno.args[0];
if(!credential)throw Error('Credential file path required');
const html='<!doctype html><meta charset="utf-8"><title>Local IAP read-only inspector</title><form method="post" action="/inspect"><label>Existing order <input name="order" autocomplete="off"></label><button>Read existing order</button></form>';
Deno.serve({hostname:'127.0.0.1',port:19093},async(req)=>{
 if(req.method==='GET'&&new URL(req.url).pathname==='/')return new Response(html,{headers:{'Content-Type':'text/html','Cache-Control':'no-store'}});
 if(req.method!=='POST'||new URL(req.url).pathname!=='/inspect'||req.headers.get('origin')!=='http://127.0.0.1:19093')return new Response('Denied',{status:403});
 let stage='INPUT';
 try{
  const form=await req.formData();const order=String(form.get('order')??'');
  if(!/^GPA\.[0-9.-]+$/.test(order))return Response.json({error:'INVALID_ORDER'});
  stage='OAUTH';const raw=await Deno.readTextFile(credential);const token=await googleAccessToken(n=>n==='IAP_GOOGLE_SERVICE_ACCOUNT_JSON'?raw:'com.legendstudy.app');
  const get=async(url:string)=>await fetch(url,{headers:{Authorization:'Bearer '+token},redirect:'error',signal:AbortSignal.timeout(15000)});
  stage='ORDER';const r=await get('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.legendstudy.app/orders/'+encodeURIComponent(order));
  if(!r.ok){await r.body?.cancel();return Response.json({stage,httpStatus:r.status})}
  const data=await r.json();
  const purchaseToken=data.purchaseToken;
  if(typeof purchaseToken!=='string')return Response.json({stage,httpStatus:r.status,orderState:data.state??data.orderState,tokenPresent:false,fieldNames:Object.keys(data)});
  stage='PURCHASE';const p=await get('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.legendstudy.app/purchases/products/com.legendstudy.essay.credit1/tokens/'+encodeURIComponent(purchaseToken));
  if(!p.ok){await p.body?.cancel();return Response.json({stage,httpStatus:p.status})}
  const v=await p.json();
  const summary={stage:'DONE',orderHttp:200,purchaseHttp:200,orderState:data.state??data.orderState,purchaseState:v.purchaseState,purchaseType:v.purchaseType,quantity:v.quantity,acknowledgementState:v.acknowledgementState,consumptionState:v.consumptionState,orderIdMatches:v.orderId===order,accountBindingPresent:typeof v.obfuscatedExternalAccountId==='string',purchaseTimePresent:typeof v.purchaseTimeMillis==='string',purchaseTime:v.purchaseTimeMillis?new Date(Number(v.purchaseTimeMillis)).toISOString():null};
  console.log(JSON.stringify(summary));return Response.json(summary,{headers:{'Cache-Control':'no-store'}});
 }catch{return Response.json({stage,error:'READ_FAILED'},{status:502})}
});
