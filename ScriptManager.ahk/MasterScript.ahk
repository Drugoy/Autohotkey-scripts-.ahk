/* MasterScript.ahk
Version: 2
Last time modified: 04:00 18.10.2013

Description: a script manager for *.ahk scripts.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
http://auto-hotkey.com/boards/viewtopic.php?f=6&t=109&p=1612
http://forum.script-coding.com/viewtopic.php?id=8724
*/

;{ TODO:
; 1. Functions to control scripts:
; 	a. Hide/restore scripts' tray icons.
; 2. Improve TreeView.
;	a. It should load all disks' root folders (and their sub-folders) + folders specified by user (that info should also get stored to settings).
;	b. TreeView should always only load folder's contents + contents of it's sub-folders. And load more, when user selected a deeper folder.
; 3. [If possible:] Combine suspendProcess() and resumeProcess() into a single function.
;	This might be helpful: http://www.autohotkey.com/board/topic/41725-how-do-i-disable-a-script-from-a-different-script/#entry287262
; 4. [If possible:] Add more processes info to ProcessList: hotkey suspend state, script's pause state.
; 5. Handle scripts' icons hiding/restoring.
;}

;{ Settings block.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force
DetectHiddenWindows, On	; Needed for "pause" and "suspend" commands.
memoryScanInterval := 1000	; Specify a value in milliseconds.
GroupAdd ScriptHwnd_A, % "ahk_pid " DllCall("GetCurrentProcessId")
SplitPath, A_AhkPath,, startFolder
rememberPosAndSize := 1	; 1 = Make script's window remember it's position and size between window's closures. 0 = always open 800x600 on the center of the screen.
storePosAndSize := 1	; 1 = Make script store info (into the "Settings.ini" file) about it's window's size and position between script's closures. 0 = do not store that info in the Settings.ini.
; startFolder := "C:\Program Files\AutoHotkey"
howToQuitAssistants := "exit"	; Specify either "exit" or "kill" as the values for this variable. This will tell the script how to close the scripts-assistants if the their triggering process(es) were closed: "exit" closes the scripts gently (the "OnExit" subroutine will work out, it's the same as you manually select "Exit" from the script's tray icon's context menu) and "kill" kills them brutally (the "OnExit" subroutine probably won't get executed, it's the same as killing the process from the Task Manager).
;}

;{ GUI Creation.
	;{ Create folder icons.
OnExit, ExitApp
ImageListID := IL_Create(1)	; Create an ImageList to hold 1 icon.
	IL_Add(ImageListID, "shell32.dll", 4)	; 'Folder' icon
;	IL_Add(ImageListID, "shell32.dll", 13)	; 'Process' icon
;	IL_Add(ImageListID, "shell32.dll", 44)	; 'Bookmark' icon
;	IL_Add(ImageListID, "shell32.dll", 46)	; 'Up to the root folder' icon
;	IL_Add(ImageListID, "shell32.dll", 71)	; 'Script' icon
;	IL_Add(ImageListID, "shell32.dll", 138)	; 'Run' icon
;	IL_Add(ImageListID, "shell32.dll", 272)	; 'Delete' icon
;	IL_Add(ImageListID, "shell32.dll", 285)	; Neat 'Script' icon
;	IL_Add(ImageListID, "shell32.dll", 286)	; Neat 'Folder' icon
;	IL_Add(ImageListID, "shell32.dll", 288)	; Neat 'Bookmark' icon
;	IL_Add(ImageListID, "shell32.dll", 298)	; 'Folders tree' icon
	;}
	;{ Tray menu.
Menu, Tray, NoStandard
Menu, Tray, Add, Manage Scripts, GuiShow	; Create a tray menu's menuitem and bind it to a label that opens main window.
Menu, Tray, Default, Manage Scripts
Menu, Tray, Add
Menu, Tray, Standard
	;}
	;{ Add tabs and their contents.
Gui, Add, Tab2, AltSubmit x0 y0 w568 h46 Choose1 +Theme -Background gTabSwitch vactiveTab, Manage files|Manage processes|Manage process assistants	; AltSubmit here is needed to make variable 'activeTab' get active tab's number, not name.
		;{ Tab #1: 'Manage files'.
Gui, Tab, Manage files
Gui, Add, Text, x26 y26, Choose a folder:
Gui, Add, Button, x301 y21 gRunSelected, Run selected
Gui, Add, Button, x+0 gBookmarkSelected, Bookmark selected
Gui, Add, Button, x+0 gDeleteSelected, Delete selected
; Folder list (left pane).
Gui, Add, TreeView, AltSubmit x0 y+0 +Resize gFolderTree vFolderTree HwndFolderTreeHwnd ImageList%ImageListID%	; Add TreeView for navigation in the FileSystem.	; ICON
buildTree(startFolder)	; Fulfill TreeView.

; File list (right pane).
Gui, Add, ListView, AltSubmit x+0 +Resize +Grid gFileList vFileList HwndFileListHwnd, Name|Size (bytes)|Created|Modified
; Set the static widths for some of it's columns
LV_ModifyCol(2, 76)
LV_ModifyCol(3, 117)
LV_ModifyCol(4, 117)

Gui, Add, Text, vtextBS, Bookmarked scripts:

; Bookmarks (bottom pane).
Gui, Add, ListView, AltSubmit +Resize +Grid gBookmarksList vBookmarksList, #|Name|Full Path|Size|Created|Modified
; Set the static widths for some of it's columns
LV_ModifyCol(1, 20)
LV_ModifyCol(4, 76)
LV_ModifyCol(5, 117)
LV_ModifyCol(6, 117)
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
Gui, Add, ListView, x0 y+0 +Resize +Grid gManageProcesses vManageProcesses, #|PID|Name|Path
; Set the static widths for some of it's columns
LV_ModifyCol(1, 20)
LV_ModifyCol(2, 40)
		;}
		;{ Tab #3: 'Manage process assistants'.
Gui, Tab, Manage process assistants
Gui, Add, Button, x374 y21 gAddNewRule, Add new rule
Gui, Add, Button, x+0 gDeleteRules, Delete selected rule(s)
Gui, Add, ListView, x0 y+0 +Resize +Grid vAssistantsList, #|Trigger condition|Scripts to execute
LV_ModifyCol(1, 20)
		;}
		;{ StatusBar
Gui, Add, StatusBar
SB_SetParts(60, 85)
		;}
		;{ Startup labels executions.
Gui, Submit, NoHide
token := 1
GoSub, AssistantsList
GoSub, ProcessList
GoSub, ManageProcesses
GoSub, FolderTree
GoSub, BookmarksList
SysGet, UA, MonitorWorkArea	; Getting Usable Area info.
If storePosAndSize
{
	IniRead, sw_W, Settings.ini, Script's window, sizeW, 800
	IniRead, sw_H, Settings.ini, Script's window, sizeH, 600
	IniRead, sw_X, Settings.ini, Script's window, posX, % (UARight - sw_W) / 2
	IniRead, sw_Y, Settings.ini, Script's window, posY, % (UABottom - sw_H) / 2
}
Else
	sizeW := 800, sizeH := 600, posX := (UARight - sw_W) / 2, posY := (UABottom - sw_H) / 2
SetTimer, ProcessList, %memoryScanInterval%
GoSub, GuiShow
Return
		;}
	;}
;}

;{ GUI Actions
	;{ G-Labels of main GUI.
GuiShow:
	Gui, +Resize +MinSize666x222
	; Gui, Show, % "x" sw_X " y" sw_Y " w" sw_W - 16 " h" sw_H - 38, Manage Scripts	; FIXME: sometimes this causes the "Error: Invalid option" upon script's execution + it will probably have window size bug on other platforms/theme, since I've tuned the values to fix it for Win7 with Aero.
	Gui, Show, % "x" sw_X " y" sw_Y " w" sw_W " h" sw_H , Manage Scripts
Return

GuiSize:	; Expand or shrink the ListView in response to the user's resizing of the window.
	If !(A_EventInfo == 1)
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
		LV_ModifyCol(2, (A_GuiWidth - 39) * 0.6)
		LV_ModifyCol(3, (A_GuiWidth - 39) * 0.4)
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
	If storePosAndSize || rememberPosAndSize
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
	Gosub, GuiClose
	If storePosAndSize
	{
			IniWrite, %sw_X%, Settings.ini, Script's window, posX
			IniWrite, %sw_Y%, Settings.ini, Script's window, posY
			IniWrite, %sw_W%, Settings.ini, Script's window, sizeW
			IniWrite, %sw_H%, Settings.ini, Script's window, sizeH
	}
	ExitApp
	;}
	;{ Tab #1: gLabels of [Tree/List]Views.
		;{ FolderTree
FolderTree:	; TreeView's G-label that should update the "FolderTree" TreeView as well as trigger "FileList" ListView update.
	Global activeControl := A_ThisLabel
	If (A_GuiEvent == "") || (A_GuiEvent == "Normal") || (A_GuiEvent == "S")	; In case of script's initialization, user's left click or keyboard selection - (re)fill the 'FileList' listview.
	{
		If (A_GuiEvent == "Normal")	; If user left clicked anything in the TreeView.
		{
			If (A_EventInfo != 0)	; If he clicked an empty space at right from a folder's name.
				TV_Modify(A_EventInfo, "Select")	; Forcefully select that line.
			Else If (A_EventInfo == 0)	; If he clicked an empty space (not the one at right from a folder's name).
				TV_Modify(0)	; Remove selection and thus make 'FileList' ListView show the root folder's contents.
		}
		Gui, TreeView, FolderTree
		TV_GetText(selectedItemText, A_EventInfo)	; Determine the full path of the selected folder:
		ParentID := A_EventInfo
		If memorizePath	; Variable 'memorizePath' is used as a token: if it returns true - then we shall use old path to the folder as the current one (otherwise the default path would be used).
			memorizePath := selectedFullPath
		Loop	; Build the full path to the selected folder.
		{
			ParentID := TV_GetParent(ParentID)
			If !ParentID	; No more ancestors.
				Break
			TV_GetText(ParentText, ParentID)
			SelectedItemText = %ParentText%\%selectedItemText%
		}
		selectedFullPath := startFolder "\" selectedItemText
		If memorizePath
			selectedFullPath := memorizePath
		If (A_GuiEvent == "") && !token
			Return
		Gui, ListView, FileList	; Put the files into the ListView:
		LV_Delete()	; Delete old data.
		GuiControl, -Redraw, FileList	; Improve performance by disabling redrawing during load.
		token := memorizePath := FileCount := TotalSize := 0	; Init prior to loop below.
		Loop %selectedFullPath%\*.ahk	; This omits folders and shows only .ahk-files in the ListView.
		{
			FormatTime, created, %A_LoopFileTimeCreated%, dd.MM.yyyy (HH:mm:ss)
			FormatTime, modified, %A_LoopFileTimeModified%, dd.MM.yyyy (HH:mm:ss)
			LV_Add("", A_LoopFileName, Round(A_LoopFileSize / 1024, 1) . " KB", created, modified)
			FileCount++
			TotalSize += A_LoopFileSize
		}
		GuiControl, +Redraw, FileList
		GoSub, sbUpdate
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
	If (A_GuiEvent == "Normal") || (A_GuiEvent == "*") || (bookmarksModified == 1)
		Global activeControl := A_ThisLabel
	If !((A_GuiEvent == "") || (bookmarksModified == 1)) || !FileExist("Settings.ini") || (A_GuiEvent == "C")	; Filter events out: (re)fill the listview only if the script just started, or we added/removed (a) bookmark(s). And don't fill anything if we have no bookmarks at all.
		Return
	If bookmarksModified	; That variable is used as token for adding and deleting bookmarks.
		GoSub, BookmarksModified	; First update the bookmarks file, and only then fill the listview.
	A_IndexMy := nBookmarks := bookmarks := token := ""
	Gui, ListView, BookmarksList
	LV_Delete()	; Clear all rows.
	IniRead, bookmarks, Settings.ini, Bookmarks, list
	If bookmarks
	{
		StringSplit, bookmarks, bookmarks, |
		While (A_IndexMy < bookmarks0)
		{
			A_IndexMy++
			thisBookmark := bookmarks%A_IndexMy%
			IfExist, %thisBookmark%	; Define whether the previously bookmared file exists.
			{	; If the file exists - display it in the list.
				SplitPath, thisBookmark, name	; Get file's name from it's path.
				FileGetSize, size, %thisBookmark%	; Get file's size.
				FileGetTime, created, %thisBookmark%, C	; Get file's creation date.
				FormatTime, created, %created%, dd.MM.yyyy (HH:mm:ss)	; Transofrm creation date into a readable format.
				FileGetTime, modified, %thisBookmark%	; Get file's last modification date.
				FormatTime, modified, %modified%, dd.MM.yyyy (HH:mm:ss)	; Transofrm creation date into a readable format.
				LV_Insert(A_IndexMy, "", A_IndexMy, name, thisBookmark, Round(size / 1024, 1) . " KB", created, modified)	; Add the listitem.
			}
			Else	; If the file doesn't exist - remove that bookmark.
			{
				bookmarksModified := 1
				If !bookmarksToDelete
					bookmarksToDelete := A_IndexMy
				Else
					bookmarksToDelete := bookmarksToDelete . "," A_IndexMy
			}
		}
	}
	If bookmarksModified
		GoSub, BookmarksModified
Return

BookmarksModified:
	If bookmarksToDelete
	{
		Loop, Parse, bookmarks, |
			If (!RegExMatch(bookmarksToDelete, "\b" A_Index "\b"))
				nBookmarks .= (StrLen(nBookmarks) ? "|" : "") A_LoopField
		bookmarks := nBookmarks
	}
	Loop ; Remove double pipes.
	{
		IfInString, bookmarks, ||
			StringReplace, bookmarks, bookmarks, ||, |, All
		Else
			Break
	}
	IniWrite, %bookmarks%, Settings.ini, Bookmarks, list
	bookmarksToDelete := bookmarksModified := ""
	GoSub, BookmarksList
Return
		;}
	;}
	;{ Tab #2: gLabel of ListView.
ManageProcesses:	; Update the list of running scripts on the Tab #2.
	Global activeControl := A_ThisLabel, oldListItems := listItems, newRows := deadRows := 0
	Gui, ListView, ManageProcesses
	Loop, %indexScripts%	; Transform the scriptsSnapshot's "pid" values into a pipe-separated string and store it in the 'listItems' variable.
		listItems := (A_Index != 1) ? (listItems "|" scriptsSnapshot[A_Index, "pid"]) : (scriptsSnapshot[A_Index, "pid"])
	Loop, parse, oldListItems, |	; Look for scripts' dead processes and fulfill 'deadRows' variable with their rows' numbers separated by pipes.
	{
		this := A_LoopField
		Loop, Parse, listItems, |
		{
			stillLives := 0
			If (this == A_LoopField)
			{
				stillLives := 1
				Break
			}
		}
		If !stillLives
			deadRows := ((deadRows) ? (deadRows "|" A_Index) : (A_Index))
	}
	If deadRows	; Delete rows if any scripts's processes were found dead.
	{
		Loop, Parse, deadRows, |
		{
			If (A_Index == 1)
				this := A_LoopField	; This would be the 1st row to delete, thus since that row and up to the end of the list - we'll have to re-index them.
			LV_Delete(A_LoopField + 1 - A_Index)
		}
		Loop, %indexScripts%	; Re-index rows #'s (first column) if needed.
			If (A_Index >= this)
				LV_Modify(A_Index,, A_Index)
	}
	Loop, Parse, listItems, |	; Look for scripts' new processes and fulfill 'newRows' variable with their rows' numbers separated by pipes.
	{
		this := A_LoopField
		Loop, Parse, oldListItems, |
		{
			newFound := 0
			If (this == A_LoopField)
			{
				newFound := 1
				Break
			}
		}
		If !newFound
			newRows := ((newRows) ? (newRows "|" A_Index) : (A_Index))
	}
	If newRows	; Add new rows for the newly found scripts.
		Loop, Parse, newRows, |
			LV_Add(, A_LoopField, scriptsSnapshot[A_LoopField, "pid"], scriptsSnapshot[A_LoopField, "name"], scriptsSnapshot[A_LoopField, "path"])
Return
	;}
	;{ Tab #3: gLabels of ListView.
AssistantsList:
	Global activeControl := A_ThisLabel, Global conditions, Global triggeredActions
	rowShift := 0
	Gui, ListView, AssistantsList
	IniRead, rules, Settings.ini, Assistants
	If rules
	{
		StringSplit, rule, rules, `n	; Each rule is stored on a new line.
		Loop, %rule0%
		{
			ruleN := A_Index	; 'ruleN' == the # of the rule being parsed.
			StringTrimLeft, rule%ruleN%, rule%ruleN%, 1 + StrLen(ruleN)	; Cut away ini-file's "keys".
			Loop, Parse, rule%A_Index%, >	; Trigger condition (TC) in a rule is separated by the ">" from the triggered actions (TA), which are the process(es) to be executed upon TC.
			{
				If (A_Index == 1)	; Left part of each rule contains a group of pipe-separated TCs.
				{
					conditions := ((conditions) ? (conditions "?" A_LoopField) : (A_LoopField))	; Preparing data for further parsing by the 'ProcessList' subroutine. Save TC-groups of all the rules into a single variable 'conditions' and separate the groups with the "?".
					If A_LoopField	; Safe check against empty groups of TCs.
					{
						Loop, Parse, A_LoopField, |	; If there are multiple TCs - they should be pipe-separated.
						{
							If A_LoopField	; Safe check against empty TCs.
							{
								tcRows := A_Index	; Number of rows to be occupied by the TC.
								LV_Add(, ((A_Index == 1) ? (ruleN) : ("")), A_LoopField)
							}
						}
					}
				}
				Else If (A_Index == 2)	; Right part of each rule contains pipe separated TAs.
				{
					triggeredActions := ((triggeredActions) ? (triggeredActions "?" A_LoopField) : (A_LoopField))	; Preparing data for further parsing by the 'ProcessList' subroutine. Save TA-groups of all the rules into a single variable 'triggeredActions' and separate the groups with the "?".
					If A_LoopField	; Safe check against empty groups of TAs.
					{
						Loop, Parse, A_LoopField, |	; If there are multiple TAs - they should be pipe-separated.
						{
							If A_LoopField	; Safe check against empty TAs.
							{
								taRows := A_Index	; Number of rows to be occupied by the TAs.
								If (taRows > tcRows)
									LV_Add(,,, A_LoopField)
								Else
									LV_Modify(taRows + rowShift,,,, A_LoopField)
							}
						}
					}
				}
			}
			rowsOccupied := ((rowsOccupied) ? (rowsOccupied "|" ((taRows > tcRows) ? (taRows) : (tcRows))) : (((taRows > tcRows) ? (taRows) : (tcRows))))	; This variable contains pipe-separated numbers which represent the number of rows occupied by each rule.
			rowShift := ((rowShift) ? (rowShift + ((taRows > tcRows) ? (taRows) : (tcRows))) : (((taRows > tcRows) ? (taRows) : (tcRows))))	; This variable contains the total number of the occupied rows.
		}
	}
Return
	;}
	;{ ProcessList.
ProcessList:
	If !indexProcesses
		processesOldSnapshot := []
	Else
		processesOldSnapshot := processesSnapshot
	If !indexScripts
		scriptsOldSnapshot := []
	Else
		scriptsOldSnapshot := scriptsSnapshot
	Global processesSnapshot := [], Global scriptsSnapshot := [], Global indexScripts := 0, Global indexProcesses := 0
	For Process In ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")	; Parsing through a list of running processes to filter out non-ahk ones (filters are based on "If RegExMatch" rules).
	{	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
		indexProcesses++
		processesSnapshot[indexProcesses, "pid"] := Process.ProcessId
		processesSnapshot[indexProcesses, "exe"] := Process.ExecutablePath
		; processesSnapshot[indexProcesses, "cmd"] := Process.CommandLine
		If (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))
		{
			indexScripts++
			scriptsSnapshot[indexScripts, "pid"] := Process.ProcessId	; Using "ProcessId" param to fulfill our "pidsArray" array.
			scriptsSnapshot[indexScripts, "name"] := scriptName	; The first RegExMatch outputs to "scriptName" variable, who's contents we use to fulfill our "scriptNamesArray" array.
			scriptsSnapshot[indexScripts, "path"] := scriptPath	; The second RegExMatch outputs to "scriptPath" variable, who's contents we use to fulfill our "scriptPathArray" array.
		}
	}
	isTCGroupMet()
	If (activeTab == 2)
		GoSub, ManageProcesses
Return
	;}
	;{ StatusBar.
sbUpdate:
; Update the three parts of the status bar to show info about the currently selected folder:
	SB_SetText(FileCount . " files", 1)
	SB_SetText(Round(TotalSize / 1024, 1) . " KB", 2)
	SB_SetText(selectedFullPath, 3)
Return
	;}
	;{ Tab #1: gLabels of buttons.
RunSelected:	; G-Label of "Run selected" button.
	If (activeControl == "FileList")	; In case the last active GUI element was "FileList" ListView.
	{
		Gui, ListView, FileList
		selected := selectedFullPath "\" getScriptNames()
		If !selected
			Return
		StringReplace, selected, selected, |, |%selectedFullPath%\, All
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
	Gui, ListView, FileList
	selected := getScriptNames()
	If !selected
		Return
	IniRead, bookmarks, Settings.ini, Bookmarks, list
	selected := selectedFullPath "\" selected
	StringReplace, selected, selected, |, |%selectedFullPath%\, All
	StringReplace, selected, selected, \\, \, All
	bookmarks := ((bookmarks) ? (bookmarks "|" selected) : (selected))
	IniWrite, %bookmarks%, Settings.ini, Bookmarks, list
	bookmarksModified := 1
	GoSub, BookmarksList
Return

DeleteSelected:	; G-Label of "Delete selected" button.
	If (activeControl == "BookmarksList") || (activeControl == "FileList")
		Gui, ListView, %activeControl%
	If (activeControl == "BookmarksList")	; In case the last active GUI element was "BookmarksList" ListView.
	{
		bookmarksToDelete := getRowNs()
		If !bookmarksToDelete
			Return
		bookmarksModified := 1
		GoSub, %activeControl%
	}
	Else If (activeControl == "FileList")	; In case the last active GUI element was "FileList" ListView.
	{
		selected := getScriptNames()
		If !selected
			Return
		Msgbox, 1, Confirmation required, Are you sure want to delete the selected file(s)?
		IfMsgBox, OK
		{
			selected := selectedFullPath "\" selected
			StringReplace, selected, selected, |, |%selectedFullPath%\, All
			Loop, Parse, selected, |
				FileDelete, %A_LoopField%
			memorizePath := 1	; This is used as a token.
			GoSub, FolderTree
		}
	}
	; Else If (activeControl == "FolderTree")	; In case the last active GUI element was "FileList" TreeView.
	; {
	; 	Msgbox, 1, Confirmation required, Are you sure want to delete the selected folder(s) and it's/their contents?
	; 	IfMsgBox, OK
	; 	{
	; 		
	; 	}
	; }
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
1. Every rule has to consist of 2 parts, separated by the ">" character:
  a. the left part of a rule is used to specify TCs. TCs can be specified as a process name (explorer.exe) or as a full or partial path (without the "\" at start) to an executable. If multiple TCs are specified in 1 rule - that means that if ANY of those processes appears - it will trigger the rule.
  b. the right part of a rule is used to specify TAs. TAs can be specified only by it's full path to the *.ahk file (but don't specify the path to the "AutoHotkey.exe"). If multiple TAs are specified in 1 rule - that means that ALL of them will get executed/closed whenever the trigger works out.
2. One rule may contain multiple TCs or TAs: you just need to separate them by the "|" (pipe) symbol.

A few examples:
firefox.exe|Program Files\GoogleChrome\chrome.exe|C:\Program Files\Internet Explorer\iexplore.exe>C:\Program Files\AHK-Scripts\browserHelper.ahk

notepad.exe>C:\Program Files\AHK-Scripts\pimpMyPad.ahk

C:\Games\DOTA\dota.exe>C:\DOTA Scripts\cooldownSoundNotify.ahk|C:\DOTA Scripts\cheats\showInvisibleEnemies.ahk
),, 745, 515
If !(ErrorLevel) && ruleAdd	; Do something only if user clicked [OK] and if he actually entered something.
	IfNotInString, ruleAdd, >	; Fool-proof.
	{
		Run, https://en.wikipedia.org/wiki/RTFM
		Msgbox RTFM!
	}
	Else	; If everything seems to be okay - add the rule to the Settings.ini and re-build the 'AssistantsList' LV.
	{
		IniWrite, %ruleAdd%, Settings.ini, Assistants, % rule0 + 1
		Gui, ListView, AssistantsList
		LV_Delete()
		GoSub, AssistantsList
	}
Return

DeleteRules:
	Gui, ListView, AssistantsList
	rulesToDelete := newRules := selectedRow := rowsSelected := rulesToDeleteIndex := isThatRowOfRule := "", thisIndex := thatIndex := "0"
	selectedRows := getRowNs()
	If !(selectedRows)	; Safe check.
		Return
	Loop, Parse, selectedRows, |	; Getting the number of items in the 'selectedRows'.
		rowsSelected := A_Index
	Loop, Parse, selectedRows, |
	{
		selectedRow := A_LoopField
		Loop
		{
			isThatRowOfRule := ""
			LV_GetText(isThatRowOfRule, selectedRow, 1)
			If isThatRowOfRule	; we found # in the left column.
			{
				If !rulesToDelete	; no rules to delete yet, so we just assign it
					rulesToDelete := isThatRowOfRule
				Else	; there are rules to delete, so we need to decide wheter to add a new value or not
				{
					Loop, Parse, rulesToDelete, |	; Getting the number of items in the 'rulesToDelete'.
						rulesToDeleteIndex := A_Index
					Loop, Parse, rulesToDelete, |
					{
						If (isThatRowOfRule == A_LoopField)
							Break
						Else If (rulesToDeleteIndex == A_Index) && (isThatRowOfRule != A_LoopField)
							rulesToDelete .= "|" isThatRowOfRule
					}
				}
				Break
			}
			Else	; Didn't find the number in the left column, checking the row above.
				selectedRow--
		}
	}
	Loop, Parse, rulesToDelete, |	; Getting the number of items in the 'rulesToDelete'.
		rulesToDeleteIndex := A_Index
	Loop, %rule0%
	{
		thisIndex := A_Index
		Loop, Parse, rulesToDelete, |
		{
			If (A_LoopField == thisIndex)
				Break
			Else If (A_LoopField != thisIndex) && (A_Index == rulesToDeleteIndex)
			{
				thatIndex++
				newRules := ((newRules) ? (newRules "`n" thatIndex "=" rule%thisIndex%) : (thatIndex "=" rule%thisIndex%))
			}
		}
	}
	IniWrite, %newRules%, Settings.ini, Assistants
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
; Usable by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill and re-execute'.
; Input: none.
; Output: script paths of the files in the selected rows.
	rowNs := getRowNs()
	Loop, Parse, rowNs, |
		scriptsPaths := ((A_Index == 1) ? (scriptsSnapshot[A_LoopField, "path"]) : (scriptsPaths "|" scriptsSnapshot[A_LoopField, "path"]))
	Return scriptsPaths
}
	;}
	;{ Functions of process control.
run(paths)	; Runs selected scripts.
{
; Used by: Tab #1 'Manage files' - LVs: 'FileList', 'BookmarksList'; buttons: 'Run selected', 'Kill and re-execute'; functions: isTAGroupRunning().
; Input: path or paths (separated by pipes, if many).
; Output: none.
	If !paths
		Return
	Loop, Parse, paths, |
		Run, "%A_AhkPath%" "%A_LoopField%"
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
; Used by: Tab #2 'Manage processes' - LV 'ManageProcesses'; buttons: 'Kill', 'Kill and re-execute'.
; Input: PID(s) (separated by pipes, if many).
; Output: none.
	If !pids
		Return
	Loop, Parse, pids, |
		Process, Close, %A_LoopField%
	NoTrayOrphans()
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
	NoTrayOrphans()
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
	;{ Functions needed for 'Process Assistant' to work.

isTCGroupMet(ruleGroupN = 0)	; Checks either all or specific TC group if any of it's TC's is running. It also calls other functions, like isTCMet() and isTAGroupRunning().
{
; Used by: soubroutines: 'ProcessList'; functions: isTCGroupMet().
; Input: specific TC-group's number or if it's called with no argument (or 0) - it calls self recursively.
; Output: none.
	If conditions	; Just a safe check, not really needed.
	{
		Loop, Parse, conditions, ?	; Parse TC-groups in the contents of 'conditions' variable.
		{
			If !ruleGroupN	; The function was called with no argument, thus it should recursively call self to check every TC group.
				isTCGroupMet(A_Index)
			Else If (A_Index != ruleGroupN)
				Continue
			Else
			{
				StringSplit, this, A_LoopField, |
				that := A_Index
				Loop, Parse, A_LoopField, |	; Parse TCs in the specified TC-group.
				{
					isAnyTCMet := isTCMet(A_LoopField)
					If isAnyTCMet	; At least 1 TC in this group is met, we need to check if the corresponding TA group is running or not and execute it if needed.
					{
						isTAGroupRunning(that, 1)
						Break
					}
					Else If (this0 == A_Index)	; We've parsed the whole TC group and found out that no TCs in this group are met, thus we have to make sure that the corresponding TA group is dead too.
						isTAGroupRunning(that, 0)
				}
			}
		}
	}
	Return
}
isTCMet(TC)	; Check if a specific TC (not a group) is running or not.
{
; Used by: function isTCGroupMet().
; Input: TC's path.
; Output: "1" if running or otherwise "0".
	Loop, %indexProcesses%
	{
		this := processesSnapshot[A_Index, "exe"]
		IfInString, this, \%TC%
		{
			TCMet := 1
			Break
		}
		Else If (A_Index == indexProcesses)
			TCMet := 0
	}
	Return TCMet
}

isTAGroupRunning(ruleGroupN, SwitchOnOrOff)	; Check if specified TA-group is running and either kill the scripts (0) or run the scripts (1).
{
; Used by: functions: isTCGroupMet().
; Input: 1st argument is a number of a TA-group to check, 2nd argument forces either to make sure that all the scripts' processes from the corresponding TA-group are dead (0) and kill the living ones; or that they are running (1) and execute the not yet running ones.
; Output: none.
	Loop, Parse, triggeredActions, ?
	{
		If (ruleGroupN != A_Index)
			Continue
		Loop, Parse, A_LoopField, |
		{
			isAnyTAMet := isTAMet(A_LoopField)
			If !(isAnyTAMet) && (SwitchOnOrOff)
				run(A_LoopField)
			Else If (isAnyTAMet) && !(SwitchOnOrOff)
				toBeKilled := ((toBeKilled) ? (toBeKilled "|" isAnyTAMet) : (isAnyTAMet))
		}
	}
	If toBeKilled
		%howToQuitAssistants%(toBeKilled)
}

isTAMet(TA)	; Check if a specific TA (not a group) is running or not.
{
; Used by: functions: isTAGroupRunning().
; Input: TA's path.
; Output: script's PID if it's running or otherwise "0".
	Loop, %indexScripts% 
	{
		this := scriptsSnapshot[A_Index, "path"]
		If (TA == this)
		{
			TAMet := scriptsSnapshot[A_Index, "pid"]
			Break
		}
		Else If (A_Index == indexScripts)
			TAMet := 0
	}
	Return TAMet
}
	;}
	;{ Fulfill 'TreeView' GUI.
buildTree(folder, ParentItemID = 0)
{
; This function adds all the subfolders in the specified folder to the TreeView.
; It also calls itself recursively to build a nested tree structure of any depth.
	If !folder
		Return
	Loop %folder%\*.*, 2	; Retrieve all of Folder's sub-folders.
		buildTree(A_LoopFileFullPath, TV_Add(A_LoopFileName, ParentItemID, "Icon1"))
}
	;}
	;{ NoTrayOrphans() - a bunch of functions to remove tray icons of dead processes.
NoTrayOrphans()
{
	TrayInfo := TrayIcons(sExeName, "ahk_class Shell_TrayWnd", "ToolbarWindow32" . GetTrayBar()) "`n"
		. TrayIcons(sExeName, "ahk_class NotifyIconOverflowWindow", "ToolbarWindow321")
	Loop, Parse, TrayInfo, `n
	{
		ProcessName := StrX(A_Loopfield, "| Process: ", " |")
		ProcesshWnd := StrX(A_Loopfield, "| hWnd: ", " |")
		ProcessuID := StrX(A_Loopfield, "| uID: ", " |")
		If !ProcessName && ProcesshWnd
			RemoveTrayIcon(ProcesshWnd, ProcessuID)
	}
}

TrayIcons(sExeName, traywindow, control)
{
	DetectHiddenWindows, On
	WinGet, pidTaskbar, PID, %traywindow%
	hProc := DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
	pProc := DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 32, "Uint", 0x1000, "Uint", 0x4)
	SendMessage, 0x418, 0, 0, %control%, %traywindow%
	Loop, %ErrorLevel%
	{
		SendMessage, 0x417, A_Index - 1, pProc, %control%, %traywindow%
		VarSetCapacity(btn, 32, 0), VarSetCapacity(nfo, 32, 0)
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pProc, "Uint", &btn, "Uint", 32, "Uint", 0)
		iBitmap := NumGet(btn, 0)
		idn := NumGet(btn, 4)
		Statyle := NumGet(btn, 8)
		If dwData := NumGet(btn, 12)
			iString := NumGet(btn, 16)
		Else
		{
			dwData := NumGet(btn, 16, "int64")
			iString := NumGet(btn, 24, "int64")
		}
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "Uint", &nfo, "Uint", 32, "Uint", 0)
		If NumGet(btn,12)
		{
			hWnd := NumGet(nfo, 0)
			uID := NumGet(nfo, 4)
			nMsg := NumGet(nfo, 8)
			hIcon := NumGet(nfo, 20)
		}
		Else
		{
			hWnd := NumGet(nfo, 0, "int64")
			uID := NumGet(nfo, 8)
			nMsg := NumGet(nfo, 12)
			hIcon := NumGet(nfo, 24)
		}
		WinGet, pid, PID, ahk_id %hWnd%
		WinGet, sProcess, ProcessName, ahk_id %hWnd%
		WinGetClass, sClass, ahk_id %hWnd%
		If !sExeName || (sExeName == sProcess) || (sExeName == pid)
		{
			VarSetCapacity(sTooltip, 128)
			VarSetCapacity(wTooltip, 128*2)
			DllCall("ReadProcessMemory", "Uint", hProc, "Uint", iString, "Uint", &wTooltip, "Uint", 128*2, "Uint", 0)
			DllCall("WideCharToMultiByte", "Uint", 0, "Uint", 0, "str", wTooltip, "int", -1, "str", sTooltip, "int", 128, "Uint", 0, "Uint", 0)
			sTrayIcons .= "idx: " A_Index - 1 " | idn: " idn " | Pid: " pid " | uID: " uID " | MessageID: " nMsg " | hWnd: " hWnd " | Class: " sClass " | Process: " sProcess " | Icon: " hIcon " | Tooltip: " wTooltip "`n"
		}
	}
	DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pProc, "Uint", 0, "Uint", 0x8000)
	DllCall("CloseHandle", "Uint", hProc)
	Return sTrayIcons
}

GetTrayBar()
{
	ControlGet, hParent, hWnd,, TrayNotifyWnd1, ahk_class Shell_TrayWnd
	ControlGet, hChild, hWnd,, ToolbarWindow321, ahk_id %hParent%
	Loop
	{
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		If (hWnd == hChild)
			idxTB := A_Index
		If !hWnd || (hWnd == hChild)
			Break
	}
	Return idxTB
}

StrX(H, BS = "", ES = "", Tr = 1, ByRef OS = 1)
{
	Return (SP := InStr(H, BS, 0, OS)) && (L := InStr(H, ES, 0, SP + StrLen(BS))) && (OS := L + StrLen(ES)) ? SubStr(H, SP := Tr ? SP + StrLen(BS) : SP, (Tr ? L : L + StrLen(ES)) -SP) : ""
}

RemoveTrayIcon(hWnd, uID, nMsg = 0, hIcon = 0, nRemove = 2)
{
	NumPut(VarSetCapacity(ni,444,0), ni)
	NumPut(hWnd, ni, 4)
	NumPut(uID, ni, 8)
	NumPut(1|2|4, ni, 12)
	NumPut(nMsg, ni, 16)
	NumPut(hIcon, ni, 20)
	Return DllCall("shell32\Shell_NotifyIconA", "Uint", nRemove, "Uint", &ni)
}
	;}
;}