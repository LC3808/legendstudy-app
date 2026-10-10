"""Reuse frozen SKKU evidence in existing Essay tables. Offline / isolated DB only.
No publication, provider call, source text in Git, new table or production writer.
"""
from copy import deepcopy
from hashlib import sha256
from uuid import UUID, uuid5
from .evidence_package import validate, question_context, EXAM_ID, RESOURCE_ID, PDF_SHA

NAMESPACE=UUID('bfbc9384-f407-440d-aa9e-45e2f485a849')
def identity(kind,key):
    return str(uuid5(NAMESPACE,f'essay-service-v1/{EXAM_ID}/{kind}/{key}'))

def prepare(package,manifest,figure):
    validate(package)
    if package['exam']['id']!=EXAM_ID or package['exam']['admission_year']!=2025:
        raise ValueError('EXAM_IDENTITY')
    if package['evidence_package_version']!=manifest['evidence_package_version']:
        raise ValueError('FROZEN_PACKAGE_CHANGED')
    if sha256(figure).hexdigest()!=manifest['figure_sha256']:
        raise ValueError('FIGURE_MISSING_OR_CHANGED')
    for e in package['evidence']:
        expected=next((v for v in manifest['locators'] if v['id']==e['id']),None)
        if not expected or e['text_sha256']!=expected['text_sha256'] or e['source_locator']!=expected['source_locator']:
            raise ValueError('SOURCE_MAPPING_CHANGED')
    version=package['evidence_package_version'];questions=[];evidence=[];criteria=[];content=[]
    for position,q in enumerate(package['questions'],1):
        qkey=f'q{position}';qid=identity('question',qkey)
        questions.append(dict(id=qid,essay_exam_id=EXAM_ID,question_key=qkey,label=q['question_label'],display_order=position,
          length_min=None,length_max=None,length_count_rule=None,time_limit_seconds=None,metadata_version=version,is_published=False))
        context=question_context(package,q['question_label']);sources={e['id']:e for e in context['evidence']}
        for e in context['evidence']:
            evidence.append(dict(id=identity('evidence',qkey+'/'+e['id']),question_id=qid,essay_exam_id=EXAM_ID,
              resource_id=RESOURCE_ID,role=e['role'],source_locator=e['source_locator'],mapping_version=version,source_sha256=PDF_SHA))
        # Official numbered requirements are dimensions. A-F grade bands remain rubric context,
        # never independent dimensions, numeric scores, or duplicated grading requirements.
        for order,c in enumerate(q['criteria'][:3],1):
            if c['criterion_id']!=f'{qkey}-{["①","②","③"][order-1]}':raise ValueError('CRITERION_REVIEW_REQUIRED')
            e=sources[c['evidence_id']]
            criteria.append(dict(id=identity('criterion',c['criterion_id']),question_id=qid,criterion_key=c['criterion_id'],
              definition_version=version,label=f'공식 평가 항목 {order}',description=e['text'][c['start']:c['end']],origin='official',
              source_evidence_id=identity('evidence',qkey+'/'+e['id']),official_weight_percent=None,display_order=order,
              verified_at=package['exam']['verified_at']))
        content.append(dict(question_id=qid,metadata_version=version,requires_figure=q['requires_figure'],
          figure_sha256=manifest['figure_sha256'] if q['requires_figure'] else None,
          prompt=deepcopy(sources[q['evidence']['prompt']]),
          passages=[deepcopy(sources[k]) for k in q['passage_refs']+q['context_refs']],
          evaluator_evidence=[deepcopy(e) for e in context['evidence'] if e['role'] not in ('example_answer','model_answer','high_scoring_answer')]))
    return dict(version='essay-service-import-v1',exam_id=EXAM_ID,source_sha256=PDF_SHA,package_version=version,
      publication_allowed=False,provider_transmission_allowed=False,questions=questions,evidence=evidence,criteria=criteria,private_content=content)

