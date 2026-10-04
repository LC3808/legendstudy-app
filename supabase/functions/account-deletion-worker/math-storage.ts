import type { OwnedStorage } from "./storage.ts";
/** Recursive, bounded Storage API deletion, including objects without artifact rows.
 * Retry inventories the same prefix again; no SQL Storage deletes or detached paths. */
export async function eraseMathStorage(api: OwnedStorage, subject: string): Promise<void> {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(subject)) {
    throw Error("STORAGE_UNAVAILABLE");
  }
  let calls = 0;
  const walk = async (prefix: string, depth: number): Promise<void> => {
    if (depth > 5) throw Error("STORAGE_UNAVAILABLE");
    while (true) {
      if (++calls > 400) throw Error("STORAGE_UNAVAILABLE");
      const rows = await api.list("math-private", prefix, 100);
      if (!Array.isArray(rows) || rows.length > 100) throw Error("STORAGE_UNAVAILABLE");
      if (!rows.length) return;
      for (const row of rows) {
        if (!row || !row.name || row.name.includes("/") || row.name.includes("\\") ||
          row.name === "." || row.name === "..") throw Error("STORAGE_UNAVAILABLE");
      }
      const files = rows.filter(row => row.id !== null);
      if (files.length) await api.remove("math-private", files.map(row => `${prefix}/${row.name}`));
      for (const folder of rows.filter(row => row.id === null)) await walk(`${prefix}/${folder.name}`, depth + 1);
      // Re-list page zero after deletes: offsets would skip remaining objects.
    }
  };
  await walk(subject, 0);
}
