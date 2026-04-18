import type { SessionStore } from "./session-store.js";

export interface RouteDecision {
  resumeSessionId?: string;
}

export class SessionRouter {
  constructor(
    private readonly store: SessionStore,
    private readonly ttlMs: number,
  ) {}

  route(threadKey: string): RouteDecision {
    const row = this.store.get(threadKey);
    if (!row) return {};
    const age = Date.now() - row.last_touched;
    if (age < this.ttlMs) {
      return { resumeSessionId: row.session_id };
    }
    return {};
  }

  record(threadKey: string, sessionId: string): void {
    this.store.upsert(threadKey, sessionId);
  }
}

export function makeThreadKey(chatId: number, userId: number): string {
  return `${chatId}:${userId}`;
}
