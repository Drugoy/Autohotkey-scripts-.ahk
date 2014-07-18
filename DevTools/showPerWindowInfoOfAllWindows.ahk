#SingleInstance, Force
; DetectHiddenWindows, On	; Uncomment this to enter  th
#NoEnv

;{ Blacklist
GroupAdd, blackList, Пуск ahk_class Button ahk_exe %A_WinDir%\explorer.exe
GroupAdd, blackList, ahk_class Shell_TrayWnd ahk_exe %A_WinDir%\explorer.exe
GroupAdd, blackList, Program Manager ahk_class Progman ahk_exe %A_WinDir%\explorer.exe
;}

;{ Gather lists of existing windows' HWNDs.
WinGet, winBlackList, List, ahk_group blackList	; Retrieve IDs of existing windows from black list.
WinGet, winList, List	; Retrieve IDs of all the existing windows.
;}
;{ Parse the lists of HWNDs to create a list of HWNDs of only non-blacklisted windows.
shift := 0
Loop, %winList%
{
	thisIndex := A_Index
	Loop, %winBlackList%	; Check if the parsed window is in the black list.
	{
		If (winList%thisIndex% == winBlackList%A_Index%)
		{
			shift++	; This is a token to detect shift to rebuild the winList.
			Continue, 2
		}
	}
	If shift
		tempVar := A_Index - shift, winList%tempVar% := winList%A_Index%
}
winlist -= shift
;}
;{ Make a "snapshot" of all the data about the existing non-blacklisted windows at this moment.
Loop, %winList%
{
	WinGetTitle, title%A_Index%, % "ahk_id " winList%A_Index%
	WinGetClass, class%A_Index%, % "ahk_id " winList%A_Index%
	; WinGetText, text%A_Index%, % "ahk_id " winList%A_Index%
	WinGetPos, x%A_Index%, y%A_Index%, width%A_Index%, height%A_Index%, % "ahk_id " winList%A_Index%
	WinGet, ID%A_Index%, ID, % "ahk_id " winList%A_Index%
	WinGet, IDLast%A_Index%, IDLast, % "ahk_id " winList%A_Index%
	WinGet, ProcessName%A_Index%, ProcessName, % "ahk_id " winList%A_Index%
	WinGet, ProcessPath%A_Index%, ProcessPath, % "ahk_id " winList%A_Index%
	WinGet, PID%A_Index%, PID, % "ahk_id " winList%A_Index%
	WinGet, MinMax%A_Index%, MinMax, % "ahk_id " winList%A_Index%
	; WinGet, ControlList%A_Index%, ControlList, % "ahk_id " winList%A_Index%
	; WinGet, ControlListHwnd%A_Index%, ControlListHwnd, % "ahk_id " winList%A_Index%
	WinGet, Transparent%A_Index%, Transparent, % "ahk_id " winList%A_Index%
	WinGet, TransColor%A_Index%, TransColor, % "ahk_id " winList%A_Index%
	WinGet, Style%A_Index%, Style, % "ahk_id " winList%A_Index%
	WinGet, ExStyle%A_Index%, ExStyle, % "ahk_id " winList%A_Index%
}
;}
;{ Display the snapshotted data.
; If the MsgBox would be inside the previous loop - it would fail to display the info about windows that have died by the moment you've reached the MsgBox about them. 
Loop, %winList%
{
	MsgBox,, % "Window #" A_Index "/" winList
	, % "Title: '" title%A_Index% "'`n"
	. "Class: '" class%A_Index% "'`n"
	. "Text: '" text%A_Index% "'`n"
	. "Position [x,y] of top left corner: [" x%A_Index% "," y%A_Index% "]`n"
	. "Size [w,h]: [" width%A_Index% "," height%A_Index% "]`n"
	. "ID: '" ID%A_Index% "'`n"
	. "IDLast: '" IDLast%A_Index% "'`n"
	. "ProcessName: '" ProcessName%A_Index% "'`n"
	. "ProcessPath: '" ProcessPath%A_Index% "'`n"
	. "PID: '" PID%A_Index% "'`n"
	. "MinMax: '" MinMax%A_Index% "'`n"
	. "ControlList: '" ControlList%A_Index% "'`n"
	. "ControlListHwnd: '" ControlListHwnd%A_Index% "'`n"
	. "Transparent: '" Transparent%A_Index% "'`n"
	. "TransColor: '" TransColor%A_Index% "'`n"
	. "Style: '" Style%A_Index% "'`n"
	. "ExStyle: '" ExStyle%A_Index% "'"
}
;}