<#
.SYNOPSIS
Checks for PowerShell 7, installs it if missing, and then collects and uploads the local machine's hardware hash to the Windows Autopilot service.

.DESCRIPTION
This script is designed to be run on a new, unmanaged device during the OOBE (Shift+F10). It ensures a modern PowerShell environment is available before proceeding with Autopilot registration.

Key Workflow:
1. Checks if the script is running in PowerShell 7+.
2. If not, it downloads and silently installs the latest stable version of PowerShell 7.
3. It then re-launches itself in the new PowerShell 7 session.
4. Once in the correct environment, it presents an interactive menu to select the target tenant.
5. It dynamically fetches and displays available Autopilot profiles from the selected tenant.
6. Based on the profile choice, it maps a corresponding Order ID.
7. Finally, it collects the hardware hash and uploads it to the Autopilot service.
All configuration settings, including tenant credentials, are read from 'Register-ThisPC.json' located in the same directory as this script.

.NOTES
Version:          4.0.0
Author:           Community Edition
Creation Date:    08/10/2025
Last Modified:    17/11/2025

IMPORTANT SECURITY NOTICE:
!!! AUTHORIZED PERSONNEL ONLY !!!

This script contains access to sensitive Azure AD credentials and Intune services.

RESTRICTIONS:
- This script is RESTRICTED to authorized IT personnel ONLY
- Requires access to Register-ThisPC.json which contains SENSITIVE credentials
- Grants ability to register devices in your organization's Autopilot service
- Unauthorized use may result in security policy violations

AUTHORIZED USERS:
- IT Administrators with Intune management responsibilities
- Approved technicians performing device provisioning under IT supervision
- Access must be approved by IT management

SECURITY REQUIREMENTS:
1. Ensure Register-ThisPC.json has restricted file permissions (Administrators only)
2. Do NOT share credentials with unauthorized personnel
3. Delete sensitive files from devices after provisioning
4. Rotate Azure AD App Secret regularly (recommended: every 90 days)
5. Audit trail: Document each use of this script for compliance

For questions about access authorization, contact: IT Security Team

Pre-requisites:
- An active internet connection to download PowerShell 7 and connect to Microsoft Graph.
- An Azure AD App Registration with the following Graph API permissions (Application type):
  - 'DeviceManagementServiceConfig.ReadWrite.All' (to upload the device hash)
  - 'DeviceManagementConfiguration.Read.All' (to read the Autopilot profiles)
- The Tenant ID, App (Client) ID, and a Client Secret.

Method Credit:
- The direct WMI/CIM query for hardware hash collection is based on the method described by Sean Bulger.
  Full article: https://www.modernendpoint.com/managed/Silently-Collect-Autopilot-Hashes-using-Microsoft-Graph-and-a-Provisioning-Package/

Release Notes:
- v4.0.0: PRODUCTION RELEASE - Ready for enterprise deployment. Removed all pause statements from batch launcher for automated workflows and OOBE deployments. Script now exits cleanly without user interaction after completion, ideal for scripted deployments and automation scenarios. All v3.3.0 features validated and production-ready. Documentation fully updated and synchronized. This is the recommended version for all production deployments.
- v3.3.0: FEATURE UPDATE - Group Tag Management & Proactive Duplicate Detection. Unified Group Tag and Order ID to use the same value for consistency with Azure AD dynamic group requirements. Added proactive duplicate device detection that checks BEFORE upload attempt (previously only checked after error). When existing device found, displays current vs. new Group Tag and prompts for delete/re-register with clear comparison. Prevents unnecessary re-downloads of PowerShell 7 by checking if already installed before attempting download. Fixed network connectivity test to handle 401/403/405 responses as successful (server reachable). Improved user experience with better prompts and clearer Group Tag change notifications.
- v3.2.0: MAJOR CODE QUALITY UPDATE - Comprehensive refactoring and improvements. Added centralized configuration constants for all timeouts, retry counts, and API endpoints. Implemented dynamic PowerShell version detection to automatically download latest stable release from GitHub API with fallback to known stable version (7.4.6). Eliminated code duplication by extracting device registration logic into reusable helper functions (New-AutopilotDeviceRequestBody, Send-AutopilotDeviceRegistration). Added comprehensive parameter validation with [ValidateNotNull], [ValidateNotNullOrEmpty], and [ValidateRange] attributes across all functions. Improved maintainability by replacing hardcoded values with Config hashtable references. Enhanced code organization with proper regions and improved function signatures. All changes maintain backward compatibility while significantly improving code quality and maintainability.
- v3.1.0: MAJOR UPDATE - Enhanced Error Handling & Retry Logic. Added comprehensive retry logic with exponential backoff for all network operations (PowerShell 7 download, module installation, Graph authentication, hardware hash collection, and Autopilot upload). Added network connectivity pre-check function. Improved error messages with context-specific troubleshooting guidance. Added validation for downloaded files, hardware hash format, and API responses. Enhanced success messages with detailed device information and timing expectations.
- v3.0.0: MAJOR UPDATE. Implemented a check for PowerShell 7. The script will now automatically download and install the latest stable version of PowerShell if it's running on an older version (like Windows PowerShell 5.1), and then relaunch itself. Also performed a full code review and fixed all remaining 'smart quote' issues and a variable name error in the Invoke-UploadAutopilotHash function.
- v2.1.7: Corrected the final 'smart quote' issue on the Disconnect-MgGraph line to resolve the persistent 'missing terminator' error.
- v2.1.6: Corrected a recurring 'missing terminator' error in the finally block by replacing a non-standard 'smart quote' with a standard quote.
- v2.1.5: Corrected a 'missing terminator' error on line 439 caused by a non-standard 'smart quote' character.
- v2.1.4: Added a detailed comment block explaining the relationship between 'Group Tag', 'Order ID', and how they are displayed in the Intune Portal ('Device group' vs 'Profile assigned').
- v2.1.3: Reverted final summary block to a simpler, stable version from v2.0.8.

.PARAMETER DryRun
Enables debug mode with full logging to a timestamped log file. No actual changes will be made to Autopilot.

.PARAMETER DuplicateHandling
Controls how the script handles devices that are already registered in Autopilot.
Valid values:
- Prompt (default): Ask the user what to do when a duplicate is found
- Delete: Automatically delete and re-register the device
- Skip: Skip registration and keep existing device settings
- Error: Throw an error and abort registration

.EXAMPLE
# Interactive mode - prompts for user input when needed
.\Register-ThisPC.ps1

