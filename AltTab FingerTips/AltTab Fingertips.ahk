; AltTabFingertips by justice
; Thanks to ak_ for FileDraft from which I borrow the "menu at cursor" idea

; general configuration
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
DetectHiddenWindows, Off 
#SingleInstance,Force
SetWinDelay,0
Dir = %A_WorkingDir%
IniFile = settings.ini
FileCreateDir, %Dir%
SetWorkingDir, %Dir%
version = 1.3
ismenu=0;

; setting variables
ExclusionList =
AltTabFingertipsHK = F10
AltTabFingertipsEnabled =
this_windowcycle =
Processes =
IDs =
Titles =
maxItems = 
showingdesktop = 0

; main
Gosub,READINI
;Gosub,RegisterAutoUpdate
Gosub,SetHotKeys
GoSub, PrettyHotkeys
Traytip,AltTabFingertips, %AltTabFingertipsHKmsg%`t Switch between active apps.
Gosub,IndexWindows
OnExit, QUIT
GoSub, Standby

IndexWindows:
	Processes =
	IDs =
	Titles =
	maxItems = 
	myArray = 
	i=
	; acquire a list of processes to work with
	WinGet, id, list,,, Program Manager ; get list of all foreground ids
	Loop, %id%
	{
	  this_id := id%A_Index%
		WinGet, this_process, ProcessName, ahk_id %this_id%
		if NOT this_process ;exclude emptiness
			continue
		WinGetTitle, this_title, ahk_id %this_id%
		if NOT this_title ;exclude start menu and empty processes
				continue
		if this_title = MtMouseGlobalHook ;exclude some kind of hook
				continue
		StringGetPos, pos, ExclusionList, %this_process%
		i +=1
		IfWinExist, %this_title%
		{
				Processes%i% := this_process
				Titles%i% := this_title
				IDs%i% := this_id
		}
	}

	id = 
	maxItems := i
	GoSub, TRAYMENU
return

PrettyHotkeys:
	; Translate hotkey modifiers to proper English
	StringReplace, AltTabFingertipsHKmsg, AltTabFingertipsHK, +, Shift-, All
	StringReplace, AltTabFingertipsHKmsg, AltTabFingertipsHKmsg, #, Win-, All
	StringReplace, AltTabFingertipsHKmsg, AltTabFingertipsHKmsg, !, Alt-, All
	StringReplace, AltTabFingertipsHKmsg, AltTabFingertipsHKmsg, ^, Control-, All

return

SetHotKeys:
	if AltTabFingertipsHK
		Hotkey,%AltTabFingertipsHK%,AltTabFingertips, ON
return

CheckUpdate:
	; check for updates. 
	; When no updates are found nothing is displayed.
	; make sure the dcuhelper.exe is in a subdirectory of this script's location.
	cmdParams = -ri
	cmdParams2 = . -show -nothingexit
	GoSub, DcUpdateHelper
return

RegisterAutoUpdate:
	; Register with DcUpdater. 
	; When no updates are found nothing is displayed.
	; make sure the dcuhelper.exe is in a subdirectory of this script's location.
	cmdParams = -r
	cmdParams2 = . -shownew -nothingexit
	GoSub, DcUpdateHelper
return

DcUpdateHelper:
	uniqueID = svd-AltTabFingertips
	dcuHelperDir = %A_ScriptDir%\dcuhelper
	IfExist, %dcuHelperDir%\dcuhelper.exe
	{
		OutputDebug, %A_Now%: %dcuHelperDir%\dcuhelper.exe %cmdParams% "%uniqueID%" "%A_ScriptDir%" %cmdParams2%
		Run, %dcuHelperDir%\dcuhelper.exe %cmdParams% "%uniqueID%" "%A_ScriptDir%" %cmdParams2%,,Hide
	}
return




READINI:
	; Read the stored settings
	IfNotExist, %IniFile% 
		GoSub, WRITEINI
	IniRead, ExclusionList, %IniFile%, ExclusionList, list, %ExclusionList%		
	IniRead, ExclusionList, %IniFile%, ExclusionList, list, %ExclusionList%
	IniRead, AltTabFingertipsHK, %IniFile%, Hotkeys, AltTabFingertipsHK, %AltTabFingertipsHK%
return

WRITEINI:
	; Store settings
	IniWrite, %ExclusionList%, %IniFile%, ExclusionList, list
	IniWrite, %ExclusionList%, %IniFile%, ExclusionList, list
	IniWrite, %AltTabFingertipsHK%, %IniFile%, Hotkeys, AltTabFingertipsHK
return


TRAYMENU:
	Menu,Tray,NoStandard 
	Menu,Tray,DeleteAll 
	If maxItems ; if windows have been indexed
	{
		Loop, %maxItems% ; add checkboxes for every window
		{
			this_process := Processes%A_Index%
			Menu, ToggleStatus, add, %this_process%,ToggleStatus
			StringGetPos, pos, ExclusionList, %this_process%
			if NOT ErrorLevel
				Menu, ToggleStatus, Uncheck, %this_process%
			else
				Menu, ToggleStatus, Check, %this_process%			
		}
		Menu, tray, add, &Include, :ToggleStatus
	}
	Menu,Tray,Add,
	Menu,Tray,Add,AltTabFingertips,AltTabFingertips
	Menu,Tray,Add,
;	Menu,Tray,Add,&Check for Updates...,CheckUpdate
	Menu,Tray,Add,&Preferences,SETTINGS
	Menu,Tray,Add,
	Menu,Tray,Add,&About,ABOUT
	Menu,Tray,Add,&Online Help..,ONLINE
	Menu,Tray,Add,
	Menu,Tray,Add,&Exit,QUIT
Return

ABOUT:
	; make sure the hotkeys are translated
	GoSub,PrettyHotkeys
	Msgbox, AltTabFingertips %version% by justice <sander.vandragt@gmail.com>`n`n`t%AltTabFingertipsHKmsg%`t Switch between active apps.`n`nThanks to DonationCoder.com for feedback and testing!
return

ONLINE:
	Run,http://blog.amasan.co.uk/search/AltTabFingertips
return

QUIT:
ExitApp

ToggleStatus:
	Menu,ToggleStatus,ToggleCheck,%A_ThisMenuItem%
	StringGetPos, pos, ExclusionList, %A_ThisMenuItem%
	if NOT ErrorLevel ; found
			StringReplace, ExclusionList, ExclusionList, %A_ThisMenuItem%`,,,
	else
			ExclusionList = %ExclusionList%%A_ThisMenuItem%`,
	
	Gosub, WRITEINI
Return


AltTabFingertips:
	if ismenu = 1 
	{
		Menu,Fichiers,DeleteAll 
		ismenu = 0
	}
	GoSub,IndexWindows
	If maxItems ; if windows have been indexed
	{
		Loop, %maxItems% ; add checkboxes for every window
		{
			this_title := Titles%A_Index%
			WinGet, this_process, ProcessName, %this_title%	
	StringGetPos, pos, ExclusionList, %this_process%
	if ErrorLevel ; not found
	{
			Menu, Fichiers, Add, %this_title%, LaunchFile
			ismenu=1
		}
		}
	}

Menu, Fichiers, Add,
If showingdesktop = 0 
	Menu, Fichiers, Add, Show Desktop,ShowDesktop
Else
	Menu, Fichiers, Add, Restore Programs,ShowDesktop

Menu, Fichiers, Show
return

LaunchFile:
	WinActivate, %A_ThisMenuItem%
return

ShowDesktop:
If showingdesktop = 0 
		showingdesktop = 1
Else
		showingdesktop = 0
		
	Send #d
return

SETTINGS:
	Hotkey,%AltTabFingertipsHK%,Off
  	Gui, Destroy	
	Gui, Add, Text, x12 y12 w100 h23 , AltTabFingertips hotkey:
	Gui, Add, Hotkey, x132 y12 w170 h23 vAltTabFingertipsHK , %AltTabFingertipsHK%  
	Gui, Add, Button, x202 y87 w100 h23 GSETTINGSOK Default,&OK
	Gui, Add, Button, x92 y87 w100 h23 GSETTINGSCANCEL,&Cancel
	Gui, Show, x127 y87 h120 w320, AltTabFingertips Preferences
Return

GuiClose:
return


SETTINGSOK:
	Gui,Submit
	GoSub,SetHotKeys
	GoSub,WRITEINI
return

SETTINGSCANCEL:
	Gui,Destroy
return


Standby: