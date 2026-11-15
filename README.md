# G2Agent

## Script usage

Run these commands from the `g2agent` folder in PowerShell:

```powershell
./scripts/Initialize-G2Agent.ps1
./scripts/Test-G2Prerequisites.ps1
./scripts/Start-G2YouTubeSetup.ps1 -ProjectId "<google-cloud-project-id>"
```

The setup script opens the required Google API/OAuth pages, then runs the consent flow. Follow its prompts and provide the path to the downloaded Desktop OAuth client JSON.

```powershell
./scripts/Get-G2Channel.ps1
```

Set the verified channel ID in local `settings.json`, then create a video job:

```powershell
./scripts/New-G2Job.ps1 -MediaPath "<video-file>" -Title "<title>" -Type Video
./scripts/Test-G2Job.ps1 -JobPath "<jobs\job-id.json>" -ForUpload
./scripts/Upload-G2Video.ps1 -JobPath "<jobs\job-id.json>" -Confirm
./scripts/Get-G2VideoStatus.ps1 -JobPath "<jobs\job-id.json>"
```

```powershell
./scripts/Set-G2VideoVisibility.ps1 -JobPath "<jobs\job-id.json>" -Visibility public -ApprovePublic -Confirm
```
