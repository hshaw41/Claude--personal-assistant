# Always-On Personal AI Assistant

A personal AI assistant that runs 24/7 on a VPS, reachable via Telegram, powered by Claude Code via the [Claude Agent SDK](https://www.npmjs.com/package/@anthropic-ai/claude-agent-sdk). Sessions are thread-sticky within a 2-hour window; memory is persisted to markdown files that Claude reads and writes directly.

Architecture and design decisions live in `CLAUDE.md` and the [project brief](#).

## Stack

- Node.js 22 + TypeScript
- `@anthropic-ai/claude-agent-sdk` — Claude Code as a library
- `grammy` — Telegram bot framework (long polling)
- `better-sqlite3` — session → session-id mapping
- `pino` — structured logging

## Phone-only bootstrap

This project assumes the operator has only a phone available. Everything below can be done from the GitHub mobile web UI + a Telegram client + one SSH app (e.g. Termius, Blink, JuiceSSH).

### 1. Create the Telegram bot

1. Message [@BotFather](https://t.me/BotFather) → `/newbot` → follow prompts → copy the token.
2. Message [@userinfobot](https://t.me/userinfobot) → copy your numeric user ID.

### 2. Provision the VPS

Hetzner CX22 (~€4/mo) running Ubuntu 24.04 is known to work. Add your SSH public key via the Hetzner web console, SSH in, then paste:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Node.js 22 + build tools
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs git build-essential sqlite3

# Claude Code CLI (optional but useful for debugging)
curl -fsSL https://claude.ai/install.sh | bash

# Dedicated service user
sudo useradd -m -s /bin/bash assistant
sudo -iu assistant bash -c 'mkdir -p ~/.ssh && cat /root/.ssh/authorized_keys >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'

# Clone the repo as the assistant user
sudo -iu assistant git clone https://github.com/YOUR_USER/Claude--personal-assistant.git always-on-assistant

# Install deps + build
sudo -iu assistant bash -lc 'cd ~/always-on-assistant && npm ci && npm run build'

# Allow the assistant user to restart its own service without a password
echo 'assistant ALL=(ALL) NOPASSWD: /bin/systemctl restart assistant, /bin/systemctl status assistant, /bin/systemctl is-active assistant' | sudo tee /etc/sudoers.d/assistant
sudo chmod 440 /etc/sudoers.d/assistant
```

### 3. Authenticate Claude (pick one)

**Option A — Claude Pro/Max subscription (recommended if you have one):**
```bash
sudo -iu assistant claude login
```
Open the URL it prints on your phone, sign in, paste the code back. Subject to your plan's weekly usage caps.

**Option B — Anthropic API key (pay-per-use):** get one from https://console.anthropic.com/ and set it as `ANTHROPIC_API_KEY` in `.env` below.

### 4. Configure `.env` on the VPS

```bash
sudo -iu assistant bash -lc 'cd ~/always-on-assistant && cp .env.example .env && nano .env'
```

Fill in:

- `TELEGRAM_BOT_TOKEN` — from BotFather
- `ANTHROPIC_API_KEY` — leave blank if you used Option A; set if you used Option B
- `ALLOWED_USER_IDS` — your numeric user ID from @userinfobot (comma-separated for multiple)
- `OWNER_CHAT_ID` — usually same as your user ID; gets deploy notifications and crash alerts

### 5. Install the systemd service

```bash
sudo cp /home/assistant/always-on-assistant/systemd/assistant.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now assistant
sudo systemctl status assistant
```

You should now be able to message the bot on Telegram and get a reply.

### 6. Wire up GitHub Actions auto-deploy

Add these secrets to the repo (GitHub mobile web → Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `VPS_HOST` | VPS IP or hostname |
| `VPS_USER` | `assistant` |
| `VPS_SSH_KEY` | Private SSH key with access to the `assistant` user (generate a dedicated deploy key on the VPS and add its public half to `/home/assistant/.ssh/authorized_keys`) |
| `TELEGRAM_BOT_TOKEN` | Same as in `.env` (used by the workflow to DM deploy results) |
| `OWNER_CHAT_ID` | Same as in `.env` |

From now on, every push to `main` → VPS pulls, rebuilds, restarts → bot DMs `✅ Deployed`.

## Project layout

```
always-on-assistant/
├── CLAUDE.md                         # Auto-loaded operating brief for Claude
├── src/
│   ├── index.ts                      # Entry point
│   ├── config.ts                     # Env + constants
│   ├── logger.ts                     # pino
│   ├── engine/claude.ts              # Claude Agent SDK wrapper
│   ├── router/                       # Thread-sticky session routing
│   ├── gateway/telegram.ts           # grammy bot
│   └── memory/bootstrap.ts           # Creates MEMORY.md on first run
├── memory/                           # MEMORY.md lives here (gitignored contents after write)
├── .claude/skills/remember/          # /remember skill
├── systemd/assistant.service         # systemd unit template
├── scripts/deploy.sh                 # VPS deploy script
└── .github/workflows/deploy.yml      # Auto-deploy on push to main
```

## Operating notes

- Sessions resume if the same (chat, user) sends another message within 2 hours; otherwise a fresh Claude Code session starts. Memory files (`memory/MEMORY.md`) carry durable state across sessions.
- The `/remember <fact>` skill forces a memory write. Claude is also instructed to write memory proactively when it learns something durable.
- Errors surface back to Telegram as `⚠️ Error: …` messages. `journalctl -u assistant -f` over SSH shows the full log stream if deeper forensics are needed.
- Weekly Claude usage caps on the subscription/API are the real operating ceiling — watch for them in logs if replies start failing.

## Phase 2 (not yet built)

Scheduler, subagent dispatch, multi-channel (WhatsApp/Discord), MCP integrations (Notion, Gmail), admin Telegram commands (`/status`, `/sessions`, `/compact`).
