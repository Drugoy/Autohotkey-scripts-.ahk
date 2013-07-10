#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#persistent
breakThisLoop := false
F1::
    Loop, 200
    {
        Send a
        sleep 1100
    }
    until breakThisLoop = true
    return

F2::breakThisLoop := !breakThisLoop
z::msgbox %breakthisloop%