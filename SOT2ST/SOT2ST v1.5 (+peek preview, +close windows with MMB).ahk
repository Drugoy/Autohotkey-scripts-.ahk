; Script to work with Windows Taskbar
; 1. Hover taskbar
; 2. Scroll up/down to pre-select any window or pinned task.
; 3. Move cursor away from taskbar to select the pre-selected window/task.
 
#SingleInstance, Force
SetKeyDelay, 30
 
IsClassUnderMouse(class) {
   MouseGetPos, , , id
   WinGetClass, this_class, ahk_id %id%
   return this_class=class
}
 
#If IsClassUnderMouse("Shell_TrayWnd")
 
WheelUp::
   ControlSend, MSTaskListWClass1, % TrayKey("list") TrayKey("previous") TrayKey("thumbs"), ahk_class Shell_TrayWnd
   SetTimer, Check, 200
Return
 
WheelDown::
   ControlSend, MSTaskListWClass1, % TrayKey("list") TrayKey("next") TrayKey("thumbs"), ahk_class Shell_TrayWnd
   SetTimer, Check, 200
Return
 
MButton::
    WinActivate, ahk_class Shell_TrayWnd
    Click
    WinWaitNotActive, , , 0.5
    If !ErrorLevel
        WinClose, A
return
 
Check:
    If !IsClassUnderMouse("Shell_TrayWnd")
    {
        ControlSend, , {Enter}, ahk_class TaskListThumbnailWnd
        SetTimer, , Off
    }
return
 
TrayKey(action) {
    WinGetPos, X, Y, W, H, ahk_class Shell_TrayWnd
    if (action = "next")
        return (W > H) ? "{Right}" : "{Down}"
    if (action = "previous")
        return (W > H) ? "{Left}" : "{Up}"
    if (action = "thumbs")
        return (X = 0 && Y = 0) ? (W > H ? "{Down}" : "{Right}") : (X = 0) ? "{Up}" : "{Left}"
    if (action = "list")
        return (X = 0 && Y = 0) ? (W > H ? "{Up}" : "{Left}") : (X = 0) ? "{Down}" : "{Right}"
}