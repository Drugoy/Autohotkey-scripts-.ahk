/* MasterScript.ahk
Version: 4.1
Last time modified: 2016.10.05 14:20
Compatible with AHK: 1.1.24.01.

Summary: a script manager for AHK scripts with bookmarks, autostart and process assistance support.

Description: this script is used for managing other ahk scripts:
	- bookmark folders on your disk to have quick access to some scripts;
	- bookmark scripts, so you can run/edit them quicker;
	- track running processes and get info about them: are they paused? are their hotkeys suspended? are their processes suspended? what are their processIDs? what are their names? what are their locations? - all that is shown on the "Processes" tab;
	- control processes of the running ahk scripts from outside: toggle suspend their hotkeys, toggle pause scripts, toggle suspend their processes, kill them, exit them, reload them, kill and re-execute them;
	- control tray icons of running scripts: hide/restore them, show tray menu;
	- configure autorun list to start scripts together with MasterScript automatically (+ you may choose to hide tray icons of those startup scripts);
	- configure "Process Assistant" rules: you may tell the script to assist one process with another. Process Assistant is a very powerful feature that has options to adjust how to assist processes: you may use Process Assistant so that running your game.exe will trigger the script gamehotkeys.ahk which will get closed when you close your game.exe. Or not - it's up to you how to configure your Process Assistant rules.

Thanks to: I've used a lot of pieces of code from scripts/functions/libs written by other people. I am very grateful to so many people, that I just can't name them all.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
http://forum.script-coding.com/viewtopic.php?id=8724
*/
/* TODO:
1. Decide what to do if a bookmarked item (folder or file) or a file related to an autorun or process assistant rule doesn't exist anymore. Should it be listed in the TV/LV? Should it get purged from settings? Should the user be notified? How?
2. It lacks small things like some context menus, 'Edit' button/menuitem for files and for running uncompiled scripts.
3. Add more description comments to functions.
*/
;{ Settings block.
; Path and name of the file name to store script's settings.
settingsPath := A_ScriptDir "\" SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4) "_settings.ini"
settings_O := readSettings(settingsPath)
; Specify a value in milliseconds.
settings_O.memoryScanInterval := 1000
; 1 = Make script store info (into the settings file) about it's window's size and position between script's closures. 0 = do not store that info in the settings file.
settings_O.rememberPosAndSize := 1
; 0 = the scripts in autorun will just be checked to made sure they are running. 1 = the scripts in autorun will get executed irregardless of whether they were already running before.
settings_O.forceExecAutostarts := 0
; 1 = use "exit" to end scripts, let them execute their 'OnExit' sub-routine. 0 = use "kill" to end scripts, that just instantly stops them, so scripts won't execute their 'OnExit' subroutines.
settings_O.quitAssistantsNicely := 1
;}
;{ Initialization.
#NoEnv	; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force
; #Warn	; Recommended for catching common errors.
DetectHiddenWindows, On	; Needed for 'pause' and 'suspend' commands, as well as for 'restoreTrayIcon()' function.
OnExit("exitApp")
WMIQueries_O := ComObjGet("winmgmts:"), scriptsSnapshot_AofO := [], procBinder := [], ownPID := DllCall("GetCurrentProcessId"), wParam := 0, oldSettings_O := readSettings(settings_O), activeTab := activeControl := selectedItemPath := ""

GroupAdd, ScriptHwnd_A, % "ahk_pid " ownPID ; Create an ahk_group "ScriptHwnd_A" and make all the current process's windows get into that group.

GoSub, CreateGUI
fillFoldersTV()
fillBookmarksLV()
fillAutorunsLV()
fillProcessesLV()
fillAssistantsLV()
TV_Modify(TV_GetNext(), "Select")	; Forcefully select topmost item in the TV and thus trigger update/fulfilment of 'fileLV' LV.
showGUI()

OnMessage(0x219, "WM_DEVICECHANGE")	; Track removable devices connecting/disconnecting to update the Folder Tree.
; Hooking ComObjects to track processes.
ComObjConnect(createSink := ComObjCreate("WbemScripting.SWbemSink"), "ProcessCreate_")
ComObjConnect(deleteSink := ComObjCreate("WbemScripting.SWbemSink"), "ProcessDelete_")
Command := "WITHIN 0.5 WHERE TargetInstance ISA 'Win32_Process'"
WMIQueries_O.ExecNotificationQueryAsync(createSink, "SELECT * FROM __InstanceCreationEvent " Command)
WMIQueries_O.ExecNotificationQueryAsync(deleteSink, "SELECT * FROM __InstanceDeletionEvent " Command)
assist()
Return
;}
;{+ CreateGUI (label).
CreateGUI:
		;{ Create image lists and populate it with icons for later use in GUI.
	IL_TVObjects := IL_Create(4)	; Create an ImageList to hold 4 icons.
		IL_Add(IL_TVObjects, "shell32.dll", 4)	; 'Folder' icon.
		IL_Add(IL_TVObjects, "shell32.dll", 80)	; 'Logical disk' icon.
		IL_Add(IL_TVObjects, "shell32.dll", 27)	; 'Removable disk' icon.
		; IL_Add(IL_TVObjects, "shell32.dll", 87)	; 'Folder with bookmarks' icon.
		IL_Add(IL_TVObjects, "shell32.dll", 206)	; 'Folder with bookmarks' icon.

	IL_scriptStates := IL_Create(6)	; Create an ImageList to hold 5 icons.
		IL_Add(IL_scriptStates, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 1)	; '[H]' default green AHK icon with letter 'H'.
		IL_Add(IL_scriptStates, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 3)	; '[S]' default green AHK icon with letter 'S'.
		IL_Add(IL_scriptStates, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 4)	; '[H]' default red AHK icon with letter 'H'.
		IL_Add(IL_scriptStates, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 5)	; '[S]' default red AHK icon with letter 'S'.
		IL_Add(IL_scriptStates, "shell32.dll", 21)	; A sheet with a clock (suspended process).
		IL_Add(IL_scriptStates, "imageres.dll", 12)	; A program's window (default .exe icon).

	IL_LVObject := IL_Create(2)	; Create an ImageList to hold 1 icon.
		IL_Add(IL_LVObject, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 2)	; default icon for AHK script.
		
		; IL_Add(IL1, "shell32.dll", 13)	; 'chip' icon.
		; IL_Add(IL1, "shell32.dll", 46)	; 'Up to the root folder' icon.
		; IL_Add(IL1, "shell32.dll", 71)	; 'Script' icon.
		; IL_Add(IL1, "shell32.dll", 138)	; 'Run' icon.
		; IL_Add(IL1, "shell32.dll", 272)	; 'Delete' icon.
		; IL_Add(IL1, "shell32.dll", 285)	; Neat 'Script' icon.
		; IL_Add(IL1, "shell32.dll", 286)	; Neat 'Folder' icon.
		; IL_Add(IL1, "shell32.dll", 288)	; Neat 'Bookmark' icon.
		; IL_Add(IL1, "shell32.dll", 298)	; 'Folders tree' icon.
		;}
		;{ Tray menu.
	Menu, Tray, NoStandard	; Remove all standard items from tray menu.
	Menu, Tray, Add, Manage Scripts, showGUI	; Create a tray menu's menuitem and bind it to a label that opens main window.
	Menu, Tray, Default, Manage Scripts	; Set 'Manage Scripts' menuitem as default action (will be executed if tray icon is left-clicked).
	Menu, Tray, Add	; Add an empty line (divider).
	Menu, Tray, Standard	; Add all standard items to the bottom of tray menu.
		;}
		;{ Context menu for 'folderTV' TV, 'fileLV' LV and 'bookmarksLV' LV.
	Menu, Tab1ContextMenu, Add, Run selected, runSelected
	Menu, Tab1ContextMenu, Add, Bookmark selected, bookmarkSelected
	Menu, Tab1ContextMenu, Add, Delete selected, deleteSelected
		;}
		;{ Context menu for 'processesLV' LV.
	Menu, MngProcContMenu, Add, Open, Open
	Menu, MngProcContMenu, Add, Reload, Reload
	Menu, MngProcContMenu, Add, Edit, Edit
	Menu, MngProcContMenu, Add, (Un) suspend hotkeys, SuspendHotkeys
	Menu, MngProcContMenu, Add, (Un) pause, Pause
	Menu, MngProcContMenu, Add, Exit, Exit
	Menu, MngProcContMenu, Add, Kill, Kill
	Menu, MngProcContMenu, Add, Kill and re-execute, killAndReRun
	Menu, MngProcContMenu, Add, (Un) suspend process, toggleSuspendProcess
	Menu, MngProcContMenu, Add, Hide tray icon(s), hideSelectedProcessesTrayIcons
	Menu, MngProcContMenu, Add, Restore tray icon(s), ahkProcessRestoreTrayIcon
	Menu, MngProcContMenu, Add, Show tray menu, showTrayMenu
		;}
	Gui, +Resize
		;{ StatusBar
	Gui, Add, StatusBar, vstatusBar
	SB_SetParts(60, 85)
		;}
		;{+ Add tabs and their contents.
	Gui, Add, Tab2, x0 y0 w799 h46 Choose1 +Theme -Background GTabSwitch VactiveTab, Files|AutoRuns|Processes|Process assistants
			;{+ Tab #1: 'Files'.
	Gui, Tab, Files
	Gui, Add, Text, x26 y26, Choose a folder:
	Gui, Add, Button, x532 y21 GrunSelected, Run selected
	Gui, Add, Button, x+0 GbookmarkSelected, Bookmark selected
	Gui, Add, Button, x+0 GdeleteSelected, Delete selected
				;{ Folders Tree (left pane).
	Gui, Add, TreeView, AltSubmit x0 y+0 GfolderTV VfolderTV HwndfolderTVHWND ImageList%IL_TVObjects%	; Add TreeView for navigation in the FileSystem.
				;}
				;{ File list (right pane).
	Gui, Add, ListView, AltSubmit x+0 +Grid GfileLV VfileLV HwndfileLVHwnd, Name|Size|Created|Modified
	LV_SetImageList(IL_LVObject)	; Assign ImageList 'IL_LVObject' to the current ListView.
	; Set the static widths for some of it's columns.
	LV_ModifyCol(2, 76)	; Size.
	LV_ModifyCol(2, "Integer")
	LV_ModifyCol(3, 117)	; Created.
	LV_ModifyCol(4, 117)	; Modified.
				;}
				;{ Bookmarks (bottom pane).
	Gui, Add, Text, vtextBS, Bookmarked scripts:
	Gui, Add, ListView, AltSubmit +Grid GbookmarksLV VbookmarksLV, #|Name|Full Path|Size|Created|Modified
	LV_SetImageList(IL_LVObject)	; Assign ImageList 'IL_LVObject' to the current ListView.
	; Set the static widths for some of it's columns
	LV_ModifyCol(1, 36)	; #.
	LV_ModifyCol(1, "Integer")
	LV_ModifyCol(4, 76)	; Size.
	LV_ModifyCol(4, "Integer")
	LV_ModifyCol(5, 117)	; Created.
	LV_ModifyCol(6, 117)	; Modified.
				;}
			;}
			;{ Tab #2: 'AutoRuns'.
	Gui, Tab, AutoRuns
	
	Gui, Add, Button, x656 y21 GaddAutorun, Add new
	Gui, Add, Button, x+0 GdeleteSelected, Delete selected
	Gui, Add, ListView, x0 y+0 +Checked +Grid -Multi +LV0x2 AltSubmit GautorunsLV HWNDautorunsLVHWND VautorunsLV, Enabled|Tray icon|Name|Path|Command line parameters
	LV_SetImageList(IL_scriptStates)	; Assign ImageList 'IL_scriptStates' to the current ListView.
	LV_ModifyCol(2, 60)
	LV_ModifyCol(3, 200)
			;}
			;{ Tab #3: 'Processes'.
	Gui, Tab, Processes
	
	; Add buttons to trigger functions.
	Gui, Add, Button, x1 y21 Gkill, Kill
	Gui, Add, Button, x+0 GkillAndReRun, Kill and re-run
	Gui, Add, Button, x+0 Gopen, Open
	Gui, Add, Button, x+0 Greload, Reload
	Gui, Add, Button, x+0 Gedit, Edit
	Gui, Add, Button, x+0 GsuspendHotkeys, (Un) suspend hotkeys
	Gui, Add, Button, x+0 Gpause, (Un) pause
	Gui, Add, Button, x+0 Gexit, Exit
	Gui, Add, Button, x+0 GtoggleSuspendProcess, (Un) suspend process
	Gui, Add, Button, x+0 GhideSelectedProcessesTrayIcons, Hide tray icon
	Gui, Add, Button, x+0 GahkProcessRestoreTrayIcon, Restore tray icon
	Gui, Add, Button, x+0 GshowTrayMenu, Show tray menu
	
	; Add the main "ListView" element and define it's size, contents, and a label binding.
	Gui, Add, ListView, x0 y+0 +Grid +Count25 +LV0x2 AltSubmit HWNDprocessesLVHWND GprocessesLV VprocessesLV, #|PID|Name|Path
	LV_SetImageList(IL_scriptStates)	; Assign ImageList 'IL_scriptStates' to the current ListView.
	; Set the static widths for some of it's columns
	
	LV_ModifyCol(1, 36)
	LV_ModifyCol(1, "Integer")	; This fixes sorting of the columns with numeric values.
	LV_ModifyCol(2, 64)
	LV_ModifyCol(2, "Integer")
			;}
			;{ Tab #4: 'Process assistants'.
	Gui, Tab, Process assistants
	Gui, Add, Button, x583 y21 GaddEditPA, Add new
	Gui, Add, Button, x+0 geditSelectedPA, Edit selected
	Gui, Add, Button, x+0 GdeleteSelected, Delete selected
	Gui, Add, ListView, x0 y+0 NoSortHdr +Grid -Multi AltSubmit VassistantsLV GassistantsLV, #|Act upon occurence|Act upon death|Bound together|Persistent|Condition|Assistant
	LV_SetImageList(IL_scriptStates)	; Assign ImageList 'IL_scriptStates' to the current ListView.
	LV_ModifyCol(1, 55)
	LV_ModifyCol(2, 20)
	LV_ModifyCol(3, 20)
	LV_ModifyCol(4, 20)
	LV_ModifyCol(5, 20)
			;}
		;}
	Gui, Default
Return
;}
;{+ GUI-related functions.
	;{ General functions of main GUI.
		;{ ShowGUI()	- shows the window and enables 'memoryScan' timer (if needed).
; Called by: initialization, 'tray menu' > 'Manage Scripts'.
showGUI()
{
	Global settings_O, activeTab
	If !(activeTab)	; After startup the 'activeTab' is empty.
		activeTab := "Files"
	Gui, Submit, NoHide
	If (settings_O.rememberPosAndSize && settings_O.xywh.x)	; If there are previously stored data.
		Gui, Show, % "x" settings_O.xywh.x " y" settings_O.xywh.y " w" settings_O.xywh.w - 16 " h" settings_O.xywh.h - 38, Manage Scripts
	Else
		Gui, Show, w830 h600 Center, Manage Scripts
	Gui, +MinSize830x600	; +Resize
	If (activeTab == "Processes")	; 'Processes' tab.
	{
		memoryScan()
		SetTimer, memoryScan, % settings_O.memoryScanInterval
	}
}
		;}
		;{ guiSize()	- resizes GUI controls to match the window's new size.
; Called by: automatically, upon minimizing, maximizing, restoring or resizing the window.
guiSize()
{
	Global folderTVHWND, activeTab, settings_O
	If (A_EventInfo != "1")	; The window has been resized or maximized.
	{
		workingAreaHeight := A_GuiHeight - 86
		GuiControl, Move, folderTV, % " h" (workingAreaHeight * 0.677)
		ControlGetPos,, FT_yCoord, FT_Width, FT_Height,, ahk_id %folderTVHWND%
		GuiControl, Move, textBS, % "x0 y" (FT_yCoord + FT_Height - 30)
		GuiControl, Move, fileLV, % "w" (A_GuiWidth - FT_Width + 30) " h" (workingAreaHeight * 0.677)
		Gui, ListView, fileLV
		LV_ModifyCol(1, A_GuiWidth - (FT_Width + 339))
		GuiControl, Move, bookmarksLV, % "x0 y" (FT_yCoord + FT_Height - 17) "w" (A_GuiWidth + 1) " h" (8 + workingAreaHeight * 0.323)
		Gui, ListView, bookmarksLV
		LV_ModifyCol(2, (A_GuiWidth - 366) * 0.35)
		LV_ModifyCol(3, (A_GuiWidth - 366) * 0.65)
		GuiControl, Move, autorunsLV, % "w" (A_GuiWidth + 1) " h" (workingAreaHeight + 42)
		Gui, ListView, autorunsLV
		LV_ModifyCol(4, (A_GuiWidth - 340) * 0.5)
		LV_ModifyCol(5, (A_GuiWidth - 340) * 0.5)
		GuiControl, Move, processesLV, % "w" (A_GuiWidth + 1) " h" (workingAreaHeight + 42)
		Gui, ListView, processesLV
		LV_ModifyCol(3, (A_GuiWidth - 128) * 0.3)
		LV_ModifyCol(4, (A_GuiWidth - 128) * 0.7)
		GuiControl, Move, assistantsLV, % "w" (A_GuiWidth + 1) " h" (workingAreaHeight + 42)
		Gui, ListView, assistantsLV
		LV_ModifyCol(6, (A_GuiWidth - 171) * 0.5)
		LV_ModifyCol(7, (A_GuiWidth - 171) * 0.5)
		If (activeTab == "Processes")
			SetTimer, memoryScan, % settings_O.memoryScanInterval
	}
}
		;}
		;{ guiClose()	- saves window position, closes it and turns off 'memoryScan' timer.
; Called by: automatically, upon the closure of script's main window.
guiClose()
{
	Global settings_O
	If (settings_O.rememberPosAndSize)
	{
		WinGetPos, sw_X, sw_Y, sw_W, sw_H, Manage Scripts ahk_class AutoHotkeyGUI
		If (sw_X && sw_X != -32000)	; Guarantees that the previous line didn't fail.
			settings_O.xywh.x := sw_X, settings_O.xywh.Y := sw_Y, settings_O.xywh.w := (sw_W < 846 ? 846 : sw_W), settings_O.xywh.h := (sw_H < 638 ? 638 : sw_H)	; 846x638 is the MinSize.

	}
	Gui, Hide
	SetTimer, memoryScan, Off
}
		;}
		;{ tabSwitch()	- hides/restores status bar and enables/disables 'memoryScan' timer.
; Called by: tabbar's G-Label, upon tab switch.
tabSwitch()
{
	Global activeTab
	Gui, Submit, NoHide
	If (activeTab == "Files")
		GuiControl, Show, statusBar
	Else
		GuiControl, Hide, statusBar	; It needs to be shown only on 'Files' tab.
	If (activeTab == "Processes")
	{
		memoryScan()
		SetTimer, memoryScan, % settings_O.memoryScanInterval
	}
	Else
		SetTimer, memoryScan, Off	; It needs to be turned on only on 'Processes' tab.
}
		;}
		;{ exitApp()	- saves window position, writes settings to the file and quits.
; Called by: automatically, whenever this script exits nicely.
exitApp()
{
	Global settings_O, oldSettings_O, settingsPath
	ObjRelease(WMIQueries_O), ObjRelease(createSink), ObjRelease(deleteSink)
	If (settings_O.rememberPosAndSize)
	{
		DetectHiddenWindows, Off
		IfWinExist, ahk_group ScriptHwnd_A
		{
			WinGetPos, sw_X, sw_Y, sw_W, sw_H, Manage Scripts ahk_class AutoHotkeyGUI
			If (sw_X && sw_X != -32000)	; Guarantees that the previous line didn't fail.
				settings_O.xywh.x := sw_X, settings_O.xywh.Y := sw_Y, settings_O.xywh.w := (sw_W < 846 ? 846 : sw_W), settings_O.xywh.h := (sw_H < 638 ? 638 : sw_H)	; 846x638 is the MinSize.

		}
		writeSettings(oldSettings_O, settings_O, settingsPath)
	}
	ExitApp
}
		;}
	;}
	;{+ Fill TV and LVs.
		;{ fillFoldersTV()		- fills 'folderTV'.
; Called by: initialization.
fillFoldersTV()
{
	Global settings_O

	Critical, On
	For k, v In settings_O.bookmarkedFolders
		buildTree(v, TV_Add(v,, "Icon4"))
	DriveGet, fixedDrivesList, List, FIXED	; Fixed logical disks.
	If !(ErrorLevel)
		Loop, Parse, fixedDrivesList	; Add all fixed disks to the TreeView.
			buildTree(A_LoopField ":", TV_Add(A_LoopField ":",, "Icon2"))
	DriveGet, removableDrivesList, List, REMOVABLE	; Removable logical disks.
	If !(ErrorLevel)
		Loop, Parse, removableDrivesList	; Add all removable disks to the TreeView.
			buildTree(A_LoopField ":", TV_Add(A_LoopField ":",, "Icon3"))
	Gui, TreeView, folderTV
	TV_Modify(TV_GetNext(), "Select")	; Forcefully select topmost item in the TV.

	Critical, Off
}
		;}
		;{ fillBookmarksLV()	- parses settings_O.bookmarkedFiles filling 'bookmarksLV'.
; Called by: initialization.
fillBookmarksLV()
{
	Global settings_O

	Critical, On
	Gui, ListView, bookmarksLV
	LV_Delete()
	For k, v In settings_O.bookmarkedFiles
		addBookmarkToLV(v)

	Critical, Off
}
		;}
		;{ fillAutorunsLV()		- parses settings_O.autoruns filling 'autorunsLV' LV and executing the parsed autoruns (and also hiding the tray icons, if needed).
; Called by: initialization.
fillAutorunsLV()
{
	Global settings_O, autorunsLVHWND
	Critical, On
	If !(settings_O.autoruns.Length())
	{
		Critical, Off
		Return
	}
	For k, arRule In settings_O.autoruns
	{
		SplitPath, % arRule.path, arRuleName
		Gui, ListView, autorunsLV
		newRowIndex := LV_Add((arRule.enabled ? "Check" : "") " Icon99",,, arRuleName, arRule.path, arRule.parameters)
		If (arRule.trayIcon)	; Draw an icon if the rule doesn't suppose to hide the tray icon of that script.
			LV_SetCellIcon(autorunsLVHWND, newRowIndex, 2, 1)
		If (arRule.enabled)	; Execute the script and decide whether to hide its tray icon.
		{
			WinGet, arRulePID, PID, % "ahk_exe " arRule.path	; This will catch exe's, but not uncompiled .ahk script processes.
			If !(arRulePID)	; Attempt #2.
			{
				currentTMM := A_TitleMatchMode
				SetTitleMatchMode, RegEx
				WinGet, arRulePID, PID, % "Si)^\Q" arRule.path "\E\s-\sAutoHotkey\sv[\d\.]+$ ahk_class AutoHotkey"	; This will catch uncompiled .ahk script processes.
				SetTitleMatchMode, % currentTMM
			}
			If ((!arRulePID || settings_O.forceExecAutostarts) && (FileExist(arRule.path)))
			{
				arRuleWasNotRunning := 1
				Run, % arRule.path " " arRule.parameters,,, arRulePID
			}
			If !(arRule.trayIcon)
			{
				While !(arRuleHWND)
					WinGet, arRuleHWND, ID, ahk_class AutoHotkey ahk_pid %arRulePID%
				While !(TrayIcon_Remove(arRuleHWND) || A_Index == 5 || !arRuleWasNotRunning)
					Sleep, 10
			}
		}
		arRulePID := arRuleHWND := arRuleWasNotRunning := ""
	}

	Critical, Off
}
		;}
		;{ fillProcessesLV()	- executes a WMI query to retrieve a list of running processes and uses these data to fill 'scriptsSnapshot_AofO' object and 'processesLV'.
; Called by: initialization.
fillProcessesLV()
{
	Global WMIQueries_O, settings_O, scriptsSnapshot_AofO, processesLVHWND

	Critical, On

; Fill scriptsSnapshot_AofO[] arrays with data and 'processesLV' LV.
	Gui, ListView, processesLV
	For process In WMIQueries_O.ExecQuery("SELECT ProcessId,ExecutablePath,CommandLine,Caption,Description FROM Win32_Process")	; Parsing through a list of running processes to filter out non-ahk ones (filters are based on 'If RegExMatch(…)' rules).
	{	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
		If !(process.ProcessId) || (process.ProcessId = 4) || (process.CommandLine = "\SystemRoot\System32\smss.exe") || (process.Caption = "auidiodg.exe" && process.Description = "audiodg.exe")	; PID 0 = System Idle Process, PID 4 = System, smss.exe and audidg.exe have no ExecutablePath and audiodg.exe has no CommandLine.
			Continue
		For k, v In settings_O.ignoredProcesses
			If (v == process.ExecutablePath)
				Continue, 2
		WinGetClass, class, % "ahk_pid " process.ProcessId
		If ((process.ExecutablePath == A_AhkPath && RegExMatch(process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script) && RegExMatch(process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script)) || (class == "AutoHotkey"))
		{
			If (process.ExecutablePath != A_AhkPath)
			{
				SplitPath, % process.ExecutablePath, scriptName
				scriptPath := process.ExecutablePath
			}
			iconIndex := (isProcessSuspended(process.ProcessId) ? 5 : 1 + getScriptState(process.ProcessId))	; The number from 1 to 5, which is the index of the icon in the 'IL_scriptStates' IL.
			scriptsSnapshot_AofO.Push({"pid": process.ProcessId, "name": scriptName, "path": scriptPath, "icon": iconIndex})
			newRowIndex := LV_Add("Icon" iconIndex, scriptsSnapshot_AofO.MaxIndex(), process.ProcessId, scriptName, scriptPath)	; Add the script to the LV with the proper icon and proper values for all columns.
			If (scriptName ~= "Si)^.*\.exe$")
				LV_SetCellIcon(processesLVHWND, newRowIndex, 3, 6)
		}
	}

	Critical, Off
}
		;}
		;{ fillAssistantsLV()	- parses settings_O.assistants filling 'assistantsLV'.
; Called by: initialization.
fillAssistantsLV()
{
	Global settings_O
	Critical, On

	Gui, ListView, assistantsLV
	LV_Delete()
	If !(settings_O.assistants.MaxIndex())	; There is nothing to do if there are no rules yet.
	{
		Critical, Off
		Return
	}
	For k, v In settings_O.assistants
	{
		Loop, % (v.TCg.MaxIndex() > v.TAg.MaxIndex() ? v.TCg.MaxIndex() : v.TAg.MaxIndex())
		{
			If (A_Index == 1)
				LV_Add("Icon" v.enabled, k, v.actUponOccurence, v.actUponDeath, v.bindAllToAll, v.persistent, v.TCg[1], v.TAg[1])
			Else
				LV_Add("Icon0",,,,,, v.TCg[A_Index], (v.bindAllToAll == 1 ? "" : v.TAg[A_Index]))
		}
	}

	Critical, Off
}
		;}
	;}
	;{+ Update TV and LVs.
		;{ buildTree(folder, parentItemID = 0) - modifies 'folderTV' TV.
; Input: folder's path and parentItemID (ID of an item in a TreeView).
; Called by:
;	Functions: fillFoldersTV(), WM_DEVICECHANGE(), bookmarkSelected().
;	GUI controls G-labels: 'folderTV'.
buildTree(folder, parentItemID = 0)
{

	Critical, On
	Gui, TreeView, folderTV
	If (folder)
		Loop, %folder%\*, 2   ; Inception: retrieve all of Folder's sub-folders.
		{
			parent := TV_Add(A_LoopFileName, parentItemID, "Icon1")	; Add all of those sub-folders to the TreeView.
			Loop, %A_LoopFileFullPath%\*, 2   ; We need to go deeper (c).
			{
				TV_Add("Please, close and re-open the parental folder", parent, "Icon2")
				Break	; No need to add more than 1 item: that's needed just to make the parent item expandable (anyways it's contents will get re-constructed when that item gets expanded).
			}
		}

	Critical, Off
}
		;}
		;{ Track removable drives appearing/disappearing and rebuild TreeView when needed.
WM_DEVICECHANGE(wp, lp, msg, hwnd)	; Add/remove data to the 'folderTV' TV about connected/disconnected removable disks.
; Input: system message details sent to the windows of this script.
; Called by: system, upon receiving message "0x219" (when a removable devices is connected/disconnected). For some reason it's called twice every time a disk got (dis)connected.
{

	Critical, On
	If (hwnd = A_ScriptHwnd && (wp = 0x8000 || wp = 0x8004) && NumGet(lp + 4, "UInt") = 2)	; 0x8000 == DBT_DEVICEARRIVAL, 0x8004 == DBT_DEVICEREMOVECOMPLETE, 2 == DBT_DEVTYP_VOLUME
	{
		dbcv_unitmask := NumGet(lp + 12, "UInt")
		driveLetter := Chr(Asc("A") + ln(dbcv_unitmask) / ln(2))
		Loop
		{
			driveID := TV_GetNext(driveID)
			TV_GetText(thisDrive, driveID)
			StringLeft, thisDrive, thisDrive, 1
		} Until (driveLetter == thisDrive) || !(driveID)
		If (wp == 0x8000) && (driveLetter != thisDrive)
			buildTree(driveLetter ":", TV_Add(driveLetter ":",, "Icon3"))
		Else If (wp == 0x8004) && (driveID)
			TV_Delete(driveID)
	}

	Critical, Off
}
		;}
		;{ bookmarkSelected()	- gets selected rows in 'fileLV' or 'folderTV' (depending on which one of them is active) and bookmarks those items, updating both: 'settings_O' object and either 'folderTV' or 'bookmarksLV'.
; Called by:
;	Buttons: 'Bookmark selected' (tab #1 'Files').
;	Menuitems: 'folderTV' > 'Bookmark selected', 'fileLV' > 'Bookmark selected'.
bookmarkSelected()
{
	Global activeControl, settings_O

	Critical, On
	If (activeControl == "fileLV")	; Bookmark a file.
	{
		Gui, ListView, fileLV
		For k, v In getScriptNames()
			settings_O.bookmarkedFiles.Push(v), addBookmarkToLV(v)
	}
	Else If (activeControl == "folderTV")	; Bookmark a folder.
	{
		settings_O.bookmarkedFolders.Push(selectedItemPath)
		buildTree(selectedItemPath, TV_Add(selectedItemPath,, "Vis Icon4"))
	}

	Critical, Off
}
		;}
		;{ addBookmarkToLV(pathToFile_S)	- adds a new row to 'bookmarksLV' (if file exist by specified path).
; Input: pathToFile_S - string with path to file.
; Called by:
; 	Functions: fillBookmarksLV(), bookmarkSelected().
addBookmarkToLV(pathToFile_S)
{

	Critical, On
	Gui, ListView, bookmarksLV
	IfExist, % pathToFile_S	; Check whether the previously bookmared file exists.
	{	; If the file exists - display it in the LV.
		SplitPath, pathToFile_S, fileName
		FileGetSize, fileSize, %pathToFile_S%
		FileGetTime, fileCreatedDate, %pathToFile_S%, C
		FormatTime, fileCreatedDate, %fileCreatedDate%, yyyy.MM.dd   HH:mm:ss	; Transofrm creation date into a readable format.
		FileGetTime, fileModifiedDate, %pathToFile_S%	; Get file's last modification date.
		FormatTime, fileModifiedDate, %fileModifiedDate%, yyyy.MM.dd   HH:mm:ss	; Transofrm creation date into a readable format.
		LV_Add("Icon1", LV_GetCount() + 1, fileName, pathToFile_S, Round(fileSize / 1024, 1) " KB", fileCreatedDate, fileModifiedDate)
	}
	; Else	; The file doesn't exist. Delete it?

	Critical, Off
}
		;}
		;{ addAutorun()	- opens a new window with prompt to add a new autorun rule.
; Called by:
;	Buttons: 'Add new' (tab #2 'AutoRuns').
addAutorun()
{
	Global settings_O, scriptPathEdit, scriptArgsEdit, hideTrayIcon, autorunsLV, autorunsLVHWND
	Gui, NewAutorun: New
	Gui, Add, Text,, Select script's file:
	Gui, Add, Edit, r1 w527 VscriptPathEdit
	Gui, Add, Button, x+6 GfileSelect, Browse
	Gui, Add, Text, x10, Specify command line arguments (optionally):
	Gui, Add, Edit, r1 w579 VscriptArgsEdit
	Gui, Add, Checkbox, x10 VhideTrayIcon, Hide tray icon on start
	Gui, Add, Button, x520 y130 GfinishAddingNewAutorun, Add this rule

	Gui, Show, w600 h160, Add new 'AutoRun' rule
	Return

	fileSelect:
		FileSelectFile, scriptPath, 3,, Select AHK script file, AHK scripts (*.ahk; *.exe)
		GuiControl,, scriptPathEdit, % scriptPath
	Return

	finishAddingNewAutorun:
		Gui, NewAutorun: Submit, NoHide
		If !(scriptPathEdit ~= "Si)^.*\.(ahk|exe)$")
		{
			MsgBox, 16, Error, Specified path doesn't point to a script file (*.ahk or *.exe)!
			Return
		}
		Else
		{
			settings_O.autoruns.Push({"enabled": "0", "trayIcon": (trayIcon ? "1" : "0"), "path": scriptPathEdit, "parameters": scriptArgsEdit})
			Gui, NewAutorun: Submit
			SplitPath, scriptPathEdit, scriptName
			Gui, 1: Default
			Gui, ListView, autorunsLV
			newRowIndex := LV_Add(,,, scriptName, scriptPathEdit, scriptArgsEdit)
			If !(hideTrayIcon)
				LV_SetCellIcon(autorunsLVHWND, newRowIndex, 2, 1)
		}
	Return
}
		;}
		;{+ addEditPA()	- a function that by default opens a new window with prompt to add a new process assistant rule, however the function also contains a set of labels needed to edit an existing process assistant rule.
addEditPA()		
{
	Global settings_O, thisPAEnabled_B, actUponOccurence_B, actUponDeath_B, bindAllToAll_B, persistent_B, trigger_S, dependentsTopText_P, addDependent_P, dependent_S, affects_P
	GoSub, addEditPAGUI
	Gui, addEditPA: Show,, New rule
	ruleToEdit_N := ""
	Return
			;{+ Labels
				;{ addEditPAGUI	- creates a window to add/edit a Process Assistant.
	addEditPAGUI:
		Gui, addEditPA: New
		Gui, Add, Checkbox, VthisPAEnabled_B, Enable rule.
		Gui, Add, Checkbox, VactUponOccurence_B GactUponOccurence_B Checked, Act upon occurence: if any trigger occures - dependent(s) will get executed.
		Gui, Add, Checkbox, VactUponDeath_B GactUponDeath_B, % "Act upon death: if any trigger dies - dependent(s) will get " (settings_O.quitAssistantsNicely ? "stopped." : "killed.")
		Gui, Add, Checkbox, w550 VbindAllToAll_B GbindAllToAll_B , Many-as-one: group all processes reciprocally together: running one will run the whole group.
		Gui, Add, Checkbox, w760 h39 Vpersistent_B Gpersistent_B, Make the rule persistent: or "keep state" (treat 'act upon occurence/death' as 'act if trigger is alive/dead').`nFor example: if execution of a.exe triggers execution of b.exe`, but b.exe later died while a.exe is still alive - then b.exe will be re-executed.
		Gui, Add, Text, x30, Specify full or partial paths to the triggering executables.
		; Gui, Add, Button, GaddTrigger x10 y130, +
		Gui, Add, Button, GaddTrigger x10, +
		Gui, Add, Edit, x30 y145 w360 Vtrigger_S R15
		Gui, Add, Text, x420 y127 VdependentsTopText_P, Specify full or partial paths to the dependent executables.
		Gui, Add, Button, GaddDependent_P VaddDependent_P x400 y145, +
		Gui, Add, Edit, x420 y145 w360 Vdependent_S R15
		Gui, Add, Text, x10 y+10, Notes:`n1. You may use partial paths if you like (the left part in the path may be omitted).`n2. Adding or editing a process assistant rule doesn't scan the already running processes - it will work only with new ones.
		Gui, Add, Button, GsavePA x750 y+0, Save
		Gui, Add, Text, x400 y220 vaffects_P, ⇒
	Return
				;}
				;{ actUponOccurence_B, actUponDeath_B	- makes sure one of them remains checked.
	actUponOccurence_B:	; Assistant rule's 'add new/edit selected' checkbox'es g-label.
	actUponDeath_B:	; Assistant rule's 'add new/edit selected' checkbox'es g-label.
		Gui, addEditPA: Submit, NoHide
		If !(%A_ThisLabel%)
			GuiControl, addEditPA:, % (A_ThisLabel = "actUponOccurence_B" ? "actUponDeath_B" : "actUponOccurence_B"), 1
		Gui, addEditPA: Submit, NoHide
		GuiControl, addEditPA: Text, bindAllToAll_B, % "Many-as-one: group all processes reciprocally together: " (actUponOccurence_B ? (actUponDeath_B ? "running or " (settings_O.quitAssistantsNicely ? "stopping" : "killing") : "running") : (settings_O.quitAssistantsNicely ? "stopping" : "killing")) " one will " (actUponOccurence_B ? (actUponDeath_B ? "run or " (settings_O.quitAssistantsNicely ? "stop" : "kill") : "run") : (settings_O.quitAssistantsNicely ? "stop" : "kill")) " the whole group."
		GuiControl, addEditPA: Text, persistent_B, % "Keep state: if 'a.exe' triggers 'b.exe', then process assistant will make sure that:" (actUponOccurence_B ? "`nwhile a.exe is running - b.exe will always run too (even if b.exe later dies - it will get re-executed)" : "") (actUponOccurence_B && actUponDeath_B ? " and " : "") (actUponDeath_B ? "`nwhile a.exe is not running - b.exe will be suppressed (even if b.exe gets manually executed - it will get " (settings_O.quitAssistantsNicely ? "stopped" : "killed") ")"  : "") "."
	Return
				;}
				;{ bindAllToAll_B	- transforms GUI making it have either 1 or 2 'edit' fields + whether to disable or enable the 'persistent_B' checkbox.
	bindAllToAll_B:	; 'Bind all to all' checkbox'es g-label.
		Gui, addEditPA: Submit, NoHide
		GuiControl, addEditPA: Move, trigger_S, % "w" (bindAllToAll_B ? "750" : "360")
		GuiControl, % "addEditPA:" (bindAllToAll_B ? "Disable" : "Enable"), persistent_B
		If (bindAllToAll_B)
			GuiControl, addEditPA:, persistent_B, 0
		For k, v In ["affects_P", "dependent_S", "dependentsTopText_P", "addDependent_P"]
			GuiControl, % "addEditPA:" (bindAllToAll_B ? "Hide" : "Show"), %v%
		Gui, addEditPA: Submit, NoHide
	Return
				;}
				;{ persistent_B	- disables/enables 'bindAllToAll_B' checkbox.
	persistent_B:
		Gui, addEditPA: Submit, NoHide
		GuiControl, % "addEditPA:" (persistent_B ? "Disable" : "Enable"), bindAllToAll_B
		If (persistent_B)
			GuiControl, addEditPA:, bindAllToAll_B, 0
		Gui, addEditPA: Submit, NoHide
	Return
				;}
				;{ addTrigger, addDependent_P	- G-Labels of buttons that open Explorer Window.
	addTrigger:	; gLabel of left "+" button in the 'New/edit rule' window.
	addDependent_P:	; gLabel of right "+" button in the 'New/edit rule' window.
		FileSelectFile, selectedFiles_S, MS,, Select executables or ahk-scripts, Processes or scripts (*.exe; *.ahk)	; M option makes the output have stupid format.
		If (ErrorLevel)	; In case user canceled file selection.
			Return
		If (A_ThisLabel = "addTrigger")
		{
			GuiControlGet, trigger_S
			trigger_S .= fixFSFOutput(selectedFiles_S)
			GuiControl, addEditPA:, trigger_S, %trigger_S%
		}
		Else
		{
			GuiControlGet, dependent_S
			dependent_S .= fixFSFOutput(selectedFiles_S)
			GuiControl, addEditPA:, dependent_S, %dependent_S%
		}
	Return
				;}
				;{ editSelectedPA	- G-Labelof 'Edit selected' button.
	editSelectedPA:
		Gui, 1: ListView, assistantsLV
		If !(LV_GetCount("Selected"))	; If no assistant is selected.
			LV_Modify(1, "Select")	; Forcefully select 1st one.
		ruleToEdit_N := ""
		While !(ruleToEdit_N)	; Find rule number by getting 1st column's value (and move upwards if it's blank).
			LV_GetText(ruleToEdit_N, LV_GetNext() + 1 - A_Index, 1)	; ruleToEdit_N will contain the number of the rule related to the selected row.
		GoSub, addEditPAGUI
		GuiControl, addEditPA:, thisPAEnabled_B, % settings_O.assistants[ruleToEdit_N].enabled
		GuiControl, addEditPA:, actUponOccurence_B, % settings_O.assistants[ruleToEdit_N].actUponOccurence
		GuiControl, addEditPA:, actUponDeath_B, % settings_O.assistants[ruleToEdit_N].actUponDeath
		GuiControl, addEditPA:, bindAllToAll_B, % settings_O.assistants[ruleToEdit_N].bindAllToAll
		GuiControl, addEditPA:, persistent_B, % settings_O.assistants[ruleToEdit_N].persistent
		GuiControl, addEditPA:, trigger_S, % arr2ASV(settings_O.assistants[ruleToEdit_N].TCg, "`n")
		GuiControl, addEditPA:, dependent_S, % arr2ASV(settings_O.assistants[ruleToEdit_N].TAg, "`n")
		Gui, addEditPA: Show,, Edit rule #%ruleToEdit_N%
	Return
				;}
				;{ savePA	- gLabel of the 'save' button in the 'New/edit rule' window.
	savePA:
		;{ Check input.
		Gui, addEditPA: Submit, NoHide
		trigger_S := Trim(trigger_S, " `n`r`t"), dependent_S := Trim(dependent_S, " `n`r`t")
		GuiControlGet, trigger_S,, trigger_S
		If !(trigger_S)
		{
			MsgBox, Error!`nNo triggers specified!
			Return
		}
		GuiControlGet, bindAllToAll_B,, bindAllToAll_B
		If (bindAllToAll_B)
		{
			IfNotInString, trigger_S, `n
			{
				MsgBox, When selecting 'Many-as-One' there's no point in a rule with only 1 trigger.
				Return
			}
		}
		GuiControlGet, dependent_S,, dependent_S
		If (!bindAllToAll_B && !dependent_S)
		{
			MsgBox, Error!`nNo dependents specified!
			Return
		}
		For k, v In ["thisPAEnabled_B", "actUponOccurence_B", "actUponDeath_B", "persistent_B"]
			GuiControlGet, %v%,, %v%
		Gui, addEditPA: Destroy
		;}
		;{ Update 'settings_O' and 'assistantsLV'.
		Gui, 1: Default
		Gui, ListView, assistantsLV
		trigger_A := ASV2Arr(trigger_S, "`n"), dependent_A := ASV2Arr(dependent_S, "`n")
		If !(ruleToEdit_N)	; If user added new rule.
		{
			settings_O.assistants.Push({"enabled": thisPAEnabled_B, "actUponOccurence": actUponOccurence_B, "actUponDeath": actUponDeath_B, "bindAllToAll": bindAllToAll_B, "persistent": persistent_B, "TCg": trigger_A, "TAg": dependent_A})
			Loop, % (trigger_A.MaxIndex() > dependent_A.MaxIndex() ? trigger_A.MaxIndex() : dependent_A.MaxIndex())
			{
				If (A_Index == 1)
					LV_Add("Icon" thisPAEnabled_B, settings_O.assistants.MaxIndex(), actUponOccurence_B, actUponDeath_B, bindAllToAll_B, persistent_B, trigger_A[1], dependent_A[1])
				Else
					LV_Add("Icon0",,,,,, trigger_A[A_Index], (bindAllToAll_B == 1 ? "" : dependent_A[A_Index]))
			}
		}
		Else
			settings_O.assistants[ruleToEdit_N] := {"enabled": thisPAEnabled_B, "actUponOccurence": actUponOccurence_B, "actUponDeath": actUponDeath_B, "bindAllToAll": bindAllToAll_B, "persistent": persistent_B, "TCg": trigger_A, "TAg": dependent_A}, fillAssistantsLV()
		;}
	Return
				;}
			;}
}
		;}
		;{ deleteSelected()	- deletes stuff associated with the selection in existing TreeView or ListViews.
; Called by:
;	Buttons: 'Delete selected' (tab #1 'Files', tab #2 'AutoRuns', tab #4 'Process assistants').
;	Menuitems: 'folderTV' > 'Delete selected', 'bookmarksLV' > 'Delete selected', 'fileLV' > 'Delete selected'.
deleteSelected()
{

	Critical, On
	Global settings_O, activeTab, activeControl
	If (activeControl != "folderTV")
		Gui, ListView, %activeControl%
	If (activeTab == "Files")
	{
		If (activeControl == "bookmarksLV")
		{
			selected := getSelectedRows(1)
			If (selected.Length())
			{
				For k, v In selected
					LV_Delete(v), settings_O.bookmarkedFiles.RemoveAt(v)
				; Re-count indexes in 1st column.
				For k, v In settings_O.bookmarkedFiles
				{
					LV_GetText(LVindex, A_Index, 1)
					If (A_Index != LVindex)
						LV_Modify(A_Index, "Integer", A_Index)
				}
			}
		}
		Else If (activeControl == "fileLV")	; In case the last active GUI element was "fileLV" ListView.
		{
			selected := getScriptNames()
			If (selected.MaxIndex() == 0)
			{
				Critical, Off
				Return
			}

			Critical, Off
			Msgbox, 1, Confirmation required, % "Are you sure want to delete the selected file(s)?`n" arr2ASV(selected, "`n")
			IfMsgBox, OK
			{

				Critical, On
				For k, v In selected
					FileDelete, %v%
				Gui, ListView, fileLV
				selected := getSelectedRows(1)
				For k, v In selected
					LV_Delete(v)

				Critical, Off
			}
		}
		Else If (activeControl == "folderTV")	; In case the last active GUI element was 'folderTV' TreeView.
		{	; Then we should delete a bookmarked folder.
			For k, v In settings_O.bookmarkedFolders
			{
				If (v == selectedItemPath)
				{
					TV_Delete(TV_GetSelection())
					settings_O.bookmarkedFolders.RemoveAt(k)
					Break
				}
			}
		}
	}
	Else If (activeTab == "AutoRuns")
	{
		selected_N := LV_GetNext()
		LV_Delete(selected_N)
		settings_O.autoruns.RemoveAt(selected_N)
	}
	Else If (activeTab == "Process assistants")
	{
		selected_N := ""
		While !(selected_N)	; Find rule number by getting 1st column's value (and move upwards if it's blank).
			LV_GetText(selected_N, LV_GetNext() + 1 - A_Index, 1)	; 'selected_N' will contain the number of the rule related to the selected row.
		MsgBox, 4, Confirmation required, Are you sure you'd like to delete assistant rule #%selected_N%?
		IfMsgBox, Yes
			settings_O.assistants.RemoveAt(selected_N), fillAssistantsLV()
	}

	Critical, Off
}
		;}
	;}
	;{ statusbarUpdate(fileCount, size, path)	- updates the three parts of the status bar to show info about the currently selected folder.
; Input:
;	fileCount - a number of files in the viewed directory.
;	size - size of files in the viewed directory.
;	path - path of the viewed directory.
; Called by:
;	Functions: folderTV().
statusbarUpdate(fileCount, size, path)
{
	SB_SetText(fileCount " files", 1)
	SB_SetText(Round(size / 1024, 1) " KB", 2)
	SB_SetText(path, 3)
}
	;}
	;{+ G-Labels associated with the TV/LVs.
		;{ folderTV()	- reacts to clicks sent to 'folderTV'.
folderTV()
{

	Critical, On
	Global activeControl := A_ThisFunc, selectedItemPath
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "RightClick") || (A_GuiEvent == "S") || (A_GuiEvent == "+")	; In case of script's initialization, user's left click, keyboard selection or tree expansion - (re)fill the 'fileLV' listview.
	{
		If (A_GuiEvent == "Normal") || (A_GuiEvent == "RightClick")	; If user left clicked an empty space at right from a folder's name in the TreeView.
		{
			If (A_EventInfo)	; If user clicked on a line's empty space.
				TV_Modify(A_EventInfo, "Select")	; Forcefully select that line.
			Else	; If user clicked on the empty space unrelated to any item in the tree.
			{
				Critical, Off
				Return	; We should react only to A_GuiEvents with "S" and "+" values.
			}
		}
			;{ Determine the full path of the selected folder:
		Gui, TreeView, folderTV
		TV_GetText(selectedItemPath, A_EventInfo)
		Loop	; Build the full path to the selected folder.
		{
			parentID :=	(A_Index == 1) ? TV_GetParent(A_EventInfo) : TV_GetParent(parentID)
			If !(parentID)	; No more ancestors.
				Break
			TV_GetText(parentText, parentID)
			selectedItemPath := parentText "\" selectedItemPath
		}
			;}
			;{ Rebuild TreeView, if it was expanded.
		If (A_GuiEvent == "+") || (A_GuiEvent == "Normal" && A_EventInfo)	; If a tree got expanded.
		{
			Loop, %selectedItemPath%\*.*, 2	; Parse all the children of the selected item.
			{
				thisChildID := TV_GetChild(A_EventInfo)	; Get first child's ID.
				If (thisChildID)	; && A_EventInfo
					TV_Delete(thisChildID)
			}
			buildTree(selectedItemPath, A_EventInfo)	; Add children and grandchildren to the selected item.
		}
			;}
			;{ Update 'fileLV'.
		oldDefLV := A_DefaultListView
		Gui, ListView, fileLV
		GuiControl, -Redraw, fileLV	; Improve performance by disabling redrawing during load.
		LV_Delete()	; Delete old data.
		fileCount := totalSize := 0	; Init prior to loop below.
		Loop, %selectedItemPath%\*.ahk	; This omits folders and shows only .ahk-files in the ListView.
		{
			FormatTime, created, %A_LoopFileTimeCreated%, yyyy.MM.dd   HH:mm:ss
			FormatTime, modified, %A_LoopFileTimeModified%, yyyy.MM.dd   HH:mm:ss
			LV_Add("Icon1", A_LoopFileName, Round(A_LoopFileSize / 1024, 1) . " KB", created, modified)
			fileCount++
			totalSize += A_LoopFileSize
		}
		GuiControl, +Redraw, fileLV
			;}
		statusbarUpdate(fileCount, totalSize, selectedItemPath)
		If (A_GuiEvent == "RightClick")	; Show context menu if user right clicked anything in the TV + disable 'bookmark selected' command there in case he clicked an already bookmarked folder.
		{
			Loop, Parse, bookmarkedFolders, |
			{
				If (selectedItemPath = A_LoopField)
				{
					bookmarkedFolderDetected := 1
					Menu, Tab1ContextMenu, Disable, Bookmark selected
					Break
				}
			}
			Menu, Tab1ContextMenu, Show
			If (bookmarkedFolderDetected)
			{
				bookmarkedFolderDetected := 0
				Menu, Tab1ContextMenu, Enable, Bookmark selected
			}
		}
		Gui, ListView, % oldDefLV
	}

	Critical, Off
}
		;}
		;{ fileLV()
fileLV()
{

	Critical, On
	Global activeControl
	Gui, ListView, % A_ThisFunc
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "RightClick")
		activeControl := A_ThisFunc
	If (A_GuiEvent == "RightClick")
		Menu, Tab1ContextMenu, Show

	Critical, Off
}
		;}
		;{ bookmarksLV()
bookmarksLV()
{

	Critical, On
	Global activeControl
	Gui, ListView, % A_ThisFunc
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "RightClick")
		activeControl := A_ThisFunc
	If (A_GuiEvent == "RightClick")
	{
		Menu, Tab1ContextMenu, Disable, Bookmark selected
		Menu, Tab1ContextMenu, Delete, Delete selected
		Menu, Tab1ContextMenu, Add, Remove selected bookmark(s), deleteSelected
		Menu, Tab1ContextMenu, Show
		Menu, Tab1ContextMenu, Enable, Bookmark selected
		Menu, Tab1ContextMenu, Delete, Remove selected bookmark(s)
		Menu, Tab1ContextMenu, Add, Delete selected, deleteSelected
	}

	Critical, Off
}
		;}
		;{ autorunsLV()
autorunsLV()
{

	Critical, On
	Global activeControl, settings_O
	Gui, ListView, % A_ThisFunc
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "RightClick")
		activeControl := A_ThisFunc
	If (A_GuiEvent == "I" && InStr(ErrorLevel, "C"))	; Row # %A_EventInfo% got (un)checked.
	{
		For k, v In settings_O.autoruns
		{
			If (A_Index == A_EventInfo)
			{
				v.enabled := (InStr(ErrorLevel, "C", 1) ? 1 : 0)
				Break
			}
		}
	}

	Critical, Off
}
		;}
		;{ processesLV()
processesLV()
{

	Critical, On
	Global activeControl := A_ThisFunc
	Gui, ListView, % A_ThisFunc

	If (A_GuiControlEvent == "RightClick")
		Menu, MngProcContMenu, Show

	Critical, Off
}
		;}
		;{ assistantsLV()
assistantsLV()
{

	Critical, On
	Global activeControl := A_ThisFunc, settings_O
	Gui, ListView, % A_ThisFunc


	If (A_GuiEvent == "DoubleClick" && A_EventInfo)
	{
		While !(doubleClickedPA)
			LV_GetText(doubleClickedPA, PAfirstRow := A_EventInfo - A_Index + 1, 1)
		settings_O.assistants[doubleClickedPA].enabled := !(settings_O.assistants[doubleClickedPA].enabled)
		GuiControl, 1: -Redraw, A_ThisFunc
		LV_Modify(PAfirstRow, "Icon" settings_O.assistants[doubleClickedPA].enabled)
		; This fixes the bug where the icon that got deleted - remains visually present.
		LV_Modify(PAfirstRow, "+Select")
		LV_Modify(PAfirstRow, "-Select")
		If (PAfirstRow == A_EventInfo)
			LV_Modify(PAfirstRow, "+Select")
		GuiControl, 1: +Redraw, A_ThisFunc
	}

	Critical, Off
}
		;}
	;}
	;{ runSelected()	- gets selected rows in 'fileLV' or 'bookmarksLV' and runs related files.
; Called by:
;	Buttons: 'Run selected' (tab #1 'Files').
;	Menuitems: 'fileLV' > 'Run selected', 'bookmarksLV' > 'Run selected'.
runSelected()
{
	Global activeControl, selectedItemPath
	Gui, ListView, %activeControl%
	selected := getScriptNames()
	If (selected.MaxIndex() != 0)
		run(selected)
}
	;}
	;{ Labels of process control buttons/(context menu menuitems)
Kill:
	Gui, ListView, processesLV
	kill(getPIDs())
Return

Exit:
	wParam++	; 65307.
Pause:
	wParam++	; 65306.
SuspendHotkeys:
	wParam++	; 65305.
Edit:
	wParam++	; 65304.
Reload:
	wParam += 3	; 65303.
Open:
	wParam += 65300
	Gui, ListView, processesLV
	commandScript(getPIDs(), wParam)
	wParam := 0
Return
	;}
;}
;{+ HOTKEYS
#IfWinActive ahk_group ScriptHwnd_A
	;{ Persistent.
~Delete::
	If (activeTab == "Files" || activeTab == "AutoRuns" || activeTab == "Process assistants")
		deleteSelected()
	Else If (activeTab == "Processes")
		Gosub, Kill
Return

~Esc::
	If (activeControl == "bookmarksLV") || (activeControl == "fileLV") || (activeControl == "processesLV")
	{
		Gui, ListView, %activeControl%
		LV_Modify(0, "-Select")
	}
	Else If (activeControl == "folderTV")
		TV_Modify(0)
Return
	;}
#IfWinActive
;}
;{+ FUNCTIONS
	;{+ Gather data.
		;{ getSelectedRows(backwardsOrder_B := 0)	- return an array of selected rows' numbers.
; Input: backwardsOrder_B - boolean, if true - sets backwards order.
; Output: an array of indexes of selected rows numbers going sequentially in either normal or backwards order.
; Called by:
;	Functions: deleteSelected(), getScriptNames(), getPIDs(), getScriptPaths().
getSelectedRows(backwardsOrder_B := 0)
{
	selectedRows_A := []
	Loop, % LV_GetCount("Selected")
		selectedRows_A.Push(row_N := LV_GetNext(row_N))
	Return (backwardsOrder_B ? sortArrayBackwards(selectedRows_A) : selectedRows_A)
}
		;}
		;{ getScriptNames()	- returns an array of script names related to selected rows.
; Output: an array of script names (or their full paths, in case of 'bookmarksLV' LV) of the files in the selected rows.
; Called by:
;	Functions: bookmarkSelected(), deleteSelected(), runSelected().
getScriptNames()
{
	Global activeControl, selectedItemPath, scriptsSnapshot_AofO, settings_O
	scriptNames := []
	For k, v In getSelectedRows()
	{
		If (activeControl == "fileLV")
		{
			LV_GetText(thisScriptName, v, 1)	; 'fileLV' LV Column #1 contains files' names.
			thisScriptName := selectedItemPath "\" thisScriptName
		}
		Else If (activeControl == "bookmarksLV")
			; LV_GetText(thisScriptName, v, 3)	; 'bookmarksLV' LV Column #3 contains full paths of the scripts.
			thisScriptName := settings_O.bookmarkedFiles[v]
		Else If (activeControl == "processesLV")
			; LV_GetText(thisScriptName, v, 3)	; 'processesLV' LV Column #3 contains names of the scripts.
			thisScriptName := scriptsSnapshot_AofO[v, "name"]
		scriptNames.Push(thisScriptName)
	}
	Return scriptNames
}
		;}
		;{ getPIDs()	- returns an array of ProcessIDs of selected rows.
; Output: an array of PIDs.
; Called by:
;	Buttons: 'Kill', 'Exit', 'Pause', 'SuspendHotkeys', 'Edit', 'Reload' (Tab #3 'Processes').
;	Functions: killAndReRun(), toggleSuspendProcess(), hideSelectedProcessesTrayIcons(), ahkProcessRestoreTrayIcon().
getPIDs()
{
	PIDs := []
	For k, v In getSelectedRows()
	{
		LV_GetText(PID, v, 2)	; Column #2 contains PIDs.
		PIDs.Push(PID)
	}
	Return PIDs
}
		;}
		;{ getScriptPaths()	- returns an array of script paths related to selected rows.
; Output: an array with script paths of the files in the selected rows.
; Called by:
;	Functions: killAndReRun().
getScriptPaths()
{
	Global scriptsSnapshot_AofO
	scriptsPaths := []
	For k, v In getSelectedRows()
		scriptsPaths.Push(scriptsSnapshot_AofO[v, "path"])
	Return scriptsPaths
}
		;}
		;{ isProcessSuspended(processID_N)	- retrieves suspension state of a process by its PID.
; Input: processID_N - ProcessID of any process.
; Output: boolean, where 'true' means the processe is suspended.
; Called by:
;	Functions: memoryScan(), fillProcessesLV(), toggleSuspendProcess(), ProcessCreate_OnObjectReady().
isProcessSuspended(processID_N)
{	; 0 = Unknown, 1 = Other, 2 = Ready, 3 = Running, 4 = Blocked, 5 = Suspended Blocked, 6 = Suspended Ready. http://msdn.microsoft.com/en-us/library/aa394372%28v=vs.85%29.aspx
	Global WMIQueries_O
	For thread In WMIQueries_O.ExecQuery("SELECT ThreadWaitReason FROM Win32_Thread WHERE ProcessHandle = " processID_N)
		If (thread.ThreadWaitReason == 5)
			Return 1	; Suspended.
	Return 0	; Not suspended.
}
		;}
		;{ getScriptState(processID_N)	- returns script's state (hotkeys suspended? script paused?).
; Input: processID_N - ProcessID of any process.
; Output: a number, where: 0 - Script is neither paused nor it's hotkeys are suspended; 1 - Script's hotkeys are suspended, but it's not paused; 2 - Script's hotkeys are not suspended, but the script is paused; 3 - script's hotkeys are suspended and the script is paused.
; Called by:
;	Functions: memoryScan(), fillProcessesLV(), toggleSuspendProcess(), 
getScriptState(processID_N)
{
	Global ownPID
	If (processID_N = ownPID)
		script_id := A_ScriptHwnd	; Fix for this script's process: WinExist returns wrong Hwnd, so we use A_ScriptHwnd for this script's process.
	Else
	{
		WinGet, this, list, ahk_pid %processID_N%
		Loop, %this%
			If (mainMenu := DllCall("GetMenu", "UInt", script_id := this%A_Index%))
				Break
	}
	; Force the script to update its Pause/Suspend checkmarks.
	SendMessage, 0x211,,,, ahk_id %script_id%  ; WM_ENTERMENULOOP
	SendMessage, 0x212,,,, ahk_id %script_id%  ; WM_EXITMENULOOP
	; Get script status from its main menu.
	mainMenu := DllCall("GetMenu", "UInt", script_id)
	fileMenu := DllCall("GetSubMenu", "UInt", mainMenu, "Int", 0)
	isSuspended := DllCall("GetMenuState", "UInt", fileMenu, "UInt", 5, "UInt", 0x400) >> 3 & 1
	isPaused := 2 * (DllCall("GetMenuState", "UInt", fileMenu, "UInt", 4, "UInt", 0x400) >> 3 & 1)
	DllCall("CloseHandle", "UInt", fileMenu)
	DllCall("CloseHandle", "UInt", mainMenu)
	Return (isSuspended + isPaused)
}
		;}
	;}
	;{+ General purpose.
		;{ arr2ASV(input_A, separator_S := "|")	- parses the input array and outputs it's values as a string with anchor-separated values.
; Input: input_A - an array; separator_S - a string to be used as an anchor to separate array's items.
; Output: a string with contents of the input array, where each item is separated with a specified separator.
; Called by:
;	Functions: deleteSelected(), writeSettings().
arr2ASV(input_A, separator_S := "|")
{
	For k, v In input_A
		var ? var .= separator_S v : var := v
	Return var
}
		;}
		;{ ASV2Arr(input_S, separator_S := "|")	- parses a string with anchor-separated values and outputs them as an array.
; Input: input_S - an anchor-separated string; separator_S - a string to be used as an anchor to separate array's items.
; Output: an array with contents of the input anchor-separated array.
; Called by:
;	Labels: savePA (in addEditPA() function).
ASV2Arr(input_S, separator_S := "|")
{
	arr := []
	Loop, Parse, input_S, %separator_S%
		arr.Push(A_LoopField)
	Return arr
}
		;}
		;{ ifArraysMatch(comparandA_A, comparandB_A)	- compares two input arrays and tells whether their contents match ([a, b] and [b, a] should match).
; Input: comparandA_A - an array; comparandB_A - an array.
; Output: boolean, where 'true' means that each item of any input array exists in the other array as well (and thus, they are regarded equal, althought the order of their items may differ).
; Called by:
;	Functions: writeSettings().
ifArraysMatch(comparandA_A, comparandB_A)
{
	copyA_A := comparandA_A.Clone(), copyB_A := comparandB_A.Clone(), idxA := idxB := 0
	For k, v In copyA_A
		idxA++
	For k, v In copyB_A
		idxB++
	If (idxA != idxB)
		Return 0
	While 1
	{
		For k, v In copyA_A
		{
			For a, b In copyB_A
			{
				If (v == b)
				{
					copyB_A.Delete(a), copyA_A.Delete(k)
					Continue, 3
				}
			}
		}
		Break
	}
	idxA := 0
	For k, v In copyA_A	; It's enough to check the index of just one array.
		idxA++
	Return !idxA
}
		;}
		;{ fixFSFOutput(input_S)	- fixes the output of 'FileSelectFile,,M'.
fixFSFOutput(input_S)
{
	Loop, Parse, input_S, `n
		((A_Index == 1) ? (dir_S := A_LoopField) : (output_S := (output_S ? output_S "`n" : "") dir_S "\" A_LoopField))
	Return output_S
}
		;}
		;{ arrayRemoveDuplicates(ByRef input_A)	- removes duplicate values from arrays.
arrayRemoveDuplicates(ByRef input_A)
{
	For k, v In input_A
	{
		removeIdx_A := []
		For a, b In input_A
			If (b == v && a != k)
				removeIdx_A.Insert(a)
		For x, y In removeIdx_A
			input_A.Remove(y - x + 1)
	}
}
		;}
		;{ sortArrayBackwards(ByRef input_A)	- sorts array in backwards order.
; Input: input_A - an array.
; Called by:
;	Functions: getSelectedRows().
sortArrayBackwards(ByRef input_A)
{
	items_N := input_A.MaxIndex(), temp_A := []
	Loop, % items_N
		temp_A.Push(input_A[items_N + 1 - A_Index])
	input_A := temp_A
}
		;}
	;}
	;{+ Process control.
		;{ run(paths_A)	- runs programs or ahk scripts by their paths.
; Input: paths_A - an array of paths to programs executables or *.ahk files.
; Output: pids_A - an array of PIDs of ran programs or AHK-scripts.
; Called by:
;	Functions: runSelected(), killAndReRun().
run(paths_A)
{
	oldCritical := A_IsCritical, pids_A := []

	Critical, On
	If !(paths_A.MaxIndex())	; Filter bad function calls.
	{
		Critical, % oldCritical
		Return
	}
	For k, v In paths_A
	{
		If (v = A_ScriptFullPath)
		{
			If (k != paths_A.MaxIndex())
				paths_A.Push(v)
			Else
			{
				Run, "%A_AhkPath%" "%v%",,, pid
				pids_A.Push(pid)
			}
		}
		Else If (SubStr(v, -2) = "ahk")	; If that's an ahk script then run it as a 1st param for A_AhkPath.
		{
			Run, "%A_AhkPath%" "%v%",,, pid
			pids_A.Push(pid)
		}
		Else
		{
			Run, %v%,,, pid
			pids_A.Push(pid)
		}
		
	}

	Critical, % oldCritical
	Return pids_A
}
		;}
		;{ kill(pids_A)	- parses input array of ProcessIDs and kills each unnicely (uses "Process, Close").
; Input: pids_A - an array of ProcessIDs.
; Called by:
;	Buttons: 'Kill' (Tab #3 'processesLV').
;	Functions: killAndReRun().
;	Hotkeys: 'Delete'.
;	Menuitems: 'Kill' (Tab #3 'processesLV').
kill(pids_A)
{
; Called by: Tab #2 'Processes' - LV 'processesLV'; buttons: 'Kill', 'Kill and re-execute'; functions: setRunState().
; Input: an array of PIDs.
; Output: none.
	Global scriptsSnapshot_AofO, ownPID
	hideTheirTrayIcons := []
	If !(pids_A.MaxIndex())	; Filter bad function calls.
		Return
	Gui, ListView, processesLV
	For k, v In pids_A
	{
		If (v != ownPID) || (pids_A.MaxIndex() = k)	; Parsing a process of a different script or this script's process but as the last.
		{
			For a, b In scriptsSnapshot_AofO
			{
				If (v == b.pid)
				{
					scriptsSnapshot_AofO.RemoveAt(a)	; Update 'scriptsSnapshot_AofO' array.
					LV_Delete(a)	; Update 'processesLV' LV.
					hideTheirTrayIcons.Push(b.pid)
					Break
				}
			}
			Process, Close, %v%
		}
		Else
			pids_A.Push(v)
	}
	Loop, % LV_GetCount()	; Update values of '#' column from 'processesLV' LV.
		LV_Modify(A_Index, "Integer", A_Index)
	hideTrayIconsByPIDs(hideTheirTrayIcons)
}
		;}
		;{ killAndReRun()	- restarts selected scripts unnicely (uses "Process, Close").
killAndReRun()
{
; Called by: Tab #2 'Processes' - LV 'processesLV'; buttons: 'Kill and re-execute'.
; Input: an array of PIDs.
; Output: none.
	Global ownPID
	Gui, ListView, processesLV
	pids_A := getPIDs()
	If !(pids_A.MaxIndex())	; Filter bad function calls.
		Return
	runThese_A := getScriptPaths()
	For k, v In pids_A	; If the script is ought to kill self - it should be done after killing and re-executing all other selected scripts.
		If (v = ownPID)
			suicide := 1, pids_A.RemoveAt(k)
	kill(pids_A), run(runThese_A)
	If (suicide)	; If the script is ought to kill self it has to re-execute self first before killing old instance.
		Process, Close, %ownPID%
}
		;}
		;{ commandScript(pids_A, wParam)	- sends specific messages (using PostMessage) to the AHK scripts processes by their PIDs.
commandScript(pids_A, wParam)
{
; Called by: Tab #2 'Processes' - LV 'processesLV'; buttons: 'Reload'.
; Input: pids_A: an array of PIDs; wParam: 65300 - open, 65303 - reload, 65304 - edit, 65305 or 65404 - suspend hotkeys, 65306 or 65403 - pause, 65307 - exit.
; Output: none.
	Global ownPID
	If !(pids_A.MaxIndex() && wParam)	; Filter bad function calls.
		Return
	For k, v In pids_A
	{
		If (v != ownPID || k == pids_A.MaxIndex())	; Parsing a process of a different script.
			PostMessage, 0x111, wParam,,, ahk_class AutoHotkey ahk_pid %v%	; Specifying ahk_class guarantees that the message will be sent to the correct window of a process.
		Else	; Parsing the process of this script in the middle of the array.
			pids_A.Push(v)	; Adding this script's PID to the end of the 'pids_A' array.
	}
}
		;}
		;{ toggleSuspendProcess()	- toggles suspension state for selected processes.
toggleSuspendProcess()
{
	Global ownPID
	Gui, ListView, processesLV
	PIDs := getPIDs()
	If !(PIDs.MaxIndex())	; Filter bad function calls.
		Return
	For k, v In PIDs
	{
		If (v != ownPID) || (k = PIDs.MaxIndex())
			isProcessSuspended(v) ? resumeOrSuspendProcess(v) : resumeOrSuspendProcess(v, 0)	; Check current state of the process and toggle it.
		Else If (k != PIDs.MaxIndex())
			PIDs.Push(ownPID)
	}
}
		;}
		;{ resumeOrSuspendProcess(processID_N, setState_B := 1)	- resumes or suspends a process by its PID.
resumeOrSuspendProcess(processID_N, setState_B := 1)	; Resume or suspend selected pid's process.
{
; Called by: Tab #2 'Processes' - LV 'processesLV'; buttons: 'Suspend process''.
; Input: processID_N: a single processID_N; setState_B: boolean, where 1 - resume [default value], 0 - suspend.
; Output: none.
	If !(procHWND := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int" (A_PtrSize = 8) ? "64" : "", processID_N))
		Return -1
	DllCall("ntdll.dll\Nt" (setState_B ? "Resume" : "Suspend") "Process", "Int", procHWND)
	DllCall("CloseHandle", "Int" (A_PtrSize = 8) ? "64" : "", procHWND)
}
		;}
	;}
	;{+ Process monitoring.
		;{ ProcessCreate_OnObjectReady(SWbemSink_O)	- do stuff when a new process appears.
ProcessCreate_OnObjectReady(SWbemSink_O)
{
	Global settings_O, scriptsSnapshot_AofO, processesLVHWND
	process := SWbemSink_O.TargetInstance

	If !(process.ExecutablePath)	; Some weird processes do not have 'ExecutablePath'.
		Return
	For k, v In settings_O.ignoredProcesses	; Check if the newly appeared process matches should be ignored (by checking if it is present in 'settings_O.ignoredProcesses' array.
		If (process.ExecutablePath = v)
			Return
	WinGetClass, class, % "ahk_pid " process.ProcessId
	If (((process.ExecutablePath = A_AhkPath) && (RegExMatch(process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))) || (class == "AutoHotkey"))	; If it is an ahk script.
	{
		defLV := A_DefaultListView
		this := (isProcessSuspended(process.ProcessId) ? 5 : 1 + getScriptState(process.ProcessId))	; The number from 1 to 5, which is the index of the icon in the 'IL_scriptStates' IL.
		If (process.ExecutablePath != A_AhkPath)
		{
			SplitPath, % process.ExecutablePath, scriptName
			scriptPath := process.ExecutablePath
		}
		scriptsSnapshot_AofO.Push({"pid": process.ProcessId, "name": scriptName, "path": scriptPath, "icon": this})
		Gui, ListView, processesLV
		newRowIndex := LV_Add("Icon" this, scriptsSnapshot_AofO.MaxIndex(), process.ProcessId, scriptName, scriptPath)
		If (scriptName ~= "Si)^.*\.exe$")
			LV_SetCellIcon(processesLVHWND, newRowIndex, 3, 6)
		Gui, ListView, defLV
	}
	For k, v In settings_O.triggeredPIDs
	{
		If (process.ProcessID == v)
		{
			settings_O.triggeredPIDs.RemoveAt(k)
			Return
		}
	}
	assist((scriptPath ? [scriptPath, 1] : [process.ExecutablePath]), 1)
}
		;}
		;{ ProcessDelete_OnObjectReady(SWbemSink_O)	- do stuff when a process dies.
ProcessDelete_OnObjectReady(SWbemSink_O)
{
	Global settings_O, scriptsSnapshot_AofO, processesLVHWND
	process := SWbemSink_O.TargetInstance

	If !(process.ExecutablePath)	; Some weird processes do not have 'ExecutablePath'.
		Return
	For k, v In settings_O.ignoredProcesses	; Check if the deceased process matches should be ignored (by checking if it is present in 'settings_O.ignoredProcesses' array.
		If (process.ExecutablePath = v)
			Return
	If (HWND := WinExist("ahk_class AutoHotkey ahk_pid " Process.ProcessId))
		TrayIcon_Remove(HWND)
	If ((process.ExecutablePath = A_AhkPath) && (RegExMatch(process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script)))
		Sleep, 1
	Else
		scriptPath := process.ExecutablePath
	defLV := A_DefaultListView
	For k, v In scriptsSnapshot_AofO
	{
		If (v.pid == process.ProcessId)
		{
			scriptsSnapshot_AofO.RemoveAt(k)
			Break
		}
	}
	deleted := 0
	Gui, ListView, processesLV
	Loop, % LV_GetCount()
	{
		LV_GetText(pid, A_Index - deleted, 2)	; Row #2 contains PIDs.
		If (pid == process.ProcessId)
			LV_Delete(A_Index), deleted++
		Else
			LV_Modify(A_Index - deleted, "Integer", A_Index - deleted)
	}
	Gui, ListView, defLV
	For k, v In settings_O.expectedToDiePIDs
	{
		If (process.ProcessID == v)
		{
			settings_O.expectedToDiePIDs.RemoveAt(k)
			Return
		}
	}
	assist((scriptPath ? [scriptPath, 1] : [process.ExecutablePath]))
}
		;}
		;{ memoryScan()	- gets states of running scripts and updates 'scriptsSnapshot_AofO' object and 'processesLV' listview correspondingly.
memoryScan()
; Callers: the main timer.
; Input: none.
; Output: none.
{
	Global scriptsSnapshot_AofO
	deadScripts := []
	defLV := A_DefaultListView
	Gui, ListView, processesLV
	For k, v In scriptsSnapshot_AofO	; Repeat as many times as there are running AHK-scripts.
	{
		;{ Detect dead processes that died without triggering the ProcessDelete_OnObjectReady(). This might be error prone as the PID may get reused by another process.
		WinGetClass, class, % "ahk_class AutoHotkey ahk_pid " v.pid	; error prone: scripts with gui windows return class other than AutoHotkey.
		Process, Exist, % v.pid
		If ((ErrorLevel != v.pid) || (class != "AutoHotkey"))
		{
			Loop, % LV_GetCount()
			{
				LV_GetText(this, A_Index, 2)	; 2nd column contains PIDs.
				If (this = v.pid)
				{
					LV_Delete(A_Index)	; Need to re-index left column!
					deadScripts.Push(k)
					Break
				}
			}
		}
		;}
		newState := (isProcessSuspended(v.pid) ? 5 : 1 + getScriptState(v.pid))
		If !(v.icon = newState)	; If the script has a new state.
		{
			Loop, % LV_GetCount()
			{
				LV_GetText(this, A_Index, 2)	; 2nd column contains PIDs.
				If (this = v.pid)
				{
					LV_Modify(A_Index, "Icon" v.icon := newState)	; Change it's icon in the LV.
					Break
				}
			}
		}
	}
	;{ Update 'scriptsSnapshot_AofO' object.
	If (deadScripts.MaxIndex() != "")
	{
		For a, b In deadScripts
			scriptsSnapshot_AofO.RemoveAt(b)
	;}
	;{ Update indexes in the first column of 'processesLV'.
		Loop, % LV_GetCount()
		{
			LV_GetText(rowIndex, A_Index, 1)
			If (rowIndex != A_Index)
				LV_Modify(A_Index, "Integer", A_Index)
		}
	}
	;}
	Gui, ListView, defLV
}
		;}
		;{ assist(process_S := "", alive_B := "")
assist(process_S := "", alive_B := 0)
{
	Global WMIQueries_O, settings_O

	runThese_A := [], killThese_A := [], processes_AofO := []

	For process In WMIQueries_O.ExecQuery("SELECT ExecutablePath,ProcessId,CommandLine,Caption,Description FROM Win32_Process")	; Parsing through a list of running processes.
	{	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
		If !(process.ProcessId) || (process.ProcessId = 4) || (process.CommandLine = "\SystemRoot\System32\smss.exe") || (process.Caption = "auidiodg.exe" && process.Description = "audiodg.exe")	; PID 0 = System Idle Process, PID 4 = System, smss.exe and audidg.exe have no ExecutablePath and audiodg.exe has no CommandLine.
			Continue
		For ignoredProcess In settings_O.ignoredProcesses
			If (process.ExecutablePath = ignoredProcess)
				Continue, 2
		processes_AofO.Push({"ExecutablePath": process.ExecutablePath, "ProcessID": process.ProcessID, "CommandLine": process.CommandLine, "Caption": process.Caption, "Description": process.Description})
	}
	If (!IsObject(process_S))	; Startup call, have to check each running process if it needs to be assisted.
	{
		For z, process In processes_AofO
		{
			For k, pa In settings_O.assistants	; Parse assistants list.
			{
				If !(pa.enabled)	; Skip disabled rules.
					Continue
				For itc, tc In pa.TCg	; Parse a group of trigger conditions.
				{

					If (pa.actUponOccurence) && ((process.ExecutablePath ~= "Si)^.*\Q" tc "\E$") || ((SubStr(tc, -3) = ".ahk") && (process.CommandLine ~= "Si)^(""?)\Q" A_AhkPath "\E\1((?:\s+/restart)?)\s+(""?)\Q" tc "\E\3\s*$")))
					{
						For ita, ta In (pa.bindAllToAll ? pa.TCg : pa.TAg)
							runThese_A.Push(ta)
						Break
					}
				}
			}
		}
	}
	Else
	{
		isUncompiledAHK := process_S[2]
		For k, pa In settings_O.assistants
		{
			If !(pa.enabled)	; Skip disabled rules.
				Continue
			foundInTC := foundInTA := 0
			For itc, tc In pa.TCg	; Parse a group of trigger conditions.
			{
				If (process_S[1] ~= "Si)^.*\Q" tc "\E$")
				{
					foundInTC := 1
					Break
				}
			}
			
			If (foundInTC && alive_B && pa.actUponOccurence)
				For ita, ta In (pa.bindAllToAll ? pa.TCg : pa.TAg)
					runThese_A.Push(ta)
			
			If (foundInTC && !alive_B && pa.actUponDeath)
			{
				If (pa.bindAllToAll)
					For ita, ta In pa.TCg
						killThese_A.Push(ta)
				Else
				{
					anyTCIsRunning := 0
					For z, process In processes_AofO
					{
						For itc, tc In pa.TCg
						{
							If ((process.ExecutablePath ~= "Si)^.*\Q" tc "\E$") || ((SubStr(tc, -3) = ".ahk") && (process.CommandLine ~= "Si)^(""?)\Q" A_AhkPath "\E\1((?:\s+/restart)?)\s+(""?)\Q" tc "\E\3\s*$")))
							{
								anyTCIsRunning := 1
								Break
							}
						}
					}
					If !(anyTCIsRunning)
						For ita, ta In (pa.bindAllToAll ? pa.TCg : pa.TAg)
							killThese_A.Push(ta)
				}
					
			}
			
			For ita, ta In pa.TAg	; Parse a group of trigger assistants.
			{
				If (process_S[1] ~= "Si)^.*\Q" ta "\E$")
				{
					foundInTA := 1
					Break
				}
			}
			
			If (foundInTA && pa.persistent)	; Need to find if any process from TCg is running to decide whether there's a need to react either kill or re-execute 'process_S'.
			{
				anyTCIsRunning := 0
				For z, process In processes_AofO
				{
					For itc, tc In pa.TCg
					{
						If ((process.ExecutablePath ~= "Si)^.*\Q" tc "\E$") || ((SubStr(tc, -3) = ".ahk") && (process.CommandLine ~= "Si)^(""?)\Q" A_AhkPath "\E\1((?:\s+/restart)?)\s+(""?)\Q" tc "\E\3\s*$")))
						{
							anyTCIsRunning := 1
							Break
						}
					}
				}
				If (alive_B && anyTCIsRunning)
					runThese_A.Push(process_S[1])
				Else If (alive_B && pa.actUponDeath && !anyTCIsRunning)
					killThese_A.Push(process_S[1])
			}
		}
	}
	If (killThese_A.MaxIndex())
	{
		;[ Remove duplicates and already non-existing processes from 'killThese_A', then get an array of PIDs of processes matching the remaining items in 'killThese_A'.
		arrayRemoveDuplicates(killThese_A), killThesePIDs_A := []
		
		For k, v In killThese_A
		{

			For z, process In processes_AofO
			{
				If ((process.ExecutablePath ~= "Si)^.*\Q" v "\E$") || ((SubStr(v, -3) = ".ahk") && (process.CommandLine ~= "Si)^(""?)\Q" A_AhkPath "\E\1((?:\s+/restart)?)\s+(""?)\Q" v "\E\3\s*$")))
					killThesePIDs_A.Push(process.ProcessID)
			}
		}
		
		kill(killThesePIDs_A)
		;]
		
	}
	If (runThese_A.MaxIndex())
	{
		;[ Remove duplicates and already existing processes from 'runThese_A'.
		arrayRemoveDuplicates(runThese_A)
		
		For z, process In processes_AofO
		{
			removeThese_A := []
			For k, v In runThese_A
				If ((process.ExecutablePath ~= "Si)^.*\Q" v "\E$") || ((SubStr(v, -3) = ".ahk") && (process.CommandLine ~= "Si)^(""?)\Q" A_AhkPath "\E\1((?:\s+/restart)?)\s+(""?)\Q" v "\E\3\s*$")))
					removeThese_A.Push(k)
			If (removeThese_A.MaxIndex())
			{
				sortArrayBackwards(removeThese_A)
				For k, v In removeThese_A
					runThese_A.RemoveAt(v)
			}
		}
		;]
		
		settings_O.triggeredPIDs := run(runThese_A)
	}
}
		;}
	;}
	;{+ Tray icon and menu.
		;{ hideSelectedProcessesTrayIcons()
hideSelectedProcessesTrayIcons()
{
	pids_A := getPIDs()
	If (pids_A.Length())
		hideTrayIconsByPIDs(pids_A)
}
		;}
		;{ hideTrayIconsByPIDs(pids_A)
hideTrayIconsByPIDs(pids_A)
{
	For k, PID in pids_A
	{
		this := TrayIcon_GetInfo(PID)
		TrayIcon_Remove(this[1].hWnd, this[1].uID)
	}
}
		;}
		;{ ahkProcessRestoreTrayIcon()
ahkProcessRestoreTrayIcon()
{
	For k, pid In getPIDs()
		restoreTrayIcon(WinExist("ahk_class AutoHotkey ahk_pid " pid))
}
		;}
		;{ LV_SetCellIcon(lvHWND, row, column, iconIdxInIL)
LV_SetCellIcon(lvHWND, row, column, iconIdxInIL)
{
	hList := lvHWND, iItem := row, iSubItem := column, iImage := iconIdxInIL
	VarSetCapacity(LVITEM, 48 + 3 * A_PtrSize, 0)	; https://msdn.microsoft.com/en-us/library/windows/desktop/bb774760(v=vs.85).aspx
	LVM_SETITEM := 0x1006	; https://msdn.microsoft.com/library/windows/desktop/bb761186(v=vs.85).aspx
	iItem--, iSubItem--, iImage--	; Because indexes there are 0-based.

	NumPut(2, LVITEM, 0, "UInt")	; mask == sum of altered flags, for example: LVIF_IMAGE == 0x2 == 2, LVIF_INDENT == 0x10 == 16 and LVIF_COLUMNS == 0x100 == 512.
	NumPut(iItem, LVITEM, 4, "Int")
	NumPut(iSubItem, LVITEM, 8, "Int")
	NumPut(iImage, LVITEM, 20 + 2 * A_PtrSize, "Int")

	SendMessage, LVM_SETITEM, 0, &LVITEM,, ahk_id %hList%
	; Return result := DllCall("SendMessage", "UInt",hList, "UInt",LVM_SETITEM, "UInt",0, "UInt",&LVITEM)
}
		;}
		;{ restoreTrayIcon(ahkScriptHWND)
restoreTrayIcon(ahkScriptHWND)
{
	WM_TASKBARCREATED := DllCall("RegisterWindowMessage", "Str","TaskbarCreated")
	PostMessage, WM_TASKBARCREATED,,,, ahk_id %ahkScriptHWND%
}
		;}
		;{ showTrayMenu()
showTrayMenu()
{
	Gui, ListView, processesLV
	LV_GetText(pid, LV_GetNext(), 2)	; Col #2 contains PIDs.
	PostMessage, 0x404,, 0x204,, % "ahk_pid " pid	; 0x404 == AHK_NOTIFYICON, 0x204 == WM_RBUTTONDOWN
	PostMessage, 0x404,, 0x205,, % "ahk_pid " pid	; 0x205 == WM_RBUTTONUP
}
		;}
		;{+ TrayIcon [Lib] by Fanatic Guru http://ahkscript.org/boards/viewtopic.php?p=9186#p9186
			;{ TrayIcon_GetInfo(sExeName := "")
TrayIcon_GetInfo(sExeName := "")
{
	oTrayIcon_GetInfo := {}
	For key, sTray in ["NotifyIconOverflowWindow", "Shell_TrayWnd"]
	{
		idxTB := TrayIcon_GetTrayBar()
		WinGet, pidTaskbar, PID, ahk_class %sTray%

		hProc := DllCall("OpenProcess", "UInt",0x38, "Int",0, "UInt",pidTaskbar)
		pRB   := DllCall("VirtualAllocEx", "Ptr",hProc, "Ptr",0, "UPtr",20, "UInt",0x1000, "UInt",0x4)

		If (SubStr(A_OSVersion, 1, 2) == 10)
			SendMessage, 0x418, 0, 0, ToolbarWindow32%key%, ahk_class %sTray%   ; TB_BUTTONCOUNT
		Else	
			SendMessage, 0x418, 0, 0, ToolbarWindow32%idxTB%, ahk_class %sTray%   ; TB_BUTTONCOUNT

		szBtn := VarSetCapacity(btn, (A_Is64bitOS ? 32 : 20), 0)
		szNfo := VarSetCapacity(nfo, (A_Is64bitOS ? 32 : 24), 0)
		szTip := VarSetCapacity(tip, 128 * 2, 0)
		
		Loop, %ErrorLevel%
		{
			If (SubStr(A_OSVersion,1,2)=10)
				SendMessage, 0x417, A_Index - 1, pRB, ToolbarWindow32%key%, ahk_class %sTray%   ; TB_GETBUTTON
			Else
				SendMessage, 0x417, A_Index - 1, pRB, ToolbarWindow32%idxTB%, ahk_class %sTray%   ; TB_GETBUTTON
			DllCall("ReadProcessMemory", "Ptr",hProc, "Ptr",pRB, "Ptr",&btn, "UPtr",szBtn, "UPtr",0)

			iBitmap := NumGet(btn, 0, "Int")
			IDcmd   := NumGet(btn, 4, "Int")
			statyle := NumGet(btn, 8)
			dwData  := NumGet(btn, (A_Is64bitOS ? 16 : 12))
			iString := NumGet(btn, (A_Is64bitOS ? 24 : 16), "Ptr")

			DllCall("ReadProcessMemory", "Ptr",hProc, "Ptr",dwData, "Ptr",&nfo, "UPtr",szNfo, "UPtr",0)

			hWnd  := NumGet(nfo, 0, "Ptr")
			uID   := NumGet(nfo, (A_Is64bitOS ? 8 : 4), "UInt")
			msgID := NumGet(nfo, (A_Is64bitOS ? 12 : 8))
			hIcon := NumGet(nfo, (A_Is64bitOS ? 24 : 20), "Ptr")

			WinGet, pID, PID, ahk_id %hWnd%
			WinGet, sProcess, ProcessName, ahk_id %hWnd%
			WinGetClass, sClass, ahk_id %hWnd%

			If !sExeName || (sExeName = sProcess) || (sExeName = pID)
			{
				DllCall("ReadProcessMemory", "Ptr",hProc, "Ptr",iString, "Ptr",&tip, "UPtr",szTip, "UPtr",0)
				Index := (oTrayIcon_GetInfo.MaxIndex() > 0 ? oTrayIcon_GetInfo.MaxIndex() + 1 : 1)
				oTrayIcon_GetInfo[Index,"idx"]     := A_Index - 1
				oTrayIcon_GetInfo[Index,"IDcmd"]   := IDcmd
				oTrayIcon_GetInfo[Index,"pID"]     := pID
				oTrayIcon_GetInfo[Index,"uID"]     := uID
				oTrayIcon_GetInfo[Index,"msgID"]   := msgID
				oTrayIcon_GetInfo[Index,"hIcon"]   := hIcon
				oTrayIcon_GetInfo[Index,"hWnd"]    := hWnd
				oTrayIcon_GetInfo[Index,"Class"]   := sClass
				oTrayIcon_GetInfo[Index,"Process"] := sProcess
				oTrayIcon_GetInfo[Index,"Tooltip"] := StrGet(&tip, "UTF-16")
				oTrayIcon_GetInfo[Index,"Tray"]    := sTray
			}
		}
		DllCall("VirtualFreeEx", "Ptr",hProc, "Ptr",pProc, "UPtr",0, "UInt",0x8000)
		DllCall("CloseHandle", "Ptr",hProc)
	}
	Return oTrayIcon_GetInfo
}
			;}
			;{ TrayIcon_GetTrayBar()
TrayIcon_GetTrayBar()
{
	WinGet, ControlList, ControlList, ahk_class Shell_TrayWnd
	RegExMatch(ControlList, "(?<=ToolbarWindow32)\d+(?!.*ToolbarWindow32)", nTB)
	Loop, %nTB%
	{
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		hParent := DllCall("GetParent", "Ptr",hWnd)
		WinGetClass, sClass, ahk_id %hParent%
		If (sClass <> "SysPager")
			Continue
		idxTB := A_Index
		Break
	}
	Return  idxTB
}
			;}
			;{ TrayIcon_Remove(hWnd, uID := 1028)
TrayIcon_Remove(hWnd, uID := 1028)
{
	If (hWnd == 0)
		Return
	NumPut(VarSetCapacity(NID, (A_IsUnicode ? 2 : 1) * 384 + A_PtrSize * 5 + 40,0), NID, 0 "UInt")
	NumPut(hWnd, NID, A_PtrSize)
	NumPut(uID, NID, A_PtrSize * 2, "UInt")	; All AutoHotkey scripts have uID == 1028 (AHK_NOTIFYICON).
	Return DllCall("shell32\Shell_NotifyIcon", "UInt",0x2, "UInt",&NID)	; 0x2 == NIM_DELETE.
}
			;}
		;}
	;}
	;{+ Read/write settings (between object and file)
		;{ readSettings(settingsFileOrObj)	- read settings from a file (or another object) to save it into an object
readSettings(settingsFileOrObj)
{
	autoruns_AofO := [], assistants_AofO := []	;, ignoredProcesses_A := [], bookmarkedFolders_A := [], bookmarkedFiles_A := [], xywh := {}
	If (!IsObject(settingsFileOrObj))	; Reading settings from a file into an object.
	{
		IniRead, xywh_S, % settingsFileOrObj, Window XYWH
		xywh_A := StrSplit(xywh_S, "`t")	; Tab-separated values: X, Y, Width, Height.

		IniRead, ignoredProcesses_S, % settingsFileOrObj, Ignored processes
		ignoredProcesses_A := StrSplit(ignoredProcesses_S, "`n")	; Paths are listed per 1 line.

		IniRead, bookmarkedFolders_S, % settingsFileOrObj, Bookmarked folders
		bookmarkedFolders_A := StrSplit(bookmarkedFolders_S, "`n")	; Paths are listed per 1 line.

		IniRead, bookmarkedFiles_S, % settingsFileOrObj, Bookmarked files
		bookmarkedFiles_A := StrSplit(bookmarkedFiles_S, "`n")	; Paths are listed per 1 line.

		IniRead, autoruns_S, % settingsFileOrObj, Autoruns
		autoruns_A := StrSplit(autoruns_S, "`n")	; Rules are listed per 1 line.
		For k, v In autoruns_A
		{
			this := StrSplit(v, "`t")	; Each rule consists of 3 tab-separated parts: the 1st one is a 2-digit number (encodes settings), the 2nd one is a path to a script or an executable, and the 3rd one is the command line arguments.
			autoruns_AofO.Push({"enabled": SubStr(this[1], 1, 1)	; 1st digit: 1/0 == if the rule is enabled/disabled.
				, "trayIcon": SubStr(this[1], 2, 1)	; 2nd digit: 1/0 state of tray icon: 0 - means to automatically hide it after start
				, "path": this[2]
				, "parameters": this[3]})
		}

		IniRead, assistants_S, % settingsFileOrObj, Assistants
		assistants_A := StrSplit(assistants_S, "`n")	; Rules are listed per 1 line.
		For k, v In assistants_A
		{
			this := StrSplit(v, "`t")	; Each rule consists of 3 tab-separated parts: the 1st one is a 5-digit number (encodes settings), the 2nd one is the Trigger Condition group (TCg) and the 3rd one is the Triggered Action group (TAg).
			TCg := StrSplit(this[2], "|")	; Each TCg is a pipe-separated array of partial paths.
			TAg := StrSplit(this[3], "|")	; Each TAg is a pipe-separated array of partial paths.
			assistants_AofO.Push({"enabled": SubStr(this[1], 1, 1)	; 1st digit: 1/0 = rule enabled/disabled.
				, "actUponOccurence": SubStr(this[1], 2, 1)	; 2nd digit: 1/0 = 'act upon occurence' option is enabled/disabled (meaning that if ANY trigger from TCg is running - then all the TAg will get executed).
				, "actUponDeath": SubStr(this[1], 3, 1)	; 3rd digit: 1/0 = 'act upon death' option is enabled/disabled (meaning that if any trigger from TCg dies - then whole TAg will get stopped/killed).
				, "bindAllToAll": SubStr(this[1], 4, 1)	; 4th digit: 1/0 = 'bind all to all' option (meaning that there will be no TAg, and any action upon any TC from TCg will cause the same action be applied to other TCs from that TCg).
				, "persistent": SubStr(this[1], 5, 1)	; 5th digit: 1/0 = 'keep state' option (meaning that if you chose running TCg to execute TAg - then the script will re-execute TAg if it dies by its own death, and the same is applicable to the death).
				, "TCg": TCg, "TAg": TAg})
		}
		Return {"assistants": assistants_AofO, "autoruns": autoruns_AofO, "bookmarkedFolders": bookmarkedFolders_A, "bookmarkedFiles": bookmarkedFiles_A, "ignoredProcesses": ignoredProcesses_A, "xywh": {"x": xywh_A[1], "y": xywh_A[2], "w": xywh_A[3], "h": xywh_A[4]}}
	}
	Else	; Cloning settings_O to oldSettings_O.
	{
		newObj := {"xywh": {}, "ignoredProcesses": [], "bookmarkedFolders": [], "bookmarkedFiles": [], "autoruns": [], "assistants": []}

		For k, v In settingsFileOrObj.xywh
			newObj["xywh", k] := v

		For k, v In settingsFileOrObj.ignoredProcesses
			newObj.ignoredProcesses.Push(v)

		For k, v In settingsFileOrObj.bookmarkedFolders
			newObj.bookmarkedFolders.Push(v)

		For k, v In settingsFileOrObj.bookmarkedFiles
			newObj.bookmarkedFiles.Push(v)

		For k, v In settingsFileOrObj.autoruns
			autoruns_AofO.Push({"enabled": v.enabled, "trayIcon": v.trayIcon, "path": v.path, "parameters": v.parameters})
		newObj.autoruns := autoruns_AofO

		For k, v In settingsFileOrObj.assistants
		{
			TCg := [], TAg := []
			For a, b In v.TCg
				TCg.Push(b)
			For a, b In v.TAg
				TAg.Push(b)
			assistants_AofO.Push({"enabled": v.enabled, "actUponOccurence": v.actUponOccurence, "actUponDeath": v.actUponDeath, "bindAllToAll": v.bindAllToAll, "persistent": v.persistent, "TCg": TCg, "TAg": TAg})
		}
		newObj.assistants := assistants_AofO

		Return newObj
	}
}
		;}
		;{ writeSettings(oldSettings_O, settings_O, settingsPath)	- parse settings object and write a section of settings into a file.
writeSettings(oldSettings_O, settings_O, settingsPath)
{
	If (settings_O.xywh.x != oldSettings_O.xywh.x || settings_O.xywh.y != oldSettings_O.xywh.y || settings_O.xywh.w != oldSettings_O.xywh.w || settings_O.xywh.h != oldSettings_O.xywh.h)
	{

		IniDelete, % settingsPath, Window XYWH
		IniWrite, % settings_O.xywh.x "`t" settings_O.xywh.y "`t" settings_O.xywh.w "`t" settings_O.xywh.h, % settingsPath, Window XYWH
	}
	
	If (!ifArraysMatch(oldSettings_O.ignoredProcesses, settings_O.ignoredProcesses))
	{

		IniDelete, % settingsPath, Ignored processes
		If (settings_O.ignoredProcesses.Length())
			IniWrite, % arr2ASV(settings_O.ignoredProcesses, "`n"), % settingsPath, Ignored processes
	}
	
	If (!ifArraysMatch(oldSettings_O.bookmarkedFolders, settings_O.bookmarkedFolders))
	{

		IniDelete, % settingsPath, Bookmarked folders
		If (settings_O.bookmarkedFolders.Length())
			IniWrite, % arr2ASV(settings_O.bookmarkedFolders, "`n"), % settingsPath, Bookmarked folders
	}
	
	If (!ifArraysMatch(oldSettings_O.bookmarkedFiles, settings_O.bookmarkedFiles))
	{

		IniDelete, % settingsPath, Bookmarked files
		If (settings_O.bookmarkedFiles.Length())
			IniWrite, % arr2ASV(settings_O.bookmarkedFiles, "`n"), % settingsPath, Bookmarked files
	}
	
	autoruns_A := [], oldAutoruns_A := []
	
	For objName, objVal In [settings_O.autoruns, oldSettings_O.autoruns]
		For k, v In objVal
			(objName < 2 ? autoruns_A : oldAutoruns_A).Push(v.enabled v.trayIcon "`t" v.path (v.parameters ? "`t" v.parameters : ""))
	If (!ifArraysMatch(oldAutoruns_A, autoruns_A))
	{

		IniDelete, % settingsPath, Autoruns
		If (autoruns_A.Length())
			IniWrite, % arr2ASV(autoruns_A, "`n"), % settingsPath, Autoruns
	}
	
	assistants_A := [], oldAssistants_A := []
	For objName, objVal In [settings_O.assistants, oldSettings_O.assistants]
	{
		For k, v In objVal
		{
			TAg := arr2ASV(v.TAg, "|")
			(objName < 2 ? assistants_A : oldAssistants_A).Push(v.enabled v.actUponOccurence v.actUponDeath v.bindAllToAll v.persistent "`t" arr2ASV(v.TCg, "|") (TAg ? "`t" TAg : ""))
		}
	}
	If (!ifArraysMatch(oldAssistants_A, assistants_A))
	{

		IniDelete, % settingsPath, Assistants
		If (assistants_A.Length())
			IniWrite, % arr2ASV(assistants_A, "`n"), % settingsPath, Assistants
	}
}
		;}
	;}
;}
