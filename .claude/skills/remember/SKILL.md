---
name: remember
description: Append a durable fact to memory/MEMORY.md. Invoke when the user says "/remember <fact>" or "remember that ...".
---

# /remember

When the user invokes this skill, they want a fact pinned to long-term memory.

## Steps

1. **Read** `memory/MEMORY.md`.
2. **Pick the right section** for the fact:
   - `## About Me` — name, role, location, background
   - `## Preferences` — how the user likes things done
   - `## People` — someone in the user's life
   - `## Ongoing Projects` — active work, state, next steps
   - `## Decisions` — durable choices worth remembering
   - If none fit, create a new `## <Topic>` section at the bottom.
3. **Append a dated bullet** under that section in the form:
   `- YYYY-MM-DD: <fact in one sentence>`
   Use today's date. Keep the fact concise and self-contained — a future session should understand it without context.
4. **Edit** `memory/MEMORY.md` with the new bullet.
5. **Reply** to the user with just the appended line, e.g. `Remembered: 2026-04-18: prefers TypeScript over JavaScript.`

## Notes

- If the same fact (or a close duplicate) already exists, say so and don't append a duplicate.
- If the fact contradicts an earlier entry, add the new one and leave the old one in place — don't rewrite history.
