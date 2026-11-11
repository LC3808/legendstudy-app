import json,re,math
from pathlib import Path
from PIL import Image,ImageDraw
D=Path('.local/task03b/cutoffs');rows=json.load(open(D/'manifest.json'));diff=[];counts={}
def number(s):
 s=s.replace(' ','').replace('–','~').replace('～','~')
 if re.fullmatch(r'\d{1,3}',s):return dict(value=int(s))
 m=re.fullmatch(r'(\d{1,3})[~-](\d{1,3})',s)
 if m and int(m[1])<=int(m[2]):return dict(min=int(m[1]),max=int(m[2]))
 return None
for r in rows:
 obs=json.load(open(D/'ocr'/r['file'].replace('.png','.json')));r['cell_ocr']=[x['text'] for x in obs];s=''.join(r['cell_ocr']);v=number(s);r['cell_parsed']=v;old=r['original']['parsed'] if r['original'] else None
 # null/null is not independently proven blank when OCR misses both; visually review all.
 if v!=old or v is None or not r['grade_label_ocr_present']:diff.append(r)
 else:r['review']='CELL_AND_PAGE_OCR_AGREE'
 counts[(r['metric'],v is not None)]=counts.get((r['metric'],v is not None),0)+1
(D/'comparison.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));print('diffs',len(diff),'counts',counts)
for page in range(math.ceil(len(diff)/70)):
 group=diff[page*70:(page+1)*70];out=Image.new('RGB',(1400,math.ceil(len(group)/10)*125),'white');dr=ImageDraw.Draw(out)
 for j,r in enumerate(group):
  im=Image.open(D/'assets'/r['file']);im.thumbnail((135,85));x=j%10*140;y=j//10*125;out.paste(im,(x,y+20));dr.text((x,y),r['file'].replace('raw_','').replace('percentile','pct')[:24],fill='black');dr.text((x,y+108),str(r['cell_parsed'])+' / '+str(r['original']['parsed'] if r['original'] else None),fill='red')
 out.save(f'/tmp/task03b-cutoffs-{page}.png')
(D/'review_needed.json').write_text(json.dumps(diff,ensure_ascii=False,indent=2))
print([(r['file'],r['original'],r['cell_ocr'],r['cell_parsed']) for r in diff if r['cell_parsed'] is not None][:60])
