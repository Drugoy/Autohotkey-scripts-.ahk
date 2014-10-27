/* MasterScript.ahk
Version: 3.4
Last time modified: 2014.10.27 21:57:11

Description: a script manager for *.ahk scripts.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
http://auto-hotkey.com/boards/viewtopic.php?f=6&t=109&p=1612
http://forum.script-coding.com/viewtopic.php?id=8724
*/
;{ TODO:
; 1. Handle scripts' tray icons: hide/restore/cleanup orphans.
;	a. Add a button to hide/restore script's tray icon.
; 2. Bug: SilentScreenshotter has incorrect icon.
; 3. Bug: 'ManageProcesses' LV has wrong sorting order for '#' column (1>10>11>2 instead of 1>2>...>10>11).
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
;}
;{ Initialization.
#NoEnv	; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force
; #Warn	; Recommended for catching common errors.
DetectHiddenWindows, On	; Needed for 'pause' and 'suspend' commands.
OnExit, ExitApp
Global processesSnapshot := [], Global scriptsSnapshot := [], Global procBinder := [], Global toBeRun := [], Global conditions, Global triggeredActions, Global rules, Global quitAssistantsNicely, Global bookmarks

IniRead, ignoreTheseProcesses, %settings%, Process Manager, IgnoreThese, 0	; Learn what processes should be absolutely ignored by all parsers.
If (ignoreTheseProcesses)
	Global ignoreTheseProcesses := ASV2Arr(ignoreTheseProcesses)

; Hooking ComObjects to track processes.
oSvc := ComObjGet("winmgmts:")
ComObjConnect(createSink := ComObjCreate("WbemScripting.SWbemSink"), "ProcessCreate_")
ComObjConnect(deleteSink := ComObjCreate("WbemScripting.SWbemSink"), "ProcessDelete_")
Command := "Within 1 Where TargetInstance ISA 'Win32_Process'"
oSvc.ExecNotificationQueryAsync(createSink, "select * from __InstanceCreationEvent " Command)
oSvc.ExecNotificationQueryAsync(deleteSink, "select * from __InstanceDeletionEvent " Command)

; Create a canvas and add the icons to be used later.
IL1 := IL_Create(4)	; Create an ImageList to hold 4 icons.
	IL_Add(IL1, "shell32.dll", 4)	; 'Folder' icon.
	IL_Add(IL1, "shell32.dll", 80)	; 'Logical disk' icon.
	IL_Add(IL1, "shell32.dll", 27)	; 'Removable disk' icon.
	; IL_Add(IL1, "shell32.dll", 87)	; 'Folder with bookmarks' icon.
	IL_Add(IL1, "shell32.dll", 206)	; 'Folder with bookmarks' icon.
IL2 := IL_Create(5)	; Create an ImageList to hold 5 icons.
	IL_Add(IL2, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 8)	; '[H]' default green AHK icon with letter 'H'.
	IL_Add(IL2, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 3)	; '[S]' default green AHK icon with letter 'S'.
	IL_Add(IL2, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 4)	; '[H]' default red AHK icon with letter 'H'.
	IL_Add(IL2, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 5)	; '[S]' default red AHK icon with letter 'S'.
	IL_Add(IL2, "shell32.dll", 21)	; A sheet with a clock (suspended process).
IL3 := IL_Create(1)	; Create an ImageList to hold 1 icon.
	IL_Add(IL3, A_AhkPath ? A_AhkPath : A_ScriptFullPath, 2)	; default icon for AHK script.
	
	; IL_Add(IL1, "shell32.dll", 13)	; 'Process' icon.
	; IL_Add(IL1, "shell32.dll", 46)	; 'Up to the root folder' icon.
	; IL_Add(IL1, "shell32.dll", 71)	; 'Script' icon.
	; IL_Add(IL1, "shell32.dll", 138)	; 'Run' icon.
	; IL_Add(IL1, "shell32.dll", 272)	; 'Delete' icon.
	; IL_Add(IL1, "shell32.dll", 285)	; Neat 'Script' icon.
	; IL_Add(IL1, "shell32.dll", 286)	; Neat 'Folder' icon.
	; IL_Add(IL1, "shell32.dll", 288)	; Neat 'Bookmark' icon.
	; IL_Add(IL1, "shell32.dll", 298)	; 'Folders tree' icon.
;}
;{ GUI Creation.
	;{ Tray menu.
Menu, Tray, NoStandard	; Remove all standard items from tray menu.
Menu, Tray, Add, Manage Scripts, GuiShow	; Create a tray menu's menuitem and bind it to a label that opens main window.
Menu, Tray, Default, Manage Scripts	; Set 'Manage Scripts' menuitem as default action (will be executed if tray icon is left-clicked).
Menu, Tray, Add	; Add an empty line (divider).
Menu, Tray, Standard	; Add all standard items to the bottom of tray menu.
	;}
	;{ StatusBar
Gui, Add, StatusBar
SB_SetParts(60, 85)
	;}
	;{ Add tabs and their contents.
Gui, Add, Tab2, AltSubmit x0 y0 w497 h46 Choose1 +Theme -Background gTabSwitch vactiveTab, Manage files|Manage processes|Manage process assistants	; AltSubmit here is needed to make variable 'activeTab' get active tab's number, not name.
		;{ Tab #1: 'Manage files'.
Gui, Tab, Manage files
Gui, Add, Text, x26 y26, Choose a folder:
Gui, Add, Button, x230 y21 gRunSelected, Run selected
Gui, Add, Button, x+0 gBookmarkSelected, Bookmark selected
Gui, Add, Button, x+0 gDeleteSelected, Delete selected
			;{ Folders Tree (left pane).
Gui, Add, TreeView, AltSubmit x0 y+0 +Resize gFolderTree vFolderTree HwndFolderTreeHwnd ImageList%IL1%	; Add TreeView for navigation in the FileSystem.
IniRead, bookmarkedFolders, %settings%, Bookmarks, Folders, 0	; Check if there are some previously saved bookmarked folders.
If (bookmarkedFolders)
	Loop, Parse, bookmarkedFolders, |
		buildTree(A_LoopField, TV_Add(A_LoopField,, "Icon4"))
DriveGet, fixedDrivesList, List, FIXED	; Fixed logical disks.
If !(ErrorLevel)
	Loop, Parse, fixedDrivesList	; Add all fixed disks to the TreeView.
		buildTree(A_LoopField ":", TV_Add(A_LoopField ":",, "Icon2"))
DriveGet, removableDrivesList, List, REMOVABLE	; Removable logical disks.
If !(ErrorLevel)
	Loop, Parse, removableDrivesList	; Add all removable disks to the TreeView.
		buildTree(A_LoopField ":", TV_Add(A_LoopField ":",, "Icon3"))

OnMessage(0x219, "WM_DEVICECHANGE")	; Track removable devices connecting/disconnecting to update the Folder Tree.
			;}
			;{ File list (right pane).
Gui, Add, ListView, AltSubmit x+0 +Resize +Grid gFileList vFileList HwndFileListHwnd, Name|Size (bytes)|Created|Modified
LV_SetImageList(IL3)	; Assign ImageList 'IL1' to the current ListView.
; Set the static widths for some of it's columns.
LV_ModifyCol(2, 76)	; Size (bytes).
LV_ModifyCol(3, 117)	; Created.
LV_ModifyCol(4, 117)	; Modified.
			;}
			;{ Bookmarks (bottom pane).
Gui, Add, Text, vtextBS, Bookmarked scripts:
Gui, Add, ListView, AltSubmit +Resize +Grid gBookmarksList vBookmarksList, #|Name|Full Path|Size|Created|Modified
LV_SetImageList(IL3)	; Assign ImageList 'IL1' to the current ListView.
; Set the static widths for some of it's columns.
				;{ Fulfill 'BookmarksList' LV.
IniRead, bookmarks, %settings%, Bookmarks, scripts, 0
If (bookmarks)
	bookmarks := ASV2Arr(bookmarks), fillBookmarksList()
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
Gui, Add, Button, x1 y21 gExit, Exit
Gui, Add, Button, x+0 gKill, Kill
Gui, Add, Button, x+0 gkillNreexecute, Kill and re-execute
Gui, Add, Button, x+0 gReload, Reload
Gui, Add, Button, x+0 gPause, (Un) pause
Gui, Add, Button, x+0 gSuspendHotkeys, (Un) suspend hotkeys
Gui, Add, Button, x+0 gToggleSuspendProcess, (Un) suspend process

; Add the main "ListView" element and define it's size, contents, and a label binding.
Gui, Add, ListView, x0 y+0 +Resize +Grid +Count25 vManageProcesses, #|PID|Name|Path
LV_SetImageList(IL2)	; Assign ImageList 'IL1' to the current ListView.
; Set the static widths for some of it's columns
LV_ModifyCol(1, 36)
LV_ModifyCol(2, 40)

			;{ Fulfill processesSnapshot[] and scriptsSnapshot[] arrays with data and 'ManageProcesses' LV.
For Process In oSvc.ExecQuery("Select * from Win32_Process")	; Parsing through a list of running processes to filter out non-ahk ones (filters are based on 'If RegExMatch(…)' rules).
{	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
	processesSnapshot.Insert({"pid": Process.ProcessId, "exe": Process.ExecutablePath, "cmd": Process.CommandLine})
	If (Process.ExecutablePath == A_AhkPath && RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script) && RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))
	{
		scriptsSnapshot.Insert({"pid": Process.ProcessId, "name": scriptName, "path": scriptPath})
		LV_Add("Icon" (isProcessSuspended(Process.ProcessId) ? 5 : 1 + getScriptState(Process.ProcessId)), scriptsSnapshot.MaxIndex(), Process.ProcessId, scriptName, scriptPath)	; Add the script to the LV with the proper icon and proper values for all columns.
	}
}
			;}
		;}
		;{ Tab #3: 'Manage process assistants'.
Gui, Tab, Manage process assistants
Gui, Add, Button, x303 y21 gAddNewRule, Add new rule
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
If (rememberPosAndSize)
{
	IniRead, XYWH, %settings%, Script's window, XYWH, % "200|100|900|700"
	Loop, Parse, XYWH, |
		(A_Index == 1 ? sw_X := A_LoopField : (A_Index == 2 ? sw_Y := A_LoopField : (A_Index == 3 ? sw_W := A_LoopField : sw_H := A_LoopField)))
}
Else
	sw_X := (UARight - sw_W) / 2, sw_Y := (UABottom - sw_H) / 2, sw_W := 800, sw_H := 600
Gui, Show, % "x" sw_X " y" sw_Y " w" sw_W - 6 " h" sw_H - 28, Manage Scripts
Gui, +Resize +MinSize666x222
GroupAdd, ScriptHwnd_A, % "ahk_pid " DllCall("GetCurrentProcessId") ; Create an ahk_group "ScriptHwnd_A" and make all the current process's windows get into that group.
SetTimer, MemoryScan, %memoryScanInterval%	; Set a timer to perform periodic scan of running scripts to update their status icons in the LV.
Return
	;}
;}
;{ Labels.
	;{ MemoryScan.
MemoryScan:
	memoryScanfunc()
Return
	;}
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
		LV_ModifyCol(3, (A_GuiWidth - 78) * 0.3)
		LV_ModifyCol(4, (A_GuiWidth - 78) * 0.7)
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
	If (rememberPosAndSize)
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
	If (rememberPosAndSize)
	{
		DetectHiddenWindows, Off
		IfWinExist, ahk_group ScriptHwnd_A
			WinGetPos, sw_X, sw_Y, sw_W, sw_H, Manage Scripts ahk_class AutoHotkeyGUI
		If (sw_X != -32000) && (sw_Y != -32000) && (sw_W)
			IniWrite, %sw_X%|%sw_Y%|%sw_W%|%sw_H%, %settings%, Script's window, XYWH
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
	If !(rules)	; There is nothing to do if there are no rules yet.
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
		If (A_GuiEvent == "Normal")	; If user left clicked an empty space at right from a folder's name in the TreeView.
		{
			If (A_EventInfo)	; If user clicked on a line's empty space.
				TV_Modify(A_EventInfo, "Select")	; Forcefully select that line.
			Else	; If user clicked on the empty space unrelated to any item in the tree.
				Return	; We should react only to A_GuiEvents with "S" and "+" values.
		}
		;{ Determine the full path of the selected folder:
		Gui, TreeView, FolderTree
		TV_GetText(selectedItemPath, A_EventInfo)
		Loop	; Build the full path to the selected folder.
		{
			parentID :=	(A_Index == 1) ? TV_GetParent(A_EventInfo) : TV_GetParent(parentID)
			If !(parentID)	; No more ancestors.
				Break
			TV_GetText(parentText, parentID)
			selectedItemPath = %parentText%\%selectedItemPath%
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
		;{ Put the files into the ListView.
		Gui, ListView, FileList
		GuiControl, -Redraw, FileList	; Improve performance by disabling redrawing during load.
		LV_Delete()	; Delete old data.
		FileCount := TotalSize := 0	; Init prior to loop below.
		Loop, %selectedItemPath%\*.ahk	; This omits folders and shows only .ahk-files in the ListView.
		{
			FormatTime, created, %A_LoopFileTimeCreated%, yyyy.MM.dd   HH:mm:ss
			FormatTime, modified, %A_LoopFileTimeModified%, yyyy.MM.dd   HH:mm:ss
			LV_Add("Icon1", A_LoopFileName, Round(A_LoopFileSize / 1024, 1) . " KB", created, modified)
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
		selected := getScriptNames()
		For k, v In selected
			selected[k] := selectedItemPath "\" v
		If !(selected)
			Return
		StringReplace, selected, selected, |, |%selectedItemPath%\, All
	}
	Else If (activeControl == "BookmarksList")	; In case the last active GUI element was "BookmarksList" ListView.
	{
		Gui, ListView, BookmarksList
		selected := getScriptNames()
		If (selected.MaxIndex() == 0)
			Return
	}
	run(selected)
Return

BookmarkSelected:	; G-Label of "Bookmark selected" button.
	If (activeControl == "FileList")	; Bookmark a script.
	{
		Gui, ListView, FileList
		selected := getScriptNames()
		If (selected.MaxIndex() == 0)
			Return
		For k, v In selected
			selected[k] := selectedItemPath "\" v
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
		LV_GetCount("Selected") ? fillBookmarksList(,getScriptNames()) : Return	; Do nothing, if nothing was selected, otherwise call fillBookmarksList().
	}
	Else If (activeControl == "FileList")	; In case the last active GUI element was "FileList" ListView.
	{
		Gui, ListView, %activeControl%
		selected := getScriptNames()
		If (selected.MaxIndex() == 0)
			Return
		Msgbox, 1, Confirmation required, Are you sure want to delete the selected file(s)?`n%selected%
		IfMsgBox, OK
		{
			For k, v In selected
			{
				selected[k] := selectedItemPath "\" v
				FileDelete, %v%
			}
			selected := getRowNs()
			For k, v In selected
				LV_Delete(v - k + 1)	; That trick lets us delete the rows considering their position change after the 1st delete. Another way to do this is to sort rows' numbers in backwards order, but that would require extra calculations.
		}
	}
	Else If (activeControl == "FolderTree")	; In case the last active GUI element was "FolderTree" TreeView.
	{	; Then we should delete a bookmarked folder.
		If bookmarkedFolders Contains %selectedItemPath%
		{
			TV_Delete(TV_GetSelection())
			bookmarkedFolders := subtract(bookmarkedFolders, selectedItemPath)
			IniWrite, %bookmarkedFolders%, %settings%, Bookmarks, folders
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

ToggleSuspendProcess:
	Gui, ListView, ManageProcesses
	toggleSuspendProcess(getPIDs())
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
	),, 745, 570
	If !(ErrorLevel) && (ruleAdd)	; Do something only if user clicked [OK] and if he actually entered something.
		IniWrite, %ruleAdd%, %settings%, Assistants	; It's strange that it works. Instead I should have written "rules "`n" ruleadd".
	procBinder := []
	Gui, ListView, AssistantsList
	LV_Delete()
	GoSub, AssistantsList
Return

DeleteRules:
	Gui, ListView, AssistantsList
	rulesToDelete := newRules := "", selectedRows := []
	selectedRows := getRowNs()	; Getting numbers of the selected rows.
	If (selectedRows.MaxIndex() == 0)	; Safe check.
		Return
	For k, v in selectedRows
	{
		LV_GetText(selectedRow, v, 1)	; 'ManageProcesses' LV Column #1 is either blank or contains the number of the rule.
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
getRowNs()	; Returm an array of selected rows' numbers.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Bookmark selected', 'Delete selected'. Tab #2 'Manage processes' - LVs: 'ManageProcesses'; buttons: "Kill and re-execute"; functions: getScriptNames(), getPIDs(), getScriptPaths().
; Input: none.
; Output: selected rows' numbers as an array.
	rowNs := []
	Loop, % LV_GetCount("Selected")
		rowNs.Insert(rowN := LV_GetNext(rowN))
	Return rowNs
}

getScriptNames()	; Return an array of selected rows' scripts' names.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Bookmark selected', 'Delete selected'.
; Input: none.
; Output: an array of script names (or their full paths, in case of 'BookmarksList' LV) of the files in the selected rows.
	rowNs := getRowNs()
	scriptNames := []
	For k, v In rowNs
	{
		If (activeControl == "FileList")
			LV_GetText(thisScriptName, v, 1)	; 'FileList' LV Column #1 contains files' names.
		Else If (activeControl == "BookmarksList")
			LV_GetText(thisScriptName, v, 3)	; 'BookmarksList' LV Column #3 contains full paths of the scripts.
		Else If (activeControl == "ManageProcesses")
			LV_GetText(thisScriptName, v, 3)	; 'ManageProcesses' LV Column #3 contains names of the scripts.
		scriptNames.Insert(thisScriptName)
	}
	Return scriptNames
}

getPIDs()	; Return an array of PIDs of selected processes.
{
; Used by: Tab #2 'Manage processes' - LVs: 'ManageProcesses'; buttons: 'Exit', 'Kill', 'Kill and re-execute', 'Reload', '(Un) pause', '(Un) suspend hotkeys', 'Suspend process', 'Resume process'.
; Input: none.
; Output: an array of PIDs.
	rowNs := getRowNs()
	PIDs := []
	For k, v In rowNs
	{
		LV_GetText(thisPID, v, 2)	; Column #2 contains PIDs.
		PIDs.Insert(thisPID)
	}
	Return PIDs
}

getScriptPaths()	; Return an array of selected rows' scripts' paths.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: none.
; Output: script paths of the files in the selected rows.
	rowNs := getRowNs()
	scriptsPaths := []
	For k, v In rowNs
		scriptsPaths.Insert(scriptsSnapshot[v, "path"])
	Return scriptsPaths
}

isProcessSuspended(pid)	; Retrieves another process's suspension state.
{	; 0 = Unknown, 1 = Other, 2 = Ready, 3 = Running, 4 = Blocked, 5 = Suspended Blocked, 6 = Suspended Ready. http://msdn.microsoft.com/en-us/library/aa394372%28v=vs.85%29.aspx
	For thread In ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Thread WHERE ProcessHandle = " pid)
		If (thread.ThreadWaitReason == 5)
			Return 1	; Suspended.
	Return 0	; Not suspended.
}

getScriptState(pid)	; Returns script's state (hotkeys suspended? script paused?).
{
	script_id := (pid == DllCall("GetCurrentProcessId") ? A_ScriptHwnd : WinExist("ahk_pid " pid))	; Fix for this process: WinExist returns wrong Hwnd, so we use A_ScriptHwnd for this script's process.
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
	Return (isSuspended + isPaused)	; 0 - Script is neither paused nor it's hotkeys are suspended; 1 - Script's hotkeys are suspended, but it's not paused; 2 - Script's hotkeys are not suspended, but the script is paused; 3 - script's hotkeys are suspended and the script is paused.
}

memoryScanfunc()
{
	Gui, ListView, ManageProcesses
	Loop, % LV_GetCount()	; Repeat as many times as there are running AHK-scripts.
	{
		LV_GetText(this, A_Index, 2)	; Column #2 is 'PID'.
		If (isProcessSuspended(this))
			LV_Modify(A_Index, "Icon5")
		Else
			LV_Modify(A_Index, "Icon" 1 + (getScriptState(this)))
	}
}
	;}
	;{ Functions to parse data.
subtract(minuend, subtrahends, separator1 := "|", separator2 := "|")	; Return the difference from a subtraction, where minuend and subtrahends are strings with anchor-separated values.
{
; Used by: Tab #1 button: 'Delete selected'.
; Input: 'minuend' - a string, that represents a pseudo-array of items separated with 'separator1'; 'subtrahends' - a single value or multiple values (separated with the 'separator2') to be subtracted from 'minuend'; 'separator1' - the char used to separate values in the 'minuend' pseudo-array; 'separator1' - the char used to separate values in the 'subtrahend' pseudo-array.
; Output: difference - the result of substraction: minuend - subtrahend.
	difference := ""
	Loop, Parse, minuend, %separator1%
	{
		b := A_LoopField
		token := 0
		Loop, Parse, subtrahends, %separator2%
			If (b == A_LoopField)
				token := 1, Break
		If !(token)
			difference ? difference .= separator1 b : difference := b
	}
	Return difference	; This function could be more universal and return data in desired state: either in a variable or in an array.
}

arr2ASV(arr, separator := "|")	; Parses the input array and outputs it's values as a string with anchor-separated values.
{
	For k, v In arr
		var ? var .= separator v : var := v
	Return var
}

ASV2Arr(var, separator := "|")	; Parses a string with anchor-separated values and outputs them as an array.
{
	arr := []
	Loop, Parse, Var, %separator%
		arr.Insert(A_LoopField)
	Return arr
}
	;}
	;{ Functions of process control.
run(paths)	; Runs selected scripts.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Kill and re-execute'; functions: setRunState().
; Input: an array of paths.
; Output: none.
	If (paths.MaxIndex() == 0)
		Return
	toBeRun := paths
	For k, v In paths
	{
		If (SubStr(v, -2) == "ahk")
			Run, "%A_AhkPath%" "%v%"
		Else
			Run, %v%
	}
}

exit(PIDs)	; Closes processes nicely (uses PostMessage).
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Exit'.
; Input: an array of PIDs.
; Output: none.
	If !(PIDs)
		Return
	For k, v In PIDs
		PostMessage, 0x111, 65307,,, ahk_pid %v%
}

kill(PIDs)	; Kills processes unnicely (uses "Process, Close").
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill', 'Kill and re-execute'; functions: setRunState().
; Input: an array of PIDs.
; Output: none.
	If !(PIDs)
		Return
	For k, v In PIDs
		Process, Close, %v%
}

killNreexecute(PIDs)	; Kills processes unnicely (uses "Process, Close") and then re-executes them.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: an array of PIDs.
; Output: none.
	If !(PIDs)
		Return
	scriptsPaths := getScriptPaths()
	kill(PIDs)
	run(scriptsPaths)
}

reload(PIDs)	; Reload (uses PostMessage) selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Reload'.
; Input: an array of PIDs.
; Output: none.
	If !(PIDs)
		Return
	For k, v In PIDs
		PostMessage, 0x111, 65303,,, ahk_pid %v%
}

