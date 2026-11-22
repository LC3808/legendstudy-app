"""Offline boundary regression: exact source equality and full review never bypassed."""
import copy,json,unittest
from tool.test_essay_live_worker import fixture,receipt
from tool.essay_lab.live_worker import (align_exact_quote_offsets,quote_alignment_receipt,parse_provider,validate_output,Invalid,sha256,Worker,ProviderResult,SignedReview,ProviderFailure)

class QuoteAlignmentTests(unittest.TestCase):
 def test_unique_exact_offset_only(self):
  c,_,o=fixture();original=copy.deepcopy(o);o['sentence_feedback'][0].update(start=2,end=99)
  raw=json.dumps(o);normalized=parse_provider(raw,c)
  self.assertEqual(normalized,original);self.assertEqual(o['sentence_feedback'][0]['start'],2)
  audit=quote_alignment_receipt(raw,normalized);self.assertEqual(len(audit['adjustments']),1)
  self.assertNotIn('quote',audit);self.assertNotIn(c['answer'],json.dumps(audit));validate_output(normalized,c)
 def test_alignment_audit_has_separate_checkpoint_namespace(self):
  from tool.essay_lab.cloudflare_runtime import receipt_checkpoint_key
  c,_,o=fixture();o['sentence_feedback'][0]['end']=99
  raw=json.dumps(o);audit=quote_alignment_receipt(raw,parse_provider(raw,c))
  key=receipt_checkpoint_key(audit)
  self.assertTrue(key.startswith('quote-alignment-'));self.assertNotIn('receipt-',key)
  self.assertNotIn('input_tokens',audit)
 def test_existing_validator_stays_strict(self):
  c,_,o=fixture();o['sentence_feedback'][0]['end']=99
  with self.assertRaisesRegex(Invalid,'EXACT_QUOTE'):validate_output(o,c)
 def test_no_fuzzy_unicode_or_whitespace_repair(self):
  c,_,o=fixture()
  for quote in ['없는 문장','🙂 가가','🙂  가가','']:
   bad=copy.deepcopy(o);bad['sentence_feedback'][0].update(quote=quote,start=0,end=99)
   with self.assertRaises(Invalid):parse_provider(json.dumps(bad),c)
 def test_duplicate_occurrences_are_ambiguous(self):
  c,_,o=fixture();c['answer']*=2;c['input']['answer_hash']=o['answer_hash']=sha256(c['answer'].encode()).hexdigest();o['sentence_feedback'][0]['start']=1
  with self.assertRaisesRegex(Invalid,'EXACT_QUOTE'):parse_provider(json.dumps(o),c)
 def test_overlapping_occurrences_are_ambiguous(self):
  c,_,o=fixture();c['answer']='aaaa';c['input']['answer_hash']=o['answer_hash']=sha256(b'aaaa').hexdigest();o['sentence_feedback'][0].update(quote='aaa',start=9,end=12)
  with self.assertRaisesRegex(Invalid,'EXACT_QUOTE'):parse_provider(json.dumps(o),c)
 def test_valid_second_occurrence_is_not_rewritten(self):
  c,_,o=fixture();n=len(c['answer']);c['answer']*=2;c['input']['answer_hash']=o['answer_hash']=sha256(c['answer'].encode()).hexdigest();o['sentence_feedback'][0].update(start=n,end=n+5)
  self.assertEqual(parse_provider(json.dumps(o),c),o);self.assertIsNone(quote_alignment_receipt(json.dumps(o),o))
 def test_boolean_and_foreign_hash_rejected(self):
  c,_,o=fixture()
  for key,value in [('start',True),('end','5')]:
   bad=copy.deepcopy(o);bad['sentence_feedback'][0][key]=value
   with self.assertRaises(Invalid):parse_provider(json.dumps(bad),c)
  o['answer_hash']='0'*64;o['sentence_feedback'][0]['end']=99
  self.assertEqual(align_exact_quote_offsets(o,c),o)
  with self.assertRaisesRegex(Invalid,'SOURCE_BINDING'):parse_provider(json.dumps(o),c)
 def test_all_other_constraints_still_run(self):
  c,_,o=fixture();o['sentence_feedback'][0]['end']=99
  for mutate in [lambda x:x['dimensions'][0].update(level=7),lambda x:x['improvements'][0].update(evidence_ids=['foreign']),lambda x:x.update(unknown=True),lambda x:x['sentence_feedback'].append(dict(x['sentence_feedback'][0],observation_key='other'))]:
   bad=copy.deepcopy(o);mutate(bad)
   with self.assertRaises(Invalid):parse_provider(json.dumps(bad),c)
 def test_full_independent_review_and_one_provider_call(self):
  for accepted in [True,False]:
   c,cache,o=fixture();o['sentence_feedback'][0]['end']=99;calls=[];audits=[];saved=[];reviews=[];provider_calls=[]
   class Provider:
    synthetic_only=True
    def evaluate(self,value):provider_calls.append(1);return ProviderResult(json.dumps(o),'synthetic','test',10,20,1)
   def rpc(name,args):calls.append(name);return c if name=='essay_claim' else ('completed' if name=='essay_finalize_success' else 'failed')
   def review(e,v,out):
    validate_output(out,c);reviews.append(out)
    if not accepted:raise ProviderFailure('INDEPENDENT_REVIEW_NOT_ACCEPTED')
    return receipt(e,v,out)
   worker=Worker(rpc,Provider(),cache,SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),review,audits.append,saved.append,isolated_fixture=True)
   self.assertEqual(worker.execute('e'),'completed' if accepted else 'failed');self.assertEqual(len(provider_calls),1);self.assertEqual(len(reviews),1);self.assertEqual(len(saved),int(accepted))
   self.assertEqual(len([a for a in audits if a.get('component')=='quote_offset_alignment']),1)

if __name__=='__main__':unittest.main()