.EXAMPLE
# Automated mode - automatically delete and re-register duplicates
.\Register-ThisPC.ps1 -DuplicateHandling Delete

.EXAMPLE
# Dry run mode for testing
.\Register-ThisPC.ps1 -DryRun

.EXAMPLE
# Automated mode with dry run
.\Register-ThisPC.ps1 -DuplicateHandling Delete -DryRun
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Prompt", "Skip", "Delete", "Error")]
    [string]$DuplicateHandling = "Prompt"
)

# --- Define Script Root ---
$scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path

# --- DEBUG MODE: Start Logging ---
if ($DryRun) {
    # Create log file in the root folder (one level up from scripts folder)
    $logFolder = Split-Path -Parent $scriptRoot
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = Join-Path $logFolder "AutopilotRegistration_DEBUG_$timestamp.log"

    try {
        Start-Transcript -Path $logFile -Append -ErrorAction Stop
        Write-Host "[DEBUG] Logging enabled. Log file: $logFile" -ForegroundColor Cyan
        Write-Host "[DEBUG] All console output will be captured to this log file." -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Warning "[DEBUG] Failed to start logging: $($_.Exception.Message)"
    }
}

#===============================================================================================================
# Script Initialization & Environment Check
#===============================================================================================================
$scriptVersion = "4.0.0" # This should match the .VERSION in NOTES

#===============================================================================================================
# Configuration Constants
#===============================================================================================================
$script:Config = @{
    # PowerShell Installation
    MinimumPowerShellVersion = 7
    PowerShellDownloadUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"

    # Retry Configuration
    DefaultMaxRetries = 3
    DefaultInitialDelaySeconds = 2
    ModuleInstallRetries = 3
    DownloadRetries = 3
    GraphAuthRetries = 3
    UploadRetries = 3

    # Timeout Configuration
    WebRequestTimeoutSeconds = 300
    ShortWebRequestTimeoutSeconds = 30
    NetworkTestTimeoutSeconds = 10

    # Wait Times
    PostDeletionWaitSeconds = 5
    PreRebootWaitSeconds = 5

    # Network Test URLs
    NetworkTestUrls = @(
        "https://graph.microsoft.com"
        "https://login.microsoftonline.com"
        "https://www.microsoft.com"
    )

    # API Endpoints
    GraphTokenEndpoint = "https://login.microsoftonline.com/{0}/oauth2/v2.0/token"
    AutopilotProfilesEndpoint = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles"
    AutopilotDevicesEndpoint = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities"
    AutopilotImportEndpoint = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities"
}

# --- Dot-source the branding function ---
. (Join-Path $scriptRoot "branding.ps1")

#region Helper Functions

# --- Function to Retry an Operation with Exponential Backoff ---
function Invoke-WithRetry {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 60)]
        [int]$InitialDelaySeconds = 2,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OperationName = "Operation"
    )

    $attempt = 0
    $delay = $InitialDelaySeconds

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            Write-Host "[$OperationName] Attempt $attempt of $MaxRetries..." -ForegroundColor Cyan
            $result = & $ScriptBlock
            Write-Host "[$OperationName] Succeeded on attempt $attempt." -ForegroundColor Green
            return $result
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "[$OperationName] Attempt $attempt failed: $errorMessage"

            if ($attempt -lt $MaxRetries) {
                Write-Host "[$OperationName] Retrying in $delay seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $delay
                $delay = $delay * 2  # Exponential backoff
            }
            else {
                Write-Error "[$OperationName] All $MaxRetries attempts failed. Last error: $errorMessage"
                throw
            }
        }
    }
}

# --- Function to Test Network Connectivity ---
function Test-NetworkConnectivity {
    param (
        [string[]]$TestUrls = $script:Config.NetworkTestUrls
    )

    Write-Host "Testing network connectivity..." -ForegroundColor Cyan
    $allFailed = $true

    foreach ($url in $TestUrls) {
        try {
            # Try GET request (some APIs like Graph don't support HEAD)
            $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec $script:Config.NetworkTestTimeoutSeconds -UseBasicParsing -ErrorAction Stop
            Write-Host "  [OK] Connection to $url successful (Status: $($response.StatusCode))" -ForegroundColor Green
            $allFailed = $false
        }
        catch {
            # If GET fails, check if it's just a method issue (401/403 means we can reach the server)
            if ($_.Exception.Response.StatusCode -in @(401, 403, 405)) {
                Write-Host "  [OK] Connection to $url verified (Authentication required, but reachable)" -ForegroundColor Green
                $allFailed = $false
            }
            else {
                Write-Warning "  [FAIL] Cannot reach $url - $($_.Exception.Message)"
            }
        }
    }

    if ($allFailed) {
        Write-Error "Network connectivity test failed. Please check your internet connection and proxy settings."
        throw "No network connectivity detected."
    }
    else {
        Write-Host "Network connectivity verified." -ForegroundColor Green
    }
}

# --- Function to Ensure a Module is Installed ---
function Ensure-ModuleInstalled {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName
    )

    # Check if module is already available
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "Module '$ModuleName' is already installed." -ForegroundColor Green
        return
    }

    Write-Host "Module '$ModuleName' not found. Installing..." -ForegroundColor Yellow

    if ($DryRun) {
        Write-Host "[DRY RUN] Would have installed module '$ModuleName'." -ForegroundColor Yellow
        return
    }

    try {
        # Install with retry logic
        Invoke-WithRetry -MaxRetries $script:Config.ModuleInstallRetries -InitialDelaySeconds 3 -OperationName "Module Installation: $ModuleName" -ScriptBlock {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # Ensure NuGet provider is installed
            $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if (-not $nugetProvider -or $nugetProvider.Version -lt [Version]"2.8.5.201") {
                Write-Host "Installing/Updating NuGet package provider..." -ForegroundColor Cyan
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
            }

            # Install the module
            Write-Host "Installing module '$ModuleName'..." -ForegroundColor Cyan
            Install-Module -Name $ModuleName -Force -SkipPublisherCheck -AllowClobber -ErrorAction Stop

            # Verify installation
            if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
                throw "Module '$ModuleName' installation completed but module is not available."
            }
        }

        Write-Host "Module '$ModuleName' installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install module '$ModuleName'. Please check your internet connection and PowerShell gallery access. Error: $($_.Exception.Message)"
        Write-Host "You can try installing manually with: Install-Module -Name $ModuleName -Force" -ForegroundColor Yellow
        throw
    }
}
#endregion Helper Functions

