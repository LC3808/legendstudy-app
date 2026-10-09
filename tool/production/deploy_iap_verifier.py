"""Deploy one disabled-by-default verifier through the supported Management API.
Preserves the platform JWT boundary; does not set secrets or activate IAP.
"""
import json,os,uuid,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
BASE='https://api.supabase.com/v1/projects/stlhijzpjfgwwdgunlsd'
AUTH={'Authorization':'Bearer '+os.environ['SUPABASE_ACCESS_TOKEN']}
boundary='legendstudy-'+uuid.uuid4().hex
parts=[]
def part(name,data,filename=None):
    head=f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"'
    if filename:head+=f'; filename="{filename}"'
    parts.append((head+'\r\n\r\n').encode()+data+b'\r\n')
meta={'name':'verify-iap-purchase','entrypoint_path':'supabase/functions/verify-iap-purchase/index.ts','verify_jwt':True}
part('metadata',json.dumps(meta).encode())
for name in ['index.ts','core.ts','stores.ts']:
    path='supabase/functions/verify-iap-purchase/'+name
    part('file',(ROOT/path).read_bytes(),path)
parts.append(f'--{boundary}--\r\n'.encode())
req=urllib.request.Request(BASE+'/functions/deploy?slug=verify-iap-purchase',data=b''.join(parts),headers={**AUTH,'Content-Type':f'multipart/form-data; boundary={boundary}'})
with urllib.request.urlopen(req,timeout=120) as f:r=json.load(f)
print(json.dumps({k:r.get(k) for k in ['slug','version','status','verify_jwt']}))
