/* Get SC and VK codes
Version: 1
Timestamp: 2012.04.30 21:32:24
Compatible with: AHK_L x32U, AHK_L x64 (else?)
Source: http://forum.script-coding.com/viewtopic.php?id=5690
Author: teadrinker
Contacts:
	e-mail: dfiveg@mail.ru
	Skype: dmitry_fiveg
The initial code was re-styled and translated into english (but it's functionaly was not modified) by Drugoy.
*/
Menu, Tray, Icon, Shell32.dll, 45

; Extra pad's keys and Pause. Those keys' SCs can't be detected by MapVirtualKey function.
ScVk := "45,13|11D,A3|135,6F|136,A1|137,2C|138,A5|145,90|147,24|148,26|149,21|"
. "14B,25|14D,27|14F,23|150,28|151,22|152,2D|153,2E|15B,5B|15C,5C|15D,5D"

; Mouse keys and their VKs. Also Ctrl+Break and Clear.
KeysVK := "LButton,1|RButton,2|Ctrl+Break,3|MButton,4|XButton1,5|XButton2,6|"
. "Clear,c|Shift,10|Ctrl,11|Alt,12"

Height := 165 ; The height of UI (excluding tabs' titles).

Gui, +AlwaysOnTop
Gui, Color, DAD6CA
Gui, Add, Tab2, vTab gTab x0 y0 w200 h185 AltSubmit hwndhTab, Get code|The key by code
Tab = 2
VarSetCapacity(RECT, 16)
SendMessage, TCM_GETITEMRECT := 0x130A, 1, &RECT,, ahk_id %hTab%
TabH := NumGet(RECT, 12, "UInt")
GuiControl, Move, Tab, % "x0 y0 w200 h" TabH + Height
Gui, Add, Text, % "x8 y" TabH + 8 " w183 +" SS_GRAYFRAME := 0x8 " h" Height - 16

Gui, Font, q5 s12, Verdana
Gui, Add, Text, vAction x15 yp+7 w170 Center c0033BB, Press a key
Gui, Add, Text, vKey xp yp+35 wp Center Hidden

Gui, Font, q5 c333333
Gui, Add, Text, vTextVK xp+8 yp+37 Hidden, vk =
Gui, Add, Text, vVK xp+35 yp w62 h23 Center Hidden
Gui, Add, Text, vTextSC xp-35 yp+35 Hidden, sc =
Gui, Add, Text, vSC xp+35 yp w62 h23 Center Hidden

Gui, Font, s8
Gui, Add, Button, vCopyVK gCopy xp+70 yp-35 w50 h22 Hidden, Copy
Gui, Add, Button, vCopySC gCopy xp yp+33 wp hp Hidden, Copy

Gui, Tab, 2
Gui, Add, Text, % "x8 y" TabH + 8 " w183 +" SS_GRAYFRAME " h" Height - 16
Gui, Add, Text, x15 yp+7 w170 c0033BB
, Write in the code`nin hex format without "0x" prefix

Gui, Font, q5 s11
Gui, Add, Text, xp yp+58, vk
Gui, Add, Edit, vEditVK gGetKey xp+25 yp-2 w45 h23 Limit3 Uppercase Center
Gui, Add, Text, vKeyVK xp+45 yp+2 w105 Center

Gui, Add, Text, x15 yp+43, sc
Gui, Add, Edit, vEditSC gGetKey xp+25 yp-2 w45 h23 Limit3 Uppercase Center
Gui, Add, Text, vKeySC xp+45 yp+2 w105 Center
Gui, Show, % "w199 h" TabH + Height - 1, Keys codes

hHookKeybd := SetWindowsHookEx()
OnExit, Exit
OnMessage(0x6, "WM_ACTIVATE")
OnMessage(0x102, "WM_CHAR")
Return

Tab:	; Whenever the user switches to a new tab, the output variable will be set to the previously selected tab number in the case of AltSubmit.
	If (Tab = 2 && !hHookKeybd)
		hHookKeybd := SetWindowsHookEx()
	Else If (Tab = 1 && hHookKeybd)
		DllCall("UnhookWindowsHookEx", UInt, hHookKeybd), hHookKeybd := ""
Return

Copy:
	GuiControlGet, Code,, % SubStr(A_GuiControl, -1)
	StringLower, GuiControl, A_GuiControl
	Clipboard := SubStr(GuiControl, -1) SubStr(Code, 3)
Return

GetKey:
	GuiControlGet, Code,, % A_GuiControl
	Code := RegExReplace(Code, "^0+")
	Code := "0x" Code
	SetFormat, IntegerFast, H
	If A_GuiControl = EditVK
	{
		If (Code > 0xA5 && Code < 0xBA)
			Key := "", IsKey := 1
		Loop, parse, KeysVK, |
		{
			If (Substr(Code, 3) = RegExReplace(A_LoopField, ".*,(.*)", "$1"))
			{
				Key := RegExReplace(A_LoopField, "(.*),.*", "$1")
				IsKey = 1
				Break
			}
		}
		If !IsKey
		{
			Loop, parse, ScVk, |
			{
				If (Code = "0x" . RegExReplace(A_LoopField, ".*,(.*)", "$1"))
				{
					Code := RegExReplace(A_LoopField, "(.*),.*", "0x$1")
					IsCode = 1
					Break
				}
			}
			If !IsCode
				Code := DllCall("MapVirtualKey", UInt, Code, UInt, MAPVK_VK_TO_VSC := 0)
		}
	}
	Else If (Code = 0x56 || Code > 0x1FF)
		Key := "", IsKey := 1
	If !IsKey
		Key := GetKeyNameText(Code)
	Key := RegExReplace(Key, "(.*)Windows", "$1Win")
	GuiControl,, % "Key" SubStr(A_GuiControl, -1), % Key
	Key := IsKey := IsCode := ""
Return

GuiClose:
ExitApp

Exit:
	If hHookKeybd
		DllCall("UnhookWindowsHookEx", Ptr, hHookKeybd)
ExitApp

WM_ACTIVATE(wp)
{
	Global
	If (wp & 0xFFFF = 0 && hHookKeybd)
		DllCall("UnhookWindowsHookEx", UInt, hHookKeybd), hHookKeybd := ""
	If (wp & 0xFFFF && Tab = 2 && !hHookKeybd)
		hHookKeybd := SetWindowsHookEx()
	GuiControl,, Action, % wp & 0xFFFF = 0 ? "Activate the window" : "Press a key"
}

SetWindowsHookEx()
{
	Return DllCall("SetWindowsHookEx" . (A_IsUnicode ? "W" : "A")
	, Int, WH_KEYBOARD_LL := 13
	, Ptr, RegisterCallback("LowLevelKeyboardProc", "Fast")
	, Ptr, DllCall("GetModuleHandle", UInt, 0, Ptr)
	, UInt, 0, Ptr)
}

LowLevelKeyboardProc(nCode, wParam, lParam)
{
	Static once, WM_KEYDOWN = 0x100, WM_SYSKEYDOWN = 0x104
	
	Critical
	SetFormat, IntegerFast, H
	vk := NumGet(lParam+0, "UInt")
	Extended := NumGet(lParam+0, 8, "UInt") & 1
	sc := (Extended<<8)|NumGet(lParam+0, 4, "UInt")
	sc := sc = 0x136 ? 0x36 : sc
	Key := GetKeyNameText(sc)
	
	If (wParam = WM_SYSKEYDOWN || wParam = WM_KEYDOWN)
	{
		GuiControl,, Key, % Key
		GuiControl,, VK, % vk
		GuiControl,, SC, % sc
	}
	
	If !once
	{
		Controls := "Key|TextVK|VK|TextSC|SC|CopyVK|CopySC"
		Loop, Parse, Controls, |
			GuiControl, Show, % A_LoopField
		once = 1
	}
	
	If Key Contains Ctrl,Alt,Shift,Tab
		Return CallNextHookEx(nCode, wParam, lParam)
	
	If (Key = "F4" && GetKeyState("Alt", "P"))	; Window closure or "Alt+F4" escape.
		Return CallNextHookEx(nCode, wParam, lParam)
	
	Return nCode < 0 ? CallNextHookEx(nCode, wParam, lParam) : 1
}

CallNextHookEx(nCode, wp, lp)
{
	Return DllCall("CallNextHookEx", Ptr, 0, Int, nCode, UInt, wp, UInt, lp)
}

GetKeyNameText(sc)
{
	VarSetCapacity(Key, A_IsUnicode ? 32 : 16)
	DllCall("GetKeyNameText" . (A_IsUnicode ? "W" : "A"), UInt, sc<<16, Str, Key, UInt, 16)
	If Key in Shift,Ctrl,Alt
		Key := "Left " Key
	Return Key
}

WM_CHAR(wp)
{
	global hBall
	SetWinDelay, 0
	CoordMode, Caret
	WinClose, ahk_id %hBall%
	GuiControlGet, Focus, Focus
	If !InStr(Focus, "Edit")
		Return
	
	If wp in 3,8,24,26	; "Ctrl+C", "Ctrl+X", "Ctrl+Z" and BackSpace handling.
		Return
	
	If wp = 22	; "Ctrl+V" handling.
	{
		GuiControlGet, Content,, % Focus
		If !StrLen(String := SubStr(Clipboard, 1, 3 - StrLen(Content)))
		{
			ShowBall("Clipboard doesn't contain any text.", "Error!")
			Return 0
		}
		Loop, parse, String
		{
			Text .= A_LoopField
			If A_LoopField not in 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,A,B,C,D,E,F
			{
				ShowBall("The clipboard contains invalid chars."
				. "`nValid chars:`n0123456789ABCDEF", "Error!")
				Return 0
			}
		}
		Control, EditPaste, % Text, % Focus, Keys codes
		Return 0
	}
	
	Char := Chr(wp)
	If Char not in 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,A,B,C,D,E,F
	{
		ShowBall("Valid chars:`n0123456789ABCDEF", Char " — is an invalid char")
		Return 0
	}
	Return
}

