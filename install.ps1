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
    [System.Uri]$ModuleUri = 'https://raw.githubusercontent.com/breakersun/dotfiles/main/dot_config/requirements.psd1',
    [System.IO.FileInfo]$ModuleFilePath = "$env:HOMEDRIVE\$env:HOMEPATH\.config",

    [String[]]$Apps = @(
        'git'
        'vcredist2019'
        'bat'
        'chezmoi'
        'fd'
        'fzf'
        'neovim'
        'ripgrep'
        'starship'
        'windows-terminal'
        'sumatrapdf'
        '7zip'
        'beyondcompare'
        'listary'
        'obsidian'
        'openvpn'
        'mobaxterm'
        'autohotkey'
        'msys2'
        'gitversion'
        'notepadplusplus'
        'gsudo'
        'lazygit'
        'FiraCode-NF'
        'ditto'
    )
)


function Set-ScoopLocation {
    <#
    .LINK
        https://scoop-docs.vercel.app/docs/getting-started/Quick-Start.html#installing-scoop
    #>

    $env:SCOOP='d:\scoop'
    [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
    Write-Host "Scoop install location at $env:SCOOP"

    $env:SCOOP_GLOBAL='d:\scoop_apps'
    [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
    Write-Host "Scoop install location at $env:SCOOP_GLOBAL"

    $env:Path+=';D:\scoop\apps\git\current\usr\bin'
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine')
    Write-Host "Git-Bash at D:\scoop\apps\git\current\usr\bin"
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

# check current powershell version
if ($$PSVersionTable.PSVersion.Major -lt 7) {
    Start-Process "https://github.com/PowerShell/powershell/releases"
    Start-Process "https://github.com/microsoft/winget-cli/releases"
    write-host 'Please install latest Powershell, such as winget install powershell' -ForegroundColor Magenta
    write-host 'Abort' -ForegroundColor Magenta
    break
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
scoop bucket add nerd-fonts

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
# bettern install git with scoop
# winget install -e --id Git.Git

# Initialize Chezmoi
chezmoi init --apply breakersun

# install vim-plug
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
    ni "$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])/nvim-data/site/autoload/plug.vim" -Force

# https://docs.microsoft.com/en-us/sysinternals/downloads/junction
# redirect chrome locations:
# junction64.exe ~\AppData\Local\Google\Chrome D:\Chrome

# activate
# https://github.com/TGSAN/CMWTAT_Digital_Edition
$hotkeys_dir=$HOME\.local\share\autohotkey_script'
git clone 'https://github.com/breakersun/autohotkey_script' $hotkeys_dir 
$StartUp="$Env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
New-Item -ItemType SymbolicLink -Path $StartUp -Name "autohot.lnk" -Value "$hotkeys_dir\startup.ahk"
