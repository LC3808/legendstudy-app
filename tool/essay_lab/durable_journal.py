"""Single-host durable private worker journal. No secrets or student data logging.
Use only on persistent local storage; not an ephemeral/serverless filesystem.
Caller holds lock across claim/provider/finalize. A pending marker never expires
into permission to call a provider again: ambiguous work requires reconciliation.
"""
from contextlib import contextmanager
from pathlib import Path
import fcntl,json,os,re,stat,tempfile
from .live_worker import require

class DurableJournal:
    ready=True
    def __init__(self,root):
        self.root=Path(root)
        self.root.mkdir(mode=0o700,parents=True,exist_ok=True)
        info=self.root.lstat()
        require(stat.S_ISDIR(info.st_mode) and not self.root.is_symlink() and
                info.st_uid==os.getuid() and info.st_mode&0o077==0,'PRIVATE_JOURNAL_REQUIRED')
        self._held=set()
    def _key(self,key):
        require(isinstance(key,str) and re.fullmatch(r'[a-zA-Z0-9_-]{1,100}',key),'INVALID_JOURNAL_ID')
        return key
    @contextmanager
    def lock(self,key):
        key=self._key(key);require(key not in self._held,'JOURNAL_LOCK_REENTRY')
        fd=os.open(self.root/(key+'.lock'),os.O_RDWR|os.O_CREAT|os.O_NOFOLLOW,0o600)
        try:
            fcntl.flock(fd,fcntl.LOCK_EX);self._held.add(key)
            yield
        finally:
            self._held.discard(key);fcntl.flock(fd,fcntl.LOCK_UN);os.close(fd)
    def _load(self,key):
        key=self._key(key);require(key in self._held,'JOURNAL_LOCK_REQUIRED')
        try:fd=os.open(self.root/(key+'.json'),os.O_RDONLY|os.O_NOFOLLOW)
        except FileNotFoundError:return None
        with os.fdopen(fd) as stream:
            require(os.fstat(stream.fileno()).st_size<=8_388_608,'JOURNAL_TOO_LARGE')
            value=json.load(stream)
        require(type(value) is dict and value.get('version')==1 and value.get('state') in ('pending','checkpoint'),'JOURNAL_INVALID')
        return value
    def _save(self,key,value):
        require(key in self._held,'JOURNAL_LOCK_REQUIRED')
        body=json.dumps(value,ensure_ascii=False,allow_nan=False).encode()
        require(len(body)<=8_388_608,'JOURNAL_TOO_LARGE')
        fd,path=tempfile.mkstemp(prefix='.journal-',dir=self.root)
        try:
            with os.fdopen(fd,'wb') as stream:stream.write(body);stream.flush();os.fsync(stream.fileno())
            os.replace(path,self.root/(key+'.json'))
            directory=os.open(self.root,os.O_RDONLY)
            try:os.fsync(directory)
            finally:os.close(directory)
        finally:
            if os.path.exists(path):os.unlink(path)
    def begin(self,key):
        if self._load(key) is not None:return False
        self._save(key,{'version':1,'state':'pending'});return True
    def read(self,key):
        value=self._load(key)
        return value.get('payload') if value and value['state']=='checkpoint' else None
    def exists(self,key):
        """Includes dispatch intent without a completed checkpoint; requires lock."""
        return self._load(key) is not None
    def write(self,key,payload):
        prior=self._load(key);require(prior is not None,'JOURNAL_NOT_STARTED')
        require(prior['state']=='pending' or prior.get('payload')==payload,'JOURNAL_CHECKPOINT_IMMUTABLE')
        self._save(key,{'version':1,'state':'checkpoint','payload':payload})
