"""Expand compact evidence inheritance for the existing package validator."""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def papers():
 return json.loads((ROOT/'data/mock_expansion/task03a/verified_papers.json').read_text())['papers']
def expanded(paper):
 p=copy.deepcopy(paper)
 for q in p['questions']:
  q.setdefault('answer_evidence',p['answer_evidence'])
  q.setdefault('points_evidence',p['points_evidence'])
 return p
def engine_questions(paper):
 return [dict(question_number=q['number'],question_id=q['question_id'],answer_type=q['answer_type'],accepted_answers=q['accepted_answers'],all_credit=q['all_credit'],points=q['points']) for q in paper['questions']]
def vectors(paper):
 qs=paper['questions']
 perfect=[None if q['all_credit'] else q['accepted_answers'][0] for q in qs]
 wrong=[next(n for n in range(1,6) if n not in q['accepted_answers']) if q['answer_type']=='multiple_choice' else next(n for n in range(1000) if n not in q['accepted_answers']) for q in qs]
 mandatory=sum(q['points'] for q in qs if q['all_credit'])
 return [('perfect',perfect,paper['max_score']),('wrong',wrong,mandatory),('blank',[None]*len(qs),mandatory)]
