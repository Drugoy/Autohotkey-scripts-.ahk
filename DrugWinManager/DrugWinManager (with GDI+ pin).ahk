/* DrugWinManager v2.0
Description: a bunch of tiny scripts that serve different functions and help to manage windows, using extra keyboard and mouse buttons and key combos.
I use mouse "Logitech M510" and keyboard "Genius Comfy KB-21e scroll" and each has extra buttons: that mouse has a wheel that can be turned left and right and it also has two extra buttons (XButton1 and XButton2) and the keyboard has lots of extra buttons.
The script has the following functions:
1. The script draws a small indicator on top of "always on top" windows (a semi-transparent red rectangular at top left corner of the window);
2. Hit "left WinKey + `" to toggle "always on top" attribute for the active window;
3. Hold XButton2 and hit WheelLeft (on the mouse) to toggle "always on top" attribute for the window under cursor (without activating it);
4. Scroll over inactive windows to scroll them without their activation;
5. Scroll over tab bar to switch tabs in Notepad++, AkelPad, Miranda's TabSRMM and Internet Explorer;
6. Hitting WheelLeft/WheelRight (on the mouse) works as going back/forward (correspondingly) in the history of browsers and in Windows Explorer;
7. Hit "XButton1" to copy (sends Ctrl+C);
8. Hit "XButton2" to paste (sends Ctrl+V);
9. Hit "Excel" key to run AkelPad Portable, activate it or hide;
10. Hit "Word" key to run Notepad++ Portable, activate it or hide;
11. Hit "WWW" key to run AHK Toolkit;
12. Hit "My Computer" key to minimize all (bring desktop to front) and to undo that;
13. Hit "Calculator" key to run calc;
14. Hit keyboard wheel to run AnVirTM, activate it or hide;
15. Hold XButton2, then hold Left Mouse Button and then drag the mouse (while Left Mouse Button is being held) to move the window under cursor (and if it was inactive - it stays inactive);
16. Hold XButton2 and scroll Mouse Wheel Up/Down to increase/decrease the opacity of the window under cursor;
17. Hold XButton2 and hit Mouse Middle Button to remove transparency from the window under cursor;
18. Hit "left WinKey + Space" to remove/restore the titlebar of the active window;
19. Hold XButton2 and hit WheelRight (on the mouse) to remove/restore the titlebar of the window under cursor;
20. Hit "left WinKey + left Ctrl + s" to pseudo-maximize the active window (the window doesn't actually become maximized, but gets resized as if it was);
21. Hit "left WinKey + left Alt + w/s/a/d" to resize the active window: decrease height/increase height/decrease width/increase width (correspondingly);
22. Hit "left WinKey + left Shift + w/s/a/d" to move the active window top/bottom/left/right;
23. Hit "left WinKey + left Ctrl + q/e/z/c" to make the active window occupy top_left/top_right/bottom_left/bottom_right quarter of the "usable area" (desktop area minus Windows' taskbar area);
24. Hit "left WinKey + left Ctrl + w/x/a/d" to make the active window occupy top/bottom/left/right part of the "usable area";
25. Hold CapsLock and hit Tab to paste tab character.

Firefox specific hotkeys:
1. Hold XButton1 and scroll Mouse Wheel Up/Down to increase/decrease to zoom page in/out;
2. Hold XButton1 and hit Middle Mouse Button to reset page's zoom level.


Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/DrugWinManager
*/
;{ Initialization
	;{ Settings
#SingleInstance, Force
SetWinDelay, 0
SendMode Input	; Recommended For new scripts due to its superior speed and reliability.
	;}

#NoEnv	; Recommended For performance and compatibility with future AutoHotkey releases.
CoordMode, Mouse, Screen	; By default all coordinates are relative to the active window, changing them to be related to screen is required for proper work of some script's commands.
SysGet, UA, MonitorWorkArea	; Getting Usable Area info.

	;{ Defining variables' values for later use.
UAcenterX := UALeft + (UAhalfW := (UALeft + UARight) / 2)
UAcenterY := UATop + (UAhalfH := (UATop + UABottom) / 2)
Global GUIs := [], Exceptions := [], WS_EX_TOPMOST := 0x8, EVENT_OBJECT_SHOW := 0x8002, EVENT_OBJECT_HIDE := 0x8003, OBJID_WINDOW := 0, EVENT_OBJECT_LOCATIONCHANGE := 0x800B, WINEVENT_SKIPOWNPROCESS := 0x2
Exceptions := ["Button", "tooltip", "shadow", "TaskListThumbnailWnd", "TaskListOverlayWnd", "Progman", "ComboLBox", "Shell_TrayWnd", "TTrayAlert", "NotifyIconOverflowWindow", "SysDragImage", "ClockFlyoutWindow", "#327"]	; Exceptions list: add here classNNs (or their parts) of windows to exclude from monitoring.	; TabSRMM's window has class #32770
	;}
	;{ Setting hooks.
HWINEVENTHOOK1 := setWinEventHook(EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE, 0, RegisterCallback("watchingShowHideWindow", "F"), 0, 0, WINEVENT_SKIPOWNPROCESS)	; Track windows' appearing and hiding
HWINEVENTHOOK2 := setWinEventHook(EVENT_OBJECT_LOCATIONCHANGE, EVENT_OBJECT_LOCATIONCHANGE, 0, RegisterCallback("watchingChangeLocation", "F"), 0, 0, WINEVENT_SKIPOWNPROCESS)	; Track windows' position changes
OnExit, Exit	; Remove hooks upon exit.
	;}
	;{ Set timer to monitor changes in windows' positions and visibility (to redraw "always on top" markers if needed).
SetTimer, MonitoringWindows, 1000	; Monitoring windows' positions to redraw AlwaysOnTop indicator.
MonitoringWindows:	; Used for timer that tracks windows' position changes to redraw the "always on top" marker.
	For k, v in GUIs
		If !WinExist("ahk_id" v.Parent)
			alwaysOnTopOff(v.Parent)
	WinGet, List, List
	Loop % List
	{
		ID := List%A_Index%
		WinWait, ahk_id %ID%
		WinGet, PID, PID
		For k, v in GUIs
			If (v.Parent == ID)
			{
				WinGet, ExStyle, ExStyle
				If !(ExStyle & WS_EX_TOPMOST)
					alwaysOnTopOff(ID)
				Continue 2
			}
		checkingAndMarking(ID)
	}
Return
	;}
	;{ Bind left click on tray icon to open menu like If you right clicked it.
Menu Tray, Click, 1	; Enable single click action on tray.
Gosub AddMenu		; Add new default menu.
Return

AddMenu:
	Menu Tray, Add, ShowMenu		; Add temporary menu item.
	Menu Tray, Default, ShowMenu	; Set it to be default (it gets executed (or opened) just when you left click the tray icon).
Return

ShowMenu:	; The temporary menu item that 
	Menu Tray, Delete, ShowMenu	; If we don't delete that temporary menu item we created - it will be displayed in the tray icon's context menu and since clicking on it would just reopen the very same menu - we don't need it to be displayed, so we delete it.
	MouseGetPos MouseX, MouseY
	Menu Tray, Show, %MouseX%, % MouseY - 15	; By default context menu gets opened at cursor's position and to let user be able to double click the tray icon - we move this menu a 15px higher.
	Gosub, AddMenu	; We have to restore the deleted menu item for later use.
Return
	;}
;}
;{ Hotkeys
; Toggle "Always on top" attribute
; active window: LWin + `
; the window under cursor: XButton2 & WheelLeft
<#vkC0::
XButton2 & WheelLeft::
	If (A_ThisHotkey == "<#vkC0")
		WinGet, ID,, A
	Else
	{
		WinGet, IDactive,, A
		MouseGetPos,,, ID
		WinGet, onTop, ExStyle, ahk_id %ID%
	}
	WinGetPos, XWIn, YWin,,, ahk_id %ID%
	WinGetClass, Class, ahk_id %ID%
	For k, v in Exceptions
		If InStr(Class, v)
		{
			Gosub, CleanVars
			Return
		}
	For k, v in GUIs
		If (v.Parent == ID)
		{
			alwaysOnTopOff(ID)	; Remove "always on top" flag
			If (A_ThisHotkey != "<#vkC0") && (onTop & WS_EX_TOPMOST)
			{
				WinActivate, ahk_id %ID%
				WinActivate, ahk_id %IDactive%
			}
			Gosub, CleanVars
			Return
		}
	WinSet, AlwaysOnTop, On, ahk_id %ID%
	createMarker(ID, XWin + 8, YWin + 7)
	Gosub, CleanVars
	Return


; Scroll inactive windows without activating them.
; Tab Wheel Scroll For Notepad++, Miranda IM (TabSRMM), AkelPad and Internet Explorer.
; Can't do the same For Google Chrome and Mozilla Firefox.
WheelUp::
WheelDown::
	MouseGetPos, m_x, m_y, id, control, 1
	hw_m_target := DllCall("WindowFromPoint", "int", m_x, "int", m_y)
	WinGetClass, class, ahk_id %id%
	If (class == "Notepad++") && (control == "SysTabControl325")	; Notepad++: ahk_class Notepad++	tab-bar classNN: SysTabControl325	listener-window classNN: Scintilla1
	{
		ControlGet, properTargetWin, Hwnd,, Scintilla1, ahk_id %id%
		PostMessage 0x319, 0, (A_ThisHotkey == "WheelUp") ? 0x10000 : 0x20000,, ahk_id %properTargetWin%
	}
	Else If (control == "TSTabCtrlClass1")	; Miranda IM, TabSRMM window's tab-bar classNN: TSTabCtrlClass1	listener-window classNN: RichEdit20W1
	{
		ControlGet, properTargetWin, Hwnd,, RichEdit20W1, ahk_id %id%
		PostMessage 0x319, 0, (A_ThisHotkey == "WheelUp") ? 0x10000 : 0x20000,, ahk_id %properTargetWin%
	}
	Else If ((class == "AkelPad4") && (control == "SysTabControl321")) || ((class == "IEFrame") && (control == "DirectUIHWND2"))
		ControlSend,, % (A_ThisHotkey == "WheelUp") ? ("{Ctrl Down}{Shift Down}{Tab}{Shift Up}{Ctrl Up}") : ("{Ctrl Down}{Tab}{Ctrl Up}"), ahk_id %id%
	PostMessage, 0x20A, (A_ThisHotkey == "WheelUp") ? 120 << 16 : -120 << 16, ( m_y << 16 )|m_x,, ahk_id %hw_m_target%
	Gosub, CleanVars
Return

WheelLeft::Send {Browser_Back}	; Go Back.
WheelRight::Send {Browser_Forward}	; Go Forward.
XButton1::Send ^{vk0x43sc0x2e}	; Copy (by sending Ctrl+C).
XButton2::Send ^{vk0x56sc0x2f}	; Paste (by sending Ctrl+V).
; XButton1::Send {Ctrl Down}{vk0x43sc0x2e}{Ctrl Up}
; XButton2::Send {Ctrl Down}{vk0x56sc0x2f}{Ctrl Up}

; Excel keyboard key to open AkelPad
sc0x114::
	Process, Exist, AkelPadPortable.exe
	If !ErrorLevel
		Run, C:\Soft\Portable soft\AkelPadPortable\AkelPadPortable.exe
	Else
	{
		IfWinExist, ahk_class AkelPad4
		{
			If WinActive(ahk_class AkelPad4)
				WinHide, ahk_class AkelPad4
			Else
				WinActivate, ahk_class AkelPad4
		}
		Else
		{
			WinShow, ahk_class AkelPad4
			IfWinNotActive, ahk_class AkelPad4
				WinActivate, ahk_class AkelPad4
		}
	}
Return

; Word keyboard key to open Notepad++
sc0x113::
	Process, Exist, Notepad++Portable.exe
	If (ErrorLevel == 0)
		Run, C:\Soft\Portable soft\Notepad++Portable\Notepad++Portable.exe
	Else
	{
		IfWinExist, ahk_class Notepad++
		{
			If WinActive(ahk_class Notepad++)
				WinHide, ahk_class Notepad++
			Else
				WinActivate, ahk_class Notepad++
		}
		Else
		{
			WinShow, ahk_class Notepad++
			IfWinNotActive, ahk_class Notepad++
				WinActivate, ahk_class Notepad++
		}
	}
Return

; WWW keyboard key to open AHK Toolkit
Browser_Home::Run, C:\Program Files\AutoHotkey\Scripts\DevTools\ToolKit\AHK-ToolKit.exe

; My Computer keyboard key
Launch_App1::Send #d

; Calculator keyboard key
Launch_App2::Run, calc

; Keyboard wheel click to open AnVir
sc0x123::
	IfWinNotExist, ahk_class AnVirMainFrame
	{
		Run C:\Soft\Portable soft\AnvirTaskManager\AnVir.exe
		WinWait, ahk_class AnVirMainFrame
		WinActivate, ahk_class AnVirMainFrame
	}
	Else
	{
		IfWinActive, ahk_class AnVirMainFrame
			WinClose, ahk_class AnVirMainFrame
		Else
			WinActivate, ahk_class AnVirMainFrame
	}
Return

; Drag windows
XButton2 & LButton::moveWinWithCursor("LButton")
moveWinWithCursor(buttonHeld)
{
	SetWinDelay, 0
	CoordMode, Mouse
	MouseGetPos, x1, y1, id
	WinExist("ahk_id" . id)
	WinGetClass, winClass
	WinGet, maximized, MinMax
	If (!GetKeyState(buttonHeld, "P")) || (winClass == "WorkerW") || (maximized)
		Exit
	WinGetPos, winX1, winY1
	While GetKeyState(buttonHeld, "P")
	{
		MouseGetPos, x2, y2
		x2 -= x1, y2 -= y1, winX2 := winX1 + x2, winY2 := winY1 + y2
		WinMove,,, winX2, winY2
		Sleep 15
	}
	Gosub, CleanVars
}

; Control transparency of a window under the cursor.
XButton2 & WheelUp::
XButton2 & WheelDown::
MouseGetPos,,, hwndUnderCursor
WinGet, currOpacity, Transparent, ahk_id %hwndUnderCursor%
If !(curropacity)
	currOpacity := 255
currOpacity := (A_ThisHotkey == "XButton2 & WheelUp") ? currOpacity + 10 : currOpacity - 10
currOpacity := (currOpacity < 25) ? 25 : (currOpacity >= 255) ? 255 : currOpacity
WinSet, Transparent, %currOpacity%, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return

; Remove transparency of the window under the cursor.
XButton2 & MButton::
MouseGetPos,,, hwndUnderCursor
WinSet, Transparent, 255, ahk_id %hwndUnderCursor%
Gosub, CleanVars
Return

; Remove/restore titlebar of the window under the cursor.
XButton2 & WheelRight::
<#Space::
MouseGetPos,,, hwndUnderCursor
WinGet, Title, Style, ahk_id %hwndUnderCursor%
If (Title & 0xC00000)
	WinSet, Style, -0xC00000, ahk_id %hwndUnderCursor%
Else WinSet, Style, +0xC00000, ahk_id %hwndUnderCursor%
; Redraw the window
WinGetPos,,,, Height, ahk_id %hwndUnderCursor%
WinMove, ahk_id %hwndUnderCursor%,,,,, % Height - 1
WinMove, ahk_id %hwndUnderCursor%,,,,, % Height
Gosub, CleanVars
Return

; Pseudo-maximize the active window (LWin + LCtrl + s).
<#<^vk53::WinMove, A,, UALeft, UATop, UARight - UALeft, UABottom - UATop

; Resize the active window	(LWin + LAlt + w/s/a/d)
<!<#vk57::winMoveResize(0, 0, 0, -UAhalfH / 8)	; Decrease height	(w).
<!<#vk53::winMoveResize(0, 0, 0, UAhalfH / 8)	; Increase height	(s).
<!<#vk41::winMoveResize(0, 0, -UAhalfW / 8, 0)	; Decrease width	(a).
<!<#vk44::winMoveResize(0, 0, UAhalfW / 8, 0)	; Increase width	(d).

; Move the active window	(LWIn + LShift + w/s/a/d)
<+<#vk57::winMoveResize(0, -UAhalfH / 8, 0, 0)	; Move top		(w).
<+<#vk53::winMoveResize(0, UAhalfH / 8, 0, 0)	; Move bottom	(s).
<+<#vk41::winMoveResize(-UAhalfW / 8, 0, 0, 0)	; Move left		(a).
<+<#vk44::winMoveResize(UAhalfW / 8, 0, 0, 0)	; Move right	(d).

; Quarter the active window	(LWin + LCtrl + q/e/z/c)
<#<^vk51::WinMove, A,, UALeft, UATop, UAcenterX, UAcenterY			; Top left		(q).
<#<^vk45::WinMove, A,, UAcenterX, UATop, UAcenterX, UAcenterY		; Top right		(e).
<#<^vk5A::WinMove, A,, UALeft, UAcenterY, UAcenterX, UAcenterY		; Bottom left	(z).
<#<^vk43::WinMove, A,, UAcenterX, UAcenterY, UAcenterX, UAcenterY	; Bottom right	(c).

; Half the active window	(LWin + LCtrl + w/x/a/d)
<#<^vk57::WinMove, A,, UALeft, UATop, UARight - UALeft, UAcenterY		; Top		(w).
<#<^vk58::WinMove, A,, UALeft, UAcenterY, UARight - UALeft, UAcenterY	; Bottom	(x).
<#<^vk41::WinMove, A,, UALeft, UATop, UAcenterX, UABottom - UATop		; Left		(a).
<#<^vk44::WinMove, A,, UAcenterX, UATop, UAcenterX, UABottom - UATop	; Right		(d).
;}

CapsLock & Tab::Send, {AltUp}	{AltUp}

;{ Functions
winMoveResize(dx, dy, dw, dh)
{
	WinGetPos, X, Y, W, H, A
	WinMove, A,, (X + dx), (Y + dy), (W + dw), (H + dh)
}

alwaysOnTopOff(hwnd)
{
	For k, v in GUIs
		If (v.Parent == hwnd)
		{
			WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
			Gui, % v.Owned ":Destroy"
			GUIs.Remove(k)
			Break
		}
}

checkingAndMarking(hwnd)
{
	Static WS_POPUP := 0x80000000, WS_CAPTION := 0xC00000, WS_BORDER := 0x800000
	WinWait, ahk_id %hwnd%
	WinGetClass, Class
	For k, v in Exceptions
		If InStr(Class, v)
			Return
	WinGet, ExStyle, ExStyle
	If (ExStyle & WS_EX_TOPMOST)
	{
		WinGet, Style, Style
		If (Style & WS_POPUP && !(Style & WS_CAPTION) && !(Style & WS_BORDER))
			Return
		; ToolTip % Class	; Uncomment this line to show a tooltip displaying active window's class, so you could add it to the exceptions list.
		WinGetPos, XWin, YWin, WWin, HWin
		; If (WWin == A_ScreenWidth && HWin == A_ScreenHeight)	; Fullscreen check: such windows should not get a marker.
		; {
		; 	; Msgbox HUI
		; 	Return
		; }
		createMarker(hwnd, XWin + 8, YWin + 7)
	}
}

createMarker(OwnerID, X, Y)
{
	Static WS_EX_TRANSPARENT := 0x20	; Needed to make the marker transparent for clicks
	Gui, New, +E%WS_EX_TRANSPARENT% -Caption +LastFound +AlwaysOnTop +ToolWindow +hwndhGui +Owner%OwnerID%	; +Owner%OwnerID% makes GUI window be bound to the active one, thus the GUI window becomes always on top of it's parent.
	WinSet, Transparent, 100	; Set marker's transparency [0; 255]
	Gui, Color, Red	; Set marker's color
	Gui, Show, NA w16 h16 x%X% y%Y%	; Set marker's size and position
	GUIs.Insert({Parent: OwnerID, Owned: hGui})
}

watchingShowHideWindow(hWinEventHook, event, hwnd, idObject)
{
	If (idObject != OBJID_WINDOW)
		Return
	If (event == EVENT_OBJECT_SHOW)
		checkingAndMarking(hwnd)
	Else If (event == EVENT_OBJECT_HIDE)
	{
		If !WinExist("ahk_id" hwnd)
			alwaysOnTopOff(hwnd)
	}
}

watchingChangeLocation(hWinEventHook, event, hwnd, idObject)
{
	If (idObject != OBJID_WINDOW)
		Return
	Static i := 0, OwnedWindowID, MonitoredWindowID
	For k, v in GUIs
		If (v.Parent == hwnd)
		{
			OwnedWindowID := v.Owned
			MonitoredWindowID := v.Parent
			SetTimer, watchingMove, 10
			Break
		}
	Return
	
watchingMove:
	WinGetPos, X, Y,,, ahk_id %MonitoredWindowID%
	WinMove, ahk_id %OwnedWindowID%,, X + 8, Y + 7
	If (i++ == 30)
	{
		i := 0
		SetTimer, watchingMove, Off
	}
	Return
}



setWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags)
{
	Return DllCall("SetWinEventHook" , UInt, eventMin, UInt, eventMax, Ptr, hmodWinEventProc, Ptr, lpfnWinEventProc, UInt, idProcess, UInt, idThread, UInt, dwFlags, Ptr)
}
;}
;{ Clean variables (label)
CleanVars:
currOpacity := hwndUnderCursor := x1 := y1 := id := winClass := maximized := winX1 := winY1 := x2 := y2 := winX2 := winY2 := ID := IDactive := control := class := properTargetWin := Hwnd := Height := m_x := m_y := hw_m_target := onTop :=
Return

Exit:	; Removing hooks upon exit.
	DllCall("UnhookWinEvent", Ptr, HWINEVENTHOOK1)
	DllCall("UnhookWinEvent", Ptr, HWINEVENTHOOK2)
	; Removing WS_EX_TOPMOST from every window we set it earlier.
	; For k, v in GUIs
		; WinSet, AlwaysOnTop, Off, % "ahk_id" v.Parent
	GUIs := ""
	ExitApp
;}
;{ Per-application rules
; Zoom control For Firefox
#IfWinActive ahk_class MozillaWindowClass
XButton1 & WheelUp::Send ^{+}
XButton1 & WheelDown::Send ^{-}
Xbutton1 & MButton::Send ^0

; Counter-Strike
#IfWinActive ahk_class Valve001
Xbutton1::Send {F9}
XButton2::Send {F10}
LWin::Send !{Tab}

; Media Player Classic - Home Cinema
#IfWinActive ahk_class MediaPlayerClassicW
XButton1::Send {Media_Prev}
XButton2::Send {Media_Next}
;}