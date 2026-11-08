from copy import deepcopy
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).parent))
from ingestion.daily_sync import observe,reconcile,ReviewRequired
NOW='2026-11-08T10:00:00+00:00'
SINCE='2026-10-08T00:00:00+00:00'
def html(post_id='99001',names=('생활과윤리 문제.pdf','생활과윤리 정답,해설.pdf'),title='학습 자료'):
    anchors=''.join(f'<a href="https://blog.kakaocdn.net/dna/file{i}/stable/x/a.pdf?signature=fake&amp;expires=9"><span class="name">{n}</span></a>' for i,n in enumerate(names))
    return f'<html><head><link rel="canonical" href="https://legendstudy.com/{post_id}"><meta property="og:title" content="{title}"><meta property="article:published_time" content="2026-11-01T00:00:00+00:00"><meta property="article:modified_time" content="2026-11-07T00:00:00+00:00"></head><body><a href="/category/수업 자료실">자료</a><div class="contents_style">{anchors}</div></body></html>'
def state(post):
    return {'source_posts':[dict(post.source_post)],'content_items':[dict(post.content_item,is_active=True)],'exams':[],'exam_subjects':[], 'resources':[dict(r,is_active=True) for r in post.resources]}
class DailySyncTests(unittest.TestCase):
    def setUp(self):
        self.post=observe('99001',html(),NOW);self.current=state(self.post)
    def changes(self,p=None,**kwargs):
        return reconcile(p or self.post,self.current,new_since=SINCE,**kwargs)
    def test_new_active_deterministic_identity(self):
        c=reconcile(self.post,None,new_since=SINCE)
        self.assertTrue(all(x.after['is_active'] for x in c if 'is_active' in x.after))
        self.assertEqual(c,reconcile(self.post,None,new_since=SINCE))
    def test_noop(self): self.assertEqual([],self.changes())
    def test_signature_rotation(self):
        p=observe('99001',html().replace('signature=fake','signature=rotated'),NOW)
        self.assertEqual([],self.changes(p))
    def test_no_historical_backfill(self):
        with self.assertRaisesRegex(ReviewRequired,'historical'):
            reconcile(self.post,None,new_since=NOW)
    def test_incomplete_html(self):
        with self.assertRaisesRegex(ReviewRequired,'incomplete_html'):
            observe('99001',html().replace('</html>',''),NOW)
    def test_wrong_identity(self):
        with self.assertRaisesRegex(ReviewRequired,'identity'): observe('99002',html(),NOW)
    def test_missing_metadata(self):
        with self.assertRaises(ReviewRequired): observe('99001',html().replace('article:published_time','unknown'),NOW)
    def test_future_clock(self):
        with self.assertRaises(ReviewRequired): observe('99001',html().replace('2026-11-07','2028-01-01'),NOW)
    def test_removal_confirmation(self):
        p=observe('99001',html(names=('생활과윤리 문제.pdf',)),NOW)
        with self.assertRaisesRegex(ReviewRequired,'second_observation'): self.changes(p)
        removed=[x for x in self.changes(p,confirmed_hash=p.source_post['content_hash']) if x.after=={'is_active':False}]
        self.assertEqual(len(removed),1);self.assertEqual(removed[0].key,self.post.resources[1]['id'])
    def test_changed_confirmation_aborts(self):
        p=observe('99001',html(names=('생활과윤리 문제.pdf',)),NOW)
        with self.assertRaises(ReviewRequired): self.changes(p,confirmed_hash='wrong')
    def test_added_answer_preserves_parent(self):
        p=observe('99001',html(names=('생활과윤리 문제.pdf','생활과윤리 정답,해설.pdf','생활과윤리 해설.pdf')),NOW)
        new=[x for x in self.changes(p) if x.before is None]
        self.assertEqual(len(new),1);self.assertEqual(new[0].after['content_item_id'],self.post.content_item['id'])
    def test_manual_inactive_preserved(self):
        self.current['resources'][0]['is_active']=False;self.assertEqual([],self.changes())
    def test_sync_removed_reappears(self):
        self.current['resources'][0]['is_active']=False
        self.assertEqual(self.changes(managed_removed={self.post.resources[0]['id']})[0].after,{'is_active':True})
    def test_parent_hold(self):
        self.current['content_items'][0]['is_active']=False
        with self.assertRaisesRegex(ReviewRequired,'publication_hold'): self.changes()
    def test_title_preserves_slug(self):
        changes=self.changes(observe('99001',html(title='새 제목'),NOW))
        self.assertTrue(any(c.table=='content_items' and c.after.get('title')=='새 제목' for c in changes))
        self.assertFalse(any('slug' in c.after or 'feed_updated_at' in c.after for c in changes))
    def test_live_non_deterministic_ids_preserved(self):
        self.current['content_items'][0]['id']='10000000-0000-0000-0000-000000000000'
        for r in self.current['resources']: r['content_item_id']=self.current['content_items'][0]['id']
        self.assertEqual([],self.changes())
    def test_unknown_provider(self):
        with self.assertRaisesRegex(ReviewRequired,'unsupported_attachment'):
            observe('99001',html().replace('https://blog.kakaocdn.net/dna/file0/stable/x/a.pdf','https://unknown.example/a.pdf'),NOW)
    def test_exam_contract_immutable(self):
        p=deepcopy(self.post);p.exam={'year':2026,'academic_year':2027,'exam_month':6,'grade_level':3,'exam_type':'evaluation_mock'}
        p.content_item['content_type']='exam';self.current['content_items'][0]['content_type']='exam';self.current['exams']=[dict(p.exam,year=2025)]
        with self.assertRaisesRegex(ReviewRequired,'exam_metadata_changed'): self.changes(p)
    def test_source_clock_regression(self):
        self.current['source_posts'][0]['source_updated_at']='2026-11-08T00:00:00+00:00'
        with self.assertRaisesRegex(ReviewRequired,'clock_regression'): self.changes()
    def test_incomplete_fileblock(self):
        body=html().replace('<div class="contents_style">','<div class="contents_style"><figure class="fileblock">')
        with self.assertRaisesRegex(ReviewRequired,'incomplete_fileblock'): observe('99001',body,NOW)
    def test_new_exam_requires_full_set(self):
        p=deepcopy(self.post);p.exam={'year':2026};p.content_item['content_type']='exam'
        with self.assertRaisesRegex(ReviewRequired,'full_set'): reconcile(p,None,new_since=SINCE)
if __name__=='__main__': unittest.main()
