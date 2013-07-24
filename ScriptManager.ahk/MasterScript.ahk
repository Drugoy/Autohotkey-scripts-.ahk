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
; 	b. Separate GUI window:
; 		b1. Add TreeView GUI for bookmarks.
; 		b2. Think of improvements over ListView GUI for running scripts.
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
startFolder := "C:\Program Files\AutoHotkey"
;}

;{ GUI
	;{ Tray menu.
Menu, Tray, NoStandard
Menu, Tray, Add, Manage Scripts, GuiShow	; Create a tray menu's menuitem and bind it to a label that opens main window.
Menu, Tray, Default, Manage Scripts
Menu, Tray, Add
Menu, Tray, Standard
	;}
; Add tabbed interface
Gui, Add, Tab2, x0 y0 Choose1, Manage files|Manage processes
; { Create folder icons.
ImageListID := IL_Create(5)
Loop 5	; Below omits the DLL's path so that it works on Windows 9x too:
	IL_Add(ImageListID, "shell32.dll", A_Index)
; }
		;{ Tab #1: 'Manage files'
Gui, Tab, Manage files
Gui, Add, Text, x85 y27, Choose a folder:
Gui, Add, Button, x270 y21 gBookmarkSelected, Bookmark selected
Gui, Add, TreeView, AltSubmit x0 y+0 w269 h400 r20 +Resize gUpdateListView ImageList%ImageListID%	; Add TreeView for navigation in the FileSystem.
AddSubFoldersToTree(startFolder)

AddSubFoldersToTree(Folder, ParentItemID = 0)
{
    ; This function adds to the TreeView all subfolders in the specified folder.
    ; It also calls itself recursively to gather nested folders to any depth.
    Loop %Folder%\*.*, 2  ; Retrieve all of Folder's sub-folders.
        AddSubFoldersToTree(A_LoopFileFullPath, TV_Add(A_LoopFileName, ParentItemID, "Icon4"))
}
Gui, Add, ListView, x+0 w550 h400 r20 +Resize +Grid gMyListView, Name|Size (bytes)|Created|Modified
; UpdateListView:
	Loop, %startFolder%\*.ahk	; This should be replaced with smth like A_SelectedFolder (selected in TreeView).
	{
		FormatTime, LoopFiletimeCreated, %A_LoopFileTimeCreated%, HH:mm:ss dd.MM.yyyy
		FormatTime, LoopFileTimeModified, %A_LoopFileTimeModified%, HH:mm:ss dd.MM.yyyy
		LV_Add("", A_LoopFileName, A_LoopFileSize, LoopFiletimeCreated, LoopFileTimeModified)
	}
; Return
; Set the column sizes
LV_ModifyCol(1, "250")
LV_ModifyCol(2, "66")
LV_ModifyCol(3, "115")
LV_ModifyCol(4, "115")	
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
Gui, Add, ListView, x0 y+0 w720 h400 r20 +Resize +Grid gMyListView, #|pID|Name|Path

; Set the column sizes
LV_ModifyCol(1, "20")
LV_ModifyCol(2, "40")
LV_ModifyCol(3, "220")
LV_ModifyCol(4, "430")
		;}

GuiShow:
	Gui, +Resize +MinSize525x225
	Gui, Show, w1000 h700 Center, Manage Scripts
	GoSub, scanMemoryForAhkProcesses
	SetTimer, scanMemoryForAhkProcesses, %memoryScanInterval%
Return

GuiClose:
	Gui, Hide
	SetTimer, scanMemoryForAhkProcesses, Off
Return
	;{ G-Labels of buttons on the "Manage files" tab.
UpdateListView:	; TreeView's G-label that should trigger ListView update.
; GuiControlGet, FocusedControl, FocusV
; Msgbox A_Gui: '%A_Gui%'`nA_GuiControl: '%A_GuiControl%'`nA_GuiEvent: '%A_GuiEvent%'`nFocusedControl: '%FocusedControl%'
Return
BookmarkSelected:
Return
	;}
	;{ G-Labels of buttons on the "Manage processes" tab.
MyListView:
Return

#IfWinActive Manage Scripts ahk_class AutoHotkeyGUI
Delete::
#IfWinActive
Kill:
	kill(getPIDsOfSelectedRows())
Return

KillNreload:
	killNreload(getPIDsOfSelectedRows())
Return

Restart:
	restart(getPIDsOfSelectedRows())
Return

Pause:
	pause(getPIDsOfSelectedRows())
Return

SuspendHotkeys:
	suspendHotkeys(getPIDsOfSelectedRows())
Return

SuspendProcess:
	suspendProcess(getPIDsOfSelectedRows())
Return

ResumeProcess:
	resumeProcess(getPIDsOfSelectedRows())
Return
	;}
;}

;{ A subroutine to scan memory for running ahk scripts.
#IfWinActive Manage Scripts ahk_class AutoHotkeyGUI
F5::
scanMemoryForAhkProcesses:
	If listIndex	; If we previously retrieved data at least once.
	{	; Backing up old data for later comparison.
		Global scriptNameArrayOld := scriptNameArray
		Global pidArrayOld := pidArray
		Global scriptPathArrayOld := scriptPathArray
	}
	
	Global scriptNameArray := [], Global pidArray := [], Global scriptPathArray := []	; Defining and clearing arrays.
	listIndex := 0
	GuiControl, -Redraw, MyListView
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
	GuiControl, +Redraw, MyListView
	Return
#IfWinActive
;}

;{ Functions to control scripts.

getSelectedRowsNumbers()
{
	Loop, % LV_GetCount("Selected")
	{
		If !RowNumber
			selectedRowsNumbers := rowNumber := LV_GetNext(rowNumber)
		Else
			selectedRowsNumbers := selectedRowsNumbers "|" . rowNumber := LV_GetNext(rowNumber)
	}
	Return selectedRowsNumbers
}

getPIDsOfSelectedRows()	; That function outputs selected rows' process IDs as a string of PIDs separated by pipes.
{
	selectedRowsNumbers := getSelectedRowsNumbers()
	Loop, Parse, selectedRowsNumbers, |
	{
		LV_GetText(pidOfSelectedRow, A_LoopField, 2)	; Column #2 contains PIDs.
		selectedRowsPIDs ? (selectedRowsPIDs . "|" . pidOfSelectedRow) : (pidOfSelectedRow)
		If !selectedRowsPIDs
			selectedRowsPIDs := pidOfSelectedRow
		Else
			selectedRowsPIDs := selectedRowsPIDs . "|" . pidOfSelectedRow
	}
	Return selectedRowsPIDs
}

getScriptsPathsOfselectedRowsNumbers(selectedRowsNumbers)
{
	selectedRowsNumbers := getSelectedRowsNumbers()
	Loop, Parse, selectedRowsNumbers, |
	{
		If (A_Index == 1)
			selectedRowsScriptsPaths := scriptPathArrayOld[A_LoopField]
		Else
			selectedRowsScriptsPaths := selectedRowsScriptsPaths . "|" scriptPathArrayOld[A_LoopField]
	}
	Return selectedRowsScriptsPaths
}

kill(pidOrPIDsSeparatedByPipes)	; Accepts a PID or a bunch of PIDs separated by pipes ("|").
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		Process, Close, % A_LoopField
	GoSub, scanMemoryForAhkProcesses
	NoTrayOrphans()
}

killNreload(pidOrPIDsSeparatedByPipes)
{
	scriptsPaths := getScriptsPathsOfselectedRowsNumbers(pidOrPIDsSeparatedByPipes)
	kill(pidOrPIDsSeparatedByPipes)
	NoTrayOrphans()
	Loop, Parse, scriptsPaths, |
		Run, % """" A_AhkPath """ """ A_LoopField """"
	GoSub, scanMemoryForAhkProcesses
}

restart(pidOrPIDsSeparatedByPipes)
{
	scriptsPaths := getScriptsPathsOfselectedRowsNumbers(pidOrPIDsSeparatedByPipes)
	Loop, Parse, scriptsPaths, |
		Run, % """" A_AhkPath """ /restart """ A_LoopField """"
	GoSub, scanMemoryForAhkProcesses
}

pause(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		PostMessage, 0x111, 65403,,, ahk_pid %A_LoopField%
	GoSub, scanMemoryForAhkProcesses
}

suspendHotkeys(pidOrPIDsSeparatedByPipes)
{
	Loop, Parse, pidOrPIDsSeparatedByPipes, |
		PostMessage, 0x111, 65404,,, ahk_pid %A_LoopField%
	GoSub, scanMemoryForAhkProcesses
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
	GoSub, scanMemoryForAhkProcesses
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
	GoSub, scanMemoryForAhkProcesses
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
		Else If hWnd = %hChild%
		{
			idxTB := A_Index
			Break
		}
	}
	Return idxTB
}

StrX(H, BS = "", ES = "", Tr = 1, ByRef OS = 1)
{
	Return (SP := InStr(H, BS, 0, OS)) && (L := InStr(H, ES, 0, SP + StrLen(BS))) && (OS := L + StrLen(ES)) ? SubStr(H, SP := Tr ? SP + StrLen(BS) : SP, (Tr ? L : L + StrLen(ES)) -SP) : ""
}
;}