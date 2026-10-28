"""Score local OCR exports, never contacts a service. NFC codepoint CER; whitespace WER."""
import json,sys,unicodedata,statistics
from pathlib import Path

def distance(a,b):
    prev=list(range(len(b)+1))
    for i,x in enumerate(a,1):
        row=[i]
        for j,y in enumerate(b,1):
            row.append(min(row[-1]+1,prev[j]+1,prev[j-1]+(x!=y)))
        prev=row
    return prev[-1]

def normalized(s):
    return ' '.join(unicodedata.normalize('NFC',s).split())

assert distance('abc','adc')==1 and distance('','ab')==2
assert normalized('가\n 나')=='가 나'
data=json.loads(Path(sys.argv[1]).read_text())
rows=[]
for name in dict.fromkeys(r['case'] for r in data['records']):
    runs=[r for r in data['records'] if r['case']==name];r=runs[0]
    a,b=normalized(r['reference']),normalized(r['text'])
    rows.append(dict(case=name,reference_characters=len(a),character_errors=distance(a,b),CER=distance(a,b)/len(a),reference_words=len(a.split()),word_errors=distance(a.split(),b.split()),WER=distance(a.split(),b.split())/len(a.split()),line_count_reference=len([s for s in r['reference'].splitlines() if s]),line_count_output=len(r['text'].splitlines()),blank_paragraph_boundary_preserved=('\n\n' in r['text']) if '\n\n' in r['reference'] else None,seconds=[x['seconds'] for x in runs],median_seconds=statistics.median(x['seconds'] for x in runs),repeat_text_identical=len({x['text'] for x in runs})==1))
print(json.dumps({'scope':data['scope'],'os':data['os'],'revision':data['records'][0]['revision'],'normalization':'NFC; whitespace folded to one space; punctuation/case retained; paragraph check separate','results':rows},ensure_ascii=False,indent=2))
