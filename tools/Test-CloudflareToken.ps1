#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$tokenFile = Join-Path $projectRoot 'private-credentials/cloudflare-token.dpapi'
if (-not (Test-Path -LiteralPath $tokenFile)) {
    throw '尚未保存 Cloudflare Token。先執行 tools/Save-CloudflareToken.ps1。'
}

$secureToken = ConvertTo-SecureString ((Get-Content -Raw -LiteralPath $tokenFile).Trim())
$credential = [PSCredential]::new('cloudflare', $secureToken)
$plainToken = $credential.GetNetworkCredential().Password
try {
    $headers = @{ Authorization = "Bearer $plainToken" }
    try {
        $response = Invoke-RestMethod -Method Get `
            -Uri 'https://api.cloudflare.com/client/v4/user/tokens/verify' `
            -Headers $headers
        $scope = 'User'
    } catch {
        $accounts = Invoke-RestMethod -Method Get `
            -Uri 'https://api.cloudflare.com/client/v4/accounts?per_page=50' `
            -Headers $headers
        if (-not $accounts.success -or $accounts.result.Count -ne 1) {
            throw '無法判斷 Account Token 所屬帳戶。'
        }
        $accountId = $accounts.result[0].id
        $response = Invoke-RestMethod -Method Get `
            -Uri "https://api.cloudflare.com/client/v4/accounts/$accountId/tokens/verify" `
            -Headers $headers
        $scope = 'Account'
    }
    if (-not $response.success) { throw 'Cloudflare Token 驗證失敗。' }
    [pscustomobject]@{
        Status = $response.result.status
        Scope = $scope
        Verified = $true
    }
} finally {
    $plainToken = $null
    $credential = $null
    $secureToken = $null
}
