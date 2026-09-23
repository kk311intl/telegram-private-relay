# Telegram Private Relay

[中文](#zh) · [日本語](#ja) · [English](#en) · [AI 提示詞 / AI プロンプト / AI prompts](#ai)

Version: v1.0.1 · License: [GPL-3.0-only](LICENSE)

<a id="ai"></a>

## AI 提示詞 / AI プロンプト / AI prompts

把 repository 和適合的提示詞交給 ChatGPT、Codex、Claude 或其他 coding agent。

### 中文

> 請先閱讀這個 repository，再協助我安裝、設定、部署、排錯或修改。這是使用 Cloudflare Worker、D1 migrations 和 Telegram Webhook 的私聊轉送 Bot：每位使用者對應管理群組中的一個 Topic，也可改用管理者私聊模式。部署需要 Worker 名稱、D1 database ID、BOT_TOKEN、WEBHOOK_SECRET、ADMIN_USER_ID；ADMIN_GROUP_ID 可選。修改前先指出真正涉及的檔案，維持現有架構並只做必要改動。不要把真實 Token、ID、網域或本機路徑提交到 Git，請使用範例設定與本機憑證。只詢問缺少的必要值，完成後執行相關檢查並簡述結果。

### 日本語

> まずこの repository を読み、インストール、設定、デプロイ、問題調査、または依頼した変更を手伝ってください。これは Cloudflare Worker、D1 migrations、Telegram Webhook を使う私信転送 Bot です。ユーザーごとに管理グループのトピックを作り、管理者への私信モードも使えます。デプロイには Worker 名、D1 database ID、BOT_TOKEN、WEBHOOK_SECRET、ADMIN_USER_ID が必要で、ADMIN_GROUP_ID は省略できます。変更前に対象ファイルを特定し、既存の構成を保って必要最小限だけ変更してください。実際の Token、ID、ドメイン、ローカルパスを Git に入れず、サンプル設定とローカルの認証情報を使ってください。不足している必須項目だけ確認し、関連するチェックを実行して結果を簡潔に報告してください。

### English

> Read this repository before acting. It is a Telegram private-message relay built with a Cloudflare Worker, D1 migrations, and a Telegram webhook. Each user has a topic in an admin group, with an admin private-chat fallback. Help me install, configure, deploy, troubleshoot, or make a requested change. Deployment needs a Worker name, a D1 database ID, BOT_TOKEN, WEBHOOK_SECRET, ADMIN_USER_ID, and optionally ADMIN_GROUP_ID. Identify the files involved first and keep the current architecture. Keep real credentials, IDs, domains, and local paths out of Git; use the example config and local secrets. Ask only for missing required values, run the relevant checks, and summarize the result.

<a id="zh"></a>

## 中文

這個 Bot 把 Telegram 私聊轉送到管理超級群組中每位使用者專屬的 Topic，管理者可直接回覆。未設定管理群組時，改用管理者私聊作為備用模式。以 Cloudflare Worker、D1 和 Telegram Webhook 運作；不儲存訊息文字或媒體內容。

### 準備

- Node.js 22 以上、pnpm、PowerShell 7、Cloudflare 帳號和 Telegram Bot Token。
- Topic 模式需要啟用話題的超級群組，Bot 須有傳送訊息及管理話題權限。
- `tools/*.ps1` 使用 Windows DPAPI 儲存本機加密憑證；在其他系統上可直接使用 Wrangler 並自行安全管理 Token。

### 部署

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

### 使用與檢查

使用者私聊 Bot；管理者在對應 Topic 回覆。支援文字、一般媒體、相簿和編輯同步；Telegram 不允許複製的訊息類型無法轉送。使用者可用 `/start`、`/id`；管理者可用 `/user`、`/block`、`/unblock`、`/close`、`/help`。

```powershell
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/health'
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/ready'
./tools/Get-TelegramWebhookInfo.ps1
./tools/Test-WorkerRuntime.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

`/ready` 檢查設定與 D1，不檢查 Telegram 權限。正式環境探針會送安全的測試更新並清除其 D1 紀錄；仍須用非管理者帳號實測「私聊 → Topic → 管理者回覆 → 使用者收到」。

### 授權

本專案採 [GPL-3.0-only](LICENSE)。Topic 分流概念參考 [Roddy-D/cloudflare-telegrambot](https://github.com/Roddy-D/cloudflare-telegrambot)。

<a id="ja"></a>

## 日本語

Telegram の私信を、管理用スーパーグループ内のユーザー別トピックへ転送する Bot です。管理者はトピックから返信できます。管理グループを設定しない場合は管理者への私信を使います。Cloudflare Worker、D1、Telegram Webhook で動作し、メッセージ本文やメディア本体は保存しません。

### 必要なもの

- Node.js 22 以降、pnpm、PowerShell 7、Cloudflare アカウント、Telegram Bot Token。
- トピックを使う場合はトピックを有効にしたスーパーグループと、Bot の送信・トピック管理権限。
- `tools/*.ps1` は Windows DPAPI でローカルの認証情報を暗号化します。他の OS では Wrangler を直接使い、Token を安全に管理してください。

### デプロイ

以下はプロジェクトのディレクトリで PowerShell 7 から実行します。`pwsh` を使用中なら `./tools/` のスクリプトを直接実行できます。

```powershell
pnpm install --frozen-lockfile
pnpm run check
Copy-Item wrangler.jsonc.example wrangler.jsonc
```

`wrangler.jsonc` に自分の Worker 名と D1 名を設定します。新しいデータベースを作成したら、返された `database_id` を同ファイルに記入します。実際の ID は Git にコミットしないでください。既存の D1 を使う場合はその ID を記入し、再作成しません。

```powershell
./tools/Save-CloudflareToken.ps1
./tools/Test-CloudflareToken.ps1
./tools/Invoke-WithCloudflareToken.ps1 d1 create YOUR_D1_NAME
./tools/Invoke-WithCloudflareToken.ps1 d1 migrations apply BOT_DB --remote --config wrangler.jsonc
./tools/Invoke-WithCloudflareToken.ps1 deploy --keep-vars --config wrangler.jsonc
```

Cloudflare API Token には Workers Scripts Edit と D1 Edit が必要です。暗号化されたローカルコピーは `private-credentials/` に保存します。`wrangler.jsonc` は Git の対象外で、`keep_vars` により次回のデプロイでも Cloudflare 側の設定が保持されます。

Cloudflare Worker の Variables and Secrets に次を設定します。

| 名前 | 種類 | 内容 |
|---|---|---|
| `BOT_TOKEN` | Secret | BotFather で取得 |
| `WEBHOOK_SECRET` | Secret | 下記スクリプトで生成し、Webhook 登録にも同じ値を使用 |
| `ADMIN_USER_ID` | Text | 管理者の数字の Telegram User ID |
| `ADMIN_GROUP_ID` | Text、省略可 | トピックを有効にしたスーパーグループの ID。省略時は管理者への私信を使用 |
| `WELCOME_MESSAGE` | Text、省略可 | `/start` の応答文 |
| `MESSAGE_INTERVAL_SECONDS` | Text、省略可 | 通常メッセージの間隔。既定は 2 秒、範囲は 0–60 |

```powershell
./tools/New-WebhookSecret.ps1
./tools/Copy-WebhookSecret.ps1
# Cloudflare の Secret に貼り付けて保存した後：
Set-Clipboard $null
./tools/Register-TelegramWebhook.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

最後のスクリプトは Bot Token を非表示で入力し、`message` と `edited_message` のみを購読します。既存の Secret は `New-WebhookSecret.ps1` で上書きされません。変更時は Cloudflare Secret と Telegram Webhook を同時に更新してください。

グループ ID が不明な場合は、Webhook 登録後に管理者が対象グループで `/setup` を送り、Bot が返した ID を `ADMIN_GROUP_ID` に設定して保存・デプロイします。登録前ならグループでメッセージを送ってから `./tools/Get-TelegramChatIds.ps1` を実行できます。

### 使い方と確認

ユーザーは Bot に私信を送り、管理者は該当トピックで返信します。テキスト、通常のメディア、アルバム、編集の同期に対応します。Telegram がコピーを許可しない種類のメッセージは転送できません。ユーザー用コマンドは `/start`、`/id`、管理者用は `/user`、`/block`、`/unblock`、`/close`、`/help` です。

```powershell
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/health'
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/ready'
./tools/Get-TelegramWebhookInfo.ps1
./tools/Test-WorkerRuntime.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

`/ready` は設定と D1 を確認しますが、Telegram 側の権限は確認しません。運用テストは安全な更新を送信して D1 のテスト行を消去します。最後に管理者以外のアカウントで「私信 → トピック → 管理者の返信 → ユーザーへの到着」を確認してください。

### ライセンス

このプロジェクトは [GPL-3.0-only](LICENSE) で公開しています。トピックへの振り分けは [Roddy-D/cloudflare-telegrambot](https://github.com/Roddy-D/cloudflare-telegrambot) のアイデアを参考にしました。

<a id="en"></a>

## English

This bot relays Telegram private messages to a separate topic for each user in an admin supergroup. The admin replies from that topic. Without a configured group, it falls back to the admin's private chat. It runs on a Cloudflare Worker with D1 and a Telegram webhook, and does not store message text or media content.

### Requirements

- Node.js 22 or newer, pnpm, PowerShell 7, a Cloudflare account, and a Telegram Bot Token.
- Topic mode requires a supergroup with topics enabled and permission for the bot to send messages and manage topics.
- `tools/*.ps1` store local encrypted credentials with Windows DPAPI. On other systems, use Wrangler directly and manage the token securely.

### Deploy

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

### Use and verify

Users message the bot privately; the admin replies in the matching topic. Text, ordinary media, albums, and edit syncing are supported. Telegram message types that cannot be copied cannot be relayed. Users can run `/start` and `/id`; the admin can run `/user`, `/block`, `/unblock`, `/close`, and `/help`.

```powershell
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/health'
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/ready'
./tools/Get-TelegramWebhookInfo.ps1
./tools/Test-WorkerRuntime.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

`/ready` checks configuration and D1, not Telegram permissions. The runtime probe sends a safe update and removes its D1 row. Also test the full flow with a non-admin account: private message → topic → admin reply → user receives the reply.

### License

This project is licensed under [GPL-3.0-only](LICENSE). Topic routing was inspired by [Roddy-D/cloudflare-telegrambot](https://github.com/Roddy-D/cloudflare-telegrambot).
