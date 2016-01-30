/* descript.ion for Windows Explorer v0.2
Last time modified: 2016.01.28 18:50

Summary: this script let's you get files' comments.

Description: if any files are selected - the comments will be shown only for them, otherwise - for all files in the folder.
Comments get taken from the descript.ion file that should be present in the folder.

Usage:
1. Get TotalCommander (or alike), select a file there, hit Ctrl+Z, add some comments to the file. This will create a descript.ion (usually hidden) file in that folder.
2. Open the commented file's folder in Windows Explorer.
3. Run this script and hold F1 to get a traytip with comments either for all the files (if no files were selected) or only for the selected ones.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/descript.ion%20for%20Windows%20Explorer

To do:
1. Add handling of '.lnk' files.
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force
CoordMode, Mouse, Screen
#MaxThreadsPerHotkey, 1


#IfWinActive, ahk_exe explorer.exe
F1::
	currentFolderPath := Explorer_GetFolder()
	files := {}, htmlBody := ""
	files := getDescription(currentFolderPath, Explorer_GetFileNames())
	For k, v In files
		htmlBody .= "<b class=""name"">" v.name "</b>`n`t`t<div class=""description"">" v.description "`n`t`t</div>`n`t`t`n`t`t"
	htmlBody := RegExReplace(htmlBody, "Si)((https?://)([^\s/]+)\S*)", "<a href=""$1"">$2$3/…</a>")
	If htmlBody
	{
htmlPage =
(
<!DOCTYPE html>
<html>
	<head>
		<style>
			html, body
			{
				margin: 0;
				padding: 0;
				width: 100`%;
			}
			html
			{
				overflow: auto;
				height: 100`%;
				background-color: #DCE1E5;
			}
			body
			{
				width: auto;
				font-family: Sans-Serif;
				font-size: 10pt;
				border: 1px solid black;
			}
			.description
			{
				background-color: white;
				border: 1px solid #A9B8C2;
			}
			a:hover:after
			{
				content: ' > ' attr(href);
			}
		</style>
	</head>
	<body>
		%htmlBody%
	</body>
</html>
)
		Gui, New, +LastFound -Caption +AlwaysOnTop	; +ToolWindow
		Gui, Color, 123456
		WinSet, TransColor, 123456
		Gui, Margin, 0, 0
		Gui, Add, Button, gOpenDescription, Open descript.ion
		Gui, Add, ActiveX, vWB w600 h800 x0 y+0, mshtml:<meta http-equiv="X-UA-Compatible" content="IE=Edge">
		ControlFocus, AtlAxWin1	; Otherwise the html element will not be scrollable until clicked.
		WB.Write(htmlPage)
		WB.Close()
		Gui, Show, % "h" (WB.body.offsetHeight < 800 ? "" WB.body.offsetHeight + 23 : "800")
		KeyWait, %A_ThisHotkey%
		Gui, Destroy
	}
	KeyWait, %A_ThisHotkey%
Return
#IfWinActive

OpenDescription:
	IfExist, %currentFolderPath%\descript.ion
		Run, %currentFolderPath%\descript.ion
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

;{ Explorer_GetFileNames()	- returns selected (or all, if none were selected) files' names.
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
;}
;{ getDescription(folder, files)	- returns an associative array with files as items, each item is an associative array of file name and file description.
getDescription(folder, files)
{
	IfExist, % folder "/descript.ion"
	{
		FileEncoding, cp1251
		FileRead, descriptionStr, % folder "/descript.ion"
		If descriptionStr
		{
			describedFiles := {}
			Loop, Parse, descriptionStr, `n, `r
			{
				If !(A_LoopField)	; Skip empty lines (like the last one).
					Continue
				name := part1 := part2 := part3 := ""
				RegExMatch(A_LoopField, "Si)^(?:""(.+)""|(\S+?))\s(.*)$", part)
				StringReplace, part3, part3, \n, `n, All	; '\n' represent new lines, so converting them back.
				StringReplace, part3, part3, В,, All	; 'В' is usually at the end of the line if description contained at least one '\n'.
				StringReplace, part3, part3, `n, `n`t`t<br/>`n`t`t, All
				For k, v In files
					If (v == (name := (part1 ? part1 : part2)))	; Get description only of the files we need (of selected (if exist) or otherwise of all.)
						describedFiles[name] := ({"name": name, "description": part3})
			}
			Return describedFiles
		}
	}
}
;}