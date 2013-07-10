#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; Get a list of all existing windows
WinGet, win, List
Loop, %win%
{
	thisWin := win%A_Index%
	WinGetClass, class, ahk_id %thisWin%
	WinGetTitle, title, ahk_id %thisWin%
	WinGet, path, ProcessPath, ahk_id %thisWin%
	Msgbox Window #%A_Index%/%win%:`nClass: '%class%'`nTitle: '%title%'`nPath: '%path%'
}