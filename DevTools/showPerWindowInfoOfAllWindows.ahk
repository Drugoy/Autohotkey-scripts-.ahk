#SingleInstance, Force
#NoEnv

; Blacklist
GroupAdd, blackList, Пуск ahk_class Button ahk_exe %A_WinDir%\explorer.exe
GroupAdd, blackList, ahk_class Shell_TrayWnd ahk_exe %A_WinDir%\explorer.exe
GroupAdd, blackList, Program Manager ahk_class Progman ahk_exe %A_WinDir%\explorer.exe

; Get a list of all existing windows, except blacklisted
; WinGet, win, List,,, ahk_group blackList
WinGet, win, List
Loop, %win%
{
	WinGetClass, class, % "ahk_id " win%A_Index%
	WinGetTitle, title, % "ahk_id " win%A_Index%
	WinGet, path, ProcessPath, % "ahk_id " win%A_Index%
	WinGet, PID, PID, % "ahk_id " win%A_Index%
	Msgbox,, Window №%A_Index%/%win%, Class: '%class%'`nTitle: '%title%'`nPath: '%path%'`nPID: '%PID%'
}