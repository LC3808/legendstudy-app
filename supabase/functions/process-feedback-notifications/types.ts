export type FeedbackCategory = "inquiry" | "bug" | "suggestion" | "other";

export type ClaimedNotification = {
  notification_id: string;
  feedback_id: string;
  claim_token: string;
  attempt_count: number;
};

export type FeedbackPayload = {
  category: FeedbackCategory;
  title: string;
  body: string;
  created_at: string;
  app_version: string;
  build_number: string;
  platform: string;
  os_version: string;
  locale: string | null;
};

export type EmailMessage = {
  to: string;
  from: string;
  subject: string;
  text: string;
};

export type SendResult =
  | { ok: true }
  | { ok: false; errorCode: ErrorCode; retryable: boolean };

export type ErrorCode =
  | "network"
  | "timeout"
  | "rate_limited"
  | "provider_5xx"
  | "provider_rejected"
  | "invalid_config"
  | "invalid_recipient"
  | "unknown";

export interface EmailProvider {
  send(message: EmailMessage, idempotencyKey: string): Promise<SendResult>;
}

export interface WorkerDatabase {
  claim(batchSize: number): Promise<ClaimedNotification[]>;
  feedback(feedbackId: string): Promise<FeedbackPayload | null>;
  complete(notificationId: string, claimToken: string): Promise<boolean>;
  fail(
    notificationId: string,
    claimToken: string,
    errorCode: ErrorCode,
    retryable: boolean,
  ): Promise<boolean>;
  reclaimExpiredLeases(): Promise<number>;
}
