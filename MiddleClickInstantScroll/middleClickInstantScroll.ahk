/* MiddleClickInstantScroll
Version: 0.2
Last time modified: 2015.04.06 17:04
Summary: middle click on arbitrary position on scrollbar to instantly scroll to that position.

Script author: Drugoy, a.k.a. Drugmix.
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/MiddleClickInstantScroll/MiddleClickInstantScroll.ahk
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force
#WinActivateForce	; Fix taskbar blinking.
CoordMode, Mouse, Client	; More reliable cursor targeting.


;{ Settings
	doNotSwitchWinFocus := 1	; When middle-clicking an inactive window - can't be more or less sure if clicked on the scrollbar or not, until that window is activated. '1' in that option makes the script switch the focus back to the initially active window, rather than leave the one that was inactive before the middle click.
;}

;{ Data.
	scrollBars := [{"exe": "explorer.exe", "ctrl": "ScrollBar2", "sbvlo": 23, "sbvro": 8}, {"exe": "explorer.exe", "ctrl": "ScrollBar1", "sbhto": 23, "sbhbo": 8}, {"exe": "notepad.exe", "ctrl": "Edit1", "sbvlo": 20, "sbvro": 3, "sbhto": 20, "sbhbo": 3}, {"exe": "akelpad.exe", "ctrl": "AkelEditW1", "sbvlo": 20, "sbvro": 3, "sbhto": 60, "sbhbo": 43}]
/*
'exe' - ProcessName of the target window;
'ctrl' - classNN of the control, shown by WinSpy when cursor hovers scrollbar;
'sbvlo' - offset from the right edge of the window, for the left edge of the vertical scrollbar;
'sbvro' - offset from the right edge of the window, for the right edge of the vertical scrollbar;
'sbhto' - offset from the bottom edge of the window, for the top edge of the horizontal scrollbar;
'sbhbo' - offset from the bottom edge of the window, for the bottom edge of the horizontal scrollbar;
*/
;}

$MButton::
	MouseGetPos,,, hoveredWinHWND, hoveredCtrlClass
	WinGet, howeredWinExeName, ProcessName, ahk_id %hoveredWinHWND%
	Loop, % scrollBars.maxIndex()
		If (howeredWinExeName = scrollBars[A_Index].exe && hoveredCtrlClass = scrollBars[A_Index].ctrl)
			thisItem := A_Index
	If !thisItem	; Not found in the scrolls database.
		Send, {MButton}
	Else
	{
		; OutputDebug, % howeredWinExeName " is found in the scrolls database, recognized process name: '" scrollBars[thisItem].exe "'recognized control's class: '" scrollBars[thisItem].ctrl "'and also some offsets for the both edges of horizontal and vertical scrollbars."
		WinGet, activeWinHWND, ID, A
		If (activeWinHWND != hoveredWinHWND)	; User middle clicked an inactive window.
		{
			WinActivate, ahk_id %hoveredWinHWND%	; Have to activate that window first, because otherwise 'MouseGetPos' command will get coordinates relative to the wrong window. Not yet sure if the script can be taught to avoid activating inactive windows and use 'ControlSend' + 'ControlClick' instead of 'Send'.
			WinWaitActive, ahk_id %hoveredWinHWND%
		}
		MouseGetPos, relPosX, relPosY,, hoveredCtrlHwnd, 2
		ControlGetPos,,, ctrlWidth, ctrlHeight,, ahk_id %hoveredCtrlHwnd%
		; OutputDebug, % "ctrlWidth: '" ctrlWidth "'`n" "ctrlHeight: '" ctrlHeight "'`n" "relPosX: '" relPosX "'`n" "relPosY: '" relPosY "'`n" "scrollbars[thisItem].sbvlo: '" scrollbars[thisItem].sbvlo "'`n" "scrollbars[thisItem].sbvro: '" scrollbars[thisItem].sbvro "'`n" "scrollbars[thisItem].sbhto: '" scrollbars[thisItem].sbhto "'`n" "scrollbars[thisItem].sbhbo: '" scrollbars[thisItem].sbhbo "'`n"
		; OutputDebug, % (!scrollbars[thisItem].sbvlo || (ctrlWidth - scrollbars[thisItem].sbvlo <= relPosX)) 
		If (hoveredCtrlClass = scrollbars[thisItem].ctrl) && ((!scrollbars[thisItem].sbvlo || (ctrlWidth - scrollbars[thisItem].sbvlo <= relPosX)) && (!scrollbars[thisItem].sbvro || (relPosX <= ctrlWidth - scrollbars[thisItem].sbvro))) || ((!scrollbars[thisItem].sbhto || (ctrlHeight - scrollbars[thisItem].sbhto <= relPosY)) && (!scrollbars[thisItem].sbhbo || (relPosY <= ctrlHeight - scrollbars[thisItem].sbhbo)))
		{
			OutputDebug, sending shift+click!
			Send, +{LButton}	; Shift+Click on the scrollbar scrolls it to the cursor's positionon it.
		}
		If doNotSwitchWinFocus && (activeWinHWND != hoveredWinHWND)	; Switch focus back.
		{
			WinActivate, ahk_id %activeWinHWND%
			WinWaitActive, ahk_id %activeWinHWND%
		}
	}
	thisItem := 0
Return