pause(PIDs)	; Pause selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: '(Un) pause'.
; Input: an array of PIDs.
; Output: none.
	If !(PIDs)
		Return
	For k, v In PIDs
		PostMessage, 0x111, 65403,,, ahk_pid %v%
}

toggleSuspendProcess(PIDarr)
{
	If (PIDarr.MaxIndex())	; Input is not empty.
		For k, v In PIDarr
			isProcessSuspended(v) ? resumeProcess(v) : suspendProcess(v)	; Check current state of the process and toggle it.
}

suspendHotkeys(PIDs)	; Suspend hotkeys of selected scripts.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: an array of PIDs.
; Output: none.
	If !(PIDs)
		Return
	For k, v In PIDs
		PostMessage, 0x111, 65404,,, ahk_pid %v%
}

suspendProcess(pid)	; Suspend selected script's process.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Suspend process''.
; Input: a single PID.
; Output: none.
	If !(procHWND := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, (A_PtrSize == 8) ? "Int64" : "Int", pid))
		Return -1
	DllCall("ntdll.dll\NtSuspendProcess", "Int", procHWND)
	DllCall("CloseHandle", (A_PtrSize == 8) ? "Int64" : "Int", procHWND)
}

resumeProcess(pid)	; Resume selected script's process.
{
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Resume process'.
; Input: a single PID.
; Output: none.
	If !(procHWND := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, (A_PtrSize == 8) ? "Int64" : "Int", pid))
		Return -1
	DllCall("ntdll.dll\NtResumeProcess", "Int", procHWND)
	DllCall("CloseHandle", (A_PtrSize == 8) ? "Int64" : "Int", procHWND)
}
	;}
	;{ Track new processes and death of old processes.
ProcessCreate_OnObjectReady(obj)
{
	Process := obj.TargetInstance	; Some weird process do not have 'ExecutablePath'.
	If !(Process.ExecutablePath)
		Return
	For k, v In ignoreTheseProcesses	; Check if the newly appeared process matches should be ignored (by checking if it is present in 'ignoreTheseProcesses' array.
		If (Process.ExecutablePath ~= "Si)^\Q" v "\E$")
			Return
	processesSnapshot.Insert({"pid": Process.ProcessId, "exe": Process.ExecutablePath, "cmd": Process.CommandLine})
	If ((Process.ExecutablePath == A_AhkPath) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script)))	; If it is an uncompiled ahk script.
	{
		scriptsSnapshot.Insert({"pid": Process.ProcessId, "name": scriptName, "path": scriptPath})
		Gui, ListView, ManageProcesses
		If (isProcessSuspended(Process.ProcessId))
			LV_Add("Icon5", scriptsSnapshot.MaxIndex(), Process.ProcessId, scriptName, scriptPath)
		Else
			LV_Add("Icon" 1 + getScriptState(Process.ProcessId), scriptsSnapshot.MaxIndex(), Process.ProcessId, scriptName, scriptPath)
		checkRunTriggers(scriptPath)
	}
	Else	; If this process is not an uncompiled ahk script.
		checkRunTriggers(Process.ExecutablePath)
}

