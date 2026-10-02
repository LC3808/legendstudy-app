#!/usr/bin/env python3
"""Unchanged 102 HQP/Humanities assertions after C/D/E, isolated only."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tool/test_math_legacy.py').read_text().replace('/math_essay/legacy_validation.json','/math_essay/learning/legacy_validation.json')
s=s.replace("try:c.execute((R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())", "try:\n   c.execute((R/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text())\n   c.execute((R/'supabase/migrations/20261002000200_math_runtime_surface.sql').read_text())\n   c.execute((R/'supabase/migrations/20261002000300_math_learning_runtime.sql').read_text())")
exec(compile(s,str(R/'tool/test_math_legacy.py'),'exec'),{'__file__':str(R/'tool/test_math_legacy.py'),'__name__':'__main__'})
