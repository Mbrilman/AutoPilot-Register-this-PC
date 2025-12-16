# Group Tag Mapping Configuration Guide

**Version:** 4.1.0
**Last Updated:** December 16, 2025
**Classification:** INTERNAL - RESTRICTED

---

## Overview

The `GroupTagMapping.json` file provides external configuration for mapping Autopilot Deployment Profile names to their corresponding Group Tags. This separation of configuration from code makes it easier to manage and update profile mappings without modifying the main PowerShell script.

---

## File Location

```
scripts/
├── Register-ThisPC.ps1
├── GroupTagMapping.json          ← Configuration file
├── Register-ThisPC.json          ← Credentials (SENSITIVE)
└── branding.ps1
```

**Path:** `scripts/GroupTagMapping.json`

---

## File Structure

```json
{
  "_comment": "Group Tag Mapping Configuration",
  "_description": "Maps Autopilot Profile Display Names to Group Tags for device registration",
  "_note": "Both 'groupTag' and 'purchaseOrderIdentifier' (Order ID) use the same value for consistency",
  "_security": "This file contains deployment configuration. Protect access accordingly.",
  "mappings": {
    "ENS_EU_Autopilot_Deployment": "EsdecEU",
    "SF_EU_Autopilot_Deployment": "SF",
    "SLG_Autopilot_Deployment": "Schletter",
    "SLG_WG_Autopilot_Deployment": "Schletter_WG",
    "US_Autopilot_Deployment": "US"
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `_comment` | String | Human-readable comment (ignored by script) |
| `_description` | String | Description of file purpose (ignored by script) |
| `_note` | String | Important implementation note (ignored by script) |
| `_security` | String | Security guidance (ignored by script) |
| `mappings` | Object | Key-value pairs mapping profile names to group tags |

**Note:** Fields starting with underscore (`_`) are metadata comments and are ignored by the script.

---

## How It Works

### 1. Script Loading Process

When `Register-ThisPC.ps1` runs, it:

1. **Looks for the file** at `scripts/GroupTagMapping.json`
2. **Loads the JSON** and parses the `mappings` object
3. **Converts to hashtable** for efficient lookup
4. **Falls back** to default mappings if file is missing or invalid

### 2. Console Output During Load

```
Loading Group Tag mappings from C:\scripts\GroupTagMapping.json...
Successfully loaded 5 Group Tag mappings.
```

### 3. Fallback Behavior

If the JSON file is missing or corrupted:
- ⚠️ **Warning displayed:** "Group Tag mapping file not found" or "Failed to load"
- ✅ **Default mappings used:** Script continues with built-in defaults
- 📝 **No failure:** Registration process continues normally

---

## Mapping Logic

### Autopilot Profile → Group Tag

Each entry maps an Autopilot Deployment Profile display name to a short Group Tag:

| Autopilot Profile Display Name | Group Tag | Use Case |
|-------------------------------|-----------|----------|
| `ENS_EU_Autopilot_Deployment` | `EsdecEU` | ESDEC EU devices |
| `SF_EU_Autopilot_Deployment` | `SF` | SF EU devices |
| `SLG_Autopilot_Deployment` | `Schletter` | Schletter devices |
| `SLG_WG_Autopilot_Deployment` | `Schletter_WG` | Schletter White Glove |
| `US_Autopilot_Deployment` | `US` | US devices |

### Why Same Value for Group Tag and Order ID?

Both `groupTag` and `purchaseOrderIdentifier` (Order ID) are set to the same value because:

1. **Azure AD Dynamic Groups** filter on Group Tag
2. **Consistency** prevents confusion in Intune portal
3. **Simplified Management** - only one value to track

---

## How to Add New Mappings

### Step 1: Edit the JSON File

Open `GroupTagMapping.json` and add your new profile mapping:

```json
{
  "mappings": {
    "ENS_EU_Autopilot_Deployment": "EsdecEU",
    "SF_EU_Autopilot_Deployment": "SF",
    "SLG_Autopilot_Deployment": "Schletter",
    "SLG_WG_Autopilot_Deployment": "Schletter_WG",
    "US_Autopilot_Deployment": "US",
    "NEW_PROFILE_NAME": "NewGroupTag"  ← Add here
  }
}
```

### Step 2: Validate JSON Syntax

Before deploying, validate the JSON:

```powershell
# Test JSON parsing
$testPath = "C:\scripts\AutoPilot-Register-this-PC\scripts\GroupTagMapping.json"
try {
    $config = Get-Content $testPath -Raw | ConvertFrom-Json
    Write-Host "✅ JSON is valid" -ForegroundColor Green
    Write-Host "Found $($config.mappings.PSObject.Properties.Count) mappings" -ForegroundColor Cyan
    $config.mappings.PSObject.Properties | ForEach-Object {
        Write-Host "  - $($_.Name) → $($_.Value)"
    }
}
catch {
    Write-Host "❌ JSON is invalid: $($_.Exception.Message)" -ForegroundColor Red
}
```

### Step 3: Create Corresponding Azure AD Dynamic Group

In Azure AD, create a dynamic group with filter:

```
(device.devicePhysicalIds -any (_ -eq "[OrderID]:NewGroupTag"))
```

### Step 4: Test the Mapping

Run the script with `-DryRun` to test:

```powershell
.\scripts\Register-ThisPC.ps1 -DryRun
```

---

## How to Modify Existing Mappings

### Scenario: Rename a Group Tag

**Before:**
```json
"SLG_Autopilot_Deployment": "Schletter"
```

**After:**
```json
"SLG_Autopilot_Deployment": "Schletter_EU"
```

### ⚠️ Important Considerations:

1. **Update Azure AD dynamic groups** to match new Group Tag
2. **Existing devices** will keep old Group Tag until re-registered
3. **Communicate changes** to all IT personnel using the tool
4. **Update documentation** and quick reference guides
5. **Test thoroughly** before production deployment

---

## Deployment

### ISO/USB Deployment Structure

When creating an ISO or USB, ensure the file structure includes:

```
ISO_Root/
├── Register-ThisPC.cmd
└── scripts/
    ├── Register-ThisPC.ps1
    ├── Register-ThisPC.json        (SENSITIVE - credentials)
    ├── GroupTagMapping.json        ← Deploy this file
    ├── branding.ps1
    └── Documentation/
