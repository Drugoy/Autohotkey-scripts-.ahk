/* MasterScript.ahk
Version: 3.2
Last time modified: 2014.08.17 21:26:29

Description: a script manager for *.ahk scripts.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
http://auto-hotkey.com/boards/viewtopic.php?f=6&t=109&p=1612
http://forum.script-coding.com/viewtopic.php?id=8724
*/
;{ TODO:
; 1. Handle scripts' icons hiding/restoring.
;	a. Add a button to hide/restore script's tray icon.
; 2. [If possible:] Combine suspendProcess() and resumeProcess() into a single function.
;	This might be helpful: http://www.autohotkey.com/board/topic/41725-how-do-i-disable-a-script-from-a-different-script/#entry287262
; 3. [If possible:] Add more info about processes to 'ManageProcesses' LV: hotkey suspend state, script's pause state.
;}
;{ Settings block.
; Path and name of the file name to store script's settings.
Global settings := A_ScriptDir "\" SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4) "_settings.ini"
; Specify a value in milliseconds.
memoryScanInterval := 1000
; 1 = Make script store info (into the settings file) about it's window's size and position between script's closures. 0 = do not store that info in the settings file.
rememberPosAndSize := 1
; 1 = use "exit" to end scripts, let them execute their 'OnExit' sub-routine. 0 = use "kill" to end scripts, that just instantly stops them, so scripts won't execute their 'OnExit' subroutines.
quitAssistantsNicely := 1
; Pipe-separated list of process to ignore by the "Process Assistant" parser.
ignoreTheseProcesses := "C:\Windows\System32\DllHost.exe|C:\Windows\Servicing\TrustedInstaller.exe|C:\Windows\System32\audiodg.exe|C:\Windows\System32\svchost.exe|C:\Windows\System32\SearchFilterHost.exe|C:\Windows\System32\SearchProtocolHost.exe|C:\Windows\System32\wbem\unescapp.exe"
;}
;{ Initialization.
#NoEnv	; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force
; #Warn	; Recommended for catching common errors.
GroupAdd, ScriptHwnd_A, % "ahk_pid " DllCall("GetCurrentProcessId")
DetectHiddenWindows, On	; Needed for "pause" and "suspend" commands.
OnExit, ExitApp
Global processesSnapshot := [], Global scriptsSnapshot := [], Global procBinder := [], Global bookmarkedScripts := [], Global conditions, Global triggeredActions, Global toBeRun, Global rules, Global quitAssistantsNicely, Global ignoreTheseProcesses, Global bookmarks, token := 1

; Hooking ComObjects to track processes.
oSvc := ComObjGet("winmgmts:")
ComObjConnect(createSink := ComObjCreate("WbemScripting.SWbemSink"), "ProcessCreate_")
ComObjConnect(deleteSink := ComObjCreate("WbemScripting.SWbemSink"), "ProcessDelete_")
Command := "Within 1 Where TargetInstance ISA 'Win32_Process'"
oSvc.ExecNotificationQueryAsync(createSink, "select * from __InstanceCreationEvent " Command)
oSvc.ExecNotificationQueryAsync(deleteSink, "select * from __InstanceDeletionEvent " Command)

; Create a canvas and add the icons to be used later.
ImageListID := IL_Create(4)	; Create an ImageList to hold 1 icon.
	IL_Add(ImageListID, "shell32.dll", 4)	; 'Folder' icon.
	IL_Add(ImageListID, "shell32.dll", 80)	; 'Logical disk' icon.
	IL_Add(ImageListID, "shell32.dll", 27)	; 'Removable disk' icon.
	IL_Add(ImageListID, "shell32.dll", 87)	; 'Folder with bookmarks' icon.
	; IL_Add(ImageListID, "shell32.dll", 13)	; 'Process' icon.
	; IL_Add(ImageListID, "shell32.dll", 46)	; 'Up to the root folder' icon.
	; IL_Add(ImageListID, "shell32.dll", 71)	; 'Script' icon.
	; IL_Add(ImageListID, "shell32.dll", 138)	; 'Run' icon.
	; IL_Add(ImageListID, "shell32.dll", 272)	; 'Delete' icon.
	; IL_Add(ImageListID, "shell32.dll", 285)	; Neat 'Script' icon.
	; IL_Add(ImageListID, "shell32.dll", 286)	; Neat 'Folder' icon.
	; IL_Add(ImageListID, "shell32.dll", 288)	; Neat 'Bookmark' icon.
	; IL_Add(ImageListID, "shell32.dll", 298)	; 'Folders tree' icon.
;}
;{ GUI Creation.
	;{ Tray menu.
Menu, Tray, NoStandard
Menu, Tray, Add, Manage Scripts, GuiShow	; Create a tray menu's menuitem and bind it to a label that opens main window.
Menu, Tray, Default, Manage Scripts
Menu, Tray, Add
Menu, Tray, Standard
	;}
	;{ StatusBar
Gui, Add, StatusBar
SB_SetParts(60, 85)
	;}
	;{ Add tabs and their contents.
Gui, Add, Tab2, AltSubmit x0 y0 w568 h46 Choose1 +Theme -Background gTabSwitch vactiveTab, Manage files|Manage processes|Manage process assistants	; AltSubmit here is needed to make variable 'activeTab' get active tab's number, not name.
		;{ Tab #1: 'Manage files'.
Gui, Tab, Manage files
Gui, Add, Text, x26 y26, Choose a folder:
Gui, Add, Button, x301 y21 gRunSelected, Run selected
Gui, Add, Button, x+0 gBookmarkSelected, Bookmark selected
Gui, Add, Button, x+0 gDeleteSelected, Delete selected
			;{ Folders Tree (left pane).
Gui, Add, TreeView, AltSubmit x0 y+0 +Resize gFolderTree vFolderTree HwndFolderTreeHwnd ImageList%ImageListID%	; Add TreeView for navigation in the FileSystem.
IniRead, bookmarkedFolders, %settings%, Bookmarks, Folders, 0	; Check if there are some previously saved bookmarked folders.
If bookmarkedFolders
	Loop, Parse, bookmarkedFolders, |
		buildTree(A_LoopField, TV_Add(A_LoopField,, "Icon4"))
DriveGet, fixedDrivesList, List, FIXED	; Fixed logical disks.
If !ErrorLevel
	Loop, Parse, fixedDrivesList	; Add all fixed disks to the TreeView.
		buildTree(A_LoopField ":", TV_Add(A_LoopField ":",, "Icon2"))
DriveGet, removableDrivesList, List, REMOVABLE	; Removable logical disks.
If !ErrorLevel
	Loop, Parse, removableDrivesList	; Add all removable disks to the TreeView.
		buildTree(A_LoopField ":", TV_Add(A_LoopField ":",, "Icon3"))

OnMessage(0x219, "WM_DEVICECHANGE")	; Track removable devices connecting/disconnecting to update the Folder Tree.
			;}
			;{ File list (right pane).
Gui, Add, ListView, AltSubmit x+0 +Resize +Grid gFileList vFileList HwndFileListHwnd, Name|Size (bytes)|Created|Modified
; Set the static widths for some of it's columns.
LV_ModifyCol(2, 76)	; Size (bytes).
LV_ModifyCol(3, 117)	; Created.
LV_ModifyCol(4, 117)	; Modified.
			;}
			;{ Bookmarks (bottom pane).
Gui, Add, Text, vtextBS, Bookmarked scripts:
Gui, Add, ListView, AltSubmit +Resize +Grid gBookmarksList vBookmarksList, #|Name|Full Path|Size|Created|Modified
				;{ Fulfill 'BookmarksList' LV.
IniRead, bookmarks, %settings%, Bookmarks, scripts, 0
If bookmarks
	fillBookmarksList()
				;}
; Set the static widths for some of it's columns
LV_ModifyCol(1, 20)	; #.
LV_ModifyCol(4, 76)	; Size.
LV_ModifyCol(5, 117)	; Created.
LV_ModifyCol(6, 117)	; Modified.
			;}
		;}
		;{ Tab #2: 'Manage processes'.
Gui, Tab, Manage processes

; Add buttons to trigger functions.
Gui, Add, Button, x2 y21 gExit, Exit
Gui, Add, Button, x+0 gKill, Kill
Gui, Add, Button, x+0 gkillNreexecute, Kill and re-execute
Gui, Add, Button, x+0 gReload, Reload
Gui, Add, Button, x+0 gPause, (Un) pause
Gui, Add, Button, x+0 gSuspendHotkeys, (Un) suspend hotkeys
Gui, Add, Button, x+0 gSuspendProcess, Suspend process
Gui, Add, Button, x+0 gResumeProcess, Resume process

; Add the main "ListView" element and define it's size, contents, and a label binding.
Gui, Add, ListView, x0 y+0 +Resize +Grid vManageProcesses, #|PID|Name|Path
; Set the static widths for some of it's columns
LV_ModifyCol(1, 20)
LV_ModifyCol(2, 40)

			;{ Fulfill processesSnapshot[] and scriptsSnapshot[] arrays with data and 'ManageProcesses' LV.
For Process In oSvc.ExecQuery("Select * from Win32_Process")	; Parsing through a list of running processes to filter out non-ahk ones (filters are based on "If RegExMatch" rules).
{	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
	processesSnapshot.Insert({"pid": Process.ProcessId, "exe": Process.ExecutablePath, "cmd": Process.CommandLine})
	If (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))
	{
		scriptsSnapshot.Insert({"pid": Process.ProcessId, "name": scriptName, "path": scriptPath})
		LV_Add(, scriptsSnapshot.MaxIndex(), Process.ProcessId, scriptName, scriptPath)
	}
}
			;}
		;}
		;{ Tab #3: 'Manage process assistants'.
Gui, Tab, Manage process assistants
Gui, Add, Button, x374 y21 gAddNewRule, Add new rule
Gui, Add, Button, x+0 gDeleteRules, Delete selected rule(s)
Gui, Add, ListView, x0 y+0 +Resize +Grid vAssistantsList, #|Type|Trigger condition|Scripts to execute
LV_ModifyCol(1, 20)
LV_ModifyCol(2, 40)
GoSub, AssistantsList	; Fulfill the list with the data.
		;}
	;}
	;{ Finish GUI creation.
Gui, Submit, NoHide
SysGet, UA, MonitorWorkArea	; Getting Usable Area info.
If rememberPosAndSize
{
	IniRead, sw_W, %settings%, Script's window, sizeW, 800
	IniRead, sw_H, %settings%, Script's window, sizeH, 600
	IniRead, sw_X, %settings%, Script's window, posX, % (UARight - sw_W) / 2
	IniRead, sw_Y, %settings%, Script's window, posY, % (UABottom - sw_H) / 2
}
Else
	sw_W := 800, sw_H := 600, sw_X := (UARight - sw_W) / 2, sw_Y := (UABottom - sw_H) / 2
Gui, Show, % "x" sw_X " y" sw_Y " w" sw_W - 6 " h" sw_H - 28, Manage Scripts
Gui, +Resize +MinSize666x222
GroupAdd ScriptHwnd_A, % "ahk_pid " DllCall("GetCurrentProcessId") ; Create an ahk_group "ScriptHwnd_A" and make all the current process's windows get into that group.
Return
	;}
