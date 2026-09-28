"""Offline catalog comparison only. No DB connection, migration execution or history writes.
Later repository additions are included in the final-state projection; defaults are current observed Supabase defaults.
This produces state evidence, NEVER proof that a migration version executed.
"""
from pathlib import Path
import json,hashlib,copy
from pglast import parse_sql,ast,parser,scan
from pglast.stream import RawStream
HERE=Path(__file__).resolve().parent
R=HERE.parents[2]
J=json.loads((HERE/'catalog.json').read_text());T={x['name']:x for x in J['tables']};F={x['name']:x for x in J['functions']}
INV=json.loads((HERE/'inventory.json').read_text()); results={x['version']:[] for x in INV}
def record(v,kind,name,ok,expected=None,actual=None):results[v].append(dict(kind=kind,name=name,match=ok,**({} if ok else dict(expected=expected,actual=actual))))
def rel(x):return (x.schemaname or 'public')+'.'+x.relname
def normal(x,table=None):
 if x is None:return None
 if isinstance(x,(tuple,list)):return [normal(z,table) for z in x]
 if isinstance(x,ast.Node):x=x()
 if isinstance(x,dict):
  typ=x.get('@')
  if ('#' in x and 'name' in x) or set(x)=={'name'} and x['name'] in ('AND_EXPR','AEXPR_OP'):return x['name']
  if typ=='TypeCast' and x['typeName'].get('names',())[-1].get('sval') in ('text','int4','int8','numeric') and x.get('arg',{}).get('@')=='A_Const':return normal(x['arg'],table)
  if typ=='A_Expr':
   kind=x.get('kind',{});kind=kind.get('name') if isinstance(kind,dict) else kind
   if kind=='AEXPR_BETWEEN':
    a=x['lexpr'];b,c=x['rexpr'];return normal({'@':'BoolExpr','boolop':{'name':'AND_EXPR'},'args':[{'@':'A_Expr','kind':{'name':'AEXPR_OP'},'name':[{'@':'String','sval':'>='}],'lexpr':a,'rexpr':b},{'@':'A_Expr','kind':{'name':'AEXPR_OP'},'name':[{'@':'String','sval':'<='}],'lexpr':a,'rexpr':c}]},table)
   if kind=='AEXPR_IN' or kind=='AEXPR_OP_ANY' and x.get('rexpr',{}).get('@')=='A_ArrayExpr':return {'in':normal(x['lexpr'],table),'op':normal(x['name'],table),'values':normal(x['rexpr'] if kind=='AEXPR_IN' else x['rexpr']['elements'],table)}
  out={k:normal(v,table) for k,v in x.items() if k not in ('location','stmt_location','stmt_len','rexpr_list_start','rexpr_list_end') and v is not None}
  if typ=='TypeName' and out.get('names',[{}])[0].get('sval')=='pg_catalog':out['names']=out['names'][1:]
  if typ=='ResTarget':out.pop('name',None)
  if typ=='RangeVar' and out.get('schemaname')=='public':out.pop('schemaname')
  if typ=='FuncCall' and out.get('funcname',[{}])[0].get('sval') in ('public','pg_catalog'):out['funcname']=out['funcname'][1:]
  if typ=='ColumnRef' and len(out.get('fields',[]))==2 and out['fields'][0].get('sval')==table:out['fields']=out['fields'][1:]
  return out
 return x
def exp(s,table=None):return normal(parse_sql('select '+s)[0].stmt.targetList[0].val,table) if s else None
def typename(n):return normal(parse_sql('create table x(a '+n+')')[0].stmt.tableElts[0].typeName)
def cons(c,column=None):
 k=c.contype.name
 if k=='CONSTR_CHECK':return (k,normal(c.raw_expr))
 if k in ('CONSTR_PRIMARY','CONSTR_UNIQUE'):return (k,[z.sval for z in c.keys] if c.keys else [column],c.deferrable,c.initdeferred,c.nulls_not_distinct)
 if k=='CONSTR_FOREIGN':return (k,[z.sval for z in c.fk_attrs] if c.fk_attrs else [column],rel(c.pktable),[z.sval for z in c.pk_attrs or ()],c.fk_del_action,c.fk_upd_action,c.deferrable,c.initdeferred)
 return None
