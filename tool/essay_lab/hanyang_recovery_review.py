"""Private L2-C3 human-review rendering; no provider or automatic quality judgment."""
import json
from pathlib import Path
from . import hanyang_recovery as r
from .vnext_owner_review import field, evaluation_sections, POSITIVE_CHECKS, CORRECTIVE_CHECKS, LOGIC_CHECKS

TARGETS=['사회계약 논증의 정확성','행위자/대상/조건의 논리 방향','공식 요구에 따른 미래 세대 논증',
 '공리주의 정당화','학생 자신의 비판과 입장 보존','논리 연결','구체적인 수정 행동',
 'Owner 확인 정정 전사 사용','명목 분량과 공식 채점 허용 범위 구분',
 '불필요한 X국 삽입 없음','별도 결론 단락의 허구 요구 없음','예시 모방 강요 없음',
 '장점의 WHY','성공한 논증의 재사용 전략','경미 표현은 부차적으로 유지']


def finding_rows(output,evidence):
    rows=['## 주요 판단과 실제 근거 대조',
          '아래 WHY/수정 방향은 GPT 원문입니다. 보고서가 빠진 이유나 공식 기준을 새로 만들어 넣지 않습니다.']
    byid={e['id']:e for e in evidence};cores=output['core_improvement_keys']
    for issue in output['improvements']:
        rows+=['### '+('CORE' if issue['issue_key'] in cores else 'NON-CORE'),field(issue['title']),
               '[학생이 쓴 내용]']
        spans=[s for s in output['sentence_feedback'] if s['linked_issue_key']==issue['issue_key']]
        rows += [field(s['quote']) for s in spans] if spans else ['별도 sentence quote 없음. 상단 전체 학생 원문과 아래 GPT 위치 설명을 대조하세요.']
        rows+=['[GPT 판단 / 왜 그렇게 판단했는가]',field(issue['explanation']),
               '[대학 공식 기준/제시문 근거 — 모델이 연결한 evidence, 실제 자료는 아래 부록]']
        refs=[{k:byid[i][k] for k in ('id','semantic_role','source_id','page','locator')} for i in issue['evidence_ids']]
        rows += [field(refs) if refs else '순수 local 관측: 공식 evidence 연결 없음.',
                 '[GPT가 제시한 수정 방향]',field(issue['action']),
                 '[Owner 확인]','- [ ] 지적 정확성 / 중요도 / 논리 방향 / 구체성 / 불필요한 요구 여부']
    return rows


def build(root=r.ROOT):
    prep=root/'prepared'/r.SLOT;target=root/'results'/r.SLOT
    result=r.old.strict_json(r.old.read_private(target/'terminal.json'))
    claim=r.old.strict_json(r.old.read_private(prep/'claim.json'))
    value=r.old.strict_json(r.old.read_private(prep/'input.json'))
    raw_payload=r.old.read_private(prep/'payload.json',32*1024*1024)
    r.old.require(r.old.sha256(raw_payload).hexdigest()==result['binding']['payload_hash'],'REVIEW_INPUT_DRIFT')
    payload=json.loads(raw_payload)
    r.old.require(r.old.digest(claim)==result['binding']['claim_hash'] and payload['input'][0]['content'][0]['text']==r.old.encoded(value).decode(),'REVIEW_INPUT_DRIFT')
    rows=['# 한양 L2-C3 — 비공개 Owner 검토',
          'HUMAN_QUALITY=PENDING_OWNER_REVIEW · PRIMARY_MODEL_SELECTED=NO · Gate C=WAIT_OWNER_REVIEW',
          '이전 L2-C2 UNKNOWN은 별개의 소비된 이력입니다. 이 문서는 새 L2-C3 결과만 표시합니다.',
          '## 문항 / 평가 맥락',field(value['question']),field(value['criteria']),
          '## 학생 원문 — 정정된 reviewed transcription',field(value['answer']),
          '## 구조 검증 / telemetry / transport',field(result)]
    if result['parser']=='PASS':
        raw=r.old.read_private(target/'raw-response.bin');normalized=r.old.read_private(target/'normalized.json')
        r.old.require(r.old.sha256(raw).hexdigest()==result['raw_hash'] and r.old.sha256(normalized).hexdigest()==result['normalized_hash'],'REVIEW_OUTPUT_DRIFT')
        output=r.old.parse_provider(normalized.decode(),claim)
        rows+=evaluation_sections(output)+finding_rows(output,value['evidence'])
    else:rows+=['## 정상화된 평가 없음','구조 검증 실패/미확정 결과를 수정하거나 품질 PASS로 해석하지 않습니다.']
    rows+=['## 공식 근거 부록 — 질문 범위 내 blind evidence만 표시']
    cat=r.old.strict_json(r.old.read_private(r.old.PACKAGES/'hanyang'/'catalog.json'))
    r.old.require(r.old.evidence.catalog_digest(cat)==result['binding']['catalog_hash'],'CATALOG_DRIFT')
    ds={x['id']:x for x in cat['derivatives']}
    for evidence in value['evidence']:
        rows+=['### 공식 근거',field({k:evidence[k] for k in ('id','semantic_role','source_id','page','locator')})]
        if 'text' in evidence:rows.append(field(evidence['text']))
        else:
            d=ds[evidence['id']];raw=r.old.blob(d['path']);r.old.require(r.old.sha256(raw).hexdigest()==evidence['sha256'],'EVIDENCE_DRIFT')
            p=Path(d['path']);p=p if p.is_absolute() else r.old.REPO/p
            rows.append('![공식 원문 페이지](<'+str(p)+'>)')
    for heading,checks in [('한양 검토 목표',TARGETS),('잘한 부분',POSITIVE_CHECKS),('고칠 부분',CORRECTIVE_CHECKS),('필요한 논리 관계',LOGIC_CHECKS)]:
        rows+=['## '+heading]+['- [ ] '+text for text in checks]
    rows+=['## Owner 판정','PASS / PARTIAL / FAIL / NOT_ASSESSABLE: 미기입',
           '공식 근거에 맞는 지적과 불필요한 비판을 구분해 주세요. Strong-answer 실호출은 이 검토가 승인되기 전에는 진행하지 않습니다.']
    path=root/'hanyang-owner-review.md';r.old.freeze(path,'\n\n'.join(rows).encode());return path
