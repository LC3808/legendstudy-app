"""legendstudy.com ingestion pipeline (Day 9-B).

Stages are deliberately separate: crawler (network / offline sample IO),
parser (raw HTML or extracted record -> raw observed facts), normalizer
(raw facts -> canonical rows + quarantine), writer (dry-run plan; apply is
gated). Nothing in this package writes to Supabase.
"""

PARSER_VERSION = 'legendstudy-parser/0.1.0'
MAPPING_RULE_VERSION = 'legendstudy-mapping/0.1.0'
SOURCE = 'legendstudy'
SITE_ORIGIN = 'https://legendstudy.com'
