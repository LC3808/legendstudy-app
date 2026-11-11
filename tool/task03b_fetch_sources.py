import json,urllib.request,urllib.parse,hashlib,time,zipfile
from pathlib import Path
from bs4 import BeautifulSoup
import pymupdf
R=Path('.');D=R/'.local/task03b';D.mkdir(exist_ok=True);(D/'assets').mkdir(exist_ok=True);(D/'legendstudy').mkdir(exist_ok=True)
u='https://legendstudy.com/1649';b=urllib.request.urlopen(u,timeout=40).read();(D/'1649.html').write_bytes(b);s=BeautifulSoup(b,'html.parser');m=[]
for i,a in enumerate(s.select('figure.fileblock a')):
 title=a.get_text(' ',strip=True)
 if '정답' not in title or '.pdf' not in title:continue
 f=D/'legendstudy'/f'{i:02}.pdf';url=a['href']
 if not f.exists():f.write_bytes(urllib.request.urlopen(urllib.request.Request(url,headers={'Referer':u}),timeout=45).read());time.sleep(.2)
 doc=pymupdf.open(f);text='\n'.join(p.get_text(sort=True) for p in doc);f.with_suffix('.txt').write_text(text)
 m.append(dict(title=title,url=urllib.parse.urlunsplit(urllib.parse.urlsplit(url)._replace(query='')),file=f.name,sha256=hashlib.sha256(f.read_bytes()).hexdigest(),pages=len(doc),text_len=len(text)))
 print('legend',title,len(text),flush=True)
(D/'legendstudy_manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2))
e=json.load(open('.local/task03a/official/extracted.json'));pages=[]
assert len(e['failures'])==40 and all((p['academic_year'],p['exam_month'])==(2025,11) for p in e['failures']), 'Source scope changed; review required'
for i,p in enumerate(e['failures']):
 f=R/'.local/task03a/official'/p['file'];bs=zipfile.ZipFile(f).read(p['member']) if p['member'] else f.read_bytes();doc=pymupdf.open(stream=bs,filetype='pdf');name=f'p{i:02}'
 doc[p['page']-1].get_pixmap(matrix=pymupdf.Matrix(3,3)).save(D/'assets'/f'{name}.png');pages.append(dict(p,local_image=f'{name}.png'))
(D/'pages.json').write_text(json.dumps(pages,ensure_ascii=False,indent=2));print('rendered',len(pages),flush=True)
