import { query } from "@anthropic-ai/claude-agent-sdk";
import { logger } from "../logger.js";

export interface AskInput {
  message: string;
  resumeSessionId?: string;
  cwd: string;
}

export interface AskResult {
  reply: string;
  sessionId: string;
}

export async function ask(input: AskInput): Promise<AskResult> {
  const { message, resumeSessionId, cwd } = input;

  const stream = query({
    prompt: message,
    options: {
      cwd,
      resume: resumeSessionId,
      permissionMode: "bypassPermissions",
    },
  });

  let sessionId: string | undefined;
  let finalReply: string | undefined;
  const textChunks: string[] = [];

  for await (const event of stream) {
    const e = event as unknown as Record<string, unknown>;

    if (e.type === "system" && e.subtype === "init" && typeof e.session_id === "string") {
      sessionId = e.session_id;
      continue;
    }

    if (e.type === "assistant" && e.message && typeof e.message === "object") {
      const msg = e.message as { content?: Array<{ type: string; text?: string }> };
      for (const block of msg.content ?? []) {
        if (block.type === "text" && typeof block.text === "string") {
          textChunks.push(block.text);
        }
      }
      continue;
    }

    if (e.type === "result") {
      if (typeof e.session_id === "string") sessionId ??= e.session_id;
      if (typeof e.result === "string") finalReply = e.result;
      if (e.subtype && e.subtype !== "success") {
        logger.warn({ subtype: e.subtype }, "Claude result was not success");
      }
    }
  }

  if (!sessionId) {
    throw new Error("Claude SDK did not return a session_id");
  }

  const reply = (finalReply ?? textChunks.join("")).trim();
  if (!reply) {
    throw new Error("Claude returned an empty reply");
  }

  return { reply, sessionId };
}
