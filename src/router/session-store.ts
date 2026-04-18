import Database from "better-sqlite3";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";

export interface SessionRow {
  thread_key: string;
  session_id: string;
  last_touched: number;
}

export class SessionStore {
  private readonly db: Database.Database;
  private readonly selectStmt: Database.Statement<[string], SessionRow>;
  private readonly upsertStmt: Database.Statement<[string, string, number]>;

  constructor(dbPath: string) {
    mkdirSync(dirname(dbPath), { recursive: true });
    this.db = new Database(dbPath);
    this.db.pragma("journal_mode = WAL");
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        thread_key TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        last_touched INTEGER NOT NULL
      );
    `);
    this.selectStmt = this.db.prepare(
      "SELECT thread_key, session_id, last_touched FROM sessions WHERE thread_key = ?",
    );
    this.upsertStmt = this.db.prepare(`
      INSERT INTO sessions (thread_key, session_id, last_touched)
      VALUES (?, ?, ?)
      ON CONFLICT(thread_key) DO UPDATE SET
        session_id = excluded.session_id,
        last_touched = excluded.last_touched
    `);
  }

  get(threadKey: string): SessionRow | undefined {
    return this.selectStmt.get(threadKey);
  }

  upsert(threadKey: string, sessionId: string): void {
    this.upsertStmt.run(threadKey, sessionId, Date.now());
  }

  close(): void {
    this.db.close();
  }
}
