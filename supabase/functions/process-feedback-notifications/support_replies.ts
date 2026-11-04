import type { EmailProvider } from './types.ts';
export type ReplyJob = { notification_id:string; reply_id:string; claim_token:string; source:string; target_id:string; member_email:string|null; body:string; attempt_count:number };
export interface ReplyQueue { claim():Promise<ReplyJob[]>; finish(id:string,token:string,error:string|null):Promise<boolean> }
export async function deliverReplies(queue:ReplyQueue, provider:EmailProvider, sender:string) {
  const jobs=await queue.claim(); let sent=0,failed=0;
  for(const job of jobs){
    let error:string|null=null;
    if(!job.member_email) error='no_recipient';
    else {
      try {
        const result=await provider.send({from:sender,to:job.member_email,subject:'[LegendStudy] 문의에 답변이 등록되었습니다',text:`관리자 답변\n\n${job.body}\n\nAPP: MY → 문의·건의사항 → 내 문의·답변\nWEB: https://lab.legendstudy.com/support/\n문의 ID: ${job.target_id}`},`support-reply/${job.reply_id}`);
        if(!result.ok) error=['network','timeout','rate_limited','provider_5xx','provider_rejected'].includes(result.errorCode)?result.errorCode:'unknown';
      } catch {error='network';}
    }
    if(await queue.finish(job.notification_id,job.claim_token,error)){if(error) failed++;else sent++;}
  }
  return {claimed:jobs.length,sent,failed};
}