# Compare migration-owned elements, later overrides attributed to their last author.
E={}; owners={};policies={};indexes={};triggers={};columns={};constraints={};rls={};functions={}
for inv in INV[:13]:
 v=inv['version'];p=R/'supabase/migrations'/inv['filename']
 for node in parse_sql(p.read_text()):
  x=node.stmt;k=type(x).__name__
  if k=='CreateStmt':
   table=rel(x.relation);E[table]=v
   for el in x.tableElts:
    if type(el).__name__=='ColumnDef':
     columns[(table,el.colname)]=(v,el)
     for c in el.constraints or ():
      if cons(c,el.colname):constraints[(table,c.conname or str(cons(c,el.colname)))]=(v,c,el.colname)
    elif type(el).__name__=='Constraint':constraints[(table,el.conname or str(cons(el)))]=(v,el,None)
  if k=='AlterTableStmt':
   table=rel(x.relation)
   for cmd in x.cmds:
    if cmd.subtype.name=='AT_AddColumn':
     el=cmd.def_;columns[(table,el.colname)]=(v,el)
     for c in el.constraints or ():
      if cons(c,el.colname):constraints[(table,c.conname or str(cons(c,el.colname)))]=(v,c,el.colname)
    elif cmd.subtype.name=='AT_AddConstraint':constraints[(table,cmd.def_.conname or str(cons(cmd.def_)))]=(v,cmd.def_,None)
    elif cmd.subtype.name=='AT_DropConstraint':
     constraints.pop((table,cmd.name),None)
     # unnamed inline status constraint inferred name; track supersession.
     if cmd.name=='feedback_notifications_status_check':
      for key in list(constraints):
       vv,c,col=constraints[key]
       if key[0]==table and col=='status' and c.contype.name=='CONSTR_CHECK':del constraints[key]
    elif cmd.subtype.name=='AT_EnableRowSecurity':rls[table]=v
  if k=='CreatePolicyStmt':policies[(rel(x.table),x.policy_name)]=(v,x)
  if k=='IndexStmt':indexes[(rel(x.relation),x.idxname)]=(v,x)
  if k=='CreateTrigStmt':triggers[(rel(x.relation),x.trigname)]=(v,x)
  if k=='CreateFunctionStmt':functions['.'.join(z.sval for z in x.funcname)]=(v,x)
for table,v in E.items():record(v,'table',table,table in T)
for (table,name),(v,c) in columns.items():
 actual=next((a for a in T.get(table,{}).get('columns',[]) if a['name']==name),None)
 nn=any(z.contype.name in ('CONSTR_NOTNULL','CONSTR_PRIMARY') for z in c.constraints or ()) or any(kk[0]==table and cc.contype.name=='CONSTR_PRIMARY' and name in [q.sval for q in cc.keys or ()] for kk,(vv,cc,col) in constraints.items())
 default=next((RawStream()(z.raw_expr) for z in c.constraints or () if z.contype.name in ('CONSTR_DEFAULT','CONSTR_GENERATED')),None)
 expected=dict(type=RawStream()(c.typeName),not_null=nn,default=default)
 ok=actual is not None and typename(actual['type'])==normal(c.typeName) and actual['not_null']==nn and exp(actual['default'])==exp(default)
 record(v,'column',table+'.'+name,ok,expected,actual)
for (table,key),(v,c,col) in constraints.items():
 expected=cons(c,col);found=False
 for a in T.get(table,{}).get('constraints',[]):
  try:ac=parse_sql('create table x('+a['definition']+')')[0].stmt.tableElts[0]
  except Exception:continue
  if cons(ac)==expected and a['validated'] and (not c.conname or c.conname==a['name']):found=True;break
 record(v,'constraint',table+'.'+(c.conname or str(expected)),found,RawStream()(c),None)
for table,v in rls.items():record(v,'rls',table,T.get(table,{}).get('rls') is True and T[table]['force_rls'] is False)
for (table,name),(v,x) in policies.items():
 a=next((a for a in T.get(table,{}).get('policies',[]) if a['name']==name),None)
 e=dict(cmd=x.cmd_name.upper(),roles=sorted(z.rolename or 'public' for z in x.roles),using=RawStream()(x.qual) if x.qual else None,check=RawStream()(x.with_check) if x.with_check else None)
 ok=a is not None and a['cmd']==e['cmd'] and sorted(a['roles'])==e['roles'] and a['permissive']==('PERMISSIVE' if x.permissive else 'RESTRICTIVE') and exp(a['using'],table.split('.')[-1])==exp(e['using'],table.split('.')[-1]) and exp(a['check'],table.split('.')[-1])==exp(e['check'],table.split('.')[-1])
 record(v,'policy',table+'.'+name,ok,e,a)
for (table,name),(v,x) in indexes.items():
 a=next((a for a in T.get(table,{}).get('indexes',[]) if a['name']==name),None)
 def ix(z):return [z.unique,z.accessMethod or 'btree',normal(z.indexParams),normal(z.whereClause),normal(z.indexIncludingParams)]
 ok=a is not None and a['valid'] and ix(parse_sql(a['definition'])[0].stmt)==ix(x)
 record(v,'index',table+'.'+name,ok,RawStream()(x),a)
