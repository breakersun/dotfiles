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
    [System.Uri] $ModuleUri =
)
