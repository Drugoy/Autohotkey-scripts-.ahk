/* DrugWinManager v2.4
Last time modified: 2016.01.12 18:00

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/DrugWinManager

Description:
	Lets you scroll over tab-bars to switch tabs, lets you scroll inactive windows (without activating them) and adds a bunch of hotkeys that help manage windows.

	I use "Logitech M510" mouse and "Genius Comfy KB-21e scroll" keyboard and each of them has extra buttons: that mouse has a wheel that can be turned left and right and it also has two extra buttons (XButton1 and XButton2) and the keyboard has lots of extra buttons.

	The script has the following functions:
1. Scroll over inactive windows to scroll them without their activation;
2. Scroll over tab bar to switch tabs in Notepad++, AkelPad, Miranda's TabSRMM and Internet Explorer;
3. Adds hotkeys and key combos that use both keyboard and mouse and their extra buttons:
	1. Hit "left WinKey + `" to toggle "always on top" attribute for the active window;
	2. Hold XButton2 and hit WheelLeft (on the mouse) to toggle "always on top" attribute for the window under cursor (without activating it);
	3. Middle mouse click on windows on taskbar to close them.
	4. Hitting WheelLeft/WheelRight (on the mouse) works as going back/forward (correspondingly) in the history of browsers and in Windows Explorer;
	5. Hit "XButton1" to copy (sends Ctrl+C);
	6. Hit "XButton2" to paste (sends Ctrl+V);
	7. Hit "Excel" key to run AkelPad, activate it or hide;
	8. Hit "Word" key to run Notepad++ Portable, activate it or hide;
	9. Hit "WWW" key to run AHK Toolkit;
	10. Hit "My Computer" key to minimize all (bring desktop to front) and to undo that;
	11. Hit "Calculator" key to run calc;
	12. Hit keyboard "wheel" (extra button) to run AnVirTM, activate it or hide;
	13. Hit "left Ctrl + keyboard wheel" to run ScriptManager.ahk, activate it or hide;
	14. Ho	ld XButton2, then hold Left Mouse Button and then drag the mouse (while Left Mouse Button is being held) to move the window under cursor (and if it was inactive - it stays inactive);
	15. Hold XButton2 and scroll Mouse Wheel Up/Down to increase/decrease the opacity of the window under cursor;
	16. Hold XButton2 and hit Mouse Middle Button to remove transparency from the window under cursor;
	17. Hit "left WinKey + Space" to remove/restore the titlebar of the active window;
	18. Hold XButton2 and hit WheelRight (on the mouse) to remove/restore the titlebar of the window under cursor;
	19. Hit "left WinKey + left Ctrl + s" to pseudo-maximize the active window (the window doesn't actually become maximized, but gets resized as if it was);
	20. Hit "left WinKey + left Alt + w/s/a/d" to resize the active window: decrease height/increase height/decrease width/increase width (correspondingly);
	21. Hit "left WinKey + left Shift + w/s/a/d" to move the active window top/bottom/left/right;
	22. Hit "left WinKey + left Ctrl + q/e/z/c" to make the active window occupy top_left/top_right/bottom_left/bottom_right quarter of the "usable area" (desktop area minus Windows' taskbar area);
	23. Hit "left WinKey + left Ctrl + w/x/a/d" to make the active window occupy top/bottom/left/right part of the "usable area".
4. Application-specific hotkeys
	Firefox:
		a. Hold XButton1 and scroll Mouse Wheel Up/Down to increase/decrease to zoom page in/out;
		b. Hold XButton1 and hit Middle Mouse Button to reset page's zoom level.
	Media Player Classic - Home Cinema:
		a. Xbutton1 and Xbutton2 respectively switch to the previous and next videos.
	24. Hit "left WinKey + NumpadDel/NumpadDot" to minimize/restore the active window.

To do:
1. Improve scrolling over inactive windows (there are some problems with windows consisting of multiple scrollable parts, like hh.exe).
2. Add GDI+ pins to the pinned windows.
*/
;{ Initialization
#SingleInstance, Force
SetWinDelay, 0
SendMode, Input	; Recommended For new scripts due to its superior speed and reliability.
#NoEnv	; Recommended For performance and compatibility with future AutoHotkey releases.
CoordMode, Mouse	; By default all coordinates are relative to the active window, changing them to be related to screen is required for proper work of some script's commands.
#MaxThreadsBuffer, Off
	;{ Retrieve data from monitors.
SysGet, monCount, MonitorCount	; Retrieving the number of monitors.
Loop, %monCount%
{
	SysGet, mon%A_Index%, Monitor, %A_Index%	; Retrieving monitors' positions data.
	SysGet, UA%A_Index%, MonitorWorkArea, %A_Index%	; Getting Usable Area info.
	; Defining variables' values for later use.
	UA%A_Index%centerX := UA%A_Index%Left + (UA%A_Index%halfW := (UA%A_Index%Right - UA%A_Index%Left) / 2)
	UA%A_Index%centerY := UA%A_Index%Top + (UA%A_Index%halfH := (UA%A_Index%Bottom - UA%A_Index%Top) / 2)
}
	;}
; Bind left click on tray icon to open menu like If you right clicked it.
Menu, Tray, Click, 1	; Enable single click action on tray.
GoSub, AddMenu	; Add new default menu.
Return
;}
;{ Hotkeys
	;{ Toggle "Always on top" attribute for the active window (LWin + `)
<#vkC0::WinSet, AlwaysOnTop, Toggle, A
	;}
	;{ Toggle "Always on top" attribute for the window under the cursor (XButton2 & WheelLeft)
XButton2 & WheelLeft::
	WinGet, IDactive,, A
	MouseGetPos,,, ID
	WinGet, onTop, ExStyle, ahk_id %ID%
	WinGetPos, XWin, YWin,,, ahk_id %ID%
	WinGetClass, Class, ahk_id %ID%
	WinGet, procName, ProcessName, ahk_id %ID%
	WinSet, AlwaysOnTop, Toggle, ahk_id %ID%
	WinActivate, ahk_id %ID%
	WinActivate, ahk_id %IDactive%
	GoSub, CleanVars
Return
 	;}
	;{ Scroll inactive windows without activating them
; Tab Wheel Scroll For Notepad++, Miranda IM (TabSRMM), AkelPad and Internet Explorer.
; Can't do the same For Google Chrome and Mozilla Firefox.
$WheelUp::
$WheelDown::
	MouseGetPos, m_x, m_y, id, control, 1
	If (A_PtrSize != 8)	; AHK is 32-bit.
		hw_m_target := DllCall("WindowFromPoint", "Int", m_x, "Int", m_y)
	Else	; AHK is 64-bit.
	{
		m_xy := ((m_y & 0xFFFFFFFF) << 32) | (m_x & 0xFFFFFFFF)
		hw_m_target := DllCall("WindowFromPoint", "Int64", m_xy, "UPtr")
	}
	WinGetClass, class, ahk_id %id%
	WinGet, idA, ID, A
	;{ Notepad++: ahk_class Notepad++	tab-bar classNN: SysTabControl325	listener-window classNN: Scintilla1
	If (class == "Notepad++") && (control == "SysTabControl325")
	{
		ControlGet, properTargetWin, Hwnd,, Scintilla1, ahk_id %id%
		PostMessage, 0x319, 0, (A_ThisHotkey == "$WheelUp") ? 0x10000 : 0x20000,, ahk_id %properTargetWin%
	}
	;}
	;{ ahk_class HH Parent ahk_exe hh.exe (built-in *.chm viewer)
	Else If (class == "HH Parent")
	{
		DetectHiddenWindows, On
		MouseGetPos,,,, control
		DetectHiddenWindows, Off
		ControlGet, selectedTab, Tab,, SysTabControl321, ahk_id %id%
		If (control == "SysTabControl321" || control == "msctls_updown321")	; Tab-bar (or it's scroll buttons) is hovered.
		{
			SendMessage, 0x1304,,, SysTabControl321, ahk_id %id%  ; ErrorLevel now contains number of tabs [0x1304 == TCM_GETITEMCOUNT].
			;{ Wrap tab-bar: scrolling doesn't stop at tab bar edges.
			If (A_ThisHotkey == "$WheelUp" && selectedTab == "1")	;
				SendMessage, 0x1330, ErrorLevel - 1,, SysTabControl321, ahk_id %id%  ; 0x1330 is TCM_SETCURFOCUS.
			Else If (A_ThisHotkey == "$WheelDown" && selectedtab == Errorlevel)
				SendMessage, 0x1330, 0,, SysTabControl321, ahk_id %id%  ; 0x1330 is TCM_SETCURFOCUS.
			;}
			Else
				Control, % "Tab" (A_ThisHotkey == "$WheelUp" ? "Left" : "Right"),, SysTabControl321, ahk_id %id%
		}
		Else If (control == "hh_kwd_vlist1")
		{
			ControlGet, hw_m_target, Hwnd,, hh_kwd_vlist1, ahk_id %id%
			PostMessage, 0x20A, (A_ThisHotkey == "$WheelUp") ? 120 << 16 : -120 << 16, (m_y << 16) | (m_x & 0xFFFF),, ahk_id %hw_m_target%
		}
		Else
			PostMessage, 0x20A, (A_ThisHotkey == "$WheelUp") ? 120 << 16 : -120 << 16, (m_y << 16) | (m_x & 0xFFFF),, ahk_id %hw_m_target%
	}
	;}
	;{ Miranda IM, TabSRMM window's tab-bar classNN: TSTabCtrlClass1	listener-window classNN: RichEdit20W1
	Else If (control == "TSTabCtrlClass1")
	{
		ControlGet, properTargetWin, Hwnd,, RichEdit50W1, ahk_id %id%
		PostMessage, 0x319, 0, (A_ThisHotkey == "$WheelUp") ? 0x10000 : 0x20000,, ahk_id %properTargetWin%
	}
	;}
	;{ AkelPad's tab bar
	Else If (class == "AkelPad4" && control == "SysTabControl321") || (class == "IEFrame" && control == "DirectUIHWND2")
		ControlSend,, % (A_ThisHotkey == "$WheelUp") ? ("{Ctrl Down}{Shift Down}{Tab}{Shift Up}{Ctrl Up}") : ("{Ctrl Down}{Tab}{Ctrl Up}"), ahk_id %id%
	;}
	;{ If the cursor hovers either an inactive window (and which is not the desktop) or the active window of Windows Explorer (so that we can scroll it's panes independently).
	Else If (id != idA && class != "Progman") || (id == idA && class == "CabinetWClass")
 	; {
 		PostMessage, 0x20A, (A_ThisHotkey == "$WheelUp") ? 120 << 16 : -120 << 16, (m_y << 16) | (m_x & 0xFFFF),, ahk_id %hw_m_target%
 		; PostMessage, 0x20A, (A_ThisHotkey == "$WheelUp") ? 120 << 16 : -120 << 16, (m_y << 16) | (m_x & 0xFFFF),, ahk_id %id%
	; }
	;}
	;{ If the cursor hovers the active window or desktop - the regular scrolling event should get sent to the active window.
	Else If (id == idA) || (class == "Progman")
	{
		If (A_ThisHotkey == "$WheelUp")
			Send, {WheelUp}
		Else
			Send, {WheelDown}
	}
	;}
	GoSub, CleanVars
Return
	;}
	;{ Middle mouse click on windows on taskbar to close them.
		;{ Bug1
			; 1. Middle click free space on taskbar (a prompt to switch off PC opens)
			; 2. Middle click that window on taskbar.
			; ER: it gets closed.
			; AR: it gets closed along with a next active window.
		;}
; ~MButton Up::
; 	MouseGetPos,,, ID, thisControl
; 	WinGetClass, class, % "ahk_id " ID
; 	If (class == "Shell_TrayWnd")	; Means user clicked somewhere on task bar.
; 	{
; 		Click
; 		WinClose, A
; 	}
; 	GoSub, CleanVars
; Return
	;}
	;{ Middle mouse click on active window's titlebar to copy it's title.
~MButton::
	MouseGetPos, m_x, m_y, hwnd
	SendMessage, 0x84, 0, (m_x&0xFFFF)|(m_y&0xFFFF)<<16,, ahk_id %Hwnd%
	If (ErrorLevel = 2)
	{
		WinGetTitle, title, ahk_id %Hwnd%
		Clipboard := title
	}
	GoSub, CleanVars
Return
	;}
	;{ Binds for mouse extra buttons (back, forward, copy, paste)
WheelLeft::Send, {Browser_Back}	; Go Back.
WheelRight::Send, {Browser_Forward}	; Go Forward.
XButton1::Send, ^{vk0x43sc0x2e}	; Copy (by sending Ctrl+C).
XButton2::Send, ^{vk0x56sc0x2f}	; Paste (by sending Ctrl+V).
	;}
	;{ "Excel" keyboard extra key to run/open/hide AkelPad
sc0x114::
	Process, Exist, AkelPad.exe
	If !ErrorLevel
		Run, C:\Soft\Portable soft\AkelPad\AkelPad.exe
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
	;}
	;{ "Word" keyboard extra key to run/open/hide Notepad++
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
	;}
	;{ "WWW" keyboard extra key to run AHK Toolkit
Browser_Home::Run, C:\Program Files\AutoHotkey\Scripts\DevTools\ToolKit\AHK-ToolKit.exe
	;}
	;{ "My Computer" keyboard extra key to open "My Computer"
Launch_App1::Send, #d
	;}
	;{ "Calculator" keyboard extra key to run "Calc.exe"
Launch_App2::Run, calc
	;}
	;{ Keyboard wheel click (extra button) to open AnVir
; sc0x123::	; Keyboard wheel click (extra button)
; 	IfWinNotExist, ahk_class AnVirMainFrame
; 	{
; 		Run, C:\Soft\Portable soft\AnvirTaskManager\AnVir.exe
; 		WinWait, ahk_class AnVirMainFrame
; 		WinActivate, ahk_class AnVirMainFrame
; 	}
; 	Else
; 	{
; 		IfWinActive, ahk_class AnVirMainFrame
; 			WinClose, ahk_class AnVirMainFrame
; 		Else
; 			WinActivate, ahk_class AnVirMainFrame
; 	}
; Return
; 	;}
; 	;{ LCTrl + keyboard wheel click to run/open/hide ScriptManager.ahk
; <^sc0x123::	;  Hold LCtrl & click keyboard wheel
; 	IfWinNotExist, Manage Scripts ahk_class AutoHotkeyGUI
; 	{
; 		Run, %A_AhkPath% "C:\Program Files\AutoHotkey\Scripts\In Development\MasterScript.ahk"
; 		WinWait, Manage Scripts ahk_class AutoHotkeyGUI
; 		WinActivate, Manage Scripts ahk_class AutoHotkeyGUI
; 	}
; 	Else
; 	{
; 		IfWinActive, Manage Scripts ahk_class AutoHotkeyGUI
; 			WinClose, Manage Scripts ahk_class AutoHotkeyGUI
; 		Else
; 			WinActivate, Manage Scripts ahk_class AutoHotkeyGUI
; 	}
; Return
	;}
#IfWinNotActive, Program Manager ahk_class Progman ahk_exe explorer.exe
	;{ Drag windows by any part of the window
; Hold XButton2 (mouse extra button) then hold left button and move the cursor while the left button is being held (you may release XButton2).
XButton2 & LButton::moveWinWithCursor("LButton")
	;}
	;{ Control transparency of a window under the cursor
XButton2 & WheelUp::
XButton2 & WheelDown::
	MouseGetPos,,, hwndUnderCursor
	WinGet, currOpacity, Transparent, ahk_id %hwndUnderCursor%
	If !(curropacity)
		currOpacity := 255
	currOpacity := (A_ThisHotkey == "XButton2 & WheelUp") ? currOpacity + 10 : currOpacity - 10
	currOpacity := (currOpacity < 25) ? 25 : (currOpacity >= 255) ? 255 : currOpacity
	WinSet, Transparent, %currOpacity%, ahk_id %hwndUnderCursor%
	GoSub, CleanVars
Return
	;}
	;{ Remove transparency of the window under the cursor
XButton2 & MButton::
	MouseGetPos,,, hwndUnderCursor
	WinSet, Transparent, 255, ahk_id %hwndUnderCursor%
	GoSub, CleanVars
Return
	;}
	;{ Remove/restore titlebar of the window under the cursor
XButton2 & WheelRight::
<#Space::
	MouseGetPos,,, hwndUnderCursor
	WinGet, Title, Style, ahk_id %hwndUnderCursor%
	If (Title & 0xC00000)
		WinSet, Style, -0xC00000, ahk_id %hwndUnderCursor%
	Else
		WinSet, Style, +0xC00000, ahk_id %hwndUnderCursor%
	; Redraw the window
	WinGetPos,,,, Height, ahk_id %hwndUnderCursor%
	WinMove, ahk_id %hwndUnderCursor%,,,,, % Height - 1
	WinMove, ahk_id %hwndUnderCursor%,,,,, % Height
	GoSub, CleanVars
Return
	;}
	;{ Pseudo-maximize the active window (LWin + LCtrl + s)
<#<^vk53::
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%Top, UA%winCenterIsOnMonN%Right - UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%Bottom - UA%winCenterIsOnMonN%Top
Return
	;}
	;{ Resize the active window	(LWin + LAlt + w/s/a/d)
<!<#vk57::	; Decrease height	(w).
	GoSub, WhatMonitor
	activeWinMoveResize(0, 0, 0, -UA%winCenterIsOnMonN%halfH / 8)
Return
<!<#vk53::	; Increase height	(s).
	GoSub, WhatMonitor
	activeWinMoveResize(0, 0, 0, UA%winCenterIsOnMonN%halfH / 8)
Return
<!<#vk41::	; Decrease width	(a).
	GoSub, WhatMonitor
	activeWinMoveResize(0, 0, -UA%winCenterIsOnMonN%halfW / 8, 0)
Return
<!<#vk44::	; Increase width	(d).
	GoSub, WhatMonitor
	activeWinMoveResize(0, 0, UA%winCenterIsOnMonN%halfW / 8, 0)
Return
	;}
	;{ Move the active window	(LWIn + LShift + w/s/a/d)
<+<#vk57::	; Move top	(w).
	GoSub, WhatMonitor
	activeWinMoveResize(0, -UA%winCenterIsOnMonN%halfH / 8, 0, 0)
Return
<+<#vk53::	; Move bottom	(s).
	GoSub, WhatMonitor
	activeWinMoveResize(0, UA%winCenterIsOnMonN%halfH / 8, 0, 0)
Return
<+<#vk41::	; Move left	(a).
	GoSub, WhatMonitor
	activeWinMoveResize(-UA%winCenterIsOnMonN%halfW / 8, 0, 0, 0)
Return
<+<#vk44::	; Move right	(d).
	GoSub, WhatMonitor
	activeWinMoveResize(UA%winCenterIsOnMonN%halfW / 8, 0, 0, 0)
Return
	;}
	;{ Quarter the active window	(LWin + LCtrl + q/e/z/c)
<#<^vk51::	; Top left	(q).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%Top, UA%winCenterIsOnMonN%halfW, UA%winCenterIsOnMonN%halfH
Return
<#<^vk45::	; Top right	(e).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%centerX, UA%winCenterIsOnMonN%Top, UA%winCenterIsOnMonN%halfW, UA%winCenterIsOnMonN%halfH
Return
<#<^vk5A::	; Bottom left	(z).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%centerY, UA%winCenterIsOnMonN%halfW, UA%winCenterIsOnMonN%halfH
Return
<#<^vk43::	; Bottom right	(c).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%centerX, UA%winCenterIsOnMonN%centerY, UA%winCenterIsOnMonN%halfW, UA%winCenterIsOnMonN%halfH
Return
	;}
	;{ Half the active window	(LWin + LCtrl + w/x/a/d)
<#<^vk57::	; Top	(w).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%Top, UA%winCenterIsOnMonN%Right - UA%winCenterIsOnMonN%Left, (UA%winCenterIsOnMonN%Bottom - UA%winCenterIsOnMonN%Top) / 2
Return
<#<^vk58::	; Bottom	(x).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%centerY, UA%winCenterIsOnMonN%Right - UA%winCenterIsOnMonN%Left, (UA%winCenterIsOnMonN%Bottom - UA%winCenterIsOnMonN%Top) / 2
Return
<#<^vk41::	; Left	(a).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%Left, UA%winCenterIsOnMonN%Top, (UA%winCenterIsOnMonN%Right - UA%winCenterIsOnMonN%Left) / 2, UA%winCenterIsOnMonN%Bottom - UA%winCenterIsOnMonN%Top
Return
<#<^vk44::	; Right	(d).
	GoSub, WhatMonitor
	WinMove, A,, UA%winCenterIsOnMonN%centerX, UA%winCenterIsOnMonN%Top, (UA%winCenterIsOnMonN%Right - UA%winCenterIsOnMonN%Left) / 2, UA%winCenterIsOnMonN%Bottom - UA%winCenterIsOnMonN%Top
Return
	;}
	;{ Minimize/restore the active window	(LWin + NumpadDel/NumpadDot)
<#NumpadDel::
<#NumpadDot::
	WinGet, currMinMax, MinMax, A
	If (currMinMax == -1)	; The active window is minimized.
		WinRestore, A
	Else
		WinMinimize, A
	currMinMax := ""
Return
	;}
;}
#IfWinNotActive
;{ Functions
	;{ For hotkeys
		;{ activeWinMoveResize(dx, dy, dw, dh)
; Moves, resizes or does both to the active window.
activeWinMoveResize(dx, dy, dw, dh)
{
	WinGetPos, X, Y, W, H, A
	WinMove, A,, (X + dx), (Y + dy), (W + dw), (H + dh)
}
		;}
		;{ getActiveWindowCenterCoords()
; Get the coordinates of the center of the active window.
getActiveWindowCenterCoords()
{
	WinGetPos, x, y, w, h, A
	Return, [(w // 2) + x, (h // 2) + y]
}
		;}
		;{ moveWinWithCursor(buttonHeld)
moveWinWithCursor(buttonHeld)
{
	SetWinDelay, 0
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
		Sleep, 15
	}
}
		;}
	;}
;}
;{ Labels

	;{ AddMenu & ShowMenu
; Open context menu via single left click on script's tray icon.
AddMenu:	; Add menuitem and make it default (bind to left click)
	Menu, Tray, Add, ShowMenu		; Add temporary menu item.
	Menu, Tray, Default, ShowMenu	; Set it to be default (it gets executed (or opened) just when you left click the tray icon).
Return

; Remove the created menuitem and show the normal menu. Then add the menuitem back The temporary menu item that 
ShowMenu:
	Menu, Tray, Delete, ShowMenu	; If we don't delete that temporary menu item we created - it will be displayed in the tray icon's context menu and since clicking on it would just reopen the very same menu - we don't need it to be displayed, so we delete it.
	MouseGetPos, MouseX, MouseY
	Menu, Tray, Show, %MouseX%, % MouseY - 15	; By default context menu gets opened at cursor's position and to let user be able to double click the tray icon - we move this menu a 15px higher.
	GoSub, AddMenu	; We have to restore the deleted menu item for later use.
Return
	;}
	;{ CleanVars
CleanVars:
	currOpacity := hwndUnderCursor := x1 := y1 := winClass := maximized := winX1 := winY1 := x2 := y2 := winX2 := winY2 := ID := IDactive := control := key := value := Class := classA := properTargetWin := Hwnd := Height := m_x := m_y := hw_m_target := onTop := procName := XWin := YWin := title := ""
Return
	;}
	;{ WhatMonitor
; Define on what monitor lays the center of the active window.
WhatMonitor:
	centerCoord := getActiveWindowCenterCoords()
	Loop, %monCount%
	{
		If (monCount == "1") || (monCount == A_Index) || (((mon%A_Index%Left < centerCoord[1]) && (centerCoord[1] < mon%A_Index%Right)) && ((mon%A_Index%Top < centerCoord[2]) && (centerCoord[2] < mon%A_Index%Bottom)))
		{
			winCenterIsOnMonN := A_Index
			Break
		}
	}
Return
	;}
;}
;{ Per-application rules
	;{ Firefox (Zoom control)
#IfWinActive, ahk_class MozillaWindowClass
XButton1 & WheelUp::Send, ^{+}
XButton1 & WheelDown::Send, ^{-}
Xbutton1 & MButton::Send, ^0
#IfWinActive
	;}
	;{ Media Player Classic - Home Cinema	(Bind extra mouxe buttons to work as prev./next)
#IfWinActive, ahk_class MediaPlayerClassicW
XButton1::Send, {Media_Prev}
XButton2::Send, {Media_Next}
#IfWinActive
	;}
;}