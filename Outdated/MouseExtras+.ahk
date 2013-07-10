#SingleInstance, Force
#NoEnv			; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input	; Recommended for new scripts due to its superior speed and reliability.
CoordMode, Mouse, Screen

; Scroll inactive windows without activating them.
; Tab Wheel Scroll for Notepad++, Miranda IM (TabSRMM), AkelPad and Internet Explorer.
; Can't do the same for Google Chrome and Mozilla Firefox.

WheelUp::
MouseGetPos, m_x, m_y, id, control, 1
hw_m_target := DllCall("WindowFromPoint", "int", m_x, "int", m_y)
WinGetClass, class, ahk_id %id%
If (control == "SysTabControl325") && (class == "Notepad++")	; Notepad++: ahk_class Notepad++	tab-bar classNN: SysTabControl325	classNN of the listener-window: Scintilla1
{
	ControlGet, properTargetWin, Hwnd, , Scintilla1, ahk_id %id%
	PostMessage 0x319, 0, 0x10000, , ahk_id %properTargetWin%
}
Else If (control == "TSTabCtrlClass1")	; Miranda IM, TabSRMM window: ahk_class #32770	tab-bar classNN: TSTabCtrlClass1	classNN of the listener-window: RichEdit20W1
{
	ControlGet, properTargetWin, Hwnd, , RichEdit20W1, ahk_id %id%
	PostMessage 0x319, 0, 0x10000, , ahk_id %properTargetWin%
}
Else If ((control == "SysTabControl321") && (class == "AkelPad4")) || ((control == "DirectUIHWND2") && (class == "IEFrame"))
	ControlSend, , {Ctrl Down}{Shift Down}{Tab}{Shift Up}{Ctrl Up}, ahk_id %id%
PostMessage, 0x20A, 120 << 16, ( m_y << 16 )|m_x, , ahk_id %hw_m_target%
Gosub, CleanVars
Return

WheelDown::
MouseGetPos, m_x, m_y, id, control, 1
hw_m_target := DllCall( "WindowFromPoint", "int", m_x, "int", m_y )
WinGetClass, class, ahk_id %id%
If (control == "SysTabControl325") && (class == "Notepad++")
{
	ControlGet, properTargetWin, Hwnd, , Scintilla1, ahk_id %id%
	PostMessage 0x319, 0, 0x20000, , ahk_id %properTargetWin%
}
Else If (control == "TSTabCtrlClass1")
{
	ControlGet, properTargetWin, Hwnd, , RichEdit20W1, ahk_id %id%
	PostMessage 0x319, 0, 0x20000, , ahk_id %properTargetWin%
}
Else If ((control == "SysTabControl321") && (class == "AkelPad4")) || ((control == "DirectUIHWND2") && (class == "IEFrame"))
	ControlSend, , {Ctrl Down}{Tab}{Ctrl Up}, ahk_id %id%
PostMessage, 0x20A, -120 << 16, ( m_y << 16 )|m_x, , ahk_id %hw_m_target%
Gosub, CleanVars
Return


; Global Hotkeys

WheelLeft::Send {Browser_Back}
WheelRight::Send {Browser_Forward}
XButton1::Send {Ctrl Down}{vk0x43sc0x2e}{Ctrl Up}
XButton2::Send {Ctrl Down}{vk0x56sc0x2f}{Ctrl Up}


; Drag windows via XButton2 & LButton

XButton2 & LButton::KDE_WinMove("LButton")
KDE_WinMove(sButton)
{
	SetWinDelay, 0
	CoordMode, Mouse
	MouseGetPos, x1, y1, id
	WinExist("ahk_id" . id)
	WinGetClass, winClass
	WinGet, maximized, MinMax
	If (!GetKeyState(sButton, "P")) || (winClass == "WorkerW") || (maximized)
		Exit
	WinGetPos, winX1, winY1
	While GetKeyState(sButton, "P")
	{
		MouseGetPos, x2, y2
		x2 -= x1, y2 -= y1, winX2 := winX1 + x2, winY2 := winY1 + y2
		WinMove,,, winX2, winY2
		Sleep 15
	}
	Gosub, CleanVars
}


; Control transparency of a window under cursor via XButton2 & Wheel(Down/Up)

XButton2 & WheelUp::
XButton2 & WheelDown::
Gosub, GetUnderCursor
If !(curropacity)
	currOpacity := 255
currOpacity := (A_ThisHotkey = "XButton2 & WheelUp") ? currOpacity + 10 : currOpacity - 10
currOpacity := (currOpacity < 25) ? 25 : (currOpacity >= 255) ? 255 : currOpacity
WinSet, Transparent, %currOpacity%, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return


; XButton2 & MButton = remove transparency
XButton2 & MButton::
MouseGetPos, , , hwndUnderCursor
WinSet, Transparent, 255, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return


; XButton2 & WheelLeft = set/remove "always on top" flag for the window under cursor
XButton2 & WheelLeft::
MouseGetPos, , , hwndUnderCursor
WinGet, pinned, ExStyle, ahk_id %hwndUnderCursor%
WinSet, AlwaysOnTop, Toggle, ahk_id %hwndUnderCursor%
WinGet, id, id, A
If (pinned & 0x00000008)
{
	WinActivate, ahk_id %hwndUnderCursor%
	WinActivate, ahk_id %id%
}
Gosub, CleanVars
Return

; Remove/restore titlebar of the window under cursor
XButton2 & WheelRight::
<#Space::
MouseGetPos, , , hwndUnderCursor
WinGet, Title, Style, ahk_id %hwndUnderCursor%
If (Title & 0xC00000)
	WinSet, Style, -0xC00000, ahk_id %hwndUnderCursor%
Else WinSet, Style, +0xC00000, ahk_id %hwndUnderCursor%
; Redraw the window
WinGetPos, , , , Height, ahk_id %hwndUnderCursor%
WinMove, ahk_id %hwndUnderCursor%, , , , , % Height-1
WinMove, ahk_id %hwndUnderCursor%, , , , , % Height
Gosub, CleanVars
Return

GetUnderCursor:
MouseGetPos, , , hwndUnderCursor
WinGet, currOpacity, Transparent, ahk_id %hwndUnderCursor%
Return

CleanVars:
currOpacity := hwndUnderCursor := x1 := y1 := id := winClass := maximized := winX1 := winY1 := x2 := y2 := winX2 := winY2 := id := control := class := properTargetWin := Hwnd := Height := m_x := m_y := hw_m_target :=
Return


; KeyboardExtras
; LWin + ` to set/remove "always on top" flag for the active window
LWin & vkC0::WinSet, AlwaysOnTop, Toggle, A


; Per-application rules
; Zoom control for Firefox
#IfWinActive ahk_class MozillaWindowClass
XButton1 & WheelUp::Send ^{+}
XButton1 & WheelDown::Send ^{-}
Xbutton1 & MButton::Send ^0
#IfWinActive

; Counter-Strike
#IfWinActive ahk_class Valve001
Xbutton1::Send {F9}
XButton2::Send {F10}
LWin::Send !{Tab}
#IfWinActive

; Media Player Classic - Home Cinema
#IfWinActive ahk_class MediaPlayerClassicW
XButton1::Send {Media_Prev}
XButton2::Send {Media_Next}
#IfWinActive