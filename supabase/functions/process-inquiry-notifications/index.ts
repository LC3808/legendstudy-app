/**
 * ADMIN-P0-B — 1:1 문의 답변 알림 워커.
 *
 * The LAB console never sends mail itself: registering a reply only enqueues a
 * row on `public.inquiry_notifications`, and this worker drains that queue with
 * the same claim/complete/retry shape the feedback worker already uses. The
 * Resend provider is the same one, so there is no second mail path to operate.
 *
 * The reply body is delivered to the member, which is why this worker reads it
 * through `complete_inquiry_notification`'s companion view rather than trusting
 * anything from the caller.
 */
import { createClient } from "npm:@supabase/supabase-js@2";

const BATCH_SIZE = 10;
const INVOCATION_HEADER = "x-inquiry-worker-secret";
const RESEND_ENDPOINT = "https://api.resend.com/emails";
const DEFAULT_SENDER = "LegendStudy <no-reply@legendstudy.com>";
const MAX_BODY = 8000;

type ClaimedNotification = {
  notification_id: string;
  inquiry_id: string;
  reply_id: string;
  member_id: string;
  member_email: string | null;
  member_display_name: string | null;
  category: string;
  title: string;
  body: string;
  claim_token: string;
  attempt_count: number;
};

type SendResult = { ok: true } | { ok: false; errorCode: string; retryable: boolean };

const json = (status: number, body: unknown): Response =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });

export const constantTimeEqual = (left: string, right: string): boolean => {
  const a = new TextEncoder().encode(left);
  const b = new TextEncoder().encode(right);
  let difference = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let index = 0; index < length; index++) {
    difference |= (a[index] ?? 0) ^ (b[index] ?? 0);
  }
  return difference === 0;
};

export const classifyProviderResponse = (status: number): SendResult => {
  if (status >= 200 && status < 300) return { ok: true };
  if (status === 429) return { ok: false, errorCode: "rate_limited", retryable: true };
  if (status >= 500) return { ok: false, errorCode: "provider_5xx", retryable: true };
  if (status === 400 || status === 422) {
    return { ok: false, errorCode: "provider_rejected", retryable: false };
  }
  return { ok: false, errorCode: "unknown", retryable: false };
};

/**
 * The member-facing message.
 *
 * The subject carries no personal data beyond the inquiry title, and the body
 * tells the member where to reply if the mail is not enough. No internal
 * identifier is exposed.
 */
export const buildMessage = (
  claimed: ClaimedNotification,
  sender: string,
): { to: string; from: string; subject: string; text: string } => {
  const greeting = claimed.member_display_name ? `${claimed.member_display_name}님, 안녕하세요.` : "안녕하세요.";
  return {
    to: claimed.member_email as string,
    from: sender,
    subject: `[LegendStudy] 문의하신 내용에 답변이 등록되었습니다`,
    text: [
      greeting,
      "",
      "문의하신 내용에 답변이 등록되었습니다.",
      "",
      `문의 제목: ${claimed.title}`,
      "",
      "── 답변 ──",
      claimed.body.slice(0, MAX_BODY),
      "",
      "추가로 궁금한 점이 있으면 고객센터 1:1 문의로 남겨 주세요.",
      "https://lab.legendstudy.com/support/inquiry/",
      "",
      "감사합니다.",
      "레전드스터디 랩 고객센터",
    ].join("\n"),
  };
};

export type WorkerDependencies = {
  env: Record<string, string | undefined>;
  fetchImpl?: typeof fetch;
  now?: () => number;
};

export function createHandler({ env, fetchImpl = fetch }: WorkerDependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") return json(405, { error: "method" });

    const secret = env.INQUIRY_WORKER_SECRET;
    if (!secret) return json(503, { error: "unconfigured" });
    const provided = request.headers.get(INVOCATION_HEADER) ?? "";
    if (!constantTimeEqual(provided, secret)) return json(401, { error: "unauthorized" });

    const supabaseUrl = env.SUPABASE_URL;
    const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY;
    const resendKey = env.RESEND_API_KEY;
    if (!supabaseUrl || !serviceKey || !resendKey) return json(503, { error: "unconfigured" });

    const sender = env.INQUIRY_MAIL_FROM?.trim() || DEFAULT_SENDER;
    const database = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await database.rpc("claim_inquiry_notifications", {
      p_limit: BATCH_SIZE,
    });
    if (error) return json(500, { error: "claim_failed" });

    const claimed = (data ?? []) as ClaimedNotification[];
    let sent = 0;
    let failed = 0;
    let skipped = 0;

    for (const item of claimed) {
      // A member without an address cannot be mailed; the delivery is completed
      // as a permanent failure so the queue does not retry it forever.
      if (!item.member_email) {
        await database.rpc("complete_inquiry_notification", {
          p_notification: item.notification_id,
          p_token: item.claim_token,
          p_ok: false,
          p_error: "no_recipient",
        });
        skipped += 1;
        continue;
      }

      const message = buildMessage(item, sender);
      let result: SendResult;
      try {
        const response = await fetchImpl(RESEND_ENDPOINT, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${resendKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: message.from,
            to: [message.to],
            subject: message.subject,
            text: message.text,
          }),
        });
        result = classifyProviderResponse(response.status);
      } catch {
        result = { ok: false, errorCode: "network", retryable: true };
      }

      await database.rpc("complete_inquiry_notification", {
        p_notification: item.notification_id,
        p_token: item.claim_token,
        p_ok: result.ok,
        p_error: result.ok ? null : result.errorCode,
      });

      if (result.ok) sent += 1;
      else failed += 1;
    }

    // Only counts leave the worker: no address, subject or body is ever logged.
    return json(200, { claimed: claimed.length, sent, failed, skipped });
  };
}

Deno.serve(createHandler({ env: Deno.env.toObject() }));