#region PowerShell Version Management
# --- Function to Get Latest PowerShell 7 Release ---
function Get-LatestPowerShellRelease {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("x64", "x86", "arm64", "arm32")]
        [string]$Architecture = "x64"
    )

    try {
        Write-Host "Fetching latest PowerShell 7 release information..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $apiUrl = $script:Config.PowerShellDownloadUrl
        $release = Invoke-RestMethod -Uri $apiUrl -TimeoutSec $script:Config.ShortWebRequestTimeoutSeconds -UseBasicParsing -ErrorAction Stop

        # Find the MSI asset for Windows x64
        $assetPattern = "PowerShell-.*-win-$Architecture\.msi$"
        $asset = $release.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1

        if (-not $asset) {
            throw "Could not find PowerShell MSI asset for architecture: $Architecture"
        }

        $version = $release.tag_name -replace '^v', ''
        Write-Host "Latest PowerShell version: $version" -ForegroundColor Green

        return @{
            Version = $version
            DownloadUrl = $asset.browser_download_url
            FileName = $asset.name
        }
    }
    catch {
        Write-Warning "Failed to fetch latest PowerShell release: $($_.Exception.Message)"
        Write-Host "Falling back to known stable version (7.4.6)..." -ForegroundColor Yellow

        # Fallback to a known stable version
        return @{
            Version = "7.4.6"
            DownloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi"
            FileName = "PowerShell-7.4.6-win-x64.msi"
        }
    }
}

