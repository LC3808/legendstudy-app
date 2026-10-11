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

# Public admissions facts only; never copy passages, model prompts or research notes.
FACT_FIELDS = ('intake_count','exam_date','exam_time','question_count','answer_length','csat_minimum','essay_weight','school_record_weight')
def public_value(value):
 value=str(value or '').strip()
 if not value or re.search(r'\b(NOT PUBLISHED|UNKNOWN|UNVERIFIED|NOT CONFIRMED)\b',value,re.I):return None
 return re.sub(r'\s*[—–-]\s*CONFIRMED.*$', '', value).strip()

def admission_details(rows):
 result=[]
 for r in rows:
  facts={k:public_value(r.get(k)) for k in FACT_FIELDS}
  # Preserve individual source-row scope; NEVER sum or merge separate admissions.
  result.append(dict(sourceId=r.get('inventory_id'),name=r.get('recruitment_track') or r.get('admission_name') or '논술전형',
   facts={k:v for k,v in facts.items() if v is not None},
   sourceStatus=r.get('evidence_status'),verifiedAt=r.get('verified_date'),
   sourceUrl=r.get('official_source_url'),documentUrl=r.get('official_pdf_url') if source_url(r.get('official_pdf_url','')) else None,
   documentBasis='시행계획 포함' if '시행계획' in (r.get('notes','')+r.get('confidence','')) else '공식 전형 자료',
   applicants=None,competitionRatio=None))
 return result

def build(catalog,identities,research=None):
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
  for label,pattern in [('인문',r'인문|언어|사회논술'),('경제·경영',r'경제|경영'),('수리',r'수리|수학\s*논술'),('과학',r'과학\s*논술|과학\([0-9]+%\)|과학 제시문 서논술'),('단답·약술형',r'약술|단답')]:
   if re.search(pattern,text):types.append(label)
  sources=list(dict.fromkeys(r['official_source_url'] for r in rows if source_url(r.get('official_source_url',''))))
  item['offerings'].append(dict(id=o['id'],campus=o['campus'],region=region(o['region']),admissionYear=o['year'],admissionNames=o['admissionNames'],types=types,rawEssayTypes=raw_types,sourceIds=o['sourceIds'],sources=sources,verifiedAt=o['checkedAt'],sourceStatus=o['sourceStatus'],admissionDetails=admission_details(rows)))
 for entry in research or []:
  match=next((u for u in out.values() if u['name']==entry['university']),None)
  if match:
   match['researchSources']=[dict(url=r['url'],label='입학처 논술 참고 자료',verifiedAt='2026-09-16') for r in entry.get('official_sources_checked',[]) if source_url(r.get('url',''))]
 result=dict(version='essay-public-catalog-v1',asOf=catalog['asOf'],identityVerifiedAt=identities['verifiedAt'],universities=sorted(out.values(),key=lambda u:u['name']),evaluationRouting='QUESTION_RUNTIME_ONLY')
 if any(not u['offerings'] for u in result['universities']):raise ValueError('UNVERIFIED_UNIVERSITY')
 return result

def main():
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--identities',type=Path,required=True);p.add_argument('--out',type=Path,required=True);p.add_argument('--research',type=Path);a=p.parse_args()
 result=build(json.loads(a.source.read_text()),json.loads(a.identities.read_text()),json.loads(a.research.read_text()) if a.research else None)
 if a.research:result['researchSha256']=hashlib.sha256(a.research.read_bytes()).hexdigest()
 result['sourceSha256']=hashlib.sha256(a.source.read_bytes()).hexdigest()
 a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps(dict(universities=len(result['universities']),offerings=sum(len(u['offerings']) for u in result['universities']),canonicalIds=sum(u['universityId'] is not None for u in result['universities']))))
if __name__=='__main__':main()
