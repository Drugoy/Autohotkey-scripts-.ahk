/* BadWindowsSuppressor v0.1
Last time modified: 2015.06.22 09:40

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/BadWindowsSuppressor

Description:
	Closes unwanted windows based on the predefined rules. Can close windows that don't get closed by just WinClose and require user to hit some buttons.
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
#SingleInstance, Force
; SetBatchLines, 30
; ahk_group unwantedWindows - WinClose
; ahk_group nastyComplexWindows - Find parental proccess and close it (Process, Close)

SetTitleMatchMode, RegEx

OnExit, Exit
; Set up hooks to track easy-to-close windows appearing.
DllCall("RegisterShellHookWindow", "UInt", A_ScriptHwnd)
OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), "ShellProc")

;{ Easy-to-close windows.
; Skype
GroupAdd, unwantedWindows, i)Веб-браузер ahk_class #32770 ahk_exe skype.exe
GroupAdd, unwantedWindows, i)Skype.\s-\sОбновить ahk_class TUpgradeForm ahk_exe Skype.exe
GroupAdd, unwantedWindows, i)Skype.\s-\sВаше\sмнение\sо\sкачестве\sсвязи ahk_class TCallQualityForm ahk_exe skype.exe
; TeamViewer
GroupAdd, unwantedWindows, i)TeamViewer ahk_class HTML\sApplication\sHost\sWindow\sClass ahk_exe mshta.exe
; Steam
GroupAdd, unwantedWindows, i)Steam\s—\sНовости\sобновлений ahk_class USurface_.* ahk_exe steam.exe
; vSphere Client
GroupAdd, unwantedWindows, i)Remote\sdevice\sdisconnect ahk_class #32770 ahk_exe VpxClient.exe
;}

;{ Hard-to-close windows.
GroupAdd, nastyComplexWindows, Disconnect\s(USB\s)?(D|d)evice ahk_class #32770 ahk_exe VpxClient.exe	; vSphere Client: Click Button1 in this window.
GroupAdd, nastyComplexWindows, Спонсируемый сеанс ahk_class #32770 ahk_exe TeamViewer.exe	; TeamViewer's nagging window: Click Button4 in this window.
;{ Typical error screens of different programs using PortableApps.com Launcher, they appear after the program previously got closed not in the proper way.
/* %program% Portable (PortableApps.com Launcher)
%program% Portable did not close properly last time it was run and will now clean up. Please then start uTorrent Portable again manually.
*/
GroupAdd, nastyComplexWindows, TeamViewer Portable \(PortableApps\.com Launcher\) ahk_class #32770 ahk_exe TeamViewerPortable.exe	; TeamViewerPortable.exe
GroupAdd, nastyComplexWindows, uTorrent Portable \(PortableApps\.com Launcher\) ahk_class #32770 ahk_exe uTorrentPortable.exe	; uTorrentPortable.exe
;}
;}

WinClose, ahk_group unwantedWindows	; Close existing easy-to-close windows at script's startup.

; Main routine: wait for the hard-to-close windows to appear and then take necessary actions to close them.
Loop
{
	WinWait, ahk_group nastyComplexWindows
	WinGetTitle, thisTitle
	WinGetClass, thisClass
	WinGet, procName, ProcessName
	thisWinTitle := thisTitle " ahk_class " thisClass " ahk_exe " procName
	If (thisWinTitle ~= "Disconnect\s(USB\s)?(D|d)evice ahk_class #32770 ahk_exe VpxClient.exe")
		ControlClick, Button1
	Else If (thisWinTitle == "Спонсируемый сеанс ahk_class #32770 ahk_exe TeamViewer.exe")
		ControlClick, Button4
	Else If (thisWinTitle ~= "\w+\sPortable\s\(PortableApps\.com\sLauncher\)\sahk_class\s#32770\sahk_exe\s\w+Portable.exe")
	{
		WinGet, procPath, ProcessPath
		WinClose
		Process, WaitClose, %procName%, 3
		Run, %procPath%
	}
}

Exit: 
	DllCall("DeregisterShellHookWindow", "UInt", A_ScriptHwnd)
ExitApp
    
ShellProc(nCode)
{
	Critical
	If (nCode = 1)	; HSHELL_WINDOWCREATED
		WinClose, ahk_group unwantedWindows
}