/* MasterScript.ahk
Description: this is a script manager written in .ahk and supposed to control other .ahk scripts.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
*/

;{ TODO:
; 1. Functions to control scripts:
; 	a. Hide/restore scripts' tray icons.
; 2. Improve TreeView.
;	a. It should load all disks' root folders (and their sub-folders) + folders specified by user (that info should also get stored to settings).
;	b. TreeView should always only load folder's contents + contents of it's sub-folders. And load more, when user selected a deeper folder.
; 3. [If possible:] Combine suspendProcess() and resumeProcess() into a single function.
;	This might be helpful: http://www.autohotkey.com/board/topic/41725-how-do-i-disable-a-script-from-a-different-script/#entry287262
; 4. [If possible:] Add more scripts' info to ProcessList: hotkey suspend state, script's pause state.
; 5. Handle scripts' icons hiding/restoring.
; 6. Add "Process assistant" feature.
;}

;{ Settings block.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force
DetectHiddenWindows, On	; Needed for "pause" and "suspend" commands.
memoryScanInterval := 1000	; Specify a value in milliseconds.
SplitPath, A_AhkPath,, startFolder
rememberPosAndSize := 1	; 1 = Make script's window remember it's position and size between window's closures. 0 = always open 800x600 on the center of the screen.
storePosAndSize := 1	; 1 = Make script store info (into the "Settings.ini" file) about it's window's size and position between script's closures. 0 = do not store that info in the Settings.ini.
; startFolder := "C:\Program Files\AutoHotkey"
;}

;{ GUI Create
	;{ Create folder icons.
OnExit, ExitApp
ImageListID := IL_Create(1)	; Create an ImageList to hold 1 icon.
	IL_Add(ImageListID, "shell32.dll", 4)	; 'Folder' icon
	; IL_Add(ImageListID, "shell32.dll", 13)	; 'Process' icon
	; IL_Add(ImageListID, "shell32.dll", 44)	; 'Bookmark' icon
	; IL_Add(ImageListID, "shell32.dll", 46)	; 'Up to the root folder' icon
	; IL_Add(ImageListID, "shell32.dll", 71)	; 'Script' icon
	; IL_Add(ImageListID, "shell32.dll", 138)	; 'Run' icon
	; IL_Add(ImageListID, "shell32.dll", 272)	; 'Delete' icon
	; IL_Add(ImageListID, "shell32.dll", 285)	; Neat 'Script' icon
	; IL_Add(ImageListID, "shell32.dll", 286)	; Neat 'Folder' icon
	; IL_Add(ImageListID, "shell32.dll", 288)	; Neat 'Bookmark' icon
	; IL_Add(ImageListID, "shell32.dll", 298)	; 'Folders tree' icon
	;}
	;{ Tray menu.
Menu, Tray, NoStandard
Menu, Tray, Add, Manage Scripts, GuiShow	; Create a tray menu's menuitem and bind it to a label that opens main window.
Menu, Tray, Default, Manage Scripts
Menu, Tray, Add
Menu, Tray, Standard
	;}
	;{ Add tabbed interface
Gui, Add, Tab2, AltSubmit x0 y0 w568 h46 Choose1 +Theme -Background gTabSwitch vactiveTab, Manage files|Manage processes	; AltSubmit here is needed to make variable 'activeTab' get active tab's number, not name.
		;{ Tab #1: 'Manage files'
Gui, Tab, Manage files
Gui, Add, Text, x26 y26, Choose a folder:
Gui, Add, Button, x301 y21 gRunSelected, Run selected
Gui, Add, Button, x+0 gBookmarkSelected, Bookmark selected
Gui, Add, Button, x+0 gDeleteSelected, Delete selected
; Folder list (left pane).
Gui, Add, TreeView, AltSubmit x0 y+0 +Resize gFolderTree vFolderTree HwndFolderTreeHwnd ImageList%ImageListID%	; Add TreeView for navigation in the FileSystem.	; ICON
AddSubFoldersToTree(startFolder)	; Fulfill TreeView.

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

; Status Bar.
Gui, Add, StatusBar
SB_SetParts(60, 85)
		;}
		;{ Tab #2: 'Manage processes'
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
Gui, Add, ListView, x0 y+0 +Resize +Grid gProcessList vProcessList, #|PID|Name|Path
; Set the static widths for some of it's columns
LV_ModifyCol(1, 20)
LV_ModifyCol(2, 40)

; Startup labels executions.
Gui, Submit, NoHide
token := 1
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
GoSub, GuiShow
Return
		;}
	;}
;}

;{ GUI Actions
	;{ G-Labels of main GUI.
GuiShow:
	Gui, +Resize +MinSize566x225
	Gui, Show, % "x" . sw_X . " y" . sw_Y . " w" . sw_W " h" . sw_H , Manage Scripts
	If (activeTab == 2)
		SetTimer, ProcessList, %memoryScanInterval%
Return

GuiSize:	; Expand or shrink the ListView in response to the user's resizing of the window.
	If !(A_EventInfo == 1)
	{	; The window has been resized or maximized. Resize GUI items to match the window's size.
		workingAreaHeight := A_GuiHeight - 86
		GuiControl, -Redraw, activeTab
		GuiControl, -Redraw, textBS
		GuiControl, -Redraw, FileList
		GuiControl, -Redraw, FolderTree
		GuiControl, -Redraw, BookmarksList
		GuiControl, -Redraw, ProcessList
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
		GuiControl, Move, ProcessList, % "w" . (A_GuiWidth + 1) . " h" . (workingAreaHeight + 20)
		Gui, ListView, ProcessList
		LV_ModifyCol(3, (A_GuiWidth - 78) * 0.3)
		LV_ModifyCol(4, (A_GuiWidth - 78) * 0.7)
		GuiControl, +Redraw, activeTab
		If (activeTab == 1)
		{
			GuiControl, +Redraw, textBS
			GuiControl, +Redraw, FileList
			GuiControl, +Redraw, FolderTree
			GuiControl, +Redraw, BookmarksList
		}
		Else
			GuiControl, +Redraw, ProcessList
	}
Return

GuiClose:
	If storePosAndSize || rememberPosAndSize
		WinGetPos, sw_X, sw_Y, sw_W, sw_H, Manage Scripts ahk_class AutoHotkeyGUI
	Gui, Hide
	SetTimer, ProcessList, Off
Return

TabSwitch:
	Gui, Submit, NoHide
	If (activeTab == 1)
	{
		SetTimer, ProcessList, Off
		GuiControl, +Redraw, activeTab
		GuiControl, +Redraw, textBS
		GuiControl, +Redraw, FileList
		GuiControl, +Redraw, FolderTree
		GuiControl, +Redraw, BookmarksList
	}
	Else
	{
		GoSub, ProcessList
		SetTimer, ProcessList, %memoryScanInterval%
		GuiControl, +Redraw, ProcessList
	}
Return

ExitApp:
	Gosub, GuiClose
	If storePosAndSize
	{
		If sw_X > 0
			IniWrite, %sw_X%, Settings.ini, Script's window, posX
		If sw_Y > 0
			IniWrite, %sw_Y%, Settings.ini, Script's window, posY
		If sw_W > 0
			IniWrite, %sw_W%, Settings.ini, Script's window, sizeW
		If sw_H > 0
			IniWrite, %sw_H%, Settings.ini, Script's window, sizeH
	}
	ExitApp
	;}
	;{ Tab #1: gLabels of [Tree/List]Views.
		;{ FolderTree
FolderTree:	; TreeView's G-label that should trigger ListView update.
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
		Global activeControl := A_ThisLabel
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
	
		; Update the three parts of the status bar to show info about the currently selected folder:
		SB_SetText(FileCount . " files", 1)
		SB_SetText(Round(TotalSize / 1024, 1) . " KB", 2)
		SB_SetText(selectedFullPath, 3)
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
	; GuiControl, -Redraw, BookmarksList	; Improve performance by disabling redrawing during load.
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
	; GuiControl, +Redraw, BookmarksList
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
	;{ Tab #1: gLabels of buttons.
RunSelected:
	If (activeControl == "FileList")
	{
		Gui, ListView, FileList
		selected := selectedFullPath "\" getScriptsNamesOfSelectedFiles(getSelectedRowsNumbers())
		StringReplace, selected, selected, |, |%selectedFullPath%\, All
	}
	Else If (activeControl == "BookmarksList")
	{
		Gui, ListView, BookmarksList
		selected := getScriptsNamesOfSelectedFiles(getSelectedRowsNumbers())
	}
	run(selected)
Return

BookmarkSelected:	; G-Label of "Bookmark selected" button.
	Gui, ListView, FileList
	selected := getScriptsNamesOfSelectedFiles(getSelectedRowsNumbers())
	IniRead, bookmarks, Settings.ini, Bookmarks, list
	selected := selectedFullPath "\" selected
	StringReplace, selected, selected, |, |%selectedFullPath%\, All
	StringReplace, selected, selected, \\, \, All
	If bookmarks
		bookmarks .= "|" . selected
	Else
		bookmarks .= selected
	IniWrite, %bookmarks%, Settings.ini, Bookmarks, list
	bookmarksModified := 1
	GoSub, BookmarksList
Return

DeleteSelected:
	If (activeControl == "BookmarksList") || (activeControl == "FileList")
		Gui, ListView, %activeControl%
	If (activeControl == "BookmarksList")
	{
		bookmarksToDelete := getSelectedRowsNumbers()
		bookmarksModified := 1
		GoSub, %activeControl%
	}
	Else If (activeControl == "FileList")
	{
		Msgbox, 1, Confirmation required, Are you sure want to delete the selected file(s)?
		IfMsgBox, OK
		{
			selected := getScriptsNamesOfSelectedFiles(getSelectedRowsNumbers())
			selected := selectedFullPath "\" selected
			StringReplace, selected, selected, |, |%selectedFullPath%\, All
			Loop, Parse, selected, |
				FileDelete, %A_LoopField%
			memorizePath := 1	; This is used as a token.
			GoSub, FolderTree
		}
	}
	; Else If (activeControl == "FolderTree")
	; {
	; 	Msgbox, 1, Confirmation required, Are you sure want to delete the selected file(s)?
	; 	IfMsgBox, OK
	; 	{
	; 		
	; 	}
	; }
Return
	;}
	;{ Tab #2: gLabels of ListView.
ProcessList:
	Global activeControl := A_ThisLabel
	If listIndex	; If we previously retrieved data at least once.
		Global pidArrayOld := pidArray
	Global scriptNameArray := [], Global pidArray := [], Global scriptPathArray := []	; Defining and clearing arrays.
	listIndex := 0
	Gui, ListView, ProcessList
	; GuiControl, -Redraw, ProcessList	; Improve performance by disabling redrawing during load.
	For Process In ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")	; Parsing through a list of running processes to filter out non-ahk ones (filters are based on "If RegExMatch" rules).
	{	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
		; If (Process.ExecutablePath == A_AhkPath)	; This and the next line are the alternative to the If RegExMatch() below.
		; 	Process.CommandLine := RegExReplace(Process.CommandLine, "i)^.*\\|\.ahk\W*") . ".ahk"
		If (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*\\(?<Name>.*\.ahk)(""|\s)*$", script)) && (RegExMatch(Process.CommandLine, "Si)^(""|\s)*\Q" A_AhkPath "\E.*""(?<Path>.*\.ahk)(""|\s)*$", script))
		{
			listIndex++
			pidArray.Insert(Process.ProcessId)	; Using "ProcessId" param to fulfill our "pidsArray" array.
			scriptNameArray.Insert(scriptName)	; The first RegExMatch outputs to "scriptName" variable, who's contents we use to fulfill our "scriptNamesArray" array.
			scriptPathArray.Insert(scriptPath)	; The second RegExMatch outputs to "scriptPath" variable, who's contents we use to fulfill our "scriptPathArray" array.
			If !(pidArrayOld[listIndex] == Process.ProcessId)
				LV_Insert(listIndex, "", listIndex, Process.ProcessId, scriptName, scriptPath)	; Fill the ListView with the freshely retrieved data.
		}
	}
	Loop	; Remove listed dead scripts from the list.
	{
		deadRow := LV_Delete(listIndex + 1)
		If !deadRow
			Break
	}
	; GuiControl, +Redraw, ProcessList
	Return
	;}
	;{ Tab #2: gLabels of buttons.
Exit:
	Gui, ListView, ProcessList
	exit(getPIDsOfSelectedRows())
Return

Kill:
	Gui, ListView, ProcessList
	kill(getPIDsOfSelectedRows())
Return

killNreexecute:
	Gui, ListView, ProcessList
	killNreexecute(getPIDsOfSelectedRows())
Return

Reload:
	Gui, ListView, ProcessList
	reload(getPIDsOfSelectedRows())
Return

Pause:
	Gui, ListView, ProcessList
	pause(getPIDsOfSelectedRows())
Return

SuspendHotkeys:
	Gui, ListView, ProcessList
	suspendHotkeys(getPIDsOfSelectedRows())
Return

SuspendProcess:
	Gui, ListView, ProcessList
	suspendProcess(getPIDsOfSelectedRows())
Return

ResumeProcess:
	Gui, ListView, ProcessList
	resumeProcess(getPIDsOfSelectedRows())
Return
	;}
;}

;{ HOTKEYS
#IfWinActive Manage Scripts ahk_class AutoHotkeyGUI

Delete::
	; ControlGet, activeTab, Tab,, SysTabControl321
	If (activeTab == 1)
		GoSub, DeleteSelected
	Else If (activeTab == 2)
		Gosub, Kill
Return

Esc::
	If (activeControl == "BookmarksList") || (activeControl == "FileList") || (activeControl == "ProcessList")
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
getSelectedRowsNumbers()	; Usable by all ListViews.
{
	Loop, % LV_GetCount("Selected")
	{
		If !rowNumber
			selectedRowsNumbers := rowNumber := LV_GetNext(rowNumber)
		Else
			selectedRowsNumbers .= "|" rowNumber := LV_GetNext(rowNumber)
	}
	Return selectedRowsNumbers
}

getScriptsNamesOfSelectedFiles(selectedRowsNumbers)	; Usable by all ListViews.
{
	Loop, Parse, selectedRowsNumbers, |
	{
		If (activeControl == "FileList")
			LV_GetText(selectedFileScriptName, A_LoopField, 1)	; Column #1 contains files' names.
		Else If (activeControl == "BookmarksList")
			LV_GetText(selectedFileScriptName, A_LoopField, 3)	; Column #3 in 'BookmarksList' ListView contains full paths of the scripts.
		Else If (activeControl == "ProcessList")
			LV_GetText(selectedFileScriptName, A_LoopField, 4)	; Column #4 in 'ProcessList' ListView contains full paths of the scripts.
		If !selectedFilesScriptNames
			selectedFilesScriptNames := selectedFileScriptName
		Else
			selectedFilesScriptNames .= "|" selectedFileScriptName
	}
	Return selectedFilesScriptNames
}

getPIDsOfSelectedRows()	; Usable by 'ProcessList' ListView. That function outputs selected rows' process IDs as a string of PIDs separated by pipes.
{
	selectedRowsNumbers := getSelectedRowsNumbers()
	Loop, Parse, selectedRowsNumbers, |
	{
		LV_GetText(pidOfSelectedRow, A_LoopField, 2)	; Column #2 contains PIDs.
		If !selectedRowsPIDs
			selectedRowsPIDs := pidOfSelectedRow
		Else
			selectedRowsPIDs .= "|" pidOfSelectedRow
	}
	Return selectedRowsPIDs
}

getScriptsPathsOfSelectedProcesses(selectedRowsNumbers)	; Usable by 'ProcessList' ListView.
{
	selectedRowsNumbers := getSelectedRowsNumbers()
	Loop, Parse, selectedRowsNumbers, |
	{
		If (A_Index == 1)
			selectedRowsScriptsPaths := scriptPathArrayOld[A_LoopField]
		Else
			selectedRowsScriptsPaths .= "|" scriptPathArrayOld[A_LoopField]
	}
	Return selectedRowsScriptsPaths
}
	;}
	;{ Functions of process control.
run(pathOrPathsSeparatedByPipes)
{
	Loop, Parse, pathOrPathsSeparatedByPipes, |
		Run, "%A_AhkPath%" "%A_LoopField%"
}

exit(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		PostMessage, 0x111, 65307,,, ahk_pid %A_LoopField%
	NoTrayOrphans()
}

kill(pidOrPIDsSeparatedByPipes)	; Accepts a PID or a bunch of PIDs separated by pipes ("|").
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		Process, Close, %A_LoopField%
	NoTrayOrphans()
}

killNreexecute(pidOrPIDsSeparatedByPipes)
{
	scriptsPaths := getScriptsPathsOfSelectedProcesses(pidOrPIDsSeparatedByPipes)
	kill(pidOrPIDsSeparatedByPipes)
	NoTrayOrphans()
	Loop, Parse, scriptsPaths, |
		Run, "%A_AhkPath%" "%A_LoopField%"
}

; reload(pidOrPIDsSeparatedByPipes)
; {
; 	scriptsPaths := getScriptsPathsOfSelectedProcesses(pidOrPIDsSeparatedByPipes)
; 	; Loop, Parse, scriptsPaths, |
; 	; 	Run, % """" A_AhkPath """ /restart """ A_LoopField """"
; 	run(scriptsPaths)
; }

reload(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		PostMessage, 0x111, 65303,,, ahk_pid %A_LoopField%
}

pause(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		PostMessage, 0x111, 65403,,, ahk_pid %A_LoopField%
}

suspendHotkeys(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		PostMessage, 0x111, 65404,,, ahk_pid %A_LoopField%
}

suspendProcess(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
	{
		If !(procHWND := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", A_LoopField))
			Return -1
		DllCall("ntdll.dll\NtSuspendProcess", "Int", procHWND)
		DllCall("CloseHandle", "Int", procHWND)
	}
}

resumeProcess(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
	{
		If !(procHWND := DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", A_LoopField))
			Return -1
		DllCall("ntdll.dll\NtResumeProcess", "Int", procHWND)
		DllCall("CloseHandle", "Int", procHWND)
	}
}
	;}
	;{ Fulfill 'TreeView' GUI.
AddSubFoldersToTree(Folder, ParentItemID = 0)
{
	; This function adds to the TreeView all subfolders in the specified folder.
	; It also calls itself recursively to gather nested folders to any depth.
	Loop %Folder%\*.*, 2	; Retrieve all of Folder's sub-folders.
		AddSubFoldersToTree(A_LoopFileFullPath, TV_Add(A_LoopFileName, ParentItemID, "Icon1"))
}
	;}
	;{ NoTrayOrphans() - a function to remove tray icons of dead processes.
NoTrayOrphans()
{
	TrayInfo:= TrayIcons(sExeName,"ahk_class Shell_TrayWnd","ToolbarWindow32" . GetTrayBar()) "`n"
		. TrayIcons(sExeName,"ahk_class NotifyIconOverflowWindow","ToolbarWindow321")
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
			sTrayIcons .= "idx: " . A_Index-1 . " | idn: " . idn . " | Pid: " . pid . " | uID: " . uID . " | MessageID: " . nMsg . " | hWnd: " . hWnd . " | Class: " . sClass . " | Process: " . sProcess . " | Icon: " . hIcon . " | Tooltip: " . wTooltip . "`n"
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