"""LOCAL ONLY platform catalog model. Never execute against a Hosted database.
Replays Owner-supplied role/schema/default-ACL metadata, not data or credentials.
Managed Auth implementation/extensions are not emulated; auth.uid is a local shim.
"""
from psycopg import sql

PERMISSIONS = {'U':'USAGE','C':'CREATE','X':'EXECUTE','r':'SELECT','w':'UPDATE',
               'a':'INSERT','d':'DELETE','D':'TRUNCATE','x':'REFERENCES',
               't':'TRIGGER','m':'MAINTAIN'}
OBJECTS = {'r':'TABLES','S':'SEQUENCES','f':'FUNCTIONS'}

def acl_items(value):
    for item in value[1:-1].split(','):
        grantee, tail = item.split('=')
        privileges, grantor = tail.split('/')
        i = 0
        while i < len(privileges):
            privilege = PERMISSIONS[privileges[i]]
            option = i+1 < len(privileges) and privileges[i+1] == '*'
            yield grantee, privilege, option, grantor
            i += 2 if option else 1

def grantee(name):
    return sql.Identifier(name) if name else sql.SQL('PUBLIC')

def setup(admin, observed):
    admin.execute('create role postgres login nosuperuser createrole createdb bypassrls; alter database postgres owner to postgres')
    # Keep PG17's original public schema owner pg_database_owner. Never normalize it.
    assert admin.execute("select pg_get_userbyid(nspowner) from pg_namespace where nspname='public'").fetchone()[0]=='pg_database_owner'
    admin.execute('create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls; create role authenticator login noinherit; create role supabase_auth_admin nologin; create role dashboard_user nologin; create role supabase_privileged_role nologin')
    for row in observed['schemas']:
        if row['name'] != 'public':
            admin.execute(sql.SQL('create schema {} authorization {}').format(sql.Identifier(row['name']),sql.Identifier(row['owner'])))
        for target, privilege, option, grantor in acl_items(row['acl']):
            admin.execute(sql.SQL('set role {}').format(sql.Identifier(grantor)))
            admin.execute(sql.SQL('grant {} on schema {} to {}{}').format(sql.SQL(privilege),sql.Identifier(row['name']),grantee(target),sql.SQL(' with grant option' if option else '')))
            admin.execute('reset role')
    for row in observed['memberships']:
        assert row['grantor']=='supabase_admin'
        admin.execute(sql.SQL('grant {} to {} with admin {}, inherit {}, set {} granted by supabase_admin').format(
            sql.Identifier(row['role']),sql.Identifier(row['member']),sql.SQL(str(row['admin'])),sql.SQL(str(row['inherit'])),sql.SQL(str(row['set']))))
    for row in observed['default_acl']:
        # Unused managed namespaces are empty local facilities, not a deployed replica.
        admin.execute(sql.SQL('create schema if not exists {}').format(sql.Identifier(row['schema'])))
        prefix=sql.SQL('alter default privileges for role {} in schema {} ').format(sql.Identifier(row['owner']),sql.Identifier(row['schema']))
        obj=sql.SQL(OBJECTS[row['object_type']])
        admin.execute(prefix+sql.SQL('revoke all on {} from public, {}').format(obj,sql.Identifier(row['owner'])))
        for target, privilege, option, grantor in acl_items(row['acl']):
            assert grantor==row['owner']
            admin.execute(prefix+sql.SQL('grant {} on {} to {}{}').format(sql.SQL(privilege),obj,grantee(target),sql.SQL(' with grant option' if option else '')))
    admin.execute("create table auth.users(id uuid primary key,created_at timestamptz default now(),email_confirmed_at timestamptz); create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$; grant references on auth.users to postgres")

def verify(c, observed):
    for row in observed['roles']:
        actual=c.execute('select rolcanlogin,rolinherit,rolsuper,rolbypassrls,rolcreaterole from pg_roles where rolname=%s',(row['name'],)).fetchone()
        assert actual==tuple(row[k] for k in ['login','inherit','superuser','bypass_rls','create_role']),(row['name'],actual)
    for row in observed['schemas']:
        actual=c.execute('select pg_get_userbyid(nspowner),nspacl::text from pg_namespace where nspname=%s',(row['name'],)).fetchone()
        assert actual[0]==row['owner'],(row['name'],actual)
        assert set(actual[1][1:-1].split(','))==set(row['acl'][1:-1].split(',')),(row['name'],actual)
    expected={(r['role'],r['member'],r['grantor'],r['admin'],r['inherit'],r['set']) for r in observed['memberships']}
    actual=set(c.execute("select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where pg_get_userbyid(member) in ('postgres','authenticator','anon','authenticated','service_role')").fetchall())
    assert actual==expected,(actual-expected,expected-actual)
    actual={(owner,ns,kind):set(acl[1:-1].split(',')) for owner,ns,kind,acl in c.execute('select pg_get_userbyid(defaclrole),defaclnamespace::regnamespace::text,defaclobjtype,defaclacl::text from pg_default_acl').fetchall()}
    expected={(r['owner'],r['schema'],r['object_type']):set(r['acl'][1:-1].split(',')) for r in observed['default_acl']}
    assert actual==expected,(actual,expected)
    assert c.execute("select has_schema_privilege('postgres','public','CREATE') and has_schema_privilege('postgres','auth','USAGE') and has_table_privilege('postgres','auth.users','REFERENCES')").fetchone()[0]
