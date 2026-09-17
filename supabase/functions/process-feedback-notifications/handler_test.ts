import {
  classifyProviderResponse,
  constantTimeEqual,
  buildMessage,
  createHandler,
  processNotifications,
} from "./index.ts";
import type {
  ClaimedNotification,
  EmailMessage,
  EmailProvider,
  FeedbackPayload,
  SendResult,
  WorkerDatabase,
} from "./types.ts";

function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}`);
  }
}

const feedback: FeedbackPayload = {
  category: "suggestion",
  title: "제목\n제목",
  body: "본문 <tag> 😀",
  created_at: "2026-09-17T00:00:00Z",
  app_version: "0.1.0",
  build_number: "1",
  platform: "ios",
  os_version: "26.4.2",
  locale: "ko-KR",
};

class FakeDatabase implements WorkerDatabase {
  constructor(private readonly jobs: ClaimedNotification[]) {}
  completed: string[] = [];
  failures: string[] = [];
  async reclaimExpiredLeases() { return 0; }
  async claim(_batchSize: number) { return this.jobs; }
  async feedback(_feedbackId: string) { return feedback; }
  async complete(notificationId: string, _claimToken: string) {
    this.completed.push(notificationId);
    return true;
  }
  async fail(notificationId: string, _claimToken: string, code: string, retryable: boolean) {
    this.failures.push(`${notificationId}:${code}:${retryable}`);
    return true;
  }
}

class FakeProvider implements EmailProvider {
  messages: EmailMessage[] = [];
  keys: string[] = [];
  constructor(private readonly result: SendResult = { ok: true }) {}
  async send(message: EmailMessage, key: string) {
    this.messages.push(message);
    this.keys.push(key);
    return this.result;
  }
}

Deno.test("worker rejects missing or wrong invocation secret before DB access", async () => {
  let claimed = false;
  const database = new FakeDatabase([]);
  database.claim = async (_batchSize: number) => {
    claimed = true;
    return [];
  };
  const handler = createHandler({
    secret: "expected",
    recipient: "admin@example.invalid",
    sender: "feedback@example.invalid",
    database,
    provider: new FakeProvider(),
  });
  equal((await handler(new Request("https://example.invalid", { method: "GET" }))).status, 405);
  equal((await handler(new Request("https://example.invalid", { method: "POST" }))).status, 403);
  equal((await handler(new Request("https://example.invalid", {
    method: "POST",
    headers: { "x-feedback-worker-secret": "wrong" },
  }))).status, 403);
  equal(claimed, false);
});

Deno.test("successful job uses bounded batch, plain text and stable idempotency", async () => {
  const database = new FakeDatabase([{
    notification_id: "notification-1",
    feedback_id: "feedback-1",
    claim_token: "claim-1",
    attempt_count: 1,
  }]);
  const provider = new FakeProvider();
  const result = await processNotifications({
    secret: "expected",
    recipient: "admin@example.invalid",
    sender: "feedback@example.invalid",
    database,
    provider,
    batchSize: 10,
  });
  equal(result, { claimed: 1, sent: 1, failed: 0 });
  equal(database.completed, ["notification-1"]);
  equal(provider.keys, ["feedback-email/feedback-1"]);
  equal(provider.messages[0].subject, "[LegendStudy] 새 문의 — 기능 제안");
  equal(provider.messages[0].text.includes("<tag>"), true);
});

Deno.test("temporary and permanent provider outcomes are classified", () => {
  equal(classifyProviderResponse(429), { ok: false, errorCode: "rate_limited", retryable: true });
  equal(classifyProviderResponse(500), { ok: false, errorCode: "provider_5xx", retryable: true });
  equal(classifyProviderResponse(400), { ok: false, errorCode: "provider_rejected", retryable: false });
  equal(classifyProviderResponse(200), { ok: true });
});

Deno.test("secret comparison is constant-length safe", () => {
  equal(constantTimeEqual("same", "same"), true);
  equal(constantTimeEqual("same", "different"), false);
  equal(constantTimeEqual("", ""), true);
});

Deno.test("message contains only the approved operational fields", () => {
  const message = buildMessage(feedback, "admin@example.invalid", "feedback@example.invalid", "feedback-1");
  equal(message.to, "admin@example.invalid");
  equal(message.from, "feedback@example.invalid");
  equal(message.text.includes("JWT"), false);
  equal(message.text.includes("access_token"), false);
  equal(message.text.includes("feedback-1"), true);
});
