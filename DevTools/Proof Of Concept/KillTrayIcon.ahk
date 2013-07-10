#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent
#SingleInstance Force
DetectHiddenWindows On
SetTitleMatchMode 2
Return

#z::
hwnd := WinExist("MouseExtras.ahk ahk_class AutoHotkey")
KillTrayIcon(hwnd)
Return

KillTrayIcon(scriptHwnd) {
	static NIM_DELETE := 2, AHK_NOTIFYICON := 1028
	VarSetCapacity(nic, size := 936+4*A_PtrSize)
	NumPut(size, nic, 0, "uint")
	NumPut(scriptHwnd, nic, A_PtrSize)
	NumPut(AHK_NOTIFYICON, nic, A_PtrSize*2, "uint")
	return DllCall("Shell32\Shell_NotifyIcon", "uint", NIM_DELETE, "ptr", &nic)
}

#a::
WM_TASKBARCREATED := DllCall("RegisterWindowMessage", "str", "TaskbarCreated")
PostMessage WM_TASKBARCREATED,,,, ahk_id %hwnd%
Return