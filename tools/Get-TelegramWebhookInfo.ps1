#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$botTokenSecure = Read-Host '輸入 Telegram Bot Token（不會顯示）' -AsSecureString
$botCredential = [PSCredential]::new('telegram', $botTokenSecure)

try {
    $botToken = $botCredential.GetNetworkCredential().Password
    $uri = "https://api.telegram.org/bot$botToken/getWebhookInfo"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri
    } catch {
        throw 'Telegram Webhook 狀態查詢失敗；為避免洩漏 Bot Token，已隱藏原始 URI。'
    }
    if (-not $response.ok) { throw 'Telegram 無法取得 Webhook 狀態。' }

    $info = $response.result
    [PSCustomObject]@{
        Url                      = $info.url
        PendingUpdateCount       = $info.pending_update_count
        LastErrorDate            = if ($info.last_error_date) {
            [DateTimeOffset]::FromUnixTimeSeconds([long]$info.last_error_date).ToLocalTime()
        } else { $null }
        LastErrorMessage         = $info.last_error_message
        LastSynchronizationError = if ($info.last_synchronization_error_date) {
            [DateTimeOffset]::FromUnixTimeSeconds([long]$info.last_synchronization_error_date).ToLocalTime()
        } else { $null }
        MaxConnections           = $info.max_connections
        AllowedUpdates           = $info.allowed_updates -join ', '
    } | Format-List
} finally {
    $botToken = $null
    $botCredential = $null
}
