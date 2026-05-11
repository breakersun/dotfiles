#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off  ; Disables the warnings if you find them too intrusive

; --- Auto-Elevate to Admin ---
; Required for the script to interact with elevated windows like Keil or SES
if !A_IsAdmin
    Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'

#Hotstring * ?

::;date::
{
    CurrentDateTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    SendInput(CurrentDateTime)
}

::;ip::
{
  addresses := SysGetIPAddresses()
  ipString := ""
  for index, addr in addresses {
      ipString .= addr . (index == addresses.Length ? "" : "`n")
  }
  Send(ipString || "No IP Address Found")
}

::;br::
{
    SendInput("Best Regards.`nLeo Sun")
}

#Hotstring *0 ?0 ; Reset defaults for anything below this line

; --- Context Sensitive Hotkeys ---

; SEGGER Embedded Studio & Foxit Reader
#HotIf WinActive("ahk_exe emStudio.exe") or WinActive("ahk_exe FoxitPDFReader.exe")
XButton1::Send "!{Left}"
XButton2::Send "!{Right}"
#HotIf

; STV Debugger
#HotIf WinActive("ahk_exe stvdebug.exe")
XButton1::Send "^+{Tab}"
XButton2::Send "^{Tab}"
#HotIf

; Keil uVision
#HotIf WinActive("ahk_exe UV4.exe")
XButton1::Send "^{-}"
XButton2::Send "^+{-}"
^LButton::Send "{F12}"
#HotIf

SetTimer(ForceEdgeContentFocus, 200)
ForceEdgeContentFocus() {
    ; 检查当前激活窗口是否为 Edge
    if WinActive("ahk_exe msedge.exe") {
        try {
            ; 获取当前焦点的控件类名
            currentFocus := ControlGetFocus("A")
            
            ; 如果焦点不在网页渲染区 (Chrome_RenderWidgetHostHWND1)
            ; 且焦点目前在工具栏或地址栏上（通常类名为 ToolbarWindow32 或中间控件）
            if (currentFocus != "Chrome_RenderWidgetHostHWND1") {
                ; 强行将焦点设置到网页渲染区域
                ControlFocus("Chrome_RenderWidgetHostHWND1", "A")
            }
        }
    }
}