;}
;{ Labels.
	;{ G-Labels of main GUI.
GuiShow:
	Gui, Show
Return

GuiSize:	; Expand or shrink the ListView in response to the user's resizing of the window.
	If (A_EventInfo != 1)
	{	; The window has been resized or maximized. Resize GUI items to match the window's size.
		workingAreaHeight := A_GuiHeight - 86
		If (activeTab == 1)
		{
			GuiControl, -Redraw, textBS
			GuiControl, -Redraw, FileList
			GuiControl, -Redraw, FolderTree
			GuiControl, -Redraw, BookmarksList
		}
		Else If (activeTab == 2)
			GuiControl, -Redraw, ManageProcesses
		Else If (activeTab == 3)
			GuiControl, -Redraw, AssistantsList
		GuiControl, Move, FolderTree, % " h" . (workingAreaHeight * 0.677)
		ControlGetPos,, FT_yCoord, FT_Width, FT_Height,, ahk_id %FolderTreeHwnd%
		GuiControl, Move, textBS, % "x0 y" . (FT_yCoord + FT_Height - 30)
		GuiControl, Move, FileList, % "w" . (A_GuiWidth - FT_Width + 30) . " h" . (workingAreaHeight * 0.677)
		Gui, ListView, FileList
		LV_ModifyCol(1, A_GuiWidth - (FT_Width + 330))
		GuiControl, Move, BookmarksList, % "x0 y" . (FT_yCoord + FT_Height - 17) . "w" . (A_GuiWidth + 1) . " h" . (8 + workingAreaHeight * 0.323)
		Gui, ListView, BookmarksList
		LV_ModifyCol(2, (A_GuiWidth - 349) * 0.35)
		LV_ModifyCol(3, (A_GuiWidth - 349) * 0.65)
		GuiControl, Move, ManageProcesses, % "w" . (A_GuiWidth + 1) . " h" . (workingAreaHeight + 20)
		Gui, ListView, ManageProcesses
		LV_ModifyCol(3, (A_GuiWidth - 79) * 0.3)
		LV_ModifyCol(4, (A_GuiWidth - 79) * 0.7)
		GuiControl, Move, AssistantsList, % "w" . (A_GuiWidth + 1) . " h" . (workingAreaHeight + 20)
		Gui, ListView, AssistantsList
		LV_ModifyCol(3, (A_GuiWidth - 79) * 0.6)
		LV_ModifyCol(4, (A_GuiWidth - 79) * 0.4)
		If (activeTab == 1)
		{
			GuiControl, +Redraw, textBS
			GuiControl, +Redraw, FileList
			GuiControl, +Redraw, FolderTree
			GuiControl, +Redraw, BookmarksList
		}
		Else If (activeTab == 2)
			GuiControl, +Redraw, ManageProcesses
		Else If (activeTab == 3)
			GuiControl, +Redraw, AssistantsList
	}
Return

GuiClose:
	If rememberPosAndSize
		WinGetPos, sw_X, sw_Y, sw_W, sw_H, Manage Scripts ahk_class AutoHotkeyGUI
	Gui, Hide
Return

TabSwitch:
	Gui, Submit, NoHide
	If (activeTab == 1)
	{
		GuiControl, +Redraw, textBS
		GuiControl, +Redraw, FileList
		GuiControl, +Redraw, FolderTree
		GuiControl, +Redraw, BookmarksList
	}
	Else If (activeTab == 2)
		GuiControl, +Redraw, ManageProcesses
	Else If (activeTab == 3)
		GuiControl, +Redraw, AssistantsList
Return

ExitApp:
	If rememberPosAndSize
	{
		DetectHiddenWindows, Off
		IfWinExist, ahk_group ScriptHwnd_A
			WinGetPos, sw_X, sw_Y, sw_W, sw_H, Manage Scripts ahk_class AutoHotkeyGUI
		If (sw_X != -32000) && (sw_Y != -32000) && sw_W
		{
			IniWrite, %sw_X%, %settings%, Script's window, posX
			IniWrite, %sw_Y%, %settings%, Script's window, posY
			IniWrite, %sw_W%, %settings%, Script's window, sizeW
			IniWrite, %sw_H%, %settings%, Script's window, sizeH
		}
	}
ExitApp
	;}
	;{ StatusbarUpdate.
StatusbarUpdate:
; Update the three parts of the status bar to show info about the currently selected folder:
	SB_SetText(FileCount . " files", 1)
	SB_SetText(Round(TotalSize / 1024, 1) . " KB", 2)
	SB_SetText(selectedItemPath, 3)
Return
	;}
	;{ AssistantsList.
AssistantsList:
	Gui, ListView, AssistantsList
	rowShift := ruleIndex := tcRows := taRows := 0
	IniRead, rules, %settings%, Assistants
	If !rules	; There is nothing to do if there are no rules yet.
		Return
	rules := Trim(rules, "`n")
	StringSplit, rule, rules, `n
	Loop, Parse, rules, `n
	{
		ruleGroupN := A_Index
		Loop, Parse, A_LoopField, >
		{
			If (A_Index == 1)
			{
				type := A_LoopField
				Continue
			}
			StringSplit, shiftRows, A_LoopField, |
			(A_Index == 2) ? (side := 1, tcRows := shiftRows0) : (side := 2, taRows := shiftRows0)
			Loop, Parse, A_LoopField, |
			{
				procBinder.Insert({"ruleGroupN": ruleGroupN, "type": type, "side": side, "value": A_LoopField})
				rowShift++
				If (ruleIndex != ruleGroupN)	; New rule (thus, left side).
				{
					ruleIndex := ruleGroupN
					If (type)
						LV_Add(, ruleGroupN, (type == 1 ? "⇒" : "⇔"), A_LoopField)
					Else
						LV_Add(, ruleGroupN, "Ѻ", A_LoopField)
				}
				Else If (side == 1)
					LV_Add(,,, A_LoopField)
				Else If !(A_Index > tcRows) && (type)
					LV_Modify(--rowShift - tcRows + A_Index,,,,, A_LoopField)
				Else
					((type) ? (LV_Add(,,,, A_LoopField)) : (LV_Add(,,, A_LoopField)))
			}
		}
	}
	checkRunTriggers()
Return
	;}
	;{ Tab #1: gLabels of [Tree/List]Views.
		;{ FolderTree
FolderTree:	; TreeView's G-label that should update the "FolderTree" TreeView as well as trigger "FileList" ListView update.
	Global activeControl := A_ThisLabel
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "S") || (A_GuiEvent == "+")	; In case of script's initialization, user's left click, keyboard selection or tree expansion - (re)fill the 'FileList' listview.
	{
		If (A_GuiEvent == "Normal") && (A_EventInfo != 0)	; If user left clicked an empty space at right from a folder's name in the TreeView.
		{
			TV_Modify(A_EventInfo, "Select")	; Forcefully select that line.
			Return	; We should react only to A_GuiEvents with "S" and "+" values.
		}
		;{ Determine the full path of the selected folder:
		Gui, TreeView, FolderTree
		TV_GetText(selectedItemPath, A_EventInfo)
		Loop	; Build the full path to the selected folder.
		{
			parentID :=	(A_Index == 1) ? TV_GetParent(A_EventInfo) : TV_GetParent(parentID)
			If !parentID	; No more ancestors.
				Break
			TV_GetText(parentText, parentID)
			selectedItemPath = %parentText%\%selectedItemPath%
		}
		;}
		;{ Rebuild TreeView, if it was expanded.
		If (A_GuiEvent == "+")	; If a tree got expanded.
		{
			Loop, %selectedItemPath%\*.*, 2	; Parse all the children of the selected item.
			{
				thisChildID := TV_GetChild(A_EventInfo)	; Get first child's ID.
				If thisChildID	; && A_EventInfo
					TV_Delete(thisChildID)
			}
			buildTree(selectedItemPath, A_EventInfo)	; Add children and grandchildren to the selected item.
		}
		;}
		;{ Put the files into the ListView.
		Gui, ListView, FileList
		GuiControl, -Redraw, FileList	; Improve performance by disabling redrawing during load.
		LV_Delete()	; Delete old data.
		token := memorizePath := FileCount := TotalSize := 0	; Init prior to loop below.
		Loop, %selectedItemPath%\*.ahk	; This omits folders and shows only .ahk-files in the ListView.
		{
			FormatTime, created, %A_LoopFileTimeCreated%, yyyy.MM.dd   HH:mm:ss
			FormatTime, modified, %A_LoopFileTimeModified%, yyyy.MM.dd   HH:mm:ss
			LV_Add("", A_LoopFileName, Round(A_LoopFileSize / 1024, 1) . " KB", created, modified)
			FileCount++
			TotalSize += A_LoopFileSize
		}
		GuiControl, +Redraw, FileList
		;}
		GoSub, StatusbarUpdate
	}
Return
		;}
		;{ FileList
FileList:
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "RightClick")
		Global activeControl := A_ThisLabel
Return
		;}
		;{ BookmarksList
BookmarksList:
	If (A_GuiEvent == "Normal")
		Global activeControl := A_ThisLabel
Return
		;}
	;}
	;{ Tab #1: gLabels of buttons.
RunSelected:	; G-Label of "Run selected" button.
	If (activeControl == "FileList")	; In case the last active GUI element was "FileList" ListView.
	{
		Gui, ListView, FileList
		selected := selectedItemPath "\" getScriptNames()
		If !selected
			Return
		StringReplace, selected, selected, |, |%selectedItemPath%\, All
	}
	Else If (activeControl == "BookmarksList")	; In case the last active GUI element was "BookmarksList" ListView.
	{
		Gui, ListView, BookmarksList
		selected := getScriptNames()
		If !selected
			Return
	}
	run(selected)
Return

BookmarkSelected:	; G-Label of "Bookmark selected" button.
	If (activeControl == "FileList")	; Bookmark a script.
	{
		Gui, ListView, FileList
		selected := getScriptNames()
		If !selected
			Return
		selected := selectedItemPath "\" selected
		StringReplace, selected, selected, |, |%selectedItemPath%\, All
		StringReplace, selected, selected, \\, \, All
		fillBookmarksList(selected)
	}
	Else If (activeControl == "FolderTree")	; Bookmark a folder.
	{
		bookmarkedFolders ? bookmarkedFolders .= "|" selectedItemPath : bookmarkedFolders := selectedItemPath
		IniWrite, %bookmarkedFolders% , %settings%, Bookmarks, folders
		buildTree(selectedItemPath, TV_Add(selectedItemPath,, "Vis Icon4"))
	}
Return

DeleteSelected:	; G-Label of "Delete selected" button.
	If (activeControl == "BookmarksList")	; In case the last active GUI element was "BookmarksList" ListView.
	{
		Gui, ListView, %activeControl%
		LV_GetCount("Selected") ? fillBookmarksList(,getRowNs()) : Return	; Do nothing, if nothing was selected, otherwise call fillBookmarksList().
	}
	Else If (activeControl == "FileList")	; In case the last active GUI element was "FileList" ListView.
	{
		Gui, ListView, %activeControl%
		selected := getScriptNames()
		If !selected
			Return
		Msgbox, 1, Confirmation required, Are you sure want to delete the selected file(s)?`n%selected%
		IfMsgBox, OK
		{
			selected := selectedItemPath "\" selected
			StringReplace, selected, selected, |, |%selectedItemPath%\, All
			Loop, Parse, selected, |
				FileDelete, %A_LoopField%
			selected := getRowNs()
			Loop, Parse, selected, |
				LV_Delete(A_LoopField + 1 - A_Index)	; That trick lets us delete the rows considering their position change after the 1st delete. Another way to do this is to sort rows' numbers in backwards order, but that would require extra calculations.
		}
	}
	Else If (activeControl == "FolderTree")	; In case the last active GUI element was "FolderTree" TreeView.
	{	; Then we should delete a bookmarked folder.
		If bookmarkedFolders Contains %selectedItemPath%
		{
			bookmarkedFolders := subtract(bookmarkedFolders, selectedItemPath)
			IniWrite, %bookmarkedFolders%, %settings%, Bookmarks, folders
			TV_Delete(TV_GetSelection())
		}
	}
Return
	;}
	;{ Tab #2: gLabels of buttons.
Exit:
	Gui, ListView, ManageProcesses
	exit(getPIDs())
Return

Kill:
	Gui, ListView, ManageProcesses
	kill(getPIDs())
Return

killNreexecute:
	Gui, ListView, ManageProcesses
	killNreexecute(getPIDs())
Return

Reload:
	Gui, ListView, ManageProcesses
	reload(getPIDs())
Return

Pause:
	Gui, ListView, ManageProcesses
	pause(getPIDs())
Return

SuspendHotkeys:
	Gui, ListView, ManageProcesses
	suspendHotkeys(getPIDs())
Return

SuspendProcess:
	Gui, ListView, ManageProcesses
	suspendProcess(getPIDs())
Return

ResumeProcess:
	Gui, ListView, ManageProcesses
	resumeProcess(getPIDs())
Return
	;}
	;{ Tab #3: gLabels of buttons.
AddNewRule:
InputBox, ruleAdd, Add new 'Process Assistant' rule,
(
'Process Assistant' feature works so: you create rules for it, where you specify Trigger Condition) (or 'TC' further in this text) - which process should be assisted with Triggered Action (or 'TA' further in this text) - with which *.ahk script and then just whenever the specified process appears - the corresponding script will get executed and whenever the specified process dies - the corresponding script will get closed too.
In the "Settings" section of the script (in it's source code) you may select a way how to close the scripts. By default, it uses a gentle method which lets the scripts execute their "OnExit" subroutine.

There are the following rules for 'Process Assistant' rule creation:
1. Every rule has to consist of 3 parts, separated by the ">" character:
  a. the left part of a rule is used to specify the rule's type: either one-way or bidirectional. "One way" rules will only execute TA-group associated with any TC from the rule's TC-group. "Bidirectional" rules work so: if any TC or TA from the rule's TC-group or TA-group is found alive - both groups will get executed, and if one of them dies - they will all die too. 
  b. the middle part of a rule is used to specify TCs. TCs can be specified as a process name (explorer.exe) or as a full or partial path (without the "\" at start) to an executable. If multiple TCs are specified in 1 rule - that means that if ANY of those processes appears - it will trigger the rule.
  c. the right part of a rule is used to specify TAs. TAs can be specified only by it's full path to the *.ahk file (but don't specify the path to the "AutoHotkey.exe"). If multiple TAs are specified in 1 rule - that means that ALL of them will get executed/closed whenever the trigger works out.
2. One rule may contain multiple TCs or TAs: you just need to separate them by the "|" (pipe) symbol.

A few examples:
2>firefox.exe|Program Files\GoogleChrome\chrome.exe|C:\Program Files\Internet Explorer\iexplore.exe>C:\Program Files\AHK-Scripts\browserHelper.ahk

1>notepad.exe>C:\Program Files\AHK-Scripts\pimpMyPad.ahk|C:\Program Files\AHK-Scripts\silentProfile.ahk

2>C:\Games\DOTA\dota.exe>C:\DOTA Scripts\cooldownSoundNotify.ahk|C:\DOTA Scripts\cheats\showInvisibleEnemies.ahk
),, 745, 515
If !(ErrorLevel) && ruleAdd	; Do something only if user clicked [OK] and if he actually entered something.
	IniWrite, %ruleAdd%, %settings%, Assistants	; It's strange that it works. Instead I should have written "rules "`n" ruleadd".
	procBinder := []
	Gui, ListView, AssistantsList
	LV_Delete()
	GoSub, AssistantsList
Return

DeleteRules:
	Gui, ListView, AssistantsList
	rulesToDelete := newRules := ""
	selectedRows := getRowNs()	; Getting numbers of the selected rows.
	If !(selectedRows)	; Safe check.
		Return
	Loop, Parse, selectedRows, |
	{
		LV_GetText(selectedRow, A_LoopField, 1)
		rulesToDelete ? rulesToDelete .= "|" selectedRow : rulesToDelete := selectedRow
	}
	Sort, rulesToDelete, N U D|	; Sorting the numbers of the rules to be deleted so there are no duplicates.
	Loop, Parse, rulesToDelete, |	; Getting the number of items in the 'rulesToDelete'.
		rulesToDeleteIndex := A_Index
	Loop, %rule0%	; Recreating rules without the ones to be deleted.
	{
		thisIndex := A_Index
		Loop, Parse, rulesToDelete, |
		{
			If (A_LoopField == thisIndex)
				Break
			Else If (A_LoopField != thisIndex) && (A_Index == rulesToDeleteIndex)
				newRules := ((newRules) ? (newRules "`n" rule%thisIndex%) : (rule%thisIndex%))
		}
	}
	IniDelete, %settings%, Assistants	; This is needed because the settings file has non-INI structure for this section.
	IniWrite, %newRules%, %settings%, Assistants
	LV_Delete()
	GoSub, AssistantsList
Return
	;}
;}
;{ HOTKEYS
#IfWinActive ahk_group ScriptHwnd_A
~Delete::
	If (activeTab == 1)
		GoSub, DeleteSelected
	Else If (activeTab == 2)
		Gosub, Kill
Return

~Esc::
	If (activeControl == "BookmarksList") || (activeControl == "FileList") || (activeControl == "ManageProcesses")
	{
		Gui, ListView, %activeControl%
		LV_Modify(0, "-Select")
	}
	Else If (activeControl == "FolderTree")
		TV_Modify(0)
Return
#IfWinActive
;}
;{ FUNCTIONS
	;{ Functions to gather data.
getRowNs()	; Get selected rows' numbers.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Bookmark selected', 'Delete selected'. Tab #2 'Manage processes' - LVs: 'ManageProcesses'; buttons: "Kill and re-execute"; functions: getScriptNames(), getPIDs(), getScriptPaths().
; Input: none.
; Output: selected rows' numbers (separated by pipes, if many).
	Loop, % LV_GetCount("Selected")
		rowNs := ((rowNs) ? (rowNs "|" rowN := LV_GetNext(rowN)) : (rowN := LV_GetNext(rowN)))
	Return rowNs
}

getScriptNames()	; Get scripts' names of the selected rows.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Bookmark selected', 'Delete selected'.
; Input: none.
; Output: script names of the files in the selected rows.
	rowNs := getRowNs()
	Loop, Parse, rowNs, |
	{
		If (activeControl == "FileList")
			LV_GetText(thisScriptName, A_LoopField, 1)	; 'FileList' LV Column #1 contains files' names.
		Else If (activeControl == "BookmarksList")
			LV_GetText(thisScriptName, A_LoopField, 3)	; 'BookmarksList' LV Column #3 contains full paths of the scripts.
		Else If (activeControl == "ManageProcesses")
			LV_GetText(thisScriptName, A_LoopField, 4)	; 'ManageProcesses' LV Column #4 contains full paths of the scripts.
		scriptNames := ((scriptNames) ? (scriptNames "|" thisScriptName) : (thisScriptName))
	}
	Return scriptNames
}