ShowBall(Text, Title="")
{
	global
	WinClose, ahk_id %hBall%
	hBall := BalloonTip(A_CaretX+1, A_CaretY+15, Text, Title)
	SetTimer, BallDestroy, -2000
	Return
	
	BallDestroy:
		WinClose, ahk_id %hBall%
	Return
}

BalloonTip(x, y, sText, sTitle = "", h_icon = 0)
{
	; BalloonTip (a ToolTip pointing to the tray icon).
	; h_icon — 0: None, 1: Info, 2: Warning, 3: Error, n>3: hIcon is expected.
	
	TTS_NOPREFIX := 2, TTS_ALWAYSTIP := 1, TTS_BALLOON := 0x40, TTS_CLOSE := 0x80
	
	hWnd := DllCall("CreateWindowEx", UInt, WS_EX_TOPMOST := 8
	, Str, "tooltips_class32", Str, ""
	, UInt, TTS_NOPREFIX|TTS_ALWAYSTIP|TTS_BALLOON|TTS_CLOSE
	, Int, 0, Int, 0, Int, 0, Int, 0
	, UInt, 0, UInt, 0, UInt, 0, UInt, 0)
	
	NumPut(VarSetCapacity(TOOLINFO, A_PtrSize = 4 ? 48 : 72, 0), TOOLINFO, "UInt")
	NumPut(0x20, TOOLINFO, 4, "UInt") ; TTF_TRACK = 0x20
	NumPut(&sText, TOOLINFO, A_PtrSize = 4 ? 36 : 48, "UInt")
	
	A_DHW := A_DetectHiddenWindows
	DetectHiddenWindows, On
	WinWait, ahk_id %hWnd%
	
	WM_USER := 0x400
	SendMessage, WM_USER + 24,, w ; TTM_SETMAXTIPWIDTH
	SendMessage, WM_USER + (A_IsUnicode ? 50 : 4),, &TOOLINFO ; TTM_ADDTOOL
	SendMessage, WM_USER + (A_IsUnicode ? 33 : 32), h_icon, &sTitle ; TTM_SETTITLEA è TTM_SETTITLEW
	SendMessage, WM_USER + (A_IsUnicode ? 57 : 12),, &TOOLINFO ; TTM_UPDATETIPTEXTA è TTM_UPDATETIPTEXTW
	SendMessage, WM_USER + 18,, x|(y<<16) ; TTM_TRACKPOSITION
	SendMessage, WM_USER + 17, 1, &TOOLINFO ; TTM_TRACKACTIVATE
	
	DetectHiddenWindows, % A_DHW
	Return hWnd
}