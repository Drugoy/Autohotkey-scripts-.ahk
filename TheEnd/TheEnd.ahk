; http://www.donationcoder.com/Software/Skrommel/index.html#TheEnd
;TheEnd.ahk
; Unselect the file type when renaming files in XP
;Skrommel @ 2008

#SingleInstance,Force
#NoEnv
SendMode,Input
DetectHiddenWindows,On
SetWinDelay,0
SetKeyDelay,0
SetControlDelay,0

applicationname=TheEnd

Gosub,TRAYMENU
Return


~LButton::
~F2::
WinGet,active,ID,A
WinGetClass,class,ahk_id %active%
If class Not In Progman,WorkerW,ExploreWClass,CabinetWClass
  Return
counter=0


EDIT:
Sleep,200
ControlGetFocus,focus,ahk_id %active%
ControlGet,hwnd,Hwnd,,%focus%,ahk_id %active%
If (hwnd=oldhwnd)
  Return
IfNotInString,focus,Edit
  Goto,TIMER
ControlGetText,text,%focus%,ahk_id %active%
SplitPath,text,name,dir,ext,name_no_ext,drive
StringLen,length,ext
length+=1
If (length<=1)
  Goto,TIMER
ControlGetFocus,oldfocus,ahk_id %active%
ControlGet,oldhwnd,Hwnd,,%oldfocus%,ahk_id %active%
ControlSend,%focus%,{Left %length%},ahk_id %active%
Return


TIMER:
If counter<=10
{
  counter+=1
  Goto,EDIT
}
Return


TRAYMENU:
Menu,Tray,NoStandard
Menu,Tray,DeleteAll
Menu,Tray,Add,%applicationname%,ABOUT
Menu,Tray,Add,
Menu,Tray,Add,&About...,ABOUT
Menu,Tray,Add,E&xit,EXIT
Menu,Tray,Default,%applicationname%
Menu,Tray,Tip,%applicationname%
Return


ABOUT:
Gui,99:Destroy
Gui,99:Margin,20,20
Gui,99:Add,Picture,xm Icon1,%applicationname%.exe
Gui,99:Font,Bold
Gui,99:Add,Text,x+10 yp+10,%applicationname% v1.0
Gui,99:Font
Gui,99:Add,Text,y+10,Unselect the file type when renaming files in XP
Gui,99:Add,Text,y+10,- Press F2 to rename a file. 
Gui,99:Add,Text,y+10,- Or click a filename slowly two times.

Gui,99:Add,Picture,xm y+20 Icon5,%applicationname%.exe
Gui,99:Font,Bold
Gui,99:Add,Text,x+10 yp+10,1 Hour Software by Skrommel
Gui,99:Font
Gui,99:Add,Text,y+10,For more tools, information and donations, please visit 
Gui,99:Font,CBlue Underline
Gui,99:Add,Text,y+5 G1HOURSOFTWARE,www.1HourSoftware.com
Gui,99:Font

Gui,99:Add,Picture,xm y+20 Icon7,%applicationname%.exe
Gui,99:Font,Bold
Gui,99:Add,Text,x+10 yp+10,DonationCoder
Gui,99:Font
Gui,99:Add,Text,y+10,Please support the contributors at
Gui,99:Font,CBlue Underline
Gui,99:Add,Text,y+5 GDONATIONCODER,www.DonationCoder.com
Gui,99:Font

Gui,99:Add,Picture,xm y+20 Icon6,%applicationname%.exe
Gui,99:Font,Bold
Gui,99:Add,Text,x+10 yp+10,AutoHotkey
Gui,99:Font
Gui,99:Add,Text,y+10,This tool was made using the powerful
Gui,99:Font,CBlue Underline
Gui,99:Add,Text,y+5 GAUTOHOTKEY,www.AutoHotkey.com
Gui,99:Font

Gui,99:Show,,%applicationname% About
hCurs:=DllCall("LoadCursor","UInt",NULL,"Int",32649,"UInt") ;IDC_HAND
OnMessage(0x200,"WM_MOUSEMOVE") 
Return

1HOURSOFTWARE:
  Run,http://www.1hoursoftware.com,,UseErrorLevel
Return

DONATIONCODER:
  Run,http://www.donationcoder.com,,UseErrorLevel
Return

AUTOHOTKEY:
  Run,http://www.autohotkey.com,,UseErrorLevel
Return

99GuiClose:
  Gui,99:Destroy
  OnMessage(0x200,"")
  DllCall("DestroyCursor","Uint",hCur)
Return

WM_MOUSEMOVE(wParam,lParam)
{
  Global hCurs
  MouseGetPos,,,,ctrl
  If ctrl in Static9,Static13,Static17
    DllCall("SetCursor","UInt",hCurs)
  Return
}
Return

EXIT:
ExitApp