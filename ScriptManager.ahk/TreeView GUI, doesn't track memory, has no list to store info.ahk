; Title: Script Manager Full v.2.2 (Designd for Multiple folders)
; AutoHotkey Version: 1.x
; Language: English
; Platform: WINXP
; Author: asred
; Modified by: Drugoy
; Thanks to: comvox for help with getting the working directory to display properly

#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows On ; Allows a script's hidden main window to be detected.
SetTitleMatchMode 2 ; Avoids the need to specify the full path of the file below.

Menu, Tray, NoStandard
Menu, Tray, Add, Script Manager, GuiShow
Menu, Tray, Default, Script Manager
Menu, Tray, Add
Menu, Tray, Standard

; **************************** READ ME ****************************
; RESOURCE: http://www.autohotkey.com/docs/commands/TreeView.htm < base code was retrieved from the example
; The following is a working script that is more elaborate than Script Manager Lite.
; It creates and displays a TreeView containing all folders in the working directory. When one
; selects a folder, its contents are shown in a ListView to the right (like Windows Explorer).
; In addition, a StatusBar control shows information about the currently selected folder.
; **************************** READ ME END ****************************

; **************************** Begin Script ****************************
; The following folder will be the root folder for the TreeView. Note that loading might take a long
; time if an entire drive such as C:\ is specified:
TreeRoot = %A_WorkingDir%
TreeViewWidth := 250
ListViewWidth := 250

; The following code for gui-resize works to resize the listvew, but I was unable to get it to properly resize the treeview without some issues. Enable it and the GuiSize subroutine further down the pae and you will see. Post your solution to the forum if you do get it to work! Have fun.
; Allow the user to maximize or drag-resize the window:
; Gui +Resize	; Drugmix: Buggy.

; Create an ImageList and put some standard system icons into it: Folder icons
ImageListID := IL_Create(5)
Loop 5 ; Below omits the DLL's path so that it works on Windows 9x too:
	IL_Add(ImageListID, "shell32.dll", A_Index)

; Create a TreeView and a ListView side-by-side to behave like Windows Explorer:
Gui, Add, TreeView, vMyTree r25 gMyTree w%TreeViewWidth% ImageList%ImageListID%
Gui, Add, ListView, vMyListView gDoubleClickLaunch w%ListViewWidth% x+10 h404, Directory Contents

Gui, Add, Button, xs gButtonLaunch Default, Launch
Gui, Add, Button, X+0 gButtonReload, Reload
Gui, Add, Button, X+0 gButtonEdit, Edit
Gui, Add, Button, X+0 gButtonstop, Stop
Gui, Add, Button, X+0 gButtonNew, New Script
Gui, Add, Button, X+0 gButtonDelete, Delete
Gui, Add, Button, X+0 gButtonProperties, Properties
Gui, Add, Button, X+0 gButtonNuke, Kill All Running Scripts
Gui, Add, Button, xs gButtonWinSpy, Window Spy
Gui, Add, Button, X+0 gButtonSMHelp, SM Help
Gui, Add, Button, X+0 gButtonAHKHelp, AutoHotkey Help


; File menu
Menu, FileMenu, Add, &New Script, ButtonNew
Menu, FileMenu, Add, &Launch , ButtonLaunch
Menu, FileMenu, Add, &Reload, ButtonReload
Menu, FileMenu, Add, &Edit, ButtonEdit
Menu, FileMenu, Add, &Stop, Buttonstop
Menu, FileMenu, Add, &Delete, ButtonDelete
Menu, FileMenu, Add, &Properties, ButtonProperties
Menu, MyContextMenu, Add	; Separator
Menu, FileMenu, Add, &Create Shortcut in Startup Folder, ButtonCoypToStartUp
Menu, FileMenu, Add, &Open Startup Folder, ButtonOpenStartup

Menu, ToolsMenu, Add, &Kill All Running Scripts, ButtonNuke
Menu, MyContextMenu, Add	; Separator
Menu, ToolsMenu, Add, &Open Current Directory, ButtonWorkingDir
Menu, ToolsMenu, Add, &Windows Spy, ButtonWinSpy


Menu, HelpMenu, Add, &Script Manager Help, ButtonSMHelp
Menu, HelpMenu, Add, &AutoHotkey User Guide, ButtonAHKHelp
Menu, HelpMenu, Add, &Reload Script Manager, ButtonReloadSM


