# ================================================================================
# branding.ps1 - Corporate Branding Module
# ================================================================================
#
# PURPOSE:
# This script provides corporate branding and UI elements for Autopilot
# registration tools. It displays your company logo and script information.
#
# USAGE:
# This file is dot-sourced by Register-ThisPC.ps1 and related scripts.
# Do not execute this file directly.
#
# CUSTOMIZATION:
# Replace the unicorn logo below with your own company ASCII art logo.
# Modify colors, tagline, and author information as needed.
#
# Author:  Your Name
# Created: 2025
# Modified: 2025
# ================================================================================

function Show-Branding {
    param (
        [string]$scriptVersion
    )

    # TEMPORARY: Pause before clearing screen to review output
    Write-Host "`n[DEBUG] Press any key to continue and show logo..." -ForegroundColor Yellow
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        # In non-interactive environments, just wait a moment
        Start-Sleep -Seconds 3
    }

    # Clear screen (handle non-interactive environments gracefully)
    try {
        Clear-Host
    }
    catch {
        # In non-interactive environments, just add spacing
        Write-Host "`n`n`n"
    }

    $logoTopColor = "Magenta"
    $logoMidColor = "Cyan"
    $logoBottomColor = "White"
    $lineColor = "DarkBlue"
    $textColor = "White"
    $labelColor = "Gray"

    # Unicorn ASCII Art Logo
    $logoTop = @"
                    ,.
                   (_|,.
                  ,' /, )_______
               __j o``-'        ``-.
              (")                   \
               `-j                   |
                 _|   /--______     /
"@
    $logoMid = @"
                /  / (  |   /
               /  /   `-'  /
              /  /         |
"@
    $logoBottom = @"
             /  '           !
            /  .-.      _,'
           |  (   \    <
           \   `-'  \
            `-.___,' ;-._
"@

    Write-Host $logoTop -ForegroundColor $logoTopColor
    Write-Host $logoMid -ForegroundColor $logoMidColor
    Write-Host $logoBottom -ForegroundColor $logoBottomColor

    Write-Host ""
    Write-Host "          Windows Autopilot Registration Tool" -ForegroundColor $textColor
    Write-Host "              Magical Device Provisioning" -ForegroundColor $labelColor
    Write-Host ("-"*70) -ForegroundColor $lineColor
    Write-Host ("  {0,-15} : {1}" -f "Version", $scriptVersion) -ForegroundColor $labelColor
    Write-Host ("  {0,-15} : {1}" -f "Author", "Community Edition") -ForegroundColor $labelColor
    Write-Host ("  {0,-15} : {1}" -f "PowerShell Ver.", ($PSVersionTable.PSVersion.ToString())) -ForegroundColor $labelColor
    Write-Host ("-"*70) -ForegroundColor $lineColor
    Write-Host ""
}
