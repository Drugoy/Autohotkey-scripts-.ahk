#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; An example on how to get a list of HWNDs of all the windows related to program.exe

WinGet, hwndArray, List, ahk_exe program.exe
Loop, %hwndArray%
     GroupAdd, winGroup, % "ahk_id " . hwndArray%A_Index%
#IfWinActive ahk_group winGroup
Msgbox the window related to program.exe is currently active.