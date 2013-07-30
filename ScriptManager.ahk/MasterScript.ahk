/* MasterScript.ahk
Description: this is a script manager written in .ahk and supposed to control other .ahk scripts.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
*/

;{ TODO:
; 1. Functions to control scripts:
; 	a. Hide/restore scripts' tray icons.
; 2. GUIs:
; 	a. A hotkey menu.
;	b. Make GUIs resizable.
;	c. Let user configure columns and memorize their order. (?) - not sure about that.
; 3. Add a hotkey to kill and execute all the scripts from bookmarks list.
; 4. Icons.
; 5. Improve TreeView.
;	a. It should load all disks' root folders (and their sub-folders) + folders specified by user (that info should also get stored to settings).
;	b. TreeView should always only load folder's contents + contents of it's sub-folders. And load more, when user selected a deeper folder.
; 6. Teach F5 and 'DeleteSelected' to properly refresh 'FileList' ListView.
;}

;{ BLAME:
; 1. suspendProcess() and resumeProcess() should better be a single function, but I don't know a way to get a suspension status of a process to let the script decide what operation to carry out.
; 2. That might be (im)possible, but I don't yet know how to get the scripts' "suspend hotkeys" and "pause" states.
; 3. I don't yet know if there is a way to get know about script's tray icon current state: is it possible? And if not - should there be some kind of internal storage for user's previous actions to take them into consideration?
;}

;{ Settings block.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Recommended for catching common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force
DetectHiddenWindows, On	; Needed for "pause" and "suspend" commands.
memoryScanInterval := 1000	; Specify a value in milliseconds.
SplitPath, A_AhkPath,, startFolder
; startFolder := "C:\Program Files\AutoHotkey"
;}

;{ GUI Create
	;{ Create folder icons.
ImageListID := IL_Create(5)	; ICON
Loop 5	; Below omits the DLL's path so that it works on Windows 9x too:	; ICON
	IL_Add(ImageListID, "shell32.dll", A_Index)	; ICON
	;}
	;{ Tray menu.
Menu, Tray, NoStandard
Menu, Tray, Add, Manage Scripts, GuiShow	; Create a tray menu's menuitem and bind it to a label that opens main window.
Menu, Tray, Default, Manage Scripts
Menu, Tray, Add
Menu, Tray, Standard
	;}
	;{ Add tabbed interface
Gui, Add, Tab2, x0 y0 Choose1 +Theme -Background gTabSwitch, Manage files|Manage processes
		;{ Tab #1: 'Manage files'
Gui, Tab, Manage files
Gui, Add, Text, x85 y27, Choose a folder:
Gui, Add, Button, x270 y21 gRunSelected, Run selected
Gui, Add, Button, x+0 gBookmarkSelected, Bookmark selected
Gui, Add, Button, x+0 gDeleteSelected, Delete selected
; Folder list (left pane).
Gui, Add, TreeView, AltSubmit x0 y+0 w269 h400 r20 +Resize gFolderTree vFolderTree ImageList%ImageListID%	; Add TreeView for navigation in the FileSystem.	; ICON
AddSubFoldersToTree(startFolder)

AddSubFoldersToTree(Folder, ParentItemID = 0)
{
	; This function adds to the TreeView all subfolders in the specified folder.
	; It also calls itself recursively to gather nested folders to any depth.
	Loop %Folder%\*.*, 2	; Retrieve all of Folder's sub-folders.
		AddSubFoldersToTree(A_LoopFileFullPath, TV_Add(A_LoopFileName, ParentItemID, "Icon4"))	; ICON
}
; File list (right pane).
Gui, Add, ListView, AltSubmit x+0 w700 h400 r20 +Resize +Grid gFileList vFileList, Name|Size (bytes)|Created|Modified
; Set the column sizes
LV_ModifyCol(1, "395")
LV_ModifyCol(2, "66")
LV_ModifyCol(3, "117")
LV_ModifyCol(4, "117")

Gui, Add, Text, x0 y+0, Bookmarked scripts:

; Bookmarks (bottom pane).
Gui, Add, ListView, AltSubmit x0 y+0 w969 h200 +Resize +Grid gBookmarksList vBookmarksList, #|Name|Full Path|Size|Created|Modified
; ADD FILEREAD/FILECREATE/REFRESH
; Set the column sizes
LV_ModifyCol(1, "20")
LV_ModifyCol(2, "185")
LV_ModifyCol(3, "479")
LV_ModifyCol(4, "47")
LV_ModifyCol(5, "117")
LV_ModifyCol(6, "117")

; Status Bar.
Gui, Add, StatusBar
SB_SetParts(60, 85)
		;}
		;{ Tab #2: 'Manage processes'
Gui, Tab, Manage processes
; Add buttons to trigger functions.
Gui, Add, Button, x2 y21 gKill, Kill
Gui, Add, Button, x+0 gkillNreload, Kill and reload
Gui, Add, Button, x+0 gRestart, Restart
Gui, Add, Button, x+0 gPause, (Un) pause
Gui, Add, Button, x+0 gSuspendHotkeys, (Un) suspend hotkeys
Gui, Add, Button, x+0 gSuspendProcess, Suspend process
Gui, Add, Button, x+0 gResumeProcess, Resume process

; Add the main "ListView" element and define it's size, contents, and a label binding.
Gui, Add, ListView, AltSubmit x0 y+0 w969 h612 r20 +Resize +Grid gProcessList vProcessList, #|pID|Name|Path

; Set the column sizes
LV_ModifyCol(1, "20")
LV_ModifyCol(2, "40")
LV_ModifyCol(3, "220")
LV_ModifyCol(4, "430")
GoSub, GuiShow
Return
		;}
	;}
;}

