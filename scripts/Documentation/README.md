# Documentation Folder

This folder contains comprehensive documentation and testing resources for the YourCompany Autopilot Registration Toolkit.

---

## 📚 Contents

### Security Documentation

**SECURITY_README.md** (8 KB)
- Comprehensive security guidelines
- File sensitivity classifications
- Authorization requirements
- Credential rotation procedures
- Incident response protocols
- Compliance requirements

**Purpose:** Essential reading for all authorized personnel before using the toolkit.

---

### User Guides

**QUICK_REFERENCE.md** (6 KB)
- Quick-start guide for technicians
- Pre-flight security checklist
- Step-by-step usage instructions
- Troubleshooting common issues
- Autopilot profile mapping
- Security reminders

**Purpose:** Field reference for daily device provisioning operations.

---

### Testing & Validation

**Test-Enhancements.ps1** (10 KB)
- Comprehensive validation script
- Tests all security enhancements
- Validates error handling
- Checks documentation completeness
- Syntax validation
- Version consistency checks

**Usage:**
```powershell
.\Documentation\Test-Enhancements.ps1
```

**TEST_RESULTS.md** (12 KB)
- Complete test report from v3.3.0 validation
- Detailed test results including new features
- Security feature verification
- Performance observations
- Production readiness assessment
- Known issues and recommendations

**Purpose:** Quality assurance documentation and deployment validation.

---

### ISO/USB Deployment

**ISO_DEPLOYMENT_GUIDE.md** (NEW)
- Complete guide for ISO/USB deployment
- Explains required file structure for OOBE use
- Step-by-step preparation instructions
- Testing procedures
- Troubleshooting common deployment issues
- Security considerations for ISO distribution

**Prepare-ISO-Structure.ps1** (NEW)
- Automated tool to prepare files for ISO creation
- Creates correct folder structure automatically
- Validates all required files present
- Validates JSON credential file integrity
- Interactive prompts with confirmation

**Usage:**
```powershell
.\Documentation\Prepare-ISO-Structure.ps1
# Creates structure at C:\Temp\AutopilotISO

# Or specify custom destination:
.\Documentation\Prepare-ISO-Structure.ps1 -DestinationPath "D:\AutopilotUSB"
```

**Purpose:** Simplifies ISO/USB preparation for OOBE deployment.

---

## 📋 Quick Navigation

**For End Users (Technicians):**
1. Start with: `QUICK_REFERENCE.md`
2. Reference: `SECURITY_README.md` (sections on Authorized Personnel and Usage Guidelines)

**For IT Administrators:**
1. Start with: `SECURITY_README.md`
2. Then: `TEST_RESULTS.md` (for deployment validation)
3. Run: `Test-Enhancements.ps1` (before each deployment)

**For Security Officers:**
1. Review: `SECURITY_README.md` (complete document)
2. Audit: Incident Response and Compliance sections
3. Verify: File permissions and credential rotation schedules

---

## 🔐 Security Classification

All documents in this folder are classified as:

**INTERNAL - RESTRICTED**

- Access limited to authorized IT personnel
- Do not distribute outside the organization
- Contains references to sensitive systems and procedures
- Subject to document retention policies

---

## 📅 Maintenance Schedule

**Monthly:**
- Review usage patterns from audit logs
- Update contact information if needed

**Quarterly (Every 90 Days):**
- Review and update security procedures
- Validate documentation accuracy
- Update troubleshooting guide based on field feedback

**Annually:**
- Complete documentation review
- Update compliance requirements
- Refresh training materials

---

## 📞 Support

For questions about this documentation:

**IT Security Team:**
- Email: security@YourCompany.com
- Phone: [Contact Number]

**Documentation Updates:**
- Submit requests to: IT Management
- Version control: Track in deployment notes

---

## 📁 File Versions

| File | Version | Last Updated |
|------|---------|--------------|
| Register-ThisPC.ps1 | **4.0.0 PRODUCTION** | 17/11/2025 |
| Register-this-PC.cmd | 2.0 | 17/11/2025 |
| SECURITY_README.md | 1.0 | 11/11/2025 |
| QUICK_REFERENCE.md | 2.0 | 17/11/2025 |
| Test-Enhancements.ps1 | 1.0 | 11/11/2025 |
| TEST_RESULTS.md | 2.0 | 17/11/2025 |
| ISO_DEPLOYMENT_GUIDE.md | 1.0 | 11/11/2025 |

---

## 🔄 Related Files

**Parent Directory (../)**
- `Register-ThisPC.ps1` - Main Autopilot registration script
- `Register-ThisPC.json` - Configuration file (HIGHLY SENSITIVE)
- `branding.ps1` - Corporate branding module
- `.gitignore` - Version control protection

---

**Created:** November 11, 2025
**Author:** Macel Brilman (IT)
**Classification:** INTERNAL - RESTRICTED
