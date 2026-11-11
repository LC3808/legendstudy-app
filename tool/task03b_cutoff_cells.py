import json,re,statistics
from pathlib import Path
from PIL import Image,ImageOps
D=Path('.local/task03b/cutoffs');(D/'assets').mkdir(parents=True,exist_ok=True)
R=Path('.local/task03');tables=json.load(open('data/grade_cutoffs/task03_pending/ocr_candidates.json'))['tables'];records=[]
for ti,t in enumerate(tables):
 obs=json.load(open(R/'ocr'/t['local_file'].replace('.png','.json')));im=Image.open(R/'assets'/t['local_file']).convert('RGB');w,h=im.size
 headers=[]
 for token,key in [('원점수','raw_score'),('표준점수','standard_score'),('백분위','percentile'),('화법과','raw_speech_writing'),('언어와','raw_language_media'),('확률과','raw_probability_statistics'),('미적분','raw_calculus'),('기하','raw_geometry')]:
  a=[x for x in obs if x['text'].replace(' ','')==token and x['y']>.7]
  if len(a)==1:headers.append((key,a[0]['x']+a[0]['w']/2))
 grades={int(x['text'][0]):x['y']+x['h']/2 for x in obs if re.fullmatch('[1-8]등급',x['text'].replace(' ',''))}
 steps=[(grades[b]-grades[a])/(b-a) for a,b in zip(sorted(grades),sorted(grades)[1:])];step=statistics.median(steps);intercept=statistics.median(y-step*g for g,y in grades.items());assert step<0
 for key,x in headers:
  if key=='standard_score':continue
  gap=min(abs(x-xx) for xx in [0]+[xx for k,xx in headers if k!=key]+[1.15]);half=min(gap*.44,.13)
  for grade in range(1,9):
   y=grades.get(grade,intercept+step*grade);dy=abs(step)*.32
   box=[round((x-half)*w),round((1-y-dy)*h),round((x+half)*w),round((1-y+dy)*h)];cell=im.crop(box);cell=cell.resize((cell.width*3,cell.height*3));cell=ImageOps.expand(cell,20,fill='white');name=f't{ti:03}-g{grade}-{key}.png';cell.save(D/'assets'/name)
   old=next((r['cells'].get(key) for r in t['rows'] if r['grade']==grade),None)
   records.append(dict(file=name,table=ti,grade=grade,metric=key,box=box,original=old,grade_label_ocr_present=grade in grades))
(D/'manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2));print('cells',len(records))
