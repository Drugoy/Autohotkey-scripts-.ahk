#SingleInstance, Force

#If !WinUnderMousePointerActive()
!Lbutton::KDE_WinMove("Lbutton")
#If
 
WinUnderMousePointerActive()
{
    MouseGetPos,,, hWnd
    Return WinActive("ahk_id" hWnd)
}
 
KDE_WinMove(sButton)
{
    If !GetKeyState(sButton, "P")
        Exit
 
    CoordMode, Mouse
    MouseGetPos, x1, y1, id
    WinExist("ahk_id" . id)
 
    WinGetClass, winClass
    WinGet, win, MinMax
    If (winClass == "WorkerW" || winClass == "Progman") || (win)
        Exit
 
    SetWinDelay, 0
    WinGetPos, winX1, winY1
    While GetKeyState(sButton, "P")
    {
        MouseGetPos, x2, y2
        x2 -= x1, y2 -= y1, winX2 := winX1 + x2, winY2 := winY1 + y2
        WinMove,,, winx2, winY2
        Sleep 15
    }
}