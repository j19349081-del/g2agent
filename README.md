# G2Agent

PowerShell scripts for reviewing exported NotebookLM videos and uploading them to YouTube.

## Prerequisites

- NotebookLM account with access to the source notebooks and video export; export media manually.
- YouTube channel access, a Google Cloud project with YouTube Data API v3 enabled, a Desktop OAuth client JSON, and Google Cloud CLI (`gcloud`). Authorize with `scripts/Connect-G2YouTube.ps1`.
- Windows PowerShell 5.1 or later. `ffprobe` is optional for media checks.
