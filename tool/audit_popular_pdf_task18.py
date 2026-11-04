import sys,json,urllib.request,concurrent.futures
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/'tool'))
from ingestion.parser import parse_html,parse_title,split_resource_kind,split_subject
ids='1700 1574 1649 1706 1710 1509 1618 1487 1686 1516 1634 1507 1501 1525 1483 1665 1485 1435'.split()
config=json.loads(Path(sys.argv[1]).read_text())
base=config['SUPABASE_URL'].rstrip('/')
assert base=='https://stlhijzpjfgwwdgunlsd.supabase.co'
key=config.get('SUPABASE_PUBLISHABLE_KEY') or config.get('SUPABASE_ANON_KEY')
def get(url,headers={}):
 with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=30) as r:return r.read().decode()
def audit(pid):
 try:
  raw=parse_html(pid,get('https://legendstudy.com/'+pid))
  from urllib.parse import urlencode
  q=urlencode({'select':'id,title,source_url','source_url':'eq.'+raw.url})
  content=json.loads(get(base+'/rest/v1/content_items?'+q,{'apikey':key}))
  rows=[]
  for c in content:
   q=urlencode({'select':'id,title,source_label,source_url,resource_type,exam_subject_id','content_item_id':'eq.'+c['id'],'limit':'1000'})
   rows+=json.loads(get(base+'/rest/v1/resources?'+q,{'apikey':key}))
  files=[]
  for a in raw.attachments:
   if '.pdf' not in a.display_name.lower():continue
   left,kind,raw_kind=split_resource_kind(a.display_name)
   matched=[r for r in rows if r['source_url']==a.unsigned_url]
   files.append({'name':a.display_name,'source_key':a.resource_key,'source_url':a.unsigned_url,'type':kind,'subject':split_subject(left)[0], 'resource_ids':[r['id'] for r in matched],'exam_subject_ids':[r['exam_subject_id'] for r in matched], 'permission':'PENDING','binary_verified':False})
  return {'post_id':pid,'url':raw.url,'title':raw.title,'facts':parse_title(raw.title,raw.category),'attachment_count':len(raw.attachments),'pdf_count':len(files),'content_ids':[c['id'] for c in content],'files':files}
 except Exception as e:return {'post_id':pid,'error':type(e).__name__}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex: result=list(ex.map(audit,ids))
p=Path('wiki/evidence/task18-popular-pdf-inventory.json');p.parent.mkdir(exist_ok=True)
p.write_text(json.dumps({'observed_date':'2026-11-04','ranking_period':'UNKNOWN','additional_posts':'NOT_REQUIRED_OWNER_CONFIRMED_18','posts':result},ensure_ascii=False,indent=2)+'\n')
for r in result:print(r['post_id'],r.get('title',r.get('error')),r.get('pdf_count'),sum(len(f['resource_ids'])==1 for f in r.get('files',[])))
