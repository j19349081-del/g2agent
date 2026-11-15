Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:G2Root = Split-Path -Parent $PSScriptRoot
$script:G2SettingsPath = Join-Path $script:G2Root 'settings.json'

function Get-G2Settings {
    if (-not (Test-Path -LiteralPath $script:G2SettingsPath -PathType Leaf)) {
        throw "Settings file not found. Run Initialize-G2Agent.ps1 first."
    }
    Get-Content -LiteralPath $script:G2SettingsPath -Raw | ConvertFrom-Json
}

function Get-G2AccessToken {
    $gcloud = Get-Command 'gcloud' -ErrorAction SilentlyContinue
    if (-not $gcloud) {
        throw 'Google Cloud CLI (gcloud) is required. Install it and complete ADC login as described in README.md.'
    }
    $token = (& $gcloud.Source auth application-default print-access-token 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
        throw 'No Google Application Default Credentials found. Run the documented gcloud login command.'
    }
    $token
}

function Invoke-G2YouTubeApi {
    param(
        [Parameter(Mandatory)][ValidateSet('GET', 'POST', 'PUT')][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [Parameter()][object]$Body
    )
    $headers = @{ Authorization = "Bearer $(Get-G2AccessToken)" }
    if ($PSBoundParameters.ContainsKey('Body')) {
        $json = $Body | ConvertTo-Json -Depth 20
        Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $json
    } else {
        Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
    }
}

function Get-G2JobRecord {
    param([Parameter(Mandatory)][string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    Get-Content -LiteralPath $resolved -Raw | ConvertFrom-Json
}

function Save-G2JobRecord {
    param(
        [Parameter(Mandatory)][object]$Job,
        [Parameter(Mandatory)][string]$Path
    )
    $Job | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Assert-G2AuthorizedChannel {
    $settings = Get-G2Settings
    if ([string]::IsNullOrWhiteSpace([string]$settings.expectedChannelId)) {
        throw 'Set expectedChannelId in settings.json to the channel ID you verified before running channel operations.'
    }
    $uri = 'https://www.googleapis.com/youtube/v3/channels?part=id%2Csnippet&mine=true'
    $response = Invoke-G2YouTubeApi -Method GET -Uri $uri
    $channel = @($response.items | Where-Object { $_.id -eq $settings.expectedChannelId }) | Select-Object -First 1
    if (-not $channel) {
        throw 'The authorized account did not return the configured expectedChannelId. No action was taken.'
    }
    $channel
}

function Assert-G2JobReady {
    param(
        [Parameter(Mandatory)][object]$Job,
        [switch]$ForUpload
    )
    $problems = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath ([string]$Job.mediaPath) -PathType Leaf)) {
        $problems.Add("Media file is missing: $($Job.mediaPath)")
    }
    if ([string]::IsNullOrWhiteSpace([string]$Job.metadata.title) -or ([string]$Job.metadata.title).Length -gt 100) {
        $problems.Add('Title must be present and no longer than 100 characters.')
    }
    if ([string]$Job.metadata.description -and ([string]$Job.metadata.description).Length -gt 5000) {
        $problems.Add('Description must be no longer than 5000 characters.')
    }
    if (-not $Job.metadata.categoryId) {
        $problems.Add('Set metadata.categoryId to a YouTube category ID.')
    }
    if ($Job.settings.privacyStatus -ne 'private') {
        $problems.Add('New uploads must remain private; use Set-G2VideoVisibility.ps1 as a separately confirmed action.')
    }
    if ($null -eq $Job.settings.selfDeclaredMadeForKids) {
        $problems.Add('Explicitly set settings.selfDeclaredMadeForKids to true or false.')
    }
    if ($ForUpload) {
        if (-not $Job.approvals.rightsConfirmed) { $problems.Add('Confirm media/source rights in the job record.') }
        if (-not $Job.approvals.audienceConfirmed) { $problems.Add('Confirm the audience setting in the job record.') }
        if (-not $Job.approvals.uploadApproved) { $problems.Add('Set approvals.uploadApproved to true after reviewing the media and metadata.') }
    }
    if ($problems.Count -gt 0) {
        throw ($problems -join [Environment]::NewLine)
    }
}

Export-ModuleMember -Function Get-G2Settings, Get-G2AccessToken, Invoke-G2YouTubeApi, Get-G2JobRecord, Save-G2JobRecord, Assert-G2AuthorizedChannel, Assert-G2JobReady
