# Security Guidelines for Autopilot Registration Toolkit

## ⚠️ AUTHORIZED PERSONNEL ONLY ⚠️

This document provides security guidelines for the use and handling of the YourCompany Autopilot Device Registration Toolkit.

---

## Overview

The Autopilot Registration Toolkit consists of sensitive scripts and configuration files that provide direct access to your organization's Microsoft Intune and Windows Autopilot services. Improper handling or unauthorized access to these files may result in:

- Unauthorized device registration
- Security policy violations
- Potential data breaches
- Compliance violations

---

## File Inventory and Sensitivity Levels

### 🔴 **CRITICAL - Highly Sensitive**

#### `Register-ThisPC.ini`
- **Contains**: Azure AD Application credentials (Tenant ID, App ID, App Secret)
- **Risk Level**: CRITICAL
- **Access**: Administrators only
- **Storage**: Encrypted storage required
- **Transmission**: Secure channels only (never email/chat)
- **Retention**: Delete after use

### 🟡 **RESTRICTED - Sensitive**

#### `Register-ThisPC.ps1`
- **Contains**: Automation logic, references to sensitive files
- **Risk Level**: HIGH
- **Access**: Authorized IT personnel only
- **Usage**: Only on managed devices

#### `branding.ps1`
- **Contains**: Corporate branding (non-sensitive)
- **Risk Level**: LOW
- **Access**: Authorized personnel only (proprietary)

---

## Authorized Personnel

### Who May Access These Files?

✅ **Authorized Users:**
- IT Administrators with Intune management responsibilities
- Device Provisioning Technicians (under IT supervision)
- Approved contractors with signed NDA
- Personnel with explicit approval from IT Management

❌ **Unauthorized Users:**
- End users / Standard employees
- External vendors without approval
- Contractors without NDA
- Any personnel without explicit authorization

### Authorization Process

To request access:
1. Submit request to IT Security Team
2. Provide business justification
3. Complete security awareness training
4. Sign acknowledgment of responsibilities
5. Receive temporary access credentials

---

## Security Requirements

### 1. File Permissions

**Windows NTFS Permissions for `Register-ThisPC.ini`:**
```
Administrators: Full Control
SYSTEM: Full Control
[Remove all other users/groups]
```

**PowerShell command to set permissions:**
```powershell
$file = "C:\Path\To\Register-ThisPC.ini"
$acl = Get-Acl $file
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","Allow")
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","Allow")

$acl.AddAccessRule($adminRule)
$acl.AddAccessRule($systemRule)
Set-Acl $file $acl
```

### 2. Storage Requirements

- ✅ Store on encrypted volumes only
- ✅ Use BitLocker or equivalent encryption
- ✅ Store in administrator-only folders
- ❌ Never store on network shares without encryption
- ❌ Never store in user-accessible locations
- ❌ Never store in Downloads or temporary folders

### 3. Credential Rotation

**Azure AD App Secret Rotation Schedule:**
- **Recommended**: Every 90 days
- **Maximum**: 180 days (compliance requirement)
- **Emergency**: Immediately if compromise suspected

**Rotation Procedure:**
1. Generate new secret in Azure AD App Registration
2. Update `Register-ThisPC.ini` with new secret
3. Test authentication with new credentials
4. Revoke old secret in Azure AD
5. Document rotation in security log

### 4. Version Control

**CRITICAL - DO NOT COMMIT SENSITIVE FILES:**

Create `.gitignore` file:
```
# Sensitive credentials
Register-ThisPC.ini
*.ini
*secret*
*password*
*credential*

# Temporary files
*.log
*.tmp
```

### 5. Transmission Security

When distributing to authorized personnel:

✅ **Approved Methods:**
- Encrypted USB drive (BitLocker To Go)
- Secure file transfer service (with encryption)
- Azure Key Vault (preferred for production)
- In-person transfer on encrypted media

❌ **Prohibited Methods:**
- Email (even internal)
- Chat applications (Teams, Slack, etc.)
- Cloud storage without encryption (Dropbox, OneDrive without protection)
- SMS or text messaging
- Unencrypted network shares

---

## Usage Guidelines

### Before Using the Toolkit

1. ✅ Verify you are authorized to use these tools
2. ✅ Ensure you are on a secure, managed device
3. ✅ Verify network connection is trusted (not public WiFi)
4. ✅ Check that credentials have not expired
5. ✅ Document the usage (device serial, date, purpose)

### During Device Registration

1. ✅ Verify the device serial number matches physical label
2. ✅ Select correct Autopilot profile for device
3. ✅ Monitor output for errors or warnings
4. ✅ Verify successful registration in Intune portal

### After Device Registration

1. ✅ Delete `Register-ThisPC.ini` from USB drive if used on new device
2. ✅ Document registration in asset management system
3. ✅ Secure or destroy temporary files
4. ✅ Log out of administrative sessions

---

## Incident Response

### If Credentials Are Compromised

**IMMEDIATE ACTIONS:**
1. ⚠️ Contact IT Security Team immediately
2. ⚠️ Provide details: What was exposed? When? To whom?
3. ⚠️ Do NOT attempt to "fix" it yourself

**IT Security Response:**
1. Revoke compromised App Secret in Azure AD
2. Generate new credentials
3. Audit Autopilot service for unauthorized registrations
4. Update all authorized copies of configuration file
5. Document incident for compliance
6. Review and strengthen access controls

### Reporting Security Concerns

Contact: **IT Security Team**
- Email: [security@YourCompany.com] (for non-urgent issues)
- Phone: [Emergency Security Hotline] (for urgent issues)
- Portal: [Security Incident Portal]

**Report immediately if:**
- Credentials were sent via insecure channel
- Unauthorized person accessed the files
- Files were stored insecurely
- Device with credentials was lost/stolen
- Suspicious Autopilot registrations detected

---

## Compliance and Auditing

### Audit Trail Requirements

Maintain records of:
- Date and time of each script execution
- User who executed the script
- Device registered (serial number)
- Autopilot profile selected
- Success or failure of registration

### Record Retention

- **Access logs**: Retain for 1 year minimum
- **Registration records**: Retain per company policy
- **Incident reports**: Retain for 7 years (compliance)

### Compliance Frameworks

This toolkit must comply with:
- ISO 27001 Information Security Management
- GDPR Data Protection Regulations
- Company Information Security Policy
- Industry-specific regulations (if applicable)

---

## Training and Awareness

### Required Training

Before accessing this toolkit, complete:
1. ✅ Information Security Awareness Training
2. ✅ Privileged Access Management Training
3. ✅ Autopilot Device Registration Procedures
4. ✅ Incident Response Procedures

### Acknowledgment

By using this toolkit, you acknowledge:
- ✅ I am authorized to access these files
- ✅ I understand the security risks
- ✅ I will follow all security requirements
- ✅ I will report any security incidents immediately
- ✅ I understand violations may result in disciplinary action

---

## Contact Information

**IT Security Team:**
- Email: security@YourCompany.com
- Phone: [Contact Number]

**IT Management:**
- Director of IT: [Name & Contact]

**Compliance Officer:**
- [Name & Contact]

---

## Document Information

- **Version**: 1.0
- **Created**: 11/11/2025
- **Last Modified**: 11/11/2025
- **Author**: Macel Brilman (IT)
- **Classification**: INTERNAL - RESTRICTED
- **Review Date**: Every 90 days

---

**For questions about this document or security procedures, contact the IT Security Team.**
