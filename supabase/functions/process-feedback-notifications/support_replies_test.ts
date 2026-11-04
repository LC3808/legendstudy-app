import {deliverReplies, type ReplyJob, type ReplyQueue} from './support_replies.ts';
import {ResendEmailProvider} from './resend_provider.ts';
const job:ReplyJob={notification_id:'n',reply_id:'r',claim_token:'lease',source:'APP',target_id:'f',member_email:'synthetic@example.invalid',body:'합성 답변 <script>본문</script>',attempt_count:1};
function assert(value:unknown){if(!value)throw new Error('assertion failed');}
Deno.test('APP/WEB reply email adapter uses same queue IDs, plain text, stable retry key',async()=>{
 const calls:RequestInit[]=[];const provider=new ResendEmailProvider('synthetic',async(_url,init)=>{calls.push(init!);return new Response('{}',{status:200});});
 const queue:ReplyQueue={claim:async()=>[job,{...job,notification_id:'n2',reply_id:'r2',source:'WEB'}],finish:async(_id,_token,error)=>error===null};
 const result=await deliverReplies(queue,provider,'feedback@example.invalid');
 assert(result.sent===2);const mail=JSON.parse(calls[0].body as string);assert(mail.to[0]===job.member_email&&mail.text.includes(job.body)&&!mail.html);assert((calls[0].headers as Record<string,string>)['Idempotency-Key']==='support-reply/r');
});
Deno.test('provider failure records retry result without changing saved reply',async()=>{
 let finalized:string|null=null;const queue:ReplyQueue={claim:async()=>[job],finish:async(_id,token,error)=>{assert(token==='lease');finalized=error;return true;}};
 const result=await deliverReplies(queue,new ResendEmailProvider('synthetic',async()=>new Response('',{status:503})),'from@example.invalid');assert(finalized==='provider_5xx'&&result.failed===1);
});
Deno.test('missing recipient never sends, lost lease never reports delivery',async()=>{
 let calls=0;const provider={send:async()=>{calls++;return {ok:true as const};}};
 const result=await deliverReplies({claim:async()=>[{...job,member_email:null}],finish:async(_id,_token,error)=>{assert(error==='no_recipient');return false;}},provider,'from@example.invalid');assert(calls===0&&result.sent===0);
});
