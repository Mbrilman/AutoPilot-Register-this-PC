# Repository Guidelines

## Project Structure & Module Organization
- Root launcher: `Register-this-PC.cmd` for OOBE/field execution from drive root.  
- Core logic: `scripts/` contains `Register-ThisPC.ps1` (main flow), `Register-ThisPC.json` (sensitive config), and `branding.ps1`.  
- Documentation and helpers: `scripts/Documentation/` holds guides, examples, ISO prep (`Prepare-ISO-Structure.ps1`), and validation (`Test-Enhancements.ps1`).  
- Deployment notes: see `PRODUCTION_DEPLOYMENT_v4.0.0.md` and `README.md` for release details.

## Build, Test, and Development Commands
- Run launcher (interactive): `.\Register-this-PC.cmd` from repo or ISO/USB root.  
- Direct script run: `.\scripts\Register-ThisPC.ps1 -DuplicateHandling Prompt` (add `-DryRun` to log without uploading).  
- ISO/USB scaffolding: `.\scripts\Documentation\Prepare-ISO-Structure.ps1 -DestinationPath "C:\Temp\AutopilotISO"`.  
- Validation suite: `.\scripts\Documentation\Test-Enhancements.ps1` (syntax, config, and safety checks).  
- Quick reference for field techs: open `scripts/Documentation/QUICK_REFERENCE.md`.

## Coding Style & Naming Conventions
- Target PowerShell 7; 4-space indentation; PascalCase functions/params; use ASCII quotes.  
- Require `Set-StrictMode -Version Latest` and `[CmdletBinding(SupportsShouldProcess)]` on new functions.  
- Include comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, and `[OutputType()]`.  
- Validate inputs (`[ValidateSet]`, `[ValidatePattern]`), prefer `PSCredential`/SecretManagement for secrets.

## Testing Guidelines
- Default to safe runs: `-DryRun` when exercising `Register-ThisPC.ps1`; review generated log in repo root.  
- After code/doc changes, run `Test-Enhancements.ps1`; capture key findings in `scripts/Documentation/TEST_RESULTS.md` if behavior changes.  
- Keep new tests deterministic; avoid network dependency unless mocking or explicitly documenting.

## Commit & Pull Request Guidelines
- Commit messages: short, imperative (e.g., “Update ISO deployment guide”, “Implement code review improvements”).  
- PRs should summarize scope, risk areas (Graph auth, config parsing), and validation evidence (`-DryRun` output, Test-Enhancements results).  
- Exclude secrets: never commit real `Register-ThisPC.json`; use examples in `scripts/Documentation`.  
- Align doc updates with behavior changes (README, deployment guides).

## Security & Configuration Tips
- Restrict NTFS permissions on `Register-ThisPC.json`; treat as HIGHLY SENSITIVE.  
- Rotate client secrets regularly; update configs offline and revalidate before deployment.  
- Protect removable media with BitLocker; remove sensitive files from devices after provisioning.  
- Guard destructive actions with `$PSCmdlet.ShouldProcess()`; require explicit `-Production`/`-Force` flags for changes.

## Agent-Specific Expectations (Macel Standard)
- Present branding via a `Show-Branding` host-only helper (script name, author, company, version, PowerShell version).  
- Add `Show-Summary` in `finally` with timing plus processed/succeeded/failed/skipped counts and an exit status (0–4 mapping: success, partial, failure, cancel, prerequisites).  
- Keep dry-run/WhatIf semantics as default safety; surface a clear warning banner when `-Production`/`-Force` is used.  
- Maintain structured logging (INFO/WARN/ERROR/DEBUG), include error context lines, and prefer retries with exponential backoff for network/API calls.
