[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$JobPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$resolvedJobPath = (Resolve-Path -LiteralPath $JobPath -ErrorAction Stop).Path
$job = Get-G2JobRecord -Path $resolvedJobPath
Assert-G2JobReady -Job $job -ForUpload
if ($job.youtube.videoId -or $job.youtube.uploadState -ne 'not-uploaded') {
    throw 'This job is not in not-uploaded state. Reconcile it manually in YouTube Studio before attempting another upload.'
}
$channel = Assert-G2AuthorizedChannel
$file = Get-Item -LiteralPath $job.mediaPath
$mime = switch ([IO.Path]::GetExtension($file.Name).ToLowerInvariant()) {
    '.mp4' { 'video/mp4' }
    '.m4v' { 'video/x-m4v' }
    '.mov' { 'video/quicktime' }
    '.webm' { 'video/webm' }
    default { throw 'Unsupported media extension. Use an MP4, M4V, MOV, or WebM export.' }
}
if (-not $PSCmdlet.ShouldProcess("channel '$($channel.snippet.title)'", "Upload '$($job.metadata.title)' as private")) { return }

$job.youtube.uploadState = 'uploading'
Save-G2JobRecord -Job $job -Path $resolvedJobPath
try {
    $resource = @{
        snippet = @{
            title = $job.metadata.title
            description = $job.metadata.description
            tags = @($job.metadata.tags)
            categoryId = [string]$job.metadata.categoryId
        }
        status = @{
            privacyStatus = 'private'
            selfDeclaredMadeForKids = [bool]$job.settings.selfDeclaredMadeForKids
        }
    } | ConvertTo-Json -Depth 10
    $uri = 'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet%2Cstatus'
    $token = Get-G2AccessToken
    $init = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uri -ContentType 'application/json; charset=utf-8' -Headers @{
        Authorization = "Bearer $token"
        'X-Upload-Content-Type' = $mime
        'X-Upload-Content-Length' = [string]$file.Length
    } -Body $resource
    $uploadUri = $init.Headers['Location']
    if ([string]::IsNullOrWhiteSpace([string]$uploadUri)) { throw 'YouTube did not return a resumable upload URL.' }
    $range = "bytes 0-$($file.Length - 1)/$($file.Length)"
    $uploaded = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $uploadUri -InFile $file.FullName -ContentType $mime -Headers @{
        Authorization = "Bearer $token"
        'Content-Range' = $range
    }
    $response = $uploaded.Content | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$response.id)) { throw 'Upload response did not contain a video ID.' }
    $job.youtube.videoId = [string]$response.id
    $job.youtube.uploadState = 'uploaded-private'
    $job.youtube.uploadedAtUtc = [DateTime]::UtcNow.ToString('o')
    $job.youtube.lastKnownPrivacyStatus = [string]$response.status.privacyStatus
    Save-G2JobRecord -Job $job -Path $resolvedJobPath
    [pscustomobject]@{
        jobId = $job.jobId
        videoId = $response.id
        url = "https://www.youtube.com/watch?v=$($response.id)"
        privacyStatus = $response.status.privacyStatus
        channel = $channel.snippet.title
    } | Format-List
} catch {
    $job.youtube.uploadState = 'upload-unknown'
    Save-G2JobRecord -Job $job -Path $resolvedJobPath
    throw "Upload did not complete cleanly. The job is marked upload-unknown to prevent duplicates; check YouTube Studio before retrying. Details: $($_.Exception.Message)"
}
