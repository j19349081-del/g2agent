[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$settings = Get-G2Settings
$uri = 'https://www.googleapis.com/youtube/v3/channels?part=id%2Csnippet&mine=true'
$response = Invoke-G2YouTubeApi -Method GET -Uri $uri
if (-not $response.items) { throw 'No YouTube channels were returned for the authorized account.' }
$response.items | ForEach-Object {
    [pscustomobject]@{
        id = $_.id
        title = $_.snippet.title
        customUrl = $_.snippet.customUrl
        matchesConfiguredChannel = ($_.id -eq $settings.expectedChannelId)
    }
} | Format-Table -AutoSize
Write-Output 'Verify the intended channel ID, then set expectedChannelId in settings.json before any upload or update.'
