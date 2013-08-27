/* DrugWinManager v2.0

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/DrugWinManager

Description:
	Lets you scroll over tab-bars to switch tabs, lets you scroll inactive windows (without activating them) and adds a bunch of hotkeys that help manage windows.

	I use mouse "Logitech M510" and keyboard "Genius Comfy KB-21e scroll" and each has extra buttons: that mouse has a wheel that can be turned left and right and it also has two extra buttons (XButton1 and XButton2) and the keyboard has lots of extra buttons.

	The script has the following functions:
1. Scroll over inactive windows to scroll them without their activation;
2. Scroll over tab bar to switch tabs in Notepad++, AkelPad, Miranda's TabSRMM and Internet Explorer;
3. Adds hotkeys and key combos that use both keyboard and mouse and their extra buttons:
	1. Hit "left WinKey + `" to toggle "always on top" attribute for the active window;
	2. Hold XButton2 and hit WheelLeft (on the mouse) to toggle "always on top" attribute for the window under cursor (without activating it);
	3. Hitting WheelLeft/WheelRight (on the mouse) works as going back/forward (correspondingly) in the history of browsers and in Windows Explorer;
	4. Hit "XButton1" to copy (sends Ctrl+C);
	5. Hit "XButton2" to paste (sends Ctrl+V);
	6. Hit "Excel" key to run AkelPad, activate it or hide;
	7. Hit "Word" key to run Notepad++ Portable, activate it or hide;
	8. Hit "WWW" key to run AHK Toolkit;
	9. Hit "My Computer" key to minimize all (bring desktop to front) and to undo that;
	10. Hit "Calculator" key to run calc;
	11. Hit keyboard "wheel" (extra button) to run AnVirTM, activate it or hide;
	12. Hit "left Ctrl + keyboard wheel" to run ScriptManager.ahk, activate it or hide;
	13. Ho	ld XButton2, then hold Left Mouse Button and then drag the mouse (while Left Mouse Button is being held) to move the window under cursor (and if it was inactive - it stays inactive);
	14. Hold XButton2 and scroll Mouse Wheel Up/Down to increase/decrease the opacity of the window under cursor;
	15. Hold XButton2 and hit Mouse Middle Button to remove transparency from the window under cursor;
	16. Hit "left WinKey + Space" to remove/restore the titlebar of the active window;
	17. Hold XButton2 and hit WheelRight (on the mouse) to remove/restore the titlebar of the window under cursor;
	18. Hit "left WinKey + left Ctrl + s" to pseudo-maximize the active window (the window doesn't actually become maximized, but gets resized as if it was);
	19. Hit "left WinKey + left Alt + w/s/a/d" to resize the active window: decrease height/increase height/decrease width/increase width (correspondingly);
	20. Hit "left WinKey + left Shift + w/s/a/d" to move the active window top/bottom/left/right;
	21. Hit "left WinKey + left Ctrl + q/e/z/c" to make the active window occupy top_left/top_right/bottom_left/bottom_right quarter of the "usable area" (desktop area minus Windows' taskbar area);
	22. Hit "left WinKey + left Ctrl + w/x/a/d" to make the active window occupy top/bottom/left/right part of the "usable area".
4. Application-specific hotkeys
	Firefox:
		a. Hold XButton1 and scroll Mouse Wheel Up/Down to increase/decrease to zoom page in/out;
		b. Hold XButton1 and hit Middle Mouse Button to reset page's zoom level.
	Media Player Classic - Home Cinema:
		a. Xbutton1 and Xbutton2 respectively switch to the previous and next videos.
*/
;{ Initialization
#SingleInstance, Force
SetWinDelay, 0
SendMode Input	; Recommended For new scripts due to its superior speed and reliability.
#NoEnv	; Recommended For performance and compatibility with future AutoHotkey releases.
CoordMode, Mouse, Screen	; By default all coordinates are relative to the active window, changing them to be related to screen is required for proper work of some script's commands.
SysGet, UA, MonitorWorkArea	; Getting Usable Area info.
OnExit, Exit	; Remove hooks upon exit.
; Defining variables' values for later use.
UAcenterX := UALeft + (UAhalfW := (UALeft + UARight) / 2)
UAcenterY := UATop + (UAhalfH := (UATop + UABottom) / 2)
; Bind left click on tray icon to open menu like If you right clicked it.
Menu Tray, Click, 1	; Enable single click action on tray.
Gosub, AddMenu		; Add new default menu.
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
	Gosub, CleanVars
Return
	;}
	;{ Scroll inactive windows without activating them
; Tab Wheel Scroll For Notepad++, Miranda IM (TabSRMM), AkelPad and Internet Explorer.
; Can't do the same For Google Chrome and Mozilla Firefox.
$WheelUp::
$WheelDown::
	MouseGetPos, m_x, m_y, id, control, 1
	hw_m_target := DllCall("WindowFromPoint", "int", m_x, "int", m_y)
	WinGetClass, class, ahk_id %id%
	WinGetClass, classA, A
	If (class == "Notepad++") && (control == "SysTabControl325")	; Notepad++: ahk_class Notepad++	tab-bar classNN: SysTabControl325	listener-window classNN: Scintilla1
	{
		ControlGet, properTargetWin, Hwnd,, Scintilla1, ahk_id %id%
		PostMessage 0x319, 0, (A_ThisHotkey == "$WheelUp") ? 0x10000 : 0x20000,, ahk_id %properTargetWin%
	}
	Else If (control == "TSTabCtrlClass1")	; Miranda IM, TabSRMM window's tab-bar classNN: TSTabCtrlClass1	listener-window classNN: RichEdit20W1
	{
		ControlGet, properTargetWin, Hwnd,, RichEdit20W1, ahk_id %id%
		PostMessage 0x319, 0, (A_ThisHotkey == "$WheelUp") ? 0x10000 : 0x20000,, ahk_id %properTargetWin%
	}
	Else If (class == "AkelPad4" && control == "SysTabControl321") || (class == "IEFrame" && control == "DirectUIHWND2")	; AkelPad
		ControlSend,, % (A_ThisHotkey == "$WheelUp") ? ("{Ctrl Down}{Shift Down}{Tab}{Shift Up}{Ctrl Up}") : ("{Ctrl Down}{Tab}{Ctrl Up}"), ahk_id %id%
	Else If (class != classA) && (class != "Progman")	; If the cursor hovers an inactive window (and which is not the desktop) - that inactive window should receive a scrolling event (without the activation of that window).
		PostMessage, 0x20A, (A_ThisHotkey == "$WheelUp") ? 120 << 16 : -120 << 16, ( m_y << 16 )|m_x,, ahk_id %hw_m_target%
	Else If (class == classA) || (class == "Progman")	; If the cursor hovers the active window or desktop - the regular scrolling event should get sent to the active window.
	{
		If (A_ThisHotkey == "$WheelUp")
			Send {WheelUp}
		Else
			Send {WheelDown}
	}
	Gosub, CleanVars
Return
	;}
	;{ Binds for mouse extra buttons (back, forward, copy, paste)
WheelLeft::Send {Browser_Back}	; Go Back.
WheelRight::Send {Browser_Forward}	; Go Forward.
XButton1::Send ^{vk0x43sc0x2e}	; Copy (by sending Ctrl+C).
XButton2::Send ^{vk0x56sc0x2f}	; Paste (by sending Ctrl+V).
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
sc0x123::	; Keyboard wheel click (extra button)
	IfWinNotExist, ahk_class AnVirMainFrame
	{
		Run, C:\Soft\Portable soft\AnvirTaskManager\AnVir.exe
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
	;}
	;{ LCTrl + keyboard wheel click to run/open/hide ScriptManager.ahk
<^sc0x123::	;  Hold LCtrl & click keyboard wheel
	IfWinNotExist, Manage Scripts ahk_class AutoHotkeyGUI
	{
		Run, %A_AhkPath% "C:\Program Files\AutoHotkey\Scripts\In Development\MasterScript.ahk"
		WinWait, Manage Scripts ahk_class AutoHotkeyGUI
		WinActivate, Manage Scripts ahk_class AutoHotkeyGUI
	}
	Else
	{
		IfWinActive, Manage Scripts ahk_class AutoHotkeyGUI
			WinClose, Manage Scripts ahk_class AutoHotkeyGUI
		Else
			WinActivate, Manage Scripts ahk_class AutoHotkeyGUI
	}
Return
	;}
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
Gosub, CleanVars
Return
	;}
	;{ Remove transparency of the window under the cursor
XButton2 & MButton::
MouseGetPos,,, hwndUnderCursor
WinSet, Transparent, 255, ahk_id %hwndUnderCursor%
Gosub, CleanVars
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
Gosub, CleanVars
Return
	;}
	;{ Pseudo-maximize the active window (LWin + LCtrl + s)
<#<^vk53::WinMove, A,, UALeft, UATop, UARight - UALeft, UABottom - UATop
	;}
	;{ Resize the active window	(LWin + LAlt + w/s/a/d)
<!<#vk57::activeWinMoveResize(0, 0, 0, -UAhalfH / 8)	; Decrease height	(w).
<!<#vk53::activeWinMoveResize(0, 0, 0, UAhalfH / 8)	; Increase height	(s).
<!<#vk41::activeWinMoveResize(0, 0, -UAhalfW / 8, 0)	; Decrease width	(a).
<!<#vk44::activeWinMoveResize(0, 0, UAhalfW / 8, 0)	; Increase width	(d).
	;}
	;{ Move the active window	(LWIn + LShift + w/s/a/d)
<+<#vk57::activeWinMoveResize(0, -UAhalfH / 8, 0, 0)	; Move top		(w).
<+<#vk53::activeWinMoveResize(0, UAhalfH / 8, 0, 0)	; Move bottom	(s).
<+<#vk41::activeWinMoveResize(-UAhalfW / 8, 0, 0, 0)	; Move left		(a).
<+<#vk44::activeWinMoveResize(UAhalfW / 8, 0, 0, 0)	; Move right	(d).
	;}
	;{ Quarter the active window	(LWin + LCtrl + q/e/z/c)
<#<^vk51::WinMove, A,, UALeft, UATop, UAcenterX, UAcenterY			; Top left		(q).
<#<^vk45::WinMove, A,, UAcenterX, UATop, UAcenterX, UAcenterY		; Top right		(e).
<#<^vk5A::WinMove, A,, UALeft, UAcenterY, UAcenterX, UAcenterY		; Bottom left	(z).
<#<^vk43::WinMove, A,, UAcenterX, UAcenterY, UAcenterX, UAcenterY	; Bottom right	(c).
	;}
	;{ Half the active window	(LWin + LCtrl + w/x/a/d)
<#<^vk57::WinMove, A,, UALeft, UATop, UARight - UALeft, UAcenterY		; Top		(w).
<#<^vk58::WinMove, A,, UALeft, UAcenterY, UARight - UALeft, UAcenterY	; Bottom	(x).
<#<^vk41::WinMove, A,, UALeft, UATop, UAcenterX, UABottom - UATop		; Left		(a).
<#<^vk44::WinMove, A,, UAcenterX, UATop, UAcenterX, UABottom - UATop	; Right		(d).
	;}