getPIDs()	; Get PIDs of selected processes.
{
; Used by: Tab #2 'Manage processes' - LVs: 'ManageProcesses'; buttons: 'Exit', 'Kill', 'Kill and re-execute', 'Reload', '(Un) pause', '(Un) suspend hotkeys', 'Suspend process', 'Resume process'.
; Input: none.
; Output: PIDs (separated by pipes, if many).
	rowNs := getRowNs()
	Loop, Parse, rowNs, |
	{
		LV_GetText(thisPID, A_LoopField, 2)	; Column #2 contains PIDs.
		PIDs := ((PIDs) ? (PIDs "|" thisPID) : (thisPID))
	}
	Return PIDs
}

getScriptPaths()	; Get scripts' paths of the selected rows.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: none.
; Output: script paths of the files in the selected rows.
	rowNs := getRowNs()
	Loop, Parse, rowNs, |
		 (A_Index == 1) ? (scriptsPaths := scriptsSnapshot[A_LoopField, "path"]) : (scriptsPaths .= "|" scriptsSnapshot[A_LoopField, "path"])
	Return scriptsPaths
}
	;}
	;{ Function to parse data.
subtract(minuend, subtrahends, separator1 := "|", separator2 := "|")
{
; Used by: Tab #1 button: 'Delete selected'.
; Input: 'minuend' - a string, that represents a pseudo-array of items separated with 'separator1'; 'subtrahends' - a single value or multiple values (separated with the 'separator2') to be subtracted from 'minuend'; 'separator1' - the char used to separate values in the 'minuend' pseudo-array; 'separator1' - the char used to separate values in the 'subtrahend' pseudo-array.
; Output: difference - the result of substraction: minuend - subtrahend.
	minuendArray := [], subtrahendsArray := [], difference := ""
	Loop, Parse, minuend, %separator1%
		minuendArray.Insert(A_LoopField)
	Loop, Parse, subtrahends, %separator2%
		subtrahendsArray.Insert(A_LoopField)
	For a, b in minuendArray
	{
		token := 0
		For k, v in subtrahendsArray
			If (b == v)
				token := 1, subtrahendsArray.Remove(k), Break
		If !token
			difference ? difference .= "|" b : difference := b
	}
	Return difference
}
	;}
	;{ Functions of process control.
run(paths)	; Runs selected scripts.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Kill and re-execute'; functions: setRunState().
; Input: path or paths (separated by pipes, if many).
; Output: none.
	If !paths
		Return
	toBeRun := paths
	Loop, Parse, paths, |
	{
		If (SubStr(A_LoopField, -2) == "ahk")
			Run, "%A_AhkPath%" "%A_LoopField%"
		Else
			Run, %A_LoopField%
	}
}

