"""Prepare a minimal patch over captured live entry.py. Does not deploy anything."""
import ast, hashlib, json, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def method(s):
 tree=ast.parse(s);cls=next(n for n in tree.body if isinstance(n,ast.ClassDef) and n.name=='Default');return next(n for n in cls.body if isinstance(n,ast.AsyncFunctionDef) and n.name=='fetch')
def segment(s,n):return ''.join(s.splitlines(keepends=True)[n.lineno-1:n.end_lineno])
def prepare(live,baseline,current):
 old=method(baseline);actual=method(live);new=method(current)
 if segment(live,actual)!=segment(baseline,old):raise ValueError('Production fetch drift: review before patch')
 lines=live.splitlines(keepends=True)
 lines[actual.lineno-1:actual.end_lineno]=[segment(current,new)]
 patched=''.join(lines)
 if patched.count('import time\n')!=1:raise ValueError('Import marker drift')
 patched=patched.replace('import time\n','import time\nfrom essay_lab.admin_run_actions import retry_admin_run\n')
 ast.parse(patched)
 return patched
if __name__=='__main__':
 live=Path(sys.argv[1]);out=Path(sys.argv[2]);baseline=Path(sys.argv[3]).read_text()
 text=prepare(live.read_text(),baseline,(ROOT/'tool/cloudflare_essay/entry.py').read_text())
 out.write_text(text)
 print(json.dumps({'input_sha256':hashlib.sha256(live.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'changes':['admin import','fetch admin adapter'],'other_methods_preserved':True}))
