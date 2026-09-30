"""L2-C2A repository-owned protection in each available related checkout."""
from pathlib import Path
import subprocess
import unittest

REPO=Path(__file__).resolve().parents[1]

def related():
    roots={REPO}
    original=Path.home()/'development/legendstudy-app'
    if (original/'.git').exists():roots.add(original)
    for repo in tuple(roots):
        text=subprocess.check_output(['git','worktree','list','--porcelain'],cwd=repo).decode()
        roots.update(Path(line.removeprefix('worktree ')) for line in text.splitlines() if line.startswith('worktree '))
    return sorted(roots)

class PrivateExclusion(unittest.TestCase):
    def test_repository_rule_without_global_ignore(self):
        for repo in related():
            for path in ('.local/essay-bakeoff-l2b/safe-test-file','.local/essay-evidence-vnext-l2c1/safe-test-file','.local/essay-vnext-l2c2/safe-test-file'):
                with self.subTest(repo=str(repo),path=path):
                    result=subprocess.run(['git','-c','core.excludesFile=/dev/null','check-ignore','-v',path],cwd=repo,capture_output=True,text=True)
                    self.assertEqual(result.returncode,0);self.assertTrue(result.stdout.startswith('.gitignore:'))
    def test_no_tracked_private_files(self):
        for repo in related():
            with self.subTest(repo=str(repo)):
                self.assertEqual(subprocess.check_output(['git','ls-files','--','.local/**'],cwd=repo),b'')
    def test_rule_is_committed(self):
        for repo in related():
            with self.subTest(repo=str(repo)):
                content=subprocess.check_output(['git','show','HEAD:.gitignore'],cwd=repo).decode()
                self.assertIn('/.local/',content.splitlines())

if __name__=='__main__':unittest.main()
