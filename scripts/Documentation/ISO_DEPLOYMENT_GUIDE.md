# ISO Deployment Guide - Autopilot Registration Toolkit

## 📀 ISO Structure Overview

When deploying the Autopilot Registration Toolkit on an ISO or USB drive for OOBE use, the files must be organized in this specific structure:

```
ISO/USB Root/
├── Register-ThisPC.cmd           (Launcher - users run this)
│
└── scripts/                      (All PowerShell files and config)
    ├── Register-ThisPC.ps1       (Main script)
    ├── Register-ThisPC.ini       (🔴 SENSITIVE credentials)
    ├── branding.ps1      (Branding module)
    ├── .gitignore                (Git protection - optional on ISO)
    │
    └── Documentation/            (Reference materials)
        ├── README.md
        ├── SECURITY_README.md
        ├── QUICK_REFERENCE.md
        ├── Test-Enhancements.ps1
        └── TEST_RESULTS.md
```

---

## 🎯 Why This Structure?

**Reason 1: OOBE Usability**
- During Windows OOBE (Out-of-Box Experience), users press `Shift+F10`
- This opens a Command Prompt at the root of the boot drive
- They can simply type: `Register-ThisPC.cmd` (no need to navigate)

**Reason 2: Security**
- Sensitive files (INI with credentials) are in a subfolder, not root
- Clear separation between launcher and sensitive components
- Documentation is easily accessible but separate

**Reason 3: Maintainability**
- All PowerShell scripts in one logical location
- Documentation travels with the scripts
- Easy to update individual components

---

## 📋 Pre-Deployment Preparation

### Step 1: Verify Current File Structure

Your current development structure:
```
Project/Windows-iso-with-apjson-Autounattend/Script/
├── Register-this-PC.cmd
├── Register-ThisPC.ps1
├── Register-ThisPC.ini
├── branding.ps1
├── .gitignore
└── Documentation/
    └── [all docs]
```

### Step 2: Prepare Files for ISO

1. **Update Credentials in Register-ThisPC.ini**
   - Verify Azure AD App credentials are current
   - Check App Secret expiration date
   - Test authentication before deployment

2. **Set File Permissions (for source files)**
   ```powershell
   # Restrict access to INI file
   $iniFile = "Register-ThisPC.ini"
   icacls $iniFile /inheritance:r
   icacls $iniFile /grant:r "Administrators:(F)"
   icacls $iniFile /grant:r "SYSTEM:(F)"
   ```

3. **Test the Structure**
   ```powershell
   # Run the test suite
   .\Documentation\Test-Enhancements.ps1
   ```

### Step 3: Create ISO Directory Structure

**Option A: Manual Copy**
```powershell
# Create ISO staging directory
$isoStaging = "C:\Temp\AutopilotISO"
New-Item -ItemType Directory -Path $isoStaging -Force
New-Item -ItemType Directory -Path "$isoStaging\scripts" -Force

# Copy launcher to root
Copy-Item "Register-this-PC.cmd" -Destination $isoStaging

# Copy all scripts to scripts subfolder
Copy-Item "Register-ThisPC.ps1" -Destination "$isoStaging\scripts"
Copy-Item "Register-ThisPC.ini" -Destination "$isoStaging\scripts"
Copy-Item "branding.ps1" -Destination "$isoStaging\scripts"

# Copy Documentation folder
Copy-Item "Documentation" -Destination "$isoStaging\scripts\Documentation" -Recurse
```

**Option B: Use PowerShell Script (Recommended)**

Create a file called `Prepare-ISO-Structure.ps1`:

