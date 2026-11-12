"""Exact live-bundle Ewha adapter/Registry deployment, no Provider traffic.
Plan first. Upload an inactive version, validate it, then explicitly activate.
Rollback reactivates the recorded old version; all queue bindings remain intact.
"""
import argparse,ast,base64,copy,email.parser,email.policy,hashlib,json,os,shutil,uuid,urllib.request,urllib.error
from pathlib import Path
APP=Path(__file__).resolve().parents[1]
BASE='https://api.cloudflare.com/client/v4/accounts/b9d221b20fdf8b9a9a8df0971a6b2347/workers/scripts/legendstudy-essay-reviewed'
def main():
 p=argparse.ArgumentParser();p.add_argument('backup',type=Path);p.add_argument('mode',choices=['plan','upload-version','activate','rollback']);a=p.parse_args();B=a.backup;O=APP/'supabase/candidates/ewha_public_20261112'
 read=lambda n:json.loads((B/n).read_text())
 old=read('worker-deployments.private.json')['result']['deployments'][0]['versions'];assert len(old)==1 and old[0]['percentage']==100
 settings=read('worker-settings.private.json')['result'];new=copy.deepcopy(settings)
 reg=ast.literal_eval((B/'worker-source/registry_asset.py').read_text().removeprefix('REGISTRY = ').strip());before=copy.deepcopy(reg)
 extra=json.loads((APP/'.local/ewha-public-20261112/essay-registry.private.json').read_text())['exams'];assert len(extra)==12
 oldids={e['examId'] for e in reg['exams']};oldqs={q['id'] for e in reg['exams'] for q in e['questions']};assert not oldids&{e['examId'] for e in extra};assert not oldqs&{q['id'] for e in extra for q in e['questions']}
 reg['exams']+=extra;assert reg['exams'][:-12]==before['exams']
 stage=B/'worker-stage';shutil.rmtree(stage,ignore_errors=True);stage.mkdir()
 msg=email.parser.BytesParser(policy=email.policy.default).parsebytes(('Content-Type: '+(B/'worker-content-type.txt').read_text()+'\r\n\r\n').encode()+(B/'worker-content.private.bin').read_bytes())
 for part in msg.iter_parts():
  n=part.get_filename() or part.get_param('name',header='content-disposition');assert n and '..' not in Path(n).parts
  d=stage/n;d.parent.mkdir(parents=True,exist_ok=True);d.write_bytes(part.get_payload(decode=True))
 (stage/'registry_asset.py').write_text('REGISTRY = '+repr(reg)+'\n')
 f=stage/'essay_lab/material_runtime.py';s=f.read_text();x="e['binding']['role'] in ('question','passage')";y="m['role'] in ('question','shared_passage')"
 assert s.count(x)==s.count(y)==1;s=s.replace(x,"e['binding']['role'] in ('question','passage','exam_intent','scoring_criteria')").replace(y,"ROLE.get(m['role'])==e['binding']['role']");f.write_text(s)
 files={str(f.relative_to(stage)):hashlib.sha256(f.read_bytes()).hexdigest() for f in stage.rglob('*') if f.is_file()};changed=[n for n,h in files.items() if h!=hashlib.sha256((B/'worker-source'/n).read_bytes()).hexdigest()];assert set(changed)=={'registry_asset.py','essay_lab/material_runtime.py'}
 bindings=[];counts=None
 for b in new['bindings']:
  if b['name']!='ESSAY_PUBLIC_EXAMS':bindings.append(dict(name=b['name'],type='inherit'));continue
  assert b['type']=='plain_text' and b['text'].startswith('uuid64:');raw=base64.b64decode(b['text'][7:]);ids=[str(uuid.UUID(bytes=raw[i:i+16])) for i in range(0,len(raw),16)];added=[e['examId'] for e in extra];assert not set(ids)&set(added)
  after=ids+added;assert len(set(after))==len(after);counts=[len(ids),len(after)]
  bindings.append(dict(name=b['name'],type='plain_text',text='uuid64:'+base64.b64encode(b''.join(uuid.UUID(i).bytes for i in after)).decode()))
 metadata={k:new[k] for k in ['compatibility_date','compatibility_flags','limits','tail_consumers','logpush']};metadata.update(main_module='entry.py',bindings=bindings,keep_bindings=['secret_text','secret_key'],annotations={'workers/message':'Ewha 36 official-rubric connections; preserve engine, prompts, Credit and bindings'})
 plan=dict(modules=len(files),changed_modules=changed,preserved_modules=len(files)-2,old_version=old[0]['version_id'],public_exam_count=counts,registry_exams=[len(before['exams']),len(reg['exams'])],provider_calls=0,files=files)
 (B/'worker-plan.json').write_text(json.dumps(plan,indent=2)+'\n');(O/'worker-plan.json').write_text(json.dumps(plan,indent=2)+'\n')
 print({k:v for k,v in plan.items() if k!='files'})
 if a.mode=='plan':return
 token=os.environ['CLOUDFLARE_API_TOKEN']
 def api(path='',method='GET',data=None,content_type=None):
  headers={'Authorization':'Bearer '+token}
  if content_type:headers['Content-Type']=content_type
  try:
   with urllib.request.urlopen(urllib.request.Request(BASE+path,data=data,method=method,headers=headers),timeout=90) as r:result=json.load(r)
  except urllib.error.HTTPError as e:
   (B/'worker-api-error.private.txt').write_bytes(e.read());raise RuntimeError('Cloudflare request failed; see private error receipt') from None
  assert result['success'];return result['result']
 def post(path,obj):return api(path,'POST',json.dumps(obj).encode(),'application/json')
 current=api('/deployments')['deployments'][0]['versions'];current_settings=api('/settings')
 if a.mode=='upload-version':
  assert current==old and current_settings==settings,'WORKER_DRIFT'
  boundary='ewha-'+uuid.uuid4().hex;parts=[]
  def add(name,data,ctype,filename=None):
   h='--'+boundary+'\r\nContent-Disposition: form-data; name="'+name+'"'+(' ;filename="'+filename+'"' if filename else '')+'\r\nContent-Type: '+ctype+'\r\n\r\n';parts.append(h.encode()+data+b'\r\n')
  add('metadata',json.dumps(metadata).encode(),'application/json')
  for n in sorted(files):
   ctype=('application/javascript+module' if n.startswith('python_modules/workers/') and n.endswith('.js') else 'application/octet-stream') if n.startswith('python_modules/') else ('text/x-python' if n.endswith('.py') else 'application/octet-stream')
   add(n,(stage/n).read_bytes(),ctype,n)
  parts.append(('--'+boundary+'--\r\n').encode());v=api('/versions?bindings_inherit=strict','POST',b''.join(parts),'multipart/form-data; boundary='+boundary)
  (B/'worker-upload-version.private.json').write_text(json.dumps(v));check=api('/versions/'+v['id']);(B/'worker-upload-version-detail.private.json').write_text(json.dumps(check));actual={b['name']:b for b in check['resources']['bindings']};expected={b['name']:b for b in read('worker-version-before.private.json')['result']['resources']['bindings']};expected['ESSAY_PUBLIC_EXAMS']=next(b for b in bindings if b['name']=='ESSAY_PUBLIC_EXAMS');assert actual==expected,'VERSION_BINDING_DRIFT';assert api('/deployments')['deployments'][0]['versions']==old,'INACTIVE_VERSION_CHANGED_DEPLOYMENT';print({'inactive_version':v['id']});return
 v=read('worker-upload-version.private.json')['id'];assert read('worker-upload-version-detail.private.json')['id']==v;expected=[{'version_id':v,'percentage':100}]
 if a.mode=='activate':assert current==old,'DEPLOYMENT_DRIFT';target=expected
 else:assert current==expected,'ROLLBACK_DEPLOYMENT_DRIFT';target=old
 result=post('/deployments',dict(strategy='percentage',versions=target,annotations={'workers/message':'Ewha scoped connection '+a.mode}))
 (B/('worker-'+a.mode+'-receipt.private.json')).write_text(json.dumps(result));assert api('/deployments')['deployments'][0]['versions']==target
 print({'mode':a.mode,'version':target[0]['version_id']})
if __name__=='__main__':main()
