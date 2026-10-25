"""Assemble exact official text connections, without answers or Provider calls.

Only two-parent text exams are handled here. Three-parent social exams retain
their own subanswer mapping task; existing active packages are never rewritten.
"""
import argparse
import json
import re
import sys
from copy import deepcopy
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material


def assemble(root, manifest_path, output):
    read=lambda p: json.loads(p.read_text())
    docs={d['sha256']: d for d in read(root/'continuous-source-pages.private.json')}
    rows=read(manifest_path)
    registry=deepcopy(read(root/'text-expansion/central-worker-registry.private.json'))
    active={e['id'] for e in read(root/'continuous-inventory.private.json')['exams'] if e['runtime']}
    packages=read(output/'packages.private.json') if (output/'packages.private.json').exists() else {}
    reports=[]
    for row in rows:
        if row['examId'] in active:
            reports.append(dict(exam_id=row['examId'],status='PRESERVED_ACTIVE')); continue
        if row['parent_count']!=2:
            reports.append(dict(exam_id=row['examId'],status='SUBANSWER_CONNECTION_PENDING')); continue
        if row['examId'] in packages:
            reports.append(dict(exam_id=row['examId'],status='INPUT_CONNECTED_NOT_DEPLOYED',question_count=len(packages[row['examId']]['questions']),reused=True,provider_calls=0));continue
        try:
            qd,sd=docs[row['question_source_hash']],docs[row['official_source_hash']]
            qt,st='\n'.join(qd['pages']),'\n'.join(sd['pages'])
            # Headings must name this academic year; generic scoring words are
            # not treated as a separate exam's official assessment chapter.
            heading=rf'\d\.\s*{row["year"]}학년도\s*(?:수시모집\s*)?(?:모의논술고사|논술고사)\s*'
            intents=list(re.finditer(heading+r'(?:출제\s*의도|문항\s*해설)',st))
            scores=list(re.finditer(heading+r'채점\s*기준',st))
            examples=list(re.finditer(heading+r'예시\s*답안',st))
            shared_explanation=None
            if len(scores)!=2 or len(examples)!=2:
                # Older official mock booklets use one exam-wide explanation,
                # not two per-question scoring chapters. Reuse its literal task
                # requirements and explanation; never invent numeric rubrics.
                shared=re.search(heading+r'문항\s*해설',st)
                if row['kind']!='mock' or not shared:raise ValueError('OFFICIAL_EXPLANATION_REQUIRED')
                shared_explanation=(shared.end(),len(st))
            e=next((e for e in registry['exams'] if e['examId']==row['examId']),None)
            if e is None:
                e={k:row[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')}
                registry['exams'].append(e)
            else:
                e['questions']=deepcopy(row['questions']);e['sourceHashes']=row['sourceHashes']
            p=dict(schema='essay-material-package-v1',exam_id=e['examId'],university_id=e['universityId'],package_version=1,
                   verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',
                   exam_identity=dict(academic_year=e['year'],exam_type=e['kind'],track=e['track'],title=e['name']),questions=[],rights_status={})
            for n,q in enumerate(row['questions']):
                numeral='(?:Ⅰ|I|1)' if n==0 else '(?:Ⅱ|II|2)'
                prompt_match=re.search(r'\[\s*논제\s*'+numeral+r'\s*\]\s*(.*?)\[([^\[\]]*(?:배점|자\s*이하)[^\[\]]*)\]',qt,re.S)
                if not prompt_match: raise ValueError('EXACT_PROMPT_SPAN_REQUIRED')
                prompt=prompt_match.group(0)
                if shared_explanation is not None:
                    a,b=shared_explanation
                    def page_at(d,pos):
                        offset=0
                        for i,text in enumerate(d['pages'],1):
                            offset+=len(text)+1
                            if pos<offset:return i
                        return len(d['pages'])
                    refs=[]
                    for role,text,d,start,end in [('question',prompt,qd,prompt_match.start(),prompt_match.end()),('shared_passage',qt,qd,0,len(qt)),('intent',st[a:b],sd,a,b),('criteria',prompt,qd,prompt_match.start(),prompt_match.end())]:
                        refs.append(dict(questionId=q['id'],sourceHash=d['sha256'],startPage=page_at(d,start),endPage=page_at(d,end-1),role=role,verification='VERIFIED',evidenceText=text.strip()))
                    p['questions'].append(dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs,criteria_basis='OFFICIAL_TASK_REQUIREMENTS_WITH_EXAM_EXPLANATION',numeric_rubric_inferred=False))
                    continue
                score=scores[n]; example=next((m for m in examples if m.start()>score.end()),None)
                if example is None: raise ValueError('OFFICIAL_SCORING_END_REQUIRED')
                scoring=st[score.end():example.start()].strip()
                # Extract literal content criteria; never turn example answers
                # into criteria. PDF text ordering problems remain explicit.
                # PDF table cells may be emitted after the example heading.
                # Locate the explicit content-criteria cell inside this question's
                # section and stop before its notes/example prose.
                section_end=scores[n+1].start() if n+1<len(scores) else len(st)
                window=st[score.end():section_end]
                content=re.search(r'채점\s*기준\s*[:：]\s*내용\s*평가',window)
                if not content: raise ValueError('SCORING_PDF_READING_ORDER_REQUIRES_LOCATOR')
                body=window[content.end():]
                boundary=re.search(r'※|<\s*예시\s*답안|'+heading+r'예시\s*답안',body)
                if boundary:body=body[:boundary.start()]
                criteria=[s.strip() for s in re.split(r'[①②③④⑤⑥⑦⑧⑨⑩⓸]|(?<![0-9])\d\)',body)[1:] if len(s.strip())>=15]
                if not criteria: raise ValueError('OFFICIAL_CRITERIA_SPANS_REQUIRED')
                intent_candidates=[m for m in intents if (scores[n-1].end() if n else 0)<m.start()<score.start()]
                if not intent_candidates: raise ValueError('EXACT_INTENT_SPAN_REQUIRED')
                intent=intent_candidates[0]
                refs=[]
                def page(d,pos):
                    offset=0
                    for i,t in enumerate(d['pages'],1):
                        offset+=len(t)+1
                        if pos<offset:return i
                    return len(d['pages'])
                def ref(role,text,d,start,end):
                    refs.append(dict(questionId=q['id'],sourceHash=d['sha256'],startPage=page(d,start),endPage=page(d,end-1),role=role,verification='VERIFIED',evidenceText=text.strip()))
                ref('question',prompt,qd,prompt_match.start(),prompt_match.end())
                # Same official exam passages remain available to the existing
                # worker. The document is private; this is not a student PDF grant.
                ref('shared_passage',qt,qd,0,len(qt))
                ref('intent',st[intent.end():score.start()],sd,intent.end(),score.start())
                for c in criteria:
                    start=st.index(c,score.end())
                    ref('criteria',c,sd,start,start+len(c))
                ref('scoring',scoring,sd,score.end(),example.start())
                p['questions'].append(dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs))
            for h in row['sourceHashes']:
                p['rights_status'][h]=dict(providerTransmission='APPROVED',purpose='Owner-authorized preparation; runtime publication requires separate scoped approval')
            p['package_digest']=digest(p)
            hosted,report=load_reviewed_material(p,registry,pinned_digest=p['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False)
            if not report['ready'] or set(hosted)!={q['id'] for q in row['questions']}:raise ValueError(str(report))
            packages[row['examId']]=p
            reports.append(dict(exam_id=row['examId'],status='INPUT_CONNECTED_NOT_DEPLOYED',question_count=len(hosted),provider_calls=0))
        except ValueError as error:
            reports.append(dict(exam_id=row['examId'],status='CONNECTION_PENDING',reason=str(error)))
    for row in rows:
        if row['examId'] not in packages:continue
        existing=next((e for e in registry['exams'] if e['examId']==row['examId']),None)
        if existing is None:
            registry['exams'].append({k:row[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')})
        else:
            existing['sourceHashes']=sorted(set(existing['sourceHashes'])|set(row['sourceHashes']))
    output.mkdir(parents=True,exist_ok=True)
    (output/'packages.private.json').write_text(json.dumps(packages,ensure_ascii=False))
    (output/'registry.private.json').write_text(json.dumps(registry,ensure_ascii=False))
    (output/'connection-status.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2)+'\n')
    return reports


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('manifest',type=Path);p.add_argument('output',type=Path);a=p.parse_args()
    print(json.dumps(assemble(a.root,a.manifest,a.output),ensure_ascii=False))
