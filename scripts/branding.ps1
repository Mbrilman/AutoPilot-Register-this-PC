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
# Replace the octopus logo below with your own company ASCII art logo.
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

    # Clear screen (handle non-interactive environments gracefully)
    try {
        Clear-Host
    }
    catch {
        # In non-interactive environments, just add spacing
        Write-Host "`n`n`n"
    }

    $logoTopColor = "Cyan"
    $logoMidColor = "Blue"
    $logoBottomColor = "DarkCyan"
    $lineColor = "DarkBlue"
    $textColor = "White"
    $labelColor = "Gray"

    # Octopus ASCII Art Logo
    $logoTop = @"
                       ___
                    .-'   `-.
                   /         \
                   |         ;
                   |         |           ___.--,
          _.._     |0) ~ (0) |    _.---'`__.-( (_.
   __.--'`_.. '.__.\    '--. \_.-' ,.--'`     `""`
  ( ,.--'`   ',__ /./;   ;, '.__.'`    __
"@
    $logoMid = @"
  _`) )  .---.__.' / |   |\   \__..--""  """--.,_
 `---' .'.''-._.-'`_./  /\ '.  \ _.-~~~````~~~-._`-.__.'
       | |  .' _.-' |  |  \  \  '.               `~---`
       \ \/ .'     \  \   '. '-._)
"@
    $logoBottom = @"
        \/ /        \  \    `=.__`~-.
        / /\         `) )    / / `"".`\
  , _.-'.'\ \        / /    ( (     / /
   `--~`   ) )    .-'.'      '.'.  | (
          (/`    ( (`          ) )  '-;
           `      '-;         (-'
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
