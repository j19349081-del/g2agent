[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$JobPath,
    [Parameter(Mandatory)][ValidateSet('private', 'unlisted', 'public')][string]$Visibility,
    [Parameter()][DateTimeOffset]$PublishAt,
    [switch]$ApprovePublic
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$resolvedJobPath = (Resolve-Path -LiteralPath $JobPath -ErrorAction Stop).Path
$job = Get-G2JobRecord -Path $resolvedJobPath
if ([string]::IsNullOrWhiteSpace([string]$job.youtube.videoId)) { throw 'Upload the video and record its ID before changing visibility.' }
$channel = Assert-G2AuthorizedChannel
if ($Visibility -eq 'public' -and (-not $ApprovePublic -or -not $job.approvals.publishApproved)) {
    throw 'Public release requires both -ApprovePublic and approvals.publishApproved=true in the reviewed job record.'
}
if ($PublishAt -and $Visibility -ne 'public') { throw 'Use -PublishAt only with -Visibility public.' }
if ($PublishAt -and $PublishAt -le [DateTimeOffset]::Now) { throw 'PublishAt must be a future date and time.' }
$effectivePrivacy = if ($PublishAt) { 'private' } else { $Visibility }
$status = @{
    privacyStatus = $effectivePrivacy
    selfDeclaredMadeForKids = [bool]$job.settings.selfDeclaredMadeForKids
}
if ($PublishAt) { $status.publishAt = $PublishAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }
$resource = @{ id = [string]$job.youtube.videoId; status = $status }
$action = if ($PublishAt) { "Schedule '$($job.metadata.title)' for $($PublishAt.ToString('o'))" } else { "Set '$($job.metadata.title)' visibility to $Visibility" }
if (-not $PSCmdlet.ShouldProcess("channel '$($channel.snippet.title)'", $action)) { return }
$uri = 'https://www.googleapis.com/youtube/v3/videos?part=status'
$response = Invoke-G2YouTubeApi -Method PUT -Uri $uri -Body $resource
$job.youtube.lastKnownPrivacyStatus = [string]$response.status.privacyStatus
$job.youtube.uploadState = 'status-updated'
Save-G2JobRecord -Job $job -Path $resolvedJobPath
[pscustomobject]@{
    jobId = $job.jobId
    videoId = $job.youtube.videoId
    requestedVisibility = $Visibility
    actualPrivacyStatus = $response.status.privacyStatus
    publishAt = $response.status.publishAt
    channel = $channel.snippet.title
    url = "https://www.youtube.com/watch?v=$($job.youtube.videoId)"
} | Format-List
