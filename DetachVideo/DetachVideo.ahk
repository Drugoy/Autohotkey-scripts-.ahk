/* DetachVideo
Version: 1
Last time modified: 02:42 26.11.2013

Description: detach embedded videos from a browser and show them in their own separate windows.

Initial script author: Skrommel
http://www.donationcoder.com/Software/Skrommel/index.html#DetachVideo

This script was later modified by: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/blob/master/DetachVideo/DetachVideo.ahk
*/

#SingleInstance, Force
DetectHiddenWindows, On
SetWinDelay, 0

counter := 0
OnExit, Exit
SetTimer, Move, 500
Return

F12::
	SetTimer, Move, Off
	MouseGetPos,,, window, ctrl, 2
	If !ctrl	; There should be no case when %ctrl% is empty, I've added this check just to avoid the conflict with Firefox.
		Return
	WinGetActiveTitle, windowTitle
	WinGetPos,,, ww, wh, ahk_id %window%
	WinGetPos,,, cw, ch, ahk_id %ctrl%
	current := counter
	Loop, % counter + 1
	{
		If !gui_%A_Index%
		{
			current := A_Index
			Break
		}
	}
	If (current > counter)
		counter++
	Gui, %current%: +AlwaysOnTop +Resize +ToolWindow +LabelAllGui 
	Gui, %current%: Show, X0 Y0 W%cw% H%ch%, %windowTitle%
	Gui, %current%: +LastFound
	gui := WinExist("A")
	parent := DllCall("SetParent", "UInt", ctrl, "UInt", gui)
	WinMove, ahk_id %ctrl%,, %cw%, %ch%
	ctrl_%current% := ctrl, gui_%current% := gui, parent_%current% := parent, window_%current% := window, w_%current% := ww, h_%current% := wh
	SetTimer, Move, 500
Return

Move:
	SetTimer, Move, Off
	Loop, %counter%
	{
		ctrl := ctrl_%A_Index%
		If !ctrl
			Continue
		IfWinExist, ahk_id %ctrl%
			WinMove, ahk_id %ctrl%,, 0, 0
		Else
			Gui, %A_Index%: Destroy
	}
	SetTimer, Move, 500
Return

AllGuiClose:
	SetTimer, Move, Off
	ctrl := ctrl_%A_Gui%, window := window_%A_Gui%
	DllCall("SetParent", "UInt", ctrl_%A_Gui%, "UInt", parent_%A_Gui%)
	Gui, %A_Gui%: Destroy
	WinMove, ahk_id %ctrl%,, 0, 0
	WinMove, ahk_id %window%,,,, % w_%A_Gui%, % h_%A_Gui% + 1
	WinMove, ahk_id %window%,,,, % w_%A_Gui%, % h_%A_Gui%
	gui_%A_Gui% := ctrl_%A_Gui% := parent_%A_Gui% := 0
	SetTimer, Move, 500
Return

Exit:
	SetTimer, Move, Off
	Loop, %counter%
	{
		ctrl := ctrl_%A_Index%, window := window_%A_Index%
		If !ctrl
			Continue
		DllCall("SetParent", "UInt", ctrl_%A_Index%, "UInt", parent_%A_Index%)
		Gui, %A_Index%: Destroy
		WinMove, ahk_id %ctrl%,, 0, 0
		WinMove, ahk_id %window%,,,, % w_%A_Index%, % h_%A_Index% + 1
		WinMove, ahk_id %window%,,,, % w_%A_Index%, % h_%A_Index%
	}
ExitApp