```powershell
<#
.SYNOPSIS
Prepares files for ISO deployment with correct folder structure
#>
param(
    [string]$SourcePath = $PSScriptRoot,
    [string]$DestinationPath = "C:\Temp\AutopilotISO"
)

Write-Host "Preparing ISO structure..." -ForegroundColor Cyan

# Create destination directories
New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
New-Item -ItemType Directory -Path "$DestinationPath\scripts" -Force | Out-Null

# Copy launcher to root
Copy-Item "$SourcePath\Register-this-PC.cmd" -Destination $DestinationPath -Force
Write-Host "[OK] Copied Register-this-PC.cmd to root" -ForegroundColor Green

# Copy scripts
$scriptFiles = @(
    "Register-ThisPC.ps1",
    "Register-ThisPC.ini",
    "branding.ps1"
)

foreach ($file in $scriptFiles) {
    Copy-Item "$SourcePath\$file" -Destination "$DestinationPath\scripts" -Force
    Write-Host "[OK] Copied $file" -ForegroundColor Green
}

# Copy Documentation folder
Copy-Item "$SourcePath\Documentation" -Destination "$DestinationPath\scripts\Documentation" -Recurse -Force
Write-Host "[OK] Copied Documentation folder" -ForegroundColor Green

# Verify structure
Write-Host "`nVerifying structure..." -ForegroundColor Yellow
$requiredFiles = @(
    "$DestinationPath\Register-this-PC.cmd",
    "$DestinationPath\scripts\Register-ThisPC.ps1",
    "$DestinationPath\scripts\Register-ThisPC.ini",
    "$DestinationPath\scripts\branding.ps1"
)

$allPresent = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "[OK] $file" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $file" -ForegroundColor Red
        $allPresent = $false
    }
}

if ($allPresent) {
    Write-Host "`nISO structure ready at: $DestinationPath" -ForegroundColor Green
    Write-Host "You can now create an ISO from this folder." -ForegroundColor Green
} else {
    Write-Host "`nERROR: Some files are missing!" -ForegroundColor Red
}
```

---

## 🔧 Creating the ISO/USB

### Option 1: Create Bootable USB

```powershell
# 1. Format USB drive (WARNING: This erases all data!)
# Use Disk Management or:
# Format-Volume -DriveLetter E -FileSystem FAT32 -NewFileSystemLabel "AUTOPILOT"

