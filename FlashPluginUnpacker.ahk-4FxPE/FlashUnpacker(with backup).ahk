#SingleInstance, Force
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

If RegExMatch(A_ScriptDir, "i)\\Data\\plugins\b")
	outputPath := A_ScriptDir

If !0	; The script was executed with no arguments (thus, no files were drag'n'dropped onto that script)
{
	Msgbox, 1, No input file specified, This script only works with that file: http://portableappz.blogspot.ru/2011/03/flash-1021531-10318042-plugins.html (click on the Download Flash 32-64 bit Plugin link there).`nWould you like to open that page in your browser?
	IfMsgBox, OK
		Run, http://portableappz.blogspot.ru/2011/03/flash-1021531-10318042-plugins.html
	Else
	{
		Msgbox, 1, Backup, Would you like to backup the existing .dll files?
		IfMsgBox, OK
			GoSub, Backup
	}
}
Else If 0	; The script was executed with one argument (it maybe caused by user drag'n'dropping any file onto the script)
{
	Loop, %0%
	{
		GivenPath := %A_Index%
		Loop %GivenPath%, 1
			fileLongPath := A_LoopFileLongPath
	}
	If RegExMatch(fileLongPath, ".*\\Flash_Portable_.*_Plugin.exe")
		GoSub, Unpack
	Else
	{
		MsgBox, 4, Unknown file, The input file's name doesn't match `"Flash_Portable_.*_Plugin.exe`" RegEx pattern. Are you sure it is a Flash installer for Chrome?
		IfMsgBox, Yes
			GoSub, Unpack
	}
	Return
}
Return

Unpack:
	Process, Close, plugin-container.exe
	GoSub, Backup
	Run, 7z.exe e `"%fileLongPath%`" -o`"%outputPath%`" CommonFiles\Plugins\*.dll, % ((A_Is64bitOS) ? (ProgramW6432) : (A_ProgramFiles)) "\7-Zip" ;, Hide
Return

Backup:
	
	MsgBox, 1, Backup, Would you like to backup the existing *.dll files in the folder next to this script's file?`nIf you have any *.bak files they will be renamed to *.bak.bak and so on.
	IfMsgBox, Yes
	{
		If !outputPath
			GoSub, SelectPath
		Loop, %outputPath%\*.dll
			fileName := A_LoopFileName, backup(fileName)
	}
	Else
		ExitApp
Return

SelectPath:
	Msgbox navigate to the folder: "...\Data\Plugins" in case you use FirefoxPortable or "...Firefox\Browser\Plugins" in case you use regular Firefox.
	FileSelectFolder, outputPath
Return

backup(file)
{
	Process, Close, plugin-container.exe
	IfExist, %file%.bak
		backup(file ".bak")
	FileMove %file%, %file%.bak
}