;{ GUI Actions
	;{ G-Labels of main GUI.
GuiShow:
	firstRun++
	If (activeTab == 2)
		activeTab := ""
	Gui, +Resize +MinSize525x225
	Gui, Show, w968 h678 Center, Manage Scripts
	If (firstRun == 1)
	{
		updateList := 1
		GoSub, FolderTree	; Won't be needed if I manage to create a proper FileTree monitoring folders.
		updateList := 1
		GoSub, BookmarksList
	}
	If ((firstRun != 1) && (activeTab != 1))
		SetTimer, ProcessList, %memoryScanInterval%
Return

GuiClose:
	Gui, Hide
	SetTimer, ProcessList, Off
Return

TabSwitch:
	ControlGet, activeTab, Tab,, SysTabControl321
	If (activeTab == 2)
		SetTimer, ProcessList, %memoryScanInterval%
	Else
	{
		If (firstRun != 1)
			SetTimer, ProcessList, Off
		GoSub, BookmarksList
	}
Return
	;}
	;{ Tab #1: gLabels of [Tree/List]Views.
		;{ FolderTree
FolderTree:	; TreeView's G-label that should trigger ListView update.
	Gui, TreeView, FolderTree
	Global activeControl := A_ThisLabel
	SetTimer, ProcessList, Off
	; Otherwise, populate the ListView with the contents of the selected folder.
	If (A_GuiEvent == "S") || (updateList == 1)	; If user selected a tree item.
	{
		updateList := ""
		TV_GetText(selectedItemText, A_EventInfo)	; Determine the full path of the selected folder:
		ParentID := A_EventInfo
		If ParentID
			savedParentID := ParentID
		ParentID := ((A_EventInfo) ? (A_EventInfo) : (savedParentID))
		Loop	; Build the full path to the selected folder.
		{
			ParentID := TV_GetParent(ParentID)
			If !ParentID	; No more ancestors.
				Break
			TV_GetText(ParentText, ParentID)
			SelectedItemText = %ParentText%\%selectedItemText%
		}
		selectedFullPath := startFolder "\" selectedItemText
		Gui, ListView, FileList	; Put the files into the ListView:
		LV_Delete()	; Delete old data.
		GuiControl, -Redraw, FileList	; Improve performance by disabling redrawing during load.
		FileCount := TotalSize := 0	; Init prior to loop below.
		Loop %selectedFullPath%\*.ahk	; This omits folders and shows only .ahk-files in the ListView.
		{
			FormatTime, created, %A_LoopFileTimeCreated%, dd.MM.yyyy (HH:mm:ss)
			FormatTime, modified, %A_LoopFileTimeModified%, dd.MM.yyyy (HH:mm:ss)
			LV_Add("", A_LoopFileName, A_LoopFileSize, created, modified)
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
	Global activeControl := A_ThisLabel
	SetTimer, ProcessList, Off
Return
		;}
		;{ BookmarksList
BookmarksList:
	Global activeControl := A_ThisLabel
	SetTimer, ProcessList, Off
	If !(updateList == 1) || If !FileExist("Settings.ini")	; Don't redraw the 'BookmarksList' ListView's contents if we don't have a pass key or we don't have any bookmarks file yet.
		Return
	; Show a list of bookmarked scripts and thier data.
	A_IndexMy := nBookmarks := bookmarks := updateList := ""
	GuiControl, -Redraw, BookmarksList	; Improve performance by disabling redrawing during load.
	Gui, ListView, BookmarksList
	LV_Delete()	; Clear all rows.
	IniRead, bookmarks, Settings.ini, Bookmarks, list
	If bookmarks
	{
		Loop ; Remove double pipes.
		{
			IfInString, bookmarks, ||
			{
				bookmarksModified := 1
				StringReplace, bookmarks, bookmarks, ||, |, All
			}
			Else
				Break
		}
		StringSplit, bookmarks, bookmarks, |
		While (A_IndexMy < bookmarks0)
		{
			A_IndexMy++
			thisBookmark := bookmarks%A_IndexMy%
			IfExist, %thisBookmark%	; Define whether the previously bookmared file exists.
			{	; If the file exists - display it in the list.
				SplitPath, thisBookmark, name	; Get file's name from it's path.
				FileGetSize, size, %thisBookmark%, K	; Get file's size.
				FileGetTime, created, %thisBookmark%, C	; Get file's creation date.
				FormatTime, created, %created%, dd.MM.yyyy (HH:mm:ss)	; Transofrm creation date into a readable format.
				FileGetTime, modified, %thisBookmark%	; Get file's last modification date.
				FormatTime, modified, %modified%, dd.MM.yyyy (HH:mm:ss)	; Transofrm creation date into a readable format.
				LV_Insert(A_IndexMy, "", A_IndexMy, name, thisBookmark, size " KB", created, modified)	; Add the listitem.
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
	{
		If bookmarksToDelete
		{
			Loop, Parse, bookmarks, |
				If (!RegExMatch(bookmarksToDelete, "\b" A_Index "\b"))
					nBookmarks .= (StrLen(nBookmarks) ? "|" : "") A_LoopField
			bookmarks := nBookmarks
		}
		StringReplace, bookmarks, bookmarks, ||, |, All
		IniWrite, %bookmarks%, Settings.ini, Bookmarks, list
		bookmarksToDelete := bookmarksModified := ""
	}
	GuiControl, +Redraw, BookmarksList
	If (deleteBookmarks == 1)
	{
		deleteBookmarks := ""
		updateList := 1
		GoSub, BookmarksList
	}
Return
		;}
	;}
	;{ Tab #1: gLabels of buttons.
RunSelected:
	If (activeControl == "FileList")
	{
		Gui, ListView, FileList
		selected := selectedFullPath "\" getScriptsNamesOfSelectedFiles(getSelectedRowsNumbers())
		StringReplace, selected, selected, |, |%selectedFullPath%\
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
	IfNotExist, Settings.ini
		FileAppend, [Settings]`n`n[Bookmarks]`n, Settings.ini, UTF-16
	selected := getScriptsNamesOfSelectedFiles(getSelectedRowsNumbers())
	IniRead, bookmarks, Settings.ini, Bookmarks, list
	selected := selectedFullPath "\" selected
	StringReplace, selected, selected, |, |%selectedFullPath%\
	If bookmarks
		bookmarks .= "|" . selected
	Else
		bookmarks .= selected
	IniWrite, %bookmarks%, Settings.ini, Bookmarks, list
	updateList := 1
	GoSub, BookmarksList
Return

DeleteSelected:
	If !(activeControl == "ProcessList")
		Gui, ListView, %activeControl%
	If (activeControl == "BookmarksList")
	{
		bookmarksToDelete := getSelectedRowsNumbers()
		deleteBookmarks := updateList := bookmarksModified := 1
		GoSub, %activeControl%
	}
	Else If (activeControl == "FolderTree")
	{
		
	}
	Else If (activeControl == "FileList")
	{
		
	}
Return
	;}
	;{ Tab #2: gLabels of ListView.
ProcessList:
	Global activeControl := A_ThisLabel
	If listIndex	; If we previously retrieved data at least once.
	{	; Backing up old data for later comparison.
		; Global scriptNameArrayOld := scriptNameArray
		Global pidArrayOld := pidArray
		; Global scriptPathArrayOld := scriptPathArray
	}
	
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
Kill:
	Gui, ListView, ProcessList
	kill(getPIDsOfSelectedRows())
Return

KillNreload:
	Gui, ListView, ProcessList
	killNreload(getPIDsOfSelectedRows())
Return

Restart:
	Gui, ListView, ProcessList
	restart(getPIDsOfSelectedRows())
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

F5::
	ControlGet, activeTab, Tab,, SysTabControl321
; msgbox activeTab: '%activeTab%'`nactiveControl: '%activeControl%'
	If (activeTab == 1)
	{
		updateList := 1
		If (activeControl == "BookmarksList") || (activeControl == "FolderTree")
			GoSub, %activeControl%
		Else
			GoSub, FolderTree
	}
	Else
		Gosub, ProcessList
Return

Delete::
; Msgbox A_Gui: '%A_Gui%'`nA_GuiControl: '%A_GuiControl%'`nA_GuiEvent: '%A_GuiEvent%'`nA_GuiControlEvent: '%A_GuiControlEvent%'`nA_EventInfo: '%A_EventInfo%'
	ControlGet, activeTab, Tab,, SysTabControl321
	If (activeTab == 1)
		GoSub, DeleteSelected
	Else If (activeTab == 2)
		Gosub, Kill
Return

Esc::
	ControlGet, activeTab, Tab,, SysTabControl321
	If (activeTab == 1) || (activeControl == "FolderTree")
	{
		updateList := 1	
		GoSub, %activeControl%
	}
Return

#IfWinActive
;}
;{ FUNCTIONS
	;{ Functions to gather data.
getSelectedRowsNumbers()	; Usable by all ListViews.
{
	Loop, % LV_GetCount("Selected")
	{
		If !RowNumber
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
	;{ Functions of process control
run(pathOrPathsSeparatedByPipes)
{
	Loop, Parse, pathOrPathsSeparatedByPipes, |
		Run, % """" A_AhkPath """ """ A_LoopField """"
}

kill(pidOrPIDsSeparatedByPipes)	; Accepts a PID or a bunch of PIDs separated by pipes ("|").
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		Process, Close, % A_LoopField
	NoTrayOrphans()
}

killNreload(pidOrPIDsSeparatedByPipes)
{
	scriptsPaths := getScriptsPathsOfSelectedProcesses(pidOrPIDsSeparatedByPipes)
	kill(pidOrPIDsSeparatedByPipes)
	NoTrayOrphans()
	Loop, Parse, scriptsPaths, |
		Run, % """" A_AhkPath """ """ A_LoopField """"
}

restart(pidOrPIDsSeparatedByPipes)
{
	scriptsPaths := getScriptsPathsOfSelectedProcesses(pidOrPIDsSeparatedByPipes)
	; Loop, Parse, scriptsPaths, |
	; 	Run, % """" A_AhkPath """ /restart """ A_LoopField """"
	run(scriptsPaths)
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
	;{ NoTrayOrphans() - a function to remove tray icons of dead processes.
NoTrayOrphans()	
{
	TrayInfo:= TrayIcons(sExeName,"ahk_class Shell_TrayWnd","ToolbarWindow32" . GetTrayBar()) "`n"
		. TrayIcons(sExeName,"ahk_class NotifyIconOverflowWindow","ToolbarWindow321")
	Loop, Parse, TrayInfo, `n
	{
		ProcessName:= StrX(A_Loopfield, "| Process: ", " |")
		ProcesshWnd:= StrX(A_Loopfield, "| hWnd: ", " |")
		ProcessuID := StrX(A_Loopfield, "| uID: ", " |")
		If !ProcessName && ProcesshWnd
			RemoveTrayIcon(ProcesshWnd, ProcessuID)
	}
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
		If Not hWnd
			Break
		Else If	hWnd = %hChild%
		{
			idxTB := A_Index
			Break
		}
	}
	Return	idxTB
}

StrX(H, BS = "", ES = "", Tr = 1, ByRef OS = 1)
{
	Return (SP := InStr(H, BS, 0, OS)) && (L := InStr(H, ES, 0, SP + StrLen(BS))) && (OS := L + StrLen(ES)) ? SubStr(H, SP := Tr ? SP + StrLen(BS) : SP, (Tr ? L : L + StrLen(ES)) -SP) : ""
}
	;}
;}