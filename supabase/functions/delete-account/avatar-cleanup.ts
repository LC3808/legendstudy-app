// Candidate only. Delete through the Storage API, never SQL-delete metadata.
// A private avatar object can prevent auth user deletion while still owned.
export async function deleteAvatarBeforeAccount(
  owner: string,
  remove: (paths: string[]) => Promise<{ error: unknown }>,
  deleteAccount: () => Promise<boolean>,
): Promise<boolean> {
  const { error } = await remove([`${owner}/avatar.png`]);
  if (error) throw new Error("avatar_cleanup_failed");
  return await deleteAccount();
}
