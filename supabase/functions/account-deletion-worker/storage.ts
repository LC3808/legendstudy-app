/** Current owned namespaces only. New personal buckets must register before use. */
export interface OwnedStorage {
  list(
    bucket: string,
    prefix: string,
    limit: number,
  ): Promise<{ name: string; id: string | null }[]>;
  remove(bucket: string, paths: string[]): Promise<void>;
}
export async function eraseOwnedStorage(
  api: OwnedStorage,
  subject: string,
): Promise<void> {
  if (!/^[0-9a-f-]{36}$/i.test(subject)) throw Error("STORAGE_UNAVAILABLE");
  // Current schema permits only this owner's single-level profile folder.
  const bucket = "profile-avatars";
  for (let batch = 0; batch < 20; batch++) {
    const rows = await api.list(bucket, subject, 100);
    if (rows.length === 0) return;
    if (
      rows.some((r) =>
        !r.id || r.name.includes("/") || r.name === "." || r.name === ".."
      )
    ) throw Error("STORAGE_UNAVAILABLE");
    await api.remove(bucket, rows.map((r) => `${subject}/${r.name}`));
  }
  throw Error("STORAGE_UNAVAILABLE"); // bounded resume; no metadata SQL deletes
}
