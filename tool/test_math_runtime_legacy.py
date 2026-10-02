#!/usr/bin/env python3
"""Existing unchanged HQP/Humanities assertions after both Math migrations."""
from pathlib import Path
import runpy
R=Path(__file__).resolve().parents[1]
s=(R/'tool/test_math_legacy.py').read_text()
s=s.replace("/math_essay/legacy_validation.json","/math_essay/runtime/legacy_validation.json")
s=s.replace("try:c.execute((R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())","try:\n   c.execute((R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())\n   c.execute((R/'supabase/migrations/20261002000200_math_runtime_surface.sql').read_text())")
exec(compile(s,str(R/'tool/test_math_legacy.py'),'exec'),{'__file__':str(R/'tool/test_math_legacy.py'),'__name__':'__main__'})
