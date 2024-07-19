# function to call TotalCommander
function tcmd {
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string] $FolderPath = $PWD,
        [Parameter(Mandatory=$false, Position=1)]
        [Alias('r')]
        [switch]$RightPane
    )

    if ($RightPane) {
        $pane = 'R'
    } else {
        $pane = 'L'
    }

    & "TotalCMD64.exe" /O /T /$pane="$FolderPath"
}

# sunlong add for starship
Invoke-Expression (&starship init powershell)
# sunlong add for auto completion
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# sunlong Function to relaunch as Admin:
function Relaunch-Admin { Start-Process -Verb RunAs (Get-Process -Id $PID).Path }

# sunlong for prediction with history
# Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadlineOption -HistoryNoDuplicates

# # sunlong prediction with listview
Set-PSReadLineOption -PredictionViewStyle ListView

# enable vim mode on pwsh
# Set-PsReadLineOption -EditMode Vi
# sunlong for psfzf key-bindings
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Import-Module -Name Terminal-Icons

# enable Vim mode indicator
$OnViModeChange = [scriptblock]{
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewLine "`e[2 q"
    }
    else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[5 q"
    }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $OnViModeChange
# function preview { fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' }
#
# ~/.config/powershell/Microsoft.PowerShell_profile.ps1
$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression
