"""Connect Owner-held HUFS exam cards to the existing whole-exam contract.

Local artifacts only. No Provider, SQL execution, or student data changes.
"""
import argparse, base64, hashlib, importlib.util, io, json, re, sys, uuid
from pathlib import Path
import pdfplumber
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from essay_lab.live_worker import digest
from essay_lab.material_runtime import load_reviewed_material

def prepare(root, registry_path, web):
    read=lambda p:json.loads(p.read_text())
    source=read(root/'hufs-source-pages.private.json')
    old=read(root/'registry-before.private.json')
    baseline=read(root/'baseline.private.json')
    registry=read(registry_path)
    ns=uuid.uuid5(uuid.NAMESPACE_URL,'https://github.com/LC3808/legendstudy-app/essay-source-registration/v1')
    out=root/'hufs';out.mkdir(exist_ok=True);(out/'pdf').mkdir(exist_ok=True)
    rows=[];packages={};assets=[]
    for d in sorted(source,key=lambda x:x['title']):
        year=int(d['title'][:4]);track='인문계' if '인문' in d['title'] else '사회계';session=re.search(r'\((T\d)\)',d['title'])[1]
        matches=[e for e in old if e['slug']=='hufs' and (e['admission_year'],e['exam_kind'],e['field_or_division'],e['session_label'])==(year,'admission',track,session)]
        assert len(matches)<=1
        existing=matches[0] if matches else None
        key=f'source:hufs-{year}-admission-{track}-{session}'
        eid=existing['id'] if existing else str(uuid.uuid5(ns,'exam/'+key))
        qs=[dict(id=q['id'],sourceKey=q['question_key'],label=q['label'],order=q['display_order']) for q in existing['questions']] if existing else [dict(id=str(uuid.uuid5(ns,'question/'+key+':'+str(n))),sourceKey=key+':'+str(n),label='문제 '+str(n),order=n-1) for n in (1,2,3)]
        assert len(qs)==3 and not (existing and existing['runtime'])
        ps=[x.replace('\x00',' ') for x in d['pages']];t='\n'.join(ps)
        intent=re.search(r'(?m)^\s*3\s*(?:출제\s*의도|문항\s*해설)',t)
        ground=re.search(r'(?m)^\s*4\s*출제\s*근거',t)
        score=re.search(r'(?m)^\s*[56]\s*채점\s*기준',t)
        example=re.search(r'(?m)^\s*[67]\s*예시\s*답안',t)
        assert all([intent,ground,score,example]) and intent.end()<ground.start()<score.start()<example.start()
        qt=t[:intent.start()].rstrip();sc=t[score.end():example.start()]
        qmarks=[next(re.finditer(r'(?m)^\s*\[문제\s*'+str(n)+r'\]',qt)) for n in (1,2,3)]
        smarks=list(re.finditer(r'(?m)^\s*\[문제\s*([123])\]\s*$',sc));assert [m[1] for m in smarks]==['1','2','3']
        def page(pos):
            acc=0
            for i,p in enumerate(ps,1):
                acc+=len(p)+1
                if pos<acc:return i
            return len(ps)
        last=page(intent.end());ims=[];official=[];crop_info=[]
        with pdfplumber.open(d['path']) as pdf:
            for i,p in enumerate(pdf.pages[:last]):
                if i==last-1:
                    hits=p.search(r'3\s*(?:출제\s*의도|문항\s*해설)');assert len(hits)==1
                    bottom=hits[0]['top']-3
                    if not (ps[i][:ps[i].find(hits[0]['text'])].strip().replace('Ⅶ.부록2-고사별 문항 카드','').strip()):break
                    if bottom<70:break
                    p=p.crop((0,0,p.width,bottom));crop_info.append(dict(page=i+1,bottom=bottom))
                im=p.to_image(resolution=120).original.convert('RGB');ims.append(im)
                b=io.BytesIO();im.convert('L').save(b,format='PNG',optimize=True);raw=b.getvalue()
                official.append(dict(sha256=hashlib.sha256(raw).hexdigest(),data=base64.b64encode(raw).decode(),sourceHash=d['sha256'],startPage=i+1,endPage=i+1))
        assert ims
        path=out/'pdf'/(eid+'.pdf');ims[0].save(path,format='PDF',save_all=True,append_images=ims[1:],resolution=120)
        sha=hashlib.sha256(path.read_bytes()).hexdigest()
        rr=[r for r in baseline['resources'] if r['title']==d['title']];assert len(rr)<=1
        doc=dict(title=d['title'],sha256=d['sha256'],local_path=d['path'],page_count=len(ps),resource_id=rr[0]['id'] if rr else None)
        row=dict(examId=eid,sourceKey=key,existingExam=bool(existing),universityId='1fd29b0d-1141-4ff0-b1b3-c4f201854476',year=year,kind='admission',track=track,session=session,campus=None,examKey=existing['exam_key'] if existing else key.replace('source:','source-'),name=existing['exam_name'] if existing else f'{year}학년도 한국외국어대학교 수시논술 {track} {session}',sourceHashes=[d['sha256']],questions=qs,documents=[doc],parent_count=3)
        if not existing:
            row['examKey']='source-'+hashlib.sha256(key.encode()).hexdigest()
        rows.append(row)
        e=next((e for e in registry['exams'] if e['examId']==eid),None)
        if e:
            assert {q['id'] for q in e['questions']}=={q['id'] for q in qs};e.update({k:row[k] for k in ('questions','sourceHashes','name','track','session')})
        else:registry['exams'].append({k:row[k] for k in ('examId','universityId','year','kind','track','name','session','campus','questions','sourceHashes')})
        package=dict(schema='essay-material-package-v1',exam_id=eid,university_id=row['universityId'],package_version=1,verification_status='VERIFIED_MANIFEST',review_scope='selected_questions',exam_identity=dict(academic_year=year,exam_type='admission',track=track,title=row['name']),questions=[],rights_status={d['sha256']:dict(providerTransmission='APPROVED',purpose='Owner three-university STANDBY authorization 2026-10-26')})
        for i,q in enumerate(qs):
            a=qmarks[i].start();b=qmarks[i+1].start() if i<2 else len(qt)
            ca=score.end()+smarks[i].end();cb=score.end()+(smarks[i+1].start() if i<2 else len(sc))
            refs=[]
            for role,start,end in [('question',a,b),('shared_passage',0,len(qt)),('intent',intent.start(),ground.start()),('criteria',ca,cb)]:
                refs.append(dict(questionId=q['id'],sourceHash=d['sha256'],startPage=page(start),endPage=page(end-1),role=role,verification='VERIFIED',evidenceText=t[start:end].strip()))
            package['questions'].append(dict(question_id=q['id'],source_key=q['sourceKey'],source_page_references=refs,official_images=official))
        package['package_digest']=digest(package)
        _,report=load_reviewed_material(package,registry,pinned_digest=package['package_digest'],binding={},regime='held',evaluation_type='humanities',activation_approved=False)
        assert report['ready'],report
        packages[eid]=package
        assets.append(dict(exam_id=eid,path=str(path),sha256=sha,source_hash=d['sha256'],page_count=len(ims),question_pages=list(range(1,len(ims)+1)),derived=True,crops=crop_info))
    for name,data in [('manifest.json',rows),('packages.private.json',packages),('assets.private.json',assets),('registry-worker.private.json',registry)]:
        (out/name).write_text(json.dumps(data,ensure_ascii=False))
    spec=importlib.util.spec_from_file_location('registration',web/'scripts/essay-materials/prepare_registration.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
    new=[r for r in rows if not r['existingExam']];sql=m.sql_document(dict(exams=new)).replace("and id<>eid and exam_key not like 'source-%'","and id<>eid and field_or_division=e->>'track' and session_label is not distinct from e->>'session'")
    (out/'registry-apply.sql').write_text(sql)
    print(json.dumps(dict(exams=len(rows),new_registry=len(new),question_units=sum(len(r['questions']) for r in rows),provider_calls=0)))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('registry',type=Path);p.add_argument('web',type=Path);a=p.parse_args();prepare(a.root,a.registry,a.web)
