[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9-]{4,28}[a-z0-9]$')][string]$ProjectId,
    [Parameter()][switch]$SkipAuthorization
)

$ErrorActionPreference = 'Stop'
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

if ($SkipAuthorization) {
    Write-Output 'Browser setup pages opened. Complete the Cloud Console steps, then rerun without -SkipAuthorization to authorize.'
    return
}

Write-Output 'In the browser: enable YouTube Data API v3; configure OAuth branding/audience and add your account as a test user if needed; create a Desktop app OAuth client; download its JSON outside this repository; and add the youtube scope in Data Access.'
$ready = Read-Host 'When those steps are complete, type READY to continue to Google authorization'
if ($ready -cne 'READY') {
    Write-Output 'Stopped without authorizing. Rerun this script when the Cloud Console setup is complete.'
    return
}

$clientIdFile = Read-Host 'Enter the full path to the downloaded OAuth Desktop client JSON (not its contents)'
if ([string]::IsNullOrWhiteSpace($clientIdFile)) { throw 'OAuth client JSON path is required.' }
$connectScript = Join-Path $PSScriptRoot 'Connect-G2YouTube.ps1'
if ($PSCmdlet.ShouldProcess('Google account', 'Run the existing YouTube OAuth consent flow')) {
    & $connectScript -ClientIdFile $clientIdFile -Confirm
}

Write-Output 'Authorization flow finished. Next run Get-G2Channel.ps1, verify the intended channel, and set expectedChannelId in settings.json.'