;}
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
		;{ moveWinWithCursor(buttonHeld)
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
		;}
	;}
;}
;{ Labels

	;{ AddMenu & ShowMenu
; Open context menu via single left click on script's tray icon.
AddMenu:	; Add menuitem and make it default (bind to left click)
	Menu Tray, Add, ShowMenu		; Add temporary menu item.
	Menu Tray, Default, ShowMenu	; Set it to be default (it gets executed (or opened) just when you left click the tray icon).
Return

; Remove the created menuitem and show the normal menu. Then add the menuitem back The temporary menu item that 
ShowMenu:
	Menu Tray, Delete, ShowMenu	; If we don't delete that temporary menu item we created - it will be displayed in the tray icon's context menu and since clicking on it would just reopen the very same menu - we don't need it to be displayed, so we delete it.
	MouseGetPos MouseX, MouseY
	Menu Tray, Show, %MouseX%, % MouseY - 15	; By default context menu gets opened at cursor's position and to let user be able to double click the tray icon - we move this menu a 15px higher.
	Gosub, AddMenu	; We have to restore the deleted menu item for later use.
Return
	;}
	;{ CleanVars
CleanVars:
	currOpacity := hwndUnderCursor := x1 := y1 := id := winClass := maximized := winX1 := winY1 := x2 := y2 := winX2 := winY2 := ID := IDactive := control := key := value := Class := classA := properTargetWin := Hwnd := Height := m_x := m_y := hw_m_target := onTop := procName := XWin := YWin := ""
Return
	;}
	;{ Exit
; Removing hooks upon exit.
Exit:
	DllCall("UnhookWinEvent", Ptr, HWINEVENTHOOK1)
	DllCall("UnhookWinEvent", Ptr, HWINEVENTHOOK2)
	; Removing WS_EX_TOPMOST from every window we set it earlier.
	; For k, v in GUIs
		; WinSet, AlwaysOnTop, Off, % "ahk_id" v.Parent
	GUIs := ""
	ExitApp
	;}
;}
;{ Per-application rules
	;{ Firefox (Zoom control)
#IfWinActive ahk_class MozillaWindowClass
XButton1 & WheelUp::Send ^{+}
XButton1 & WheelDown::Send ^{-}
Xbutton1 & MButton::Send ^0
#IfWinActive
	;}
	;{ Media Player Classic - Home Cinema	(Bind extra mouxe buttons to work as prev./next)
#IfWinActive ahk_class MediaPlayerClassicW
XButton1::Send {Media_Prev}
XButton2::Send {Media_Next}
#IfWinActive
	;}
;}