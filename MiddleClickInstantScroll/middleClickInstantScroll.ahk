/* MiddleClickInstantScroll
Version: 0.4
Last time modified: 2015.05.10 01:55

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
CoordMode, Mouse, Screen	; More reliable cursor targeting.
SetControlDelay, -1

;{ Settings
	nonStdWins := ["hh.exe"]	; List processes that don't have role 3 set for their scrollbars, use predefined rules to detect scrollbars in them. 
	stdWinsReqActiv := ["mspaint.exe"]	; List processes that have role 3 set for their scrollbars, but don't play well with the ControlSend+ControlClick approach and require WinActivate+Send.
;}

DllCall("LoadLibrary", Str, "oleacc", Ptr)

$Mbutton::
	MouseGetPos, x, y, hoveredWinHWND, hoveredCtrlHWND, 2
	WinGet, activeWinHWND, ID, A
	WinGet, hoveredWinProcessName, ProcessName, ahk_id %hoveredWinHWND%
	stdWinReqActive := isVarInArr(hoveredWinProcessName, stdWinsReqActiv)
	nonStdWin := isVarInArr(hoveredWinProcessName, nonStdWins)
	active := (activeWinHWND == hoveredWinHWND ? 1 : 0)
	accRole := Acc_ObjectFromPoint().accRole(0)
	If active
	{
		If accRole = 3
			Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's position on it.
		Else	; accRole != 3
		{
			; If nonStdWin && predefined	; Not yet coded, but possible.
			; 	Send, +{LButton}
			; Else	; !predefined
				Send, {MButton}
		}
	}
	Else	; !active
	{
		If accRole = 3
		{
			If !stdWinReqActive && !nonStdWin
			{
				WinGetPos, hoveredWinX, hoveredWinY,,, ahk_id %hoveredWinHWND%
				x -= hoveredWinX, y -= hoveredWinY
				ControlSend,, {Shift Down}, ahk_id %hoveredWinHWND%
				ControlClick, x%x% y%y%, ahk_id %hoveredWinHWND%,,,, NA Pos
				Sleep, 50	; Without this some clicks go with "Shift" modifier already unpressed.
				ControlSend,, {Shift Up}, ahk_id %hoveredWinHWND%
			}
			Else	; stdWinReqActive || (nonStdWin && predefined)	; Not yet coded, but possible.
			{
				WinActivate, ahk_id %hoveredWinHWND%
				WinWaitActive, ahk_id %hoveredWinHWND%
				Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's position on it.
				WinActivate, ahk_id %activeWinHWND%
				WinWaitActive, ahk_id %activeWinHWND%
			}
		}
		Else	; accRole != 3
		{
			; If nonStdWin && predefined	; Not yet coded, but possible.
			; {
			; 	WinActivate, ahk_id %hoveredWinHWND%
			; 	WinWaitActive, ahk_id %hoveredWinHWND%
			; 	Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's position on it.
			; 	WinActivate, ahk_id %activeWinHWND%
			; 	WinWaitActive, ahk_id %activeWinHWND%
			; }
			; Else	; !predefined
				Send, {MButton}
		}
	}
Return

;{ Functions
Acc_ObjectFromPoint(ByRef _idChild_ = "", x = "", y = "")
{
	If DllCall("oleacc\AccessibleObjectFromPoint", "Int64", x == "" || y == "" ? 0 * DllCall("GetCursorPos", "Int64*", pt) + pt : x & 0xFFFFFFFF | y <<32, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild, 8 + 2 * A_PtrSize, 0) * 0 + &varChild) = 0
		Return ComObjEnwrap(9, pacc, 1), _idChild_ := NumGet(varChild, 8, "UInt")
}

isVarInArr(variable, array)
{
	For k, v In array
		If (variable = v)
			Return 1
}
;}