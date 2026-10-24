"""Async Supabase journal. No filesystem, no lease stealing, no automatic retry."""
from uuid import uuid4
from .live_worker import require

class DatabaseCheckpoint:
    def __init__(self,rpc,subject,run,token,session=False):
        self.rpc=rpc
        self.function='essay_exam_session_checkpoint' if session else 'essay_exam_checkpoint'
        self.base=dict(p_subject=subject,p_run=run,p_token=token)
        self.writers={}

    async def read(self,key):
        return await self.rpc(self.function,dict(self.base,p_key=key,p_action='read'))

    async def begin(self,key):
        writer=str(uuid4())
        result=await self.rpc(self.function,dict(self.base,p_key=key,p_action='begin',p_writer=writer))
        require(result.get('started') is True,'EXAM_RECONCILIATION_REQUIRED')
        self.writers[key]=writer

    async def write(self,key,value):
        require(key in self.writers,'CHECKPOINT_WRITER_REQUIRED')
        await self.rpc(self.function,dict(self.base,p_key=key,p_action='write',p_writer=self.writers[key],p_payload=value))
