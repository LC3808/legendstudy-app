"""Read-only private Owner report from frozen L2-C2 results. Never repairs output."""
import json
from . import vnext_validation as v

POSITIVE_CHECKS=['실제 학생 답안에서 확인되는 장점인가?','왜 잘된 것인지 설명했는가?',
 '논제/대학 평가기준과의 관계가 설명되는가?','칭찬을 넘어 학습 가능한 정보인가?',
 '다음 문제에서도 재사용할 사고/논증 전략이 있는가?','좋은 부분을 불필요하게 다시 쓰게 하지 않는가?']
CORRECTIVE_CHECKS=['학생의 구체적 문제를 정확히 찾았는가?','왜 문제인지 기준/논리와 연결했는가?',
 '필요한 학생 문장/논증 위치를 짚었는가?','추상적 보완 지시에서 끝나지 않는가?',
 '빠진 내용/논리 연결을 알려 주는가?','다음 답안에서 할 행동을 알 수 있는가?',
 '학생 대신 완성 답안을 쓰거나 입장을 바꾸지 않는가?']
LOGIC_CHECKS=['주장→이유','이유→근거','근거→해석','해석→논제','원인→중간 과정→결과',
 '개념→사례 적용','비판→근거→학생의 최종 판단','성공한 연결의 효과와 재사용 전략']


def field(value):
    return v.block(value if isinstance(value,str) else json.dumps(value,ensure_ascii=False,indent=2))


def evaluation_sections(out):
    if not isinstance(out,dict):return ['### 해석할 수 없는 원문',field(out)]
    rows=['### 종합 평가',field(out.get('summary')),'### 잘한 부분 — 학생 행동 → WHY → 기준 → 재사용 전략',
          '아래는 GPT strengths 전문입니다. 각 요소의 실제 포함 여부를 Owner가 확인합니다. 누락된 설명을 보고서가 보충하지 않습니다.']
    for i,s in enumerate(out.get('strengths',[]) or []):rows.extend([f'#### 장점 {i+1}',field(s)])
    rows.append('### 평가기준별 진단')
    for d in out.get('dimensions',[]) or []:
        rows.append(field(d))
    cores=out.get('core_improvement_keys',[]) or []
    rows+=['### 고칠 부분 — 학생 원문/위치 → 문제 → WHY → HOW',
           'CORE/NON-CORE 표시는 Owner 검토용입니다. 설명과 수정 방향은 모델 원문 그대로이며, 실제 WHY가 없는 경우 미충족으로 검토하세요.']
    for r in out.get('improvements',[]) or []:
        if not isinstance(r,dict):rows.append(field(r));continue
        tag='CORE' if r.get('issue_key') in cores else 'NON-CORE'
        rows += [f'#### {tag}',field(r.get('title')),'문제 / 위치 / WHY (explanation 원문)',field(r.get('explanation')),
                 'HOW (action 원문)',field(r.get('action')),'검토용 provenance',field({k:r.get(k) for k in ('issue_key','category','priority','status','claim_scope','evidence_ids')})]
    if not cores:rows.append('선택된 CORE 없음. 강한 답안에서는 정상일 수 있으며, 강제로 문제를 만들지 않습니다.')
    rows.append('### 학생 문장 인용 / 문장 다듬기')
    for s in out.get('sentence_feedback',[]) or []:
        if not isinstance(s,dict):rows.append(field(s));continue
        rows+=['학생 원문',field(s.get('quote')),'문제 진단 / WHY (모델이 설명한 범위)',field(s.get('diagnosis')),
               '구체적 수정 방향',field(s.get('direction'))]
        if s.get('example') is not None:rows+=['선택적 예시',field(s['example'])]
        rows+=['연결/인용 검증용 정보',field({k:s.get(k) for k in ('observation_key','linked_issue_key','start','end')})]
    rows+=['### 다시 쓸 때 확인',field(out.get('checklist')),'### 이전 과제 검토',field(out.get('previous_improvement_reviews'))]
    return rows