Menu, MyMenuBar, Add, &File, :FileMenu ; Attach the above FileMenu sub-menus that were created above.
Menu, MyMenuBar, Add, &Tools, :ToolsMenu ; Attach the above HelpMenu sub-menus that were created above.
Menu, MyMenuBar, Add, &Help, :HelpMenu ; Attach the above HelpMenu sub-menus that were created above.
Gui, Menu, MyMenuBar


; Right ClickContext Menu
Menu, MyContextMenu, Add, New Script, ButtonNew
Menu, MyContextMenu, Add, Launch, ButtonLaunch
Menu, MyContextMenu, Add, Reload, ButtonReload
Menu, MyContextMenu, Add, Edit, ButtonEdit
Menu, MyContextMenu, Add, Stop, Buttonstop
Menu, MyContextMenu, Add, Delete, ButtonDelete
Menu, MyContextMenu, Add, Properties, ButtonProperties
Menu, MyContextMenu, Add	; Separator
Menu, MyContextMenu, Add, Create Shortcut in Startup Folder, ButtonCoypToStartUp
Menu, MyContextMenu, Add, Open Startup Folder, ButtonOpenStartup
Menu, MyContextMenu, Add	; Separator
Menu, MyContextMenu, Add, Kill All Running Scripts, ButtonNuke
Menu, MyContextMenu, Add, Open Current Directory, ButtonWorkingDir
Menu, MyContextMenu, Add, Window Spy, ButtonWinSpy
Menu, MyContextMenu, Add	; Separator
Menu, MyContextMenu, Add, Script Manager Help, ButtonSMHelp
Menu, MyContextMenu, Add, AutoHotkey User Guide, ButtonAHKHelp
Menu, MyContextMenu, Default, Launch ; Make "Open" a bold font to indicate that double-click does the same thing.


; Set the ListView's column (this is optional):
LV_ModifyCol(1, %CharCount%) ; Auto-size each column to fit its contents.
LV_Modify(1, "Focus") ; When the Script Manager runs for the first time, the first row item is selected by default
LV_Modify(1, "Select") ; When the Script Manager runs for the first time, the first row item is highlighted by default
LV_Modify(RowNumber, "Vis") ; Ensures that the specified row is completely visible by scrolling the ListView, if necessary.

; Create a Status Bar to give info about the number of files and their total size:
Gui, Add, StatusBar
SB_SetParts(60, 85) ; Create three parts in the bar (the third part fills all the remaining width).
; Add folders and their subfolders to the tree. Display the status in case loading takes a long time:
; SplashTextOn, 200, 25, TreeView and StatusBar Example, Loading the tree...
ShortName(LongName)
{
	SplitPath, LongName, ShortName
	If !ShortName	; Otherwise if LongName is a root directory, then ShortName will be empty
		ShortName := LongName
	Return ShortName
}
Name := ShortName(A_WorkingDir)
AddSubFoldersToTree(TreeRoot,TV_Add("", ParentItemID, "Icon4"))
FirstItemID := TV_GetNext()
TV_Modify(FirstItemID, "", Name)
; SplashTextOff
SplitPath, A_AhkPath,, ahkDir
Return

GuiShow:
	; Display the window and return. The OS will notify the script whenever the user performs an eligible action:
	Gui, Show,, Script Manager ; Display the source directory (TreeRoot) in the title bar.
	Send {Right} ; Unfolds the top element of the tree
Return

TV_Add("",ParentItemId, "Icon4")

AddSubFoldersToTree(Folder, ParentItemID = 0)
{
	; This function adds to the TreeView all subfolders in the specified folder.
	; It also calls itself recursively to gather nested folders to any depth.
	Loop %Folder%\*.*, 2 ; Retrieve all of Folder's sub-folders.
	AddSubFoldersToTree(A_LoopFileFullPath, TV_Add(A_LoopFileName, ParentItemID, "Icon4" Expand))
}

