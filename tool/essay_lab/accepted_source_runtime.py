"""Bind existing accepted Hanyang/Sookmyung inputs to the approved Registry.
Offline preparation only; never carries the prior student's answer or answer image.
Uses the existing v1.3 validator/prompt/Provider transport, not a new evaluator.
"""
import base64,json
from copy import deepcopy
from hashlib import sha256
from pathlib import Path
from uuid import UUID,uuid5
from .live_worker import digest,require
R=Path(__file__).resolve().parents[2]
NAMESPACE=UUID('bfbc9384-f407-440d-aa9e-45e2f485a849')
TARGETS={
 'hanyang':('345d3caa-3438-58c3-8f80-62a6242179ec','4cbe8b69-2ccc-5c4e-9e77-0644f90e2cde',2024,'admission',5),
 'sookmyung':('a6667288-75ad-50d4-b237-d2a08e2bff8b','1dab31d8-ea73-513f-80c3-9f871f079e2b',2025,'mock',2),
}
ROLES={'Q':'question','P':'passage','E1':'exam_intent','E2':'scoring_criteria'}
def prepare(case,private_root,registration=None):
 require(case in TARGETS,'UNREVIEWED_CASE')
 root=Path(private_root)/case
 value=json.loads((root/'package.json').read_text())
 accepted=next(p for p in json.loads((R/'tool/essay_lab/evidence/l2_b_preparation_result.json').read_text())['packages'] if p['case']==case)
 require(digest(value)==accepted['package_sha256'],'ACCEPTED_PACKAGE_DRIFT')
 exam_id,qid,year,kind,count=TARGETS[case]
 registry=registration or json.loads((R/'supabase/reviews/essay-source-registration/manifest.json').read_text())
 matches=[e for e in registry['exams'] if e['examId']==exam_id]
 require(len(matches)==1,'REGISTRY_EXAM_MISSING');exam=matches[0]
 require(exam['year']==year and exam['kind']==kind and sum(q['id']==qid for q in exam['questions'])==1,'REGISTRY_IDENTITY_CHANGED')
 if case=='hanyang':
  source=json.loads((R/'tool/essay_lab/evidence/hanyang_afternoon2_source.json').read_text())
  require(source['files'][0]['sha256'] in exam['sourceHashes'] and source['gate']=='PASS','REGISTRY_SOURCE_CHANGED')
  hashes={'Q':source['files'][0]['sha256'],'P':source['files'][0]['sha256'],'E1':source['files'][2]['sha256'],'E2':source['files'][2]['sha256']}
 else:
  # This is the existing verified package metadata, not a new extraction or research.
  source=json.loads((Path(private_root).parent/'essay-quality-2025/packages/sookmyung/evidence_package.json').read_text())
  require(source['exam']['id']==exam_id and source['exam']['verification_status']=='verified','EXAM_NOT_VERIFIED')
  docs={d['resource_id']:d['sha256'] for d in source['documents']}
  hashes={key:docs[ref['resource_id']] for key,ref in value['reference_catalog'].items()}
  require(hashes['Q'] in exam['sourceHashes'],'REGISTRY_SOURCE_CHANGED')
 version='accepted-'+case+'-registry-v1'
 def identity(kind,key):return str(uuid5(NAMESPACE,f'{version}/{qid}/{kind}/{key}'))
 evidence=[]
 for key,role in ROLES.items():
  ref=value['reference_catalog'][key]
  # Hanyang's official pages are already accepted images. Labels are provenance
  # pointers, never a fabricated transcription of the original material.
  if case=='hanyang': text='공식 자료 이미지에서 확인: '+ref['source_locator']
  elif key in ('Q','P'):text=value['official_evidence']['question' if key=='Q' else 'passages']
  else:text=value['official_evidence']['official_evidence']['exam_intent' if key=='E1' else 'scoring_criteria']['text']
  require(isinstance(text,str) and text.strip(),'OFFICIAL_EVIDENCE_MISSING')
  evidence.append({'binding':dict(id=identity('evidence',key),role=role,hash=hashes[key],version=version,locator=ref['source_locator']),
   'text':text,'text_sha256':sha256(text.encode()).hexdigest()})
 criteria=[{'binding':dict(id=identity('criterion',key),version=version),'label':label+'\n'+value['criteria_note']} for key,label in value['criteria'].items()]
 images=[]
 for i in range(count):
  raw=(root/f'input_{i+1}.png').read_bytes()
  require(sha256(raw).hexdigest()==accepted['input_images'][i],'OFFICIAL_IMAGE_CHANGED')
  images.append({'sha256':accepted['input_images'][i],'data':base64.b64encode(raw).decode(),
   'evidence_ids':[e['binding']['id'] for e in evidence if (case=='sookmyung' and e['binding']['role'] in ('question','passage')) or
    (case=='hanyang' and e['binding']['role'] in (('question','passage') if i<2 else ('exam_intent',) if i==2 else ('scoring_criteria',)))]})
 # No arbitrary fields from old package, answer_hash, student image, or prior context.
 cache={'contract_version':'1.3','evidence':evidence,'criteria':criteria,'official_images':images,
        'length_requirement':{**deepcopy(value['length_requirement']),'evidence_id':identity('evidence','Q')}}
 return {'exam_id':exam_id,'question_id':qid,'metadata_version':'source-registration-v1',
         'cache':cache,'cache_sha256':digest(cache),'package_version':version,
         'provider_transmission_allowed':False,'publication_allowed':False}


def hosted_question(case,private_root,binding,*,regime,approved_processing=False,reviewed_cache=False):
    """Compose the existing host without inferring operational authorization."""
    from .package_registry import bind_registered_package
    bound=prepare(case,private_root)
    registry=json.loads((R/'supabase/reviews/essay-source-registration/manifest.json').read_text())
    exam=next(e for e in registry['exams'] if e['examId']==bound['exam_id'])
    question=next(q for q in exam['questions'] if q['id']==bound['question_id'])
    source=next(e['binding']['hash'] for e in bound['cache']['evidence'] if e['binding']['role']=='question')
    assignment={k:exam[k] for k in ('examId','universityId','year','kind','track','session','campus')}
    assignment.update(evaluationType='humanities',questionId=question['id'],sourceKey=question['sourceKey'],questionSourceHash=source,cacheSha256=bound['cache_sha256'])
    return bind_registered_package(registry,assignment,bound['cache'],binding=binding,regime=regime,
        approved_processing=approved_processing,reviewed_cache=reviewed_cache)
