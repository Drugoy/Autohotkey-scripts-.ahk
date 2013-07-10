#SingleInstance, Force
DetectHiddenWindows, On
SetTitleMatchMode, 3

; Choose step value (percents)
Step := 10

#Volume_Mute::
#Volume_Up::
#Volume_Down::
	WinGetClass, class, A	; Store active window's class to the var "class". Needed for Firefox only.
	If (class = "MozillaWindowClass")	; Fix for firefox (because it's window's title != it's title in sndvol.exe
		thisTitle := "Mozilla Firefox"
	Else If (class ~= "(Progman|Shell_TrayWnd)")	; Bind Desktop and Taskbar to control "System sounds"
	    thisTitle := "Системные звуки"	; OS Locale dependent code
	Else	; Handle the rest applications (not Desktop, Taskbar or Mozilla Firefox)
		WinGetActiveTitle, thisTitle	; Store acitve window's title to the var "thisTitle"
	Run, SndVol.exe,, Hide	; Run sndvol.exe hidden
	WinWait, ahk_class #32770 ahk_exe SndVol.exe	; Wait for it's window to appear
	If (A_ThisHotkey = "#Volume_Mute")	; Mute/unmute
	{
		ControlGet, thisHwnd, Hwnd,, % thisTitle ": отключить звук"	; Search for a hwnd of a control who's text ends with that phrase	; OS Locale dependent code
		TrayTip, % thisTitle, Muted or unmuted, 1, 1	; Show a traytip, that the active window's application was either muted or unmuted (I haven't yet found a way to distinguish these 2 states)
	}
	Else	; Change volume level (doesn't unmute)
		ControlGet, thisHwnd, Hwnd,, % thisTitle ": громкость"	; Search for a hwnd of a control who's text ends with that phrase	; OS Locale dependent code
	WinGet, listHwnd, ControlListHwnd	; Get a list of all controls' hwnds and store them into a var "listHwnd"
	If (A_ThisHotkey = "#Volume_Mute")	; The used hotkey should mute/unmute the volume

		ControlClick,, ahk_id %thisHwnd%	; Click the "mute" button that we found by it's Hwnd
	Else	; The used hotkey should change the volume level
	{
		thisHwnd := RegExReplace(listHwnd, "S).*" thisHwnd "`n(.*?)`n.*", "$1")	; Search for the hwnd of the next (to %thisHwnd%) item in the list of all controls, to reach the volume bar
		SendMessage, 0x0400,,,, ahk_id %thisHwnd%	; Get current volume level
		volLvl := A_ThisHotkey = "#Volume_Up" ? ErrorLevel - Step : ErrorLevel + Step	; Define whether to increase or to decrease the volume
		volLvl := volLvl > 100 ? 100 : volLvl < 0 ? 0 : volLvl	; Make "volLvl" obey the limitations  (volume level can't be lower than 0 or higher than 100)
		SendMessage, 0x0400 + 34, , % volLvl,, ahk_id %thisHwnd%	; Change the volume
		TrayTip, % thisTitle, % "Volume: " 100 - volLvl "%", 1, 1	; Notify user of current sound level of the active application
	}
	WinClose	; Close sndvol.exe window
	Return

; This script does the same as the script above, except it requires nircmd.
; #SingleInstance, Force
; #1::
; #2::Run % A_ScriptDir "\nircmd.exe changeappvolume focused " (A_ThisHotkey = "#1" ? "-" : "") "0.2"