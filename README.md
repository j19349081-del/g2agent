# G2Agent

PowerShell automation for NotebookLM video generation and YouTube publishing.

## Prerequisites

- **NotebookLM:** NotebookLM Enterprise on Google Cloud, project/location configured, service enabled, and an officially supported API with access to create/manage notebooks, add sources, generate Video Overviews, and retrieve the finished video. Grant the runtime identity the documented NotebookLM IAM role and API scopes. The consumer NotebookLM app's documented workflow is UI-based; do not use private endpoints or browser automation as an API substitute. Confirm that Google's current API actually exposes every required video operation before implementation—otherwise fully automatic NotebookLM generation is not available through a supported API.
- **YouTube:** channel access; Google Cloud project with YouTube Data API v3 enabled; OAuth Desktop client and authorized OAuth credentials with the YouTube upload/management scope. Configure the target channel ID and keep credentials outside this repository.
- **Local:** Windows PowerShell 5.1+; `gcloud` for current scripts; `ffprobe` optional for media checks.

Uploads should default to private. Public publishing requires explicit per-video approval.
