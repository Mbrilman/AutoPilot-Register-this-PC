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
    ├── Register-ThisPC.json      (🔴 SENSITIVE credentials )
    ├── branding.ps1              (Corporate branding module)
    ├── .gitignore                (Git protection)
    │
    └── Documentation/            (Reference materials)
        ├── README.md
        ├── SECURITY_README.md
        ├── QUICK_REFERENCE.md
        ├── MIGRATION_GUIDE.md
        └── ISO_DEPLOYMENT_GUIDE.md

```

## Why This Structure?

**1. OOBE Usability**
- During Windows OOBE, users press `Shift+F10` to open Command Prompt
- The prompt opens at the root of the boot drive
- Users can simply type: `Register-ThisPC.cmd` (no navigation needed)

**2. Security**
- Sensitive files (JSON with credentials) are in `scripts/` subfolder, not root
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

- The `Register-ThisPC.json` file contain HIGHLY SENSITIVE Azure AD credentials
- Only authorized IT personnel should have access to this structure
- Encrypt USB drives with BitLocker To Go
- Track each ISO/USB deployment for compliance
- Rotate credentials every 90 days
- Delete files from devices after provisioning

**Configuration File Options:**
- **JSON (preferred)**: Modern, cleaner format - `Register-ThisPC.json`
- Script checks for JSON

See `scripts/Documentation/SECURITY_README.md` and `MIGRATION_GUIDE.md` for complete security guidelines and migration information.

## Version Information

**Toolkit Version:** 4.1.0 - CODE QUALITY UPDATE
**Last Updated:** 18/11/2025
**Author:** Community Edition

### What's New in v4.1.0
- **JSON Configuration Support**: Modern JSON config files (preferred over INI)
- **Enhanced Automation**: New `-DuplicateHandling` parameter for unattended deployments
- **Better Validation**: ValidateSet attributes for platform architectures
- **Performance Optimization**: Removed unnecessary CIM session overhead
- **Full Backward Compatibility**: Existing INI files and workflows continue to work
- **Comprehensive Documentation**: New MIGRATION_GUIDE.md and examples

### Key Features
- **Dual Config Format**: Supports both JSON (modern) and INI (legacy)
- **Automation Modes**: Prompt, Delete, Skip, or Error on duplicates
- **Unified Group Tag Management**: Group Tag and Order ID use the same value
- **Proactive Duplicate Detection**: Checks for existing devices BEFORE upload
- **Smart Re-registration**: Shows current vs. new Group Tag comparison
- **Improved PowerShell 7 Handling**: No unnecessary re-downloads
- **Enhanced Network Testing**: Better API authentication response handling

### Previous Versions
- **v4.0.0**: Production release with automation-friendly clean exit
- **v3.3.0**: Unified Group Tag and proactive duplicate detection

## Related Documentation

- **Migration Guide:** `scripts/Documentation/MIGRATION_GUIDE.md` ⭐ NEW
- **Complete Guide:** `scripts/Documentation/ISO_DEPLOYMENT_GUIDE.md`
- **Quick Reference:** `scripts/Documentation/QUICK_REFERENCE.md`
- **Security Guide:** `scripts/Documentation/SECURITY_README.md`
- **JSON Template:** `scripts/Documentation/Register-ThisPC.json.example` ⭐ NEW

---

**Classification:** INTERNAL - RESTRICTED
**For:** Authorized IT Personnel Only
