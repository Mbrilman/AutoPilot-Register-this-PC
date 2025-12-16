# PR Checklist (Repository Guidelines)

## Summary
- What changed and why? Be specific about Autopilot flow, config parsing, or deployment behavior.

## Validation
- [ ] `.\Register-ThisPC.ps1 -DryRun` (attach log location or key lines)
- [ ] `.\scripts\Documentation\Test-Enhancements.ps1`
- [ ] Additional tests (list): 

## Risk & Impact
- Areas touched: (e.g., Graph auth, INI/JSON parsing, ISO prep, OOBE launcher)
- Known risks/mitigations:
- Backward compatibility: (yes/no; details)

## Security
- Credentials/secrets handled? (no real secrets in PR)
- Sensitive files excluded (`Register-ThisPC.ini`/`.json`)? 

## Documentation
- Updated docs? (README, AGENTS, deployment guides)
- Screenshots/log snippets (if UI/log changes):

## Production Flag
- Does this change alter `-Production`/`-Force` behavior or safety defaults? Describe.
