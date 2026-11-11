"""Offline official multi-PDF candidates; reuses math-v1, never calls a provider.

Only ignored .local output is accepted. Plans hold reviewed physical-page maps;
original bytes/text/points are not corrected. Candidate metadata is not a release.
"""
from __future__ import annotations
import argparse, base64, copy, json
from pathlib import Path
from essay_lab.natural_expansion import build_review_package, digest, encode, require
from essay_lab.natural_connection import ROLES
from essay_lab.task20_priority_packages import registration_sql, literal

ORDER=['math_problem_sets','math_problems','math_subproblems','math_source_artifacts',
       'math_evaluation_profiles','math_scoring_criteria','math_canonical_solutions','math_canonical_solution_steps']

def validate(plan,registry):
    require(not plan['publication_allowed'] and not plan['provider_allowed'],'PRIVATE_ONLY')
    seen=set()
    for e in plan['exams']:
        rr=[r for r in registry if r['exam_id']==e['exam_id'] and r['question_id']]
        require(set(e['registry_question_ids'])=={r['question_id'] for r in rr},'REGISTRY_SET_DRIFT')
        for q in e['questions']:
            require(q['question_id'] not in seen,'DUPLICATE_QUESTION');seen.add(q['question_id'])
            r=next((r for r in rr if r['question_id']==q['question_id']),None)
            require(r is not None,'QUESTION_ID_DRIFT')
            for key in ['university_id','exam_key','admission_year','exam_kind','field_or_division','session_label','campus']:
                require(r[key]==e[key],'CONTEXT_DRIFT:'+key)
            require(r['slug']==e['university_slug'] and r['label']==q['label'] and r['display_order']==q['display_order'],'IDENTITY_DRIFT')
            require(not r['math_bindings'] and not r.get('worker_source',False),'EXISTING_CONNECTION_PRESERVED')
            require(not r['is_active'] and not r['is_published'],'EXISTING_PUBLICATION_PRESERVED')
            require(set(q['refs'])==set(ROLES.values()),'MISSING_ROLE')
            for ref in q['refs'].values():
                require(ref['pages'] and ref['pages']==sorted(set(ref['pages'])),'INVALID_PAGES')
                require(all(1<=p<=ref['page_count'] for p in ref['pages']),'PAGE_BOUNDS')
            require(q['student_pages'],'MISSING_STUDENT_PAGES')
            for p in q['student_pages']:require(1<=p['physical_page']<=p['page_count'],'STUDENT_PAGE_BOUNDS')

def validate_worker(payload,exam,q):
    require(payload['question_id']==q['question_id'] and payload['exam_id']==exam['exam_id'],'WORKER_IDENTITY_DRIFT')
    require(digest((payload['manifest_text']+payload['images_text']).encode())==payload['sha256'],'WORKER_DIGEST_DRIFT')
    refs=json.loads(payload['manifest_text']);images=json.loads(payload['images_text'])
    require(set(refs)==set(ROLES.values()),'WORKER_ROLE_MISSING')
    require(1<=len(images)<=24 and len(payload['images_text'].encode())<1800000,'WORKER_SIZE_LIMIT')
    require(len({(i['source_sha256'],i['physical_page']) for i in images})==len(images),'DUPLICATE_IMAGE')
    for role,ref in refs.items():
        expected=q['refs'][role]
        require(ref=={k:expected[k] for k in ['file','sha256','pages']},'WORKER_SOURCE_DRIFT')
        require(sorted((i['source_sha256'],i['physical_page']) for i in images if role in i['roles'])==[(ref['sha256'],p) for p in ref['pages']],'WORKER_PAGE_DRIFT')
    for i in images:
        data=base64.b64decode(i['data'],validate=True)
        require(data.startswith(b'\x89PNG\r\n\x1a\n') and digest(data)==i['sha256'],'WORKER_IMAGE_HASH_DRIFT')
        require(i['roles'] and all(role in refs and i['source_sha256']==refs[role]['sha256'] and i['physical_page'] in refs[role]['pages'] for role in i['roles']),'IMAGE_ROLE_DRIFT')
    return len(images)

