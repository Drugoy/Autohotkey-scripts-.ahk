; DrugWinManager v1.1
; https://github.com/Drugoy/DrugWinManager

#NoEnv
#Persistent
#SingleInstance, Force
SetWorkingDir %A_ScriptDir%

Menu, Tray, Icon, DrugWinManager.ico
Menu, Tray, NoStandard
Menu, Tray, Add, Settings, openSettingsWindow
Menu, Tray, Add
Menu, Tray, Standard


; Global variables

SysGet, UA, MonitorWorkArea
UAcenterX := UALeft + (UAhalfW := (UALeft + UARight)/2)
UAcenterY := UATop + (UAhalfH := (UATop + UABottom)/2)


; Reading hotkey combinations.

SplitPath, A_ScriptName,,,ini, TheSameFileName
IniRead, HK1, %TheSameFileName%.ini, Hotkeys, ToggleAlwaysOnTop, LWin & vkC0 ; `
IniRead, HK2, %TheSameFileName%.ini, Hotkeys, ToggleRemoveRestoreTitle, <#Space
IniRead, HK3, %TheSameFileName%.ini, Hotkeys, PseudoMaximize, <#<^vk53	; s
IniRead, HK4, %TheSameFileName%.ini, Hotkeys, DecreaseHeight, <!<#vk57	; w
IniRead, HK5, %TheSameFileName%.ini, Hotkeys, IncreaseHeight, <!<#vk53	; s
IniRead, HK6, %TheSameFileName%.ini, Hotkeys, DecreaseWidth, <!<#vk41	; a
IniRead, HK7, %TheSameFileName%.ini, Hotkeys, IncreaseWidth, <!<#vk44	; d
IniRead, HK8, %TheSameFileName%.ini, Hotkeys, MoveTop, <+<#vk57		; w
IniRead, HK9, %TheSameFileName%.ini, Hotkeys, MoveBottom, <+<#vk53	; s
IniRead, HK10, %TheSameFileName%.ini, Hotkeys, MoveLeft, <+<#vk41	; a
IniRead, HK11, %TheSameFileName%.ini, Hotkeys, MoveRight, <+<#vk44	; d
IniRead, HK12, %TheSameFileName%.ini, Hotkeys, QuarterUL, <#<^vk51	; q
IniRead, HK13, %TheSameFileName%.ini, Hotkeys, QuarterUR, <#<^vk45	; e
IniRead, HK14, %TheSameFileName%.ini, Hotkeys, QuarterBL, <#<^vk5A	; z
IniRead, HK15, %TheSameFileName%.ini, Hotkeys, QuarterBR, <#<^vk43	; c
IniRead, HK16, %TheSameFileName%.ini, Hotkeys, HalfTop, <#<^vk57	; w
IniRead, HK17, %TheSameFileName%.ini, Hotkeys, HalfBottom, <#<^vk58	; x
IniRead, HK18, %TheSameFileName%.ini, Hotkeys, HalfLeft, <#<^vk41	; a
IniRead, HK19, %TheSameFileName%.ini, Hotkeys, HalfRight, <#<^vk44	; d


; Setting hotkeys.

Hotkey, % HK1, ToggleAlwaysOnTop
Hotkey, % HK2, ToggleRemoveRestoreTitle
Hotkey, % HK3, PseudoMaximize
Hotkey, % HK4, DecreaseHeight
Hotkey, % HK5, IncreaseHeight
Hotkey, % HK6, DecreaseWidth
Hotkey, % HK7, IncreaseWidth
Hotkey, % HK8, MoveTop
Hotkey, % HK9, MoveBottom
Hotkey, % HK10, MoveLeft
Hotkey, % HK11, MoveRight
Hotkey, % HK12, QuarterUL
Hotkey, % HK13, QuarterUR
Hotkey, % HK14, QuarterBL
Hotkey, % HK15, QuarterBR
Hotkey, % HK16, HalfTop
Hotkey, % HK17, HalfBottom
Hotkey, % HK18, HalfLeft
Hotkey, % HK19, HalfRight

Return

; Opening settings window.

openSettingsWindow:
	Gui, Add, Tab2, x0 y0 h300 w380 , General|Resize|Move|Quarter|Half

	Gui, Tab, 1
	
	Gui, Add, Text, x15 y30, Toggle "Always on top" state for the active window.
	If HK1 = Lwin & vkC0
		Gui, Add, Text, cBlue x15 y45, Currently used hotkey: hit `` while holding left Winkey.
	Gui, Add, Hotkey, x15 y64 vHK1, % HK1
	Gui, Add, Button, w60 h25 x140 y62 vHK1btn gSetHotkey1, Set hotkey

	Gui, Add, Text, x15 y97, Toggle remove/restore title bar of the active window.
	If HK2 = <#Space
		Gui, Add, Text, cBlue x15 y112, Currently used hotkey: left Winkey + Space.
	Gui, Add, Hotkey, x15 y131 vHK2, % HK2
	Gui, Add, Button, w60 h25 x140 y129 vHK2btn gSetHotkey2, Set hotkey

	Gui, Add, Text, x15 y164, Resize the active window to occupy full usable area.
	If HK3 = <#<^vk53
		Gui, Add, Text, cBlue x15 y179, Currently used hotkey: left Ctrl + left Winkey + S.
	Gui, Add, Hotkey, x15 y198 vHK3, % HK3
	Gui, Add, Button, w60 h25 x140 y196 vHK3btn gSetHotkey3, Set hotkey

	Gui, Tab, 2

	Gui, Add, Text, x15 y30, Decrease height of the active window.
	If HK4 = <!<#vk57
		Gui, Add, Text, cBlue x15 y45, Currently used hotkey: left Alt + left Winkey + W.
	Gui, Add, Hotkey, x15 y64 vHK4, % HK4
	Gui, Add, Button, w60 h25 x140 y62 vHK4btn gSetHotkey4, Set hotkey

	Gui, Add, Text, x15 y97, Increase height of the active window.
	If HK5 = <!<#vk53
		Gui, Add, Text, cBlue x15 y114, Currently used hotkey: left Alt + left Winkey + S.
	Gui, Add, Hotkey, x15 y131 vHK5, % HK5
	Gui, Add, Button, w60 h25 x140 y129 vHK5btn gSetHotkey5, Set hotkey

	Gui, Add, Text, x15 y164, Decrease width of the active window.
	If HK6 = <!<#vk41
		Gui, Add, Text, cBlue x15 y179, Currently used hotkey: left Alt + left Winkey + A.
	Gui, Add, Hotkey, x15 y198 vHK6, % HK6
	Gui, Add, Button, w60 h25 x140 y196 vHK6btn gSetHotkey6, Set hotkey

	Gui, Add, Text, x15 y231, Increase width of the active window.
	If HK7 = <!<#vk44
		Gui, Add, Text, cBlue x15 y246, Currently used hotkey: left Alt + left Winkey + D.
	Gui, Add, Hotkey, x15 y265 vHK7, % HK7
	Gui, Add, Button, w60 h25 x140 y263 vHK7btn gSetHotkey7, Set hotkey

	Gui, Tab, 3
	
	Gui, Add, Text, x15 y30, Move the active window up.
	If HK8 = <+<#vk57
		Gui, Add, Text, cBlue x15 y45, Currently used hotkey: left Shift + left Winkey + W.
	Gui, Add, Hotkey, x15 y64 vHK8, % HK8
	Gui, Add, Button, w60 h25 x140 y62 vHK8btn gSetHotkey8, Set hotkey

	Gui, Add, Text, x15 y97, Move the active window down.
	If HK9 = <+<#vk53
		Gui, Add, Text, cBlue x15 y112, Currently used hotkey: left Shift + left Winkey + S.
	Gui, Add, Hotkey, x15 y131 vHK9, % HK9
	Gui, Add, Button, w60 h25 x140 y129 vHK9btn gSetHotkey9, Set hotkey

	Gui, Add, Text, x15 y164, Move the active window left.
	If HK10 = <+<#vk41
		Gui, Add, Text, cBlue x15 y179, Currently used hotkey: left Shift + left Winkey + A.
	Gui, Add, Hotkey, x15 y198 vHK10, % HK10
	Gui, Add, Button, w60 h25 x140 y196 vHK10btn gSetHotkey10, Set hotkey

	Gui, Add, Text, x15 y231, Move the active window right.
	If HK11 = <+<#vk44
		Gui, Add, Text, cBlue x15 y246, Currently used hotkey: left Shift + left Winkey + D.
	Gui, Add, Hotkey, x15 y265 vHK11, % HK11
	Gui, Add, Button, w60 h25 x140 y263 vHK11btn gSetHotkey11, Set hotkey

	Gui, Tab, 4

	Gui, Add, Text, x15 y30, Resize and move the active window to the upper left quarter of the screen.
	If HK12 = <#<^vk51
		Gui, Add, Text, cBlue x15 y45, Currently used hotkey: left Ctrl + left Winkey + Q.
	Gui, Add, Hotkey, x15 y64 vHK12, % HK12
	Gui, Add, Button, w60 h25 x140 y62 vHK12btn gSetHotkey12, Set hotkey

	Gui, Add, Text, x15 y97, Resize and move the active window to the upper right quarter of the screen.
	If HK13 = <#<^vk45
		Gui, Add, Text, cBlue x15 y112, Currently used hotkey: left Ctrl + left Winkey + E.
	Gui, Add, Hotkey, x15 y131 vHK13, % HK13
	Gui, Add, Button, w60 h25 x140 y129 vHK13btn gSetHotkey13, Set hotkey

	Gui, Add, Text, x15 y164, Resize and move the active window to the bottom left quarter of the screen.
	If HK14 = <#<^vk5A
		Gui, Add, Text, cBlue x15 y179, Currently used hotkey: left Ctrl + left Winkey + Z.
	Gui, Add, Hotkey, x15 y198 vHK14, % HK14
	Gui, Add, Button, w60 h25 x140 y196 vHK14btn gSetHotkey14, Set hotkey

	Gui, Add, Text, x15 y231, Resize and move the active window to the bottom right quarter of the screen.
	If HK15 = <#<^vk43
		Gui, Add, Text, cBlue x15 y246, Currently used hotkey: left Ctrl + left Winkey + C.
	Gui, Add, Hotkey, x15 y265 vHK15, % HK15
	Gui, Add, Button, w60 h25 x140 y263 vHK15btn gSetHotkey15, Set hotkey

	Gui, Tab, 5

	Gui, Add, Text, x15 y30, Resize and move the active window to the upper half of the screen.
	If HK16 = <#<^vk57
		Gui, Add, Text, cBlue x15 y45, Currently used hotkey: left Ctrl + left Winkey + W.
	Gui, Add, Hotkey, x15 y64 vHK16, % HK16
	Gui, Add, Button, w60 h25 x140 y62 vHK16btn gSetHotkey16, Set hotkey

	Gui, Add, Text, x15 y97, Resize and move the active window to the bottom half of the screen.
	If HK17 = <#<^vk58
		Gui, Add, Text, cBlue x15 y112, Currently used hotkey: left Ctrl + left Winkey + X.
	Gui, Add, Hotkey, x15 y131 vHK17, % HK17
	Gui, Add, Button, w60 h25 x140 y129 vHK17btn gSetHotkey17, Set hotkey

	Gui, Add, Text, x15 y164, Resize and move the active window to the left half of the screen.
	If HK18 = <#<^vk41
		Gui, Add, Text, cBlue x15 y179, Currently used hotkey: left Ctrl + left Winkey + A.
	Gui, Add, Hotkey, x15 y198 vHK18, % HK18
	Gui, Add, Button, w60 h25 x140 y196 vHK18btn gSetHotkey18, Set hotkey

	Gui, Add, Text, x15 y231, Resize and move the active window to the right half of the screen.
	If HK19 = <#<^vk44
		Gui, Add, Text, cBlue x15 y246, Currently used hotkey: left Ctrl + left Winkey + D.
	Gui, Add, Hotkey, x15 y265 vHK19, % HK19
	Gui, Add, Button, w60 h25 x140 y263 vHK19btn gSetHotkey19, Set hotkey

	Gui, Show, , DrugWinManager settings
	Return

; Closing settings window.

GuiClose:
GuiEscape:
	Gui, Destroy
	Return


; Binding hotkeys to the labels (that will be bound to blocks of code)

SetHotkey1:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK1, Off, UseErrorLevel
	Hotkey, % HK1, ToggleAlwaysOnTop
	Prev_HK1 := HK1
	iniWrite, % HK1, %TheSameFileName%.ini, Hotkeys, ToggleAlwaysOnTop
	Return

SetHotkey2:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK2, Off, UseErrorLevel
	Hotkey, % HK2, ToggleRemoveRestoreTitle
	Prev_HK2 := HK2
	iniWrite, % HK2, %TheSameFileName%.ini, Hotkeys, ToggleRemoveRestoreTitle
	Return

SetHotkey3:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK3, Off, UseErrorLevel
	Hotkey, % HK3, PseudoMaximize
	Prev_HK3 := HK3
	iniWrite, % HK3, %TheSameFileName%.ini, Hotkeys, PseudoMaximize
	Return

SetHotkey4:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK4, Off, UseErrorLevel
	Hotkey, % HK4, DecreaseHeight
	Prev_HK4 := HK4
	iniWrite, % HK4, %TheSameFileName%.ini, Hotkeys, DecreaseHeight
	Return

SetHotkey5:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK5, Off, UseErrorLevel
	Hotkey, % HK5, IncreaseHeight
	Prev_HK5 := HK5
	iniWrite, % HK5, %TheSameFileName%.ini, Hotkeys, IncreaseHeight
	Return

SetHotkey6:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK6, Off, UseErrorLevel
	Hotkey, % HK6, DecreaseWidth
	Prev_HK6 := HK6
	iniWrite, % HK6, %TheSameFileName%.ini, Hotkeys, DecreaseWidth
	Return

SetHotkey7:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK7, Off, UseErrorLevel
	Hotkey, % HK7, IncreaseWidth
	Prev_HK7 := HK7
	iniWrite, % HK7, %TheSameFileName%.ini, Hotkeys, IncreaseWidth
	Return

SetHotkey8:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK8, Off, UseErrorLevel
	Hotkey, % HK8, MoveTop
	Prev_HK8 := HK8
	iniWrite, % HK8, %TheSameFileName%.ini, Hotkeys, MoveTop
	Return

SetHotkey9:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK9, Off, UseErrorLevel
	Hotkey, % HK9, MoveBottom
	Prev_HK9 := HK9
	iniWrite, % HK9, %TheSameFileName%.ini, Hotkeys, MoveBottom
	Return

SetHotkey10:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK10, Off, UseErrorLevel
	Hotkey, % HK10, MoveLeft
	Prev_HK10 := HK10
	iniWrite, % HK10, %TheSameFileName%.ini, Hotkeys, MoveLeft
	Return

SetHotkey11:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK11, Off, UseErrorLevel
	Hotkey, % HK11, MoveRight
	Prev_HK11 := HK11
	iniWrite, % HK11, %TheSameFileName%.ini, Hotkeys, MoveRight
	Return

SetHotkey12:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK12, Off, UseErrorLevel
	Hotkey, % HK12, QuarterUL
	Prev_HK12 := HK12
	iniWrite, % HK12, %TheSameFileName%.ini, Hotkeys, QuarterUL
	Return

SetHotkey13:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK13, Off, UseErrorLevel
	Hotkey, % HK13, QuarterUR
	Prev_HK13 := HK13
	iniWrite, % HK13, %TheSameFileName%.ini, Hotkeys, QuarterUR
	Return

SetHotkey14:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK14, Off, UseErrorLevel
	Hotkey, % HK14, QuarterBL
	Prev_HK14 := HK14
	iniWrite, % HK14, %TheSameFileName%.ini, Hotkeys, QuarterBL
	Return

SetHotkey15:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK15, Off, UseErrorLevel
	Hotkey, % HK15, QuarterBR
	Prev_HK15 := HK15
	iniWrite, % HK15, %TheSameFileName%.ini, Hotkeys, QuarterBR
	Return

SetHotkey16:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK16, Off, UseErrorLevel
	Hotkey, % HK16, HalfTop
	Prev_HK16 := HK16
	iniWrite, % HK16, %TheSameFileName%.ini, Hotkeys, HalfTop
	Return

SetHotkey17:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK17, Off, UseErrorLevel
	Hotkey, % HK17, HalfBottom
	Prev_HK17 := HK17
	iniWrite, % HK17, %TheSameFileName%.ini, Hotkeys, HalfBottom
	Return

SetHotkey18:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK18, Off, UseErrorLevel
	Hotkey, % HK18, HalfLeft
	Prev_HK18 := HK18
	iniWrite, % HK18, %TheSameFileName%.ini, Hotkeys, HalfLeft
	Return

SetHotkey19:
	Gui, Submit, NoHide
	Hotkey, % Prev_HK19, Off, UseErrorLevel
	Hotkey, % HK19, HalfRight
	Prev_HK19 := HK19
	iniWrite, % HK19, %TheSameFileName%.ini, Hotkeys, HalfRight
	Return


; Binding blocks of code to execute to the corresponding labels.


; TOGGLE THINGS

ToggleAlwaysOnTop:
	WinSet, AlwaysOnTop, Toggle, A
	Return

ToggleRemoveRestoreTitle:
	WinGet,Title,Style,A
	if (Title & 0xC00000)
	WinSet,Style,-0xC00000,A
	Else WinSet,Style,+0xC00000,A
	WinGetPos,,,,Height,A
	WinMove,A,,,,,% Height-1
	WinMove,A,,,,,% Height
	Return

PseudoMaximize:
	WinMove,A,,UALeft,UATop,UARight-UALeft,UABottom-UATop
	Return


; RESIZE

DecreaseHeight:
	WinGetPos,,,,H, A
	WinMove,A,,,,,H-UAhalfH/8
	Return
IncreaseHeight:
	WinGetPos,,,,H, A
	WinMove,A,,,,,H+UAhalfH/8
	Return
DecreaseWidth:
	WinGetPos,,,W,, A
	WinMove,A,,,,W-UAhalfW/8
	Return
IncreaseWidth:
	WinGetPos,,,W,, A
	WinMove,A,,,,W+UAhalfW/8
	Return


; MOVE

MoveTop:
	WinGetPos,,Y,,,A
	WinMove,A,,,Y-UAhalfH/8
	Return
MoveBottom:
	WinGetPos,,Y,,,A
	WinMove,A,,,Y+UAhalfH/8
	Return
MoveLeft:
	WinGetPos,X,,,,A
	WinMove,A,,X-UAhalfW/8
	Return
MoveRight:
	WinGetPos,X,,,,A
	WinMove,A,,X+UAhalfW/8
	Return


; QUARTER

QuarterUL:
	WinMove,A,,UALeft,UATop,UAcenterX,UAcenterY
	Return
QuarterUR:
	WinMove,A,,UAcenterX,UATop,UAcenterX,UAcenterY
	Return
QuarterBL:
	WinMove,A,,UALeft,UAcenterY,UAcenterX,UAcenterY
	Return
QuarterBR:
	WinMove,A,,UAcenterX,UAcenterY,UAcenterX,UAcenterY
	Return


; HALF

HalfTop:
	WinMove,A,,UALeft,UATop,UARight-UALeft,UAcenterY
	Return
HalfBottom:
	WinMove,A,,UALeft,UAcenterY,UARight-UALeft,UAcenterY
	Return
HalfLeft:
	WinMove,A,,UALeft,UATop,UAcenterX,UABottom-UATop
	Return
HalfRight:
	WinMove,A,,UAcenterX,UATop,UAcenterX,UABottom-UATop
	Return