exit(pids)	; Closes processes nicely (uses PostMessage).
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Exit'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
		PostMessage, 0x111, 65307,,, ahk_pid %A_LoopField%
}

kill(pids)	; Kills processes unnicely (uses "Process, Close").
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill', 'Kill and re-execute'; functions: setRunState().
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
		Process, Close, %A_LoopField%
}

killNreexecute(pids)	; Kills processes unnicely (uses "Process, Close") and then re-executes them.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	scriptsPaths := getScriptPaths()
	kill(pids)
	run(scriptsPaths)
}

reload(pids)	; Reload (uses PostMessage) selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Reload'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
		PostMessage, 0x111, 65303,,, ahk_pid %A_LoopField%
}

pause(pids)	; Pause selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: '(Un) pause'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
		PostMessage, 0x111, 65403,,, ahk_pid %A_LoopField%
}

suspendHotkeys(pids)	; Suspend hotkeys of selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
		PostMessage, 0x111, 65404,,, ahk_pid %A_LoopField%
}

suspendProcess(pids)	; Suspend processes of selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Suspend process''.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
	{
		If !(procHWND := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", A_LoopField))
			Return -1
		DllCall("ntdll.dll\NtSuspendProcess", "Int", procHWND)
		DllCall("CloseHandle", "Int", procHWND)
	}
}

