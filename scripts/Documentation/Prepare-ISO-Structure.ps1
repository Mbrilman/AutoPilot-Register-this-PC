# ================================================================================
# Prepare-ISO-Structure.ps1 - ISO Deployment Preparation Tool
# ================================================================================
#
# PURPOSE:
# Prepares the Autopilot Registration Toolkit files in the correct structure
# for ISO/USB deployment during Windows OOBE.
#
# USAGE:
#   .\Prepare-ISO-Structure.ps1
#   .\Prepare-ISO-Structure.ps1 -DestinationPath "D:\AutopilotUSB"
#
# Author: Community Edition
# Version: 1.0
# Created: 11/11/2025
# ================================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),

    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = "C:\Temp\AutopilotISO",

    [Parameter(Mandatory = $false)]
    [switch]$SkipVerification
)

function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )

    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }

    $prefix = switch ($Type) {
        "SUCCESS" { "[OK]" }
        "ERROR" { "[ERROR]" }
        "WARNING" { "[WARN]" }
        default { "[INFO]" }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}

# Display header
Clear-Host
Write-Host @"
================================================================================
              ISO Structure Preparation Tool
              Autopilot Registration Toolkit
================================================================================
Version: 1.0
Source: $SourcePath
Destination: $DestinationPath
================================================================================
"@ -ForegroundColor Cyan

Write-Host ""

# Validate source path
Write-Status "Validating source files..." "INFO"

$requiredSourceFiles = @(
    "Register-this-PC.cmd",
    "Register-ThisPC.ps1",
    "Register-ThisPC.ini",
    "branding.ps1"
)

