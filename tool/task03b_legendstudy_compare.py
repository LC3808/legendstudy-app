from pathlib import Path
import json,re
from PIL import Image,ImageDraw
D=Path('.local/task03b');ps=json.load(open(D/'2025_extracted.json'));ms=json.load(open(D/'legendstudy_manifest.json'));diff=[]
labels={'국어':'국어','수학':'수학','영어':'영어','한국사':'한국사','물리학I':'물리학1','물리학II':'물리학2','화학I':'화학1','화학II':'화학2','생명과학I':'생명과학1','생명과학II':'생명과학2','지구과학I':'지구과학1','지구과학II':'지구과학2'}
el={'화법과 작문':'화작','언어와 매체':'언매','확률과 통계':'확통','미적분':'미적','기하':'기하'}
for p in ps:
 if p['variant']=='짝수형':continue
 label=labels.get(p['subject'],p['subject'])+(('('+el[p['elective']]+')') if p['elective'] else '')
 matches=[m for m in ms if label+' 정답' in m['title']];assert len(matches)==1,(label,matches)
 m=matches[0];t=(D/'legendstudy'/m['file']).with_suffix('.txt').read_text();pairs=re.findall(r'\b(\d{2})\.\s*([①②③④⑤]|\d{1,3})(?=\s|$)',t);answers={}
 for n,v in pairs:
  if 1<=int(n)<=p['question_count']:answers.setdefault(int(n),'①②③④⑤'.index(v)+1 if v in '①②③④⑤' else int(v))
 assert len(answers)==p['question_count'],(label,len(answers))
 delta=[(q['number'],q['accepted_answers'][0],answers[q['number']]) for q in p['questions'] if q['accepted_answers'][0]!=answers[q['number']]]
 diff+=delta;p['legendstudy_crosscheck']=dict(m,page_url='https://legendstudy.com/1649',compared_questions=len(answers),mismatches=delta)
 print(label,len(answers),delta)
(D/'2025_crosschecked.json').write_text(json.dumps(ps,ensure_ascii=False,indent=2));assert not diff
items=json.load(open(D/'number_ocr_issues.json'))
for k,items2 in enumerate([items, sorted(json.load(open(D/'glyph_audit.json')),key=lambda x:x['margin'])[:25]]):
 out=Image.new('RGB',(1200,((len(items2)+9)//10)*115),'white');dr=ImageDraw.Draw(out)
 for j,x in enumerate(items2):
  im=Image.open(D/'cells/assets'/x['cell']);im.thumbnail((110,85));xx=j%10*120;yy=j//10*115;out.paste(im,(xx,yy+25));dr.text((xx,yy),x['cell'].replace('.png',''),fill='black');dr.text((xx,yy+100),str(x.get('grid_number',x.get('answer'))),fill='red')
 out.save(f'/tmp/task03b-review-{k}.png')
