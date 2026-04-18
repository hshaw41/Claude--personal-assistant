import "dotenv/config";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
export const PROJECT_ROOT = resolve(here, "..");

function required(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === "") {
    throw new Error(`Missing required env var: ${name}`);
  }
  return value;
}

function parseIdList(raw: string | undefined): Set<number> {
  if (!raw) return new Set();
  return new Set(
    raw
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean)
      .map((s) => {
        const n = Number(s);
        if (!Number.isFinite(n)) {
          throw new Error(`Invalid user ID in ALLOWED_USER_IDS: ${s}`);
        }
        return n;
      }),
  );
}

export const config = {
  telegramBotToken: required("TELEGRAM_BOT_TOKEN"),
  anthropicApiKey: process.env.ANTHROPIC_API_KEY,
  allowedUserIds: parseIdList(process.env.ALLOWED_USER_IDS),
  ownerChatId: process.env.OWNER_CHAT_ID ? Number(process.env.OWNER_CHAT_ID) : undefined,
  logLevel: process.env.LOG_LEVEL ?? "info",
  projectRoot: PROJECT_ROOT,
  dataDir: resolve(PROJECT_ROOT, "data"),
  memoryDir: resolve(PROJECT_ROOT, "memory"),
  sessionTtlMs: 2 * 60 * 60 * 1000,
} as const;
