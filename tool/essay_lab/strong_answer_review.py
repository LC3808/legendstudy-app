"""Private Gate D report; faithful output, never automatic quality acceptance."""
import json
from . import strong_answer_calibration as c
from .vnext_owner_review import field, evaluation_sections, POSITIVE_CHECKS, CORRECTIVE_CHECKS, LOGIC_CHECKS
from .hanyang_recovery_review import finding_rows

CHECKS=['허위 결함을 만들어 내지 않는가?', '실제 결함이 없을 때 CORE=0을 허용하는가?',
        '장점을 실제 답안 행동으로 짚는가?', 'WHY와 공식 기준의 관계를 설명하는가?',
        '성공한 논증 구조를 다른 문제에 재사용하도록 지도하는가?',
        'minor polish를 CORE로 승격하지 않는가?', '예시답안을 정답 template로 취급하지 않는가?',
        '좋은 부분을 불필요하게 다시 쓰게 하지 않는가?']


def build(root=c.ROOT):
    prep=root/'prepared'/c.SLOT;target=root/'results'/c.SLOT
    result=c.old.strict_json(c.old.read_private(target/'terminal.json'))
    value=c.old.strict_json(c.old.read_private(prep/'input.json'))
    claim=c.old.strict_json(c.old.read_private(prep/'claim.json'))
    payload_raw=c.old.read_private(prep/'payload.json',32*1024*1024)
    c.old.require(c.old.sha256(payload_raw).hexdigest()==result['binding']['payload_hash'],'REVIEW_INPUT_DRIFT')
    c.old.require(c.old.digest(claim)==result['binding']['claim_hash'] and
        json.loads(payload_raw)['input'][0]['content'][0]['text']==c.old.encoded(value).decode(),'REVIEW_INPUT_DRIFT')
    rows=['# L2-C3 Gate D — 비공개 Owner 검토',
          'HUMAN_QUALITY_REVIEW=PENDING_OWNER_REVIEW · PRIMARY_MODEL_SELECTED=NO',
          '숙명 2025 모의 인문 Q1-1. 공식 예시에서 가져온 검증된 본문이지만 완벽한 답안이라고 가정하지 않습니다. 출처/품질 라벨은 provider에 전달하지 않았습니다.',
          'CORE=0을 강제하지 않습니다. 실제 공식 기준상 문제와 허위/취향 지적을 구분해 주세요.',
          '## 문항 / 대학 평가기준',field(value['question']),field(value['criteria']),
          '## 평가 대상 답안 원문',field(value['answer']),
          '## Owner 전용 출처',field(result['binding']['answer_provenance']),
          '## 구조 검증 / telemetry',field(result)]
    raw_path=target/'raw-response.bin'
    if raw_path.exists():
        c.old.require(c.old.sha256(c.old.read_private(raw_path)).hexdigest()==result['raw_hash'],'RAW_DRIFT')
    if result['parser']=='PASS':
        normalized=c.old.read_private(target/'normalized.json')
        c.old.require(c.old.sha256(normalized).hexdigest()==result['normalized_hash'],'NORMALIZED_DRIFT')
        output=c.old.parse_provider(normalized.decode(),claim)
        rows+=evaluation_sections(output)+finding_rows(output,value['evidence'])
    else:
        rows+=['## 정상화된 평가 없음','구조 실패/UNKNOWN을 복구하거나 품질 PASS로 취급하지 않습니다.']
    rows+=['## 대학 공식 근거 — provider에 실제 제공된 범위']
    for e in value['evidence']:
        rows += [field({k:e[k] for k in ('id','semantic_role','source_id','page','locator')}),field(e['text'])]
    for heading,checks in [('강한 답안 검토',CHECKS),('실제로 잘한 부분 → WHY → 기준 → 논리 구조 → 재사용 전략',POSITIVE_CHECKS),
                            ('지적 → 실제 중요도 → 공식 기준 → CORE 필요성 → 취향 여부',CORRECTIVE_CHECKS),('논리 연결',LOGIC_CHECKS)]:
        rows+=['## '+heading]+['- [ ] '+x for x in checks]
    rows+=['## Owner 판정','PASS / PARTIAL / FAIL / NOT_ASSESSABLE: 미기입',
           '이 결과는 모델 선정이나 Round2/Production 승인을 의미하지 않습니다.']
    path=root/'owner-review.md';c.old.freeze(path,'\n\n'.join(rows).encode());return path
