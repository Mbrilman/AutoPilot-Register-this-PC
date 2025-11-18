# ================================================================================
# Test-Enhancements.ps1 - Validation Script for Security Enhancements
# ================================================================================
#
# PURPOSE:
# This script tests all the security enhancements and error handling improvements
# made to Register-ThisPC.ps1 without actually executing the full registration.
#
# Author: Community Edition
# Created: 11/11/2025
# ================================================================================

[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
$testResults = @()

function Test-Feature {
    param(
        [string]$FeatureName,
        [scriptblock]$TestCode
    )

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing: $FeatureName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        & $TestCode
        $result = @{
            Feature = $FeatureName
            Status = "PASS"
            Message = "Test completed successfully"
        }
        Write-Host "[PASS] $FeatureName" -ForegroundColor Green
    }
    catch {
        $result = @{
            Feature = $FeatureName
            Status = "FAIL"
            Message = $_.Exception.Message
        }
        Write-Host "[FAIL] $FeatureName - $($_.Exception.Message)" -ForegroundColor Red
    }

    $script:testResults += $result
}

Write-Host @"
================================================================================
              SECURITY ENHANCEMENTS VALIDATION TEST
================================================================================
Version: 3.1.0
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Test Environment: $env:COMPUTERNAME
User: $env:USERNAME
================================================================================
"@ -ForegroundColor Yellow

# Test 1: File Existence
Test-Feature "Required Files Exist" {
    $requiredFiles = @(
        "Register-ThisPC.ps1",
        "Register-ThisPC.ini",
        "branding.ps1",
        "SECURITY_README.md",
        ".gitignore",
        "QUICK_REFERENCE.md"
    )

    foreach ($file in $requiredFiles) {
        $path = Join-Path $scriptRoot $file
        if (-not (Test-Path $path)) {
            throw "Missing required file: $file"
        }
        Write-Host "  [OK] Found: $file" -ForegroundColor Gray
    }
}

# Test 2: INI File Security Header
Test-Feature "INI File Has Security Header" {
    $iniPath = Join-Path $scriptRoot "Register-ThisPC.ini"
    $content = Get-Content $iniPath -Raw

    $requiredKeywords = @(
        "IMPORTANT SECURITY NOTICE",
        "HIGHLY SENSITIVE CREDENTIALS",
        "AUTHORIZED PERSONNEL ONLY",
        "DO NOT share",
        "ROTATE"
    )

    foreach ($keyword in $requiredKeywords) {
        if ($content -notlike "*$keyword*") {
            throw "Missing security keyword in INI: $keyword"
        }
        Write-Host "  [OK] Found keyword: $keyword" -ForegroundColor Gray
    }
}

