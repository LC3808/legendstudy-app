// Public, read-only and bounded. No Supabase DB/Auth admin client or user JWT.
const headers = {
  "Content-Type": "application/json; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Cache-Control": "no-store",
};
const schoolFields = [
  "ATPT_OFCDC_SC_CODE",
  "SD_SCHUL_CODE",
  "SCHUL_NM",
  "SCHUL_KND_SC_NM",
  "ORG_RDNMA",
];
const mealFields = [
  "ATPT_OFCDC_SC_CODE",
  "SD_SCHUL_CODE",
  "MMEAL_SC_NM",
  "MLSV_YMD",
  "DDISH_NM",
];
const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers });
const validCode = (s: string | null): s is string =>
  s !== null && s.length >= 1 && s.length <= 32 && s.trim() === s;

export function createHandler(
  key: () => string | undefined,
  fetcher: typeof fetch = fetch,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== "GET") {
      return reply(405, { error: "method_not_allowed" });
    }
    const params = new URL(request.url).searchParams;
    const action = params.get("action");
    const endpoint = action === "search" || action === "school"
      ? "schoolInfo"
      : action === "meals"
      ? "mealServiceDietInfo"
      : null;
    if (!endpoint) return reply(400, { error: "invalid_request" });
    const allowed = action === "search"
      ? ["action", "q"]
      : action === "school"
      ? ["action", "office", "school"]
      : ["action", "office", "school", "date"];
    for (const name of params.keys()) {
      if (!allowed.includes(name) || params.getAll(name).length !== 1) {
        return reply(400, { error: "invalid_request" });
      }
    }
    const query = new URLSearchParams({
      Type: "json",
      pIndex: "1",
      pSize: "100",
    });
    if (action === "search") {
      const term = params.get("q")?.trim();
      if (!term || term.length > 100) {
        return reply(400, { error: "invalid_request" });
      }
      query.set("SCHUL_NM", term);
    } else {
      const office = params.get("office"), school = params.get("school");
      if (!validCode(office) || !validCode(school)) {
        return reply(400, { error: "invalid_request" });
      }
      query.set("ATPT_OFCDC_SC_CODE", office);
      query.set("SD_SCHUL_CODE", school);
      if (action === "meals") {
        const date = params.get("date");
        if (!date || !/^\d{8}$/.test(date)) {
          return reply(400, { error: "invalid_request" });
        }
        const iso = `${date.slice(0, 4)}-${date.slice(4, 6)}-${
          date.slice(6, 8)
        }`;
        const parsed = new Date(`${iso}T00:00:00Z`);
        if (
          Number.isNaN(parsed.valueOf()) ||
          parsed.toISOString().slice(0, 10) !== iso
        ) return reply(400, { error: "invalid_request" });
        query.set("MLSV_YMD", date);
      }
    }
    const apiKey = key();
    if (!apiKey) return reply(503, { error: "service_unavailable" });
    query.set("KEY", apiKey);
    try {
      const response = await fetcher(
        `https://open.neis.go.kr/hub/${endpoint}?${query}`,
        {
          signal: AbortSignal.timeout(10000),
          redirect: "error",
        },
      );
      if (!response.ok) return reply(502, { error: "upstream_unavailable" });
      const body = await response.json();
      const entries = body[endpoint];
      const result = body.RESULT ??
        entries?.flatMap((e: { head?: unknown[] }) => e.head ?? [])
          .find((e: { RESULT?: unknown }) => e.RESULT)?.RESULT;
      if (result?.CODE === "INFO-200") return reply(200, { rows: [] });
      if (result?.CODE !== "INFO-000" || !Array.isArray(entries)) {
        return reply(502, { error: "upstream_unavailable" });
      }
      const rows = entries.flatMap((e: { row?: unknown[] }) =>
        e.row ?? []
      ) as Record<string, unknown>[];
      const fields = endpoint === "schoolInfo" ? schoolFields : mealFields;
      if (
        rows.length > 100 ||
        rows.some((row: Record<string, unknown>) =>
          !row || typeof row !== "object" ||
          fields.some((name) =>
            typeof row[name] !== "string" &&
            !(endpoint === "schoolInfo" &&
              ["SCHUL_KND_SC_NM", "ORG_RDNMA"].includes(name) &&
              row[name] === null)
          )
        )
      ) {
        return reply(502, { error: "upstream_unavailable" });
      }
      return reply(200, {
        rows: rows.map((row: Record<string, unknown>) =>
          Object.fromEntries(fields.map((name) => [name, row[name]]))
        ),
      });
    } catch (_) {
      // Never log upstream URL (contains key), errors or response bodies.
      return reply(502, { error: "upstream_unavailable" });
    }
  };
}
