# ISO_Root - Ready-to-Deploy Structure

This folder contains the **exact structure** that should be used when creating an ISO or USB drive for Windows Autopilot device registration during OOBE.

## Purpose

The `ISO_Root` folder is structured to match the deployment requirements for OOBE (Out-of-Box Experience) usage:

```
ISO_Root/
├── Register-ThisPC.cmd           (Launcher at root - users run this)
│
└── scripts/
    ├── Register-ThisPC.ps1       (Main registration script)
    ├── Register-ThisPC.ini       (🔴 SENSITIVE credentials)
    ├── branding.ps1      (Corporate branding module)
    ├── .gitignore                (Git protection)
    │
    └── Documentation/            (Reference materials)
        ├── README.md
        ├── SECURITY_README.md
        ├── QUICK_REFERENCE.md
        ├── ISO_DEPLOYMENT_GUIDE.md
        ├── Test-Enhancements.ps1
        ├── TEST_RESULTS.md
        └── Prepare-ISO-Structure.ps1
```

## Why This Structure?

**1. OOBE Usability**
- During Windows OOBE, users press `Shift+F10` to open Command Prompt
- The prompt opens at the root of the boot drive
- Users can simply type: `Register-ThisPC.cmd` (no navigation needed)

**2. Security**
- Sensitive files (INI with credentials) are in `scripts/` subfolder, not root
- Clear separation between launcher and components
- Documentation included but organized

**3. Maintainability**
- All PowerShell scripts in logical `scripts/` folder
- Documentation travels with the toolkit
- Easy to update individual components

## Usage for ISO/USB Creation

### Option 1: Copy Directly to USB
```powershell
# Copy entire ISO_Root contents to USB drive
Copy-Item "C:\...\ISO_Root\*" -Destination "E:\" -Recurse -Force
```

### Option 2: Create ISO File
```powershell
# Use your preferred ISO creation tool (ImgBurn, PowerISO, oscdimg, etc.)
# Point the tool to the ISO_Root folder as the source
```

### Option 3: Use Automated Preparation Script
```powershell
# The Prepare-ISO-Structure.ps1 script can also create this structure
.\scripts\Documentation\Prepare-ISO-Structure.ps1 -DestinationPath "D:\MyISO"
```

## OOBE Deployment

Once the ISO/USB is created and mounted during Windows setup:

1. Press `Shift + F10` during OOBE
2. Identify the drive letter (D:, E:, F:, etc.)
   ```cmd
   D:
   dir
   ```
3. Run the launcher:
   ```cmd
   Register-ThisPC.cmd
   ```
4. Follow the on-screen prompts

## Security Warnings

⚠️ **IMPORTANT**

- The `Register-ThisPC.ini` file contains HIGHLY SENSITIVE Azure AD credentials
- Only authorized IT personnel should have access to this structure
- Encrypt USB drives with BitLocker To Go
- Track each ISO/USB deployment for compliance
- Rotate credentials every 90 days
- Delete files from devices after provisioning

See `scripts/Documentation/SECURITY_README.md` for complete security guidelines.

## Version Information

**Toolkit Version:** 4.0.0 - PRODUCTION RELEASE
**Last Updated:** 17/11/2025
**Author:** Community Edition

### What's New in v4.0.0
- **Production Ready**: Removed all pause statements for automated deployments
- **Clean Exit**: Script exits without user interaction after completion
- **Automation Friendly**: Perfect for scripted OOBE deployments
- **All v3.3.0 Features**: Includes all previous enhancements
- **Fully Validated**: Complete documentation and testing

### Features (from v3.3.0)
- **Unified Group Tag Management**: Group Tag and Order ID use the same value
- **Proactive Duplicate Detection**: Checks for existing devices BEFORE upload
- **Smart Re-registration**: Shows current vs. new Group Tag comparison
- **Improved PowerShell 7 Handling**: No unnecessary re-downloads
- **Enhanced Network Testing**: Better API authentication response handling

## Related Documentation

- **Complete Guide:** `scripts/Documentation/ISO_DEPLOYMENT_GUIDE.md`
- **Quick Reference:** `scripts/Documentation/QUICK_REFERENCE.md`
- **Security Guide:** `scripts/Documentation/SECURITY_README.md`
- **Test Results:** `scripts/Documentation/TEST_RESULTS.md`

---

**Classification:** INTERNAL - RESTRICTED
**For:** Authorized IT Personnel Only