def import_isolated(connection,plan):
    """One transaction; idempotent exact replay, conflicting originals abort. Caller cannot publish.
    Uses psycopg composables/parameters, never interpolates source text into SQL.
    """
    from psycopg import sql
    if not connection.info.host.startswith(('/tmp/','/private/tmp/')):
        raise ValueError('ISOLATED_UNIX_DB_REQUIRED')
    if plan['publication_allowed'] is not False or plan['provider_transmission_allowed'] is not False:
        raise ValueError('PUBLICATION_HELD')
    with connection.transaction():
        exam=connection.execute('select id,admission_year,verification_status,provenance from public.essay_exams where id=%s',(plan['exam_id'],)).fetchone()
        if not exam or str(exam[0])!=EXAM_ID or exam[1:]!=(2025,'verified','official'):raise ValueError('CANONICAL_EXAM_MISMATCH')
        for table,key in [('essay_questions','questions'),('essay_question_evidence','evidence'),('essay_evaluation_criteria','criteria')]:
            for row in plan[key]:
                if key=='questions' and row['is_published'] is not False:raise ValueError('PUBLICATION_HELD')
                # Lock and compare JSON projection so immutable conflicts are never overwritten.
                prior=connection.execute(sql.SQL('select to_jsonb(t) from public.{} t where id=%s for update').format(sql.Identifier(table)),(row['id'],)).fetchone()
                if prior:
                    for k,v in row.items():
                        actual=prior[0].get(k)
                        if k=='verified_at':
                            from datetime import datetime
                            if datetime.fromisoformat(actual)!=datetime.fromisoformat(v):raise ValueError('IMPORT_CONFLICT')
                        elif actual!=v:raise ValueError('IMPORT_CONFLICT')
                    continue
                columns=list(row)
                connection.execute(sql.SQL('insert into public.{} ({}) values ({})').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,columns)),sql.SQL(',').join(sql.Placeholder() for _ in columns)),[row[k] for k in columns])
    return {'questions':len(plan['questions']),'evidence':len(plan['evidence']),'criteria':len(plan['criteria']),'published':0}

def cache_for_claim(plan,question_id,claim):
    """Bind private extracted evidence to the actual frozen server snapshot.
    Produces input for existing live_worker.package; does not authorize network dispatch.
    Figure-dependent questions cannot enter the current text-only Humanities worker.
    """
    question=next((q for q in plan['private_content'] if q['question_id']==question_id),None)
    if question is None:raise ValueError('QUESTION_NOT_REGISTERED')
    if question['requires_figure']:raise ValueError('VISUAL_WORKER_CONTRACT_REQUIRED')
    rows={e['id']:e for e in plan['evidence'] if e['question_id']==question_id and e['role'] in ('question','passage','exam_intent','scoring_criteria')}
    actual={r['id']:r for r in claim['input']['evidence']}
    if len(actual)!=len(claim['input']['evidence']) or set(actual)!=set(rows):raise ValueError('FROZEN_EVIDENCE_SET_CHANGED')
    evidence=[]
    for eid,row in rows.items():
        expected=dict(id=eid,role=row['role'],hash=row['source_sha256'],version=row['mapping_version'],locator=row['source_locator'])
        if actual[eid]!=expected:raise ValueError('FROZEN_EVIDENCE_BINDING_CHANGED')
        sources=[e for e in question['evaluator_evidence'] if e['resource_id']==row['resource_id'] and e['role']==row['role'] and e['source_locator']==row['source_locator']]
        if len(sources)!=1:raise ValueError('EXTRACTION_NOT_UNIQUE')
        source=sources[0]
        if sha256(source['text'].encode()).hexdigest()!=source['text_sha256']:raise ValueError('EXTRACTION_CHANGED')
        evidence.append(dict(binding=expected,text=source['text'],text_sha256=source['text_sha256']))
    rows={c['id']:c for c in plan['criteria'] if c['question_id']==question_id}
    actual={r['id']:r for r in claim['input']['criteria']}
    if len(actual)!=len(claim['input']['criteria']) or set(actual)!=set(rows):raise ValueError('FROZEN_CRITERIA_SET_CHANGED')
    criteria=[]
    for cid,row in rows.items():
        expected=dict(id=cid,version=row['definition_version'])
        if actual[cid]!=expected:raise ValueError('FROZEN_CRITERION_CHANGED')
        criteria.append(dict(binding=expected,label=row['label']+'\n'+row['description']))
    cache=dict(contract_version='1.3',evidence=evidence,criteria=criteria)
    from .live_worker import package
    package(claim,cache)  # Reuse canonical answer/hash/role/contract validation.
    return cache

def main():
    import argparse,json
    from pathlib import Path
    parser=argparse.ArgumentParser(description='Prepare private, unpublished existing-schema content. Never connects to Production.')
    parser.add_argument('--package-dir',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if '.local' not in args.out.resolve().parts:raise ValueError('PRIVATE_LOCAL_OUTPUT_REQUIRED')
    root=Path(__file__).resolve().parents[2]
    plan=prepare(json.loads((args.package_dir/'package.json').read_text()),
      json.loads((root/'tool/essay_lab/evidence/skku_2025_humanities1_manifest.json').read_text()),
      (args.package_dir/'q2-data-1.png').read_bytes())
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n')
    args.out.chmod(0o600)
    print(json.dumps(dict(questions=len(plan['questions']),criteria=len(plan['criteria']),published=False,provider_calls=0)))
if __name__=='__main__':main()
