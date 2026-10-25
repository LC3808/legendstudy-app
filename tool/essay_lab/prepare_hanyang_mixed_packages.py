"""Local pinned mixed packages; existing Essay/Math contracts, no activation."""
import argparse
import base64
import hashlib
import io
import json
import sys
from pathlib import Path
from uuid import UUID, uuid5
import pdfplumber
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material

NS=UUID('bfbc9384-f407-440d-aa9e-45e2f485a849')
def uid(kind, value):return str(uuid5(NS,'mixed-session/'+kind+'/'+value))

def prepare(source,output,model):
    read=lambda p:json.loads(p.read_text())
    units=read(output/'hanyang-source-units.private.json')
    manifest={e['examId']:e for e in read(source/'manifest.json')}
    registry=read(source/'registry-worker.private.json')
    documents={d['sha256']:d for d in read(source/'source-pages.private.json')}
    resources={r['id']:r for r in read(source/'resources.private.json')}
    packages={};assets=[];math_rows=[];connection_rows=[]
    image_cache={}
    def images(source_hash,first,last):
        key=(source_hash,first,last)
        if key not in image_cache:
            rows=[]
            with pdfplumber.open(documents[source_hash]['path']) as pdf:
                for page in range(first,last+1):
                    image=pdf.pages[page-1].to_image(resolution=100).original.convert('RGB')
                    buffer=io.BytesIO();image.save(buffer,format='PNG');raw=buffer.getvalue()
                    rows.append(dict(sha256=hashlib.sha256(raw).hexdigest(),data=base64.b64encode(raw).decode(),sourceHash=source_hash,startPage=page,endPage=page))
            image_cache[key]=rows
        return image_cache[key]
    for source_exam in units:
        exam=manifest[source_exam['exam_id']];eid=exam['examId'];entries=[]
        connection_rows.append(exam)
        existing=next((e for e in registry['exams'] if e['examId']==eid),None)
        if existing is None:
            registry['exams'].append({k:exam[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')})
        elif {q['id'] for q in existing['questions']}!={q['id'] for q in exam['questions']}:
            raise ValueError('REGISTRY_ID_CONFLICT')
        for unit in source_exam['units']:
            qid=unit['question_id'];q=unit['question'];o=unit['official'];refs=[]
            for role,doc,text in [('question',q,q['text']),('shared_passage',q,q['text']),('intent',o,o['intent']),('criteria',o,o['criteria'])]:
                if not text.strip():raise ValueError('OFFICIAL_TEXT_REQUIRED')
                refs.append(dict(questionId=qid,sourceHash=doc['sha256'],startPage=doc['first_page'],endPage=doc['last_page'],role=role,verification='VERIFIED',evidenceText=text))
            entry=dict(question_id=qid,source_key=unit['source_key'],source_page_references=refs,
                       official_images=images(q['sha256'],q['first_page'],q['last_page']))
            if unit['engine']=='math':
                leaf=uid('leaf',qid);problem=uid('problem',qid);problem_set=uid('set',eid)
                dimensions=['logical_development','computation_accuracy','final_conclusion']
                profile=dict(id=uid('profile',eid),logical_id=uid('profile-logical',eid),version=1,scope='EXAM',essay_exam_id=eid,
                    response_format='FULL_SOLUTION',rubric_version='math-rubric-v1',required_dimensions=dimensions,optional_dimensions=[],reasoning_required=True,state='ACTIVE')
                criteria=[dict(id=uid('criterion',qid),leaf_id=leaf,source_id=uid('scoring-source',qid),criterion_key='official-q2',
                    description=o['criteria'],official_points=None,rubric_dimensions=dimensions)]
                context=dict(exam_id=eid,question_id=qid,leaf=dict(id=leaf,response_format='FULL_SOLUTION'),profile=profile,
                    problem=dict(id=problem,statement=q['text']),criteria=criteria,solutions=[],
                    official_intent=o['intent'],provider_binding=dict(provider='openai',model=model),
                    official_images=entry['official_images']+images(o['sha256'],o['first_page'],o['last_page']))
                entry.update(evaluation_engine='math',math_context=context)
                doc=next(d for d in exam['documents'] if d['sha256']==o['sha256'])
                resource=resources.get(doc['resource_id'])
                math_rows.append(dict(exam_id=eid,question_id=qid,problem_set_id=problem_set,problem_id=problem,leaf_id=leaf,
                    name=exam['name'],statement=q['text'],profile=profile,criteria=criteria,
                    source=dict(id=uid('scoring-source',qid),resource_id=resource['id'] if resource else None,
                        source_url=resource['source_url'] if resource else 'https://stlhijzpjfgwwdgunlsd.supabase.co/storage/v1/object/authenticated/essay-material-originals/'+o['sha256']+'.pdf',
                        locator=f"PDF {o['first_page']}-{o['last_page']}",content_sha256=o['sha256'])))
            entries.append(entry)
        package=dict(schema='essay-material-package-v1',exam_id=eid,university_id=exam['universityId'],package_version=1,
            verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',
            exam_identity=dict(academic_year=exam['year'],exam_type=exam['kind'],track=exam['track'],title=exam['name']),
            questions=entries,rights_status={h:dict(providerTransmission='APPROVED',purpose='Owner mixed STANDBY scope 2026-10-26') for h in exam['sourceHashes']})
        package['package_digest']=digest(package)
        hosted,report=load_reviewed_material(package,registry,pinned_digest=package['package_digest'],binding={},regime='held',evaluation_type='business')
        if not report['ready'] or set(hosted)!={q['id'] for q in exam['questions']}:raise ValueError('EXACT_WHOLE_EXAM_REQUIRED')
        packages[eid]=package
        doc=documents[exam['question_source_hash']]
        assets.append(dict(exam_id=eid,path=doc['path'],sha256=doc['sha256'],source_hash=doc['sha256'],page_count=len(doc['pages']),
                           question_pages=[u['question']['first_page'] for u in source_exam['units']],derived=False))
    for name,data in [('packages.private.json',packages),('registry-worker.private.json',registry),('math-content.private.json',math_rows),('manifest.json',connection_rows),('assets.private.json',assets)]:
        (output/name).write_text(json.dumps(data,ensure_ascii=False,indent=2))
    print(json.dumps(dict(exams=len(packages),questions=sum(len(p['questions']) for p in packages.values()),math_leaves=len(math_rows),provider_calls=0,production_applied=False)))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--model',required=True)
    a=p.parse_args();prepare(a.source,a.output,a.model)
