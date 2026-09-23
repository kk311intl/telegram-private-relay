#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$secureToken = Read-Host '輸入 Telegram Bot Token（不會顯示或保存）' -AsSecureString
$credential = [PSCredential]::new('telegram', $secureToken)
$token = $credential.GetNetworkCredential().Password

try {
    $uri = "https://api.telegram.org/bot$token/getUpdates?limit=100&timeout=0"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri
    } catch {
        throw 'Telegram 群組查詢失敗；為避免洩漏 Bot Token，已隱藏原始 URI。'
    }
    if (-not $response.ok) { throw 'Telegram getUpdates 失敗。' }

    $chats = foreach ($update in $response.result) {
        $message = $update.message
        if (-not $message) { $message = $update.edited_message }
        if (-not $message) { $message = $update.channel_post }
        if (-not $message) { continue }
        if ($message.chat.type -notin @('group', 'supergroup')) { continue }

        [pscustomobject]@{
            ChatId = [string]$message.chat.id
            Title = [string]$message.chat.title
            Type = [string]$message.chat.type
            TopicsEnabled = [bool]$message.chat.is_forum
        }
    }

    $uniqueChats = @($chats | Sort-Object ChatId -Unique)
    if ($uniqueChats.Count -eq 0) {
        Write-Warning '沒有找到群組。請先在目標群組傳送一則 /setup，再重新執行。若已註冊 Webhook，getUpdates 將無法使用。'
        return
    }
    $uniqueChats | Format-Table -AutoSize
} finally {
    $token = $null
    $credential = $null
    $secureToken = $null
}
