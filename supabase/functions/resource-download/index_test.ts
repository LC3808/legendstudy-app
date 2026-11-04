import { downloadHandler } from "./index.ts";
const id="11111111-1111-4111-8111-111111111111";
const request=()=>new Request("https://example.invalid",{method:"POST",body:JSON.stringify({resource_id:id})});
const allowed={state:"ALLOWED",sha256:"a".repeat(64),filename:"test.pdf"};
function assert(value:unknown){if(!value)throw new Error("assertion failed");}
for(const state of ["PENDING","VIEW_ONLY","OFFICIAL_LINK","unknown"]) Deno.test(`denies ${state} before source fetch`,async()=>{
 let fetched=false; const handler=downloadHandler(async()=>({state}),async()=>{fetched=true;throw new Error();});
 assert((await handler(request())).status===403);assert(!fetched);
});
Deno.test("allowed uses existing resolver",async()=>{
 const handler=downloadHandler(async()=>allowed,async()=>Response.json({status:"resolved",resource_id:id,target:"fixture"}));
 const r=await handler(request());assert(r.status===200);assert((await r.json()).policy.sha256===allowed.sha256);
});
Deno.test("revocation during resolution blocks",async()=>{
 let n=0;const handler=downloadHandler(async()=>++n===1?allowed:{state:"PENDING"},async()=>Response.json({status:"resolved",resource_id:id}));
 assert((await handler(request())).status===403);
});
Deno.test("missing backend denies",async()=>{
 const handler=downloadHandler(async()=>{throw new Error();},async()=>Response.json({}));assert((await handler(request())).status===403);
});
Deno.test("client URL or authorization fields rejected",async()=>{
 const handler=downloadHandler(async()=>allowed,async()=>Response.json({}));
 const r=await handler(new Request("https://example.invalid",{method:"POST",body:JSON.stringify({resource_id:id,target:"https://evil.invalid"})}));assert(r.status===403);
});
