# Migration Guide - v4.1.0 Improvements

This guide summarizes key changes and how to adapt existing workflows.

## Configuration Shift: JSON Only
- INI support removed; credentials must live in `scripts/Register-ThisPC.json`.
- Template:
```json
{
  "TenantID": "your-tenant-id-here",
  "AppID": "your-app-client-id-here",
  "AppSecret": "your-app-secret-here"
}
```
- Action: Populate the JSON from your previous INI or vault secrets, delete any lingering INI files, and lock down NTFS permissions (Administrators/SYSTEM).

## Automation & Parameter Updates
- `-DuplicateHandling` controls duplicate device behavior: `Prompt` (default), `Delete`, `Skip`, `Error`.
- `-DryRun` remains the safest validation path before production use.

## Performance & Quality
- Local hardware hash collection no longer spins up unnecessary CIM sessions.
- PowerShell 7 remains required; script auto-installs if missing.

## Testing Checklist
- Run: `.\Register-ThisPC.ps1 -DryRun`
- Validate JSON loads correctly and secrets are not in history.
- Exercise duplicate handling paths relevant to your deployment (e.g., `-DuplicateHandling Skip`).

## Rollback Plan
- If issues arise, validate JSON structure, rerun with `-DryRun`, or temporarily revert to v4.0.0 while retaining JSON configuration.

## Support
- `Get-Help .\Register-ThisPC.ps1 -Detailed`
- Review console/log output for line-specific errors.
- Engage IT Security for credential distribution and access issues.
