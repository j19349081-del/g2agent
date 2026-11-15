[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$JobPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$resolvedJobPath = (Resolve-Path -LiteralPath $JobPath -ErrorAction Stop).Path
$job = Get-G2JobRecord -Path $resolvedJobPath
if ([string]::IsNullOrWhiteSpace([string]$job.youtube.videoId)) {
    throw 'This job has no recorded YouTube video ID. Check YouTube Studio manually if its uploadState is uploading or upload-unknown.'
}
$channel = Assert-G2AuthorizedChannel
$id = [Uri]::EscapeDataString([string]$job.youtube.videoId)
$uri = "https://www.googleapis.com/youtube/v3/videos?part=id%2Csnippet%2Cstatus&id=$id"
$response = Invoke-G2YouTubeApi -Method GET -Uri $uri
$video = @($response.items | Select-Object -First 1)
if ($video.Count -eq 0) { throw 'YouTube did not return this video. It may have been removed or may not be visible to the authorized channel.' }
$job.youtube.lastKnownPrivacyStatus = [string]$video[0].status.privacyStatus
Save-G2JobRecord -Job $job -Path $resolvedJobPath
[pscustomobject]@{
    jobId = $job.jobId
    videoId = $video[0].id
    title = $video[0].snippet.title
    uploadStatus = $video[0].status.uploadStatus
    privacyStatus = $video[0].status.privacyStatus
    channel = $channel.snippet.title
    url = "https://www.youtube.com/watch?v=$($video[0].id)"
} | Format-List
