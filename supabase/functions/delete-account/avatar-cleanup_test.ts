import { deleteAvatarBeforeAccount } from "./avatar-cleanup.ts";
Deno.test("exact own avatar deleted before account, including absent object", async () => {
  const calls: string[] = [];
  const result = await deleteAvatarBeforeAccount("owner-a", async (paths) => {
    if (JSON.stringify(paths) !== '["owner-a/avatar.png"]') throw Error("path");
    calls.push("storage");
    return { error: null };
  }, async () => {
    calls.push("account");
    return true;
  });
  if (!result || calls.join() !== "storage,account") throw Error("order");
});
Deno.test("storage failure blocks user deletion and is retryable", async () => {
  let deleted = false;
  try {
    await deleteAvatarBeforeAccount(
      "owner-a",
      async () => ({ error: true }),
      async () => {
        deleted = true;
        return true;
      },
    );
    throw Error("expected failure");
  } catch (error) {
    if (
      !(error instanceof Error) || error.message !== "avatar_cleanup_failed" ||
      deleted
    ) throw Error("unsafe deletion");
  }
});
