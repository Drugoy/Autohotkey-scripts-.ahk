#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force

Global GUIs := []
, EVENT_SYSTEM_MOVESIZESTART := 0xA
, EVENT_SYSTEM_MOVESIZEEND := 0xB
EVENT_OBJECT_DESTROY := 0x8001
WS_EX_TRANSPARENT := 0x20

SetWinDelay, 0

; отслеживаем передвижение окон
HWINEVENTHOOK1 := SetWinEventHook(EVENT_SYSTEM_MOVESIZESTART, EVENT_SYSTEM_MOVESIZEEND, 0, RegisterCallback("WatchingMoveWindow", "F"), 0, 0, 0)
; отслеживаем закрытие окон
HWINEVENTHOOK2 := SetWinEventHook(EVENT_OBJECT_DESTROY, EVENT_OBJECT_DESTROY, 0, RegisterCallback("WatchingDestroyWindow", "F"), 0, 0, 0)
OnExit, Exit
Return

Exit:
	DllCall("UnhookWinEvent", Ptr, HWINEVENTHOOK1)
	DllCall("UnhookWinEvent", Ptr, HWINEVENTHOOK2)
; снимаем стиль WS_EX_TOPMOST со всех окон, где он был установлен
	For k, v in GUIs
		WinSet, AlwaysOnTop, Off, % "ahk_id" v.Parent
	GUIs := ""
	ExitApp
   
!1::
	WinGet, ID,, A
	For k, v in GUIs
		If (v.Parent = ID)
			Return

	WinSet, AlwaysOnTop, On, A
	WinGetPos, X, Y,,, A
; устанавливая расширенный стиль WS_EX_TRANSPARENT делаем окно прозрачным для мыши
; опцией Owner%ID% делаем GUI принадлежащим активному окну, тогда GUI всегда будет поверх окна-хозяина
	Gui, New, +E%WS_EX_TRANSPARENT% -Caption +LastFound +AlwaysOnTop +hwndhGui +Owner%ID%
	WinSet, Transparent, 200  ; прозрачность окна-метки, от 0 до 255
	Gui, Color, Red
	Gui, Show, % "NA w16 h16 x" X+8 " y" Y+7
	GUIs.Insert({Parent: ID, Owned: hGui})
	Return
   
!2::
	WinGet, ID,, A
	AlwaysOnTopOff(ID)
	Return
   
Esc::ExitApp

WatchingMoveWindow(hWinEventHook, event, hwnd)
{
	Static MonitoredWindowID, OwnedWindowID
	If (event = EVENT_SYSTEM_MOVESIZESTART)
	{
		For k, v in GUIs
			if (v.Parent = hwnd)
			{
				MonitoredWindowID := hwnd
				OwnedWindowID := v.Owned
				SetTimer, WatchingMove, 10
				Break
			}
	}
	Else If (event = EVENT_SYSTEM_MOVESIZEEND)
		SetTimer, WatchingMove, Off
	Return
   
WatchingMove:
	WinGetPos, X, Y,,, ahk_id %MonitoredWindowID%
	WinMove, ahk_id %OwnedWindowID%,, X+8, Y+7
	Return
}

WatchingDestroyWindow(hWinEventHook, event, hwnd)
{
	AlwaysOnTopOff(hwnd)
}

AlwaysOnTopOff(hwnd)
{
	For k, v in GUIs
		If (v.Parent = hwnd)
		{
			WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
			Gui, % v.Owned ":Destroy"
			GUIs.Remove(k)
			Break
		}
}

SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags)
{
	Return DllCall("SetWinEventHook", UInt, eventMin, UInt, eventMax
									, Ptr, hmodWinEventProc, Ptr, lpfnWinEventProc
									, UInt, idProcess, UInt, idThread
									, UInt, dwFlags, Ptr)
}