"""Create student question-only PDF derivatives from existing local originals.

For combined official reports, rasterize only the explicit question sections;
cropping a PDF alone would leave hidden solution text in its content stream.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
import pdfplumber
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader


def prepare(root, manifest, output):
    docs={d['sha256']:d for d in json.loads((root/'continuous-source-pages.private.json').read_text())}
    rows=json.loads(manifest.read_text())
    output.mkdir(parents=True,exist_ok=True)
    assets=[]
    for row in rows:
        source=docs[row['question_source_hash']]
        if '해설' not in source['title'] and '답안' not in source['title']:
            assets.append(dict(exam_id=row['examId'],path=source['path'],sha256=source['sha256'],source_hash=source['sha256'],page_count=len(source['pages']),question_pages=[1]*len(row['questions']),derived=False));continue
        target=output/(row['examId']+'.pdf')
        evidence=[];question_pages=[];page_count=0
        with pdfplumber.open(source['path']) as pdf:
            starts=[];ends=[]
            for i,page in enumerate(pdf.pages):
                starts += [(i,h['top']) for h in page.search(r'2\.\s*'+str(row['year'])+r'학년도[^\n]*문항\s*및\s*제시문')]
                ends += [(i,h['top']) for h in page.search(r'3\.\s*'+str(row['year'])+r'학년도[^\n]*출제\s*의도')]
            if len(starts)!=len(row['questions']) or len(ends)!=len(starts):
                raise ValueError(('QUESTION_SECTION_BOUNDS_REQUIRED',row['examId']))
            c=canvas.Canvas(str(target),invariant=1)
            for start,end in zip(starts,ends):
                if start>=end:raise ValueError('QUESTION_SECTION_ORDER')
                question_pages.append(page_count+1)
                for i in range(start[0],end[0]+1):
                    page=pdf.pages[i];top=max(0,start[1]-2) if i==start[0] else 0
                    bottom=max(0,end[1]-3) if i==end[0] else page.height
                    if bottom-top<20:continue
                    box=(0,top,page.width,bottom)
                    crop=page.crop(box)
                    image=crop.to_image(resolution=150).original
                    c.setPageSize((page.width,bottom-top));c.drawImage(ImageReader(image),0,0,width=page.width,height=bottom-top);c.showPage()
                    evidence.append(dict(source_page=i+1,bbox=box));page_count+=1
            c.save()
        assets.append(dict(exam_id=row['examId'],path=str(target),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),source_hash=source['sha256'],page_count=page_count,question_pages=question_pages,derived=True,source_regions=evidence))
    (output/'assets.private.json').write_text(json.dumps(assets,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(dict(exams=len(assets),derived=sum(a['derived'] for a in assets))))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('manifest',type=Path);p.add_argument('output',type=Path);a=p.parse_args();prepare(a.root,a.manifest,a.output)
