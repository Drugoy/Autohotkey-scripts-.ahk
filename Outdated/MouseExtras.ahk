#SingleInstance, Force
#NoEnv			; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input	; Recommended for new scripts due to its superior speed and reliability.


; Tab Wheel Scroll for Notepad++, AkelPad and Internet Explorer
; Can't do the same for Google Chrome, Mozilla Firefox and Miranda IM :(

~WheelUp::
MouseGetPos, , , id, control, 1
WinGetClass, class, ahk_id %id%
If (control == "SysTabControl325") && (class == "Notepad++")
{
	ControlGet, hScintilla, Hwnd, , Scintilla1, ahk_class Notepad++
	PostMessage 0x319, 0, 0x10000, , ahk_id %hScintilla%
}
Else If ((control == "SysTabControl321") && (class == "AkelPad4")) || ((control == "DirectUIHWND2") && (class == "IEFrame"))
	ControlSend, , {Ctrl Down}{Shift Down}{Tab}{Shift Up}{Ctrl Up}, ahk_id %id%
Gosub, CleanVars
Return

~WheelDown::
MouseGetPos, , , id, control, 1
WinGetClass, class, ahk_id %id%
If (control == "SysTabControl325") && (class == "Notepad++")
{
	ControlGet, hScintilla, Hwnd, , Scintilla1, ahk_class Notepad++
	PostMessage 0x319, 0, 0x20000, , ahk_id %hScintilla%
}
Else If ((control == "SysTabControl321") && (class == "AkelPad4")) || ((control == "DirectUIHWND2") && (class == "IEFrame"))
	ControlSend, , {Ctrl Down}{Tab}{Ctrl Up}, ahk_id %id%
Gosub, CleanVars
Return


; Global Hotkeys

WheelLeft::
Send {Browser_Back}
Return

WheelRight::
Send {Browser_Forward}
Return

XButton1::
Send {Ctrl Down}{vk0x43sc0x2e}{Ctrl Up}
Return

XButton2::
Send {Ctrl Down}{vk0x56sc0x2f}{Ctrl Up}
Return


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


; Control transparency of a window under cursor via XButton2 & Wheel(Down/Up). XButton2 & MButton = remove transparency.

XButton2 & WheelUp::
Gosub, GetUnderCursor
If !(curropacity)
	currOpacity := 255
If (currOpacity <= 245)
	currOpacity := currOpacity + 10
WinSet, Transparent, %currOpacity%, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return

XButton2 & WheelDown::
Gosub, GetUnderCursor
If !(currOpacity)
	currOpacity := 255
If (currOpacity > 25)
	currOpacity := currOpacity - 10
WinSet, Transparent, %currOpacity%, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return

XButton2 & MButton::
MouseGetPos, , , hwndUnderCursor
WinSet, Transparent, 255, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return

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
currOpacity := hwndUnderCursor := x1 := y1 := id := winClass := maximized := winX1 := winY1 := x2 := y2 := winX2 := winY2 := id := control := class := hScintilla := Hwnd := Height :=
Return


; KeyboardExtras

LWin & vkC0::WinSet, AlwaysOnTop, Toggle, A


; Zoom control for Firefox

#IfWinActive ahk_class MozillaWindowClass
XButton1 & WheelUp::Send ^{+}
XButton1 & WheelDown::Send ^{-}
Xbutton1 & MButton::Send ^0
#IfWinActive

#IfWinActive ahk_class Valve001
Xbutton1::Send {F9}
XButton2::Send {F10}
#IfWinActive