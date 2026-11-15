[CmdletBinding()]
param(
    [switch]$CheckAuthentication
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$results = [System.Collections.Generic.List[object]]::new()
$results.Add([pscustomobject]@{ check = 'PowerShell'; result = $PSVersionTable.PSVersion.ToString(); ok = ($PSVersionTable.PSVersion.Major -ge 5) })
$gcloud = Get-Command 'gcloud' -ErrorAction SilentlyContinue
$results.Add([pscustomobject]@{ check = 'Google Cloud CLI'; result = if ($gcloud) { $gcloud.Source } else { 'not installed' }; ok = [bool]$gcloud })
$ffprobe = Get-Command 'ffprobe' -ErrorAction SilentlyContinue
$results.Add([pscustomobject]@{ check = 'ffprobe (optional)'; result = if ($ffprobe) { $ffprobe.Source } else { 'not installed; media probing unavailable' }; ok = $true })
$settingsPath = Join-Path $root 'settings.json'
$settingsExists = Test-Path -LiteralPath $settingsPath -PathType Leaf
$results.Add([pscustomobject]@{ check = 'Local settings'; result = if ($settingsExists) { $settingsPath } else { 'run Initialize-G2Agent.ps1' }; ok = $settingsExists })
if ($CheckAuthentication) {
    try {
        $null = Get-G2AccessToken
        $results.Add([pscustomobject]@{ check = 'Google ADC'; result = 'token available (value hidden)'; ok = $true })
    } catch {
        $results.Add([pscustomobject]@{ check = 'Google ADC'; result = $_.Exception.Message; ok = $false })
    }
}
$results | Format-Table -AutoSize
if (@($results | Where-Object { -not $_.ok }).Count -gt 0) { exit 1 }
