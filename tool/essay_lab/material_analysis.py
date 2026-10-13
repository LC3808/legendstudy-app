"""Offline PDF role/page candidates. No upload, Provider, publication or activation.
Originals are read-only. Outputs belong ONLY in a private operator directory.
"""
import argparse, hashlib, json, os, re
from pathlib import Path
from .live_worker import digest, require

ROLE_MARKERS = {
 'question': r'(?:문제|문항|논제)\s*\d|제시문',
 'intent': r'출제\s*의도', 'explanation': r'해설|풀이',
 'criteria': r'평가\s*(?:기준|요소)', 'scoring': r'채점\s*기준|배점',
 'model_answer': r'(?:예시|우수|모범)\s*답안',
}

def analyze_pages(pages, source_hash):
    sections=[]; years=set(); low=[]
    for index,text in enumerate(pages):
        years.update(re.findall(r'(20\d{2})\s*학년도',text))
        if len(text.strip())<40: low.append(index+1)
        for role,pattern in ROLE_MARKERS.items():
            if re.search(pattern,text):
                sections.append({'sourceHash':source_hash,'role':role,'startPage':index+1,
                    'endPage':index+1,'pdfIndex':index,'printedPage':None,
                    'questionId':None,'verification':'NEEDS_REVIEW'})
    roles={s['role'] for s in sections}
    return {'sourceHash':source_hash,'pageCount':len(pages),'sections':sections,
        'yearCandidates':sorted(years),'visualReviewPages':low,
        'documentType':'COMPOSITE' if len(years)>1 else ('INTEGRATED' if len(roles)>1 else 'SEPARATE'),
        'verification':'NEEDS_REVIEW','studentDelivery':'BLOCKED',
        'rights':{'download':'UNVERIFIED','studentDisplay':'UNVERIFIED','providerTransmission':'UNVERIFIED'}}

def analyze_file(path):
    from pypdf import PdfReader
    raw=path.read_bytes();require(raw.startswith(b'%PDF-'),'NOT_PDF')
    require(len(raw)<=128*1024*1024,'PDF_TOO_LARGE')
    sha=hashlib.sha256(raw).hexdigest();reader=PdfReader(path)
    require(not reader.is_encrypted,'ENCRYPTED_PDF_REQUIRES_REVIEW')
    require(0<len(reader.pages)<=3000,'PAGE_COUNT')
    result=analyze_pages([page.extract_text() or '' for page in reader.pages],sha)
    result['title']=path.name
    return result

def freeze_review(review, documents, registry, question_id):
    """Immutable question package manifest; not a runtime activation decision.
    Private texts/images remain in existing reviewed evidence caches referenced here.
    """
    require(review['state']=='VERIFIED','REVIEW_REQUIRED')
    exams=[x for x in registry['exams'] if x['examId']==review['examId']]
    require(len(exams)==1,'EXAM_NOT_REGISTERED');exam=exams[0]
    require(any(q['id']==question_id for q in exam['questions']),'QUESTION_NOT_IN_EXAM')
    mappings=[m for m in review['body']['mappings'] if m['questionId']==question_id]
    require(any(m['role']=='question' for m in mappings),'QUESTION_EVIDENCE_REQUIRED')
    for m in mappings:
        d=documents[m['sourceHash']]
        require(d['sourceHash']==m['sourceHash'],'SOURCE_HASH_MISMATCH')
        require(type(m['startPage']) is int and type(m['endPage']) is int and 1<=m['startPage']<=m['endPage']<=d['pageCount'],'PAGE_RANGE')
        require(m.get('verification')=='VERIFIED','MAPPING_REVIEW_REQUIRED')
        if m['role']=='question':require(m['sourceHash'] in exam['sourceHashes'],'QUESTION_SOURCE_MISMATCH')
    package={'version':'material-review-v1','university_id':exam['universityId'],
      'exam_id':exam['examId'],'question_id':question_id,'exam_identity':{k:exam[k] for k in ('year','kind','track','session','campus')},
      'package_version':review['revision'],'source_page_references':mappings,
      'rights_status':{m['sourceHash']:documents[m['sourceHash']]['rights'] for m in mappings},
      'verification_status':'VERIFIED_MANIFEST','runtime_ready':False}
    package['package_digest']=digest(package)
    return package

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('pdf',type=Path,nargs='+');p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    os.umask(0o077);a.output.mkdir(parents=True,exist_ok=True)
    for file in a.pdf:
        result=analyze_file(file);target=a.output/(result['sourceHash']+'.json')
        # Do not overwrite a prior human review; analysis is an immutable draft.
        if not target.exists():target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'analyzed':len(a.pdf),'verified':0,'published':0}))
