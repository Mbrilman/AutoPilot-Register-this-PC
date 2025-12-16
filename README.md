# Windows Autopilot Registration Tool 🐙

**Version:** 4.1.0
**Status:** Production Ready
**Classification:** INTERNAL - RESTRICTED

---

## Overview

This toolkit provides automated Windows Autopilot device registration during OOBE (Out-of-Box Experience). Deploy via ISO or USB to register devices with Microsoft Intune Autopilot service.

## Project Structure

```
AutoPilot-Register-this-PC/
├── README.md                      (This file)
├── Register-ThisPC.cmd            (Launcher - run during OOBE)
│
└── scripts/
    ├── Register-ThisPC.ps1        (Main PowerShell script)
    ├── Register-ThisPC.json       (🔴 SENSITIVE - Credentials)
    ├── GroupTagMapping.json       (Profile to Group Tag mappings)
    ├── branding.ps1               (Octopus ASCII art & branding)
    ├── .gitignore                 (Git protection)
    │
    └── Documentation/
        ├── README.md              (Detailed documentation)
        ├── GROUPTAG_MAPPING_GUIDE.md
        ├── SECURITY_README.md
        ├── QUICK_REFERENCE.md
        ├── MIGRATION_GUIDE.md
        └── ISO_DEPLOYMENT_GUIDE.md
```

## Quick Start

### OOBE Deployment

1. **Boot from ISO/USB** containing this toolkit
2. **Press `Shift + F10`** during Windows OOBE to open Command Prompt
3. **Navigate to drive letter** (usually D:, E:, or F:)
   ```cmd
   D:
   dir
   ```
4. **Run the launcher:**
   ```cmd
   Register-ThisPC.cmd
   ```
5. **Follow on-screen prompts** to complete registration

### Testing (Dry Run)

```powershell
.\scripts\Register-ThisPC.ps1 -DryRun
```

### Automated Deployment

```powershell
# Auto-delete duplicates and re-register
.\scripts\Register-ThisPC.ps1 -DuplicateHandling Delete

# Skip registration if device already exists
.\scripts\Register-ThisPC.ps1 -DuplicateHandling Skip
```

## What's New in v4.1.0

### 🐙 Octopus Branding
- Modern octopus ASCII art replaces unicorn theme
- Ocean-themed color scheme (Cyan, Blue, DarkCyan)
- Cleaner execution without debug pauses

### 📋 External Group Tag Mappings
- **NEW:** `GroupTagMapping.json` for easy configuration
- Separates configuration from code
- Simple JSON structure for profile mappings
- Fallback protection if file missing

### Key Features

| Feature | Description |
|---------|-------------|
| **JSON Configuration** | Single `Register-ThisPC.json` file for credentials |
| **External Mappings** | `GroupTagMapping.json` for profile-to-tag assignments |
| **Automation Modes** | `-DuplicateHandling`: Prompt, Delete, Skip, or Error |
| **Auto PowerShell 7** | Automatically installs PS7 if needed |
| **Retry Logic** | Exponential backoff for network operations |
| **Proactive Detection** | Checks for duplicates BEFORE upload |
| **Smart Re-registration** | Shows current vs. new Group Tag comparison |

## Configuration Files

### 1. Register-ThisPC.json (SENSITIVE)

Contains Azure AD credentials - **NEVER commit to Git!**

```json
{
  "TenantID": "your-tenant-id-here",
  "AppID": "your-app-client-id-here",
  "AppSecret": "your-app-secret-here"
}
```

### 2. GroupTagMapping.json

Maps Autopilot profiles to Group Tags:

```json
{
  "mappings": {
    "ENS_EU_Autopilot_Deployment": "EsdecEU",
    "SF_EU_Autopilot_Deployment": "SF",
    "SLG_Autopilot_Deployment": "Schletter",
    "SLG_WG_Autopilot_Deployment": "Schletter_WG",
    "US_Autopilot_Deployment": "US"
  }
}
```

See `scripts/Documentation/GROUPTAG_MAPPING_GUIDE.md` for detailed configuration guide.

## Prerequisites

### Azure AD Requirements

- Azure AD App Registration with permissions:
  - `DeviceManagementServiceConfig.ReadWrite.All`
  - `DeviceManagementConfiguration.Read.All`
- Admin consent granted
- Client Secret created and not expired

### Technical Requirements

