# Quick Reference - Autopilot Registration Toolkit

## ⚠️ AUTHORIZED PERSONNEL ONLY ⚠️

---

## Before You Start

### ✅ Pre-Flight Checklist

- [ ] I am authorized to use this toolkit
- [ ] I have completed security traJSONng
- [ ] I am on a secure, managed device
- [ ] I have the latest version of files
- [ ] Credentials have not expired (check rotation date)
- [ ] I have documented this usage

---

## File Overview

| File | Purpose | Sensitivity |
|------|---------|-------------|
| `Register-ThisPC.ps1` | Main registration script | HIGH |
| `Register-ThisPC.json` | **Azure AD credentials** | **CRITICAL** |
| `branding.ps1` | YourCompany logo/branding | LOW |
| `Register-this-PC.cmd` | Batch launcher | MEDIUM |
| `SECURITY_README.md` | Security guidelines | INFO |

---

## Usage Instructions

### Method 1: PowerShell (Recommended)

```powershell
# Open PowerShell as AdmJSONstrator
# Navigate to script directory
cd "X:\Path\To\Script"

# Run the script
.\Register-ThisPC.ps1
```

### Method 2: Command Prompt

```cmd
REM During OOBE, press Shift+F10
REM Navigate to USB drive (usually D:, E:, or F:)
D:
cd Script
Register-this-PC.cmd
```

---

## Script Workflow

1. **PowerShell 7 Check** - Auto-installs if needed (or relaunches if already installed)
2. **Network Test** - Verifies connectivity
3. **Credentials** - Loads from JSON file (displays user/computer/time)
4. **Module Install** - Microsoft.Graph.Authentication
5. **Graph Auth** - Connects to Azure AD
6. **Profile Selection** - Choose Autopilot deployment profile
7. **Hash Collection** - Reads hardware hash from device
8. **Duplicate Check** - ⭐ NEW: Proactively checks if device already registered
9. **Re-registration Prompt** - If exists, shows current vs. new Group Tag
10. **Upload** - Registers device in Autopilot
11. **Confirmation** - Shows success/failure

---

## Autopilot Profile Selection

| Profile Name | Group Tag | Use For |
|--------------|-----------|---------|
| ENS_EU_Autopilot_Deployment | EsdecEU | ESDEC EU devices |
| SF_EU_Autopilot_Deployment | SF | SF EU devices |
| SLG_Autopilot_Deployment | Schletter | Schletter devices |
| SLG_WG_Autopilot_Deployment | Schletter_WG | Schletter White Glove |
| US_Autopilot_Deployment | US | US devices |

**Note:**
- Group Tag and Order ID are now THE SAME VALUE for consistency
- If profile is not in list, select "Manual Group Tag input"

---

## Timing Expectations

| Action | Expected Time |
|--------|---------------|
| PowerShell 7 download | 1-3 minutes |
| Module installation | 30-60 seconds |
| Hardware hash collection | 5-10 seconds |
| Upload to Autopilot | 10-30 seconds |
| Device appears in portal | 5-10 minutes |
| Profile assignment (dynamic groups) | 15 minutes - 1 hour |

---

## Troubleshooting

### "Network connectivity test failed"
- Check internet connection
- Verify firewall allows Graph API access
- Try different network if on guest WiFi

### "Authentication to Graph API failed"
- Verify credentials in JSON file are correct
- Check if App Secret has expired (rotate every 90 days)
- Ensure API permissions are granted and consented

### "Failed to collect hardware hash"
- Run script as AdmJSONstrator
- Verify device is physical or supported VM
- Check WMI service is running: `Get-Service winmgmt`

### "Device already exists"
- ⭐ NEW: Script now checks PROACTIVELY and shows you current vs. new Group Tag
- You'll be prompted to delete and re-register automatically
- Select [Y] to delete existing and register with new settings
- Select [N] to cancel and keep existing registration
- May need to wait 5-10 seconds after deletion for Azure AD sync

### Script hangs or freezes
- Press `Ctrl+C` to cancel
- Check network connectivity
- Review error messages carefully
- Restart and try again

---

## After Registration

### ✅ Post-Registration Checklist

- [ ] Verify device appears in Intune portal
- [ ] Document registration in asset management
- [ ] Delete JSON file if copied to device
- [ ] Log out of admJSONstrative session
- [ ] Reboot device (if prompted)

### Verification

1. Log into Intune portal: https://intune.microsoft.com
2. Navigate: Devices > Windows > Windows enrollment > Devices
3. Search for device serial number
4. Verify:
   - ✅ Device appears in list
   - ✅ Group Tag is correct
   - ✅ Profile assigned (may take up to 1 hour)

---

## Security Reminders

### 🔴 DO NOT:
- ❌ Share credentials with unauthorized personnel
- ❌ Email or message the JSON file
- ❌ Leave USB drive with credentials unattended
- ❌ Commit JSON file to Git/version control
- ❌ Store on unencrypted media

### ✅ DO:
- ✅ Use encrypted USB drives (BitLocker To Go)
- ✅ Delete credentials after use
- ✅ Rotate App Secret every 90 days
- ✅ Report security incidents immediately
- ✅ Document each registration

---

## Emergency Contacts

**IT Security Team (Credential Compromise):**
- Email: security@YourCompany.com
- Phone: [Emergency Hotline]

**IT Support (Technical Issues):**
- Email: itsupport@YourCompany.com
- Phone: [Support Number]

**After Hours:**
- On-Call: [Emergency Contact]

---

## Credential Rotation Schedule

**App Secret Expiration Check:**
```powershell
# Check in Azure Portal
# Azure AD > App registrations > [Your App] > Certificates & secrets
# Note expiration date in JSON file header
```

**Next Rotation Due:** [Check JSON file header or Azure Portal]

---

## Common Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Device registered successfully |
| 1 | Generic error | Check error message, review logs |
| 401/403 | Auth failed | Check credentials, permissions |
| 409 | Device exists | Delete existing entry, retry |

---

## DryRun Mode (Testing)

Test the script without making changes:

```powershell
.\Register-ThisPC.ps1 -DryRun
```

This will:
- ✅ Simulate all operations
- ✅ Show what would happen
- ❌ NOT install PowerShell 7
- ❌ NOT install modules
- ❌ NOT connect to Graph
- ❌ NOT upload hardware hash

---

## Version Information

- **Script Version:** 4.0.0 - PRODUCTION RELEASE
- **Last Updated:** 17/11/2025
- **Author:** Community Edition

### What's New in v4.0.0
- 🚀 **Production Ready**: Removed all pause statements - automation friendly!
- 🚀 **Clean Exit**: No user interaction required after completion
- 🚀 **Perfect for OOBE**: Ideal for automated Windows deployments

### Features (from v3.3.0)
- ⭐ **Unified Group Tag**: Group Tag and Order ID now use same value
- ⭐ **Proactive Duplicate Detection**: Checks BEFORE upload
- ⭐ **Smart Re-registration**: Compare current vs. new Group Tag
- ⭐ **Improved PowerShell 7**: No unnecessary re-downloads
- ⭐ **Better Network Test**: Handles authentication responses correctly

---

## Additional Resources

- **Full Security Guide:** `SECURITY_README.md`
- **Script Source:** `Register-ThisPC.ps1`
- **Autopilot Documentation:** [Microsoft Learn - Windows Autopilot](https://learn.microsoft.com/en-us/mem/autopilot/)
- **Graph API Reference:** [Microsoft Graph API Docs](https://learn.microsoft.com/en-us/graph/)

---

**Remember: When in doubt, ask IT Security! Better to ask than to create a security incident.**


