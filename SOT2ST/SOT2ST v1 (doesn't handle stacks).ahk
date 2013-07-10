; Script to work with Windows Taskbar
; 1. Hover taskbar
; 2. Scroll up/down to pre-select any window or pinned task.
; 3. Move cursor away from taskbar to select the pre-selected window/task.
; Works perfectly fine, except it doesn't work with stacks of windows.

#SingleInstance, Force

IsClassUnderMouse(class) {
   MouseGetPos, , , id
   WinGetClass, this_class, ahk_id %id%
   return this_class=class
}
 
#IF IsClassUnderMouse("Shell_TrayWnd")
 
WheelUp::
   WinGetPos,,, W, H, ahk_class Shell_TrayWnd
   ControlSend, MSTaskListWClass1, % W>H ? "{Left}":"{Up}", ahk_class Shell_TrayWnd
   SetTimer, Check, 50
   Return
 
WheelDown::
   WinGetPos,,, W, H, ahk_class Shell_TrayWnd
   ControlSend, MSTaskListWClass1, % W>H ? "{Right}":"{Down}", ahk_class Shell_TrayWnd
   SetTimer, Check, 50
   Return
 
#IF
 
Check:
If !IsClassUnderMouse("Shell_TrayWnd") {
ControlSend MSTaskListWClass1, {Lbutton}{Left}{Space}, ahk_class Shell_TrayWnd
SetTimer, Check, Off
} return