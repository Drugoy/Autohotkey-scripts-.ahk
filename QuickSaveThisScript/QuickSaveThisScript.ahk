/* QuickSaveThisScript.ahk
Version: 0.1
Last time modified: 2015.09.14 20:42

Description: a script to quickly save selected text to an *.ahk file and open it in the editor.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/QuickSaveThisScript/QuickSaveThisScript.ahk
*/
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance, Force
SetKeyDelay, 50

;{ Settings
saveToFolder := ""	; Where to save scripts. If blank - the scripts will get saved next to this script.
;}

RegRead, editor, HKCR, AutoHotkeyScript\Shell\Edit\Command	; Get user's editor assigned for AutoHotkey scripts.
editor := StrReplace(editor, "%SystemDrive%", SystemDrive)
Return

^!vk43 Up::	; "Ctrl+Alt+c"	< this will also open a prompt for file name.
!vk43 Up::	; "Alt+c".
	;{ Make sure all the hotkey's keys got unpressed.
	If (A_ThisHotkey = "^!vk43 Up")
		While (GetKeyState("Ctrl", "P"))
			Sleep, 10
	While (GetKeyState("Alt", "P"))
		Sleep, 10
	;}
	savedClipboard := ClipboardAll	; Backup data from clipboard.
	Clipboard := ""
	While !Clipboard	; Try to copy selected (it may fail, and then we have to retry).
	{
		Send, {Ctrl Down}c{Ctrl Up}
		Sleep, 25
	}
	textToSave := Clipboard
	Clipboard := savedClipboard
	If (A_ThisHotkey = "^!vk43 Up")
	{
		InputBox, filename, Enter the name for the script's file:,,, 300, 100
		If ErrorLevel	; Flush the variable's contents in case user canceled or closed the input box.
			filename := ""
	}
	saveTofile := (saveToFolder ? saveToFolder : A_ScriptDir) "\" (filename ? filename : A_Now) ".ahk"
	FileAppend, %textToSave%, %saveTofile%, UTF-8	 ; Save selected into a file next to this script.
	Run, % (editor ? StrReplace(editor, "%1", """" saveTofile """") : notepad.exe  """" saveTofile """") 
	textToSave := filename := savedClipboard := saveTofile := ""	; Restore clipboard from backup and clean temporary variables.
Return