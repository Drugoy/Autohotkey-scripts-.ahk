#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Loop %0%  ; %0% contains a number of parameters (if multiple files were dropped on the script - they all will be sent as separate parameters
{
    GivenPath := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
    Loop %GivenPath%, 1
        LongPath = %A_LoopFileLongPath%
    MsgBox,, File #%A_Index%, %LongPath%
}