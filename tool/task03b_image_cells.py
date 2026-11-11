from pathlib import Path
import numpy as np,json
from PIL import Image,ImageOps
D=Path('.local/task03b');O=D/'cells';(O/'assets').mkdir(parents=True,exist_ok=True);records=[]
def groups(ix):
 return [int(np.mean(x)) for x in np.split(ix,np.where(np.diff(ix)>2)[0]+1) if len(x)]
def runmax(row):
 edges=np.diff(np.r_[False,row,False].astype(int));starts=np.flatnonzero(edges==1);ends=np.flatnonzero(edges==-1);return max(ends-starts,default=0)
for i in range(25):
 im=Image.open(D/'assets'/f'p{i:02}.png').convert('RGB');a=np.array(im.convert('L'))<150
 xs=groups(np.flatnonzero(a.sum(axis=0)>a.shape[0]*.16));ys=groups(np.array([j for j,row in enumerate(a) if runmax(row)>250]))
 start=3 if i<4 else 1
 print(i,xs,ys,flush=True)
 for ri,(y1,y2) in enumerate(zip(ys[start:],ys[start+1:])):
  for ci,(x1,x2) in enumerate(zip(xs,xs[1:])):
   cell=im.crop((x1+8,y1+8,x2-8,y2-8));ink=np.array(cell.convert('L'))<150
   if ink.sum()<5:continue
   # crop around actual glyph and pad; preserve source pixel bbox for review.
   yy,xx=np.where(ink);box=(int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1)
   cell=cell.crop(box);cell=cell.resize((cell.width*3,cell.height*3));cell=ImageOps.expand(cell,50,fill='white')
   name=f'p{i:02}-r{ri:02}-c{ci:02}.png';cell.save(O/'assets'/name)
   records.append(dict(name=name,page=i,row=ri,col=ci,box=[x1+8+box[0],y1+8+box[1],x1+8+box[2],y1+8+box[3]]))
(O/'manifest.json').write_text(json.dumps(records,indent=2));print('CELLS',len(records))
