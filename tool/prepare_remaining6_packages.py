"""Reproduce private KAU2 source-reading guidance from existing technical packages; no DB/Provider calls."""
from pathlib import Path
import json,shutil,hashlib
A=Path(__file__).resolve().parents[1];O=A/'supabase/candidates/remaining6_20261113';O.mkdir(exist_ok=True);P=A/'.local/remaining6-20261113';P.mkdir(exist_ok=True)
notes={'74e16370-a1be-57f9-b6c7-b2e035bfbb06':'[서비스 근거 판독 지침; 대학의 정정 공지나 신규 배점이 아님] 공식 p5 로그 합은 log(1-1/k²)로 일치하며 p6 최종값2025/4048을 사용한다. p6 근의 합 중간식의 부호 표기는 독립 평가기준으로 사용하지 않는다. 공식 문제의 이차방정식과 공식 풀이의 (alpha+beta)^2-4alpha beta 관계 및 최종 구간을 근거로 판단한다. 공식 배점은 p4 표를 그대로 따른다.', '48512d94-959c-5a94-b985-7e1bd005c6b7':'[서비스 근거 판독 지침; 대학의 정정 공지나 신규 배점이 아님] 공식 p18 주풀이의 이차식은 4m²+17m+15=0이고 제시근/최종 -5/4와 일치한다. 기존 -17m 기록은 원문 판독 오류로 폐기한다. p16~18 주풀이와 p14 채점표를 기준으로 사용하고, p17~18 다른 풀이 예시의 변수치환·분모 표기 줄은 필수 정답 기준으로 사용하지 않는다. 주풀이의 공식 결과와 배점을 변경하지 않는다.'}
for q,note in notes.items():
 src=A/'.local/natural-connection-20261111/kau';p=json.loads((src/(q+'.package.private.json')).read_text());p['publication_allowed']=True;p['reaudit_service_guidance']=note
 for row in p['existing_schema_rows']['math_scoring_criteria']:row['description']=note+'\n\n[공식 평가 설명 원문 추출; 수식은 원본 이미지와 함께 판독]\n'+row['description']
 for row in p['existing_schema_rows']['math_canonical_solutions']:row['body']=note+'\n\n[공식 예시풀이 원문 추출]\n'+row['body']
 (P/(q+'.package.private.json')).write_text(json.dumps(p,ensure_ascii=False,indent=2));shutil.copy(src/(q+'.worker.private.json'),P/(q+'.worker.private.json'))
