"""Build a held recovery/quality candidate over a verified 204cfb37 capture.
No upload, environment activation, DB change or student action.
"""
import ast,json,subprocess
from pathlib import Path
from hashlib import sha256
from .admin_recovery_patch import prepare,EXISTING,NEW,ROOT,repository_path,_method,_replace_method

def source(ref,path):return subprocess.check_output(['git','show',ref+':'+repository_path(path)],cwd=ROOT)
def once(text,before,after):
    if text.count(before)!=1:raise ValueError('Runtime patch context drift')
    return text.replace(before,after,1)
def build(live,hashes):
    baseline={p:source('9bffbc0',p) for p in EXISTING}
    current={p:(ROOT/repository_path(p)).read_bytes() for p in (*EXISTING,NEW)}
    result,_=prepare(live,baseline,current,hashes)
    result['entry.py']=_replace_method(result['entry.py'].decode(),baseline['entry.py'].decode(),current['entry.py'].decode(),'Default','configuration').encode()
    path='essay_lab/live_worker.py';actual=result[path].decode();old=source('8b06758',path).decode();new=(ROOT/repository_path(path)).read_text()
    actual=_replace_method(actual,old,new,'Worker','__init__')
    node,method=_method(actual,'Worker','execution_steps')
    if method.replace('value=self.prepare_input(claim)','value=package(claim,self.cache)')!=_method(old,'Worker','execution_steps')[1]:raise ValueError('Worker execution drift')
    actual=once(actual,method,_method(new,'Worker','start_quality')[1]+'\n\n'+_method(new,'Worker','execution_steps')[1].replace('value=package(claim,self.cache)','value=self.prepare_input(claim)'))
    result[path]=actual.encode()
    path='essay_lab/cloudflare_runtime.py';actual=result[path].decode();old=source('8b06758',path).decode();new=(ROOT/repository_path(path)).read_text()
    actual=_replace_method(actual,old,new,'CloudflareExamRuntime','__init__')
    actual=once(actual,'        journal=DatabaseCheckpoint',"        if self.quality_provider_factory is not None:\n            require(await self.rpc('essay_exam_recovery_quality_ready',{})=='quality-repair-2-1-v1','QUALITY_POLICY_NOT_INSTALLED')\n        journal=DatabaseCheckpoint")
    start=new.index('            repair=None');end=new.index('                permit=RuntimePermit',start)
    actual=once(actual,'            return ReviewedRuntimeWorker(channel,provider,cache,self.reviewer,review,persist_receipt,checkpoint,\n',new[start:end])
    result[path]=actual.encode()
    path='essay_lab/semantic_review.py'
    if live[path]!=source('8b06758',path):raise ValueError('Independent review drift')
    result[path]=(ROOT/repository_path(path)).read_bytes()
    result['essay_lab/quality_repair.py']=(ROOT/'tool/essay_lab/quality_repair.py').read_bytes()
    for name,data in result.items():
        if name.endswith('.py') and not name.startswith('python_modules/'):ast.parse(data)
    return result,dict(changes=[dict(module=p,sha256_before=hashes.get(p),sha256_after=sha256(v).hexdigest()) for p,v in result.items() if v!=live.get(p)],
        preserved={p:hashes[p] for p in live if result[p]==live[p]},deployment_performed=False,quality_activation=False)

if __name__=='__main__':
 import argparse
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('capture',type=Path);parser.add_argument('inventory',type=Path);parser.add_argument('output',type=Path);a=parser.parse_args()
 if a.output.exists():raise ValueError('Output must be new')
 live={str(p.relative_to(a.capture)):p.read_bytes() for p in a.capture.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
 hashes={x['name']:x['sha256'] for x in json.loads(a.inventory.read_text())}
 result,manifest=build(live,hashes)
 for name,data in result.items():p=a.output/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 a.output.with_name(a.output.name+'-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print({'modules':len(result),'changed':len(manifest['changes']),'preserved':len(manifest['preserved']),'deployment':False})
