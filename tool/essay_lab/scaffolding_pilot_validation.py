"""Deterministic checks only: quote presence does not establish educational merit."""
import hashlib

def inspect_output(value,text,criterion_ids,refs=('Q','P','E1','E2')):
 errors=[]
 def check(flag,code):
  if not flag:errors.append(code)
 check(value.get('contract_version')=='1.3','contract_version')
 check(value.get('attempt_id')=='blind-attempt-a','attempt_identity')
 check(value.get('answer_hash')==hashlib.sha256(text.encode()).hexdigest(),'answer_hash')
 check(value.get('previous_improvement_reviews')==[],'no_invented_history')
 dimensions=value.get('dimensions',[]);items=value.get('improvements',[]);core=value.get('core_improvement_keys',[]);ss=value.get('sentence_feedback',[])
 check(len(dimensions)==len(criterion_ids) and {x.get('criterion_id') for x in dimensions}==set(criterion_ids),'complete_dimensions')
 for i,d in enumerate(dimensions):
  check(type(d.get('level')) is int and 1<=d['level']<=5,'dimension_level_'+str(i))
  check(bool(d.get('explanation','').strip()),'dimension_explanation_'+str(i))
  check(bool(d.get('evidence_ids')) and set(d['evidence_ids'])<=set(refs),'dimension_evidence_'+str(i))
 roots=[x.get('issue_key') for x in items]
 check(len(roots)==len(set(roots)),'duplicate_root_keys')
 check(len(core)<=3 and len(core)==len(set(core)) and set(core)<=set(roots),'core_limit_subset')
 check(len(ss)<=5,'sentence_limit')
 spans=[];ids=[];quotes=[]
 for i,s in enumerate(ss):
  start=s.get('start');end=s.get('end');q=s.get('quote');valid=type(start) is int and type(end) is int and 0<=start<end<=len(text) and isinstance(q,str) and q==text[start:end]
  quotes.append(valid);check(valid,'exact_quote_'+str(i));spans.append((start,end));ids.append(s.get('observation_key'))
  check(s.get('linked_issue_key') in roots,'linked_root_'+str(i))
  check(s.get('category') in ['grammar','expression','structure','logic'],'category_'+str(i))
  check(s.get('priority') in ['contradiction','unclear_meaning','grammar_agreement','wording'],'priority_'+str(i))
  for k in ['diagnosis','direction']:check(isinstance(s.get(k),str) and bool(s[k].strip()),k+'_'+str(i))
  check('example' not in s or isinstance(s['example'],str) and bool(s['example'].strip()),'optional_example_'+str(i))
  check('[판독 어려움]' not in (q or ''),'uncertain_span_'+str(i))
 check(len(spans)==len(set(spans)),'duplicate_spans');check(len(ids)==len(set(ids)),'duplicate_observation_keys')
 for i,x in enumerate(items):
  check(x.get('status')=='open' and x.get('previous_progress_id') is None,'new_root_state_'+str(i))
  if x.get('claim_scope')=='official_criterion':check(bool(x.get('evidence_ids')) and set(x['evidence_ids'])<=set(refs),'official_provenance_'+str(i))
  elif x.get('claim_scope')=='local_sentence':check(x.get('evidence_ids')==[] and any(s.get('linked_issue_key')==x['issue_key'] for s in ss),'local_provenance_'+str(i))
  else:check(False,'claim_scope_'+str(i))
 return {'structural_validation':'PASS' if not errors else 'FAIL','errors':errors,'quote_accuracy':'PASS' if all(quotes) else 'FAIL','quote_checks':quotes,'core_focus_count':len(core),'sentence_feedback_count':len(ss),'dimension_count':len(dimensions),'improvement_root_count':len(items),'semantic_review_required':True}


def rpc_payload_gap(value):
 """Read-only transport check, not a substitute for SQL runtime validation."""
 allowed={'contract_version','summary','strengths','checklist','dimensions','improvements',
          'attempt_id','answer_hash','core_improvement_keys','previous_improvement_reviews',
          'sentence_feedback','local_reviews'}
 return {'extra_provider_keys':sorted(set(value)-allowed),
         'pilot_alias_mapping_required':value.get('attempt_id')=='blind-attempt-a',
         'rpc_execution':'NOT_RUN'}
