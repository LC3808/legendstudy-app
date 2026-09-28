/** Operator-only adapter; no LAB deploy/product UI. Run inside the authenticated
 * LAB page, after Owner login. Return only a one-time digest. Never return session.
 * Direct GET /auth/v1/user is equivalent server validation to auth.getUser().
 * Config key is publishable, never a secret/service-role key. */
export async function probeLabIdentity({ salt, expires, publishableKey }, env = globalThis) {
  const project = 'stlhijzpjfgwwdgunlsd';
  if (env.location.origin !== 'https://lab.legendstudy.com' ||
      !/^[0-9a-f]{64}$/.test(salt) || !/^sb_publishable_[A-Za-z0-9_-]+$/.test(publishableKey) ||
      !Number.isFinite(Date.parse(expires)) || Date.parse(expires) <= Date.now() ||
      Date.parse(expires) > Date.now() + 7200000) return { status: 'invalid_configuration' };
  const bytes = s => new TextEncoder().encode(s);
  const hex = b => Array.from(new Uint8Array(b), x => x.toString(16).padStart(2, '0')).join('');
  const challenge = hex(await env.crypto.subtle.digest('SHA-256', bytes(salt)));
  const base = { schema: 'legendstudy-identity-v1', surface: 'lab', project, challenge,
    observed_at: new Date().toISOString(), event: 'operator_snapshot' };
  try {
    // Match the actual LAB browserClient storageKey. Keep token entirely inside browser memory.
    const original = env.localStorage.getItem('legendstudy-lab-auth');
    if (!original) return { ...base, status: 'signed_out' };
    const session = JSON.parse(original);
    if (!session.access_token || !session.user?.id) return { ...base, status: 'verification_failed' };
    const response = await env.fetch(`https://${project}.supabase.co/auth/v1/user`, {
      method: 'GET', redirect: 'error', cache: 'no-store', credentials: 'omit',
      headers: { apikey: publishableKey, Authorization: `Bearer ${session.access_token}` },
    });
    if (!response.ok) return { ...base, status: 'verification_failed' };
    const user = await response.json();
    if (env.localStorage.getItem('legendstudy-lab-auth') !== original || Date.now() >= Date.parse(expires))
      return { ...base, status: 'session_changed' };
    if (!user.id || user.id !== session.user.id) return { ...base, status: 'verification_failed' };
    const key = await env.crypto.subtle.importKey('raw', bytes(salt), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
    const digest = hex(await env.crypto.subtle.sign('HMAC', key, bytes(`legendstudy-identity-v1|${project}|${user.id}`)));
    return { ...base, status: 'verified', digest };
  } catch (_) { return { ...base, status: 'verification_failed' }; }
}
