"""Offline V2 handoff validator. No network, DB, Provider or writes outside output.
Research content stays under ignored .local; only aggregate audit may enter Git.
"""
import argparse, ast, csv, hashlib, json, re
from pathlib import Path
from essay_lab.evidence_preview import evidence_manifest

ROUTING='NOT_ROUTABLE_WITHOUT_QUESTION_AND_GOLD_PACKAGE'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read_csv(p):
 with p.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def refs(value):
 if value.startswith('['):
  result=ast.literal_eval(value)
  if not isinstance(result,list) or any(not isinstance(x,str) for x in result):raise ValueError('Invalid source ID list')
  return result
 return [x.strip() for x in re.split(r'[;|]',value) if x.strip()]
def verify(root):
 manifest=json.loads((root/'MANIFEST.json').read_text());issues=[];files=[]
 for f in manifest['files']:
  path=(root/f['package_path']).resolve()
  if not path.is_relative_to(root.resolve()):raise ValueError('Manifest path escapes package')
  actual=digest(path);match=actual==f['sha256'] and path.stat().st_size==f['size_bytes']
  files.append(dict(path=f['package_path'],sha256=actual,manifest_match=match))
  if not match:issues.append(dict(code='STALE_INSTRUCTION_MANIFEST' if f['package_path']=='CODEX_OVERNIGHT_INSTRUCTIONS.md' else 'SOURCE_HASH_MISMATCH',severity='warning' if f['package_path']=='CODEX_OVERNIGHT_INSTRUCTIONS.md' else 'error',id=f['package_path']))
 master=read_csv(root/'data/admission-master-2027.csv');offerings=read_csv(root/'data/essay-offerings-2027.csv');tracks=read_csv(root/'data/essay-tracks-2027.csv')
 j=json.loads((root/'data/admission-master-2027.json').read_text());evidence=json.loads((root/'research/university-evidence.json').read_text())
 def check(ok,code,id='package'):
  if not ok:issues.append(dict(code=code,severity='error',id=id))
 def index(rows,key):
  result={r[key]:r for r in rows};check(len(result)==len(rows),'DUPLICATE_ID',key);return result
 mi=index(master,'inventory_id');oi=index(offerings,'essay_offering_id');index(tracks,'essay_track_id');ji=index(j['records'],'inventory_id')
 check(set(mi)==set(ji),'MASTER_JSON_IDS')
 for id,row in mi.items():
  other=ji.get(id,{})
  for k,v in row.items():
   raw=other.get(k,'');raw=str(raw).lower() if isinstance(raw,bool) else str(raw)
   check(v==raw,'MASTER_JSON_VALUE',id+':'+k)
 seoul=read_csv(root/'data/admission-seoul-2027.csv');nonseoul=read_csv(root/'data/admission-nonseoul-2027.csv')
 check(len(seoul)==27 and len(nonseoul)==26,'SUBSET_COUNTS')
 check({r['inventory_id'] for r in seoul}.isdisjoint({r['inventory_id'] for r in nonseoul}),'SUBSET_OVERLAP')
 check({r['inventory_id'] for r in seoul+nonseoul}==set(mi),'SUBSET_COVERAGE')
 for r in seoul+nonseoul:check({**r,'is_seoul':r['is_seoul'].lower()}==mi.get(r['inventory_id']),'SUBSET_VALUE',r['inventory_id'])
 linked=set();out=[]
 for o in offerings:
  ids=refs(o['official_source_rows']);linked.update(ids)
  check(all(x in mi for x in ids),'MISSING_MASTER',o['essay_offering_id'])
  check(o['academic_year']=='2027','OFFERING_YEAR',o['essay_offering_id'])
  check(all(mi[x]['university_name']==o['canonical_name'] for x in ids if x in mi),'UNIVERSITY_MISMATCH',o['essay_offering_id'])
  related=[t for t in tracks if t['essay_offering_id']==o['essay_offering_id']]
  quarantine=any('2027-08-27' in json.dumps(mi.get(x,{}),ensure_ascii=False) for x in ids)
  out.append(dict(id=o['essay_offering_id'],universityId=o['university_id'],name=o['canonical_name'],year=2027,campus=o['campus'],region=o['region'],seoul=o['seoul_flag'].lower()=='true',sourceStatus=o['source_status'],checkedAt=o['checked_at'],sourceIds=ids,sources=refs(o['official_source_urls']),admissionNames=refs(o['official_admission_names']),tracks=[dict(id=t['essay_track_id'],type=t['track_type'],label=t['raw_track_labels'],status=t['evidence_status'],sourceIds=refs(t['source_row_ids']),routing=t['evaluator_routing_status'],problemFormat=t['provisional_problem_formats'],answerFormat=t['provisional_answer_formats'],inputModes=refs(t['provisional_input_modes']),formatEvidence=t['format_evidence_status'],inputEvidence=t['input_mode_evidence_status']) for t in related],rawMaster=[mi[x] for x in ids if x in mi],metadataState='QUARANTINED' if quarantine else 'RESEARCH_CANDIDATE',evaluationState='NOT_CONNECTED',ownerTier='UNDECIDED',questionSets=[]))
 check(linked==set(mi),'MASTER_OFFERING_COVERAGE')
 for t in tracks:
  o=oi.get(t['essay_offering_id']);check(o is not None,'MISSING_OFFERING',t['essay_track_id'])
  if o:
   check(t['university_id']==o['university_id'] and t['academic_year']==o['academic_year'],'TRACK_IDENTITY',t['essay_track_id'])
   check(set(refs(t['source_row_ids']))<=set(refs(o['official_source_rows'])),'TRACK_SOURCE_SCOPE',t['essay_track_id'])
  check(t['evaluator_routing_status']==ROUTING,'ROUTING_NOT_HELD',t['essay_track_id'])
 counts=dict(master=len(master),universities=len({r['university_name'] for r in master}),seoul=len(seoul),nonseoul=len(nonseoul),offerings=len(offerings),tracks=len(tracks),evidenceUniversities=len(evidence))
 check(counts==dict(master=53,universities=42,seoul=27,nonseoul=26,offerings=50,tracks=101,evidenceUniversities=10),'EXPECTED_COUNTS')
 issues.append(dict(code='FUTURE_NOTICE_RELATIVE_TO_AS_OF',severity='quarantine',id='LSL27-052',as_of=j['as_of'],mentioned_date='2027-08-27'))
 # Preserve evidence metadata as references only, no copied original passage/answer.
 imports=[dict(university=e['university'],researchTier=e['recommended_tier'],ownerTier='UNDECIDED',readiness=e['evaluation_readiness'],rights='REVIEW_REQUIRED',sourceFile='research/university-evidence.json',sourceSha256=digest(root/'research/university-evidence.json'),sourceUrls=[s['url'] for s in e['official_sources_checked']],curationUrls=[s['url'] for s in e['legendstudy_posts_checked']],questionId=None,academicYear=None,examKind=None,sourceLocator=None,pdfSha256=None,publicationAllowed=False,evaluationAllowed=False) for e in evidence]
 audit=dict(version='manus-handoff-audit-v2',counts=counts,files=files,issues=issues,allTracksHeld=all(t['evaluator_routing_status']==ROUTING for t in tracks),sourceContentPublished=False,productionWrites=0,missingArtifacts=['134-row inventory CSV','original PDF bodies'],researchAsOf=j['as_of'])
 catalog=dict(version='essay-research-preview-v1',asOf=j['as_of'],publicationAllowed=False,evaluationAllowed=False,offerings=out)
 return audit,catalog,imports

