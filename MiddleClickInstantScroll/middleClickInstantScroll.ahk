/* MiddleClickInstantScroll
Version: 0.5.1
Last time modified: 2015.05.14 16:39

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
	scrollBars := [{"exe": "hh.exe", "ctrl": "Internet Explorer_Server1", "sbvlo": 23, "sbvro": 8, "sbhto": 23, "sbhbo": 8}]
/*
'exe' - ProcessName of the target window;
'ctrl' - classNN of the control, shown by WinSpy when cursor hovers scrollbar;
'sbvlo' - offset from the right edge of the window, for the left edge of the vertical scrollbar;
'sbvro' - offset from the right edge of the window, for the right edge of the vertical scrollbar;
'sbhto' - offset from the bottom edge of the window, for the top edge of the horizontal scrollbar;
'sbhbo' - offset from the bottom edge of the window, for the bottom edge of the horizontal scrollbar;
*/
;}

DllCall("LoadLibrary", Str, "oleacc", Ptr)

$Mbutton::
	MouseGetPos, x, y, hoveredWinHWND, hoveredCtrlClass
	WinGet, activeWinHWND, ID, A
	WinGet, hoveredWinProcessName, ProcessName, ahk_id %hoveredWinHWND%
	stdWinReqActive := isVarInArr(hoveredWinProcessName, stdWinsReqActiv)
	nonStdWin := isVarInArr(hoveredWinProcessName, nonStdWins)
	active := (activeWinHWND == hoveredWinHWND ? 1 : 0)
	accRole := Acc_ObjectFromPoint().accRole(0)
	Loop, % scrollBars.maxIndex()
	{
		If (howeredWinExeName = scrollBars[A_Index].exe && hoveredCtrlClass = scrollBars[A_Index].ctrl)
		{
			thisItem := A_Index
			Break
		}
		thisItem := ""
	}
	WinGetPos, hoveredWinX, hoveredWinY,,, ahk_id %hoveredWinHWND%
	x -= hoveredWinX, y -= hoveredWinY
	If thisItem && (hoveredCtrlClass = scrollbars[thisItem].ctrl) && ((!scrollbars[thisItem].sbvlo || (ctrlWidth - scrollbars[thisItem].sbvlo <= x)) && (!scrollbars[thisItem].sbvro || (x <= ctrlWidth - scrollbars[thisItem].sbvro))) || ((!scrollbars[thisItem].sbhto || (ctrlHeight - scrollbars[thisItem].sbhto <= y)) && (!scrollbars[thisItem].sbhbo || (y <= ctrlHeight - scrollbars[thisItem].sbhbo)))
		predefined := 1
	Else
		predefined := 0	
	If active
	{
		If accRole = 3
			Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's position on it.
		Else	; accRole != 3
		{
			If nonStdWin && predefined	; Not yet coded, but possible.
				Send, +{LButton}
			Else	; !predefined
			{
				While (GetKeyState("MButton", "P"))
					Sleep, 20
				Send, {MButton}
			}
		}
	}
	Else	; !active
	{
		If accRole = 3
		{
			If !stdWinReqActive && !nonStdWin
			{
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
			If nonStdWin && predefined	; Not yet coded, but possible.
			{
				WinActivate, ahk_id %hoveredWinHWND%
				WinWaitActive, ahk_id %hoveredWinHWND%
				Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's position on it.
				WinActivate, ahk_id %activeWinHWND%
				WinWaitActive, ahk_id %activeWinHWND%
			}
			Else	; !predefined
				While (GetKeyState("MButton", "P"))
					Sleep, 20
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