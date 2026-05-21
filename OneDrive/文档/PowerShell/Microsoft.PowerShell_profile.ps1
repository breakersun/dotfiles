$env:PYTHONIOENCODING = "UTF-8"

Import-Module PSFzf
Import-Module posh-git
Import-Module -Name Terminal-Icons

Set-PSReadLineOption -PredictionViewStyle ListView
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -EnableAliasFuzzyEdit -EnableAliasFuzzyKillProcess
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }

Invoke-Expression (&starship init powershell)

# Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -TabExpansion

Invoke-Expression (&sfsu hook)

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

function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe @args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}