def student_page_bottom(page,spec):
    """Reviewed explicit boundary for PDFs whose text coordinates are unreliable."""
    boundary=spec.get('crop_bottom')
    if boundary is not None:
        require(not spec.get('crop_before'),'AMBIGUOUS_CROP_MODE')
        require(type(boundary) in (int,float) and 50<boundary<=page.rect.height,'INVALID_CROP')
        return boundary
    if spec.get('crop_before'):
        matches=page.search_for(spec['crop_before']);require(len(matches)==1,'CROP_HEADING_AMBIGUOUS')
        bottom=matches[0].y0-8
        require(bottom>50,'INVALID_CROP')
        return bottom
    require(not any(page.search_for(h) for h in ['3. 출제 의도','6. 채점 기준','7. 예시 답안']),'UNREVIEWED_STUDENT_ANSWER_LEAK')
    return page.rect.height

def prepare(plan,registry,paths,out):
    import pymupdf
    require('.local' in out.resolve().parts and not out.exists(),'FRESH_PRIVATE_OUTPUT_REQUIRED')
    validate(plan,registry)
    docs={}
    for e in plan['exams']:
        for q in e['questions']:
            for ref in list(q['refs'].values())+q['student_pages']:
                h=ref['sha256']
                if h not in docs:
                    path=Path(paths[h]);require(digest(path.read_bytes())==h,'SOURCE_HASH_DRIFT');docs[h]=pymupdf.open(path)
                require(len(docs[h])==ref['page_count'],'SOURCE_PAGE_COUNT_DRIFT')
    out.mkdir(parents=True)
    records=[];packages=[];pdfs=[];expansions=[];inputs={};worker=[]
    for e in plan['exams']:
        student=pymupdf.open();selected=[]
        # Each question includes its own complete passage context, even shared pages.
        for q in e['questions']:
            start=len(student)+1
            for spec in q['student_pages']:
                page=docs[spec['sha256']][spec['physical_page']-1]
                bottom=student_page_bottom(page,spec)
                pix=page.get_pixmap(matrix=pymupdf.Matrix(2,2),clip=pymupdf.Rect(0,0,page.rect.width,bottom))
                new=student.new_page(width=page.rect.width,height=bottom);new.insert_image(new.rect,stream=pix.tobytes('png'))
            refs={role:{k:ref[k] for k in ['file','sha256','pages']} for role,ref in q['refs'].items()}
            # A flattened index allows reuse of the existing package builder; every
            # artifact is then rebound to its own original PDF and physical pages.
            texts=[];ev={}
            for role,ref in q['refs'].items():
                ev[role]=[]
                for n in ref['pages']:
                    raw=docs[ref['sha256']][n-1].get_text().replace('\x00',' ')
                    scope=f"대상: {q['label']}. {ref['file']} PDF {n}쪽의 해당 문항만 참조. 원문 수식·도형·배점은 공식 이미지 기준.\n"
                    texts.append(scope+raw if raw.strip() else scope+'[이미지형 공식 원문: 전사·배점 추정 없음]')
                    ev[role].append(len(texts))
            stub=copy.deepcopy(e);stub['source']=dict(file='multi-PDF',sha256=q['refs']['problem']['sha256'])
            package=build_review_package(stub,dict(q,evidence=ev),texts)
            rows=package['existing_schema_rows']
            rows['math_problem_sets'][0]['label']=f"{e['university_name']} {e['admission_year']} {e['field_or_division']} {q['label']}"
            rows['math_subproblems'][0]['statement']=q['label']+'의 모든 소문항 풀이 과정을 포함하세요.'
            for s in rows['math_source_artifacts']:
                ref=q['refs'][ROLES[s['source_role']]]
                s.update(source_url='urn:sha256:'+ref['sha256'],locator=ref['file']+' PDF '+','.join(map(str,ref['pages']))+'쪽',content_sha256=ref['sha256'])
            for i,c in enumerate(rows['math_scoring_criteria']):c['criterion_key']=f"q{q['number']}-official-page-{q['refs']['rubric']['pages'][i]}"
            package['existing_schema_rows']={k:rows[k] for k in ORDER}
            package['connection_version']=plan['version'];package['remaining']=['LOCAL_CONTRACT_VALIDATION','OWNER_SOURCE_AND_PUBLICATION_APPROVAL']
            images=[]
            identities=sorted({(ref['sha256'],p) for ref in refs.values() for p in ref['pages']})
            for h,n in identities:
                page=docs[h][n-1];scale=1000/max(page.rect.width,page.rect.height)
                data=page.get_pixmap(matrix=pymupdf.Matrix(scale,scale),colorspace=pymupdf.csGRAY).tobytes('png')
                images.append(dict(data=base64.b64encode(data).decode(),sha256=digest(data),source_sha256=h,physical_page=n,roles=[role for role,ref in refs.items() if h==ref['sha256'] and n in ref['pages']]))
            m=json.dumps(refs,ensure_ascii=False,sort_keys=True);s=json.dumps(images,separators=(',',':'),sort_keys=True)
            payload=dict(question_id=q['question_id'],exam_id=e['exam_id'],manifest_text=m,images_text=s,sha256=digest((m+s).encode()))
            validate_worker(payload,e,q)
            body=encode(package);qid=q['question_id']
            (out/(qid+'.package.private.json')).write_text(body);(out/(qid+'.worker.private.json')).write_text(encode(payload))
            packages.append(package)
            row=dict(question_id=qid,exam_id=e['exam_id'],leaf_id=package['ids']['leaf'],package_sha256=digest(body.encode()),row_count=sum(map(len,rows.values())),student_pdf_pages=list(range(start,len(student)+1)),state='DRAFT',publication_allowed=False,official_content_preserved=True)
            records.append(row);selected.append(row);inputs[qid]=dict(examId=e['exam_id'],mode='image')
            values=','.join(literal(payload[k])+('::jsonb' if k.endswith('_text') else '') for k in ['question_id','exam_id','manifest_text','images_text','sha256'])
            worker.append('insert into math_private.task20_hanyang_source_pages(question_id,exam_id,manifest,images,content_sha256) values ('+values+');')
        path=out/(e['exam_id']+'.problem-only.private.pdf');student.save(path,deflate=True);count=len(student);student.close();h=digest(path.read_bytes())
        for r in selected:pdfs.append(dict(examId=e['exam_id'],questionId=r['question_id'],assetId=h,pageCount=count,startPage=r['student_pdf_pages'][0],verification='HASH_VERIFIED',studentDisplay='OWNER_APPROVAL_REQUIRED',storageRead='NOT_APPLIED'))
        expansions.append(dict(examId=e['exam_id'],universityId=e['university_id'],questionIds=e['registry_question_ids'],mathQuestions={r['question_id']:r['leaf_id'] for r in selected},mode='math',label=f"{e['university_name']} {e['admission_year']} {e['field_or_division']}",packageDigest=digest(encode(selected).encode()),completeExam=len(selected)==len(e['registry_question_ids'])))
    manifest=dict(version=plan['version'],packages=records,provider_calls=0,production_writes=0,publication_allowed=False)
    for name,data in [('source-plan.json',plan),('manifest.json',manifest),('web-expansion-candidate.json',dict(exams=expansions)),('web-pdf-candidate.json',pdfs),('web-input-candidate.json',inputs)]: (out/name).write_text(encode(data))
    (out/'register-draft.private.sql').write_text(registration_sql(packages))
    (out/'worker-source.private.sql').write_text('-- INSERT-only candidate. Requires Owner approval; conflict aborts.\nbegin;\nset local lock_timeout=\'5s\';\n'+ '\n'.join(worker)+'\ncommit;\n')
    for d in docs.values():d.close()
    return manifest

if __name__=='__main__':
    p=argparse.ArgumentParser()
    for k in ['plan','registry','source-paths','output']:p.add_argument('--'+k,required=True,type=Path)
    a=p.parse_args();r=prepare(json.loads(a.plan.read_text()),json.loads(a.registry.read_text()),json.loads(a.source_paths.read_text()),a.output)
    print(json.dumps(dict(packages=len(r['packages']),rows=sum(x['row_count'] for x in r['packages']),production_writes=0,provider_calls=0)))
