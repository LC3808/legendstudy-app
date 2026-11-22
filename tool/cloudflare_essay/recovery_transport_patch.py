"""Patch only recovery transport/entry over verified live bytes; never deploy."""
import ast,json,subprocess
from hashlib import sha256
from pathlib import Path
from .admin_recovery_patch import _replace_method,ROOT

def build(live,hashes):
 if {p:sha256(v).hexdigest() for p,v in live.items()}!=hashes:raise ValueError('Capture hash mismatch')
 result=dict(live)
 for p,source,methods in [('entry.py','tool/cloudflare_essay/entry.py',[('Default','fetch')]),('essay_lab/cloudflare_http.py','tool/essay_lab/cloudflare_http.py',[('AsyncOperatingTransport','__init__')])]:
  old=subprocess.check_output(['git','show','825e022:'+source],cwd=ROOT).decode();new=(ROOT/source).read_text();actual=live[p].decode()
  for cls,method in methods:actual=_replace_method(actual,old,new,cls,method)
  if p.endswith('cloudflare_http.py'):
   def function(s):
    n=next(n for n in ast.parse(s).body if isinstance(n,ast.AsyncFunctionDef) and n.name=='fetch_bytes');return n,''.join(s.splitlines(True)[n.lineno-1:n.end_lineno])
   node,text=function(actual)
   if text!=function(old)[1]:raise ValueError('Transport drift')
   lines=actual.splitlines(True);lines[node.lineno-1:node.end_lineno]=[function(new)[1]];actual=''.join(lines).replace('import time\n','import time\nimport io\n',1)
  ast.parse(actual);result[p]=actual.encode()
 return result,dict(changes=[dict(module=p,sha256_before=hashes[p],sha256_after=sha256(v).hexdigest()) for p,v in result.items() if v!=live[p]],preserved={p:hashes[p] for p in live if result[p]==live[p]})
if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('capture',type=Path);p.add_argument('inventory',type=Path);p.add_argument('output',type=Path);a=p.parse_args()
 live={str(p.relative_to(a.capture)):p.read_bytes() for p in a.capture.rglob('*') if p.is_file() and '__pycache__' not in p.parts};hashes={x['name']:x['sha256'] for x in json.loads(a.inventory.read_text())};result,manifest=build(live,hashes)
 for name,data in result.items():p=a.output/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 a.output.with_name(a.output.name+'-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print({'changed':len(manifest['changes']),'preserved':len(manifest['preserved'])})
