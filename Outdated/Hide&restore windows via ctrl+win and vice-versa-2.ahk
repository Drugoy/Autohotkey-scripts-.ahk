global ArrayMinimisedID := [] ; в этот массив будут записываться все минимизированные окна
global EVENT_SYSTEM_MINIMIZESTART := 0x16
global EVENT_SYSTEM_MINIMIZEEND := 0x17
; создаём изначально отключённую горячую клавишу LWin, которую будем включать при необходимости.
Hotkey, *LWin, Win, Off   

WinGet, List, List
Loop % List
{
	WinGet, MinMax, MinMax, % "ahk_id" List%A_Index%
	if MinMax = -1
		ArrayMinimisedID.Insert(List%A_Index%)
}
; устанавливаем хук, отслеживающий события минимизации и восстановления
; информация — http://msdn.microsoft.com/en-us/library/windows/desktop/dd373640%28v=vs.85%29.aspx
DllCall("SetWinEventHook", UInt, EVENT_SYSTEM_MINIMIZESTART
						, UInt, EVENT_SYSTEM_MINIMIZEEND
						, UInt, 0
						, UInt, RegisterCallback("HookProc", "F")
						, UInt, 0 , UInt, 0 , UInt, 0)
Return
 
HookProc(hWinEventHook, event, hwnd)
{
	if (event = EVENT_SYSTEM_MINIMIZESTART)
		ArrayMinimisedID.Insert(1, hwnd) ; при минимизации какого-л. окна записываем его идентификатор в массив

	if (event = EVENT_SYSTEM_MINIMIZEEND) ; при восстановлении какого-л. окна исключаем его идентификатор из массива
		for k, v in ArrayMinimisedID
			if (v = hwnd)
				ArrayMinimisedID.Remove(k, k)
}

~*LCtrl::
	if !GetKeyState("LWin", "P")
	{
		Hotkey, *LWin, On
		Return
	}
	if !GetKeyState("LShift", "P")
	{
	WinGetClass, class, A
	if !(class ~= "Progman|WorkerW|Shell_TrayWnd|Button")
		WinMinimize, A
	Return
	}

~*LCtrl Up:: Hotkey, *LWin, Off

Win:
	ID := ArrayMinimisedID.1
	WinRestore, % "ahk_id " ID
	WinActivate, % "ahk_id " ID
	Return
; Win+` = добавить/снять активному окну метку "поверх всех окон".
#`::Winset, Alwaysontop, , A

; Win+Shift+LCtrl = Win+D
#+LCtrl::Send, #d

; To do:
; Мидл-клик по окнам в таскбаре закрывает их, мидл клик по пуску открывает окно завершения работы.
; Прокрутка вверх/вниз над таскбаром - переключает окна вверх/вниз.