"""Reuse existing private extraction for every registered exam; no network/DB calls.
Page-role candidates are NOT verified per-question evidence. This preparation never
activates evaluation or substitutes material from another exam/university.
"""
import argparse,json,os
from pathlib import Path
from .live_worker import require

ROLES=('exam_intent','scoring_criteria','explanation','example_answer')

def connect(registry, inventory, review_groups=()):
    by_hash={r['sha256']:r for r in inventory}
    packages=[]
    for exam in registry['exams']:
        materials=[];universities=set()
        for sha in exam['sourceHashes']:
            row=by_hash.get(sha);require(row is not None,'SOURCE_NOT_FOUND')
            require(row['university_id']==exam['universityId'],'FOREIGN_UNIVERSITY_SOURCE')
            universities.add(row['catalog_source_id'])
            materials.append({'source_sha256':sha,'question_pages':row.get('question_marker_pages',[]),
                'role_pages':{role:row.get('body_role_pages',{}).get(role,[]) for role in ROLES},
                'visual_review_pages':row.get('low_text_pages',[]),
                'provider_transmission':row.get('external_provider_transmission','NOT_VERIFIED')})
        require(len(universities)==1,'AMBIGUOUS_UNIVERSITY')
        # Reuse existing question/solution pair candidates. Separate PDFs are not
        # missing merely because the registered QUESTION PDF has no rubric pages.
        # These are candidate links only, never automatically approved evidence.
        related=[]
        for group in review_groups:
            if not set(exam['sourceHashes']) & set(group['source_hashes']):continue
            require(group['university_id']==exam['universityId'],'FOREIGN_REVIEW_GROUP')
            if group.get('academic_year_candidate')!=exam['year']:continue
            for sha in group['source_hashes']:
                if sha in exam['sourceHashes'] or any(m['source_sha256']==sha for m in related):continue
                row=by_hash[sha]
                require(row['university_id']==exam['universityId'],'FOREIGN_UNIVERSITY_SOURCE')
                related.append({'source_sha256':sha,'review_group_key':group['review_group_key'],
                    'role_pages':{role:row.get('body_role_pages',{}).get(role,[]) for role in ROLES},
                    'verification':'EXAM_AND_QUESTION_PAIRING_REVIEW_REQUIRED'})
        missing=[role for role in ROLES if not any(m['role_pages'][role] for m in materials+related)]
        packages.append({'version':'registered-materials-review-v1','universityId':exam['universityId'],
            'sourceUniversityId':next(iter(universities)),'examId':exam['examId'],
            'year':exam['year'],'kind':exam['kind'],'track':exam['track'],
            'session':exam['session'],'campus':exam['campus'],
            'questions':[{'id':q['id'],'sourceKey':q['sourceKey']} for q in exam['questions']],
            'materials':materials,'related_material_candidates':related,'missing_role_candidates':missing,
            'verification':'PER_QUESTION_ROLE_REVIEW_REQUIRED','evaluationReady':False})
    return packages

def summary(packages):
    counts={}
    for p in packages:
        key=p['sourceUniversityId'];v=counts.setdefault(key,dict(exams=0,questions=0,sourceFiles=0,roleCandidateExams={r:0 for r in ROLES}))
        v['exams']+=1;v['questions']+=len(p['questions']);v['sourceFiles']+=len(p['materials'])
        v['pairedCandidateFiles']=v.get('pairedCandidateFiles',0)+len(p['related_material_candidates'])
        for role in ROLES:v['roleCandidateExams'][role]+=int(role not in p['missing_role_candidates'])
    return {'universities':len(counts),'exams':len(packages),'questions':sum(len(p['questions']) for p in packages),
        'scope':'Exact source/registry mapping; role pages are candidates, not approved runtime packages',
        'runtimeActivation':False,'coverage':counts}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--registry',type=Path,required=True)
    parser.add_argument('--private-root',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();os.umask(0o077)
    packages=connect(json.loads(args.registry.read_text()),json.loads((args.private_root/'inventory.json').read_text()),json.loads((args.private_root/'review-candidates.json').read_text()))
    args.output.mkdir(parents=True,exist_ok=True)
    for p in packages:(args.output/(p['examId']+'.json')).write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
    (args.output/'summary.json').write_text(json.dumps(summary(packages),ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in summary(packages).items() if k!='coverage'},ensure_ascii=False))