# --- Check for PowerShell 7 and Upgrade if Necessary ---
if ($PSVersionTable.PSVersion.Major -lt $script:Config.MinimumPowerShellVersion) {
    Write-Host "Running on older PowerShell version ($($PSVersionTable.PSVersion))." -ForegroundColor Yellow

    # Check if PowerShell 7 is already installed
    $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    if (Test-Path $pwshPath) {
        Write-Host "PowerShell 7 is already installed. Relaunching script in PowerShell 7..." -ForegroundColor Green

        if (-not $DryRun) {
            & $pwshPath -File "$($MyInvocation.MyCommand.Path)"
            exit
        } else {
            Write-Host "[DRY RUN] Would have relaunched in PowerShell 7." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "PowerShell 7 not found. Installing..." -ForegroundColor Yellow
    }

    try {
        # Get latest PowerShell release
        $pwshRelease = Get-LatestPowerShellRelease
        $downloadUrl = $pwshRelease.DownloadUrl
        $installerPath = Join-Path $env:TEMP $pwshRelease.FileName

        Write-Host "Will install PowerShell $($pwshRelease.Version)" -ForegroundColor Cyan

        # Download with retry logic
        $null = Invoke-WithRetry -MaxRetries $script:Config.DownloadRetries -InitialDelaySeconds 5 -OperationName "PowerShell 7 Download" -ScriptBlock {
            Write-Host "Downloading PowerShell 7 installer from $downloadUrl..." -ForegroundColor Cyan
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -TimeoutSec $script:Config.WebRequestTimeoutSeconds -UseBasicParsing

            # Verify download succeeded and file exists
            if (-not (Test-Path $installerPath)) {
                throw "Downloaded file not found at $installerPath"
            }
            $fileSize = (Get-Item $installerPath).Length
            if ($fileSize -lt 1MB) {
                throw "Downloaded file appears incomplete (size: $fileSize bytes)"
            }
            Write-Host "Download verified: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Green
        }

        Write-Host "Starting silent installation..." -ForegroundColor Cyan
        if (-not $DryRun) {
            $installProcess = Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait -PassThru

            if ($installProcess.ExitCode -ne 0) {
                throw "PowerShell 7 installation failed with exit code $($installProcess.ExitCode)"
            }

            Write-Host "Installation complete. Relaunching script in PowerShell 7..." -ForegroundColor Green

            # Verify pwsh.exe is available before relaunching
            $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
            if (-not (Test-Path $pwshPath)) {
                throw "PowerShell 7 executable not found at expected location: $pwshPath"
            }

            # Use pwsh.exe -File with the script's own path to relaunch
            & $pwshPath -File "$($MyInvocation.MyCommand.Path)"
            exit # Exit the current (old) PowerShell session
        } else {
            Write-Host "[DRY RUN] Would have installed PowerShell 7 and relaunched the script." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Failed to download or install PowerShell 7. Please install it manually and re-run the script. Error: $($_.Exception.Message)"
        Write-Host "Manual download available at: https://github.com/PowerShell/PowerShell/releases/latest" -ForegroundColor Yellow
        throw
    }
}
#endregion PowerShell Version Management

#region Main Workflow Functions
# --- Function to get Tenant Credentials ---
function Get-TenantCredentials {
    Show-Branding -scriptVersion $scriptVersion

    # Security Warning
    Write-Host ""
    Write-Host "SECURITY CHECK: Loading sensitive credentials..." -ForegroundColor Yellow
    Write-Host "User: $env:USERNAME" -ForegroundColor Cyan
    Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host ""

    $credentials = @{}

    # Try JSON configuration first (preferred)
    $jsonConfigPath = Join-Path $scriptRoot "Register-ThisPC.json"

    if (Test-Path $jsonConfigPath) {
        # Load from JSON (cleaner, more modern approach)
        Write-Host "Reading credentials from $jsonConfigPath..." -ForegroundColor Green
        try {
            $configData = Get-Content $jsonConfigPath -Raw | ConvertFrom-Json

            if ($configData.TenantID -and $configData.AppID -and $configData.AppSecret) {
                $credentials.TenantID = $configData.TenantID
                $credentials.AppID = $configData.AppID
                $credentials.AppSecret = $configData.AppSecret
            }
            else {
                throw "JSON config is missing required fields (TenantID, AppID, AppSecret)"
            }
        }
        catch {
            Write-Error "Failed to parse JSON configuration: $($_.Exception.Message)"
            throw "Invalid JSON config file."
        }
    }
    else {
        Write-Error "Configuration file not found. Looking for:"
        Write-Host "  - $jsonConfigPath (JSON format)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This file contains sensitive Azure AD credentials required for Autopilot registration." -ForegroundColor Yellow
        Write-Host "If you are authorized to use this tool, contact IT Security to obtain the configuration file." -ForegroundColor Yellow
        throw "Config file missing."
    }

    # Validate credentials
    if ([string]::IsNullOrWhiteSpace($credentials.TenantID) -or
        [string]::IsNullOrWhiteSpace($credentials.AppID) -or
        [string]::IsNullOrWhiteSpace($credentials.AppSecret)) {
        Write-Error "Missing one or more credentials (TenantID, AppID, AppSecret) in configuration file."
        throw "Incomplete credentials in config file."
    }

    Write-Host "Credentials loaded successfully." -ForegroundColor Green

    return $credentials
}

# --- Function to get Autopilot Profile based on Tenant ---
function Get-AutopilotProfile {
    # --- Important Explanation: Group Tag vs. Order ID in the Intune Portal ---
    #
    # QUESTION: Why is 'Profile assigned' empty and why does 'Device group' show the full profile name?
    #
    # ANSWER: This is normal and expected behavior. The process works as follows:
    #
    # 1. Group Tag (in script) -> 'Device group' (in portal):
    #    - This script sends the FULL NAME of the selected Autopilot profile (e.g., 'SLG_WG_Autopilot_Deployment') as the 'Group Tag'.
    #    - This is REQUIRED because your dynamic groups in Azure AD filter on this to automatically assign the profile.
    #    - The 'Device group' column in the Intune portal displays this 'Group Tag'.
    #
    # 2. Order ID (in script) -> 'Order ID' (in portal):
    #    - The script sends the SHORT, FRIENDLY NAME (e.g., 'Schletter_WG') as the 'Order ID'.
    #    - You can add the 'Order ID' column in the portal to see this value.
    #
    # 3. 'Profile assigned' is 'None' (in portal):
    #    - Assigning a profile does not happen immediately.
    #    - After the device is uploaded, Azure needs to add the device to the correct dynamic group. This process can take several minutes to an hour.
    #    - Once the device is a member of the group, the 'Profile assigned' status will automatically be updated to the profile name.
    #
    # Conclusion: The script is working correctly. The delay and the display in the portal are part of how Autopilot functions.
    #-------------------------------------------------------------------------------------------------------------
    Show-Branding -scriptVersion $scriptVersion
    Write-Host "Fetching Autopilot profiles from the tenant..." -ForegroundColor Cyan
    $profile = @{ GroupTag = ""; OrderID = "" }

    # Group Tag Mapping
    # Note: Both 'groupTag' and 'purchaseOrderIdentifier' (Order ID) are set to the same value
    # This ensures consistency and matches Azure AD dynamic group filtering requirements
    # Maps Autopilot Profile Display Name -> Group Tag (short, friendly name)
    # Load mappings from external JSON configuration file
    $groupTagMappingPath = Join-Path $scriptRoot "GroupTagMapping.json"

    if (Test-Path $groupTagMappingPath) {
        try {
            Write-Host "Loading Group Tag mappings from $groupTagMappingPath..." -ForegroundColor Cyan
            $groupTagMappingConfig = Get-Content $groupTagMappingPath -Raw | ConvertFrom-Json
            $groupTagMapping = @{}

            # Convert JSON mappings object to PowerShell hashtable
            $groupTagMappingConfig.mappings.PSObject.Properties | ForEach-Object {
                $groupTagMapping[$_.Name] = $_.Value
            }

            Write-Host "Successfully loaded $($groupTagMapping.Count) Group Tag mappings." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to load Group Tag mappings from JSON: $($_.Exception.Message)"
            Write-Warning "Using default mappings as fallback."
            # Fallback to default mappings
            $groupTagMapping = @{
                "ENS_EU_Autopilot_Deployment" = "EsdecEU"
                "SF_EU_Autopilot_Deployment"  = "SF"
                "SLG_Autopilot_Deployment"    = "Schletter"
                "SLG_WG_Autopilot_Deployment" = "Schletter_WG"
                "US_Autopilot_Deployment"     = "US"
            }
        }
    }
    else {
        Write-Warning "Group Tag mapping file not found at: $groupTagMappingPath"
        Write-Warning "Using default mappings."
        # Fallback to default mappings
        $groupTagMapping = @{
            "ENS_EU_Autopilot_Deployment" = "EsdecEU"
            "SF_EU_Autopilot_Deployment"  = "SF"
            "SLG_Autopilot_Deployment"    = "Schletter"
            "SLG_WG_Autopilot_Deployment" = "Schletter_WG"
            "US_Autopilot_Deployment"     = "US"
        }
    }

    try {
        $uri = $script:Config.AutopilotProfilesEndpoint
        $tenantProfiles = (Invoke-MGGraphRequest -Uri $uri -Method Get).value
    }
    catch {
        Write-Warning "Could not retrieve Autopilot profiles automatically. Check API permissions ('DeviceManagementConfiguration.Read.All'). Falling back to manual input."
        $tenantProfiles = $null
    }

    if ($tenantProfiles) {
        do {
            Show-Branding -scriptVersion $scriptVersion
            Write-Host "Select an Autopilot Deployment Profile:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $tenantProfiles.Count; $i++) {
                $profileName = $tenantProfiles[$i].displayName
                $groupTag = $groupTagMapping[$profileName]

                if ($groupTag) {
                    Write-Host ("{0}. {1} (Group Tag: {2})" -f ($i + 1), $profileName, $groupTag)
                }
                else {
                    Write-Host ("{0}. {1} (Group Tag: Not Mapped)" -f ($i + 1), $profileName) -ForegroundColor Gray
                }
            }
            $manualOption = $tenantProfiles.Count + 1
            $noneOption = $tenantProfiles.Count + 2
            Write-Host "$manualOption. Manual Group Tag input"
            Write-Host "$noneOption. No Group Tag"

            $profileChoice = Read-Host "Enter your choice (1-$noneOption)"
            $validChoice = $true

            if ($profileChoice -ge 1 -and $profileChoice -le $tenantProfiles.Count) {
                $selectedIndex = [int]$profileChoice - 1
                $selectedProfileName = $tenantProfiles[$selectedIndex].displayName

                if ($groupTagMapping.ContainsKey($selectedProfileName)) {
                    $assignedGroupTag = $groupTagMapping[$selectedProfileName]
                    $profile.GroupTag = $assignedGroupTag
                    $profile.OrderID = $assignedGroupTag  # Same value for both fields
                    Write-Host "Assigned Group Tag: $assignedGroupTag" -ForegroundColor Green
                }
                else {
                    Write-Host "Selected profile '$selectedProfileName' has no pre-defined Group Tag." -ForegroundColor Yellow
                    $manualTag = Read-Host "Please enter the Group Tag for this device"
                    $profile.GroupTag = $manualTag
                    $profile.OrderID = $manualTag  # Same value for both fields
                }
            }
            elseif ($profileChoice -eq $manualOption) {
                $manualTag = Read-Host "Enter the Group Tag"
                $profile.GroupTag = $manualTag
                $profile.OrderID = $manualTag  # Same value for both fields
            }
            elseif ($profileChoice -eq $noneOption) {
                # Values are already empty, so just break
            }
            else {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 5
                $validChoice = $false
            }
        } while (-not $validChoice)
    }
    else {
        do {
            Show-Branding -scriptVersion $scriptVersion
            Write-Host "Select an option:" -ForegroundColor Yellow
            Write-Host "1. Manual Group Tag input"
            Write-Host "2. No Group Tag"
            $fallbackChoice = Read-Host "Enter your choice (1-2)"
            $validChoice = $true
            switch ($fallbackChoice) {
                "1" {
                    $manualTag = Read-Host "Enter the Group Tag"
                    $profile.GroupTag = $manualTag
                    $profile.OrderID = $manualTag  # Same value for both fields
                }
                "2" { }
                default {
                    Write-Host "Invalid selection. Please try again." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    $validChoice = $false
                }
            }
        } while (-not $validChoice)
    }
    
    return $profile
}

# --- Function to Collect Hardware Information ---
function Get-HardwareInfo {
    Write-Host "Collecting the local device's hardware hash..." -ForegroundColor Cyan

    try {
        # Collect hardware info with retry logic
        $hwInfo = Invoke-WithRetry -MaxRetries $script:Config.DefaultMaxRetries -InitialDelaySeconds $script:Config.DefaultInitialDelaySeconds -OperationName "Hardware Hash Collection" -ScriptBlock {
            # Get serial number
            Write-Host "Querying BIOS information..." -ForegroundColor Cyan
            $bios = Get-CimInstance -Class Win32_BIOS -ErrorAction Stop
            $serialNumber = $bios.SerialNumber

            if ([string]::IsNullOrWhiteSpace($serialNumber)) {
                throw "Serial number is empty or null"
            }

            # Get hardware hash from MDM namespace
            Write-Host "Querying hardware hash from MDM namespace..." -ForegroundColor Cyan
            $devDetail = Get-CimInstance `
                -Namespace root/cimv2/mdm/dmmap `
                -Class MDM_DevDetail_Ext01 `
                -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" `
                -ErrorAction Stop

            $hardwareHash = $devDetail.DeviceHardwareData

            if ([string]::IsNullOrWhiteSpace($hardwareHash)) {
                throw "Hardware hash is empty or null"
            }

            # Validate hash format (should be base64)
            try {
                $null = [Convert]::FromBase64String($hardwareHash)
            }
            catch {
                throw "Hardware hash is not in valid base64 format"
            }

            # Get computer model
            $computerSystem = Get-CimInstance -Class Win32_ComputerSystem -ErrorAction SilentlyContinue

            return @{
                SerialNumber = $serialNumber.Trim()
                HardwareHash = $hardwareHash
                Manufacturer = $bios.Manufacturer
                Model = $computerSystem.Model
            }
        }

        Write-Host "Successfully collected hardware information:" -ForegroundColor Green
        Write-Host "  Serial Number: $($hwInfo.SerialNumber)" -ForegroundColor Green
        Write-Host "  Manufacturer: $($hwInfo.Manufacturer)" -ForegroundColor Green
        Write-Host "  Model: $($hwInfo.Model)" -ForegroundColor Green

        return $hwInfo
    }
    catch {
        Write-Error "Failed to collect hardware hash. Error: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "  1. Ensure the script is running with Administrator privileges" -ForegroundColor Yellow
        Write-Host "  2. Verify WMI/CIM services are running (winmgmt service)" -ForegroundColor Yellow
        Write-Host "  3. This must be run on a physical device or supported VM" -ForegroundColor Yellow
        Write-Host "  4. Some virtualization platforms may not support hardware hash extraction" -ForegroundColor Yellow
        throw
    }
}

# --- Function to Connect to Graph ---
function Connect-GraphAsApp {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Credentials
    )

    Write-Host "Connecting to Microsoft Graph via App Registration..." -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "[DRY RUN] Would have connected to Microsoft Graph." -ForegroundColor Yellow
        return
    }

    try {
        # Get access token with retry logic
        $accessToken = Invoke-WithRetry -MaxRetries $script:Config.GraphAuthRetries -InitialDelaySeconds 3 -OperationName "Graph API Authentication" -ScriptBlock {
            $body = @{
                grant_type    = "client_credentials"
                client_id     = $Credentials.AppID
                client_secret = $Credentials.AppSecret
                scope         = "https://graph.microsoft.com/.default"
            }

            $tokenUri = $script:Config.GraphTokenEndpoint -f $Credentials.TenantID
            Write-Host "Requesting access token from Azure AD..." -ForegroundColor Cyan

            $response = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $body -TimeoutSec $script:Config.ShortWebRequestTimeoutSeconds -ErrorAction Stop

            if (-not $response.access_token) {
                throw "No access token received in response"
            }

            return $response.access_token
        }

        # Convert to secure string and connect
        $secureToken = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

        # Disconnect any existing session
        if (Get-MgContext -ErrorAction SilentlyContinue) {
            Write-Host "Disconnecting existing Graph session..." -ForegroundColor Yellow
            Disconnect-MgGraph -ErrorAction SilentlyContinue
        }

        # Connect to Graph
        Connect-MgGraph -AccessToken $secureToken -NoWelcome -ErrorAction Stop

        # Verify connection
        $context = Get-MgContext
        if (-not $context) {
            throw "Connected to Graph but context is null"
        }

        Write-Host "Successfully connected to Microsoft Graph (Tenant: $($context.TenantId))" -ForegroundColor Green
    }
    catch {
        $errorDetails = $_.ErrorDetails.Message
        if ($errorDetails) {
            try {
                $errorObj = $errorDetails | ConvertFrom-Json
                $errorMessage = $errorObj.error_description
                if (-not $errorMessage) {
                    $errorMessage = $errorObj.error
                }
            }
            catch {
                $errorMessage = $errorDetails
            }
        }
        else {
            $errorMessage = $_.Exception.Message
        }

        Write-Error "Authentication to Graph API failed. Error: $errorMessage"
        Write-Host ""
        Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
        Write-Host "  1. Verify Tenant ID is correct: $($Credentials.TenantID)" -ForegroundColor Yellow
        Write-Host "  2. Verify App ID (Client ID) is correct" -ForegroundColor Yellow
        Write-Host "  3. Verify App Secret has not expired" -ForegroundColor Yellow
        Write-Host "  4. Ensure the app registration has required API permissions:" -ForegroundColor Yellow
        Write-Host "     - DeviceManagementServiceConfig.ReadWrite.All" -ForegroundColor Yellow
        Write-Host "     - DeviceManagementConfiguration.Read.All" -ForegroundColor Yellow
        Write-Host "  5. Ensure admin consent has been granted for the permissions" -ForegroundColor Yellow
        throw
    }
}

