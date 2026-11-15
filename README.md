# G2Agent

PowerShell automation for NotebookLM video generation and YouTube publishing.

## Prerequisites

- **Local:** Windows PowerShell 5.1+ and [Google Cloud CLI](https://cloud.google.com/sdk/docs/install). `ffprobe` is optional for media checks.

## NotebookLM API access

Google's [consumer NotebookLM help](https://support.google.com/notebooklm/answer/16454555) documents Video Overview generation and download through the NotebookLM interface. The public documentation does not currently provide a supported consumer NotebookLM API, API-key flow, or OAuth scope for programmatically creating notebooks, generating Video Overviews, and retrieving the result. A browser login token, API key, or copied session cookie is not a supported substitute; do not scrape private endpoints.

Google documents [NotebookLM Enterprise](https://cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs) as a separately configured Google Cloud product. Its [roles and setup](https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/overview) describe Enterprise access, but the currently published docs do not establish supported API endpoints for the complete create-source-generate-download video workflow. The `roles/discoveryengine.notebookLmUser` role grants product access; it does not by itself prove that these API operations are available.

Before enabling automated NotebookLM generation, Google must provide a supported API reference for each required operation and document its authentication scopes/IAM permissions, product eligibility, and artifact download method. If such an API becomes available, use its documented Google Cloud OAuth/ADC flow and least-privilege permissions. Until then, end-to-end automation from NotebookLM is blocked; YouTube API credentials cannot grant NotebookLM access.

References: [NotebookLM Enterprise overview and roles](https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/overview), [Google Cloud Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials).

## YouTube API OAuth setup

Uploads and private-channel operations require **OAuth user authorization**, not an API key. An API key only identifies a Google Cloud project for public-data requests; it cannot upload a video or access a private channel.

1. In the [Google Cloud Console](https://console.cloud.google.com/), create/select a project and [enable YouTube Data API v3](https://console.cloud.google.com/apis/library/youtube.googleapis.com).
2. Configure the [OAuth consent screen / Google Auth Platform](https://console.cloud.google.com/auth/overview). Select the appropriate audience, provide the required app details, and add your account as a test user if the app is in testing.
3. On [OAuth Clients](https://console.cloud.google.com/auth/clients), create an **OAuth client ID** of type **Desktop app** and download its JSON file. Store it outside this repository. Desktop client secrets cannot be treated as confidential; do not commit or share the file.
4. From the repository folder, authorize the account that owns or manages the target channel:

	`./scripts/Connect-G2YouTube.ps1 -ClientIdFile "C:\secure\path\oauth-client.json"`

	Complete Google's consent flow in the browser. The script currently requests `https://www.googleapis.com/auth/youtube` (manage the YouTube account) because it checks the authorized channel and uploads/updates video status. Google's [scope reference](https://developers.google.com/youtube/v3/guides/authentication#scopes) lists available narrower scopes; use one only after verifying it supports all operations the scripts call.

5. Google Cloud CLI stores the resulting Application Default Credentials under your Windows user profile. The scripts obtain short-lived access tokens when needed; do not paste tokens into chat, save them in project settings, or commit them. To check ADC without displaying a token, run `./scripts/Test-G2Prerequisites.ps1 -CheckAuthentication`.
6. List available channels with `./scripts/Get-G2Channel.ps1`, verify the exact channel ID, then set `expectedChannelId` in the ignored local `settings.json`. Uploads default to private. Public publishing needs explicit per-video approval.

Official guides: [YouTube API project/authentication setup](https://developers.google.com/youtube/v3/guides/authentication), [OAuth for desktop apps](https://developers.google.com/identity/protocols/oauth2/native-app), [YouTube video uploads](https://developers.google.com/youtube/v3/docs/videos/insert), [OAuth consent screen setup](https://support.google.com/cloud/answer/10311615), and [API keys versus OAuth credentials](https://cloud.google.com/docs/authentication/api-keys).
