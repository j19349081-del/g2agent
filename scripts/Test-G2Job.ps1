[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$JobPath,
    [switch]$ForUpload
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'G2Agent.Common.psm1') -Force
$job = Get-G2JobRecord -Path $JobPath
Assert-G2JobReady -Job $job -ForUpload:$ForUpload
$file = Get-Item -LiteralPath $job.mediaPath
$result = [ordered]@{
    jobId = $job.jobId
    type = $job.type
    mediaPath = $file.FullName
    sizeBytes = $file.Length
    title = $job.metadata.title
    privacyStatus = $job.settings.privacyStatus
    checks = @('Media file exists', 'Required metadata and privacy defaults are valid')
    mediaProbe = 'not-run'
}
$ffprobe = Get-Command 'ffprobe' -ErrorAction SilentlyContinue
if ($ffprobe) {
    $probeText = & $ffprobe.Source -v error -show_entries 'format=duration:stream=codec_type,width,height' -of json $file.FullName 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "ffprobe could not read the media file: $probeText" }
    $probe = $probeText | ConvertFrom-Json
    $result.mediaProbe = $probe
    $result.checks += 'ffprobe can read media streams'
} else {
    Write-Warning 'ffprobe is not installed; codec, duration, and aspect ratio were not inspected.'
}
if ($ForUpload) { $result.checks += 'Rights, audience, and upload approval flags are confirmed' }
$result | ConvertTo-Json -Depth 10