# --- Function to Query Existing Autopilot Device by Serial Number ---
function Get-AutopilotDeviceBySerial {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber
    )

    Write-Host "Searching for existing Autopilot device with serial number: $SerialNumber..." -ForegroundColor Cyan

    try {
        $uri = "$($script:Config.AutopilotDevicesEndpoint)?`$filter=contains(serialNumber,'$SerialNumber')"
        $response = Invoke-MgGraphRequest -Uri $uri -Method Get -ErrorAction Stop

        if ($response.value -and $response.value.Count -gt 0) {
            # Find exact match (filter can return partial matches)
            $exactMatch = $response.value | Where-Object { $_.serialNumber -eq $SerialNumber }

            if ($exactMatch) {
                Write-Host "Found existing device: $($exactMatch.id)" -ForegroundColor Yellow
                return $exactMatch
            }
        }

        Write-Host "No existing device found with serial number: $SerialNumber" -ForegroundColor Gray
        return $null
    }
    catch {
        Write-Warning "Failed to query existing device: $($_.Exception.Message)"
        return $null
    }
}

# --- Function to Delete Existing Autopilot Device ---
function Remove-AutopilotDevice {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceId
    )

    Write-Host "Deleting existing Autopilot device (ID: $DeviceId)..." -ForegroundColor Yellow

    try {
        $uri = "$($script:Config.AutopilotDevicesEndpoint)/$DeviceId"
        Invoke-MgGraphRequest -Uri $uri -Method Delete -ErrorAction Stop

        Write-Host "Successfully deleted existing device." -ForegroundColor Green
        Write-Host "Waiting $($script:Config.PostDeletionWaitSeconds) seconds for Azure AD sync..." -ForegroundColor Cyan
        Start-Sleep -Seconds $script:Config.PostDeletionWaitSeconds

        return $true
    }
    catch {
        Write-Error "Failed to delete device: $($_.Exception.Message)"
        return $false
    }
}

