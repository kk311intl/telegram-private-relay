#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$secureToken = Read-Host '輸入 Telegram Bot Token（不會顯示或保存）' -AsSecureString
$credential = [PSCredential]::new('telegram', $secureToken)

try {
    $token = $credential.GetNetworkCredential().Password
    try {
        $response = Invoke-RestMethod -Method Get -Uri "https://api.telegram.org/bot$token/getUpdates?limit=100&timeout=0"
    } catch {
        throw 'Telegram 使用者 ID 查詢失敗；請確認尚未註冊 Webhook。為避免洩漏 Bot Token，已隱藏原始 URI。'
    }
    if (-not $response.ok) { throw 'Telegram 無法取得更新。' }

    $users = @($response.result | Where-Object {
        $_.message.chat.type -eq 'private' -and $_.message.text -match '^/id(?:@\w+)?(?:\s|$)'
    } | Sort-Object update_id -Descending | ForEach-Object {
        [pscustomobject]@{
            UserId = [string]$_.message.from.id
            Username = [string]$_.message.from.username
        }
    } | Sort-Object UserId -Unique)

    if ($users.Count -eq 0) {
        Write-Warning '沒有找到私聊 /id。請先用你的 Telegram 帳號對新 Bot 傳送 /id，再重新執行；已有 Webhook 的部署請從現有設定取得 ADMIN_USER_ID。'
        return
    }
    $users | Format-Table -AutoSize
} finally {
    $token = $null
    $credential = $null
    $secureToken = $null
}