- Windows 10/11 device (physical or supported VM)
- Internet connection during OOBE
- Administrator privileges
- PowerShell 7+ (auto-installed if missing)

## Security

⚠️ **AUTHORIZED PERSONNEL ONLY**

This tool accesses sensitive Azure AD credentials and Intune services.

### Security Checklist

- [ ] Restrict `Register-ThisPC.json` to Administrators only
- [ ] Encrypt USB drives with BitLocker To Go
- [ ] Rotate Azure AD App Secret every 90 days
- [ ] Delete credentials from devices after provisioning
- [ ] Track all deployments for compliance
- [ ] Review audit logs regularly

**See:** `scripts/Documentation/SECURITY_README.md` for complete security guidelines

## Creating ISO/USB

### Option 1: Copy to USB Drive

```powershell
# Copy entire repository to USB
Copy-Item "C:\...\AutoPilot-Register-this-PC\*" -Destination "E:\" -Recurse -Force
```

### Option 2: Create ISO File

```powershell
# Use Prepare-ISO-Structure script
.\scripts\Documentation\Prepare-ISO-Structure.ps1 -DestinationPath "D:\MyISO"
```

See `scripts/Documentation/ISO_DEPLOYMENT_GUIDE.md` for detailed instructions.

## Documentation

| Document | Description |
|----------|-------------|
| [README.md](scripts/Documentation/README.md) | Detailed project documentation |
| [GROUPTAG_MAPPING_GUIDE.md](scripts/Documentation/GROUPTAG_MAPPING_GUIDE.md) | Group Tag configuration guide |
| [SECURITY_README.md](scripts/Documentation/SECURITY_README.md) | Security best practices |
| [QUICK_REFERENCE.md](scripts/Documentation/QUICK_REFERENCE.md) | Quick troubleshooting guide |
| [MIGRATION_GUIDE.md](scripts/Documentation/MIGRATION_GUIDE.md) | Migration and upgrade guide |
| [ISO_DEPLOYMENT_GUIDE.md](scripts/Documentation/ISO_DEPLOYMENT_GUIDE.md) | ISO creation and deployment |

## Troubleshooting

### Common Issues

**Script won't run:**
- Verify PowerShell execution policy
- Check file permissions
- Run as Administrator

**Authentication fails:**
- Verify Tenant ID, App ID, App Secret
- Check App Secret expiration
- Confirm API permissions granted

**Device already registered:**
- Use `-DuplicateHandling Delete` to re-register
- Manually delete from Intune portal
- Check for Group Tag conflicts

**Group Tag not assigned:**
- Verify `GroupTagMapping.json` exists
- Check profile name matches exactly
- Wait 15-60 minutes for dynamic group membership

See `scripts/Documentation/QUICK_REFERENCE.md` for complete troubleshooting guide.

## Version History

### v4.1.0 (December 16, 2025)
- 🐙 New octopus ASCII art branding
- 📋 External `GroupTagMapping.json` configuration
- 📚 Comprehensive Group Tag mapping documentation
- 🔧 Improved error handling and fallback logic

### v4.0.0 (November 17, 2025)
- ✅ Production release
- 🤖 Removed pause statements for automation
- ✨ Clean exit without user interaction
- 📦 Enterprise deployment ready

### v3.3.0 (November 17, 2025)
- 🏷️ Unified Group Tag and Order ID
- 🔍 Proactive duplicate detection
- 🔄 Smart re-registration workflow
- ⚡ PowerShell 7 optimization

## Support

**IT Security Team:**
- Credential issues, security incidents
- Email: security@enstall.com

**IT Support:**
- Technical deployment issues
- Email: itsupport@enstall.com

## Contributing

This is an internal enterprise tool. All changes must be:
1. Reviewed by IT Security
2. Tested in development environment
3. Documented in CHANGELOG
4. Approved before merging to main

## License

**INTERNAL USE ONLY**
- Restricted to authorized Enstall IT personnel
- Not for public distribution
- Contains sensitive organizational credentials

## Acknowledgments

- PowerShell 7 auto-install method
- Hardware hash collection based on Sean Bulger's work
- Microsoft Graph API integration

---

**⚠️ REMINDER:** This tool contains access to sensitive Azure AD credentials. Unauthorized use is strictly prohibited and may violate security policies.

**Last Updated:** December 16, 2025
**Maintained By:** Enstall IT Team
**Classification:** INTERNAL - RESTRICTED
