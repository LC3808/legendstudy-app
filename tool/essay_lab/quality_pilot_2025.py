"""Bounded two-university manifest and private offline package builder. No AI/network.

Uses the established Pilot transaction functions with an explicit scope validator.
Bodies and image crops stay in a caller-supplied ignored/private output directory.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path
from uuid import UUID
from urllib.parse import urlparse
from .pilot_2025 import COLUMNS, ROLES

PLAN = Path(__file__).with_name('quality_pilot_2025_plan.json')
SCOPE = {'sookmyung': ('숙명여자대학교', '1697', 'sookmyung.ac.kr'),
         'hanyang': ('한양대학교', '1660', 'hanyang.ac.kr')}

def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()

def sha(data):
    return hashlib.sha256(data).hexdigest()

def validate(plan):
    us={u['id']:u for u in plan['universities']}
    es={e['id']:e for e in plan['exams']}
    ds={d['resource_id']:d for d in plan['documents']}
    assert len(us)==len(plan['universities'])==2
    assert {u['slug'] for u in us.values()}==set(SCOPE)
    assert len(es)==len(plan['exams'])==2 and len(ds)==len(plan['documents'])==6
    assert len({e['university_id'] for e in es.values()})==2
    for u in us.values():
        UUID(u['id']); assert set(u)==set(COLUMNS['universities'])
        assert u['name']==SCOPE[u['slug']][0] and u['is_active'] is True
    for e in es.values():
        UUID(e['id']); assert set(e)==set(COLUMNS['essay_exams'])
        assert e['university_id'] in us and e['admission_year']==2025
        assert e['exam_key']=='mock-humanities' and e['exam_kind']=='mock'
        assert e['metadata_resource_id'] in ds
    keys=set()
    for m in plan['mappings']:
        assert set(m)==set(COLUMNS['essay_exam_resources'])
        key=(m['essay_exam_id'],m['resource_id'],m['role'])
        assert key not in keys and m['role'] in ROLES; keys.add(key)
        assert m['essay_exam_id'] in es and m['resource_id'] in ds
        assert m['source_locator'].strip()
    for row in [*es.values(),*plan['mappings']]:
        e=row if 'university_id' in row else es[row['essay_exam_id']]
        slug=us[e['university_id']]['slug']; domain=SCOPE[slug][2]
        rid=row.get('resource_id',e['metadata_resource_id'])
        assert ds[rid]['source_post_id']==SCOPE[slug][1]
        p=urlparse(row['official_source_url'])
        assert p.scheme=='https' and (p.hostname==domain or p.hostname.endswith('.'+domain))
        assert row['provenance']=='official' and row['verification_status']=='verified'
        assert row['is_active'] is True and row['evidence_note'].strip()
        if row.get('role')=='high_scoring_answer':
            assert slug=='sookmyung' and rid=='55b745da-a297-5797-b855-678f8e744506'
    assert len(keys)==13
    for d in ds.values():
        assert re.fullmatch('[0-9a-f]{64}',d['sha256'])
        assert Path(d['file']).name==d['file']
    return plan

def load_plan():
    return validate(json.loads(PLAN.read_text()))

def _pages(path):
    import pdfplumber
    with pdfplumber.open(path) as pdf:
        return [(p.extract_text() or '').replace('\x00',' ') for p in pdf.pages]

def verify_sources(plan, source_dir):
    """Verify exact local bytes AND independent official correspondence before build."""
    from pypdf import PdfReader
    for d in [*plan['documents'],*plan['official_documents']]:
        assert sha((source_dir/d['file']).read_bytes())==d['sha256'], 'Source hash drift: '+d['file']
    norm=lambda s:''.join(s.split())
    for local,official,pages in [('1697-2.pdf','sm-official-0.pdf',2),('1697-4.pdf','sm-official-1.pdf',7)]:
        assert list(map(norm,_pages(source_dir/local)))==list(map(norm,_pages(source_dir/official)[:pages]))
    image=PdfReader(source_dir/'1697-3.pdf').pages[0].images[0]
    official=PdfReader(source_dir/'sm-official-3.pdf').pages[0].images[0]
    assert sha(image.data)==sha(official.data)==plan['proofs']['sookmyung']['answer_page']['image_sha256']
    for i in range(3):
        assert (source_dir/f'1660-{i}.pdf').read_bytes()==(source_dir/f'hy-official-{i}.pdf').read_bytes()

def blind_payload(question, passages, intent, criteria, image_hash, question_images):
    """Allowlist, not redaction: no reference answers, official quality labels or IDs."""
    return {'test_id':'blind_test_answer_1','target_question':'1-1',
            'question':question,'passages':passages,
            'official_evidence':{'exam_intent':{'id':'E1','text':intent},
                                 'scoring_criteria':{'id':'E2','text':criteria}},
            'question_page_assets':question_images,
            'student_answer':{'modality':'image','asset':'answer_1.png','sha256':image_hash},
            'scope':'Evaluate only question 1-1. Original question pages preserve underlining. E1/E2 are official source excerpts, not a score prediction.'}

def build(source_dir, output_dir):
    from pypdf import PdfReader
    import pdfplumber
    plan=load_plan(); verify_sources(plan,source_dir)
    # Prevent accidentally publishing source bodies into a tracked directory.
    repo=Path(__file__).resolve().parents[2]
    output_dir=output_dir.resolve()
    assert output_dir.is_relative_to((repo/'.local').resolve()), 'Private .local output required'
    outputs={}
    for u in plan['universities']:
        slug=u['slug']; out=output_dir/slug; out.mkdir(parents=True,exist_ok=True)
        e=next(e for e in plan['exams'] if e['university_id']==u['id'])
        ms=[m for m in plan['mappings'] if m['essay_exam_id']==e['id']]
        docs=[d for d in plan['documents'] if d['source_post_id']==SCOPE[slug][1]]
        package={'version':'v1','exam':e,'mappings':ms,'documents':[],
                 'missing_roles':sorted(ROLES-{m['role'] for m in ms}),
                 'coverage':'question 1-1/1-2 only; humanities item 2 not packaged' if slug=='sookmyung' else 'single humanities mock question',
                 'ai_evaluation_executed':False}
        for d in docs:
            package['documents'].append({**d,'pages':_pages(source_dir/d['file'])})
        (out/'evidence_package.json').write_bytes(encoded(package))
        if slug=='sookmyung':
            q='\n'.join(_pages(source_dir/'1697-2.pdf'))
            question=q.split('1-1.\n',1)[1].split('1-2.',1)[0].strip()
            passages=q[q.index('<가>'):q.index('<다>')].strip()
            cards=_pages(source_dir/'1697-4.pdf')
            intent=cards[3].split('3. 출제 의도',1)[1].split('4. 출제 근거',1)[0].strip()
            criteria='■ 답안의 구성요소'+cards[5].split('■ 답안의 구성요소')[1]
            im=PdfReader(source_dir/'1697-3.pdf').pages[0].images[0].image
            assert im.size==(2260,1900)
            # Pixel-preserving original first response. Second response begins below y=740.
            im.crop((0,0,2260,620)).save(out/'answer_1.png')
            qassets=[]
            with pdfplumber.open(source_dir/'1697-2.pdf') as pdf:
                for i,p in enumerate(pdf.pages,1):
                    name=f'question_page_{i}.png';p.to_image(resolution=120).save(out/name)
                    qassets.append({'asset':name,'sha256':sha((out/name).read_bytes())})
            blind=blind_payload(question,passages,intent,criteria,sha((out/'answer_1.png').read_bytes()),qassets)
            (out/'blind_input.json').write_bytes(encoded(blind))
            gt={'test_id':'blind_test_answer_1','ground_truth':'high_scoring','university':slug,
                'essay_exam_id':e['id'],'resource_id':'55b745da-a297-5797-b855-678f8e744506',
                'source_locator':'PDF page 1; embedded image crop [0,0,2260,620]; question 1-1; response 1',
                'official_source_url':e['official_source_url'],'individual_score':None,
                'student_identity':None,'open_only_after_evaluation':True}
            (out/'ground_truth.json').write_bytes(encoded(gt))
        outputs[slug]={'package_version':'v1','package_sha256':sha((out/'evidence_package.json').read_bytes()),
                       'roles':sorted({m['role'] for m in ms}), 'missing_roles':package['missing_roles'],
                       'blind_ready':slug=='sookmyung','target_question':'1-1' if slug=='sookmyung' else None,
                       'files':{p.name:sha(p.read_bytes()) for p in sorted(out.iterdir()) if p.is_file()}}
    return outputs

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source-dir',type=Path,required=True);p.add_argument('--output-dir',type=Path,required=True)
    args=p.parse_args(); print(json.dumps(build(args.source_dir,args.output_dir),ensure_ascii=False,indent=2))
