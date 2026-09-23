#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$secretFile = Join-Path $projectRoot 'private-credentials/telegram-webhook-secret.dpapi'
if (-not (Test-Path -LiteralPath $secretFile)) {
    throw '找不到本機保存的 WEBHOOK_SECRET。先執行 tools/New-WebhookSecret.ps1。'
}

$secureSecret = ConvertTo-SecureString ((Get-Content -Raw -LiteralPath $secretFile).Trim())
$credential = [PSCredential]::new('webhook', $secureSecret)
try {
    $plainSecret = $credential.GetNetworkCredential().Password
    Set-Clipboard -Value $plainSecret
    Write-Host 'WEBHOOK_SECRET 已放入剪貼板；貼入 Cloudflare Secret 後請清空剪貼板。'
} finally {
    $plainSecret = $null
    $credential = $null
    $secureSecret = $null
}
