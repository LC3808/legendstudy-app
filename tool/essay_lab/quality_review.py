"""Offline Owner review of existing results; never calls Provider/DB or edits inputs."""
import argparse, json, html, pathlib, hashlib

def audit(runs, package):
    notes=[]
    for run in runs:
        for q in run['result']['questions']:
            answer=next(a['body'] for a in run['answers'] if a['questionId']==q['questionId'])
            e=q['evaluation']; feedback=e.get('sentence_feedback',[])
            exact=all(isinstance(x.get('start'),int) and isinstance(x.get('end'),int) and 0<=x['start']<x['end']<=len(answer) and answer[x['start']:x['end']]==x.get('quote') for x in feedback)
            notes.append(dict(run=run['id'],question=q['questionId'],answer_sha256=hashlib.sha256(answer.encode()).hexdigest(),
              quote_status=('PASS' if exact else 'FAIL') if feedback else 'NOT_VERIFIED',quote_count=len(feedback),
              package_match=package['package_digest'] in q['evidenceVersion'],
              quality='NOT_VERIFIED',reason='Owner must compare official evidence, submitted answer and feedback; schema checks are not quality approval.'))
    return notes

def render(runs, package, notes):
    esc=lambda x:html.escape(str(x))
    out=['<!doctype html><html lang="ko"><meta charset="utf-8"><title>한양대 첨삭 품질 검토</title><style>body{max-width:1000px;margin:32px auto;padding:16px;font:17px/1.7 sans-serif;color:#172b4d}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f4f5f7;padding:16px}section{border-top:1px solid #555;padding:24px 0}summary{cursor:pointer;font-weight:bold}td,th{border:1px solid #bbb;padding:8px}table{border-collapse:collapse;width:100%}</style><h1>한양대 2024 수시 인문 오후 2 · 문제 1</h1><p>기존 실제 평가 2건의 읽기 전용 검토 자료. 새 평가·Credit 거래 없음. 최종 품질 판정: NOT_VERIFIED — Owner 검토 대기.</p>']
    out.append('<p>Package '+esc(package['package_version'])+' / '+esc(package['package_digest'])+'</p>')
    out.append('<details><summary>검수 Package의 공식 자료·페이지 근거</summary><pre>'+esc(json.dumps(package,ensure_ascii=False,indent=2))+'</pre></details>')
    before={}
    for i,run in enumerate(runs):
        out.append('<section><h2>'+('최초 첨삭' if not run['parent_id'] else '무료 재첨삭')+'</h2><p>'+esc(run['completed_at'])+'</p>')
        for q in run['result']['questions']:
            e=q['evaluation'];answer=next(a['body'] for a in run['answers'] if a['questionId']==q['questionId'])
            out.append('<details><summary>'+('최초 제출 답안' if i==0 else '수정 제출 답안 — 직접 연결된 재첨삭')+'</summary><pre>'+esc(answer)+'</pre></details>')
            out.append('<h3>종합 평가</h3><pre>'+esc(e['summary'])+'</pre><table><tr><th>평가요소 (저장된 원문)</th><th>평가 단계</th><th>평가 근거</th></tr>')
            labels={c['binding']['id']:c['label'] for c in q['criteria']}
            for d in e['dimensions']:
                old=before.get(d['criterion_id']);change=(f'{old}/5 → ' if old is not None else '')+str(d['level'])+'/5'
                out.append('<tr><td>'+esc(labels.get(d['criterion_id'],d['criterion_id']))+'</td><td>'+esc(change)+'</td><td>'+esc(d['explanation'])+'</td></tr>');before[d['criterion_id']]=d['level']
            out.append('</table><p>원문 안의 %는 Package에 포함된 평가자료 라벨이며 별점은 서비스 5단계 평가입니다. 서로 다른 값입니다.</p>')
            for key,title in [('strengths','강점'),('improvements','보완점·수정 방향'),('previous_improvement_reviews','AI의 이전 보완점 비교'),('sentence_feedback','문장 인용·수정 예시')]:
                value=e.get(key,[]);out.append('<details><summary>'+title+'</summary><pre>'+esc(json.dumps(value,ensure_ascii=False,indent=2) if value else '저장된 항목 없음 — 생성하거나 보충하지 않음')+'</pre></details>')
        out.append('</section>')
    out.append('<h2>Owner 검토 항목</h2><p>논제·제시문 해석 / 공식 기준 적용 / 실제 수정과 단계 변화의 관계 / 강점·보완점 구체성 / 수정 방향의 타당성 / 존재하지 않는 인용 여부.</p><p>PASS: 핵심 평가와 피드백 타당. PARTIAL: 일부 보완 필요. FAIL: 중대한 해석·인용 오류. NOT_VERIFIED: 자료·검토 부족.</p><p>Owner 판정: ______ 근거 및 수정 의견: __________________</p><details><summary>자동 점검 결과 (품질 승인 아님)</summary><pre>'+esc(json.dumps(notes,ensure_ascii=False,indent=2))+'</pre></details></html>')
    return ''.join(out)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--runs',required=True);p.add_argument('--package',required=True);p.add_argument('--output',required=True);a=p.parse_args()
    runs=json.loads(pathlib.Path(a.runs).read_text());pkg=json.loads(pathlib.Path(a.package).read_text())[0]['body']['package'];notes=audit(runs,pkg)
    target=pathlib.Path(a.output);target.write_text(render(runs,pkg,notes));target.chmod(0o600)
    print(json.dumps({'runs':len(runs),'quote_status':[n['quote_status'] for n in notes],'package_match':all(n['package_match'] for n in notes),'quality':'NOT_VERIFIED','output':str(target)}))
