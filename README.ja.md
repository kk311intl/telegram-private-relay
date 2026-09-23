# Telegram Private Relay

[繁體中文](README.md) | 日本語 | [English](README.en.md)

バージョン：v1.0.0

Telegram の私信を、管理用スーパーグループ内のユーザー別トピックへ転送する Bot です。管理者はトピックから返信できます。管理グループを設定しない場合は管理者への私信を使います。Cloudflare Worker、D1、Telegram Webhook で動作し、メッセージ本文やメディア本体は保存しません。

## 必要なもの

- Node.js 22 以降、pnpm、PowerShell 7、Cloudflare アカウント、Telegram Bot Token。
- トピックを使う場合はトピックを有効にしたスーパーグループと、Bot の送信・トピック管理権限。
- `tools/*.ps1` は Windows DPAPI でローカルの認証情報を暗号化します。他の OS では Wrangler を直接使い、Token を安全に管理してください。

## デプロイ

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

## 使い方と確認

ユーザーは Bot に私信を送り、管理者は該当トピックで返信します。テキスト、通常のメディア、アルバム、編集の同期に対応します。Telegram がコピーを許可しない種類のメッセージは転送できません。ユーザー用コマンドは `/start`、`/id`、管理者用は `/user`、`/block`、`/unblock`、`/close`、`/help` です。

```powershell
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/health'
Invoke-RestMethod 'https://YOUR_WORKER.workers.dev/ready'
./tools/Get-TelegramWebhookInfo.ps1
./tools/Test-WorkerRuntime.ps1 -WorkerUrl 'https://YOUR_WORKER.workers.dev'
```

`/ready` は設定と D1 を確認しますが、Telegram 側の権限は確認しません。運用テストは安全な更新を送信して D1 のテスト行を消去します。最後に管理者以外のアカウントで「私信 → トピック → 管理者の返信 → ユーザーへの到着」を確認してください。

## AI で使う

Repository と次の文を ChatGPT、Codex、Claude などの coding agent に渡してください。

> Read this repository before acting. It is a Telegram private-message relay built with a Cloudflare Worker, D1 migrations, and a Telegram webhook. Help me install, configure, deploy, troubleshoot, or make a requested change. Identify the files involved first and keep the current architecture. Deployment needs a Worker name, a D1 database ID, BOT_TOKEN, WEBHOOK_SECRET, ADMIN_USER_ID, and optionally ADMIN_GROUP_ID. Keep real credentials, IDs, domains, and local paths out of Git; use the example config and local secrets. Do not add dependencies or extra files without a concrete need. Ask only for missing required values, run the relevant checks, and summarize the result.
