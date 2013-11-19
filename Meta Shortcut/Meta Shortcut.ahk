; 【 Multi Shortcuts List 】 【 v.2 】
;
; The script shows a menu list of shortcuts to the files previously drag'n'dropped onto it.
; First, user just needs to drag'n'drop any files onto this script's file. The script will create an external *.txt file to store those files' (or folders') paths and their names.
; Later, when the user will just execute this script - it will use the data from the *.txt file to create a menu list. Clicking on any list item in that menu will run/open the corresponding file/folder.
;
; 【 Credits 】
; The script is written by Drugoy, contact me via email: idrugoy@gmail.com
; Script's issue tracker should be listed there: https://github.com/Drugoy


#NoEnv
#NoTrayIcon
#SingleInstance, Force
SetWorkingDir %A_ScriptDir%

; Here we create var %settingstxt% that contains a name of the txt file (which is equal to the script's name, except it has a *.txt extension).
SplitPath, A_ScriptFullPath, , , , settingstxt
settingstxt := settingstxt ".txt"
; And then we check if that file already exists.
IfNotExist %settingstxt%	; Nothing to show: settings file doesn't yet exist.
	settingsExist := false


; This is a check: did user just run the script (to access stored shortcuts), or he drag'n'dropped a file(s) onto script to add the shortcut(s).

If (0 = 0)		; User wanted to access the already stored shortcuts.
{
	If (settingsExist = false)	; The user has not yet added at least one shortcut.
		Msgbox You wanted to access the already stored shortcuts, but you don't have any settings file with at least one record yet.`nTo create one - just drag'n'drop any file you would like to have a shortcut to onto the this script's file.
	Else	; There is at least one shortcut.
	{
		FileRead, settings, %settingstxt%
		paths := {}	; Initiating an array. We will use it to add bindings between MenuItem and the path to run when it will be selected.
		Loop, Parse, settings, `n, `r
		{
			StringSplit, singleRecordPart, A_LoopField, |	; We will use file names (without it's path) as menu item names. %singleRecordPart1% contains file name.
			Menu, ShortcutsList, Add, %singleRecordPart1%, LaunchFiles	; Construct menu.
			paths.insert(singleRecordPart1, singleRecordPart2)	; Here we do bindings (using array) so we'll know later what to run.
		}
		Menu, ShortcutsList, Show, %A_GUIX%, %A_GUIY%	; Show the constructed menu.
	}
}
Else	; User did drag'n'drop at least one file.
	Loop %0%  ; Usually %0% contains the number of command line parameters, but when the user drag'n'drops files onto the script - each of the dropped file gets sent to script as a separate command line parameter, so %0% contains the number of dropped files.
		Loop % %A_Index%, 1
			FileAppend, %A_LoopFileName%|%A_LoopFileLongPath%`n, %settingstxt%
ExitApp

LaunchFiles:
	Run, % paths[A_ThisMenuItem]	; Since we used arrays - we know what the selected MenuItem is bound to. So we just run the bound path
	Return