# --- Function to Build Autopilot Device Request Body ---
function New-AutopilotDeviceRequestBody {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$HardwareInfo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$Profile
    )

    # Validate required hardware info fields
    if ([string]::IsNullOrWhiteSpace($HardwareInfo.SerialNumber)) {
        throw "HardwareInfo must contain a non-empty SerialNumber"
    }
    if ([string]::IsNullOrWhiteSpace($HardwareInfo.HardwareHash)) {
        throw "HardwareInfo must contain a non-empty HardwareHash"
    }

    $requestBody = @{
        "@odata.type"             = "#microsoft.graph.importedWindowsAutopilotDeviceIdentity"
        "groupTag"                = if ($Profile.GroupTag) { $Profile.GroupTag } else { "" }
        "serialNumber"            = $HardwareInfo.SerialNumber
        "productKey"              = "" # Not needed
        "hardwareIdentifier"      = $HardwareInfo.HardwareHash
        "purchaseOrderIdentifier" = if ($Profile.OrderID) { $Profile.OrderID } else { "" }
    }

    return ($requestBody | ConvertTo-Json)
}

# --- Function to Send Autopilot Device Registration ---
function Send-AutopilotDeviceRegistration {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$HardwareInfo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$Profile
    )

    $uri = $script:Config.AutopilotImportEndpoint
    $requestBody = New-AutopilotDeviceRequestBody -HardwareInfo $HardwareInfo -Profile $Profile

    Write-Host "Sending device registration request to Intune..." -ForegroundColor Cyan
    $response = Invoke-MGGraphRequest -Uri $uri -Method Post -Body $requestBody -ContentType "application/json" -ErrorAction Stop

    # Verify the response
    if ($response -and $response.id) {
        Write-Host "Device registered with ID: $($response.id)" -ForegroundColor Green
    }

    return $response
}

