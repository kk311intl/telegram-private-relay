#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$privateDir = Join-Path $projectRoot 'private-credentials'
$tokenFile = Join-Path $privateDir 'cloudflare-token.dpapi'

$secureToken = Read-Host '輸入 Cloudflare API Token（不會顯示）' -AsSecureString
$encrypted = ConvertFrom-SecureString -SecureString $secureToken
New-Item -ItemType Directory -Path $privateDir -Force | Out-Null
Set-Content -LiteralPath $tokenFile -Value $encrypted -Encoding utf8NoBOM

try {
    $acl = Get-Acl -LiteralPath $tokenFile
    $acl.SetAccessRuleProtection($true, $false)
    $rule = [Security.AccessControl.FileSystemAccessRule]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent().Name,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow
    )
    $acl.SetAccessRule($rule)
    Set-Acl -LiteralPath $tokenFile -AclObject $acl
} catch [System.UnauthorizedAccessException] {
    Write-Warning '目前工作區不允許修改 NTFS ACL；DPAPI 使用者綁定仍然有效。'
}
Write-Host "Token 已用目前 Windows 使用者的 DPAPI 加密保存：$tokenFile"
