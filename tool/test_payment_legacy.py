#!/usr/bin/env python3
"""Existing 102 HQP/Humanities tests after payment migration, isolated PG17 only."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tool/test_math_learning_legacy.py').read_text()
s=s.replace("exec(compile(s,", "s=s.replace(\"  finally:c.execute('rollback')\",\"   c.execute((R/'supabase/migrations/20261003000100_payment_foundation.sql').read_text())\\n  finally:c.execute('rollback')\")\ns=s.replace('/math_essay/learning/legacy_validation.json','/payments/legacy_validation.json')\nexec(compile(s,")
exec(compile(s,str(R/'tool/test_math_learning_legacy.py'),'exec'),dict(__file__=str(R/'tool/test_math_learning_legacy.py'),__name__='__main__'))
