from datetime import datetime,timezone,timedelta
import unittest
from ingestion.schedule import next_due
from ingestion.daily_sync import observe,Change
from run_daily_material_sync import change_metrics
from test_daily_material_sync import html,NOW
class ScheduleTests(unittest.TestCase):
 def test_72_hours_across_month(self):
  t=datetime(2026,11,30,19,tzinfo=timezone.utc)
  self.assertEqual(next_due(t)-t,timedelta(hours=72))
  self.assertEqual(next_due(t).day,3)
 def test_delayed_completion_moves_next_due(self):
  t=datetime(2026,11,9,0,23,tzinfo=timezone.utc)
  self.assertEqual(next_due(t).hour,0);self.assertEqual(next_due(t).minute,23)
 def test_body_edit_without_timestamp_change(self):
  a=observe('99001',html().replace('</div>','설명A</div>'),NOW)
  b=observe('99001',html().replace('</div>','설명B</div>'),NOW)
  self.assertNotEqual(a.source_post['content_hash'],b.source_post['content_hash'])
  self.assertEqual(a.content_item['id'],b.content_item['id'])
 def test_observation_is_not_modified_post(self):
  c=Change('source_posts','id',{'last_crawled_at':NOW},{'last_crawled_at':NOW})
  self.assertEqual(change_metrics([c])['modified_posts'],0)
 def test_metrics_distinguish_add_replace_remove(self):
  rows=[Change('resources','a',None,{}),Change('resources','b',{}, {'source_url':'https://example.com/a.pdf'}),Change('resources','c',{}, {'is_active':False})]
  c=change_metrics(rows)
  self.assertEqual([c[k] for k in ['added_attachments','replaced_attachments','removed_attachments','modified_posts']],[1,1,1,1])
