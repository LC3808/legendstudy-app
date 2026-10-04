import { eraseMathStorage } from "./math-storage.ts";
const subject = "00000000-0000-4000-8000-000000000001";
function assert(ok: unknown) { if (!ok) throw Error("assertion"); }
Deno.test("Math Storage deletes nested owned bytes/orphans and re-lists page zero", async () => {
  const objects = new Set([`${subject}/attempt/raw/artifact`, `${subject}/orphan/crop/file`, "foreign/attempt/raw/file"]);
  await eraseMathStorage({
    list: async (_bucket, prefix) => {
      const entries = new Map<string, { name: string; id: string | null }>();
      for (const path of objects) if (path.startsWith(prefix + "/")) {
        const relative = path.slice(prefix.length + 1), name = relative.split("/")[0];
        entries.set(name, { name, id: relative.includes("/") ? null : "object" });
      }
      return [...entries.values()];
    },
    remove: async (bucket, paths) => { assert(bucket === "math-private"); for (const path of paths) objects.delete(path); },
  }, subject);
  assert(objects.size === 1 && objects.has("foreign/attempt/raw/file"));
});
Deno.test("Math Storage fails closed on traversal and transport errors", async () => {
  for (const name of ["..", "a/b", "a\\b"]) {
    let denied = false;
    try { await eraseMathStorage({ list: async () => [{ name, id: "object" }], remove: async () => { throw Error("must not delete"); } }, subject); }
    catch { denied = true; } assert(denied);
  }
});
Deno.test("Math Storage bounded non-progress is retryable, never false absence", async () => {
  let calls = 0, denied = false;
  try { await eraseMathStorage({ list: async () => { calls++; return [{ name: "file", id: "object" }]; }, remove: async () => {} }, subject); }
  catch { denied = true; } assert(denied && calls === 400);
});