# --- Function to Upload Hash to Autopilot ---
function Invoke-UploadAutopilotHash {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$HardwareInfo,

        [Parameter(Mandatory = $true)]
        [hashtable]$Profile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Prompt", "Skip", "Delete", "Error")]
        [string]$DuplicateHandling = "Prompt"
    )

    Write-Host "Uploading the hardware hash for serial number $($HardwareInfo.SerialNumber) to the Autopilot service..." -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "[DRY RUN] Would have uploaded hardware hash for serial number $($HardwareInfo.SerialNumber)." -ForegroundColor Yellow
        Write-Host "[DRY RUN] GroupTag: $($Profile.GroupTag), OrderID: $($Profile.OrderID)" -ForegroundColor Gray
        return
    }

    # PROACTIVE CHECK: Query if device already exists before attempting upload
    Write-Host ""
    Write-Host "Checking if device is already registered in Autopilot..." -ForegroundColor Cyan
    $existingDevice = Get-AutopilotDeviceBySerial -SerialNumber $HardwareInfo.SerialNumber

    if ($existingDevice) {
        Write-Host ""
        Write-Host "DEVICE ALREADY REGISTERED!" -ForegroundColor Yellow
        Write-Host "-------------------------------------------" -ForegroundColor Yellow
        Write-Host "Serial Number: $($existingDevice.serialNumber)" -ForegroundColor Cyan
        Write-Host "Current Group Tag: $($existingDevice.groupTag)" -ForegroundColor Cyan
        Write-Host "Device ID: $($existingDevice.id)" -ForegroundColor Gray
        Write-Host "-------------------------------------------" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "New registration will use:" -ForegroundColor Green
        Write-Host "Group Tag: $($Profile.GroupTag)" -ForegroundColor Green
        Write-Host ""

        # Check if Group Tag is different
        if ($existingDevice.groupTag -ne $Profile.GroupTag) {
            Write-Host "NOTE: Group Tag will be CHANGED from '$($existingDevice.groupTag)' to '$($Profile.GroupTag)'" -ForegroundColor Magenta
            Write-Host ""
        }
        else {
            Write-Host "NOTE: Group Tag is the same. Device will be re-registered with existing Group Tag." -ForegroundColor Cyan
            Write-Host ""
        }

        # Determine action based on DuplicateHandling parameter
        $shouldDelete = $false
        switch ($DuplicateHandling) {
            "Prompt" {
                Write-Host "Would you like to delete the existing registration and re-register with the new settings?" -ForegroundColor Yellow
                Write-Host "  [Y] Yes - Delete and re-register (recommended if changing Group Tag)" -ForegroundColor White
                Write-Host "  [N] No  - Cancel registration (device keeps existing settings)" -ForegroundColor White
                Write-Host ""
                $choice = Read-Host "Delete and re-register? (y/n)"
                $shouldDelete = ($choice -eq 'y' -or $choice -eq 'Y')
            }
            "Delete" {
                Write-Host "DuplicateHandling=Delete: Automatically deleting and re-registering..." -ForegroundColor Cyan
                $shouldDelete = $true
            }
            "Skip" {
                Write-Host "DuplicateHandling=Skip: Skipping registration (device keeps existing settings)." -ForegroundColor Yellow
                return
            }
            "Error" {
                throw "Device already registered and DuplicateHandling is set to Error. Registration aborted."
            }
        }

        if ($shouldDelete) {
            Write-Host ""
            Write-Host "Deleting existing device registration..." -ForegroundColor Cyan

            $deleteSuccess = Remove-AutopilotDevice -DeviceId $existingDevice.id

            if (-not $deleteSuccess) {
                throw "Failed to delete existing device. Cannot proceed with re-registration."
            }

            Write-Host "Proceeding with new registration..." -ForegroundColor Cyan
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "Registration cancelled. Device keeps existing Autopilot registration." -ForegroundColor Yellow
            Write-Host "To change the Group Tag, re-run the script and select 'Y' when prompted." -ForegroundColor Yellow
            return
        }
    }

    # Proceed with upload
    try {
        # Upload with retry logic
        $response = Invoke-WithRetry `
            -MaxRetries $script:Config.UploadRetries `
            -InitialDelaySeconds 5 `
            -OperationName "Autopilot Device Upload" `
            -ScriptBlock {
                Send-AutopilotDeviceRegistration -HardwareInfo $HardwareInfo -Profile $Profile
            }

        Write-Host ""
        Write-Host "SUCCESS: Device has been successfully registered in Autopilot!" -ForegroundColor Green
        Write-Host "-------------------------------------------" -ForegroundColor Green
        Write-Host "Serial Number: $($HardwareInfo.SerialNumber)" -ForegroundColor Cyan
        if ($Profile.GroupTag) {
            Write-Host "Group Tag: $($Profile.GroupTag)" -ForegroundColor Cyan
        }
        if ($Profile.OrderID) {
            Write-Host "Order ID: $($Profile.OrderID)" -ForegroundColor Cyan
        }
        Write-Host "-------------------------------------------" -ForegroundColor Green
        Write-Host ""
        Write-Host "Note: It may take 5-10 minutes for the device to appear in the Intune portal." -ForegroundColor Yellow
        Write-Host "      Profile assignment may take longer (up to 1 hour) for dynamic group membership." -ForegroundColor Yellow
    }
    catch {
        # Enhanced error message parsing
        $errorMessage = "An unknown error occurred."
        $errorCode = ""

        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                if ($errorJson.error) {
                    $errorMessage = $errorJson.error.message
                    $errorCode = $errorJson.error.code
                }
            }
            catch {
                $errorMessage = $_.ErrorDetails.Message
            }
        }
        elseif ($_.Exception.Message) {
            $errorMessage = $_.Exception.Message
        }

        Write-Error "Failed to import device $($HardwareInfo.SerialNumber). Error: $errorMessage"

        if ($errorCode) {
            Write-Host "Error Code: $errorCode" -ForegroundColor Red
        }

        Write-Host ""
        Write-Host "Common issues and solutions:" -ForegroundColor Yellow

        # Provide specific guidance based on error
        if ($errorMessage -like "*already exists*" -or $errorMessage -like "*duplicate*") {
            Write-Host ""
            Write-Host "This device is already registered in Autopilot!" -ForegroundColor Yellow
            Write-Host ""

            # Determine action based on DuplicateHandling parameter (fallback error handling)
            $shouldDeleteOnError = $false
            switch ($DuplicateHandling) {
                "Prompt" {
                    Write-Host "Would you like to delete the existing entry and re-register with the new profile?" -ForegroundColor Cyan
                    Write-Host "  - Current device will be removed from Autopilot" -ForegroundColor Gray
                    Write-Host "  - New registration will use the selected profile settings" -ForegroundColor Gray
                    Write-Host ""
                    $choice = Read-Host "Delete and re-register? (y/n)"
                    $shouldDeleteOnError = ($choice -eq 'y' -or $choice -eq 'Y')
                }
                "Delete" {
                    Write-Host "DuplicateHandling=Delete: Automatically deleting and re-registering..." -ForegroundColor Cyan
                    $shouldDeleteOnError = $true
                }
                "Skip" {
                    Write-Host "DuplicateHandling=Skip: Skipping registration (device keeps existing settings)." -ForegroundColor Yellow
                    throw "Device already exists and DuplicateHandling is set to Skip."
                }
                "Error" {
                    throw "Device already registered and DuplicateHandling is set to Error. Registration aborted."
                }
            }

            if ($shouldDeleteOnError) {
                Write-Host ""
                Write-Host "Attempting to delete and re-register device..." -ForegroundColor Cyan

                # Query existing device
                $existingDevice = Get-AutopilotDeviceBySerial -SerialNumber $HardwareInfo.SerialNumber

                if ($existingDevice) {
                    # Delete existing device
                    $deleteSuccess = Remove-AutopilotDevice -DeviceId $existingDevice.id

                    if ($deleteSuccess) {
                        Write-Host ""
                        Write-Host "Re-attempting device registration with new profile..." -ForegroundColor Cyan

                        # Retry the upload using the helper function
                        try {
                            $response = Send-AutopilotDeviceRegistration -HardwareInfo $HardwareInfo -Profile $Profile

                            Write-Host ""
                            Write-Host "SUCCESS: Device has been successfully re-registered in Autopilot!" -ForegroundColor Green
                            Write-Host "-------------------------------------------" -ForegroundColor Green
                            Write-Host "Serial Number: $($HardwareInfo.SerialNumber)" -ForegroundColor Cyan
                            if ($Profile.GroupTag) {
                                Write-Host "Group Tag: $($Profile.GroupTag)" -ForegroundColor Cyan
                            }
                            if ($Profile.OrderID) {
                                Write-Host "Order ID: $($Profile.OrderID)" -ForegroundColor Cyan
                            }
                            Write-Host "-------------------------------------------" -ForegroundColor Green
                            Write-Host ""
                            Write-Host "Note: It may take 5-10 minutes for the device to appear in the Intune portal." -ForegroundColor Yellow
                            return  # Success - exit function
                        }
                        catch {
                            Write-Error "Failed to re-register device: $($_.Exception.Message)"
                            throw
                        }
                    }
                    else {
                        Write-Host ""
                        Write-Host "Failed to delete existing device. Cannot proceed with re-registration." -ForegroundColor Red
                        throw
                    }
                }
                else {
                    Write-Host ""
                    Write-Host "Could not find existing device to delete." -ForegroundColor Red
                    Write-Host "You may need to manually delete it from the Intune portal:" -ForegroundColor Yellow
                    Write-Host "  Devices > Windows > Windows enrollment > Devices" -ForegroundColor Yellow
                    throw
                }
            }
            else {
                Write-Host ""
                Write-Host "Operation cancelled. Device was not re-registered." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "To manually update the device:" -ForegroundColor Cyan
                Write-Host "  - Check the Intune portal: Devices > Windows > Windows enrollment > Devices" -ForegroundColor Gray
                Write-Host "  - Delete the existing entry manually if needed" -ForegroundColor Gray
                throw
            }
        }
        elseif ($errorMessage -like "*Forbidden*" -or $errorMessage -like "*401*" -or $errorMessage -like "*403*") {
            Write-Host "  - Insufficient permissions. Verify API permissions:" -ForegroundColor Yellow
            Write-Host "    * DeviceManagementServiceConfig.ReadWrite.All" -ForegroundColor Yellow
            Write-Host "  - Ensure admin consent has been granted" -ForegroundColor Yellow
        }
        elseif ($errorMessage -like "*serialNumber*") {
            Write-Host "  - Invalid or missing serial number" -ForegroundColor Yellow
            Write-Host "  - Serial collected: $($HardwareInfo.SerialNumber)" -ForegroundColor Yellow
        }
        elseif ($errorMessage -like "*hardwareIdentifier*" -or $errorMessage -like "*hash*") {
            Write-Host "  - Invalid hardware hash format" -ForegroundColor Yellow
            Write-Host "  - Ensure running on compatible hardware/VM" -ForegroundColor Yellow
        }
        else {
            Write-Host "  - Verify network connectivity to Microsoft Graph API" -ForegroundColor Yellow
            Write-Host "  - Check if Graph API authentication is still valid" -ForegroundColor Yellow
            Write-Host "  - Review the error message above for more details" -ForegroundColor Yellow
        }

        throw
    }
}
#endregion Main Workflow Functions