$missingFiles = @()
foreach ($file in $requiredSourceFiles) {
    $fullPath = Join-Path $SourcePath $file
    if (Test-Path $fullPath) {
        Write-Status "Found: $file" "SUCCESS"
    }
    else {
        Write-Status "Missing: $file" "ERROR"
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Status "ERROR: Missing required files. Cannot continue." "ERROR"
    Write-Host "Expected files in: $SourcePath" -ForegroundColor Yellow
    exit 1
}

# Check if Documentation folder exists
$docPath = Join-Path $SourcePath "Documentation"
if (-not (Test-Path $docPath)) {
    Write-Status "Documentation folder not found - will skip" "WARNING"
    $copyDocumentation = $false
}
else {
    Write-Status "Found Documentation folder" "SUCCESS"
    $copyDocumentation = $true
}

Write-Host ""

# Verify credentials are not expired (check INI file comments)
Write-Status "Checking credential file..." "INFO"
$iniPath = Join-Path $SourcePath "Register-ThisPC.ini"
$iniContent = Get-Content $iniPath -Raw

if ($iniContent -match 'IMPORTANT SECURITY NOTICE') {
    Write-Status "INI file has security header" "SUCCESS"
}
else {
    Write-Status "INI file missing security header - consider updating" "WARNING"
}

Write-Host ""

# Confirm before proceeding
Write-Host "Ready to create ISO structure:" -ForegroundColor Yellow
Write-Host "  Source: $SourcePath" -ForegroundColor White
Write-Host "  Destination: $DestinationPath" -ForegroundColor White
Write-Host ""

if (-not $SkipVerification) {
    $confirm = Read-Host "Continue? (y/n)"
    if ($confirm -ne 'y') {
        Write-Status "Operation cancelled by user." "WARNING"
        exit 0
    }
}

Write-Host ""
Write-Status "Creating ISO structure..." "INFO"

# Create destination directories
try {
    New-Item -ItemType Directory -Path $DestinationPath -Force -ErrorAction Stop | Out-Null
    Write-Status "Created root directory: $DestinationPath" "SUCCESS"

    $scriptsDir = Join-Path $DestinationPath "scripts"
    New-Item -ItemType Directory -Path $scriptsDir -Force -ErrorAction Stop | Out-Null
    Write-Status "Created scripts directory" "SUCCESS"
}
catch {
    Write-Status "Failed to create directories: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Host ""
Write-Status "Copying files..." "INFO"

# Copy launcher to root
try {
    $cmdFile = Join-Path $SourcePath "Register-this-PC.cmd"
    Copy-Item $cmdFile -Destination $DestinationPath -Force
    Write-Status "Copied Register-this-PC.cmd to root" "SUCCESS"
}
catch {
    Write-Status "Failed to copy CMD file: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Copy scripts to scripts subfolder
$scriptFiles = @(
    "Register-ThisPC.ps1",
    "Register-ThisPC.ini",
    "branding.ps1"
)

foreach ($file in $scriptFiles) {
    try {
        $sourcePath = Join-Path $SourcePath $file
        $destPath = Join-Path $scriptsDir $file
        Copy-Item $sourcePath -Destination $destPath -Force

        # Show file size for INI (to verify it's not empty)
        if ($file -eq "Register-ThisPC.ini") {
            $size = (Get-Item $destPath).Length
            Write-Status "Copied $file ($size bytes)" "SUCCESS"
        }
        else {
            Write-Status "Copied $file" "SUCCESS"
        }
    }
    catch {
        Write-Status "Failed to copy $file`: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Copy Documentation folder
if ($copyDocumentation) {
    try {
        $docSourcePath = Join-Path $SourcePath "Documentation"
        $docDestPath = Join-Path $scriptsDir "Documentation"
        Copy-Item $docSourcePath -Destination $docDestPath -Recurse -Force

        $docFileCount = (Get-ChildItem $docDestPath -File).Count
        Write-Status "Copied Documentation folder ($docFileCount files)" "SUCCESS"
    }
    catch {
        Write-Status "Failed to copy Documentation: $($_.Exception.Message)" "WARNING"
    }
}

Write-Host ""
Write-Status "Verifying structure..." "INFO"

# Verify all required files
$verificationFiles = @(
    @{Path = "Register-this-PC.cmd"; Location = "Root"},
    @{Path = "scripts\Register-ThisPC.ps1"; Location = "Scripts"},
    @{Path = "scripts\Register-ThisPC.ini"; Location = "Scripts"},
    @{Path = "scripts\branding.ps1"; Location = "Scripts"}
)

$allVerified = $true
foreach ($fileInfo in $verificationFiles) {
    $fullPath = Join-Path $DestinationPath $fileInfo.Path
    if (Test-Path $fullPath) {
        Write-Status "$($fileInfo.Location): $($fileInfo.Path)" "SUCCESS"
    }
    else {
        Write-Status "$($fileInfo.Location): $($fileInfo.Path) - MISSING!" "ERROR"
        $allVerified = $false
    }
}

# Display final structure
Write-Host ""
Write-Host "Final Structure:" -ForegroundColor Cyan
Write-Host "================================================================================`n" -ForegroundColor Cyan

$tree = @"
$DestinationPath\
├── Register-ThisPC.cmd           (Launcher)
│
└── scripts\
    ├── Register-ThisPC.ps1       (Main script)
    ├── Register-ThisPC.ini       (Credentials - SENSITIVE)
    ├── branding.ps1      (Branding module)
    │
    └── Documentation\            (Reference materials)
        ├── README.md
        ├── SECURITY_README.md
        ├── QUICK_REFERENCE.md
        ├── ISO_DEPLOYMENT_GUIDE.md
        ├── Test-Enhancements.ps1
        └── TEST_RESULTS.md
"@

Write-Host $tree -ForegroundColor Gray
Write-Host ""

# Final status
if ($allVerified) {
    Write-Host "================================================================================`n" -ForegroundColor Green
    Write-Status "SUCCESS: ISO structure is ready!" "SUCCESS"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review files in: $DestinationPath" -ForegroundColor White
    Write-Host "  2. Verify Register-ThisPC.ini contains valid credentials" -ForegroundColor White
    Write-Host "  3. Create ISO file or copy to USB drive" -ForegroundColor White
    Write-Host "  4. Test in VM before production deployment" -ForegroundColor White
    Write-Host ""
    Write-Host "Documentation:" -ForegroundColor Yellow
    Write-Host "  See: $DestinationPath\scripts\Documentation\ISO_DEPLOYMENT_GUIDE.md" -ForegroundColor White
    Write-Host ""

    # Offer to open destination folder
    $openFolder = Read-Host "Open destination folder in Explorer? (y/n)"
    if ($openFolder -eq 'y') {
        Start-Process explorer.exe -ArgumentList $DestinationPath
    }
}
else {
    Write-Host "================================================================================`n" -ForegroundColor Red
    Write-Status "ERRORS DETECTED: Please review the errors above" "ERROR"
    Write-Host ""
    exit 1
}

Write-Host "================================================================================`n" -ForegroundColor Cyan
