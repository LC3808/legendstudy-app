import unittest
from copy import deepcopy
from essay_lab.live_worker import Invalid
from essay_lab.university_profile import profile_digest, select, resolve_rules, compose_material, bind_material
import test_material_runtime as legacy

class ProfileTests(unittest.TestCase):
 def setUp(self):
  base=legacy.MaterialRuntimeTests();base.setUp();self.package=base.package;self.registry={'exams':[base.exam]};self.exam=base.exam
  self.profile=dict(schema='university-evaluation-profile-v1',profile_id='uep/u/human',version=1,university_id='u',engine_route='humanities',review_status='REVIEWED',scopes=[dict(exam_id='e',year=2024,kind='admission',track='인문',question_ids=['q'])],rules=[],criteria_mappings=[])
  self.pin()
 def pin(self):self.profile['content_sha256']=profile_digest(self.profile)
 def test_legacy_host_cache_and_binding_unchanged(self):
  from essay_lab.material_runtime import reviewed_material_question
  args=dict(pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities')
  old,_=reviewed_material_question(self.package,self.registry,'q',**args)
  new,report=bind_material(self.package,self.registry,'q',[self.profile],**args)
  self.assertEqual(old.frozen_cache,new.frozen_cache);self.assertFalse(new.approved_processing)
  self.assertFalse(report['profile_resolution']['activation_granted'])
 def test_reproducible_no_mutation_sibling_preserved(self):
  self.package['questions'].append(dict(question_id='sibling',sentinel=True));before=deepcopy(self.package)
  first=compose_material(self.package,self.registry,'q',[self.profile]);self.assertEqual(first,compose_material(self.package,self.registry,'q',[self.profile]));self.assertEqual(before,self.package)
 def test_changed_profile_pin_rejected(self):
  self.profile['version']=2
  with self.assertRaisesRegex(Invalid,'PROFILE_PIN_DRIFT'):select([self.profile],self.exam,'q')
 def test_draft_year_and_track_rejected(self):
  for field,value in [('year',2025),('kind','mock'),('track','자연')]:
   p=deepcopy(self.profile);p['scopes'][0][field]=value;p['content_sha256']=profile_digest(p)
   with self.assertRaisesRegex(Invalid,'PROFILE_MISSING'):select([p],self.exam,'q')
  self.profile['review_status']='DRAFT';self.pin()
  with self.assertRaisesRegex(Invalid,'PROFILE_MISSING'):select([self.profile],self.exam,'q')
 def test_ambiguous_and_foreign_question_rejected(self):
  with self.assertRaisesRegex(Invalid,'PROFILE_AMBIGUOUS'):select([self.profile,self.profile],self.exam,'q')
  with self.assertRaisesRegex(Invalid,'QUESTION_NOT_IN_EXAM'):select([self.profile],self.exam,'other')
 def test_prior_revision_pin_not_latest(self):
  p2=deepcopy(self.profile);p2['version']=2;p2['content_sha256']=profile_digest(p2)
  chosen=select([self.profile,p2],self.exam,'q',pinned=('uep/u/human',1,self.profile['content_sha256']))
  self.assertEqual(chosen['version'],1)
 def test_official_precedence_unknown_and_same_level_conflict(self):
  def r(v):return dict(key='points',value=v,provenance='OFFICIAL',source_refs=['source'])
  rules,trace=resolve_rules([r(10)],[r(20)],[r(17)]);self.assertEqual(rules['points']['value'],17)
  rules,_=resolve_rules([r(10)],[],[r(None)]);self.assertEqual(rules['points']['value'],10)
  with self.assertRaisesRegex(Invalid,'PROFILE_RULE_CONFLICT'):resolve_rules([r(10),r(20)])
 def test_internal_axis_is_not_official(self):
  with self.assertRaisesRegex(Invalid,'OFFICIAL_RULE_REQUIRED'):resolve_rules([dict(key='score',value=10,provenance='INTERNAL_GUIDANCE')])
 def test_question_criteria_override_lower_group(self):
  self.profile['criteria_mappings']=[dict(role='criteria',verification='VERIFIED',sourceHash='b'*64,evidenceText='lower')];self.pin()
  out,manifest=compose_material(self.package,self.registry,'q',[self.profile]);self.assertEqual(out,self.package);self.assertEqual(manifest['criteria_source'],'question')
 def test_unreviewed_question_cannot_fall_back(self):
  self.package['questions'][0]['source_page_references'][3]['verification']='NEEDS_REVIEW'
  with self.assertRaisesRegex(Invalid,'QUESTION_CRITERIA_REVIEW_REQUIRED'):compose_material(self.package,self.registry,'q',[self.profile])

 def test_common_evidence_preserves_question_criteria_and_requires_review(self):
  self.profile['common_evidence']=[dict(scope='COMMON',verification='VERIFIED',provenance='OFFICIAL',
      evidenceText='논리적인 구성과 명확한 언어 사용',sourceHash='a'*64,startPage=1,endPage=1,question_ids=['q'])]
  self.pin();out,_=compose_material(self.package,self.registry,'q',[self.profile])
  old=self.package['questions'][0]['source_page_references'];new=out['questions'][0]['source_page_references']
  self.assertEqual([m for m in old if m['role']=='criteria'],[m for m in new if m['role']=='criteria'])
  self.assertEqual(new[-1]['role'],'scoring');self.assertIn('문항 기준을 우선',new[-1]['evidenceText'])
  with self.assertRaisesRegex(Invalid,'COMPILED_PACKAGE_REVIEW_REQUIRED'):
   bind_material(self.package,self.registry,'q',[self.profile],pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities')
  self.profile['common_evidence'][0]['question_ids']=['other'];self.pin()
  out,_=compose_material(self.package,self.registry,'q',[self.profile]);self.assertEqual(out,self.package)
  self.profile['common_evidence'][0]['question_ids']=[];self.pin()
  with self.assertRaisesRegex(Invalid,'COMMON_EVIDENCE_SCOPE'):compose_material(self.package,self.registry,'q',[self.profile])


 def test_math_profile_is_not_replaced_or_given_numeric_score(self):
  from essay_lab.university_profile import bind_math
  from essay_lab.live_worker import digest
  ctx=dict(profile=dict(id='mp',rubric_version='math-rubric-v1'),leaf=dict(id='leaf'),problem=dict(id='problem'),criteria=[dict(official_points=None)])
  self.profile['engine_route']='math';self.profile['math_binding']=dict(profile_id='mp',leaf_id='leaf',problem_id='problem',profile_sha256=digest(ctx['profile']));self.pin()
  result,manifest=bind_math(ctx,self.exam,'q',[self.profile]);self.assertEqual(ctx,result);self.assertFalse(manifest['activation_granted'])
  ctx['profile']['rubric_version']='other'
  with self.assertRaisesRegex(Invalid,'MATH_PROFILE_CONTENT_DRIFT'):bind_math(ctx,self.exam,'q',[self.profile])

 def test_existing_worker_loader_consumes_profile_without_activation(self):
  from essay_lab.material_runtime import load_reviewed_material
  out,report=load_reviewed_material(self.package,self.registry,pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities',university_profiles=[self.profile])
  self.assertEqual(list(out),['q']);self.assertIn('profile_resolution',report['questions'][0]);self.assertFalse(out['q'].approved_processing)
 def test_year_criteria_fallback_requires_new_package_review(self):
  self.package['questions'][0]['source_page_references']=[m for m in self.package['questions'][0]['source_page_references'] if m['role']!='criteria']
  mapping=dict(questionId='q',sourceHash='a'*64,role='criteria',startPage=1,endPage=1,evidenceText='year official criterion',verification='VERIFIED')
  self.profile['year_exceptions']=[dict(self.profile['scopes'][0],review_status='REVIEWED',criteria_mappings=[mapping])];self.pin()
  out,manifest=compose_material(self.package,self.registry,'q',[self.profile]);self.assertEqual(manifest['criteria_source'],'year')
  with self.assertRaisesRegex(Invalid,'COMPILED_PACKAGE_REVIEW_REQUIRED'):bind_material(self.package,self.registry,'q',[self.profile],pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities')
  self.profile['year_exceptions']*=2;self.pin()
  with self.assertRaisesRegex(Invalid,'YEAR_EXCEPTION_AMBIGUOUS'):compose_material(self.package,self.registry,'q',[self.profile])

if __name__=='__main__':unittest.main()
