import { createProductionCandidate } from "../resource-resolver/candidate.ts";
import { parseRequest } from "../resource-resolver/handler.ts";
import { readBoundedText } from "../resource-resolver/security.ts";
const headers = {"Content-Type":"application/json", "Cache-Control":"no-store", "Access-Control-Allow-Origin":"*", "Access-Control-Allow-Headers":"apikey, content-type, authorization, x-client-info", "Access-Control-Allow-Methods":"POST, OPTIONS"};
export function downloadHandler(policy: (id: string) => Promise<Record<string, unknown>>, resolve: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    const denied = () => new Response(JSON.stringify({status:"denied"}), {status:403,headers});
    if (req.method === "OPTIONS") return new Response(null,{status:204,headers});
    if (req.method !== "POST") return new Response(null,{status:405,headers});
    try {
      const text = await readBoundedText(new Response(req.body),256,AbortSignal.timeout(3000));
      const body = text === null ? null : parseRequest(JSON.parse(text));
      if (!body) return denied();
      const p = await policy(body.resource_id);
      if (p.state !== "ALLOWED" || typeof p.sha256 !== "string" || !/^[a-f0-9]{64}$/.test(p.sha256)) return denied();
      const response = await resolve(new Request(req.url,{method:"POST",body:JSON.stringify(body)}));
      const result = await response.json();
      if (result.status !== "resolved" || result.resource_id !== body.resource_id) return denied();
      // Recheck after source resolution to catch revocation while resolving.
      const current = await policy(body.resource_id);
      if (JSON.stringify(current) !== JSON.stringify(p)) return denied();
      return new Response(JSON.stringify({...result,policy:p}),{headers});
    } catch { return denied(); }
  };
}
if (import.meta.main) {
  const url = Deno.env.get("SUPABASE_URL")!;
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const resolve = createProductionCandidate(url,key);
  Deno.serve(downloadHandler(async (id) => {
    const r = await fetch(`${url}/rest/v1/rpc/resource_download_policy`, {method:"POST", redirect:"error", signal:AbortSignal.timeout(3000), headers:{apikey:key, Authorization:`Bearer ${key}`, "Content-Type":"application/json"},body:JSON.stringify({p_resource_id:id})});
    if (!r.ok) throw new Error("policy unavailable");
    return await r.json();
  },resolve));
}