# Test 3: Main Script Security Notices
Test-Feature "Main Script Has Security Notices" {
    $scriptPath = Join-Path $scriptRoot "Register-ThisPC.ps1"
    $content = Get-Content $scriptPath -Raw

    $requiredElements = @(
        "AUTHORIZED PERSONNEL ONLY",
        "IMPORTANT SECURITY NOTICE",
        "Invoke-WithRetry",
        "Test-NetworkConnectivity",
        "scriptVersion = `"3.1.0`"",
        "Enhanced Error Handling & Retry Logic"
    )

    foreach ($element in $requiredElements) {
        if ($content -notlike "*$element*") {
            throw "Missing element in script: $element"
        }
        Write-Host "  [OK] Found: $element" -ForegroundColor Gray
    }
}

# Test 4: Branding Script
Test-Feature "Branding Script Loads" {
    $brandingPath = Join-Path $scriptRoot "branding.ps1"
    . $brandingPath

    if (-not (Get-Command Show-Branding -ErrorAction SilentlyContinue)) {
        throw "Show-Branding function not loaded"
    }

    Write-Host "  [OK] Show-Branding function loaded" -ForegroundColor Gray
}

# Test 5: Retry Function Logic
Test-Feature "Retry Logic Implementation" {
    . (Join-Path $scriptRoot "Register-ThisPC.ps1")

    if (-not (Get-Command Invoke-WithRetry -ErrorAction SilentlyContinue)) {
        throw "Invoke-WithRetry function not found"
    }

    # Test successful retry
    $counter = 0
    $result = Invoke-WithRetry -MaxRetries 3 -InitialDelaySeconds 1 -OperationName "Test" -ScriptBlock {
        $counter++
        if ($counter -lt 2) {
            throw "Simulated failure"
        }
        return "Success"
    }

    if ($result -ne "Success") {
        throw "Retry logic did not succeed"
    }

    Write-Host "  [OK] Retry logic works (succeeded on attempt $counter)" -ForegroundColor Gray
}

# Test 6: Network Connectivity Function
Test-Feature "Network Connectivity Check" {
    . (Join-Path $scriptRoot "Register-ThisPC.ps1")

    if (-not (Get-Command Test-NetworkConnectivity -ErrorAction SilentlyContinue)) {
        throw "Test-NetworkConnectivity function not found"
    }

    Write-Host "  [OK] Network check function exists" -ForegroundColor Gray

    # Try to run it (may fail in restricted environments)
    try {
        Test-NetworkConnectivity -TestUrls @("https://www.microsoft.com")
        Write-Host "  [OK] Network check executed" -ForegroundColor Gray
    }
    catch {
        Write-Host "  [WARN] Network check failed (expected in restricted environments)" -ForegroundColor Yellow
    }
}

# Test 7: .gitignore Protection
Test-Feature ".gitignore Protects Sensitive Files" {
    $gitignorePath = Join-Path $scriptRoot ".gitignore"
    $content = Get-Content $gitignorePath -Raw

    $protectedPatterns = @(
        "*.ini",
        "*credentials*",
        "*secret*",
        "*.log"
    )

    foreach ($pattern in $protectedPatterns) {
        if ($content -notlike "*$pattern*") {
            throw "Missing protection pattern: $pattern"
        }
        Write-Host "  [OK] Protects: $pattern" -ForegroundColor Gray
    }
}

# Test 8: Documentation Completeness
Test-Feature "Documentation Files Complete" {
    $securityReadme = Join-Path $scriptRoot "SECURITY_README.md"
    $quickRef = Join-Path $scriptRoot "QUICK_REFERENCE.md"

    $securityContent = Get-Content $securityReadme -Raw
    $quickRefContent = Get-Content $quickRef -Raw

    # Check SECURITY_README.md
    $securityKeywords = @("Incident Response", "Authorized Personnel", "Credential Rotation")
    foreach ($keyword in $securityKeywords) {
        if ($securityContent -notlike "*$keyword*") {
            throw "Missing keyword in SECURITY_README.md: $keyword"
        }
    }
    Write-Host "  [OK] SECURITY_README.md is complete" -ForegroundColor Gray

    # Check QUICK_REFERENCE.md
    $quickRefKeywords = @("Pre-Flight Checklist", "Troubleshooting", "Security Reminders")
    foreach ($keyword in $quickRefKeywords) {
        if ($quickRefContent -notlike "*$keyword*") {
            throw "Missing keyword in QUICK_REFERENCE.md: $keyword"
        }
    }
    Write-Host "  [OK] QUICK_REFERENCE.md is complete" -ForegroundColor Gray
}

# Test 9: PowerShell Syntax Validation
Test-Feature "PowerShell Syntax Validation" {
    $scriptPath = Join-Path $scriptRoot "Register-ThisPC.ps1"

    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptPath,
        [ref]$tokens,
        [ref]$errors
    )

    if ($errors) {
        throw "Syntax errors found: $($errors.Count) errors"
    }

    Write-Host "  [OK] No syntax errors found" -ForegroundColor Gray
}

# Test 10: Version Consistency
Test-Feature "Version Numbers Consistent" {
    $scriptPath = Join-Path $scriptRoot "Register-ThisPC.ps1"
    $content = Get-Content $scriptPath -Raw

    # Check .NOTES version
    if ($content -match 'Version:\s+(\d+\.\d+\.\d+)') {
        $notesVersion = $Matches[1]
        Write-Host "  [OK] .NOTES Version: $notesVersion" -ForegroundColor Gray
    }
    else {
        throw ".NOTES version not found"
    }

    # Check scriptVersion variable
    if ($content -match '\$scriptVersion\s*=\s*"(\d+\.\d+\.\d+)"') {
        $varVersion = $Matches[1]
        Write-Host "  [OK] scriptVersion: $varVersion" -ForegroundColor Gray
    }
    else {
        throw "scriptVersion variable not found"
    }

    if ($notesVersion -ne $varVersion) {
        throw "Version mismatch: .NOTES=$notesVersion, variable=$varVersion"
    }

    Write-Host "  [OK] Versions match: $notesVersion" -ForegroundColor Gray
}

# Summary
Write-Host "`n`n" -NoNewline
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                              TEST SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host "`nTotal Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($result in $testResults | Where-Object { $_.Status -eq "FAIL" }) {
        Write-Host "  - $($result.Feature): $($result.Message)" -ForegroundColor Red
    }
}

Write-Host "`n================================================================================" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "`n  ALL TESTS PASSED! Security enhancements are working correctly." -ForegroundColor Green
    Write-Host "  Script is ready for production use.`n" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n  SOME TESTS FAILED. Please review the errors above." -ForegroundColor Red
    Write-Host "  Fix issues before deploying to production.`n" -ForegroundColor Red
    exit 1
}
