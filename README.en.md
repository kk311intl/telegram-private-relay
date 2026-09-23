# Telegram Private Relay

[繁體中文](README.md) | [日本語](README.ja.md) | English

Version: v1.0.0

This bot relays Telegram private messages to a separate topic for each user in an admin supergroup. The admin replies from that topic. Without a configured group, it falls back to the admin's private chat. It runs on a Cloudflare Worker with D1 and a Telegram webhook, and does not store message text or media content.

## Requirements

- Node.js 22 or newer, pnpm, PowerShell 7, a Cloudflare account, and a Telegram Bot Token.
- Topic mode requires a supergroup with topics enabled and permission for the bot to send messages and manage topics.
- `tools/*.ps1` store local encrypted credentials with Windows DPAPI. On other systems, use Wrangler directly and manage the token securely.

## Deploy

Run these commands from the project directory in PowerShell 7. If you are already in `pwsh`, you can run scripts under `./tools/` directly.

```powershell
pnpm install --frozen-lockfile
pnpm run check
Copy-Item wrangler.jsonc.example wrangler.jsonc
```

Set your Worker and D1 names in `wrangler.jsonc`. For a new database, put the returned `database_id` in that file; never commit the real ID. For an existing database, enter its ID and skip creation.

```powershell
./tools/Save-CloudflareToken.ps1
./tools/Test-CloudflareToken.ps1
./tools/Invoke-WithCloudflareToken.ps1 d1 create YOUR_D1_NAME
./tools/Invoke-WithCloudflareToken.ps1 d1 migrations apply BOT_DB --remote --config wrangler.jsonc
./tools/Invoke-WithCloudflareToken.ps1 deploy --keep-vars --config wrangler.jsonc
```

The Cloudflare API Token needs Workers Scripts Edit and D1 Edit. Its encrypted local copy stays under `private-credentials/`. Git ignores `wrangler.jsonc`; `keep_vars` preserves settings made in the Cloudflare dashboard on later deployments.

Set these under the Worker's Variables and Secrets in Cloudflare:

| Name | Type | Purpose |
|---|---|---|
| `BOT_TOKEN` | Secret | From BotFather |
| `WEBHOOK_SECRET` | Secret | Generated below; use the same value when registering the webhook |
| `ADMIN_USER_ID` | Text | The admin's numeric Telegram User ID |
| `ADMIN_GROUP_ID` | Text, optional | Supergroup ID with topics enabled; omit for admin private-chat mode |
| `WELCOME_MESSAGE` | Text, optional | Reply to `/start` |
| `MESSAGE_INTERVAL_SECONDS` | Text, optional | Minimum interval for ordinary messages; default 2 seconds, range 0–60 |

```powershell
./tools/New-WebhookSecret.ps1
./tools/Copy-WebhookSecret.ps1
# After pasting into the Cloudflare Secret field and saving:
Set-Clipboard $null
./tools/Register-TelegramWebhook.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

The last script prompts for the Bot Token without displaying it and subscribes to `message` and `edited_message` only. `New-WebhookSecret.ps1` refuses to overwrite an existing secret. If you rotate it, update the Cloudflare Secret and Telegram webhook together.

If you do not know the group ID, register the webhook, have the admin send `/setup` in the target group, then set the returned ID as `ADMIN_GROUP_ID` and save/deploy. Before webhook registration, you can send a group message and run `./tools/Get-TelegramChatIds.ps1` instead.

## Use and verify

Users message the bot privately; the admin replies in the matching topic. Text, ordinary media, albums, and edit syncing are supported. Telegram message types that cannot be copied cannot be relayed. Users can run `/start` and `/id`; the admin can run `/user`, `/block`, `/unblock`, `/close`, and `/help`.

```powershell
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/health'
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/ready'
./tools/Get-TelegramWebhookInfo.ps1
./tools/Test-WorkerRuntime.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

`/ready` checks configuration and D1, not Telegram permissions. The runtime probe sends a safe update and removes its D1 row. Also test the full flow with a non-admin account: private message → topic → admin reply → user receives the reply.

## Use with AI

Give this repository and prompt to ChatGPT, Codex, Claude, or another coding agent:

> Read this repository before acting. It is a Telegram private-message relay built with a Cloudflare Worker, D1 migrations, and a Telegram webhook. Help me install, configure, deploy, troubleshoot, or make a requested change. Identify the files involved first and keep the current architecture. Deployment needs a Worker name, a D1 database ID, BOT_TOKEN, WEBHOOK_SECRET, ADMIN_USER_ID, and optionally ADMIN_GROUP_ID. Keep real credentials, IDs, domains, and local paths out of Git; use the example config and local secrets. Do not add dependencies or extra files without a concrete need. Ask only for missing required values, run the relevant checks, and summarize the result.