MyTree: ; This subroutine handles user actions (such as clicking).
	If (A_GuiEvent <> S) ; i.e. an event other than "select new tree item".
		Return ; Do nothing.
	; Otherwise, populate the ListView with the contents of the selected folder.
	; First determine the full path of the selected folder:
	TV_GetText(SelectedItemText, A_EventInfo)
	ParentID := A_EventInfo
	If (ParentID == %FirstItemID%)
		SelectedFullPath == %TreeRoot%
	Else
	{
		Loop ; Build the full path to the selected folder.
		{
			ParentID := TV_GetParent(ParentID)
			If (ParentID == %FirstItemID%)
				Break
			TV_GetText(ParentText, ParentID)
			SelectedItemText == %ParentText%\%SelectedItemText%
		}
		SelectedFullPath == %TreeRoot%\%SelectedItemText%
	}
	
	; Put the files into the ListView:
	LV_Delete() ; Clear all rows.
	GuiControl, -Redraw, MyListView	; Improve performance by disabling redrawing during load.
	FileCount == 0 ; Init prior to loop below.
	TotalSize == 0
	; For simplicity, this omits folders so that only files are shown in the ListView.
	; Loop %SelectedFullPath%\*.* ; Uncomment this line and comment out the next to make the listview show all files in the sleceted folder
	Loop %SelectedFullPath%\*.ahk
	{
		LV_Add("", A_LoopFileName, A_LoopFileTimeModified)
		FileCount++
		TotalSize += A_LoopFileSize
	}
	GuiControl, +Redraw, MyListView
	
	; Update the three parts of the status bar to show info about the currently selected folder:
	SB_SetText(FileCount . " files", 1)
	SB_SetText(Round(TotalSize / 1024, 1) . " KB", 2)
	SB_SetText(SelectedFullPath, 3)


	; The following code works to resize the listvew, but I was unable to get it to properly resize the treeview without some issues. Enable it and you will see. Post your solution to the forum if you do get it to work! Have fun.
	; GuiSize: ; Expand/shrink the ListView and TreeView in response to user's resizing of window.
	; If A_EventInfo = 1 ; The window has been minimized. No action needed.
	;	Return
	; Otherwise, the window has been resized or maximized. Resize the controls to match.
	; GuiControl, Move, MyListView, % "H" . (A_GuiHeight - 30) ; -30 for StatusBar and margins.
	; GuiControl, Move, MyListView, % "H" . (A_GuiHeight - 30) . " W" . (A_GuiWidth - TreeViewWidth - 30)
	; Return

	;_________________________________Gui Button Subroutines

	DoubleClickLaunch:
		If (A_GuiEvent == DoubleClick)
		{
			Gosub, GetFileName
			Gosub, CheckSelect
			; MsgBox, 262148,, Would you you like to launch the following script?`n`n%A_WorkingDir%\%FileName%
			; IfMsgBox, No
			; 	Return
			; Otherwise, try to reload it:
			Gosub, LaunchFileName
		}
Return

