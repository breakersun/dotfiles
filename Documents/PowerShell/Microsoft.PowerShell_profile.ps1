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

# # sunlong prediction with listview
Set-PSReadLineOption -PredictionViewStyle ListView

# # sunlong for psfzf key-bindings
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
# Set-PsFzfOption -EnableFd
# $env:FZF_DEFAULT_COMMAND='fd -E *pycache*'
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

Import-Module -Name Terminal-Icons

# function preview { fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' }
