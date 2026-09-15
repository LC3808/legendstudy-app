#!/bin/sh
# No credentials in arguments or files. Python retains all getpass prompts.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
stable_venv="$HOME/Library/Application Support/LegendStudy/verifier-venv"

if [ "${1-}" = "--setup" ]; then
    if [ "$#" -ne 1 ]; then
        printf '%s\n' 'Use --setup alone; run the smoke separately afterward.' >&2
        exit 2
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        printf '%s\n' 'Python 3 is required to create the dedicated verifier venv.' >&2
        exit 2
    fi
    # Explicit opt-in setup; never installs into global Python or the repository.
    if ! python3 -m venv "$stable_venv" >/dev/null 2>&1 ||
       ! "$stable_venv/bin/python" -m pip install --disable-pip-version-check 'psycopg[binary]==3.2.10' >/dev/null 2>&1; then
        printf '%s\n' 'Verifier venv setup failed. Check Python venv support and package-network access, then retry --setup.' >&2
        exit 2
    fi
    printf '%s\n' 'Verifier venv ready. Run this wrapper with the external local-config path.'
    exit 0
fi
if [ "$#" -eq 0 ]; then
    printf '%s\n' 'Usage: ./tool/run_mock_grade_flutter_smoke.sh /path/to/local-config.json [--device ID] [--preflight-only]' >&2
    printf '%s\n' 'One-time setup if needed: ./tool/run_mock_grade_flutter_smoke.sh --setup' >&2
    exit 2
fi
if [ -n "${LEGENDSTUDY_VERIFIER_VENV-}" ]; then
    verifier_python="$LEGENDSTUDY_VERIFIER_VENV/bin/python"
elif [ -x "$stable_venv/bin/python" ]; then
    verifier_python="$stable_venv/bin/python"
else
    verifier_python='/private/tmp/legendstudy-scoring-verifier-venv/bin/python'
fi
if [ ! -x "$verifier_python" ] ||
   ! "$verifier_python" -I -c 'import sys, psycopg; assert sys.prefix != sys.base_prefix' >/dev/null 2>&1; then
    printf '%s\n' 'Dedicated verifier venv is missing or lacks psycopg. Global Python is not used.' >&2
    printf '%s\n' 'Run: ./tool/run_mock_grade_flutter_smoke.sh --setup' >&2
    printf '%s\n' 'If LEGENDSTUDY_VERIFIER_VENV is set, unset it or point it to a prepared venv.' >&2
    exit 2
fi
exec "$verifier_python" -B "$repo/tool/run_mock_grade_flutter_smoke.py" "$@"