resumeProcess(pids)	; Resume processes of selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Resume process'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
	{
		If !(procHWND := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", A_LoopField))
			Return -1
		DllCall("ntdll.dll\NtResumeProcess", "Int", procHWND)
		DllCall("CloseHandle", "Int", procHWND)
	}
}
	;}
	;{ Track Processes.
ProcessCreate_OnObjectReady(obj)
{
	Process := obj.TargetInstance
	If !(Process.ExecutablePath)
		Return
	Loop, Parse, ignoreTheseProcesses, |
		If (Process.ExecutablePath ~= "Si)^\Q" A_LoopField "\E$")
			Return
	processesSnapshot.Insert({"pid": Process.ProcessId, "exe": Process.ExecutablePath, "cmd": Process.CommandLine})
	If (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))
	{
		scriptsSnapshot.Insert({"pid": Process.ProcessId, "name": scriptName, "path": scriptPath})
		Gui, ListView, ManageProcesses
		LV_Add(, scriptsSnapshot.MaxIndex(), Process.ProcessId, scriptName, scriptPath)
		thisProcess := scriptPath
	}
	Else
		thisProcess := Process.ExecutablePath
	If (toBeRun)
	{
		StringReplace, toBeRun, toBeRun, % thisProcess
		StringReplace, toBeRun, toBeRun, ||
		StringLeft, thisChar, toBeRun, 1
		If (thisChar == "|")
			StringTrimLeft, toBeRun, toBeRun, 1
		StringRight, thisChar, toBeRun, 1
		If (thisChar == "|")
			StringTrimRight, toBeRun, toBeRun, 1
	}
	checkRunTriggers(thisProcess)
}

