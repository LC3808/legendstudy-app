"""Project existing Manus research into a shared, public-metadata-only read model.
Never author university rows, route evaluators from administrative labels or mutate DB.
"""
import json,re,hashlib
from pathlib import Path
from urllib.parse import urlparse

def region(v):
 if '서울' in v or 'Seoul' in v:return '서울'
 if any(k in v for k in ['경기','인천','Gyeonggi','Incheon']):return '경기·인천'
 return '기타 지역'
def source_url(v):
 u=urlparse(v)
 return u.scheme in ('http','https') and bool(u.hostname) and not u.username and not u.password

def build(catalog,identities):
 if catalog['version']!='essay-research-preview-v1':raise ValueError('SOURCE_CONTRACT')
 by_name={u['name']:u for u in identities['universities']};out={};seen=set()
 for o in catalog['offerings']:
  key=o['universityId']
  if o['id'] in seen:raise ValueError('DUPLICATE_OFFERING')
  seen.add(o['id'])
  u=by_name.get(o['name']);item=out.setdefault(key,dict(sourceUniversityId=key,universityId=u['id'] if u else None,canonicalSlug=u['slug'] if u else None,name=o['name'],offerings=[]))
  if item['name']!=o['name']:raise ValueError('IDENTITY_CONFLICT')
  # Future-date row remains in source, excluded from public claims; university retained.
  if o['metadataState']=='QUARANTINED':continue
  rows=[r for r in o['rawMaster'] if r.get('evidence_status') in ('OFFICIAL_CONFIRMED','OFFICIAL_PARTIAL')]
  if not rows:continue
  # Display/filter types come from literal official essay-type text, NOT track/department.
  # This discovery classification NEVER authorizes a question's evaluator.
  raw_types=[r['essay_type'] for r in rows if r.get('essay_type')]
  types=[]
  text=' '.join(raw_types)
  for label,pattern in [('인문',r'인문|언어|사회논술'),('경제·경영',r'경제|경영'),('수리',r'수리|수학\s*논술'),('과학',r'과학\s*논술|과학\([0-9]+%\)|과학 제시문 서논술')]:
   if re.search(pattern,text):types.append(label)
  sources=list(dict.fromkeys(r['official_source_url'] for r in rows if source_url(r.get('official_source_url',''))))
  item['offerings'].append(dict(id=o['id'],campus=o['campus'],region=region(o['region']),admissionYear=o['year'],admissionNames=o['admissionNames'],types=types,rawEssayTypes=raw_types,sourceIds=o['sourceIds'],sources=sources,verifiedAt=o['checkedAt'],sourceStatus=o['sourceStatus']))
 result=dict(version='essay-public-catalog-v1',asOf=catalog['asOf'],identityVerifiedAt=identities['verifiedAt'],universities=sorted(out.values(),key=lambda u:u['name']),evaluationRouting='QUESTION_RUNTIME_ONLY')
 if any(not u['offerings'] for u in result['universities']):raise ValueError('UNVERIFIED_UNIVERSITY')
 return result

def main():
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--identities',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 result=build(json.loads(a.source.read_text()),json.loads(a.identities.read_text()))
 result['sourceSha256']=hashlib.sha256(a.source.read_bytes()).hexdigest()
 a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps(dict(universities=len(result['universities']),offerings=sum(len(u['offerings']) for u in result['universities']),canonicalIds=sum(u['universityId'] is not None for u in result['universities']))))
if __name__=='__main__':main()
