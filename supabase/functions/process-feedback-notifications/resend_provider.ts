import type { EmailMessage, EmailProvider, SendResult } from "./types.ts";

export class ResendEmailProvider implements EmailProvider {
  constructor(
    private readonly apiKey: string,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async send(message: EmailMessage, idempotencyKey: string): Promise<SendResult> {
    try {
      const response = await this.fetcher("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.apiKey}`,
          "Idempotency-Key": idempotencyKey,
        },
        body: JSON.stringify({
          from: message.from,
          to: [message.to],
          subject: message.subject,
          text: message.text,
        }),
        signal: AbortSignal.timeout(10000),
      });
      if (response.ok) return { ok: true };
      if (response.status === 429) {
        return { ok: false, errorCode: "rate_limited", retryable: true };
      }
      if (response.status >= 500) {
        return { ok: false, errorCode: "provider_5xx", retryable: true };
      }
      if (response.status === 400 || response.status === 422) {
        return { ok: false, errorCode: "provider_rejected", retryable: false };
      }
      return { ok: false, errorCode: "unknown", retryable: false };
    } catch (error) {
      const name = error instanceof Error ? error.name : "";
      return {
        ok: false,
        errorCode: name === "AbortError" || name === "TimeoutError"
          ? "timeout"
          : "network",
        retryable: true,
      };
    }
  }
}
