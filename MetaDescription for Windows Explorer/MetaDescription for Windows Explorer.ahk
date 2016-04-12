/* MetaDescription for Windows Explorer v0.2
Last time modified: 2016.04.13 02:15

Summary: this script let's you get files' comments.

Description: if any files are selected - the comments will be shown only for them, otherwise - for all files in the folder.
The file description gets stored right in the file in such a way that you shouldn't notice any difference.

Usage:
1. Select a file in Windows Explorer and hit Alt+F1 to set descriptions for files.
2. Select a file in Windows Explorer and hit F1 to show descriptions for the files. If none are selected - the whole folder will get scanned for files that have description.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/blob/master/MetaDescription%20for%20Windows%20Explorer/MetaDescription%20for%20Windows%20Explorer.ahk
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force
; #NoTrayIcon
CoordMode, Mouse, Screen
#MaxThreadsPerHotkey, 1
FileEncoding, UTF-8

Global dFiles

#IfWinActive, ahk_exe explorer.exe
F1::
	htmlBody := ""
	dFiles := getDescription()
	For k, v In dFiles
		htmlBody .= (A_Index == 1 ? "" : "`n") "`n`t`t<b class=""name"">`n`t`t`t" k "`n`t`t</b>`n`t`t<div class=""description"">`n`t`t`t" RegExReplace(RegExReplace(v, "Si)""""", """"), "Si)\n", "<br>") "`n`t`t</div>"
	; htmlBody := RegExReplace(htmlBody, "Si)((https?://)([^\s/]+)\S*)", "<a href=""$1"">$2$3/…</a>")
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
			.notfound
			{
				color: red;
			}
			a:hover:after
			{
				content: ' > ' attr(href);
			}
		</style>
	</head>
	<body>%htmlBody%
	</body>
</html>
)
		Gui, New, +LastFound -Caption +AlwaysOnTop +ToolWindow
		Gui, Color, 123456
		WinSet, TransColor, 123456
		Gui, Margin, 0, 0
		Gui, Add, ActiveX, vWB w600 h800 x0 y+0, mshtml:<meta http-equiv="X-UA-Compatible" content="IE=Edge">
		; ControlFocus, AtlAxWin1	; Otherwise the html element will not be scrollable until clicked.
		WB.Write(htmlPage)
		WB.Close()
		Gui, Show, % "h" (WB.body.offsetHeight < 800 ? "" WB.body.offsetHeight : "800")
		KeyWait, %A_ThisHotkey%
		Gui, Destroy
	}
	KeyWait, %A_ThisHotkey%
Return

!F1::	; Edit
	name := description := describedFile := ""
	selected := Explorer_GetFiles()
	If (selected.Length() == 1)	; Make it work only if 1 file was selected.
	{
		describedFile := getDescription()
		Gui, New, +LastFound +Border
		; Gui, Color, 123456
		; WinSet, TransColor, 123456
		Gui, Margin, 1, 1
		Gui, Add, Edit, +ReadOnly vname, % RegExReplace(selected[1], ".+\\(.+)", "$1")
		For k, v in (describedFile.GetCapacity() ? describedFile : {"":""})
			Gui, Add, Edit, Wrap y+0 w600 h400 +Multi vdescription, % StrReplace(v, """""", """")
		Gui, Add, Button, y+0 x547 gSave, Save
		ControlFocus, Edit2
		Gui, Show
	}
Return
#IfWinActive

Save:
	Gui, Submit
	setDescription(selected[1], description)
Return

GuiClose:
GuiEscape:
	Gui, Destroy
Return

;{ Functions
	;{ Explorer_GetWindow()
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
	;}
	;{ Explorer_GetFiles()	- returns selected (or all, if none were selected) files' names.
Explorer_GetFiles()
{
	files := []
	If !(window := Explorer_GetWindow())
		Return ErrorLevel := "ERROR"
	If (window = "desktop")
	{
		ControlGet, activeWinHWND, HWND,, SysListView321, ahk_class Progman
		If !activeWinHWND ; #D mode
			ControlGet, activeWinHWND, HWND,, SysListView321, A
		ControlGet, fileList, List, % "Selected" "Col1",, ahk_id %activeWinHWND%
		If !fileList
			ControlGet, fileList, List, % "Col1",, ahk_id %activeWinHWND%
		desktop := SubStr(A_Desktop, 0, 1) == "\" ? SubStr(A_Desktop, 1, -1) : A_Desktop
		Loop, Parse, fileList, `n, `r
			files.Insert(desktop "\" A_LoopField)
	}
	Else
	{
		items := window.document.SelectedItems
		If !items.item[0].name	; If none are selected - get the list of all files.
			items := window.document.Folder.Items
		For item In items	; https://msdn.microsoft.com/en-us/library/ms970456.aspx
			files.Insert(item.path)
	}
	Return files
}
	;}
	;{ getDescription(folder, filesFilter = 0)	- returns an associative array with files as items, each item is an associative array of file name and file description.
getDescription()
{
	files := Explorer_GetFiles()
	describedFiles := {}
	For k, v In files
	{
		FileRead, oneDescription, % v ":description"
		If oneDescription
			describedFiles[v] := oneDescription
	}
	Return describedFiles
}
	;}
	;{ setDescription(file, description)
setDescription(file, description)
{
	If (description)
		RunWait, % ComSpec " /c " comspecEscape(description) ">""" file ":description""",, Hide
	Else
		FileDelete, %file%:description
}
	;}
	;{ comspecEscape(input)
comspecEscape(input)
{
	output := input
	StringReplace, output, output, ", "", A	; Due to some internal bug in cmd.exe - it's impossible to escape a single double_quote char in 'set/p z="…"' construction. So we double all the double_quot chars there to make sure their total number is never odd. Later (when using F1/Alt+F1) we have to replace the doubled double_quote chars back to single double_quote char.
	StringReplace, output, output, `n, % """&echo.&<nul set/p z=""", A	; Makes proper handling of newline characters.
	output := "(<nul set/p z=""" output """)"	; "set/p=text" - prompt user input and sets ErrorLevel equal the text to the right; "<nul" - redirect prompted input from NUL, thus do not wait for user input.
	Return output
}
	;}
;}