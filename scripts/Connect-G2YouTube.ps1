[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][string]$ClientIdFile
)

$ErrorActionPreference = 'Stop'
$gcloud = Get-Command 'gcloud' -ErrorAction SilentlyContinue
if (-not $gcloud) { throw 'Install Google Cloud CLI (gcloud) before connecting.' }
$resolvedClientIdFile = (Resolve-Path -LiteralPath $ClientIdFile -ErrorAction Stop).Path
$scope = 'https://www.googleapis.com/auth/youtube'
if ($PSCmdlet.ShouldProcess('Google account in the browser', 'Authorize YouTube Data API access through Google ADC')) {
    & $gcloud.Source auth application-default login "--client-id-file=$resolvedClientIdFile" "--scopes=$scope"
    if ($LASTEXITCODE -ne 0) { throw 'Google ADC login did not complete successfully.' }
}
Write-Output 'Google manages the local ADC credential. No password or OAuth token is written to the G2Agent folder.'