for (table,name),(v,x) in triggers.items():
 a=next((a for a in T.get(table,{}).get('triggers',[]) if a['name']==name),None)
 def tr(z):return [z.row,z.timing,z.events,z.isconstraint,z.deferrable,z.initdeferred,normal(z.whenClause),[s.sval for s in z.funcname][-1],normal(z.args),normal(z.columns)]
 record(v,'trigger',table+'.'+name,a is not None and a['enabled']=='O' and tr(parse_sql(a['definition'])[0].stmt)==tr(x),RawStream()(x),a)
for name,(v,x) in functions.items():
 a=F.get(name);body=next(o.arg[0].sval for o in x.options if o.defname=='as');h=hashlib.md5(body.strip(' \t\n\r').encode()).hexdigest();ok=a is not None and a['body_md5']==h
 if name=='public.study_active_milliseconds':
  tok=[body[t.start:t.end+1] for t in scan(body) if t.name not in ('SQL_COMMENT','C_COMMENT')];ok=hashlib.sha256(json.dumps(tok,ensure_ascii=False).encode()).hexdigest()==json.loads((HERE/'catalog_followup.json').read_text())['study_token_sha256']
 record(v,'function_body',name,ok,h,a['body_md5'] if a else None)
 # parameter/signature, return table descriptor, volatility/security/config are retained for manual review.
D=json.loads((HERE/'catalog_followup.json').read_text()); acl={}; ca={};facl={};attribution={}
# Reconstruct privileges from observed Supabase defaults + ordered explicit migration grants.
for table,v in E.items():
 acl[table]={(z['role'],z['privilege']) for z in D['defaults'] if z['type']=='r' and z['schema'] in (None,'public') and z['role']!='postgres'};ca[table]=set();attribution[table]=v
for name,(v,x) in functions.items():
 facl[name]={(z['role'],z['privilege']) for z in D['defaults'] if z['type']=='f' and z['schema'] in (None,'public') and z['role']!='postgres'}
 if not any(z['type']=='f' and z['schema'] is None for z in D['defaults']):facl[name].add(('PUBLIC','EXECUTE'))
for inv in INV[:13]:
 for nn in parse_sql((R/'supabase/migrations'/inv['filename']).read_text()):
  x=nn.stmt
  if type(x).__name__!='GrantStmt':continue
  roles=[z.rolename or 'PUBLIC' for z in x.grantees]
  for ob in x.objects or ():
   if x.objtype.name=='OBJECT_TABLE':name=rel(ob);dest=acl
   elif x.objtype.name=='OBJECT_FUNCTION':name='.'.join(z.sval for z in ob.objname);dest=facl
   else:continue
   if name not in dest:continue
   if x.privileges:
    for pr in x.privileges:
     for role in roles:
      if pr.cols and dest is acl:
       for col in pr.cols:
        v=(col.sval,role,pr.priv_name.upper())
        ca[name].add(v) if x.is_grant else ca[name].discard(v)
      else:
       v=(role,pr.priv_name.upper());dest[name].add(v) if x.is_grant else dest[name].discard(v)
   elif not x.is_grant:dest[name]={z for z in dest[name] if z[0] not in roles}
for table,e in acl.items():
 a={(z['role'],z['privilege']) for z in T[table]['table_acl']};v=E[table];record(v,'effective_table_grants',table,a==e,sorted(e),sorted(a))
 a={(z['column'],z['role'],z['privilege']) for z in T[table]['column_acl']};e=ca[table];record(v,'effective_column_grants',table,a==e,sorted(e),sorted(a))
for name,e in facl.items():
 a={(z['role'],z['privilege']) for z in F[name]['acl'] or []};record(functions[name][0],'effective_function_grants',name,a==e,sorted(e),sorted(a))
# Exact public method identity and optional defaults, plus security and runtime attributes.
for name,(v,x) in functions.items():
 a=F[name]
 actual=parse_sql('create function f('+a['args_with_defaults']+') returns '+a['result']+" language sql as 'select 1'")[0].stmt
 def params(z):return [(p.name,normal(p.argType),p.mode.name,normal(p.defexpr)) for p in z.parameters or ()]
 record(v,'function_signature',name,params(x)==params(actual) and normal(x.returnType)==normal(actual.returnType),params(x),params(actual))
 o={o.defname:o.arg for o in x.options}
 expected={'definer':bool(o.get('security',ast.Boolean(boolval=False)).boolval),'volatility':o['volatility'].sval[0] if 'volatility' in o else 'v','strict':bool(o.get('strict',ast.Boolean(boolval=False)).boolval),'language':o['language'].sval}
 # security/strict AST flags are Integer in this parser, accounted below.
 record(v,'function_attributes',name,all(a[k]==vv for k,vv in expected.items()),expected,{k:a[k] for k in expected})
 config=[]
 for opt in x.options:
  if opt.defname=='set':config.append(opt.arg.name+'='+','.join('""' if z.val.sval=='' else z.val.sval for z in opt.arg.args))
 record(v,'function_config',name,sorted(config)==sorted(a['config'] or []),config,a['config'])
