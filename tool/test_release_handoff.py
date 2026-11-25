import copy
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from check_release_handoff import validate

class HandoffTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.w=self.root/'wiki';self.w.mkdir()
        self.s={'wiki_branch':'main','last_verified':'2026-11-25','release_record':'release.md','candidate':{'version':'1.0.7','build':89,'source':'b'*40,'branch':'candidate','state':'BUILT','release_state':'UNRELEASED','evidence':'e.md'},'unreleased':['D-Day'],'web':{'evidence':'e.md'},'worker':{'evidence':'e.md'}}
        for k in ('db','payment','finance','development','work','blocked','approval','next'):self.s[k]='explicit'
        self.r={'version':'1.0.6','build':88,'source':'a'*40,'branch':'release','last_verified':'2026-11-25','evidence':'e.md','platforms':[{'platform':p,'version':'1.0.6','build':88,'source':'a'*40,'state':'RELEASED','released_on':'2026-11-18'} for p in ('ios','android')]}
        (self.w/'index.md').write_text('[Release](release.md)');(self.w/'e.md').write_text('evidence')
    def write(self):
        (self.w/'current-status.md').write_text('[Release](release.md)\n<!-- handoff-status -->\n```json\n'+json.dumps(self.s)+'\n```')
        (self.w/'release.md').write_text('<!-- release-record -->\n```json\n'+json.dumps(self.r)+'\n```')
    def fakegit(self,root,*args):
        if args[0]=='show':return 'version: '+('1.0.6+88' if args[1].startswith('a') else '1.0.7+89')
        if args[0]=='ls-remote':return 'c'*40+'\trefs/heads/main'
        if args[0]=='rev-parse':return 'c'*40
        return ''
    def check(self,official=False,fn=None):
        self.write()
        with patch('check_release_handoff.git',side_effect=fn or self.fakegit):return validate(self.root,official)
    def test_known_stale_index(self):
        (self.w/'index.md').write_text('[Release](release.md) APP 릴리스 HOLD 유지.')
        self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_valid(self):self.assertFalse(any(self.check(True).values()))
    def test_missing_required(self):del self.s['next'];self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_conflicting_build(self):self.r['platforms'][1]['build']=87;self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_duplicate_platform(self):self.r['platforms'][1]['platform']='ios';self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_missing_release_evidence(self):self.r['evidence']='missing.md';self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_unconfirmed_not_released(self):self.r['platforms'][0]['state']='BUILT';self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_candidate_not_branch(self):self.s['candidate']['branch']='';self.assertTrue(self.check()['RELEASE_CONSISTENCY'])
    def test_wrong_pubspec(self):self.r['version']='2.0.0';self.assertTrue(self.check()['GIT_BASELINE'])
    def test_missing_commit(self):
        def bad(root,*a):
            if a[0]=='cat-file':raise subprocess.CalledProcessError(1,a)
            return self.fakegit(root,*a)
        self.assertTrue(self.check(fn=bad)['GIT_BASELINE'])
    def test_non_descendant(self):
        def bad(root,*a):
            if a[0]=='merge-base':raise subprocess.CalledProcessError(1,a)
            return self.fakegit(root,*a)
        self.assertTrue(self.check(fn=bad)['GIT_BASELINE'])
    def test_unpublished(self):
        def bad(root,*a):return 'diff' if a[0]=='diff' else self.fakegit(root,*a)
        self.assertTrue(self.check(True,bad)['OFFICIAL_WIKI'])
    def test_stale_remote(self):
        def bad(root,*a):return 'd'*40 if a[0]=='rev-parse' else self.fakegit(root,*a)
        self.assertTrue(self.check(True,bad)['OFFICIAL_WIKI'])
    def test_duplicate_record(self):
        self.write();p=self.w/'current-status.md';p.write_text(p.read_text()*2)
        self.assertTrue(validate(self.root)['RELEASE_CONSISTENCY'])

if __name__=='__main__':unittest.main()
