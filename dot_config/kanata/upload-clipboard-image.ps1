# upload-clipboard-image.ps1
# Triggered by kanata hotkey: validates clipboard image, uploads via picgo CLI,
# copies returned URL back to clipboard, and shows a Windows Toast notification.

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Notification {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Message
    )

    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $escapedTitle = [System.Security.SecurityElement]::Escape($Title)
        $escapedMsg = [System.Security.SecurityElement]::Escape($Message)
        $xml = "<toast><visual><binding template='ToastGeneric'><text>$escapedTitle</text><text>$escapedMsg</text></binding></visual></toast>"

        $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
        $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        return
    } catch {
        # Fallback to WinForms NotifyIcon balloon tip if WinRT Toast fails
    }

    try {
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        $notifyIcon.BalloonTipTitle = $Title
        $notifyIcon.BalloonTipText = $Message
        $notifyIcon.Visible = $true
        $notifyIcon.ShowBalloonTip(4000)
        Start-Sleep -Milliseconds 500
        $notifyIcon.Dispose()
    } catch {
        # Last-resort silent fail if no desktop session is available
    }
}

function Invoke-WithClipboardRetry {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)

    for ($i = 0; $i -lt 4; $i++) {
        try {
            return (& $Action)
        } catch {
            if ($i -eq 3) { throw }
            Start-Sleep -Milliseconds 60
        }
    }
}

function Save-ClipboardImageToTemp {
    param([Parameter(Mandatory = $true)][string]$OutPath)

    $wpfImg = Invoke-WithClipboardRetry { [Windows.Clipboard]::GetImage() }
    if ($null -ne $wpfImg) {
        try {
            $fcb = New-Object Windows.Media.Imaging.FormatConvertedBitmap($wpfImg, [Windows.Media.PixelFormats]::Bgra32, $null, 0)
            $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
            $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($fcb)) | Out-Null
            $stream = [System.IO.File]::Open($OutPath, [System.IO.FileMode]::Create)
            try {
                $encoder.Save($stream)
            } finally {
                $stream.Dispose()
            }
            if ((Test-Path -LiteralPath $OutPath) -and ((Get-Item -LiteralPath $OutPath).Length -gt 0)) {
                return $true
            }
        } catch {
            # Fallback to WinForms Clipboard below
        }
    }

    $wfImg = Invoke-WithClipboardRetry { [System.Windows.Forms.Clipboard]::GetImage() }
    if ($null -ne $wfImg) {
        try {
            $wfImg.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
            if ((Test-Path -LiteralPath $OutPath) -and ((Get-Item -LiteralPath $OutPath).Length -gt 0)) {
                return $true
            }
        } finally {
            $wfImg.Dispose()
        }
    }

    return $false
}

function Resolve-PicGoRunner {
    $picgoEntryCandidates = @()
    $picgoCmd = Get-Command picgo -ErrorAction SilentlyContinue
    if ($null -ne $picgoCmd -and $picgoCmd.Source) {
        $binDir = Split-Path -Path $picgoCmd.Source -Parent
        $picgoEntryCandidates += (Join-Path $binDir "node_modules\picgo\bin\picgo")
    }
    $picgoEntryCandidates += (Join-Path $env:USERPROFILE "scoop\apps\nodejs\current\bin\node_modules\picgo\bin\picgo")
    $picgoEntryCandidates += (Join-Path $env:USERPROFILE "scoop\persist\nodejs\bin\node_modules\picgo\bin\picgo")

    $picgoEntry = $picgoEntryCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

    $nodeExe = $null
    $nodeCmd = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($null -ne $nodeCmd -and $nodeCmd.Source) {
        $nodeExe = $nodeCmd.Source
    } else {
        $nodeCandidates = @(
            (Join-Path $env:USERPROFILE "scoop\apps\nodejs\current\node.exe"),
            (Join-Path $env:USERPROFILE "scoop\apps\nodejs-lts\current\node.exe")
        )
        $nodeExe = $nodeCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    }

    if ($nodeExe -and $picgoEntry) {
        return @{
            FileName = $nodeExe
            BaseArgs = @($picgoEntry)
        }
    }

    if ($null -ne $picgoCmd -and $picgoCmd.Source) {
        return @{
            FileName = "cmd.exe"
            BaseArgs = @("/c", $picgoCmd.Source)
        }
    }

    return $null
}

function Format-ProcessArguments {
    param([string[]]$ArgList)
    return ($ArgList | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }) -join " "
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Local\KanataPicGoClipboardUpload", [ref]$createdNew)
if (-not $createdNew) {
    Show-Notification -Title "PicGo 正在上传" -Message "上一张图片仍在上传中，请稍候再试。"
    $mutex.Dispose()
    exit 0
}

$tempFileToDelete = $null

