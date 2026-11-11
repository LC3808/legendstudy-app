import json,re,hashlib,copy
from pathlib import Path
import numpy as np
from PIL import Image
D=Path('.local/task03b');C=D/'cells';M={x['name']:x for x in json.load(open(C/'manifest.json'))};pages=json.load(open(D/'pages.json'));out=[];audit=[];number_ocr_issues=[]
def glyph(n):
 im=Image.open(C/'assets'/n).convert('L');a=np.array(im);yy,xx=np.where(a<160);im=im.crop((xx.min(),yy.min(),xx.max()+1,yy.max()+1));return np.asarray(im.resize((50,50)),dtype=float)/255
anchors={1:'p00-r07-c01.png',2:'p00-r06-c01.png',3:'p00-r00-c01.png',4:'p00-r01-c01.png',5:'p00-r02-c01.png'};templates={n:glyph(f) for n,f in anchors.items()}
point_templates={2:glyph('p00-r00-c02.png'),3:glyph('p00-r02-c02.png'),4:glyph('p02-r08-c02.png')}
def point(name):
 scores=sorted((float(np.mean((glyph(name)-t)**2)),n) for n,t in point_templates.items());assert scores[0][0]<.08 and scores[1][0]-scores[0][0]>.04,(name,scores);v=scores[0][1]
 if raw(name):assert digit(name)==v,(name,raw(name),v)
 return v
def raw(name):return ''.join(x['text'] for x in json.load(open(C/'ocr'/name.replace('.png','.json')))).replace(' ','')
def digit(name):
 t=raw(name);t={'4]':'41',']':'1','10월':'10'}.get(t,t)
 if not t.isdigit():raise ValueError((name,t))
 return int(t)
def circ(name):
 g=glyph(name);scores=sorted((float(np.mean((g-t)**2)),n) for n,t in templates.items());assert scores[0][0]<.08 and scores[1][0]-scores[0][0]>.015,(name,scores);audit.append(dict(cell=name,answer=scores[0][1],distance=scores[0][0],margin=scores[1][0]-scores[0][0],ocr=raw(name)))
 return scores[0][1]
subjects=['국어','국어','수학','수학','영어','영어','한국사','한국사','생활과윤리','윤리와사상','한국지리','세계지리','동아시아사','세계사','경제','정치와법','사회문화','물리학I','화학I','생명과학I','지구과학I','물리학II','화학II','생명과학II','지구과학II']
for i in range(25):
 subject=subjects[i];variant='홀수형' if i<8 and i%2==0 else '짝수형' if i<8 else '공통'
 starts=[1,18,35,35] if subject=='국어' else [1,12,23,23,23] if subject=='수학' else [1,13,25,37] if subject=='영어' else [1,6,11,16]
 lengths=[17,17,11,11] if subject=='국어' else [11,11,8,8,8] if subject=='수학' else [12,12,12,9] if subject=='영어' else [5]*4
 groups=[]
 for col,(start,n) in enumerate(zip(starts,lengths)):
  qs=[]
  for row in range(n):
   names=[f'p{i:02}-r{row:02}-c{col*3+j:02}.png' for j in range(3)]
   numraw=raw(names[0]);num=start+row
   if not numraw or digit(names[0])!=num:number_ocr_issues.append(dict(cell=names[0],ocr=numraw,grid_number=num))
   numeric=subject=='수학' and (16<=num<=22 or 29<=num<=30)
   ans=digit(names[1]) if numeric else circ(names[1]);pts=point(names[2]);assert pts in [2,3,4]
   qs.append(dict(number=num,answer_type='numeric' if numeric else 'multiple_choice',accepted_answers=[ans],all_credit=False,points=pts))
  groups.append(qs)
 electives=['화법과 작문','언어와 매체'] if subject=='국어' else ['확률과 통계','미적분','기하'] if subject=='수학' else [None]
 for j,elective in enumerate(electives):
  qs=groups[0]+groups[1]+groups[j+2] if elective else sum(groups,[]);assert [q['number'] for q in qs]==list(range(1,len(qs)+1));assert sum(q['points'] for q in qs)==(100 if i<6 else 50),(i,elective)
  p=copy.deepcopy(pages[i]);p.pop('error');p.update(subject=subject,elective=elective,variant=variant,question_count=len(qs),max_score=sum(q['points'] for q in qs),questions=qs,extraction_checks=['official_image_grid_cells','visual_glyph_anchors','point_total','number_order','legendstudy_answer_crosscheck_pending']);out.append(p)
(D/'2025_extracted.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));(D/'glyph_audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2));print('PAPERS',len(out),'CELLS',len(audit));print('WORST',sorted(audit,key=lambda x:x['margin'])[:15]);print('DIST',sorted(audit,key=lambda x:-x['distance'])[:8])

(D/'number_ocr_issues.json').write_text(json.dumps(number_ocr_issues,indent=2));print('NUMBER_OCR_ISSUES',len(number_ocr_issues))