def build(root=v.ROOT):
    rows=['# L2-C2 / L2-C2A 비공개 Owner 검토',
          'HUMAN_QUALITY_REVIEW=PENDING_OWNER_REVIEW · PRIMARY_MODEL_SELECTED=NO',
          '구조 통과는 교육적 품질 통과가 아닙니다. 원문/응답은 private artifact이며 공유·Git 게시 대상이 아닙니다.']
    for slot,case in v.SLOTS.items():
        prep=root/'prepared'/slot;target=root/'results'/slot
        rows+=['## '+('숙명여대 2025 모의 인문 Q1-1' if case=='sookmyung' else '한양대 2024 인문 오후2')]
        if not (target/'terminal.json').is_file():rows+=['실행 결과 없음. 추가 호출하지 않았습니다.'];continue
        terminal=v.strict_json(v.read_private(target/'terminal.json'))
        value=v.strict_json(v.read_private(prep/'input.json'))
        claim=v.strict_json(v.read_private(prep/'claim.json'))
        payload_raw=v.read_private(prep/'payload.json',32*1024*1024)
        # Frozen request images can exceed the response parser's 256 KiB cap.
        # Verify the exact request bytes before reading this operator-built JSON.
        # Provider responses still use the unchanged strict Contract parser.
        v.require(v.sha256(payload_raw).hexdigest()==terminal['binding']['payload_hash'],'REVIEW_INPUT_DRIFT')
        payload=json.loads(payload_raw)
        v.require(v.digest(claim)==terminal['binding']['claim_hash'] and v.digest(payload)==terminal['binding']['payload_hash'],'REVIEW_INPUT_DRIFT')
        v.require(v.encoded(value).decode()==payload['input'][0]['content'][0]['text'],'REVIEW_INPUT_DRIFT')
        rows+=['### 문항 / 평가 맥락',field(value['question']),field(value['criteria']),
               '공식 evidence와 학생 제출은 분리되었습니다. 예시답안은 blind 입력에서 제외되었습니다.',
               '### 학생 원문',field(value['answer']),'### Structural validation / telemetry',field(terminal)]
        raw_path=target/'raw-response.bin'
        if raw_path.exists():
            raw=v.read_private(raw_path);v.require(v.sha256(raw).hexdigest()==terminal['raw_hash'],'RAW_DRIFT')
        else:rows+=['Raw withheld/unknown: terminal reason 확인.'];continue
        if terminal['parser']=='PASS':
            raw_output=v.read_private(target/'normalized.json')
            v.require(v.sha256(raw_output).hexdigest()==terminal['normalized_hash'],'NORMALIZED_DRIFT')
            out=v.parse_provider(raw_output.decode(),claim)
        else:
            rows+=['**구조 검증 실패 — 아래는 미승인 raw 내용의 읽기 전용 표시이며 normalized 결과가 아닙니다. 수정/재연결하지 않았습니다.**']
            try:
                native=v.strict_json(raw)
                parts=[p['text'] for x in native.get('output',[]) for p in x.get('content',[]) if p.get('type')=='output_text']
                out=v.strict_json(parts[0]) if len(parts)==1 else dict(raw_output_available=False)
            except (ValueError,KeyError,TypeError,AttributeError):out=dict(raw_output_available=False)
        rows+=evaluation_sections(out)
        rows+=['### Owner 검토 — 잘한 부분']+['- [ ] '+x for x in POSITIVE_CHECKS]
        rows+=['### Owner 검토 — 고칠 부분']+['- [ ] '+x for x in CORRECTIVE_CHECKS]
        rows+=['### Owner 검토 — 필요한 논리 관계 (모든 관계를 강제하지 않음)']+['- [ ] '+x for x in LOGIC_CHECKS]
        rows+=['### 추가 품질 확인','- [ ] 공식 기준 정확성 / 중요 문제 누락 / false criticism',
               '- [ ] CORE 우선순위 / 선택적 문장 피드백 / 과도한 피드백 통제',
               '- [ ] 학생 입장 보존 / 예시 모방 금지 / 허구 요구 없음 / 한국어 명료성']
    destination=root/'owner-review.md';v.freeze(destination,'\n\n'.join(rows).encode());return destination
