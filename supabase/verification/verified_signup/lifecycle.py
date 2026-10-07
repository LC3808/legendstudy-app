"""Run the existing full disposable lifecycle suite with the verified signup guard.
Only adds the guard at the existing Auth shim boundary; no assertion is removed.
Use --pg-bin /path/to/postgresql/17/bin. No network DSN is accepted.
"""
import pathlib,sys,tempfile
root=pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'tool'))
original_temporary_directory=tempfile.TemporaryDirectory
def portable_temp(*args,**kwargs):
    if kwargs.get('dir')=='/private/tmp':kwargs['dir']='/tmp'
    return original_temporary_directory(*args,**kwargs)
tempfile.TemporaryDirectory=portable_temp
path=root/'tool/test_account_deletion.py';source=path.read_text()
anchor=' c.execute("alter table auth.users add column email_confirmed_at timestamptz default now()")'
assert source.count(anchor)==1
source=source.replace(anchor,anchor+'\n c.execute((h.R/"supabase/migrations/20261007150000_verified_signup_eligibility.sql").read_text())',1)
exec(compile(source,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
