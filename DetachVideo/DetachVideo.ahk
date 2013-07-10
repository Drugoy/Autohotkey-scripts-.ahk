#SingleInstance,Force
DetectHiddenWindows,On
SetWinDelay,0

counter=0
OnExit,EXIT
SetTimer,MOVE,500
Return

F12::
SetTimer,MOVE,Off
MouseGetPos,,,window,ctrl,2
WinGetPos,,,ww,wh,ahk_id %window%
WinGetPos,,,cw,ch,ahk_id %ctrl%
current:=counter
Loop,% counter+1
{
  If gui_%A_Index%=
  {
    current:=A_Index
    Break
  }
}
If current>%counter%
  counter+=1
Gui,%current%:+AlwaysOnTop +Resize +ToolWindow +LabelAllGui 
Gui,%current%:Show,X0 Y0 W%cw% H%ch%,DetachVideo
Gui,%current%:+LastFound
gui:=WinExist("A")
parent:=DllCall("SetParent","UInt",ctrl,"UInt",gui)
WinMove,ahk_id %ctrl%,,0,0 ;,%cw%,%ch%
ctrl_%current%:=ctrl
gui_%current%:=gui
parent_%current%:=parent
window_%current%:=window
w_%current%:=ww
h_%current%:=wh
SetTimer,MOVE,500
Return

MOVE:
SetTimer,MOVE,Off
Loop,%counter%
{
  ctrl:=ctrl_%A_Index%
  If ctrl=
    Continue
  IfWinExist,ahk_id %ctrl%
    WinMove,ahk_id %ctrl%,,0,0
  Else
    Gui,%A_Index%:Destroy
}
SetTimer,MOVE,500
Return

AllGuiClose:
SetTimer,MOVE,Off
ctrl:=ctrl_%A_Gui%
window:=window_%A_Gui%
DllCall("SetParent","UInt",ctrl_%A_Gui%,"UInt",parent_%A_Gui%)
Gui,%A_Gui%:Destroy
WinMove,ahk_id %ctrl%,,0,0
WinMove,ahk_id %window%,,,,% w_%A_Gui%,% h_%A_Gui%+1
WinMove,ahk_id %window%,,,,% w_%A_Gui%,% h_%A_Gui%
gui_%A_Gui%=
ctrl_%A_Gui%=
parent_%A_Gui%=
SetTimer,MOVE,500
Return

EXIT:
SetTimer,MOVE,Off
Loop,%counter%
{
  ctrl:=ctrl_%A_Index%
  window:=window_%A_Index%
  If ctrl=
    Continue
  DllCall("SetParent","UInt",ctrl_%A_Index%,"UInt",parent_%A_Index%)
  Gui,%A_Index%:Destroy
  WinMove,ahk_id %ctrl%,,0,0
  WinMove,ahk_id %window%,,,,% w_%A_Index%,% h_%A_Index%+1
  WinMove,ahk_id %window%,,,,% w_%A_Index%,% h_%A_Index%
}
ExitApp