try {
    $imageExtensions = @(".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".svg", ".ico", ".tif", ".tiff", ".avif")
    $uploadPaths = @()

    $hasFileDrop = Invoke-WithClipboardRetry { [Windows.Clipboard]::ContainsFileDropList() }
    $hasImage = Invoke-WithClipboardRetry {
        [Windows.Clipboard]::ContainsImage() -or [System.Windows.Forms.Clipboard]::ContainsImage()
    }

    if ($hasFileDrop) {
        $dropList = Invoke-WithClipboardRetry { [Windows.Clipboard]::GetFileDropList() }
        $validImageFiles = @()
        foreach ($item in $dropList) {
            if ([System.IO.File]::Exists($item)) {
                $ext = [System.IO.Path]::GetExtension($item).ToLowerInvariant()
                if ($imageExtensions -contains $ext) {
                    $validImageFiles += $item
                }
            }
        }

        if ($validImageFiles.Count -gt 0) {
            $uploadPaths = $validImageFiles
        } elseif (-not $hasImage) {
            Show-Notification -Title "PicGo 上传取消" -Message "剪贴板内容非图片（当前为非图片文件或文件夹）。"
            exit 1
        }
    }

    if ($uploadPaths.Count -eq 0) {
        if ($hasImage) {
            $tempPath = Join-Path $env:TEMP ("picgo-clip-" + [DateTime]::Now.ToString("yyyyMMddHHmmssfff") + ".png")
            if (-not (Save-ClipboardImageToTemp -OutPath $tempPath)) {
                Show-Notification -Title "PicGo 上传失败" -Message "无法读取剪贴板中的图片数据。"
                exit 1
            }
            $tempFileToDelete = $tempPath
            $uploadPaths = @($tempPath)
        } else {
            $hasText = Invoke-WithClipboardRetry {
                [Windows.Clipboard]::ContainsText() -or [System.Windows.Forms.Clipboard]::ContainsText()
            }
            if ($hasText) {
                Show-Notification -Title "PicGo 上传取消" -Message "剪贴板内容非图片（当前为文本内容）。"
            } else {
                Show-Notification -Title "PicGo 上传取消" -Message "剪贴板中没有图片。"
            }
            exit 1
        }
    }

    $runner = Resolve-PicGoRunner
    if ($null -eq $runner) {
        Show-Notification -Title "PicGo 上传失败" -Message "未找到 picgo CLI 或 Node.js，请检查安装和 PATH。"
        exit 1
    }

    $allArgs = @() + $runner.BaseArgs + @("upload") + $uploadPaths
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $runner.FileName
    $psi.Arguments = Format-ProcessArguments -ArgList $allArgs
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()

    $errTask = $proc.StandardError.ReadToEndAsync()
    $stdout = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    $stderr = $errTask.GetAwaiter().GetResult()

    $combined = ($stdout + "`n" + $stderr) -replace '\x1B\[[0-9;]*[A-Za-z]', ''
    $lines = $combined -split "\r?\n"

    $urls = @()
    $inSuccessBlock = $false
    $errorLines = @()
    $inErrorBlock = $false

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match "^\[PicGo SUCCESS\]:") {
            $inSuccessBlock = $true
            $inErrorBlock = $false
            $afterPrefix = ($trimmed -replace "^\[PicGo SUCCESS\]:\s*", "").Trim()
            if ($afterPrefix -match "^https?://\S+") {
                $urls += $afterPrefix
            }
            continue
        }
        if ($trimmed -match "^\[PicGo ERROR\]:") {
            $inSuccessBlock = $false
            $inErrorBlock = $true
            $afterPrefix = ($trimmed -replace "^\[PicGo ERROR\]:\s*", "").Trim()
            if ($afterPrefix) { $errorLines += $afterPrefix }
            continue
        }
        if ($trimmed -match "^\[PicGo (INFO|WARN)\]:") {
            $inSuccessBlock = $false
            $inErrorBlock = $false
            continue
        }

        if ($inSuccessBlock -and $trimmed) {
            if ($trimmed -match "^https?://\S+") {
                $urls += $trimmed
            }
        } elseif ($inErrorBlock -and $trimmed -and $trimmed -notmatch "^at\s+") {
            $errorLines += $trimmed
        }
    }

    if ($urls.Count -gt 0) {
        $resultText = $urls -join [Environment]::NewLine
        Invoke-WithClipboardRetry { [System.Windows.Forms.Clipboard]::SetText($resultText) }
        Show-Notification -Title "PicGo 上传成功" -Message ("已复制 URL 到剪贴板：`n" + $resultText)
        exit 0
    }

    $errMsg = ($errorLines -join " ").Trim()
    if (-not $errMsg) {
        $lastLine = ($lines | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 1)
        if ($lastLine) {
            $errMsg = $lastLine.Trim()
        } else {
            $errMsg = "未知错误（退出码: $($proc.ExitCode)）"
        }
    }
    if ($errMsg.Length -gt 180) {
        $errMsg = $errMsg.Substring(0, 180) + "..."
    }
    Show-Notification -Title "PicGo 上传失败" -Message $errMsg
    exit 1
} catch {
    $msg = $_.Exception.Message
    if (-not $msg) { $msg = "发生未预期的异常。" }
    Show-Notification -Title "PicGo 上传异常" -Message $msg
    exit 1
} finally {
    if ($tempFileToDelete -and (Test-Path -LiteralPath $tempFileToDelete)) {
        Remove-Item -LiteralPath $tempFileToDelete -Force -ErrorAction SilentlyContinue
    }
    try { $mutex.ReleaseMutex() } catch {}
    $mutex.Dispose()
}
