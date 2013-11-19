;http://www.autohotkey.com/board/topic/30399-wintraymin-to-trayicon/page-4
;----------------------------------------------------------
; WinTraymin.ahk
; by Sean
;----------------------------------------------------------
;----------------------------------------------------------
; Adding a trayminned trayicon of hWnd:	WinTraymin(hWnd,0), where 0 can be omitted.
; Removing all trayminned trayicons:	WinTraymin(0,-1).
; Other values than 0 & -1 are reserved for internal use.
;----------------------------------------------------------

; #NoTrayIcon
#SingleInstance, Force
TrayminOpen:
SetWinDelay, 0
SetFormat, Integer, D
CoordMode, Mouse, Screen
DetectHiddenWindows On
hAHK := WinExist("ahk_class AutoHotkey ahk_pid " . DllCall("GetCurrentProcessId"))
ShellHook := DllCall("RegisterWindowMessage", "str", "SHELLHOOK")
DllCall("RegisterShellHookWindow", "Uint", hAHK)
OnExit, TrayminClose
Return
TrayminClose:
DllCall("DeregisterShellHookWindow", "Uint", hAHK)
WinTraymin(0, -1)
OnExit
ExitApp

RButton Up::
If	h := WM_NCHITTEST()
	WinTraymin(h)
Else
	Click, % SubStr(A_ThisHotkey, 1, 1)	; for hotkey: LButton/MButton/RButton
Return

WM_NCHITTEST()
{
	MouseGetPos, x, y, z
	SendMessage, 0x84, 0, (x & 0xFFFF) | (y & 0xFFFF) << 16,, ahk_id %z%
	Return	ErrorLevel = 8 ? z : ""
}

WM_SHELLHOOKMESSAGE(wParam, lParam, nMsg)
{
	Critical
	If nMsg = 1028
	{
		If wParam = 1028
			Return
		Else If (lParam = 0x201 || lParam = 0x205 || lParam = 0x207)
			WinTraymin(wParam, 3)
	}
	Else If (wParam = 1 || wParam = 2)
		WinTraymin(lParam, wParam)
	Return 0
}

WinTraymin(hWnd = "", nFlags = "")
{
	Local h, ni, fi, uid, pid, hProc, sClass
	Static nMsg, nIcons :=0
	nMsg ? "" : OnMessage(nMsg := 1028, "WM_SHELLHOOKMESSAGE")
	NumPut(hAHK, NumPut(VarSetCapacity(ni, 444, 0), ni))
	If !nFlags
	{
		If !((hWnd += 0) || hWnd := DllCall("GetForegroundWindow")) || ((h := DllCall("GetWindow", "Uint", hWnd, "Uint", 4)) && DllCall("IsWindowVisible", "Uint", h) && !hWnd := h) || !(VarSetCapacity(sClass, 15), DllCall("GetClassNameA", "Uint", hWnd, "str", sClass, "Uint", VarSetCapacity(sClass) + 1)) || sClass == "Shell_TrayWnd" || sClass == "Progman"
		Return
		OnMessage(ShellHook, "")
		WinMinimize, ahk_id %hWnd%
		WinHide, ahk_id %hWnd%
		Sleep, 100
		OnMessage(ShellHook, "WM_SHELLHOOKMESSAGE")
		uID := uID_%hWnd%, uID ? "" : (uID_%hWnd% := uID := ++nIcons = nMsg ? ++nIcons : nIcons)
		If !hIcon_%uID%
		{
			If !hIcon_%uID% := DllCall("user32\SendMessage", "Uint", hWnd, "Uint", 127, "Uint", 2, "Uint", 0, "Uint")
				If !hIcon_%uID% := DllCall("user32\SendMessage", "Uint", hWnd, "Uint", 127, "Uint", 0, "Uint", 0, "Uint")
					hIcon_%uID% := DllCall("user32\SendMessage", "Uint", hWnd, "Uint", 127, "Uint", 1, "Uint", 0, "Uint")
			VarSetCapacity(fi, 352, 0), DllCall("GetWindowThreadProcessId", "Uint", hWnd, "UintP", pid), DllCall("psapi\GetModuleFileNameExA", "Uint", hProc := DllCall("kernel32\OpenProcess", "Uint", 0x410, "int", 0, "Uint", pid), "Uint", 0, "Uint", &fi + 12, "Uint", 260), DllCall("kernel32\CloseHandle", "Uint", hProc)
		}
		hIcon_%uID% ? "" : (DllCall("shell32\SHGetFileInfoA", "Uint", &fi + 12,"Uint", 0, "Uint", &fi, "Uint", 352, "Uint", 0x101), hIcon_%uID% := NumGet(fi))
		DllCall("GetWindowTextA", "Uint", hWnd, "Uint", NumPut(hIcon_%uID%, NumPut(nMsg, NumPut(1|2|4, NumPut(uID, ni, 8)))),  "int", 64)
		Return hWnd_%uID% := DllCall("shell32\Shell_NotifyIconA", "Uint", hWnd_%uID% ? 1 : 0, "Uint", &ni) ? hWnd : DllCall("ShowWindow", "Uint", hWnd, "int", 5) * 0
	}
	Else If nFlags > 0
	{
		If (nFlags = 3 && uID := hWnd)
			If WinExist("ahk_id " . hWnd := hWnd_%uID%)
			{
				WinShow, ahk_id %hWnd%
				WinRestore, ahk_id %hWnd%
			}
			Else
				nFlags := 2
		Else
			uID := uID_%hWnd%
		Return uID ? (hWnd_%uID% ? (DllCall("shell32\Shell_NotifyIconA", "Uint", 2, "Uint", NumPut(uID, ni, 8) -12), hWnd_%uID% := "") : "", nFlags == 2 && hIcon_%uID% ? (DllCall("DestroyIcon", "Uint", hIcon_%uID%), hIcon_%uID% := "") : "") : ""
	}
	Else
		Loop, % nIcons
			hWnd_%A_Index% ? (DllCall("shell32\Shell_NotifyIconA", "Uint", 2, "Uint", NumPut(A_Index, ni, 8) - 12), DllCall("ShowWindow", "Uint", hWnd_%A_Index%, "int", 5), hWnd_%A_Index% := "") : "", hIcon_%A_Index% ? (DllCall("DestroyIcon", "Uint", hIcon_%A_Index%), hIcon_%A_Index% := "") : ""
}