def validate_evidence_candidate(c):
 """Completeness is not rights clearance. Explicitly pinned past exam only."""
 required=['questionId','academicYear','examKind','sourceLocator','pdfSha256']
 missing=[k for k in required if not c.get(k)]
 if c.get('pdfSha256') and not re.fullmatch('[0-9a-f]{64}',c['pdfSha256']):missing.append('INVALID_PDF_HASH')
 if c.get('rights')!='APPROVED':missing.append('RIGHTS_REVIEW')
 mappings=c.get('resourceMappings',[])
 manifest=evidence_manifest(c.get('examId'),mappings,c.get('visibleResourceIds',[]))
 if not c.get('examId') or any(role in manifest['missing_roles'] for role in ['question','scoring_criteria']):missing.append('VERIFIED_QUESTION_RUBRIC_MAPPINGS')
 if any(not re.fullmatch('[0-9a-f]{64}',str(m.get('source_sha256',''))) for m in mappings):missing.append('MAPPING_SOURCE_HASH')
 return dict(missing=missing,importReady=not missing,evaluationAllowed=False,publicationAllowed=False)

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--package',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
 if '.local' not in args.output.resolve().parts:raise SystemExit('Output must remain in ignored .local directory')
 audit,catalog,imports=verify(args.package)
 args.output.mkdir(parents=True,exist_ok=True)
 outputs=[('audit.json',audit)]
 if any(i['severity']=='error' for i in audit['issues']):
  for stale in ['catalog.json','evidence-candidates.json']:(args.output/stale).unlink(missing_ok=True)
 if not any(i['severity']=='error' for i in audit['issues']):outputs += [('catalog.json',catalog),('evidence-candidates.json',imports)]
 for name,data in outputs:
  (args.output/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps(dict(counts=audit['counts'],issues=audit['issues']),ensure_ascii=False,indent=2))
 if any(i['severity']=='error' for i in audit['issues']):raise SystemExit(1)
if __name__=='__main__':main()
