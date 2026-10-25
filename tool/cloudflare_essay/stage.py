"""Build disposable Cloudflare source from canonical code/Registry; no raw PDF/assets."""
from pathlib import Path
import argparse,shutil,json,ast
ROOT=Path(__file__).resolve().parents[2]
def main():
 p=argparse.ArgumentParser();p.add_argument('directory',type=Path);p.add_argument('--registry',type=Path,default=ROOT/'supabase/reviews/essay-source-registration/manifest.json');args=p.parse_args()
 target=args.directory.resolve();target.mkdir(parents=True,exist_ok=False)
 source=target/'src';source.mkdir();package=source/'essay_lab';package.mkdir()
 # Build copies are disposable; there is one maintained Runtime/Registry source.
 pending=[node.module.split('.')[1] for node in ast.walk(ast.parse(Path(__file__).with_name('entry.py').read_text()))
          if isinstance(node,ast.ImportFrom) and node.module and node.module.startswith('essay_lab.')]
 seen=set()
 while pending:
  name=pending.pop()
  if name in seen:continue
  seen.add(name);file=ROOT/'tool/essay_lab'/(name+'.py')
  shutil.copy2(file,package/file.name)
  for node in ast.walk(ast.parse(file.read_text())):
   if isinstance(node,ast.ImportFrom) and node.level==1 and node.module:
    pending.append(node.module.split('.')[0])
 (package/'__init__.py').write_text('')
 (package/'prompts').mkdir()
 # Keep pinned historical policies and the current module import available.
 # Packaging assets never selects or activates a prompt version.
 for prompt in sorted((ROOT/'tool/essay_lab/prompts').glob('*.txt')):
  shutil.copy2(prompt,package/'prompts'/prompt.name)
 shutil.copy2(Path(__file__).with_name('entry.py'),source/'entry.py')
 # Explicit local trusted metadata manifest; never fetched from student input.
 registry=json.loads(args.registry.read_text())
 ids=[exam['examId'] for exam in registry['exams']]
 if len(ids)!=len(set(ids)):raise ValueError('DUPLICATE_EXAM_ID')
 questions=[q['id'] for exam in registry['exams'] for q in exam['questions']]
 if len(questions)!=len(set(questions)):raise ValueError('DUPLICATE_QUESTION_ID')
 (source/'registry_asset.py').write_text('REGISTRY = '+repr(registry)+'\n')
 (target/'package.json').write_text(json.dumps({'private':True,'devDependencies':{'wrangler':'4.150.0'}})+'\n')
 (target/'pyproject.toml').write_text('[project]\nname="legendstudy-essay-worker"\nversion="0.1.0"\nrequires-python=">=3.13"\ndependencies=[]\n[dependency-groups]\ndev=["workers-py==1.17.7", "workers-runtime-sdk==1.9.3"]\n')
 (target/'wrangler.jsonc').write_text(json.dumps({'name':'legendstudy-essay-reviewed','main':'src/entry.py',
  'compatibility_date':'2026-10-13','compatibility_flags':['python_workers','global_fetch_strictly_public'],'workers_dev':False,
  'vars':{'ESSAY_EXECUTION_ENABLED':'false'},'observability':{'enabled':False},
  'queues':{'producers':[{'binding':'ESSAY_QUEUE','queue':'legendstudy-essay-exams'}],
    'consumers':[{'queue':'legendstudy-essay-exams','max_batch_size':1,'max_retries':3,'dead_letter_queue':'legendstudy-essay-exams-dlq'}]},
  'rules':[{'type':'Data','globs':['**/*.txt'],'fallthrough':True}]},indent=2)+'\n')
 print(target)
if __name__=='__main__':main()
