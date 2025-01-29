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
        'terminal-icons'
        'psreadline'
        'carapace-bin'
        'zoxide'
        'psfzf'
        'gcc'
        'vcredist2019'
        'bat'
        'chezmoi'
        'fd'
        'fzf'
        'neovim'
        'neovide'
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
        'vscode'
        'lsd'
        'keepass'
        'keepass-plugin-keeanywhere'
        'keepass-plugin-keeagent'
        'keepass-plugin-keepasshttp' 
        'nodejs'
        'global'
        'bincalc'
        'glow'
        'simplyserial'
        'tokei'
        'diff-pdf'
        'adb'
    )
)


function Test-ScoopApp {
    param (
        [Parameter(Mandatory)]
        [String]$App
    )
    Process {
        $appInstalled = Test-Path -Path "~\scoop\apps"
        return $appInstalled
    }
}

# check current powershell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
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
    # install scoop
    Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
    # Add the Scoop path to Windows Defender exclusions
    $scoopPath = [System.IO.Path]::Combine($env:USERPROFILE, 'scoop')
    Add-MpPreference -ExclusionPath $scoopPath
}

scoop bucket add extras
scoop bucket add twpayne https://github.com/twpayne/scoop-bucket
scoop bucket add nerd-fonts
scoop bucket add my-utils https://github.com/breakersun/utils-bucket.git

foreach ($app in $Apps) {
    scoop install $app
}

winget install --id=Git.Git  -e
winget install "openssh beta"
winget install Tortoisegit.Tortoisegit
#winget install Snipaste
winget install --exact --id MartiCliment.UniGetUI --source winget
winget install --id=Tencent.WeType  -e
# for sshfs : 'net use X: \\sshfs\sunlong@10.84.130.211; net use X: /delete'
winget install WinFsp.WinFsp 
winget install SSHFS-Win.SSHFS-Win
# Initialize Chezmoi
chezmoi init --apply breakersun

$hotkeys_dir='~\.local\share\autohotkey_script'
git clone 'https://github.com/breakersun/autohotkey_script' $hotkeys_dir 
$StartUp="$Env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$Startup = $Startup -replace ' ', '` '
gsudo New-Item -ItemType SymbolicLink -Path $StartUp -Name "autohot.lnk" -Value "$hotkeys_dir\startup.ahk"
$viatc_dir='~\.local\share\viatc'
git clone 'https://github.com/breakersun/ViATc-English.git' $viatc_dir --depth=1

# pull neovim configs
git -C $env:LOCALAPPDATA clone --branch lazy https://github.com/breakersun/nvim.git

#install picgo command line tool
npm install picgo -g
Start-Process "https://www.notion.so/hitme/ba9d263f7f6b40f4a317eb9c6719e508"
write-host 'Please prepare your Aliyun OSS Keys' -ForegroundColor Magenta
picgo set uploader

# activate
Start-Process "https://github.com/TGSAN/CMWTAT_Digital_Edition/releases"

Start-Process "https://www.listary.com/download-completion?version=stable"

Start-Process "http://iyoung.ysepan.com/?xzpd=1"
