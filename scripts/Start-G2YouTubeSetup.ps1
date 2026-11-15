[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{4,28}[a-z0-9]$')][string]$ProjectId,
    [Parameter(Mandatory)][string]$ClientIdFile,
    [Parameter(Mandatory)][ValidatePattern('^UC[a-zA-Z0-9_-]{22}$')][string]$ExpectedChannelId
)

$ErrorActionPreference = 'Stop'
$resolvedClientIdFile = (Resolve-Path -LiteralPath $ClientIdFile -ErrorAction Stop).Path
$oauthClient = Get-Content -LiteralPath $resolvedClientIdFile -Raw | ConvertFrom-Json
if (-not $oauthClient.installed) {
    throw 'The client JSON is not a Google OAuth Desktop app client. Download the Desktop app client JSON and retry.'
}

$setupPages = @(
    [pscustomobject]@{
        Name = 'Enable YouTube Data API v3'
        Uri = "https://console.cloud.google.com/apis/library/youtube.googleapis.com?project=$([Uri]::EscapeDataString($ProjectId))"
    },
    [pscustomobject]@{
        Name = 'Configure OAuth consent and app audience'
        Uri = "https://console.cloud.google.com/auth/overview?project=$([Uri]::EscapeDataString($ProjectId))"
    },
    [pscustomobject]@{
        Name = 'Create Desktop OAuth client'
        Uri = "https://console.cloud.google.com/auth/clients?project=$([Uri]::EscapeDataString($ProjectId))"
    },
    [pscustomobject]@{
        Name = 'Review YouTube OAuth setup'
        Uri = 'https://developers.google.com/youtube/v3/guides/authentication'
    }
)

Write-Output "Opening YouTube API setup pages for Google Cloud project '$ProjectId'."
foreach ($page in $setupPages) {
    Write-Output "Open: $($page.Name)"
    if ($PSCmdlet.ShouldProcess($page.Uri, "Open $($page.Name) in the browser")) {
        Start-Process $page.Uri
    }
}

$settingsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'settings.json'
$initializeScript = Join-Path $PSScriptRoot 'Initialize-G2Agent.ps1'
if (-not (Test-Path -LiteralPath $settingsPath)) {
    & $initializeScript -Confirm:$false
}

$connectScript = Join-Path $PSScriptRoot 'Connect-G2YouTube.ps1'
if ($PSCmdlet.ShouldProcess('Google account', 'Run the YouTube OAuth consent flow in the browser')) {
    & $connectScript -ClientIdFile $resolvedClientIdFile -Confirm:$false
}

Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$channelsUri = 'https://www.googleapis.com/youtube/v3/channels?part=id%2Csnippet&mine=true'
$channels = Invoke-G2YouTubeApi -Method GET -Uri $channelsUri
$channel = @($channels.items | Where-Object { $_.id -eq $ExpectedChannelId } | Select-Object -First 1)
if ($channel.Count -eq 0) {
    throw "OAuth completed, but the authorized account does not expose expected channel '$ExpectedChannelId'. No channel setting was changed."
}

$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$settings.expectedChannelId = $ExpectedChannelId
$settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
Write-Output "Setup complete. Authorized channel: $($channel[0].snippet.title) ($ExpectedChannelId). Subsequent G2Agent operations run without terminal prompts."
