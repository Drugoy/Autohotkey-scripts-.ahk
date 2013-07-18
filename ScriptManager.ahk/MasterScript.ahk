/* MasterScript.ahk
Description: this is a script manager written in .ahk and supposed to control other .ahk scripts.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/ScriptManager.ahk/MasterScript.ahk
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force

scanMemoryForAhkProcesses:
; Defining and clearing arrays.
scriptNamesArray := pidsArray := []

; Parsing through a list of running processes to filter out non-ahk ones.
For Process In ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")	; A list of accessible parameters related to the running processes: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
{
	; If (Process.ExecutablePath == A_AhkPath)	; This and the next line are the alternative to the If RegExMatch() below.
	; 	Process.CommandLine := RegExReplace(Process.CommandLine, "i)^.*\\|\.ahk\W*") . ".ahk"
	If RegExMatch(Process.CommandLine, "^(""|\s)*\Q" A_AhkPath "i)\E.*\\(?<Name>.*\.ahk)(""|\s)*$", Script)	; Parses "CommandLine" parameter, filters out non-ahk processes and outputs running script's name to the "ScriptName" variable, so we can fullfill our arrays with the running ahk-scripts' names and their processIDs.
	{
		scriptNamesArray.Insert(ScriptName)	; Using contents of the "ScriptName" variable to fulfill our "scriptNamesArray" array.
		pidsArray.Insert(Process.ProcessId)	; Using "ProcessId" param to fulfill our "pidsArray" array.
	}
}
Return