
$env:PYTHONIOENCODING = "UTF-8"


Import-Module PSFzf
Import-Module -Name Terminal-Icons

Set-PSReadLineOption -PredictionViewStyle ListView
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Invoke-Expression (&starship init powershell)

# Caraspace
$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

Invoke-Expression (&sfsu hook)

# enable vim mode on pwsh
# Set-PsReadLineOption -EditMode Emacs
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

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadlineOption -HistoryNoDuplicates
Set-PSReadLineOption -ShowToolTips

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
Invoke-Expression (& { (zoxide init powershell | Out-String) })

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

    & "$HOME\AppData\Local\TotalCMD64\TotalCMD64.exe" /O /T /$pane="$FolderPath"
}