```

### Checklist Before Deployment

- [ ] JSON syntax is valid (test with `ConvertFrom-Json`)
- [ ] All Group Tags match Azure AD dynamic group filters
- [ ] File is included in ISO/USB structure
- [ ] Changes documented in change log
- [ ] IT personnel notified of updates
- [ ] Backup of previous version saved

---

## Troubleshooting

### Issue: "Group Tag mapping file not found"

**Symptom:**
```
WARNING: Group Tag mapping file not found at: C:\scripts\GroupTagMapping.json
WARNING: Using default mappings.
```

**Solution:**
- Verify file exists in `scripts/` folder
- Check file name spelling (case-sensitive on some systems)
- Ensure file wasn't accidentally deleted
- Script will use fallback mappings (registration still works)

---

### Issue: "Failed to load Group Tag mappings from JSON"

**Symptom:**
```
WARNING: Failed to load Group Tag mappings from JSON: Invalid JSON
WARNING: Using default mappings as fallback.
```

**Causes:**
- Syntax error in JSON (missing comma, bracket, quote)
- File encoding issue (should be UTF-8)
- File corruption

**Solution:**
1. Validate JSON syntax with online validator or:
   ```powershell
   Get-Content .\GroupTagMapping.json -Raw | ConvertFrom-Json
   ```
2. Check for common errors:
   - Missing commas between entries
   - Trailing comma after last entry
   - Unescaped quotes or backslashes
3. Use a JSON-aware editor (VS Code, Notepad++)
4. Re-create from template if corrupted

---

### Issue: Profile Shows "Not Mapped"

**Symptom:**
When selecting profiles, some show "(Group Tag: Not Mapped)"

**Cause:**
Profile display name in Intune doesn't match any key in JSON

**Solution:**
1. Check exact profile name in Intune portal:
   - Navigate: Devices > Windows > Windows enrollment > Deployment Profiles
   - Copy the exact "Profile name"
2. Add entry to `GroupTagMapping.json`:
   ```json
   "EXACT_PROFILE_NAME_FROM_INTUNE": "DesiredGroupTag"
   ```
3. Reload script or re-run registration

---

## Security Considerations

### File Protection

**Access Control:**
- Restrict read/write to Administrators only
- Not as sensitive as `Register-ThisPC.json` (no credentials)
- Still protect from unauthorized modification

**NTFS Permissions:**
```powershell
# Set appropriate permissions
$filePath = "C:\scripts\AutoPilot-Register-this-PC\scripts\GroupTagMapping.json"
$acl = Get-Acl $filePath
$acl.SetAccessRuleProtection($true, $false)

