/* descript.ion for Windows Explorer v0.1
Last time modified: 2015.09.22 18:30

Summary: this script let's you get files' comments.

Description: if any files are selected - the comments will be shown only for them, otherwise - for all files in the folder.
Comments get taken from the descript.ion file that should be present in the folder.

Usage:
1. Get TotalCommander (or alike), select a file there, hit Ctrl+Z, add some comments to the file. This will create a descript.ion (usually hidden) file in that folder.
2. Open the commented file's folder in Windows Explorer.
3. Run this script and either hold F1 to get a traytip with comments for all the files in that folder or select the necessary files first and then get comments only to the selected files.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/DrugWinManager

To do:
1. Add handling of '.lnk' files.
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force

F1::
	description := getDescription(Explorer_GetFolder(), Explorer_GetFileNames())
	tooltipText := ""
	For k, v In description
		tooltipText .= v.name ":`n`t" v.description "`n"
	If tooltipText
	{
		ToolTip, % tooltipText
		While GetKeyState(A_ThisHotkey, "P")
			Sleep, 30
		ToolTip
	}
Return

Explorer_GetFolder()
{
	If !(window := Explorer_GetWindow())
		Return ErrorLevel := "ERROR"
	If (window = "desktop")
		Return A_Desktop
	path := window.LocationURL
	path := RegExReplace(path, "ftp://.*@","ftp://")
	StringReplace, path, path, file:///
	StringReplace, path, path, /, \, All 
	While RegExMatch(path, "i)(?<=%)[\da-f]{1,2}", hex)
		StringReplace, path, path, `%%hex%, % Chr("0x" hex), All
	Return path
}

Explorer_GetWindow()
{
	WinGet, process, processName, % "ahk_id " hwnd := WinExist("A")
	WinGetClass, class, A
	If (process != "explorer.exe")
		Return ErrorLevel := "ERROR"
	If (class ~= "(Cabinet|Explore)WClass")
	{
		For window In ComObjCreate("Shell.Application").Windows
			If (window.hwnd == hwnd)
				Return window
	}
	Else If (class ~= "Progman|WorkerW") 
		Return "desktop" ; desktop found
}

Explorer_GetFileNames()
{
	fileNames := []
	If !(window := Explorer_GetWindow())
		Return ErrorLevel := "ERROR"
	If (window = "desktop")
	{
		ControlGet, activeWinHWND, HWND,, SysListView321, ahk_class Progman
		If !activeWinHWND ; #D mode
			ControlGet, activeWinHWND, HWND,, SysListView321, A
		ControlGet, files, List, % "Selected" "Col1",, ahk_id %activeWinHWND%
		If !files	; If none are selected - get the list of all files.
			ControlGet, files, List, "Col1",, ahk_id %activeWinHWND%
		folder := SubStr(A_Desktop, 0, 1) == "\" ? SubStr(A_Desktop, 1, -1) : A_Desktop
		Loop, Parse, files, `n, `r
		{
			path := folder "\" A_LoopField
			IfExist %path% ; ignore special icons like Computer (at least for now)	; FIXME: fails on "*.lnk" files.
				fileNames.Insert(A_LoopField)
		}
	}
	Else
	{
		items := window.document.SelectedItems
		If !items.item[0].name	; If none are selected - get the list of all files.
			items := window.document.Folder.Items
		For item In items	; https://msdn.microsoft.com/en-us/library/ms970456.aspx
			fileNames.Insert(item.name)
	}
	Return fileNames
}

getDescription(folder, files)
{
	IfExist, % folder "/descript.ion"
	{
		FileRead, descriptionStr, % folder "/descript.ion"
		If descriptionStr
		{
			description := {}
			Loop, Parse, descriptionStr, `n, `r
			{
				linePart1 := linePart2 := linePart3 := ""	; Make sure regexmatch's results will be correct.
				If A_LoopField	; Skip empty lines (like the last one).
				{
					RegExMatch(A_LoopField, "Si)^(?:""(.+)""|(\S+?))\s(.*)$", linePart)
					StringReplace, linePart3, linePart3, \n, `n, All
					StringReplace, linePart3, linePart3, В, `n, All
					For k, v In files
					{
						OutputDebug, % "filename from descript.ion: '" (linePart1 ? linePart1 : linePart2) "' " "filename from the list of selected files: '" linePart3 "' "
						If (v = (linePart1 ? linePart1 : linePart2))	; Get description only of the files we need (of selected (if exist) or otherwise of all.)
							description.Insert({"name": (linePart1 ? linePart1 : linePart2), "description": linePart3})
					}
				}
			}
		}
	}
	Return description
}