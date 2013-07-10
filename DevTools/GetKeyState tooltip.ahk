; This example allows you to move the mouse around to see
; the title of the window currently under the cursor:
#Persistent
#SingleInstance force
#NoEnv
SetTimer, WatchCursor, 100
Return

WatchCursor:
GetKeyState, a, LAlt, P
GetKeyState, b, LButton, P
ToolTip, LAlt:%a%`nLButton:%b%
Return