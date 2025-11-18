# Migration Guide - v4.1.0 Improvements

This guide covers the improvements made to the Register-ThisPC script based on code review feedback.

## Overview of Changes

### 1. Platform Architecture Validation
**What changed**: Added `ValidateSet` parameter validation for PowerShell architecture selection.

**Impact**: Better parameter validation and IDE auto-completion support.

**Action Required**: None - this is a code quality improvement with no breaking changes.

---

### 2. JSON Configuration Support
**What changed**: The script now supports JSON configuration files as an alternative to INI files.

**Why**: JSON is more modern, easier to parse, and less complex than INI files.

**Migration Path**:

#### Option A: Continue using INI (no action required)
Your existing `Register-ThisPC.ini` will continue to work. The script maintains full backward compatibility.

#### Option B: Migrate to JSON (recommended)
1. Create a new file: `Register-ThisPC.json` in the `scripts/` folder
2. Copy this template:
```json
{
  "TenantID": "your-tenant-id-here",
  "AppID": "your-app-client-id-here",
  "AppSecret": "your-app-secret-here"
}
```
3. Fill in your credentials from the existing INI file
4. Delete or rename the old INI file (optional)

**Priority Order**: The script checks for JSON first, then falls back to INI.

---

### 3. Optimized Hardware Collection
**What changed**: Removed unnecessary CIM session creation for local hardware queries.

**Why**: When querying local resources, PowerShell can access WMI/CIM directly without creating a session.

**Impact**:
- Slightly improved performance
- Cleaner, simpler code
- Same functionality

**Action Required**: None - this is an internal optimization.

---

### 4. Automation Support
**What changed**: Added `-DuplicateHandling` parameter to control duplicate device behavior without user prompts.

**Why**: The original script required user input when duplicates were found, breaking full automation scenarios.

**New Parameter**: `-DuplicateHandling`

Valid values:
- **Prompt** (default): Ask the user what to do when a duplicate is found
- **Delete**: Automatically delete and re-register the device
- **Skip**: Skip registration and keep existing device settings
- **Error**: Throw an error and abort registration

#### Usage Examples:

**Interactive mode (default - unchanged behavior)**:
```powershell
.\Register-ThisPC.ps1
```

**Automated deployment with duplicate handling**:
```powershell
.\Register-ThisPC.ps1 -DuplicateHandling Delete
```

**Automated deployment that skips duplicates**:
```powershell
.\Register-ThisPC.ps1 -DuplicateHandling Skip
```

**Strict mode - error on duplicates**:
```powershell
.\Register-ThisPC.ps1 -DuplicateHandling Error
```

**Automated deployment with dry run testing**:
```powershell
.\Register-ThisPC.ps1 -DuplicateHandling Delete -DryRun
```

---

## Automation Scenarios

### Scenario 1: SCCM/Intune Task Sequence
For fully automated deployments where duplicate devices should always be re-registered:

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Register-ThisPC.ps1" -DuplicateHandling Delete
```

### Scenario 2: Provisioning Package
For provisioning packages where you want to skip devices that are already registered:

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Register-ThisPC.ps1" -DuplicateHandling Skip
```

### Scenario 3: Manual Technician Mode
For technicians who want to be prompted before making changes:

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Register-ThisPC.ps1" -DuplicateHandling Prompt
```

---

## Security Considerations

### JSON Configuration Files
**IMPORTANT**: JSON files containing credentials must be protected just like INI files.

The `.gitignore` has been updated to exclude:
- `Register-ThisPC.json`
- `*.json` (all JSON files in the scripts folder)

**Ensure you**:
1. Set proper file permissions (Administrators only)
2. Never commit credentials to version control
3. Rotate secrets regularly (every 90 days recommended)
4. Delete sensitive files from devices after provisioning

---

## Testing Recommendations

Before deploying to production:

1. **Test with DryRun mode**:
```powershell
.\Register-ThisPC.ps1 -DuplicateHandling Delete -DryRun
```

2. **Test duplicate handling**: Register a device, then run the script again with different `-DuplicateHandling` values to verify behavior.

3. **Test JSON config**: If migrating to JSON, verify credentials load correctly before decommissioning INI files.

---

## Rollback Plan

If you encounter issues with these changes:

1. **JSON Issues**: Simply delete `Register-ThisPC.json` and the script will fall back to `Register-ThisPC.ini`

2. **DuplicateHandling Issues**: Omit the parameter to use default "Prompt" behavior (original behavior)

3. **Complete Rollback**: Revert to the previous version (v4.0.0) if needed

---

## Questions or Issues?

If you encounter problems with these changes:
1. Check the script's help: `Get-Help .\Register-ThisPC.ps1 -Detailed`
2. Review error messages carefully
3. Test with `-DryRun` to debug without making changes
4. Contact IT Security Team for credentials or access issues

---

## Summary

These improvements make the script:
- ✅ More maintainable (better validation)
- ✅ More flexible (JSON support)
- ✅ More efficient (optimized CIM queries)
- ✅ More automation-friendly (DuplicateHandling parameter)
- ✅ Fully backward compatible (existing workflows unchanged)
