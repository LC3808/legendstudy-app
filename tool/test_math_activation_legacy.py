#!/usr/bin/env python3
"""Unchanged 102 Humanities/HQP assertions after the full local activation candidate."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tool/test_math_legacy.py').read_text().replace('/math_essay/legacy_validation.json','/math_essay/activation/legacy_validation.json')
prerequisites=['20260913000200','20260914000100','20260914000200','20260923000100','20260926000100','20260930000100','20260917000200']
extra="\n for version in "+repr(prerequisites)+":c.execute(next((R/'supabase/migrations').glob(version+'_*.sql')).read_text())\n c.execute('alter table auth.users add column email_confirmed_at timestamptz default now()')\n c.execute('create schema storage;create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text);alter table storage.objects enable row level security;create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[])')"
s=s.replace(" sock=args[-1]",extra+"\n sock=args[-1]")
needle="try:c.execute((R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())"
files=['20261001000300_account_deletion_lifecycle.sql','20261002000100_math_essay_persistence.sql','20261002000200_math_runtime_surface.sql','20261002000300_math_learning_runtime.sql','20261004000200_math_storage_erasure_activation.sql']
s=s.replace(needle,"try:\n"+''.join("   c.execute((R/'supabase/migrations/"+name+"').read_text())\n" for name in files).rstrip())
exec(compile(s,str(R/'tool/test_math_legacy.py'),'exec'),{'__file__':str(R/'tool/test_math_legacy.py'),'__name__':'__main__'})
