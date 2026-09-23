# Telegram Private Relay

繁體中文 | [日本語](README.ja.md) | [English](README.en.md)

版本：v1.0.0

這個 Bot 把 Telegram 私聊轉送到管理超級群組中每位使用者專屬的 Topic，管理者可直接回覆。未設定管理群組時，改用管理者私聊作為備用模式。以 Cloudflare Worker、D1 和 Telegram Webhook 運作；不儲存訊息文字或媒體內容。

## 準備

- Node.js 22 以上、pnpm、PowerShell 7、Cloudflare 帳號和 Telegram Bot Token。
- Topic 模式需要啟用話題的超級群組，Bot 須有傳送訊息及管理話題權限。
- `tools/*.ps1` 使用 Windows DPAPI 儲存本機加密憑證；在其他系統上可直接使用 Wrangler 並自行安全管理 Token。

## 部署

以下命令在工程目錄的 PowerShell 7 執行；若已在 `pwsh` 中，可直接執行 `./tools/` 下的腳本。

```powershell
pnpm install --frozen-lockfile
pnpm run check
Copy-Item wrangler.jsonc.example wrangler.jsonc
```

先在 `wrangler.jsonc` 設定自己的 Worker 名稱和 D1 名稱。建立新資料庫後，把傳回的 `database_id` 填入該檔；不要把真正的 ID 提交到 Git。既有資料庫請直接填入原 ID，勿重新建立。

```powershell
./tools/Save-CloudflareToken.ps1
./tools/Test-CloudflareToken.ps1
./tools/Invoke-WithCloudflareToken.ps1 d1 create YOUR_D1_NAME
./tools/Invoke-WithCloudflareToken.ps1 d1 migrations apply BOT_DB --remote --config wrangler.jsonc
./tools/Invoke-WithCloudflareToken.ps1 deploy --keep-vars --config wrangler.jsonc
```

Cloudflare API Token 需要 Workers Scripts Edit 和 D1 Edit 權限。加密副本只留在本機 `private-credentials/`。`wrangler.jsonc` 已被忽略；`keep_vars` 讓後續部署保留 Cloudflare 控制台中的設定。

在 Cloudflare Worker 的 Variables and Secrets 設定：

| 名稱 | 類型 | 說明 |
|---|---|---|
| `BOT_TOKEN` | Secret | 從 BotFather 取得 |
| `WEBHOOK_SECRET` | Secret | 使用下方腳本產生，與註冊 Webhook 使用同一值 |
| `ADMIN_USER_ID` | Text | 管理者的數字 Telegram User ID |
| `ADMIN_GROUP_ID` | Text，可選 | 啟用話題的超級群組 ID；省略則使用管理者私聊模式 |
| `WELCOME_MESSAGE` | Text，可選 | `/start` 的歡迎訊息 |
| `MESSAGE_INTERVAL_SECONDS` | Text，可選 | 一般訊息間隔，預設 2 秒，範圍 0–60 |

```powershell
./tools/New-WebhookSecret.ps1
./tools/Copy-WebhookSecret.ps1
# 貼入 Cloudflare Secret 並儲存後：
Set-Clipboard $null
./tools/Register-TelegramWebhook.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

最後一個腳本會隱藏輸入 Bot Token，並只訂閱 `message` 和 `edited_message`。已有 Secret 時，`New-WebhookSecret.ps1` 會拒絕覆寫；若要輪替，須同步更新 Cloudflare Secret 和 Telegram Webhook。

不知道群組 ID 時，可先註冊 Webhook，再由管理者在目標群組傳送 `/setup`，把 Bot 回覆的 ID 填入 `ADMIN_GROUP_ID` 並儲存部署。Webhook 尚未註冊時，可先在群組傳送訊息，再執行 `./tools/Get-TelegramChatIds.ps1`。

## 使用與檢查

使用者私聊 Bot；管理者在對應 Topic 回覆。支援文字、一般媒體、相簿和編輯同步；Telegram 不允許複製的訊息類型無法轉送。使用者可用 `/start`、`/id`；管理者可用 `/user`、`/block`、`/unblock`、`/close`、`/help`。

```powershell
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/health'
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/ready'
./tools/Get-TelegramWebhookInfo.ps1
./tools/Test-WorkerRuntime.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

`/ready` 檢查設定與 D1，不檢查 Telegram 權限。正式環境探針會送安全的測試更新並清除其 D1 紀錄；仍須用非管理者帳號實測「私聊 → Topic → 管理者回覆 → 使用者收到」。

## 使用 AI

把 repository 和這段文字交給 ChatGPT、Codex、Claude 等 coding agent：

> Read this repository before acting. It is a Telegram private-message relay built with a Cloudflare Worker, D1 migrations, and a Telegram webhook. Help me install, configure, deploy, troubleshoot, or make a requested change. Identify the files involved first and keep the current architecture. Deployment needs a Worker name, a D1 database ID, BOT_TOKEN, WEBHOOK_SECRET, ADMIN_USER_ID, and optionally ADMIN_GROUP_ID. Keep real credentials, IDs, domains, and local paths out of Git; use the example config and local secrets. Do not add dependencies or extra files without a concrete need. Ask only for missing required values, run the relevant checks, and summarize the result.
