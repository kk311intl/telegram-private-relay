#requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$privateDir = Join-Path $projectRoot 'private-credentials'
$secretFile = Join-Path $privateDir 'telegram-webhook-secret.dpapi'
if ((Test-Path -LiteralPath $secretFile) -and -not $Force) {
    throw '本機已有 WEBHOOK_SECRET；若確定要輪替，請使用 -Force，並立即同步更新 Cloudflare Secret 與 Telegram Webhook。'
}
$bytes = [byte[]]::new(32)
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$plainSecret = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$secureSecret = ConvertTo-SecureString $plainSecret -AsPlainText -Force

New-Item -ItemType Directory -Path $privateDir -Force | Out-Null
Set-Content -LiteralPath $secretFile `
    -Value (ConvertFrom-SecureString -SecureString $secureSecret) `
    -Encoding utf8NoBOM

try {
    $acl = Get-Acl -LiteralPath $secretFile
    $acl.SetAccessRuleProtection($true, $false)
    $rule = [Security.AccessControl.FileSystemAccessRule]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent().Name,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow
    )
    $acl.SetAccessRule($rule)
    Set-Acl -LiteralPath $secretFile -AclObject $acl
} catch [System.UnauthorizedAccessException] {
    Write-Warning '目前工作區不允許修改 NTFS ACL；DPAPI 使用者綁定仍然有效。'
} finally {
    $plainSecret = $null
    $secureSecret = $null
    [Array]::Clear($bytes, 0, $bytes.Length)
}

Write-Host "WEBHOOK_SECRET 已用目前 Windows 使用者的 DPAPI 加密保存：$secretFile"
Write-Host '需要填入 Cloudflare 時，請執行 tools/Copy-WebhookSecret.ps1。'
