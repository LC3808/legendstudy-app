import unittest,datetime as dt,hashlib,importlib.util
from pathlib import Path
s=importlib.util.spec_from_file_location('check',Path(__file__).with_name('check.py'));m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class ComparisonTests(unittest.TestCase):
 def setUp(self):
  self.c={'salt':'a'*64,'created_at':(m.now()-dt.timedelta(seconds=1)).isoformat(),'expires':(m.now()+dt.timedelta(hours=1)).isoformat()}
  self.a={'schema':'legendstudy-identity-v1','surface':'app','project':m.PROJECT,'challenge':hashlib.sha256(self.c['salt'].encode()).hexdigest(),'observed_at':m.now().isoformat(),'event':'signedIn','status':'verified','digest':'a'*64}
  self.b=dict(self.a,surface='lab',event='operator_snapshot')
 def test_equal_requires_owner_attestation(self):
  self.assertEqual(m.compare(self.c,self.a,self.b,False)['RESULT'],'OWNER_SAME_ACCOUNT_CONFIRMATION_REQUIRED')
  self.assertEqual(m.compare(self.c,self.a,self.b,True)['RESULT'],'PASS')
 def test_conflict_stops(self):self.assertEqual(m.compare(self.c,self.a,dict(self.b,digest='b'*64),True)['RESULT'],'STOP_IDENTITY_CONFLICT')
 def test_logout_invalidates(self):
  b=dict(self.b,status='signed_out');b.pop('digest');self.assertEqual(m.compare(self.c,self.a,b,True)['RESULT'],'LOGIN_REQUIRED')
 def test_private_fields_rejected(self):
  with self.assertRaises(ValueError):m.validate(dict(self.a,access_token='SENTINEL'),self.c,'app')
 def test_wrong_challenge_rejected(self):
  with self.assertRaises(ValueError):m.validate(dict(self.a,challenge='b'*64),self.c,'app')
 def test_old_observation_rejected(self):
  self.c['created_at']=(m.now()-dt.timedelta(hours=1)).isoformat()
  with self.assertRaises(ValueError):m.validate(dict(self.a,observed_at=(m.now()-dt.timedelta(minutes=6)).isoformat()),self.c,'app')
if __name__=='__main__':unittest.main()
