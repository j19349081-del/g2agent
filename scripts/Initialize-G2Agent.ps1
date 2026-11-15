[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$directories = @('inbox', 'jobs', 'logs')
foreach ($directory in $directories) {
    $path = Join-Path $root $directory
    if ($PSCmdlet.ShouldProcess($path, 'Create local data directory')) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

$settingsPath = Join-Path $root 'settings.json'
if (-not (Test-Path -LiteralPath $settingsPath)) {
    $settings = [ordered]@{
        expectedChannelId = ''
        apiBaseUrl = 'https://www.googleapis.com/youtube/v3'
        note = 'Set expectedChannelId only after verifying the channel with Get-G2Channel.ps1.'
    }
    if ($PSCmdlet.ShouldProcess($settingsPath, 'Create non-secret local settings')) {
        $settings | ConvertTo-Json | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    }
} else {
    Write-Output "Settings already exist; leaving unchanged: $settingsPath"
}
Write-Output 'G2Agent local folders are initialized. No account access or upload was performed.'
