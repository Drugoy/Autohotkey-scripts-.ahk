
Version = v1.76
 ; Автор - serzh82saratov
 ; Тема - http://forum.script-coding.com/viewtopic.php?pid=72244#p72244
 ; Коллекция - http://forum.script-coding.com/viewtopic.php?pid=72459#p72459

#NoTrayIcon
#SingleInstance force
#ErrorStdOut
DetectHiddenWindows, on
Menu, Tray, Icon, Shell32.dll, 56
SetBatchLines -1

Global HF_SCCode, hGui, hEdit_Win, Copy, I, Paste_P_Buttons := "Wait press button..."
	, Title2 := "     (Shift+Tab - Freeze AhkSpy || RButton - CopySelected)     " Version
		;		Переменные настроек
	, wKey := 125			;    Ширина кнопок - 125
	, D := Chr(0x25aa)		;    Символ разделителя параметров - Chr(0x25aa)    (только для Unicode интерпретатора)
	, Timer := "B_Mouse"	;    Стартовая подпрограмма - B_Win|B_Mouse|B_Buttons
	, SpotActiveWin := 0	;    0 - если нужны данные об окне под курсором. 1 - данные об активном окне
	, AltEsc := 0			;    0 - чтобы при нажатии кнопок режимов не деактивировать окно. 1 - деактивировать

SysGet, SM_CYMINSPACING, 48
sFont := SM_CYMINSPACING = 32 ? 7 : 9

Gui Font, s%sFont%, Verdana
Gui, +AlwaysOnTop +HWNDhGui +ReSize
Gui, Add, Button, x8 y0 h%SM_CYMINSPACING% w%wKey% gB_Win, Window
Gui, Add, Button, x+0 yp hp wp gB_Mouse, Mouse && Control
Gui, Add, Progress, x+0 yp hp w%SM_CYMINSPACING% vColorProgress cWhite, 100
Gui, Add, Button, x+0 yp hp w%wKey% gB_Buttons, Button
Gui, Add, Edit, x0 y+0 r28 HScroll -Wrap t10 vEdit_Win HWNDhEdit_Win
Gui Show, NA
Gui, +MinSize
Loop 25
	I .= D
Gosub %Timer%
Gui, Add, Link, % "x" wKey*4 " y" SM_CYMINSPACING * 0.25
	, <a href="http://forum.script-coding.com/viewtopic.php?pid=72459#p72459">Have questions?</a>
Return

	; _________________________________________________ Hotkey _________________________________________________

Pause::
	Pause,,1
	Gui Color, , % A_IsPaused ? "D4D0C8" : "Default"
	Return

+Tab::
	Gosub S_Mouse
	Gosub S_Win
	Gosub, % Timer = "P_Win" ? "P_WinView" : "P_MouseView"
	WinActivate ahk_id %hGui%
	Return

#If WinActive("ahk_id " hGui) && MyCondition()
RButton::
	Copy := Clipboard := RegExReplace(Copy, "(^\s+|\s+$|\R?" D "+\R?)")
	SendMessage, 0xC, 0, &Copy, , ahk_id %hGui%
	SetTimer TitleShow, -1000
;	PostMessage,0x00B1,-1,,, ahk_id %hEdit_Win%    ;    EM_SETSEL - Снимает выделение после копирования.
	Return
TitleShow:
	SendMessage, 0xC, 0, &Title, , ahk_id %hGui%
	Return
#If

MyCondition()    {
	ControlGet, Copy, Selected, , , ahk_id %hEdit_Win%
	If Copy is space
		Return 0
	Return 1
}
	; _________________________________________________ Window _________________________________________________

B_Win:
	SetTimer %Timer%, Off
	SetTimer P_Win, 100
	Timer := "P_Win" , Pr_Paste_P_Win := ""
	If IsHotkeyUserFunc = 1
		HF_HotkeyUserFunc("Off"), IsHotkeyUserFunc := ""
	Gui Show, NA, % Title := "AhkSpy - Window" Title2
	If A_GuiControl && AltEsc
		Send !{Esc}
	Gosub P_WinView
	Return

P_Win:
	If WinActive("ahk_id " hGui) || Sleep = 1
	{
		Pr_Paste_P_Win := ""
		Return
	}
	Gosub S_Win
	Gosub P_WinView
	Return

