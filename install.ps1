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

    [String[]]$Apps = @(
        'vcredist2019'
        'bat'
        'chezmoi'
        'fd'
        'fzf'
        'neovim'
        'ripgrep'
        'starship'
        'windows-terminal'
    )
)


function Set-ScoopLocation {
    <#
    .LINK
        https://scoop-docs.vercel.app/docs/getting-started/Quick-Start.html#installing-scoop
    #>

    $SCOOP = Read-Host -Prompt 'Please enter Scoop install location(Enter to skip) '
    if (Test-Path -Path "$SCOOP") {
        Write-Host "Scoop install location at $SCOOP"
        $env:SCOOP=$SCOOP
        [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
    } else {
        $SCOOP = 'd:\scoop'
        $env:SCOOP=$SCOOP
        New-Item -Path "d:\" -Name "scoop" -ItemType "directory"
        Write-Host "Scoop Default Install to $SCOOP"
    }

    $SCOOP_GLOBAL = Read-Host -Prompt 'Please enter Scoop Apps install location(Enter to skip) '
    if (Test-Path -Path "$SCOOP_GLOBAL") {
        Write-Host "Scoop install location at $SCOOP_GLOBAL"
        $env:SCOOP_GLOBAL=$SCOOP_GLOBAL
        [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
    } else {
        $SCOOP_GLOBAL = 'd:\scoop_apps'
        $env:SCOOP_GLOBAL=$SCOOP_GLOBAL
        New-Item -Path "d:\" -Name "scoop_apps" -ItemType "directory"
        Write-Host "Scoop Apps Default Install to $SCOOP_GLOBAL"
    }
}

function Test-ScoopApp {
    param (
        [Parameter(Mandatory)]
        [String]$App
    )
    Process {
        if (Test-Path -Path $env:SCOOP) {
            $appInstalled = Test-Path -Path "$env:SCOOP\apps\$App"
        } else {
            Write-Host "Can't find a chocolatey install directory..."
        }

        return $appInstalled
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

scoop bucket add extras
# bucket for chezmoi
scoop bucket add twpayne https://github.com/twpayne/scoop-bucket

foreach ($app in $Apps) {
    if (-not (Test-ScoopApp($app))) {
        scoop install $app
    }
}

################################################################################
# Add commonly used modules (this must be done first)                          #
################################################################################
Install-Module PSDepend -Scope CurrentUser
Import-Module PSDepend

Write-Host 'Downloading PowerShell module dependency list from GitHub...' -ForegroundColor Magenta
New-Item -ItemType Directory $ModuleFilePath -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $ModuleUri -UseBasicParsing -OutFile "$ModuleFilePath\requirements.psd1"

Write-Host 'Installing PowerShell modules...' -ForegroundColor Magenta
Invoke-PSDepend -Path "$ModuleFilePath\requirements.psd1" -Force


# Install Git[Git.Git] using winget
winget install -e --id Git.Git

# Initialize Chezmoi
chezmoi init --apply breakersun
chezmoi diff