ProcessDelete_OnObjectReady(obj)
{
	Process := obj.TargetInstance
	If !(Process.ExecutablePath)	; Some weird process do not have 'ExecutablePath'.
		Return
	For k, v In ignoreTheseProcesses	; Check if the newly appeared process matches should be ignored (by checking if it is present in 'ignoreTheseProcesses' array.
		If (Process.ExecutablePath ~= "Si)^\Q" v "\E$")
			Return
	For k, v In processesSnapshot	; Remove a dead process from 'processesSnapshot' array.
	{
		If (v.pid == Process.ProcessId)
		{
			processesSnapshot.Remove(k)
			Break
		}
	}
	If ((Process.ExecutablePath == A_AhkPath) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script)))	; If it is an uncompiled ahk script.
	{
		For k, v In scriptsSnapshot
		{
			If (v.pid == Process.ProcessId)
			{
				Gui, ListView, ManageProcesses
				; Update ListView
				Loop, % LV_GetCount()	; Parse LV to delete a row.
				{
					LV_GetText(this, A_Index, 2)	; Write 'PID' from LV into variable 'this'.
					If (this == v.pid)
					{
						LV_GetText(this, A_Index)	; Write '#' of the deleted row into variable 'this'.
						LV_Delete(A_Index)
						Break
					}
				}
				Loop, % LV_GetCount()	; Re-parse the LV to update '#' value of the rows with greater '#'.
				{
					LV_GetText(that, A_Index, 1)	; Write '#' of the parsed row into variable 'that'.
					If (that > this)
						LV_Modify(A_Index,, that-1)
				}
				scriptsSnapshot.Remove(k)	; Update scriptsSnapshot array by removing the
				Break
			}
		}
		checkKillTriggers(scriptPath)
	}
	Else	; If this process is not an uncompiled ahk script.
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
	If (stuffToKill)
	{
		Sort, stuffToKill, U D|	; Removing duplicates, if there are any of them.
		setRunState(stuffToKill, 0)	; Check if everything from 'stuffToRun' is already running, and run if something is not yet running.
	}
	If (stuffToRun)
	{
		Sort, stuffToRun, U D|	; Removing duplicates, if there are any of them.
		If (toBeRun.MaxIndex() != 0)
			Loop, Parse, stuffToRun, |
			{
				this := 0
				For k, v in toBeRun
				{
					IfInString, v, %A_LoopField%
					{
						this := 1
						Break
					}
				}
				If !(this)
					((runThem) ? (runThem .= "|" A_LoopField) : (runThem := A_LoopField))
			}
		If (runThem)
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
	stuffToRunOrKill := []
	Loop, Parse, input, |
	{
		match := !runOrKill
		For k, v In ((SubStr(A_LoopField, -2) == "ahk") ? scriptsSnapshot : processesSnapshot)
		{
			If (RegExMatch((SubStr(A_LoopField, -2) == "ahk" ? v.path : v.exe), "Si)^.*\Q" A_LoopField "\E$"))
			{
				match := runOrKill
				Break
			}
		}
		If ((match != runOrKill) && runOrKill) || ((match == runOrKill) && !runOrKill)
			stuffToRunOrKill.Insert(runOrKill ? A_LoopField : v.pid)
	}
	If (stuffToRunOrKill)
		((runOrKill) ? (run(stuffToRunOrKill)) : (quitAssistantsNicely ? exit(stuffToRunOrKill) : kill(stuffToRunOrKill)))
}
	;}
	;{ Fulfill 'FolderTree' TV.
buildTree(folder, parentItemID = 0)
{
; Used by: script's initialization; Tab #1 'Manage files' - TVs: 'FolderTree'.
; Input: folder's path and parentItemID (ID of an item in a TreeView).
; Output: none.
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
}
		;{ Track removable drives appearing/disappearing and rebuild TreeView when needed.
WM_DEVICECHANGE(wp, lp, msg, hwnd)	; Add/remove data to the 'FolderTree" TV about connected/disconnected removable disks.
{
; Used by: script's initialization. For some reason it's called twice every time a disk got (dis)connected.
; Input: system messages sent to the windows of this script.
; Output: none.
	If (hwnd = A_ScriptHwnd && (wp == 0x8000 || wp == 0x8004) && NumGet(lp+4, "UInt") == 2)	; 0x8000 == DBT_DEVICEARRIVAL, 0x8004 == DBT_DEVICEREMOVECOMPLETE, 2 == DBT_DEVTYP_VOLUME
	{
		dbcv_unitmask := NumGet(lp + 12, "uInt")
		driveLetter := Chr(Asc("A") + ln(dbcv_unitmask)/ln(2))
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
	If !(remove.MaxIndex())	; If there are no scripts to be removed from bookmarks.
	{
		For k, v In (add.MaxIndex() ? add : bookmarks)
		{
			If (add.MaxIndex())
				bookmarks.Insert(v)
			IfExist, % v	; Define whether the previously bookmared file exists.
			{	; If the file exists - display it in the list.
				SplitPath, v, name	; Get file's name from it's path.
				FileGetSize, size, %v%	; Get file's size.
				FileGetTime, created, %v%, C	; Get file's creation date.
				FormatTime, created, %created%, yyyy.MM.dd   HH:mm:ss	; Transofrm creation date into a readable format.
				FileGetTime, modified, %v%	; Get file's last modification date.
				FormatTime, modified, %modified%, yyyy.MM.dd   HH:mm:ss	; Transofrm creation date into a readable format.
				LV_Add("Icon1", add.MaxIndex() ? bookmarks.MaxIndex() : k , name, v, Round(size / 1024, 1) . " KB", created, modified)	; Add the listitem.
			}
			; Else	; The file doesn't exist. Delete it?
		}
	}
	Else	; If there are scripts to be removed from bookmarks.
	{
		For k, v In remove
		{
			Loop, % LV_GetCount()
			{
				LV_GetText(this, A_Index, 3)	; Column #3 is 'Full Path'.
				If (this == v)
				{
					LV_GetText(this, A_Index), LV_Delete(A_Index)	; Column #1 is '#'.
					Break
				}
			}
			Loop, % LV_GetCount()	; Re-parse the LV to update '#' value of the rows with greater '#'.
			{
				LV_GetText(that, A_Index)	; Write '#' of the parsed row into variable 'that'.
				If (that > this)
					LV_Modify(A_Index,, that-1)
			}
			bookmarks.Remove(this)
		}
	}
	If (add.MaxIndex() || remove.MaxIndex())	; If the function was called with at least one non-empty argument - the user has modified bookmarks and they have to be re-written to the ini-file.
	{
		For k, v in bookmarks
			writeBookmarks ? writeBookmarks .= "|" v : writeBookmarks := v
		IniWrite, %writeBookmarks%, %settings%, Bookmarks, scripts
	}
}
;}