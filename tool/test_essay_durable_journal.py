import tempfile,unittest,os,concurrent.futures,multiprocessing
from pathlib import Path
from tool.essay_lab.durable_journal import DurableJournal
from tool.essay_lab.live_worker import Invalid

def compete(root):
    j=DurableJournal(root)
    with j.lock('run'):return j.begin('run')

class DurableJournalTests(unittest.TestCase):
    def test_cross_process_claim_once_and_restart_pending_not_retried(self):
        with tempfile.TemporaryDirectory() as root:
            with concurrent.futures.ProcessPoolExecutor(4,mp_context=multiprocessing.get_context('spawn')) as pool:
                result=list(pool.map(compete,[root]*8))
            self.assertEqual(sum(result),1)
            j=DurableJournal(root)
            with j.lock('run'):
                self.assertIsNone(j.read('run'));self.assertFalse(j.begin('run'))
    def test_checkpoint_restart_immutable(self):
        with tempfile.TemporaryDirectory() as root:
            j=DurableJournal(root)
            with j.lock('run'):
                self.assertTrue(j.begin('run'));j.write('run',{'answer':'private'})
            j=DurableJournal(root)
            with j.lock('run'):
                self.assertEqual(j.read('run'),{'answer':'private'})
                j.write('run',{'answer':'private'})
                with self.assertRaises(Invalid):j.write('run',{'answer':'changed'})
            self.assertEqual(Path(root,'run.json').stat().st_mode&0o077,0)
    def test_lock_path_symlink_and_corrupt_fail_closed(self):
        with tempfile.TemporaryDirectory() as root:
            j=DurableJournal(root)
            with self.assertRaises(Invalid):j.begin('run')
            with self.assertRaises(Invalid):
                with j.lock('../outside'):pass
            Path(root,'bad.json').write_text('not json')
            with j.lock('bad'):
                with self.assertRaises(ValueError):j.begin('bad')
            Path(root,'link.lock').symlink_to(Path(root,'bad.json'))
            with self.assertRaises(OSError):
                with j.lock('link'):pass
if __name__=='__main__':unittest.main()