ProcessDelete_OnObjectReady(obj)
{
	Process := obj.TargetInstance
	If !(Process.ExecutablePath)
		Return
	Loop, Parse, ignoreTheseProcesses, |
		If (Process.ExecutablePath ~= "Si)^\Q" A_LoopField "\E$")
			Return
	For k, v In processesSnapshot
		If (v.pid == Process.ProcessId)
			processesSnapshot.Remove(A_Index)
	If (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))
	{
		For k, v In scriptsSnapshot
		{
			If (v.pid == Process.ProcessId)
			{
				Gui, ListView, ManageProcesses
				LV_Delete(A_Index)
				scriptsSnapshot.Remove(A_Index)
				this := 1
			}
			If (this)
				LV_Modify(A_Index,, A_Index)	; FIXME: This better be called after some delay since the last call of this function.
		}
		; noTrayOrphans()
		checkKillTriggers(scriptPath)
	}
	Else
		checkKillTriggers(Process.ExecutablePath)
}
	;}
	;{ Functions needed for 'Process Assistant' to work.
checkRunTriggers(rule = 0)
{	; OPTIMIZEME
; Used by: Tab #3 'Manage process assistants' - LV 'AssistantsList'; functions: ProcessCreate_OnObjectReady().
; Input: none.
; Output: none.
	For, k, v In procBinder
	{
		If (v.ruleGroupN != procBinder[k - 1, "ruleGroupN"])	; First rule in a group.
			ruleIndex := stopperIndex := noTriggerFound := 0
		ruleIndex++	; Counter of the rules in a sub-group (or in a group, if type == 0)
		If ((v.side == 2 || !v.type) && stopperIndex)	; No need in deep parsing, local instructions are enough.
			stuffToRun := (stuffToRun ? stuffToRun "|" v.value : v.value)
		Else If ((v.type != 1) && !rule && noTriggerFound)
			stuffToKill := (stuffToKill ? stuffToKill "|" v.value : v.value)
		If (stopperIndex || noTriggerFound)
			Continue
		isAhkProc := ((SubStr(v.value, -2) == "ahk") ? 1 : 0)	; isAhkProc: 1 - an ahk-script is being parsed; 0 - non-ahk process is being parsed.
		If (rule)	; A new process appeared.
		{
			If ((rule ~= "Si)^.*\Q" v.value "\E$") || ((rule ~= "Si)^.*\Q" v.value "\E$") && (SubStr(rule, -2) == "exe"))) && ((v.side == 1 && v.type) || !v.type)
			{
				stopperIndex := k	; A TC found, which is eough to trigger the whole TA-group (or + TC-group in case of !v.type).
				Loop, % ruleIndex - 1
					stuffToRun := ((stuffToRun) ? (stuffToRun "|" procBinder[k - ruleIndex + A_Index, "value"]) : (procBinder[k - ruleIndex + A_Index, "value"]))
			}
		}
		Else If (!v.type || (v.side == 1))	; Not a new process appeared, but an initial check is getting executed.
		{
			For i, j In (isAhkProc ? scriptsSnapshot : processesSnapshot)	; Need to find out if it's running (and thus is a trigger to run the whole group).
			{
				If (((j.path ~= "Si)^.*\Q" v.value "\E$") && (isAhkProc)) || ((j.exe ~= "Si)^.*\Q" v.value "\E$") && !(isAhkProc)))	; A rule was found running, need to trigger the whole group.
				{
					stopperIndex := k	; A TC found, which is enough to trigger the whole TA-group (or + TC-group in case of !v.type).
					If !(v.type)
						Loop, % ruleIndex - 1
							stuffToRun := ((stuffToRun) ? (stuffToRun "|" procBinder[k - ruleIndex + A_Index, "value"]) : (procBinder[k - ruleIndex + A_Index, "value"]))
					Break
				}
			}
		}
		If (v.side != procBinder[k + 1, "side"]) && (v.type) && !(stopperIndex)
			noTriggerFound := 1
	}
	If stuffToKill
	{
		Sort, stuffToKill, U D|	; Removing duplicates, if there are any of them.
		setRunState(stuffToKill, 0)	; Check if everything from 'stuffToRun' is already running, and run if something is not yet running.
	}
	If stuffToRun
	{
		Sort, stuffToRun, U D|	; Removing duplicates, if there are any of them.
		If toBeRun
			Loop, Parse, stuffToRun, |
				IfNotInString, toBeRun, %A_LoopField%
					((runThem) ? (runThem .= "|" A_LoopField) : (runThem := A_LoopField))
		If runThem
			setRunState(runThem, 1)	; Check if everything from 'stuffToRun' is already running, and run if something is not yet running.
		Else
			setRunState(stuffToRun, 1)
	}
}

checkKillTriggers(path)	; A selective check of the specified process to trigger any rules.
{
; Used by: functions: ProcessDelete_OnObjectReady()
; Input: 'path' - a Process.CommandLine/scriptPath of a just died process/script.
; Output: none.
ruleIndex := 0
	For k, v In procBinder
	{
		isAhkProc := ((SubStr((procBinder[k - (ruleIndex + 1) + A_Index, "value"]), -2) == "ahk") ? 1 : 0)
		If (v.ruleGroupN != procBinder[k - 1, "ruleGroupN"])	; First rule in a group.
			ruleIndex := stopperIndex := noTriggerFound := 0
		ruleIndex++
		If (stopperIndex)
		{
			If !(v.type)
				stuffToKill := ((stuffToKill) ? (stuffToKill "|" v.value) : (v.value))
			Else If (noTriggerFound)	; There was a match already, need to finish parsing the rules in the left side.
			{
				If (v.side == 1)
				For i, j In (isAhkProc ? scriptsSnapshot : processesSnapshot)
				{
					If (((j.path ~= "Si)^.*\Q" v.value "\E$") && (isAhkProc)) || ((j.exe ~= "Si)^.*\Q" v.value "\E$") && !(isAhkProc)))
					{
						noTriggerFound := 0
						Break
					}
				}
				Else
					stuffToKill := ((stuffToKill) ? (stuffToKill "|" v.value) : (v.value))
			}
			Continue
		}
		If (path ~= "Si)^.*\Q" v.value "\E$")	; If the dead process matches anything from 'procBinder[]'.
		{
			stopperIndex := k
			If !(v.type)	; The dead process matches a rule with "type = 0".
			{
				Loop, % ruleIndex - 1	; Check previous TCs in the rule's TC-group.
					stuffToKill := ((stuffToKill) ? (stuffToKill "|" procBinder[k - ruleIndex + A_Index, "value"]) : (procBinder[k - ruleIndex + A_Index, "value"]))
			}
			Else If (v.side == 1) && (v.type == 2)	; The dead process matches some TC from a TC-group of a rule with "type = 2".
			{
				If (ruleIndex == 1)
					noTriggerFound := 1
				Else
				{
					Loop, % ruleIndex - 1	; Check previous TCs in the rule's TC-group.
					{
						For i, j In (isAhkProc ? scriptsSnapshot : processesSnapshot)
							If (((j.path ~= "Si)^.*\Q" v.value "\E$") && (isAhkProc)) || ((j.exe ~= "Si)^.*\Q" v.value "\E$") && !(isAhkProc)))
								Break 2
						If (A_Index == ruleIndex)
							noTriggerFound := 1
					}
				}
			}
		}
	}
	If (stuffToKill)
	{
		Sort, killThem, U D|
		setRunState(stuffToKill, 0)
	}
}

setRunState(input, runOrKill)	; Checks the running state of the input and runs or kills if needed.
{
; Used by: functions: checkRunTriggers.
; Input: input - pipe separated processes or scripts to check and either run or kill; runOrKill: 1 - make sure it is running or run if it isn't; 0 - make sure it is dead, or kill if needed.
; Output: none.
	Loop, Parse, input, |
	{
		match := !runOrKill
		For k, v in ((SubStr(A_LoopField, -2) == "ahk") ? scriptsSnapshot : processesSnapshot)
		{
			If (RegExMatch((SubStr(A_LoopField, -2) == "ahk" ? v.path : v.exe), "Si)^.*\Q" A_LoopField "\E$"))
			{
				match := runOrKill
				Break
			}
		}
		If ((match != runOrKill) && runOrKill) || ((match == runOrKill) && !runOrKill)
			stuffToRunOrKill := stuffToRunOrKill ? stuffToRunOrKill "|" ((runOrKill) ? (A_LoopField) : (v.pid)) : ((runOrKill) ? (A_LoopField) : (v.pid))
	}
	If stuffToRunOrKill
		((runOrKill) ? (run(stuffToRunOrKill)) : (quitAssistantsNicely ? exit(stuffToRunOrKill) : kill(stuffToRunOrKill)))
}
	;}
	;{ Fulfill 'FolderTree' TV.
buildTree(folder, parentItemID = 0)
{
; Used by: script's initialization; Tab #1 'Manage files' - TVs: 'FolderTree'.
; Input: folder's path and parentItemID (ID of an item in a TreeView).
; Output: none.
	If folder
		Loop, %folder%\*, 2   ; Inception: retrieve all of Folder's sub-folders.
		{
			parent := TV_Add(A_LoopFileName, parentItemID, "Icon1")	; Add all of those sub-folders to the TreeView.
			Loop, %A_LoopFileFullPath%\*, 2   ; We need to go deeper (c).
			{
				TV_Add("Please, close and re-open the parental folder", parent, "Icon2")
				Break	; No need to add more than 1 item: that's needed just to make the parent item expandable (anyways it's contents will get re-constructed when that item gets expanded).
			}
		}
}
		;{ Track removable drives appearing/disappearing and rebuild TreeView when needed.
WM_DEVICECHANGE(wp, lp)	; Add/remove data to the 'FolderTree" TV about connected/disconnected removable disks.
{
; Used by: script's initialization. For some reason it's called twice every time a disk got (dis)connected.
; Input: unknown.
; Output: none.
	If ((wp == 0x8000 || wp == 0x8004) && NumGet(lp + 4, "uInt") == 2)
	{
		dbcv_unitmask := NumGet(lp + 12, "uInt")
		Loop, 26	; The number of letters in latin alphabet.
		{
			driveLetter := Chr(Asc("A") + A_Index - 1)
		} Until (dbcv_unitmask >> (A_Index - 1))&1
		If (wp == 0x8000)	; A new drive got connected.
		{
			Loop
			{
				If (A_Index == 1)
					driveID := TV_GetChild(0)
				Else
					driveID := TV_GetNext(driveID)
				TV_GetText(thisDrive, driveID)
				StringLeft, thisDrive, thisDrive, 1
			} Until (driveLetter == thisDrive) || !(driveID)
			If (driveLetter != thisDrive)
				buildTree(driveLetter ":", TV_Add(driveLetter ":",, "Icon3"))
		}
		Else If (wp == 0x8004)	; A drive got removed.
		{
			Loop
			{
				If (A_Index == 1)
					driveID := TV_GetChild(0)
				Else
					driveID := TV_GetNext(driveID)
				TV_GetText(thisDrive, driveID)
				StringLeft, thisDrive, thisDrive, 1
			} Until (driveLetter == thisDrive) || !(driveID)
			If driveID
				TV_Delete(driveID)
		}
	}
}
		;}
	;}
	;{ Fulfill 'BookmarksList' LV.
fillBookmarksList(add = 0, remove = 0)
{
; Used by: script's initialization; Tab #1 'Manage files' - buttons: 'Bookmark selected', 'Delete selected'.
; Input: paths of scripts to be bookmarked and paths of scripts to be removed from bookmarks.
; Output: none.
	Gui, ListView, BookmarksList
	If !(remove)
	{
		LV_Delete()	; Clear all rows.
		If add	; If there are scripts to be bookmarked - they should be added to the ini.
		{
			bookmarks ? bookmarks .= "|" add : bookmarks := add
			IniWrite, %bookmarks%, %settings%, Bookmarks, scripts
		}
		Loop, Parse, bookmarks, |, `n`r
		{
			IfExist, % A_LoopField	; Define whether the previously bookmared file exists.
			{	; If the file exists - display it in the list.
				bookmarkedScripts.Insert(A_LoopField)
				SplitPath, A_LoopField, name	; Get file's name from it's path.
				FileGetSize, size, %A_LoopField%	; Get file's size.
				FileGetTime, created, %A_LoopField%, C	; Get file's creation date.
				FormatTime, created, %created%, yyyy.MM.dd   HH:mm:ss	; Transofrm creation date into a readable format.
				FileGetTime, modified, %A_LoopField%	; Get file's last modification date.
				FormatTime, modified, %modified%, yyyy.MM.dd   HH:mm:ss	; Transofrm creation date into a readable format.
				LV_Add("", A_Index, name, A_LoopField, Round(size / 1024, 1) . " KB", created, modified)	; Add the listitem.
			}
			; Else	; The file doesn't exist. Delete it?
		}
	}
	Else
	{
		Loop, Parse, remove, |
			For k in bookmarkedScripts
				If (k == A_LoopField)
					bookmarkedScripts.Remove(k)
		bookmarks := ""
		For k, v in bookmarkedScripts
			bookmarks .= v "|"
		StringTrimRight, bookmarks, bookmarks, 1
		IniWrite, %bookmarks%, %settings%, Bookmarks, scripts
		fillBookmarksList()
	}
}
	;}
	;{ NoTrayOrphans() - a bunch of functions to remove tray icons of dead processes.
; Initially that function was there: http://www.autohotkey.com/board/topic/80624-notrayorphans/?p=512781
; Thanks to N. Nazzal a.k.a. Chef: http://www.autohotkey.com/board/user/13176-nazzal/
noTrayOrphans()
{
	tray_icons := tray_icons()
	For index In tray_icons
	{
		If (index == 0)
			Continue
		If (tray_icons[index, "sProcess"] = "")
			tray_iconRemove(tray_icons[index, "hWnd"], tray_icons[index, "uID"], "", tray_icons[index, "hIcon"])
	}
}

tray_icons()
{
	arr := []
	arr[0] := ["sProcess", "Tooltip", "nMsg", "uID", "idx", "idn", "Pid", "hWnd", "sClass", "hIcon"]
	Index := 0
	trayWindows := "Shell_TrayWnd|NotifyIconOverflowWindow"
	Loop, Parse, trayWindows, |
	{
		WinGet, taskbar_pid, PID, ahk_class %A_LoopField%
		hProc := DllCall("OpenProcess", "uInt", 0x38, "Int", 0, "uInt", taskbar_pid)
		pProc := DllCall("VirtualAllocEx", "uInt", hProc, "uInt", 0, "uInt", 32, "uInt", 0x1000, "uInt", 0x4)
		idxTB := tray_getTrayBar()
		SendMessage, 0x0418, 0, 0, ToolbarWindow32%idxTB%, ahk_class %A_LoopField%
		Loop, %ErrorLevel%
		{
			SendMessage, 0x0417, A_Index - 1, pProc, ToolbarWindow32%idxTB%, ahk_class %A_LoopField%
			VarSetCapacity(btn, 32, 0), VarSetCapacity(nfo, 32, 0)
			DllCall("ReadProcessMemory", "uInt", hProc, "uInt", pProc, "uInt", &btn, "uInt", 32, "uInt", 0)
			iBitmap := NumGet(btn, 0), idn := NumGet(btn, 4), Statyle := NumGet(btn, 8)
			If dwData := NumGet(btn, 12, "uInt")
				iString := NumGet(btn, 16)
			Else
				dwData := NumGet(btn, 16, "Int64"), iString := NumGet(btn, 24, "Int64")
			DllCall("ReadProcessMemory", "uInt", hProc, "uInt", dwData, "uInt", &nfo, "uInt", 32, "uInt", 0)
			If NumGet(btn, 12, "uInt")
				hWnd := NumGet(nfo, 0), uID := NumGet(nfo, 4), nMsg := NumGet(nfo, 8), hIcon := NumGet(nfo,20)
			Else
				hWnd := NumGet(nfo, 0, "Int64"), uID := NumGet(nfo, 8, "uInt"), nMsg := NumGet(nfo, 12, "uInt")
			WinGet, pid, PID, ahk_id %hWnd%
			WinGet, sProcess, ProcessName, ahk_id %hWnd%
			WinGetClass, sClass, ahk_id %hWnd%
			VarSetCapacity(sTooltip,128), VarSetCapacity(wTooltip,128*2)
			DllCall("ReadProcessMemory", "uInt", hProc, "uInt", iString, "uInt", &wTooltip, "uInt", 128*2, "uInt", 0)
			DllCall("WideCharToMultiByte", "uInt", 0, "uInt", 0, "Str", wTooltip, "Int", -1, "Str", sTooltip, "Int", 128, "uInt", 0, "uInt", 0)
			idx := A_Index - 1
			Tooltip := A_IsUnicode ? wTooltip : sTooltip
			Index++
			For a, b In arr[0]
				arr[Index, b] := %b%
		}
		DllCall("VirtualFreeEx", "uInt", hProc, "uInt", pProc, "uInt", 0, "uInt", 0x8000)
		DllCall("CloseHandle", "uInt", hProc)
	}
	Return arr
}
	
tray_iconRemove(hWnd, uID, nMsg = 0, hIcon = 0, nRemove = 0x2)
{
	VarSetCapacity(nid, size := 936 + 4 * A_PtrSize)
	NumPut(size, nid, 0, "uInt")
	NumPut(hWnd, nid, A_PtrSize)
	NumPut(uID, nid, A_PtrSize * 2, "uInt")
	NumPut(1|2|4, nid, A_PtrSize * 3, "uInt")
	NumPut(nMsg, nid, A_PtrSize * 4, "uInt")
	NumPut(hIcon, nid, A_PtrSize * 5, "uInt")
	Return DllCall("shell32\Shell_NotifyIconA", "uInt", nRemove, "uInt", &nid)
}

tray_getTrayBar()
{
	ControlGet, hParent, hWnd,, TrayNotifyWnd1, ahk_class Shell_TrayWnd
	ControlGet, hChild, hWnd,, ToolbarWindow321, ahk_id %hParent%
	Loop
	{
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		If (hWnd = hChild)
			idxTB := A_Index
		If (hWnd = hChild) || !hWnd
			Break
	}
	Return idxTB
}
	;}
;}