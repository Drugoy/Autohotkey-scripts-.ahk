#SingleInstance, Force
~Alt & LButton::KDE_WinMove("LButton")

KDE_WinMove(sButton)
{
	If !GetKeyState(sButton, "P")
		Exit

	SetWinDelay, 0
	CoordMode, Mouse
	MouseGetPos, x1, y1, id
	WinExist("ahk_id" . id)

	If WinActive() ; если найденное выше окно активно Ч выходим из подпрограммы гор€чей клавиши.
		Exit

	WinGetClass, winClass
	If (winClass == "WorkerW")
		Exit

	WinGet, win, MinMax
	If (win)
		Exit

	WinGetPos, winX1, winY1
	While GetKeyState(sButton, "P")
	{
		MouseGetPos, x2, y2
		x2 -= x1, y2 -= y1, winX2 := winX1 + x2, winY2 := winY1 + y2
		WinMove,,, winx2, winY2
		Sleep 15
	}
}