[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$MediaPath,
    [Parameter(Mandatory)][ValidateLength(1, 100)][string]$Title,
    [Parameter()][string]$Description = '',
    [Parameter(Mandatory)][ValidateSet('Video', 'Short')][string]$Type,
    [Parameter()][string[]]$Tags = @()
)

$ErrorActionPreference = 'Stop'
$resolvedMedia = (Resolve-Path -LiteralPath $MediaPath -ErrorAction Stop).Path
if (-not (Test-Path -LiteralPath $resolvedMedia -PathType Leaf)) { throw 'MediaPath must name a file.' }
$root = Split-Path -Parent $PSScriptRoot
$jobsDir = Join-Path $root 'jobs'
if (-not (Test-Path -LiteralPath $jobsDir)) { throw 'Run Initialize-G2Agent.ps1 first.' }
$jobId = [guid]::NewGuid().ToString()
$jobPath = Join-Path $jobsDir "$jobId.json"
$job = [ordered]@{
    jobId = $jobId
    createdAtUtc = [DateTime]::UtcNow.ToString('o')
    type = $Type
    mediaPath = $resolvedMedia
    metadata = [ordered]@{
        title = $Title
        description = $Description
        tags = @($Tags)
        categoryId = ''
    }
    settings = [ordered]@{
        privacyStatus = 'private'
        selfDeclaredMadeForKids = $null
    }
    approvals = [ordered]@{
        rightsConfirmed = $false
        audienceConfirmed = $false
        uploadApproved = $false
        publishApproved = $false
    }
    youtube = [ordered]@{
        videoId = ''
        uploadState = 'not-uploaded'
        uploadedAtUtc = ''
        lastKnownPrivacyStatus = ''
    }
}
if ($PSCmdlet.ShouldProcess($jobPath, 'Create draft job record')) {
    $job | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jobPath -Encoding UTF8
    Write-Output $jobPath
}
