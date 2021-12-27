<#
.SYNOPSIS
    Setup the environment for the development
.DESCRIPTION
    Used for one-line PC setup. Includes package installs, profile download, etc.

    Perform the following steps:
    1. Install and configure Scoop (https://scoop.sh/)
    2. Install defined Scoop packages
    3. Install PSDepend for PowerShell modules management
    4. Download requiremetns.psd1 from the repo
    5. Install & import modules from step #4
    6. Initialize Chezmoi to download and keep dotfiles up to date
#>

[CmdletBinding()]
param (
    [System.Uri]$ModuleUri = 'https://raw.githubusercontent.com/breakersun/dotfiles/main/dot_config/requirments.psd1',
    [System.IO.FileInfo]$ModuleFilePath = "$env:HOMEDRIVE\$env:HOMEPATH\.config",

    [String[]]$Packages = @(
        'starship'
        'fzf'
    )
)


function Set-ScoopLocation {
    <#
    .LINK
        https://scoop-docs.vercel.app/docs/getting-started/Quick-Start.html#installing-scoop
    #>

    $SCOOP = Read-Host -Prompt 'Please enter Scoop install location(Enter to skip): '
    if (Test-Path -Path "$SCOOP") {
        Write-Host "Scoop install location at $SCOOP"
        [Environment]::SetEnvironmentVariable('SCOOP', "$SCOOP", 'Machine')
    } else {
        Write-Host "Scoop install location not found, skipped"
    }

    $SCOOP_GLOBAL = Read-Host -Prompt 'Please enter Scoop Apps install location(Enter to skip): '
    if (Test-Path -Path "$SCOOP_GLOBAL") {
        Write-Host "Scoop install location at $SCOOP_GLOBAL"
        [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', "$SCOOP_GLOBAL", 'Machine')
    } else {
        Write-Host "Scoop Apps install location not found, skipped"
    }
}

# Scoop setup
write-host 'Configuring Scoop...' -ForegroundColor Magenta

if (-not (Get-Command -Name scoop -ErrorAction SilentlyContinue)) {
    # allow to install by script
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
    # config scoop install location
    Set-ScoopLocation
    # install scoop
    Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
    # update environment
    refreshenv
}