/* MiddleClickInstantScroll
Version: 0.3
Last time modified: 2015.04.29 21:30

Summary: middle click on arbitrary position on scrollbar to instantly scroll to that position.

Script author: Drugoy, a.k.a. Drugmix.
Contacts: idrugoy@gmail.com, drug0y@ya.ru
Thanks to: yalanne http://forum.script-coding.com/profile.php?id=32850

https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/MiddleClickInstantScroll/MiddleClickInstantScroll.ahk
*/

#NoEnv	; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn	; Enable warnings to assist with detecting common errors.
SendMode, Input	; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%	; Ensures a consistent starting directory.
#SingleInstance, Force
#WinActivateForce	; Fix taskbar blinking.

;{ Settings
	doNotSwitchWinFocus := 1	; When middle-clicking an inactive window - can't be more or less sure if clicked on the scrollbar or not, until that window is activated. '1' in that option makes the script switch the focus back to the initially active window, rather than leave the one that was inactive before the middle click.
;}


#If GetScroll()
Mbutton::
	MouseGetPos,,, hoveredWinHWND, hoveredCtrlClass
	WinGet, activeWinHWND, ID, A
; OutputDebug, % "hoveredWinHWND: '" hoveredWinHWND "' " "activeWinHWND: '" activeWinHWND "' "
	If (activeWinHWND != hoveredWinHWND)	; User middle clicked an inactive window.
	{
		WinActivate, ahk_id %hoveredWinHWND%	; Have to activate that window first, because otherwise 'MouseGetPos' command will get coordinates relative to the wrong window. Not yet sure if the script can be taught to avoid activating inactive windows and use 'ControlSend' + 'ControlClick' instead of 'Send'.
		WinWaitActive, ahk_id %hoveredWinHWND%
	}
	Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's positionon it.
	If doNotSwitchWinFocus && (activeWinHWND != hoveredWinHWND)	; Switch focus back.
	{
		WinActivate, ahk_id %activeWinHWND%
		WinWaitActive, ahk_id %activeWinHWND%
	}
#If

;{ Thanks to yalanne http://forum.script-coding.com/profile.php?id=32850
GetScroll()
{
	role := Acc_ObjectFromPoint(Child).accRole(Child)
	If role In 39,43
		Return 1
	Return 0
}

Acc_ObjectFromPoint(ByRef _idChild_ = "", x = "", y = "")
{
	DllCall("LoadLibrary", Str, "oleacc", Ptr)
	If DllCall("oleacc\AccessibleObjectFromPoint", "Int64", x == "" || y == "" ? 0 * DllCall("GetCursorPos", "Int64*", pt) + pt : x & 0xFFFFFFFF | y <<32, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild, 8 + 2 * A_PtrSize, 0) * 0 + &varChild) = 0
		Return ComObjEnwrap(9, pacc, 1), _idChild_ := NumGet(varChild, 8, "UInt")
}
;}