# 2. Copy prepared structure to USB
Copy-Item "C:\Temp\AutopilotISO\*" -Destination "E:\" -Recurse -Force
```

### Option 2: Create ISO File

Using **oscdimg.exe** (from Windows ADK):

```cmd
oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,bC:\Temp\AutopilotISO\boot\etfsboot.com#pEF,e,bC:\Temp\AutopilotISO\efi\microsoft\boot\efisys.bin C:\Temp\AutopilotISO C:\Output\Autopilot-Registration.iso
```

**Note:** For registration-only ISO (no Windows installer), you can use simpler tools like:
- **ImgBurn** (GUI tool)
- **PowerISO**
- **Rufus** (for USB creation)

---

## 🧪 Testing the Deployment

### Test in VM Before Production

1. Create a test VM (Hyper-V or VMware)
2. Mount the ISO or attach USB
3. Boot from the ISO/USB
4. Press `Shift+F10` during OOBE
5. Run: `Register-ThisPC.cmd -DryRun`
6. Verify:
   - ✅ Script finds files correctly
   - ✅ Branding displays
   - ✅ Credentials load from INI
   - ✅ All checks pass

### Common Test Issues

**Issue:** "scripts folder not found"
- **Cause:** Incorrect file structure on ISO
- **Fix:** Verify `scripts\` folder exists at root level

**Issue:** "Register-ThisPC.ps1 not found"
- **Cause:** Files not copied to scripts subfolder
- **Fix:** Ensure all .ps1 files are in `scripts\` not root

**Issue:** "Section [YourCompanyCredentials] not found"
- **Cause:** Register-ThisPC.ini is corrupted or missing
- **Fix:** Re-copy INI file, verify encoding (UTF-8)

---

## 📝 OOBE Usage Instructions

### For Field Technicians:

**Step 1:** Boot device from Autopilot ISO/USB

**Step 2:** When Windows Setup appears, press `Shift + F10`
- This opens Command Prompt

**Step 3:** Identify the drive letter
```cmd
D:
# Try D:, E:, F: until you find the ISO/USB
dir
# You should see Register-ThisPC.cmd
```

**Step 4:** Run the launcher
```cmd
Register-ThisPC.cmd
```

**Step 5:** Follow on-screen prompts
- Select Autopilot profile
- Wait for registration to complete
- Reboot if prompted

---

## 🔐 Security Considerations for ISO

### Before Creating ISO

✅ **DO:**
- Verify credentials are current (not expired)
- Test authentication before deployment
- Document which devices/locations will use this ISO
- Encrypt USB drives with BitLocker To Go
- Number each USB drive for tracking

❌ **DO NOT:**
- Create ISO with test/invalid credentials
- Share ISO file via email or insecure channels
- Leave ISO files on unencrypted network shares
- Create multiple ISO versions with different credentials (confusing)

### Distribution

**Approved Methods:**
- Hand-delivery of encrypted USB drives to authorized technicians
- Secure file transfer with encryption
- Locked storage cabinet for ISO files

**Track Each ISO:**
- Create log: ISO created date, who received it, serial numbers used
- Review and destroy old ISOs after credential rotation

---

## 🔄 Updating Deployed ISOs

### When App Secret is Rotated (Every 90 Days):

1. **Update source INI file**
   ```ini
   [YourCompanyCredentials]
   TenantID=<same>
   AppID=<same>
   AppSecret=<NEW SECRET>
   ```

2. **Test locally**
   ```powershell
   .\Register-ThisPC.ps1 -DryRun
   ```

3. **Re-create ISO structure**
   ```powershell
   .\Prepare-ISO-Structure.ps1
   ```

4. **Re-create ISO/USB**

5. **Distribute to field technicians**

6. **Destroy old ISOs/USBs**
   - Securely erase or physically destroy
   - Update tracking log

### Version Control

When updating scripts (not just credentials):

1. Update version number in Register-ThisPC.ps1
2. Update CLAUDE.md and documentation
3. Run Test-Enhancements.ps1
4. Create new TEST_RESULTS.md
5. Include updated documentation in ISO
6. Notify technicians of changes

---

## 📊 Post-Deployment Monitoring

### Track Usage

After deploying ISOs, monitor:
- How many devices registered per ISO/USB
- Any authentication failures (check Azure AD logs)
- Technician feedback on usability
- Time to complete registration

### Audit Log Review

Monthly review:
- Which users ran the script (from audit logs)
- Were all uses authorized?
- Any unusual patterns or failures?
- Update training if common errors occur

---

## 🆘 Troubleshooting Deployment Issues

### Problem: CMD file doesn't find scripts folder

**Symptoms:**
```
ERROR: scripts folder not found at: D:\scripts
Expected structure:
  D:\
  ├── Register-ThisPC.cmd (this file)
  └── scripts\
```

**Solution:**
1. Check ISO/USB structure - ensure `scripts\` folder exists
2. Verify files weren't copied to wrong location
3. Re-create ISO using preparation script

### Problem: PowerShell execution policy blocks script

**Symptoms:**
```
...cannot be loaded because running scripts is disabled...
```

**Solution:**
- This shouldn't happen (we use `-ExecutionPolicy Bypass`)
- If it does, manually run:
  ```cmd
  powershell.exe -ExecutionPolicy Bypass -File scripts\Register-ThisPC.ps1
  ```

### Problem: Network connectivity test fails

**Solution:**
- Check if device has network access
- Verify firewall allows Graph API access
- Try different network (guest WiFi may block)

---

## 📚 Additional Resources

- **Full Security Guide:** `scripts\Documentation\SECURITY_README.md`
- **Quick Reference:** `scripts\Documentation\QUICK_REFERENCE.md`
- **Test Results:** `scripts\Documentation\TEST_RESULTS.md`
- **Windows ADK Download:** https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install

---

**Document Version:** 1.0
**Created:** 11/11/2025
**Author:** Community Edition
**Classification:** INTERNAL - RESTRICTED
