import { Bot, GrammyError, HttpError } from "grammy";
import { ask } from "../engine/claude.js";
import type { SessionRouter } from "../router/session-router.js";
import { makeThreadKey } from "../router/session-router.js";
import { logger } from "../logger.js";

const TELEGRAM_MAX_MESSAGE = 4096;

export interface GatewayDeps {
  botToken: string;
  allowedUserIds: Set<number>;
  ownerChatId?: number;
  router: SessionRouter;
  cwd: string;
}

export function createGateway(deps: GatewayDeps): Bot {
  const bot = new Bot(deps.botToken);

  bot.on("message:text", async (ctx) => {
    const userId = ctx.from?.id;
    const chatId = ctx.chat.id;
    const text = ctx.message.text;

    if (!userId || !deps.allowedUserIds.has(userId)) {
      logger.warn({ userId, chatId }, "dropped message from non-allowed user");
      return;
    }

    const threadKey = makeThreadKey(chatId, userId);
    logger.info({ threadKey, len: text.length }, "incoming message");

    ctx.api.sendChatAction(chatId, "typing").catch(() => {});

    try {
      const { resumeSessionId } = deps.router.route(threadKey);
      const { reply, sessionId } = await ask({
        message: text,
        resumeSessionId,
        cwd: deps.cwd,
      });
      deps.router.record(threadKey, sessionId);
      await sendChunked(ctx, reply);
      logger.info({ threadKey, sessionId, resumed: !!resumeSessionId }, "replied");
    } catch (err) {
      const short = err instanceof Error ? err.message : String(err);
      logger.error({ err, threadKey }, "handler error");
      await ctx.reply(`⚠️ Error: ${truncate(short, 500)}`).catch(() => {});
    }
  });

  bot.catch((err) => {
    if (err.error instanceof GrammyError) {
      logger.error({ err: err.error }, "grammy API error");
    } else if (err.error instanceof HttpError) {
      logger.error({ err: err.error }, "grammy HTTP error");
    } else {
      logger.error({ err: err.error }, "grammy unknown error");
    }
  });

  if (deps.ownerChatId !== undefined) {
    installProcessFailureNotifier(bot, deps.ownerChatId);
  }

  return bot;
}

async function sendChunked(
  ctx: { reply: (text: string) => Promise<unknown> },
  text: string,
): Promise<void> {
  if (text.length <= TELEGRAM_MAX_MESSAGE) {
    await ctx.reply(text);
    return;
  }
  for (let i = 0; i < text.length; i += TELEGRAM_MAX_MESSAGE) {
    await ctx.reply(text.slice(i, i + TELEGRAM_MAX_MESSAGE));
  }
}

function truncate(s: string, max: number): string {
  return s.length <= max ? s : `${s.slice(0, max - 1)}…`;
}

function installProcessFailureNotifier(bot: Bot, ownerChatId: number): void {
  const notify = async (label: string, err: unknown) => {
    const msg = err instanceof Error ? err.message : String(err);
    try {
      await bot.api.sendMessage(ownerChatId, `💥 ${label}: ${truncate(msg, 500)}`);
    } catch {
      // best effort
    }
  };
  process.on("uncaughtException", async (err) => {
    logger.fatal({ err }, "uncaughtException");
    await notify("uncaughtException", err);
    process.exit(1);
  });
  process.on("unhandledRejection", async (reason) => {
    logger.fatal({ reason }, "unhandledRejection");
    await notify("unhandledRejection", reason);
    process.exit(1);
  });
}