S_Win:
	If SpotActiveWin = 1
		WinGet, WinID, ID, A
	Else
	{
		MouseGetPos,,, WinID
		If (WinID = hGui)
			Return
	}
	WinGetTitle, GetWinTitle, ahk_id %WinID%
	WinGetPos, GetWinX, GetWinY, GetWinWidth, GetWinHeight, ahk_id %WinID%
	WinGetClass, GetWinClass, ahk_id %WinID%
	WinGet, WinProcessName, ProcessName, ahk_id %WinID%
	WinGet, WinProcessPath, ProcessPath, ahk_id %WinID%
	Loop, %WinProcessPath%
		WinProcessPath = %A_LoopFileLongPath%
	WinGet, WinPID, PID, ahk_id %WinID%
	WinGet, WinCountProcess, Count, ahk_pid %WinPID%
	WinGet, WinStyle, Style, ahk_id %WinID%
	WinGet, WinExStyle, ExStyle, ahk_id %WinID%

	GetClientSize(WinID, ClientWidth, ClientHeight) , GetClientPos(WinID, caWinX, caWinY)
	caWinRight := GetWinWidth - ClientWidth - caWinX , caWinBottom := GetWinHeight - ClientHeight - caWinY

	StatusBarText =
	Loop
	{
		StatusBarGetText, StatusBarGetText, %A_Index%, ahk_id %WinID%
		If StatusBarGetText =
			Break
		StatusBarText = %StatusBarText%(%A_Index%): %StatusBarGetText%`n
	}
	StatusBarText := RTrim(StatusBarText, "`n")
	WinGetText, VisibleWinText, ahk_id %WinID%
	VisibleWinText := SubStr(VisibleWinText, 1, 2000) 
	CoordMode, Mouse
	CoordMode, Pixel
	MouseGetPos, WinXS, WinYS
	PixelGetColor, RGBMouse, %WinXS% , %WinYS% , RGB
	GuiControl, -Redraw, ColorProgress
	GuiControl, % "+c" sRGBMouse := SubStr(RGBMouse, 3), ColorProgress
	GuiControl, +Redraw, ColorProgress
	Return

P_WinView:
	Paste_P_Win =
	( Ltrim
		%I% ( Title ) %I%%I%%I%%I%%D%%D%%D%%D%%D%
		%GetWinTitle%
		%I% ( Class ) %I%%I%%I%%I%%D%%D%%D%
		ahk_class %GetWinClass%
		%I% ( ProcessName ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		ahk_exe %WinProcessName%
		%I% ( ProcessPath ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		%WinProcessPath%
		%I% ( Window Position ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		x%GetWinX% y%GetWinY% w%GetWinWidth% h%GetWinHeight%     ||     %GetWinX%, %GetWinY%, %GetWinWidth%, %GetWinHeight%
		Client area size: width %ClientWidth% height %ClientHeight%     top %caWinY% left %caWinX% bottom %caWinBottom% right %caWinRight%
		%I% ( Other ) %I%%I%%I%%I%%D%%D%%D%
		PID "%WinProcessName%": %WinPID%     ||     Count window this PID: %WinCountProcess%
		Style: %WinStyle%     ||     ExStyle: %WinExStyle%     ||     Win ID : ahk_id %WinID%
		%I% ( StatusBarText ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		%StatusBarText%
		%I% ( Visible Window Text ) %I%%I%%I%%D%%D%%D%%D%%D%
		%VisibleWinText%
		%I%%I%%I%%I%%I%%I%
	)
	If (Pr_Paste_P_Win <> Paste_P_Win)
		GuiControl,, Edit_Win, % Paste_P_Win
	Pr_Paste_P_Win := Paste_P_Win
	Return

	; _________________________________________________ Mouse & Control  _________________________________________________

B_Mouse:
	SetTimer %Timer%, Off
	SetTimer P_Mouse, 100
	Timer := "P_Mouse" , Pr_Paste_P_Mouse := ""
	If IsHotkeyUserFunc = 1
		HF_HotkeyUserFunc("Off"), IsHotkeyUserFunc := ""
	Gui Show, NA, % Title := "AhkSpy - Mouse & Control" Title2
	If A_GuiControl && AltEsc
		Send !{Esc}
	Gosub P_MouseView
	Return

P_Mouse:
	If WinActive("ahk_id " hGui) || Sleep = 1
		return
	Gosub S_Mouse
	Gosub P_MouseView
	Return

S_Mouse:
	WinGet, WinMouseProcessNameA, ProcessName, A
	CoordMode, Mouse, Window
	MouseGetPos, MouseXW, MouseYW, Tmp_MouseWinID, Tmp_MouseControlID, 2
	CoordMode, Mouse, Client
	MouseGetPos, MouseXCA, MouseYCA
	CoordMode, Mouse
	MouseGetPos, MouseXS, MouseYS,, Tmp_MouseControlNN

	If (Tmp_MouseWinID <> hGui)
	{
		MouseWinID := Tmp_MouseWinID
		MouseControlNN := Tmp_MouseControlNN
		MouseControlID := Tmp_MouseControlID
		CoordMode, Pixel
		PixelGetColor, RGBMouse, %MouseXS% , %MouseYS% , RGB
		GuiControl, -Redraw, ColorProgress
		GuiControl, % "+c" sRGBMouse := SubStr(RGBMouse, 3), ColorProgress
		GuiControl, +Redraw, ColorProgress

		ControlGetText, ControlGetText, , ahk_id %MouseControlID%
		ControlGetText := RegExReplace(SubStr(ControlGetText, 1, 2000), "S`a)\R", "`n")
		ControlGet, ControlGetStyle, Style,,, ahk_id %MouseControlID%
		ControlGet, ControlExStyle, ExStyle,,, ahk_id %MouseControlID%

		MouseControlNN_Sub := RegExReplace(MouseControlNN, "S)\d+| ")
		If IsLabel("GetInfo_" MouseControlNN_Sub)
		{
			Gosub, GetInfo_%MouseControlNN_Sub%
			GetInfoTitle := I " ( Get info - " MouseControlNN_Sub " ) " I I I "`n" GetInfoCtrl "`n"
		}
		else
			GetInfoTitle := ""

		ControlGetPos, GetCtrlX, GetCtrlY, GetCtrlWidth, GetCtrlHeight,, ahk_id %MouseControlID%
		GetClientPos(MouseWinID, caX, caY)
		PosCtrlC_X := GetCtrlX - caX , PosCtrlC_Y := GetCtrlY - caY

		WinGetClass, WinMouseClass, ahk_id %MouseWinID%
		WinGet, WinMouseProcessName, ProcessName, ahk_id %MouseWinID%
	}
	Return

P_MouseView:
	Paste_P_Mouse =
	( Ltrim
		%I% ( Relative Mouse Pos ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		Screen:  x%MouseXS% y%MouseYS%     ||     %MouseXS%, %MouseYS%
		%D% %D% %D% %D% %D%  active win process: "%WinMouseProcessNameA%"  %D% %D% %D% %D% %D%
		Window: x%MouseXW% y%MouseYW%     ||     %MouseXW%, %MouseYW%
		Client area:  x%MouseXCA% y%MouseYCA%     ||     %MouseXCA%, %MouseYCA%
		%I% ( Class & ProcessName Win & Id) %I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		ahk_class %WinMouseClass%  ahk_exe %WinMouseProcessName%     ||     ahk_id %MouseWinID%
		%I% ( PixelGetColor - RGB ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		%RGBMouse%     ||     %sRGBMouse%
		%I% ( Control ) %I%%I%%I%%I%%D%%D%%D%%D%
		Class NN: %MouseControlNN%
		Pos: x%GetCtrlX% y%GetCtrlY% w%GetCtrlWidth% h%GetCtrlHeight%
		Pos relative client area: x%PosCtrlC_X% y%PosCtrlC_Y% w%GetCtrlWidth% h%GetCtrlHeight%
		Style: %ControlGetStyle%     ||     ExStyle: %ControlExStyle%
		ID: %MouseControlID%
		%GetInfoTitle%%I% ( ControlGetText ) %I%%I%%I%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%%D%
		%ControlGetText%
		%I%%I%%I%%I%%I%%I%
	)
	If (Paste_P_Mouse <> Pr_Paste_P_Mouse)
		GuiControl,, Edit_Win, % Paste_P_Mouse
	Pr_Paste_P_Mouse := Paste_P_Mouse
	Return

	; _________________________________________________ Get Info Control _________________________________________________

GetInfo_SysListView:
	ControlGet, GetInfo_List_Text, List,,, ahk_id %MouseControlID%
	ControlGet, GetInfo_List_Count, List,Count,, ahk_id %MouseControlID%
	ControlGet, GetInfo_List_CountCol, List,Count Col,, ahk_id %MouseControlID%
	GetInfoCtrl := "Count line: " GetInfo_List_Count
				. "     ||     Count Col: " GetInfo_List_CountCol
				. "`n" I "   All content:   " I "`n" GetInfo_List_Text
	MouseControlNN_Sub := "SysListView32"
	Return

GetInfo_ListBox:
GetInfo_ComboBox:
	ControlGet, GetInfo_List_Text, List,,, ahk_id %MouseControlID%
	RegExReplace(GetInfo_List_Text, "`a)\R|$", "", GetInfo_List_Line)
	GetInfoCtrl := "Count line: " GetInfo_List_Line "`n" I "   All content:   " I "`n"  GetInfo_List_Text
	Return

GetInfo_Edit:
GetInfo_Scintilla:
	ControlGet, GetInfo_Edit_LineCount, LineCount,,, ahk_id %MouseControlID%
	ControlGet, GetInfo_Edit_CurrentCol, CurrentCol,,, ahk_id %MouseControlID%
	ControlGet, GetInfo_Edit_CurrentLine, CurrentLine,,, ahk_id %MouseControlID%
	ControlGet, GetInfo_Edit_Selected, Selected,,, ahk_id %MouseControlID%
	GetInfo_Edit_Selected := StrLen(GetInfo_Edit_Selected)
	SendMessage, 0x00B0,,,, ahk_id %MouseControlID%			; 	EM_GETSEL
	EM_GETSEL := ErrorLevel >> 16
	SendMessage, 0x00CE,,,, ahk_id %MouseControlID%			; 	EM_GETFIRSTVISIBLELINE
	EM_GETFIRSTVISIBLELINE := ErrorLevel + 1
	GetInfoCtrl := "LineCount: " GetInfo_Edit_LineCount
				. "     ||     Length selected: " GetInfo_Edit_Selected
				. "`nCurrentLine: " GetInfo_Edit_CurrentLine
				. "     ||     CurrentCol: " GetInfo_Edit_CurrentCol
				. "`nCurrentSelect: " EM_GETSEL
				. "     ||     FirstVisibleLine: " EM_GETFIRSTVISIBLELINE
	Return

GetInfo_msctls_progress:
	SendMessage, 0x0400+7,"TRUE",,, ahk_id %MouseControlID%		; 	PBM_GETRANGE
	PBM_GETRANGEMIN := ErrorLevel
	SendMessage, 0x0400+7,,,, ahk_id %MouseControlID%			; 	PBM_GETRANGE
	PBM_GETRANGEMAX := ErrorLevel
	SendMessage, 0x0400+8,,,, ahk_id %MouseControlID%			; 	PBM_GETPOS
	GetInfoCtrl := "Level: " ErrorLevel "     ||     Range:   min " PBM_GETRANGEMIN "   max " PBM_GETRANGEMAX
	MouseControlNN_Sub := "msctls_progress32"
	Return

GetInfo_msctls_trackbar:
	SendMessage, 0x0400+1,,,, ahk_id %MouseControlID%			; 	TBM_GETRANGEMIN
	TBM_GETRANGEMIN := ErrorLevel
	SendMessage, 0x0400+2,,,, ahk_id %MouseControlID%			;	 TBM_GETRANGEMAX
	TBM_GETRANGEMAX := ErrorLevel
	SendMessage, 0x0400,,,, ahk_id %MouseControlID%				;	 TBM_GETPOS
	(ControlGetStyle & 0x0200)
		? (TBM_GETPOS := TBM_GETRANGEMAX - (ErrorLevel - TBM_GETRANGEMIN) , TBS_REVERSED := "Yes")
		: (TBM_GETPOS := ErrorLevel , TBS_REVERSED := "No")
	GetInfoCtrl := "Level: " TBM_GETPOS "     ||     Invert style: " TBS_REVERSED
	. "`nRange:   min " TBM_GETRANGEMIN "   max " TBM_GETRANGEMAX
	MouseControlNN_Sub := "msctls_trackbar32"
	Return

GetInfo_msctls_updown:
	SendMessage, 0x0400+102,,,, ahk_id %MouseControlID%			;	 UDM_GETRANGE
	UDM_GETRANGE := ErrorLevel
	SendMessage, 0x400+114,,,, ahk_id %MouseControlID%			;	 UDM_GETPOS32
	GetInfoCtrl := "Level: " ErrorLevel "     ||     Range:   min " UDM_GETRANGE >> 16 "   max No support"
	MouseControlNN_Sub := "msctls_updown32"
	Return

GetInfo_SysTabControl:
	SendMessage, 0x1300+44,,,, ahk_id %MouseControlID%			;	 TCM_GETROWCOUNT
	TCM_GETROWCOUNT := ErrorLevel
	SendMessage, 0x1300+4,,,, ahk_id %MouseControlID%			;	 TCM_GETITEMCOUNT
	GetInfoCtrl := "Item count: " ErrorLevel "     ||     Row count: " TCM_GETROWCOUNT
	MouseControlNN_Sub := "SysTabControl32"
	Return

GetInfo_InternetExplorer_Server:
	SendMessage, DllCall("RegisterWindowMessage", Str, "WM_HTML_GETOBJECT"),,,, ahk_id %MouseControlID%
	DllCall("oleacc\ObjectFromLresult", Ptr, ErrorLevel, Ptr, 0, Ptr, 0, PtrP, pdoc)
	If pdoc
		GetInfoCtrl := ComObjEnwrap(pdoc).body.innerText , ObjRelease(pdoc)
	MouseControlNN_Sub := "Internet Explorer_Server"
	Return

	; _________________________________________________ Other _________________________________________________

GuiSize:
	Sleep := A_EventInfo
	GuiControl, MoveDraw, Edit_Win, % "x0 y" SM_CYMINSPACING " w" A_GuiWidth  " h" A_GuiHeight - SM_CYMINSPACING
	Return

GuiClose:
GuiEscape:
	ExitApp

	;	 GetClientPos && GetClientSize
	;	 http://www.autohotkey.com/board/topic/77915-get-client-window/

GetClientPos(hwnd, ByRef x, ByRef y) {
	WinGetPos,,,, Window_Height, ahk_id %hwnd%
	VarSetCapacity(rcClient, 16, 0)
    DllCall("user32\GetClientRect","ptr", hwnd ,"ptr",&rcClient)
	rcClient_b := NumGet(rcClient, 12, "int")
	VarSetCapacity(pwi, 60, 0), NumPut(60, pwi, 0, "UInt")
	DllCall("GetWindowInfo", "ptr", hwnd, "Uint", &pwi)
	x := NumGet(pwi, 48, "int"), by := NumGet(pwi, 52, "int")
	y := Window_Height - by - rcClient_b
}

GetClientSize(hwnd, ByRef RealWidth, ByRef RealHeight) {
    VarSetCapacity(rcClient, 16, 0)
    DllCall("user32\GetClientRect","ptr", hwnd ,"ptr",&rcClient)
    RealWidth := NumGet(rcClient, 8, "int"), RealHeight := NumGet(rcClient, 12, "int")
}

	; _________________________________________________ Button _________________________________________________

B_Buttons:
	IsHotkeyUserFunc := 1
	SetTimer %Timer%, Off
	HF_HotkeyUserFunc("ON","MyNameFunc")
	Title := "AhkSpy - Button" Title2
	SendMessage, 0xC, 0, &Title, , ahk_id %hGui%
	GuiControl,, Edit_Win, % Paste_P_Buttons
	WinActivate ahk_id %hGui%
	Return

MyNameFunc(Mod, KeyName, Prefix, Hotkey, VkCode, ThisKey)   {
	Comment := Hotkey ~= "^vk" ? "  `;  """ KeyName """" : ""
	Paste_P_Buttons =
	( Ltrim
		%I%%I%%I%%I%%I%%I%

		%Mod%%KeyName%

		%I%%I%%I%%I%%I%%I%

		%Prefix%%Hotkey%

		%Prefix%{%Hotkey%}

		%Prefix%%Hotkey%::%Comment%

		Send %Prefix%{%Hotkey%}%Comment%

		ControlSend, ahk_parent, %Prefix%{%Hotkey%},  %Comment%

		%I%%I%%I%%I%%I%%I%

		%ThisKey%

		%VkCode%%HF_SCCode%

		%VkCode%

		%HF_SCCode%

		%I%%I%%I%%I%%I%%I%
		LButton - vk1 | RButton - vk2
	)
	GuiControl,, Edit_Win, % Paste_P_Buttons
}

	; _________________________________________________ HotkeyUserFunc Library _________________________________________________
	;  http://forum.script-coding.com/viewtopic.php?pid=69765#p69765

HF_HotkeyUserFunc(Option = "", UserFuncName = "") { ;***
    Global
    Static HF_IsStart
    HF_UserFuncName := (UserFuncName = "") ? HF_UserFuncName : UserFuncName
	If HF_IsStart =
	{
		OnMessage(0x6, "HF_WM_ACTIVATE")
		#InstallKeybdHook
		#InstallMouseHook
		#HotkeyInterval 200
		#MaxHotkeysPerInterval 200
		HF_IsStart := "IsStart"
		SetBatchLines -1
	}
	If (Option = "T")
		( HF_State ) ? (HF_State := "" , Option = "OFF") : (HF_State := 1 , Option = "ON")
    If (Option = "OFF")
		HF_Man := "Man" , HF_Unhook()
	Else If  (Option = "ON")
		HF_Man := "" , HF_Hook()
	HF_CleanMod() , HF_Hotkey := HF_PR_Result := ""
	Return HF_State
} ;**

HF_WM_ACTIVATE(HF_wp) { ;***
    Global
	Critical
    IF (HF_wp & 0xFFFF = 0 && HF_State)
		HF_Unhook() , HF_ExtFunc("HF_WinStatus", "0")
    IF (HF_wp & 0xFFFF && HF_State = "" && HF_Man = "")
		HF_Hook() , HF_ExtFunc("HF_WinStatus", "1")
} ;**

HF_ExtFunc(F, V) { ;***
	If IsFunc(F)
		%F%(V)
} ;**

HF_Unhook() { ;***
	Global
	HF_KeyName := HF_Hotkey := HF_PR_Result := HF_State := ""
	HF_CleanMod()
	If (HF_DelStr = 1)
		%HF_UserFuncName%("", "", "", "", HF_VkCode, HF_ThisKey)
} ;**

HF_Hook() { ;***
	Global
	HF_DelStr := "", HF_State := 1
} ;**

HF_CleanMod() { ;***
	Global
	HF_ModCtrl := HF_ModAlt := HF_ModShift := HF_ModWin := HF_Prefix := HF_PrefModCtrl := HF_PrefModAlt := HF_PrefModShift := HF_PrefModWin := ""
} ;**
	; -------------------------------------- Read --------------------------------------
HF_HotkeyUserRead(Key, Section = "", Path = "") { ;***
	Global HF_DelStr := ""
    If (Section <> "")
        IniRead, Key, % Path, % Section, % Key, %A_Space%
	RegExMatch(Rtrim(Key, "}"), "S)^([\^\!\+#]*)\{?(.*)", K)
    Return RegExReplace(RegExReplace(RegExReplace(RegExReplace( K1,"\+","Shift+"),"\!","Alt+"),"\^","Ctrl+"),"#","Win+")
		. (K2 ~= "^vk" ? GetKeyName(K2) : K2)
} ;**

HF_ReadToSend(Key, Section = "", Path = "") { ;***
    If (Section <> "")
        IniRead, Key, % Path, % Section, % Key, %A_Space%
    Return RegExReplace( Key, "S)\w+", "{$0}")
} ;**

Gosub, HF_DROPSTART
Return

HF_Write:
	(HF_Hotkey = "") ? (HF_Prefix := "" , HF_DelStr := 1) : (HF_Prefix := HF_PrefModCtrl HF_PrefModAlt HF_PrefModShift HF_PrefModWin , HF_DelStr := "" )
    If (HF_PR_Result = HF_ModCtrl HF_ModAlt HF_ModShift HF_ModWin HF_KeyName HF_Prefix HF_Hotkey HF_VkCode HF_ThisKey)
        Return
    HF_PR_Result := HF_ModCtrl HF_ModAlt HF_ModShift HF_ModWin HF_KeyName HF_Prefix HF_Hotkey HF_VkCode HF_ThisKey
    %HF_UserFuncName%(HF_ModCtrl HF_ModAlt HF_ModShift HF_ModWin, HF_KeyName, HF_Prefix, HF_Hotkey, HF_VkCode, HF_ThisKey)
	Return

#IF (HF_State = 1)

LAlt::
RAlt::
	If HF_ModAlt <>
		Return
	HF_ModAlt := "Alt+"
	HF_PrefModAlt := "!"
	Gosub, HF_PressMod
	Return
LCtrl::
RCtrl::
	If HF_ModCtrl <>
		Return
	HF_ModCtrl := "Ctrl+"
	HF_PrefModCtrl := "^"
	Gosub, HF_PressMod
	Return
LShift::
RShift::
	If HF_ModShift <>
		Return
	HF_ModShift := "Shift+"
	HF_PrefModShift := "+"
	Gosub, HF_PressMod
	Return
LWin::
RWin::
	If HF_ModWin <>
		Return
	HF_ModWin := "Win+"
	HF_PrefModWin := "#"

HF_PressMod:
	HF_KeyName := HF_Hotkey := ""
	SetFormat, IntegerFast, H
	HF_VkCode := "vk" SubStr(GetKeyVK(A_ThisHotkey),3)
	HF_SCCode := "sc" SubStr(GetKeySC(HF_VkCode),3) , HF_SCCode := (HF_SCCode = "sc136" ? "sc36" : HF_SCCode)
	HF_ThisKey := A_ThisHotkey
	Gosub, HF_Write
	Return

LAlt UP::
RAlt UP::
	HF_PrefModAlt := HF_ModAlt := ""
	If HF_Hotkey <>
		Return
	Gosub, HF_Write
	Return
LCtrl UP::
RCtrl UP::
	HF_PrefModCtrl := HF_ModCtrl := ""
	If HF_Hotkey <>
		Return
	Gosub, HF_Write
	Return
LShift UP::
RShift UP::
	HF_PrefModShift := HF_ModShift := ""
	If HF_Hotkey <>
		Return
	Gosub, HF_Write
	Return
LWin UP::
RWin UP::
	HF_PrefModWin := HF_ModWin := ""
	If HF_Hotkey <>
		Return
	Gosub, HF_Write
	Return

   ; 37 Letter Buttons
vkBA::   ;   "ж"
vkBB::   ;   "="
vkBC::   ;   "б"
vkBD::   ;   "-"
vkBE::   ;   "ю"
vkBF::   ;   "."
vkC0::   ;   "ё"
vkDB::   ;   "х"
vkDC::   ;   "\"
vkDD::   ;   "ъ"
vkDE::   ;   "э"
vk41::   ;   "A"
vk42::   ;   "B"
vk43::   ;   "C"
vk44::   ;   "D"
vk45::   ;   "E"
vk46::   ;   "F"
vk47::   ;   "G"
vk48::   ;   "H"
vk49::   ;   "I"
vk4A::   ;   "J"
vk4B::   ;   "K"
vk4C::   ;   "L"
vk4D::   ;   "M"
vk4E::   ;   "N"
vk4F::   ;   "O"
vk50::   ;   "P"
vk51::   ;   "Q"
vk52::   ;   "R"
vk53::   ;   "S"
vk54::   ;   "T"
vk55::   ;   "U"
vk56::   ;   "V"
vk57::   ;   "W"
vk58::   ;   "X"
vk59::   ;   "Y"
vk5A::   ;   "Z"

vkC1::     ; 18 No Name
vkC2::
vkDF::
vkE1::
vkE2::   ;   "\"
vkE6::
vkE3::
vkF0::
vkF2::
vkF3::
vkF5::
vkF6::
vkF7::
vkF8::
vkF9::
vkFE::
vk2B::
vk6C::

	HF_Hotkey := HF_VkCode := A_ThisHotkey
	HF_ThisKey := HF_KeyName := GetKeyName(A_ThisHotkey)
	SetFormat, IntegerFast, H
	HF_SCCode := "sc" SubStr(GetKeySC(HF_VkCode),3)
	Gosub, HF_Write
	Return

0::
1::
2::
3::
4::
5::
6::
7::
8::
9::

F1::
F2::
F3::
F4::
F5::
F6::
F7::
F8::
F9::
F10::
F11::
F12::
F13::
F14::
F15::
F16::
F17::
F18::
F19::
F20::
F21::
F22::
F23::
F24::

AppsKey::
Backspace::
CapsLock::
Del::
Down::
End::
Enter::
Esc::
Home::
Left::
Pause::
PgDn::
PgUp::
PrintScreen::
Right::
ScrollLock::
Space::
Tab::
Up::

Break::
CtrlBreak::
Help::
Insert::
Sleep::

Numlock::
Numpad0::
Numpad1::
Numpad2::
Numpad3::
Numpad4::
Numpad5::
Numpad6::
Numpad7::
Numpad8::
Numpad9::
NumpadAdd::
NumpadClear::
NumpadDel::
NumpadDiv::
NumpadDot::
NumpadDown::
NumpadEnd::
NumpadEnter::
NumpadHome::
NumpadIns::
NumpadLeft::
NumpadMult::
NumpadPgDn::
NumpadPgUp::
NumpadRight::
NumpadSub::
NumpadUp::

Browser_Back::
Browser_Favorites::
Browser_Forward::
Browser_Home::
Browser_Refresh::
Browser_Search::
Browser_Stop::
Launch_App1::
Launch_App2::
Launch_Mail::
Launch_Media::
Media_Next::
Media_Play_Pause::
Media_Prev::
Media_Stop::
Volume_Down::
Volume_Mute::
Volume_Up::

MButton::
WheelUp::
WheelDown::
WheelLeft::
WheelRight::
XButton1::
XButton2::

	SetFormat, IntegerFast, H
	HF_VkCode := "vk" SubStr(GetKeyVK(A_ThisHotkey),3)
	HF_SCCode := "sc" SubStr(GetKeySC(A_ThisHotkey),3), (HF_SCCode = "sc0") ? HF_SCCode := ""
	HF_Hotkey := HF_ThisKey := HF_KeyName := A_ThisHotkey
	Gosub, HF_Write
	Return

1Joy1::
1Joy2::
1Joy3::
1Joy4::
1Joy5::
1Joy6::
1Joy7::
1Joy8::
1Joy9::
1Joy10::
1Joy11::
1Joy12::
1Joy13::
1Joy14::
1Joy15::
1Joy16::
1Joy17::
1Joy18::
1Joy19::
1Joy20::
1Joy21::
1Joy22::
1Joy23::
1Joy24::
1Joy25::
1Joy26::
1Joy27::
1Joy28::
1Joy29::
1Joy30::
1Joy31::
1Joy32::

2Joy1::
2Joy2::
2Joy3::
2Joy4::
2Joy5::
2Joy6::
2Joy7::
2Joy8::
2Joy9::
2Joy10::
2Joy11::
2Joy12::
2Joy13::
2Joy14::
2Joy15::
2Joy16::
2Joy17::
2Joy18::
2Joy19::
2Joy20::
2Joy21::
2Joy22::
2Joy23::
2Joy24::
2Joy25::
2Joy26::
2Joy27::
2Joy28::
2Joy29::
2Joy30::
2Joy31::
2Joy32::

3Joy1::
3Joy2::
3Joy3::
3Joy4::
3Joy5::
3Joy6::
3Joy7::
3Joy8::
3Joy9::
3Joy10::
3Joy11::
3Joy12::
3Joy13::
3Joy14::
3Joy15::
3Joy16::
3Joy17::
3Joy18::
3Joy19::
3Joy20::
3Joy21::
3Joy22::
3Joy23::
3Joy24::
3Joy25::
3Joy26::
3Joy27::
3Joy28::
3Joy29::
3Joy30::
3Joy31::
3Joy32::

4Joy1::
4Joy2::
4Joy3::
4Joy4::
4Joy5::
4Joy6::
4Joy7::
4Joy8::
4Joy9::
4Joy10::
4Joy11::
4Joy12::
4Joy13::
4Joy14::
4Joy15::
4Joy16::
4Joy17::
4Joy18::
4Joy19::
4Joy20::
4Joy21::
4Joy22::
4Joy23::
4Joy24::
4Joy25::
4Joy26::
4Joy27::
4Joy28::
4Joy29::
4Joy30::
4Joy31::
4Joy32::

	HF_VkCode := HF_SCCode := ""
	HF_Hotkey := HF_ThisKey := HF_KeyName := A_ThisHotkey
	Gosub, HF_Write
	Return
#IF
HF_DROPSTART:


/*



DetectHiddenWindows, on
WinGet, List, List, ahk_exe opera.exe
MsgBox Всего - %List%
loop % List
{
	WinGetTitle, Title, % "ahk_id " List%A_Index%
	WinGetClass, Class, % "ahk_id " List%A_Index%
	DetectHiddenText off
	WinGetText, Text, % "ahk_id " List%A_Index%
	DetectHiddenText on
	WinGetText, HiddenText, % "ahk_id " List%A_Index%
	msgbox =
	( Ltrim
	Окно - %A_Index% из %List%

	Title - %Title%
	Class - %Class%

	Text - %Text%
	HiddenText - %HiddenText%
	)
	msgbox %msgbox%
}
msgbox The end
