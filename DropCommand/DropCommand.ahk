; http://www.donationcoder.com/Software/Skrommel/DropCommand/DropCommand.ahk
;DropCommand.ahk
; Enables drag and drop of files to a command window in Vista
;Skrommel @ 2008

FileInstall,DropCommand.wav,DropCommand.wav

#SingleInstance,Force
#NoEnv
SetWinDelay,0
SetControlDelay,0
CoordMode,Mouse,Screen
DetectHiddenWindows,on
SetBatchLines,-1

showtooltip=1
playsound=1

applicationname=DropCommand
Gosub,TRAYMENU

Gui,+E0x10 +LastFound +AlwaysOnTop -Caption
gui:=WinExist()
Gui,Show,W3 H3
WinHide,ahk_id %gui%
WinSet,Transparent,1,ahk_id %gui%
Return


MOVE:
MouseGetPos,mx2,my2,mwin
WinGetClass,class,ahk_id %mwin%
If class Not In ConsoleWindowClass
  Return
WinMove,ahk_id %gui%,,% mx2-1,% my2-1
WinSet,AlwaysOnTop,On,ahk_id %gui%
WinShow,ahk_id %gui%
Return


~$LButton::
MouseGetPos,mx1,my1,mwin
WinGetClass,class,ahk_id %mwin%
If class In ConsoleWindowClass
{
  WinHide,ahk_id %gui%
  Return
}
down=1
SetTimer,MOVE,100
Return


~$LButton Up::
If down<>1
  Return
down=0
SetTimer,MOVE,Off
SetTimer,HIDE,-100
Return


;By Sean at http://www.autohotkey.com/forum/topic16849.html
GuiDropFiles:
WinHide,ahk_id %gui%
If showtooltip=1
  ToolTip,%A_GuiEvent%
clip:=ClipboardAll
Loop,Parse,A_GuiEvent,`n
{
  If A_LoopField=
    Continue
  IfInString,A_LoopField,%A_Space%
    ClipBoard:="""" A_LoopField """" A_Space
  Else
    ClipBoard:=A_LoopField . A_Space
  ClipWait,1
  nIndex0 := 7   ; 0-based index of the SubMenu in SysMenu 
  nIndex1 := 2   ; 0-based index of the item in the SubMenu 
  MouseGetPos,,,hWnd
  hSysMenu := DllCall("GetSystemMenu", "Uint", hWnd, "int", False) 
  ; nID := DllCall("GetMenuItemID", "Uint", hSysMenu, "int", nIndex0) ; produce -1 for a SubMenu item 
  hSubMenu := DllCall("GetSubMenu", "Uint", hSysMenu, "int", nIndex0) 
  nID := DllCall("GetMenuItemID", "Uint", hSubMenu, "int", nIndex1) 
  PostMessage,0x112,nID,0,,ahk_id %hWnd%   ; WM_SYSCOMMAND
  If playsound=1
    SoundPlay,%applicationname%.wav
  Sleep,100
}
Clipboard:=clip
Clip:=
SetTimer,TOOLTIPOFF,-1000
Return


TOOLTIPOFF:
ToolTip,
Return


HIDE:
WinHide,ahk_id %gui%
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


EXIT:
ExitApp


ABOUT:
Gui,2:Destroy
Gui,2:Add,Picture,Icon1,%applicationname%.exe
Gui,2:Font,Bold
Gui,2:Add,Text,x+10 yp+10,%applicationname% v1.0
Gui,2:Font
Gui,2:Add,Text,xm,Enables drag and drop of files to a command window in Vista
Gui,2:Add,Text,y+0,`t

Gui,2:Add,Picture,xm Icon2,%applicationname%.exe
Gui,2:Font,Bold
Gui,2:Add,Text,x+10 yp+10,1 Hour Software by Skrommel
Gui,2:Font
Gui,2:Add,Text,xm,For more tools, information and donations, visit
Gui,2:Font,CBlue Underline
Gui,2:Add,Text,xm G1HOURSOFTWARE,www.1HourSoftware.com
Gui,2:Font
Gui,2:Add,Text,y+0,`t

Gui,2:Add,Picture,xm Icon5,%applicationname%.exe
Gui,2:Font,Bold
Gui,2:Add,Text,x+10 yp+10,DonationCoder
Gui,2:Font
Gui,2:Add,Text,xm,Please support the DonationCoder community
Gui,2:Font,CBlue Underline
Gui,2:Add,Text,xm GDONATIONCODER,www.DonationCoder.com
Gui,2:Font
Gui,2:Add,Text,y+0,`t

Gui,2:Add,Picture,xm Icon6,%applicationname%.exe
Gui,2:Font,Bold
Gui,2:Add,Text,x+10 yp+10,AutoHotkey
Gui,2:Font
Gui,2:Add,Text,xm,This program was made using AutoHotkey
Gui,2:Font,CBlue Underline
Gui,2:Add,Text,xm GAUTOHOTKEY,www.AutoHotkey.com
Gui,2:Font
Gui,2:Add,Text,y+0,`t
Gui,2:Add,Text,y+0,`t

Gui,2:Font,Bold
Gui,2:Add,Text,xm yp+10,FreeSoundFiles
Gui,2:Font
Gui,2:Add,Text,xm,Sound file from 
Gui,2:Font,CBlue Underline
Gui,2:Add,Text,xm GFREESOUNDFILES,www.FreeSoundFiles.tintagel.net
Gui,2:Font
Gui,2:Add,Text,y+0,`t

Gui,2:Add,Button,GABOUTOK Default w75,&OK
Gui,2:Show,,%applicationname% About

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

FREESOUNDFILES:
Run,http://www.freesoundfiles.tintagel.net
Return

ABOUTOK:
Gui,2:Destroy
OnMessage(0x200,"") 
DllCall("DestroyCursor","Uint",hCurs)
Return

WM_MOUSEMOVE(wParam,lParam)
{
  Global hCurs
  MouseGetPos,,,,ctrl
  If ctrl in Static8,Static13,Static18,Static23
    DllCall("SetCursor","UInt",hCurs)
  Return
}