ButtonNew:
	FileNumber == ""	; Zero out the file number variable
	IfExist, %SelectedFullPath%\NewAutoHotkeyScript.ahk
		Loop
		{
			FileNumber = %A_Index%
			IfNotExist %SelectedFullPath%\NewAutoHotkeyScript%FileNumber%.ahk
				Break
		}
	InputBox, NewFileName, Script Manager, Enter a name for your new script. No need for an extention `n".ahk" will be added automatically `n`n Location: %SelectedFullPath%,, Width 400, Height 200,,,,, NewAutoHotkeyScript%FileNumber%
	If ErrorLevel
		Return
	Else
	{
		FileAppend, ; The following file append method uses a continuation section to enhance readability and maintainability:
		(
		; AutoHotkey Version: 1.x
		; Language: English
		; Platform: WINXP
		; Author:
		;
		;
		#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
		SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
		SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
		DetectHiddenWindows On ; Allows a script's hidden main window to be detected.
		SetTitleMatchMode 2 ; Avoids the need to specify the full path of the file below.
		
		
		; **************************** READ ME ****************************
		; RESOURCE:
		; DESCRIPTION:
		; **************************** READ ME END ****************************
		
		; **************************** BEGIN SCRIPT ****************************
		), %SelectedFullPath%\%NewFileName%.ahk
		Run, Notepad.exe %SelectedFullPath%\%NewFileName%.ahk
	}
	Gosub, ReloadListView ;Reloading the listview is needed to show your new script
Return

ButtonReloadSM:
	Reload
Return

ButtonLaunch:
	Gosub,GetFileName
	Gosub,CheckSelect
	; MsgBox, 262148,, Would you you like to launch the following script?`n`n%A_WorkingDir%\%FileName%
	; IfMsgBox, No
	; 	Return
	; Otherwise, try to reload it:
	Gosub,LaunchFileName
Return

ButtonDelete:
	Gosub,GetFileName
	Gosub,CheckSelect
	; MsgBox, 262148, , Would you you like to edit the following script?`n`n%A_WorkingDir%\%FileName%
	; IfMsgBox, No
	; 	Return
	; Otherwise, try to open the file in notepad:
	FileDelete, %SelectedFullPath%\%FileName%
	Gosub, ReloadListView
Return

ButtonReload:
	Gosub,GetFileName
	Gosub,CheckSelect
	; MsgBox, 262148,, Are you sure you want to reload the following script?`n`n%A_WorkingDir%\%FileName%
	; IfMsgBox, No
	; 	Return
	; Otherwise, try to reload it:
	Gosub,ReloadFileName
Return



Buttonstop:
	Gosub,GetFileName
	Gosub,CheckSelect
	; MsgBox, 262148, , Would you you like to stop the following script?`n`n%A_WorkingDir%\%FileName%
	; IfMsgBox, No
	; 	Return
	; Otherwise, try to kill it:
	Gosub,KillFileName
Return


ButtonEdit:
	Gosub,GetFileName
	Gosub,CheckSelect
	; MsgBox, 262148, , Would you you like to edit the following script?`n`n%A_WorkingDir%\%FileName%
	; IfMsgBox, No
	; 	Return
	; Otherwise, try to open the file in notepad:
	Run, Notepad.exe %SelectedFullPath%\%FileName%
Return


ButtonProperties: ; The user selected "Properties" in the context menu.
	FocusedRowNumber := LV_GetNext(0, "F") ; For simplicitly, operate upon only the focused row rather than all selected rows. This command locates the focused row.
	If !FocusedRowNumber	; No row is focused.
		Return
	LV_GetText(FileName, FocusedRowNumber, 1) ; Get the text of the first field.
	LV_GetText(FileDir, FocusedRowNumber, 2) ; Get the text of the second field.
	IfInString A_ThisMenuItem, Open ; User selected "Open" from the context menu.
		Run %SelectedFullPath%\%FileName%,, UseErrorLevel
	Else ; User selected "Properties" from the context menu.
		Run Properties "%SelectedFullPath%\%FileName%",, UseErrorLevel
	If ErrorLevel
		MsgBox The requested action on the following file failed. `n`n%SelectedFullPath%\%FileName%
Return


ButtonNuke:
	MsgBox, 262148, , Are you sure you want to kill all running AutoHotkey scripts? `n`n Note: This will not Stop Script Manager, only running processes that belong to the AutoHoykey class (i.e. have an .ahk extension).
	IfMsgBox, No
		Return
	; Otherwise...
	Progress,, Stopping all scripts...,, Autohotkey Script Manager
	Progress, 100
	Sleep 1050
	Progress, Off
	Loop, 20
	{
		IfWinExist, .ahk ahk_class AutoHotkey
		{
			WinActivate,
			WinGetTitle, Title, A
			Progress,, Stopping script: %Title%,, Autohotkey Script Manager
			Progress, 100
			WinKill, %Title%
		}
		Else
		{
			Progress, Off
			Msgbox, 262144, Script Mananager, All scripts have been closed., 2
			Return
		}
	}
	Progress, Off
	Msgbox, 262144, Script Mananager, All scripts have been closed2., 2
Return


ButtonSMHelp:
	MsgBox, 262144, Scrip Manager Help, Manage all your scripts in one simple app`n`nScript Manager displays whatever Autohotkey scripts are located in the child directory it lives in (e.g. if one's scripts are in D:\MyDocs\Scripts, then ScriptManager should be located in D:\MyDocs). `n`nThe purpose of this program is to give you more control over your Autohotkey scripts. Select a script from the list and choose a command from the buttons below the list view or by using the right click context menu.`n`nTo actively view what scripts are running, check out the Autohotkey icons in your system tray. Hover your mouse over any of the Autohotkey icons for the script's name. Right click on the icon for a context menu to control the script.`n`nIf you have an interest in modifying a script and want to know how, open the AutoHotkey user guide from the Help menu. Making your own scripts is easier than you think.
Return


ButtonWinSpy:
	Run %ahkDir%\AU3_Spy.exe
Return

ButtonAHKHelp:
	Run %ahkDir%\AutoHotkey.chm
Return

; GuiClose: ; When the "X" button is clicked. . .
; GuiEscape: ; When the "Esc" key is hit . . .
; ExitApp


;___________________Master SUBROUTINES

ReloadListView:
	LV_Delete() ; Clear all rows.
	GuiControl, -Redraw, MyListView ; Improve performance by disabling redrawing during load.
	FileCount = 0 ; Init prior to loop below.
	TotalSize = 0
	Loop %SelectedFullPath%\*.ahk ; For simplicity, this omits folders so that only files are shown in the ListView.
	{
		LV_Add("", A_LoopFileName, A_LoopFileTimeModified)
		FileCount++
		TotalSize += A_LoopFileSize
	}
	GuiControl, +Redraw, MyListView
Return

CheckSelect:
RowNumber = 0 ; This causes the first loop iteration to start the search at the top of the list.
Loop
{
	RowNumber := LV_GetNext(RowNumber, Focus) ; Resume the search at the row after that found by the previous iteration.
	If !RowNumber ; The above returned zero, so there are no more selected rows.
		Break
	Else
		Return
}
Exit

GetFileName:
	FocusedRowNumber := LV_GetNext(0, "F") ; Find the focused row.
	If !FocusedRowNumber ; No row is focused.
		Return
	LV_GetText(FileName, FocusedRowNumber, 1) ;Get the file name from the focused row.
	; MsgBox %SelectedFullPath%`n File:%FileName% `n Row:%FocusedRowNumber% ; Show what file and row is selected
Return

LaunchFileName:
	Progress,, Starting script %FileName%,, Autohotkey Script Manager
	Progress, 100
	Sleep 350
	Run %SelectedFullPath%\%FileName%,, UseErrorLevel
	If (ErrorLevel == ERROR)
		MsgBox Well that didn't work. The following script would not start no matter how many times I tried to launch it.`n`n%SelectedFullPath%\%FileName%
	Progress, Off
Return

ReloadFileName:
	IfWinNotExist %FileName%
		Msgbox, 262144,, That Script isn't running. Launching script. . .,1
	IfWinExist %FileName%
		GoSub, KillFileName
	Progress,, Starting script %FileName%,, Autohotkey Script Manager
	Progress, 100
	Sleep 350
	Run %SelectedFullPath%\%FileName%,, UseErrorLevel
	If (ErrorLevel == ERROR)
		MsgBox Well that didn't work. The following script would not start no matter how many times I tried to launch it.`n`n%SelectedFullPath%\%FileName%
	Progress, Off
Return


KillFileName:
	IfWinExist %FileName%
	{
		WinKill %FileName%
		Progress,, Stopping script: %FileName%,, Autohotkey Script Manager
		Progress, 100
		Sleep 350
		Progress, Off
		IfWinExist %FileName% ; Error Catch, If the dumb script is still running after one attempt to stop it, try killing the script again before sending a error message
		{
			WinKill %FileName%
			IfWinExist %FileName%
				MsgBox, 262144,, Wow, that script doesn't want to die. I was unable to stop %FileName%. `n`nReason: unknown. `nTry ending the process with Windows task manager.
			Return
		}
		Else
			Return
	}
	Else
	MsgBox, 262144, ,I'm sorry you can't stop something you never started.`n`n %FileName% is not running. `n`nTo actively view what scripts are running, check out the Autohotkey icons in your system tray. Hover your mouse over any of the Autohotkey icons for the script's name. Right click on the icon for a context menu to control the script.
Return


;__________________________Right Click Context Menu

GuiContextMenu: ; Launched in response to a right-click or press of the Apps key.
	; Show the menu at the provided coordinates, A_GuiX and A_GuiY. These should be used
	; because they provide correct coordinates even if the user pressed the Apps key:
	Menu, MyContextMenu, Show, %A_GuiX%, %A_GuiY%
Return

ButtonWorkingDir:
	Run %SelectedFullPath%
Return

ButtonCoypToStartUp:
	Gosub,GetFileName
	Gosub,CheckSelect
	Progress,, Creating a shortcut…,,, Autohotkey Script Manager
	Progress, 100
	Sleep 350
	FileCreateShortcut, %SelectedFullPath%\%FileName%, %A_Startup%\%FileName%.lnk, %SelectedFullPath%, "%A_ScriptFullPath%", Shortcut to AutoHotKey script %FileName%
	Run %A_Startup%
	Progress, Off
Return

ButtonOpenStartup:
	Run %A_Startup%
Return
; **************************** End Script ****************************