# --- SCRIPT EXECUTION ---
Show-Branding -scriptVersion $scriptVersion
Write-Host ""
Write-Host "!!! AUTHORIZED PERSONNEL ONLY !!!" -ForegroundColor Red -BackgroundColor Black
Write-Host "This tool accesses sensitive Azure AD credentials and Intune services." -ForegroundColor Yellow
Write-Host "Unauthorized use is strictly prohibited and may violate security policies." -ForegroundColor Yellow
Write-Host ""
Write-Host "Starting the Autopilot Device Registration Process..." -ForegroundColor Cyan

try {
    # --- Step 1: Test Network Connectivity ---
    Write-Host ""
    Test-NetworkConnectivity

    # --- Step 2: Get Credentials ---
    Write-Host ""
    $credentials = Get-TenantCredentials
    if ([string]::IsNullOrWhiteSpace($credentials.TenantID)) {
        throw "Tenant credentials were not provided. Exiting."
    }

    # --- Step 3: Prepare Modules and Connect to Graph ---
    Write-Host ""
    Ensure-ModuleInstalled -ModuleName "Microsoft.Graph.Authentication"
    Import-Module Microsoft.Graph.Authentication -Force
    Connect-GraphAsApp -Credentials $credentials

    # --- Step 4: Get Profile ---
    Write-Host ""
    $profile = Get-AutopilotProfile
    Write-Host "Selected Profile: GroupTag = '$($profile.GroupTag)', OrderID = '$($profile.OrderID)'" -ForegroundColor Green

    # --- Step 5: Collect & Upload ---
    Write-Host ""
    $hardwareInfo = Get-HardwareInfo
    Write-Host ""
    Invoke-UploadAutopilotHash -HardwareInfo $hardwareInfo -Profile $profile -DuplicateHandling $DuplicateHandling

    #===============================================================================================================
    # FINAL SUMMARY
    #===============================================================================================================
    Show-Branding -scriptVersion $scriptVersion
    Write-Host "Registration Complete!" -ForegroundColor Green
    Write-Host "-------------------------------------------"
    Write-Host (" {0,-15} : {1}" -f "Serial Number", $hardwareInfo.SerialNumber)
    Write-Host (" {0,-15} : {1}" -f "Tenant ID", $credentials.TenantID)
    Write-Host (" {0,-15} : {1}" -f "Group Tag", $profile.GroupTag)
    Write-Host (" {0,-15} : {1}" -f "Order ID", $profile.OrderID)
    Write-Host "-------------------------------------------"
    Write-Host ""

    $rebootChoice = Read-Host "Would you like to reboot the computer now? (y/n)"
    if ($rebootChoice -eq 'y' -or $rebootChoice -eq 'Y') {
        Write-Host "Rebooting in $($script:Config.PreRebootWaitSeconds) seconds..." -ForegroundColor Yellow
        if (-not $DryRun) {
            Start-Sleep -Seconds $script:Config.PreRebootWaitSeconds
            Restart-Computer -Force
        } else {
            Write-Host "[DRY RUN] Would have rebooted the computer." -ForegroundColor Yellow
        }
    }

}
catch {
    Write-Error "The script encountered a fatal error and could not complete. Full error: $_"
}
finally {
    # --- Disconnect from Graph ---
    if (Get-MgContext -ErrorAction SilentlyContinue) {
        Write-Host "Disconnecting from Graph API."
        Disconnect-MgGraph
    }

    # --- DEBUG MODE: Stop Logging ---
    if ($DryRun) {
        try {
            Write-Host ""
            Write-Host "[DEBUG] Stopping transcript and saving log file..." -ForegroundColor Cyan
            Stop-Transcript -ErrorAction SilentlyContinue
            Write-Host "[DEBUG] Log file saved: $logFile" -ForegroundColor Green
        }
        catch {
            # Silently ignore transcript stop errors
        }
    }
}
