import { resolve } from "node:path";
import { config } from "./config.js";
import { logger } from "./logger.js";
import { bootstrapMemory } from "./memory/bootstrap.js";
import { SessionStore } from "./router/session-store.js";
import { SessionRouter } from "./router/session-router.js";
import { createGateway } from "./gateway/telegram.js";

async function main(): Promise<void> {
  bootstrapMemory(config.memoryDir);

  const store = new SessionStore(resolve(config.dataDir, "sessions.db"));
  const router = new SessionRouter(store, config.sessionTtlMs);

  const bot = createGateway({
    botToken: config.telegramBotToken,
    allowedUserIds: config.allowedUserIds,
    ownerChatId: config.ownerChatId,
    router,
    cwd: config.projectRoot,
  });

  const shutdown = async (signal: string) => {
    logger.info({ signal }, "shutting down");
    try {
      await bot.stop();
    } catch (err) {
      logger.warn({ err }, "bot.stop failed");
    }
    store.close();
    process.exit(0);
  };
  process.on("SIGINT", () => void shutdown("SIGINT"));
  process.on("SIGTERM", () => void shutdown("SIGTERM"));

  logger.info(
    {
      allowedUsers: config.allowedUserIds.size,
      ownerChatId: config.ownerChatId,
      sessionTtlMs: config.sessionTtlMs,
    },
    "starting bot",
  );
  await bot.start({
    onStart: (info) => logger.info({ username: info.username }, "bot started"),
  });
}

main().catch((err) => {
  logger.fatal({ err }, "fatal startup error");
  process.exit(1);
});
