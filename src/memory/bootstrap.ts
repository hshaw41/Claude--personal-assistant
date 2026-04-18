import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const MEMORY_TEMPLATE = `# MEMORY

Long-term facts, preferences, and decisions. Claude reads this at the start of every session and appends to it when learning something durable.

## About Me

<!-- Name, role, location, context. Example: "Lives in Berlin, works as a software engineer, has a dog named Pip." -->

## Preferences

<!-- How the user likes things. Example: "Prefers concise replies. TypeScript over JavaScript. Dark mode everywhere." -->

## People

<!-- Important people and how they relate. Example: "Alex — co-founder of Acme, lives in NYC." -->

## Ongoing Projects

<!-- Active projects and their current state. Example: "Always-on assistant — MVP shipped 2026-04." -->

## Decisions

<!-- Durable decisions worth remembering, dated. Example: "2026-04-18: chose grammy over telegraf for Telegram adapter." -->
`;

export function bootstrapMemory(memoryDir: string): void {
  mkdirSync(memoryDir, { recursive: true });
  const memoryFile = resolve(memoryDir, "MEMORY.md");
  if (!existsSync(memoryFile)) {
    writeFileSync(memoryFile, MEMORY_TEMPLATE, "utf8");
  }
}