# Retain mismatches for inspection, never normalize semantic differences silently.
for table,v in E.items():
 expected={name for t,name in columns if t==table};actual={z['name'] for z in T[table]['columns']};record(v,'exact_column_set',table,expected==actual,sorted(expected),sorted(actual))
 for category,defs,field in [('policies',policies,'policies'),('triggers',triggers,'triggers')]:
  expected={name for t,name in defs if t==table};actual={z['name'] for z in T[table][field]};record(v,'exact_'+category+'_set',table,expected==actual,sorted(expected),sorted(actual))
 expected=sum(t==table for t,key in constraints);actual=sum(not c['definition'].startswith('TRIGGER ') for c in T[table]['constraints']);record(v,'exact_constraint_count',table,expected==actual,expected,actual)
for (table,name),(v,c) in columns.items():
 expected='s' if any(z.contype.name=='CONSTR_GENERATED' for z in c.constraints or ()) else ''
 actual=next(z for z in T[table]['columns'] if z['name']==name)
 record(v,'column_generation',table+'.'+name,actual['generated']==expected and actual['identity']=='',expected,actual['generated'])
x=next(x.stmt for x in parse_sql((R/'supabase/migrations/20260914000200_mock_exam_scoring.sql').read_text()) if type(x.stmt).__name__=='ViewStmt')
record('20260914000200','view','public.mock_exam_scoring_availability',normal(x.query)==normal(parse_sql(D['view_definition'])[0].stmt) and D['view_options']==['security_invoker=true'],RawStream()(x.query),D['view_definition'])
for inv in INV[:13]:
 for nn in parse_sql((R/'supabase/migrations'/inv['filename']).read_text()):
  x=nn.stmt
  if type(x).__name__=='GrantStmt' and x.is_grant and x.objtype.name=='OBJECT_TABLE':
   for obj in x.objects:
    table=rel(obj)
    for pr in x.privileges or ():
     for col in pr.cols or ():
      for role in x.grantees:
       yes=(col.sval,role.rolename or 'PUBLIC',pr.priv_name.upper()) in ca.get(table,set())
       record(inv['version'],'declared_column_grant',table+'.'+col.sval+':'+str(role.rolename)+':'+pr.priv_name,yes)
for name,(v,x) in functions.items():record(v,'function_owner',name,F[name]['owner']=='postgres','postgres',F[name]['owner'])

for table,v in E.items():
 record(v,'table_owner',table,T[table]['owner']=='postgres','postgres',T[table]['owner'])
 record(v,'grant_option',table,all(not z['grantable'] for z in T[table]['table_acl']+T[table]['column_acl']))
 expected=sum(t==table for t,key in indexes)+sum(t==table and c.contype.name in ('CONSTR_PRIMARY','CONSTR_UNIQUE') for (t,key),(vv,c,col) in constraints.items())
 record(v,'exact_index_count',table,expected==len(T[table]['indexes']),expected,len(T[table]['indexes']))
for name,(v,x) in functions.items():record(v,'function_grant_option',name,all(not z['grantable'] for z in F[name]['acl'] or []))
review=json.loads((HERE/'deparse_review.json').read_text())
for v,rows in results.items():
 for item in rows:
  if item['match'] or item['name'] not in review:continue
  approved=review[item['name']];actual=item.get('actual')
  if actual is None:
   table,name=item['name'].rsplit('.',1)
   actual=next(z['definition'] for z in T[table]['constraints'] if z['name']==name)
  if item['expected']==approved['expected'] and actual==approved['actual']:
   item['match']=True;item['normalization_review']=approved['reason']
   item.pop('expected',None);item.pop('actual',None)
if __name__=='__main__':
 print(json.dumps({'checks':sum(len(x) for x in results.values()),'unmatched':sum(not a['match'] for x in results.values() for a in x),'per_version':{v:{'checks':len(x),'unmatched':[a for a in x if not a['match']]} for v,x in results.items()}},indent=2,ensure_ascii=False))