# Remove all existing rules
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

# Add Administrators - Full Control
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl", "Allow"
)
$acl.AddAccessRule($adminRule)

# Add SYSTEM - Full Control
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM", "FullControl", "Allow"
)
$acl.AddAccessRule($systemRule)

Set-Acl $filePath $acl
```

### Version Control

- ✅ **Safe to commit** to Git (contains no credentials)
- 📝 **Track changes** in version control
- 🔄 **Review changes** before merging
- 📋 **Document updates** in commit messages

---

## Best Practices

### 1. **Consistent Naming**
- Use clear, descriptive Group Tag values
- Follow organizational naming conventions
- Document meaning of each tag

### 2. **Regular Reviews**
- Quarterly review of all mappings
- Remove obsolete profiles
- Update documentation

### 3. **Change Management**
- Test changes in development environment first
- Use `-DryRun` parameter before production
- Communicate changes to technicians
- Keep backup of previous version

### 4. **Documentation**
- Maintain list of all Group Tags and their purpose
- Document which Azure AD groups use each tag
- Keep mapping table in IT knowledge base

---

## Example: Multi-Tenant Configuration

For organizations with multiple tenants, you can maintain separate mapping files:

```
scripts/
├── GroupTagMapping.json          (Default/Production)
├── GroupTagMapping-Dev.json      (Development)
├── GroupTagMapping-Test.json     (Testing)
└── GroupTagMapping-EU.json       (EU Region)
```

To use alternate file, modify script or create wrapper:

```powershell
# Copy desired mapping before running
Copy-Item "GroupTagMapping-EU.json" "GroupTagMapping.json" -Force
.\Register-ThisPC.ps1
```

---

## Related Documentation

- **Main README:** `scripts/Documentation/README.md`
- **Quick Reference:** `scripts/Documentation/QUICK_REFERENCE.md`
- **Migration Guide:** `scripts/Documentation/MIGRATION_GUIDE.md`
- **Security Guide:** `scripts/Documentation/SECURITY_README.md`
- **Deployment Guide:** `scripts/Documentation/ISO_DEPLOYMENT_GUIDE.md`

---

## Change Log

### v4.1.0 (December 16, 2025)
- ✅ Initial creation of GroupTagMapping.json
- ✅ Externalized mappings from Register-ThisPC.ps1
- ✅ Added fallback mechanism for missing/invalid file
- ✅ Documented configuration and usage

---

## Support

**For Questions About:**
- **Profile Mappings:** Contact IT Autopilot Team
- **Azure AD Dynamic Groups:** Contact Azure AD Administrators
- **File Issues:** Contact IT Support
- **Security Concerns:** Contact IT Security Team

---

**Document Version:** 1.0
**Author:** Community Edition
**Classification:** INTERNAL - RESTRICTED
**Next Review:** March 16, 2026
