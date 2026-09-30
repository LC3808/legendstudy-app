"""Build two private L2-C1 packages from already retained, reviewed PDFs; offline.
Requires bundled pypdf/pypdfium2. Never writes the frozen L2-B root. No OCR/network.
"""
import argparse,json,os
from pathlib import Path
from hashlib import sha256
from pypdf import PdfReader
import pypdfium2 as pdfium
from .live_worker import digest,encoded
from .official_evidence_package import VERSION,BASE_ROLES,EXAMPLES,freeze_manifest,validate,blind_input,catalog_digest
from .scaffolding_vnext import prompt_contract

def build(source_repo, out):
    out.mkdir(mode=0o700,parents=True,exist_ok=False)
    plan=json.loads((Path(__file__).parent/'quality_pilot_2025_plan.json').read_text())
    hy=json.loads((Path(__file__).parent/'evidence/hanyang_afternoon2_source.json').read_text())
    approved=json.loads((Path(__file__).parent/'evidence/evidence_vnext_l2c1_result.json').read_text())
    pinned={s['filename']:s['sha256'] for case in approved for s in case['source_files']}
    summaries=[]
    for case in ('sookmyung','hanyang'):
        dest=out/case;dest.mkdir(mode=0o700)
        question={'id':f'{case}/'+('2025/mock-humanities/1-1' if case=='sookmyung' else '2024/humanities-afternoon-2/1'),'university':case,'exam_key':'mock-humanities' if case=='sookmyung' else 'humanities-afternoon-2','admission_year':2025 if case=='sookmyung' else 2024,'canonical_question_id':None}
        # No fabricated DB UUID: natural scoped question identity; canonical registration remains separate.
        c={'question':question,'sources':[],'derivatives':[],'criteria':{},'allowed_evidence':[],'selected_transcription':'answer-v2'}
        def save(name,body):
            p=dest/name;p.write_bytes(body);p.chmod(0o600);return str(p),sha256(body).hexdigest()
        def source(ident,path,provenance='official_university_source',expected=None):
            h=sha256(path.read_bytes()).hexdigest()
            assert h==(expected or pinned[path.name]),'Accepted source drift'
            c['sources'].append(dict(id=ident,path=str(path),sha256=h,provenance=provenance))
            return path
        def derivative(ident,source_id,page,role,body,locator,media='text/plain',prior=None,current=True,identity=None):
            path,h=save(ident+('.png' if media=='image/png' else '.txt'),body)
            d=dict(id=ident,identity=identity or ident,source_id=source_id,page=page,locator=locator,semantic_role=role,canonical_role=BASE_ROLES.get(role),question_id=question['id'],version='2' if prior else '1',review_state='reviewed',current=current,path=path,sha256=h,media_type=media,prior_id=prior,correction_reason='Owner verified readable manuscript phrase; prior version retained' if prior else None,reviewer='OWNER_VERIFIED' if prior else 'existing-source-review-plus-L2-C1',reviewed_at='2026-09-30')
            c['derivatives'].append(d)
            if role in BASE_ROLES:c['allowed_evidence'].append(ident)
        def image(ident,sid,path,page,role,locator):
            import io
            doc=pdfium.PdfDocument(str(path));im=doc[page-1].render(scale=1.5).to_pil();b=io.BytesIO();im.save(b,format='PNG');doc.close()
            derivative(ident,sid,page,role,b.getvalue(),locator,'image/png')
        if case=='sookmyung':
            base=source_repo/'.local/essay-quality-2025'
            qp=source('question-pdf',base/'sm-official-0.pdf')
            cp=source('rubric-pdf',base/'sm-official-1.pdf')
            ap=source('answer-source',base/'1697-3.pdf','student_submission')
            blind_bytes=(base/'packages/sookmyung/blind_input.json').read_bytes()
            accepted=json.loads((Path(__file__).parent/'quality_pilot_2025_result.json').read_text())['packages']['sookmyung']['files']['blind_input.json']
            assert sha256(blind_bytes).hexdigest()==accepted,'Reviewed extraction drift'
            blind=json.loads(blind_bytes)
            # Reuse reviewed Q1-1-only extraction; no Q1-2 criterion leakage.
            derivative('Q','question-pdf',2,'question',blind['question'].encode(),'PDF pages 1–2; Q1-1 only')
            derivative('P','question-pdf',1,'passage',blind['passages'].encode(),'PDF pages 1–2; passages 가/나 only')
            pages=[(p.extract_text() or '').replace('\x00',' ') for p in PdfReader(cp).pages]
            intent=pages[3].split('3. 출제 의도',1)[1].split('4. 출제 근거',1)[0]
            # Official shared intent retained with explicit scope, not mandatory criterion.
            derivative('intent','rubric-pdf',4,'official_intent',intent.encode(),'section 3; shared intent, Q1-1 applies only to 가/나')
            criteria=pages[5].split('1-1',1)[1].split('1-2',1)[0]
            derivative('rubric','rubric-pdf',6,'scoring_criterion',criteria.encode(),'section 6; Q1-1 row only')
            derivative('question-length','question-pdf',2,'question_length_rule','300±30자'.encode(),'Q1-1 displayed instruction')
            derivative('scoring-length','rubric-pdf',6,'scoring_length_rule','글자 수 200자 이내 답안은 0점(9등급) 처리함.'.encode(),'Q1-1 유의 사항')
            example=pages[6].split('7. 예시 답안',1)[1].split('1-2.',1)[0]
            derivative('example-1','rubric-pdf',7,'official_example',example.encode(),'section 7; Q1-1 only; reviewer calibration')
            c['criteria']={'Q1-1-holistic':dict(source_evidence='rubric',origin='official',official_weight=None)}
            exam=next(x for x in plan['exams'] if x['exam_key']=='mock-humanities' and x['admission_year']==2025 and '숙명' in x['exam_name'])
            c['question'].update(exam_id=exam['id'],university_id=exam['university_id'])
        else:
            paths=[Path(x['local_path']) for x in hy['files']]
            qp=source('question-pdf',paths[0],expected=hy['files'][0]['sha256'])
            ep=source('examples-pdf',paths[1],expected=hy['files'][1]['sha256'])
            gp=source('guide-pdf',paths[2],expected=hy['files'][2]['sha256'])
            source('answer-source',paths[1],'student_submission',hy['files'][1]['sha256'])
            image('Q','question-pdf',qp,2,'question','question prompt and passages; 2024 humanities Afternoon2')
            image('P','question-pdf',qp,3,'passage','remaining passages; same question')
            image('intent','guide-pdf',gp,51,'official_intent','PDF51 / printed49; official intent, not mandatory checklist')
            image('rubric','guide-pdf',gp,52,'scoring_criterion','PDF52 / printed50; five official domains and weights')
            image('rubric-holistic','guide-pdf',gp,53,'scoring_criterion','PDF53 / printed51; holistic descriptors and formal rules')
            derivative('question-length','question-pdf',2,'question_length_rule','1,200자'.encode(),'question displayed target; not scoring tolerance')
            derivative('scoring-length','guide-pdf',53,'scoring_length_rule','1,150자 이상 1,250자 이내: 감점 없음; 1,250자 초과: -1점; 1,100자 이상 1,150자 미만: -1점; 1,050자 이상 1,100자 미만: -2점; 1,000자 이상 1,050자 미만: -4점; 950자 이상 1,000자 미만: -6점; 900자 이상 950자 미만: -8점; 850자 이상 900자 미만: -10점. 표에 없는 구간은 추론하지 않음. 전사 Unicode count는 원고지 산정이 아님.'.encode(),'PDF53 section4 length table; visually reviewed')
            derivative('non-criterion','guide-pdf',53,'explicit_non_criterion','서론-본론-결론의 형식을 갖추었는지의 여부는 평가에 반영하지 않음.'.encode(),'PDF53 section5 second bullet')
            for i in (1,2):image(f'example-{i}','examples-pdf',ep,i,'accepted_example',f'Owner retained official accepted-answer PDF page{i}; calibration only')
            for key,weight in zip(('structure','future_generations','social_contract','utilitarianism','expression'),(10,25,25,30,10)):
                c['criteria'][key]=dict(source_evidence='rubric',origin='official',official_weight=weight)
            c['question'].update(exam_id=None,university_id=next(x['university_id'] for x in plan['exams'] if '한양' in x['exam_name']))
        old=(source_repo/'.local/essay-rewrite-v1'/case/'original.txt').read_bytes()
        old_expected=json.loads((source_repo/'.local/essay-bakeoff-l2b'/case/'package.json').read_text())['answer_hash']
        assert sha256(old).hexdigest()==old_expected,'Frozen answer drift'
        corrected=old
        if case=='hanyang':
            old_phrase='오로지 최대행복 최소고통만을 [판독 어려움]하는 공리주의는'
            new_phrase='오로지 최대 행복, 최소 고통만을 주장하는 공리주의는'
            assert old.decode().count(old_phrase)==1,'Transcription correction target mismatch'
            corrected=old.decode().replace(old_phrase,new_phrase).encode()
        derivative('answer-v1','answer-source',1 if case=='sookmyung' else 2,'student_transcription',old,'selected original response; frozen transcription',current=False,identity='answer')
        derivative('answer-v2','answer-source',1 if case=='sookmyung' else 2,'student_transcription',corrected,'same selected response; new reviewed version',prior='answer-v1',identity='answer')
        if case=='sookmyung':c['derivatives'][-1]['correction_reason']='No text correction; retained reviewed transcription in new package'
        p=freeze_manifest(c);validate(p,c,lambda path:Path(path).read_bytes())
        view=blind_input(p,c,lambda path:Path(path).read_bytes())
        save('catalog.json',encoded(c));save('manifest.json',encoded(p));save('blind-input.json',encoded(view))
        pc=prompt_contract();save('prompt.txt',pc['prompt'].encode());save('schema.json',encoded(pc['schema']))
        summary=dict(case_id=case,package_version=VERSION,question=c['question'],source_files=[dict(id=s['id'],filename=Path(s['path']).name,sha256=s['sha256']) for s in c['sources']],evidence_roles=sorted({d['semantic_role'] for d in c['derivatives']}),derivative_versions={d['id']:dict(version=d['version'],sha256=d['sha256'],page=d['page']) for d in c['derivatives']},criterion_count=len(c['criteria']),example_answer_count=sum(d['semantic_role'] in EXAMPLES for d in c['derivatives']),non_criteria_count=sum(d['semantic_role']=='explicit_non_criterion' for d in c['derivatives']),question_length_rule_present=True,scoring_length_rule_present=True,transcription_review_state='OWNER_VERIFIED_CORRECTION' if case=='hanyang' else 'RETAINED_REVIEWED',package_hash=p['hash'],catalog_hash=catalog_digest(c),prompt_version=pc['prompt_version'],prompt_hash=pc['prompt_sha256'],contract_version='1.3',schema_hash=digest(pc['schema']),validation_status='PASS',production_registered=False)
        summaries.append(summary)
    return summaries

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--source-repo',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args()
    print(json.dumps(build(a.source_repo,a.out),ensure_ascii=False,indent=2))
