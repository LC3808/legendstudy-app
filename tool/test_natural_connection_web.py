"""Run existing WEB modules with private connection metadata; no HTTP/Provider.

Creates an ignored .local test fixture in the explicitly supplied WEB checkout.
Tracked WEB source/configuration is never edited.
"""
import argparse
import json
from pathlib import Path
import subprocess

parser=argparse.ArgumentParser()
parser.add_argument('--web-root',required=True,type=Path)
parser.add_argument('--candidate-root',required=True,type=Path)
args=parser.parse_args()
web=args.web_root.resolve();candidate=args.candidate_root.resolve()
root=Path(__file__).resolve().parents[1]
fixture=web/'.local/natural-connection-20261111'
fixture.mkdir(parents=True,exist_ok=True)
test=fixture/'connection.test.ts'
test.write_text((root/'tool/fixtures/natural_connection.web.test.ts').read_text().replace('__WEB_ROOT__',str(web)).replace('__CANDIDATE_ROOT__',str(candidate)))
config=fixture/'vitest.config.mjs'
config.write_text('export default '+json.dumps({'resolve':{'alias':{'@':str(web/'src')}},'test':{'environment':'node','include':[str(test)],'globals':True}})+';\n')
result=subprocess.run([str(web/'node_modules/.bin/vitest'),'run','--config',str(config),'--reporter=json','--outputFile='+str(candidate/'web-contract-report.json')],cwd=web)
raise SystemExit(result.returncode)
