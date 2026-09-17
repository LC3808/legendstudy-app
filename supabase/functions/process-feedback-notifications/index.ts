import { createClient } from "npm:@supabase/supabase-js@2";
import { ResendEmailProvider } from "./resend_provider.ts";
import type {
  ClaimedNotification,
  FeedbackPayload,
  SendResult,
  WorkerDatabase,
} from "./types.ts";
import type { EmailMessage, EmailProvider } from "./types.ts";

const BATCH_SIZE = 10;
const INVOCATION_HEADER = "x-feedback-worker-secret";
const categoryLabels: Record<string, string> = {
  inquiry: "문의",
  bug: "오류 신고",
  suggestion: "기능 제안",
  other: "기타",
};

const json = (status: number, body: unknown) =>
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

export const buildMessage = (
  feedback: FeedbackPayload,
  recipient: string,
  sender: string,
  feedbackId: string,
): EmailMessage => ({
  to: recipient,
  from: sender,
  subject: `[LegendStudy] 새 문의 — ${categoryLabels[feedback.category] ?? "기타"}`,
  text: [
    "LegendStudy 새 문의",
    "",
    `유형: ${categoryLabels[feedback.category] ?? "기타"}`,
    `제목: ${feedback.title}`,
    `내용: ${feedback.body}`,
    `접수 시각: ${feedback.created_at}`,
    `앱 버전: ${feedback.app_version}`,
    `빌드 번호: ${feedback.build_number}`,
    `플랫폼: ${feedback.platform}`,
    `OS: ${feedback.os_version}`,
    `locale: ${feedback.locale ?? "-"}`,
    `Feedback ID: ${feedbackId}`,
  ].join("\n"),
});

export const classifyProviderResponse = (status: number): SendResult => {
  if (status >= 200 && status < 300) return { ok: true };
  if (status === 429) return { ok: false, errorCode: "rate_limited", retryable: true };
  if (status >= 500) return { ok: false, errorCode: "provider_5xx", retryable: true };
  if (status === 400 || status === 422) {
    return { ok: false, errorCode: "provider_rejected", retryable: false };
  }
  return { ok: false, errorCode: "unknown", retryable: false };
};

export const createSupabaseDatabase = (
  url: string,
  serviceRoleKey: string,
): WorkerDatabase => {
  const client = createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  return {
    async claim(batchSize) {
      const { data, error } = await client.rpc("claim_feedback_notifications", {
        p_batch_size: batchSize,
      });
      if (error) throw new Error("claim_failed");
      return (data ?? []) as ClaimedNotification[];
    },
    async feedback(feedbackId) {
      const { data, error } = await client
        .from("feedback_submissions")
        .select("category,title,body,created_at,app_version,build_number,platform,os_version,locale")
        .eq("id", feedbackId)
        .single();
      if (error) throw new Error("feedback_read_failed");
      return data as FeedbackPayload;
    },
    async complete(notificationId, claimToken) {
      const { data, error } = await client.rpc("complete_feedback_notification", {
        p_notification_id: notificationId,
        p_claim_token: claimToken,
      });
      if (error) throw new Error("complete_failed");
      return data === true;
    },
    async fail(notificationId, claimToken, errorCode, retryable) {
      const { data, error } = await client.rpc("fail_feedback_notification", {
        p_notification_id: notificationId,
        p_claim_token: claimToken,
        p_error_code: errorCode,
        p_retryable: retryable,
      });
      if (error) throw new Error("fail_failed");
      return data === true;
    },
    async reclaimExpiredLeases() {
      const { data, error } = await client.rpc("reclaim_feedback_notification_leases");
      if (error) throw new Error("reclaim_failed");
      return Number(data ?? 0);
    },
  };
};

export type WorkerDependencies = {
  secret: string | undefined;
  recipient: string | undefined;
  sender: string | undefined;
  database: WorkerDatabase;
  provider: EmailProvider;
  batchSize?: number;
};

export const processNotifications = async (
  dependencies: WorkerDependencies,
): Promise<{ claimed: number; sent: number; failed: number }> => {
  const reclaimed = await dependencies.database.reclaimExpiredLeases();
  if (reclaimed > 0) console.log(JSON.stringify({ event: "leases_reclaimed", count: reclaimed }));
  const jobs = await dependencies.database.claim(dependencies.batchSize ?? BATCH_SIZE);
  let sent = 0;
  let failed = 0;
  for (const job of jobs) {
    const feedback = await dependencies.database.feedback(job.feedback_id);
    if (!feedback) {
      await dependencies.database.fail(job.notification_id, job.claim_token, "unknown", false);
      failed++;
      continue;
    }
    const result = await dependencies.provider.send(
      buildMessage(feedback, dependencies.recipient!, dependencies.sender!, job.feedback_id),
      `feedback-email/${job.feedback_id}`,
    );
    if (result.ok) {
      if (await dependencies.database.complete(job.notification_id, job.claim_token)) sent++;
    } else {
      if (await dependencies.database.fail(job.notification_id, job.claim_token, result.errorCode, result.retryable)) failed++;
    }
    console.log(JSON.stringify({
      event: result.ok ? "notification_sent" : "notification_failed",
      notification_id: job.notification_id,
      feedback_id: job.feedback_id,
      attempt: job.attempt_count,
      status: result.ok ? "sent" : "failed",
      error_code: result.ok ? undefined : result.errorCode,
    }));
  }
  return { claimed: jobs.length, sent, failed };
};

export const createHandler = (dependencies: WorkerDependencies) =>
  async (request: Request): Promise<Response> => {
    if (request.method !== "POST") return json(405, { error: "method_not_allowed" });
    const suppliedSecret = request.headers.get(INVOCATION_HEADER) ?? "";
    if (!dependencies.secret || !constantTimeEqual(suppliedSecret, dependencies.secret)) {
      return json(403, { error: "forbidden" });
    }
    if (!dependencies.recipient || !dependencies.sender) {
      return json(503, { error: "configuration_unavailable" });
    }
    try {
      return json(200, await processNotifications(dependencies));
    } catch (_) {
      return json(500, { error: "worker_failed" });
    }
  };

const secret = Deno.env.get("FEEDBACK_WORKER_SECRET");
const recipient = Deno.env.get("LEGENDSTUDY_ADMIN_EMAIL");
const sender = Deno.env.get("LEGENDSTUDY_EMAIL_FROM");
const resendKey = Deno.env.get("RESEND_API_KEY");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (import.meta.main) {
  if (!resendKey || !supabaseUrl || !serviceRoleKey) {
    Deno.serve(() => json(503, { error: "configuration_unavailable" }));
  } else {
    Deno.serve(createHandler({
      secret,
      recipient,
      sender,
      database: createSupabaseDatabase(supabaseUrl, serviceRoleKey),
      provider: new ResendEmailProvider(resendKey),
    }));
  }
}
