; http://www.donationcoder.com/Software/Skrommel/index.html#GoneIn60s
;GoneIn60s.ahk
; Recover closed applications
;Skrommel @ 2006

#NoEnv
#SingleInstance,Force

OnExit,EXIT

CoordMode,Mouse,Screen
CoordMode,ToolTip,Screen

SysGet,SM_CYCAPTION,4
SysGet,SM_CXBORDER,5
SysGet,SM_CYBORDER,6
SysGet,SM_CXEDGE,45
SysGet,SM_CYEDGE,46
SysGet,SM_CXFIXEDFRAME,7
SysGet,SM_CYFIXEDFRAME,8
SysGet,SM_CXSIZEFRAME,32
SysGet,SM_CYSIZEFRAME,33
SysGet,SM_CXSIZE,30
SysGet,SM_CYSIZE,31

applicationname=GoneIn60s

Gosub,INIREAD

inside=0

Gosub,TRAYMENU
SetTimer,CHECK,1000

Loop
{
  Sleep,100
  MouseGetPos,mx,my,win1
  parent:=DllCall("GetParent","uint",win1)
  If parent>0
    Continue
  WinGetPos,x,y,w,h,ahk_id %win1%
  l:=x+w-SM_CXSIZEFRAME-SM_CXSIZE
  t:=y+SM_CYSIZEFRAME
  r:=x+w-SM_CXSIZEFRAME
  b:=y+SM_CYSIZEFRAME+SM_CYSIZE
  If (mx<l Or mx>r Or my<t Or my>b)
  {
    If inside=1
    {
      ToolTip,
      Hotkey,LButton,CLICK,Off
      inside=0
    }
  }
  Else
  {
    If inside=0
    {
      WinGet,program,ProcessName,ahk_id %win1%
      If program In %ignore%
        Continue 
      WinGetClass,class,ahk_id %win1%
      If class In %nonwindows%
        Continue 
      ToolTip,Gone in %timeout% seconds
      Hotkey,LButton,CLICK,On
      inside=1
    }
  }
}


!F4::
WinGet,win1,Id,A
parent:=DllCall("GetParent",UInt,win1)
If parent>0
  Return
WinGetClass,class,ahk_id %win1%
If class In %nonwindows%
  Return

CLICK:
WinHide,ahk_id %win1%
IfNotInString,closing,%win1%
{
  closing=%closing%%win1%-%A_TickCount%|
  Gosub,TRAYMENU
}
Return


CHECK:
StringSplit,part_,closing,|
Loop,% part_0-1
{
  StringSplit,info_,part_%A_Index%,-
  IfWinExist,ahk_id %info_1%
  {
    left:=Ceil((info_2+timeout*1000-A_TickCount)/1000)
    TrayTip,%applicationname%,Recovered with %left% seconds left!
    StringReplace,closing,closing,%info_1%-%info_2%|
    Gosub,TRAYMENU
  }
  Else
  If (A_TickCount>=info_2+timeout*1000)
  {
    DetectHiddenWindows,On
    If kill=1
    {
      WinGet,pid,Pid,ahk_id %info_1%
      Process,Close,%pid%
    }
    Else
      WinClose,ahk_id %info_1%
    DetectHiddenWindows,Off
    Sleep,1000
    WinShow,ahk_id %info_1%
    StringReplace,closing,closing,%info_1%-%info_2%|
    Gosub,TRAYMENU
  }
 }
Return


RECOVER:
menuitem:=A_ThisMenuItemPos-4
StringSplit,part_,closing,|
StringSplit,info_,part_%menuitem%,-
WinShow,ahk_id %info_1%
Return


RECOVERALL:
StringSplit,part_,closing,|
Loop,% part_0-1
{
  StringSplit,info_,part_%A_Index%,-
  WinShow,ahk_id %info_1%
}
Return


CLOSEALL:
StringSplit,part_,closing,|
Loop,% part_0-1
{
  StringSplit,info_,part_%A_Index%,-
  DetectHiddenWindows,On
  If kill=1
  {
    WinGet,pid,Pid,ahk_id %info_1%
    Process,Close,%pid%
  }
  Else
    WinClose,ahk_id %info_1%
  DetectHiddenWindows,Off
  Sleep,1000
  WinShow,ahk_id %info_1%
  StringReplace,closing,closing,%info_1%-%info_2%|
  Gosub,TRAYMENU
 }
Return



SETTINGS:
ok=0
Gui,Destroy
Gui,Margin,20,10

Gui,Add,GroupBox,xm-10 w300 h50,&Time to wait
Gui,Add,Edit,xm yp+20 w100 vtimeout
Gui,Add,UpDown,x+5,%timeout%
Gui,Add,Text,x+5 yp+2,seconds

Gui,Add,GroupBox,xm-10 y+20 w300 h50,Actions
Gui,Add,CheckBox,xm yp+20 vkill Checked%kill%,&Kill windows   Won't ask to save changed documents!

Gui,Add,GroupBox,xm-10 y+20 w300 h120,&Programs to ignore
Gui,Add,Edit,xm yp+20 r5 w280 vignore,%ignore%
Gui,Add,Text,xm y+5,Example: Notepad.exe,Calc.exe,Pbrush.exe

Gui,Add,GroupBox,xm-10 y+20 w300 h120,Cl&asses to ignore
Gui,Add,Edit,xm yp+20 r5 w280 vsystem,%system%
Gui,Add,Text,xm y+5,Example: Shell_TrayWnd,Progman,#32768

Gui,Add,Button,xm y+20 w75 gSETTINGSOK,&OK
Gui,Add,Button,x+5 w75 gSETTINGSCANCEL,&Cancel

Gui,Show,,%applicationname% Settings

Loop
{
  If ok=1
    Break
  MouseGetPos,x,y,winid,ctrlid
  WinGet,program,ProcessName,ahk_id %winid%
  WinGetClass,class,ahk_id %winid%
  ToolTip,Program: %program%`nClass:      %class%
  Sleep,100
}
ToolTip,
Return


GuiClose:
SETTINGSOK:
ok=1
Gui,Submit
Gosub,INIWRITE
Return


SETTINGSCANCEL:
ok=1
Gui,Destroy
Return


TRAYMENU:
Menu,Tray,NoStandard
Menu,Tray,DeleteAll
Menu,Tray,Add,%applicationname%,RECOVERALL
Menu,Tray,Add
Menu,Tray,Add,&Recover All,RECOVERALL
Menu,Tray,Add
DetectHiddenWindows,On
StringSplit,part_,closing,|
Loop,% part_0-1
{
  StringSplit,info_,part_%A_Index%,-
  WinGetTitle,title,ahk_id %info_1%
  Menu,Tray,Add,&%A_Index% - %title%,RECOVER
}
DetectHiddenWindows,Off
Menu,Tray,Add
Menu,Tray,Add,&Settings...,SETTINGS
Menu,Tray,Add,&About...,ABOUT
Menu,Tray,Add,E&xit,EXIT
Menu,Tray,Default,%applicationname%
Menu,Tray,Tip,%applicationname%
Return


ABOUT:
ok=1
Gui,99:Destroy
Gui,99:Margin,20,20
Gui,99:Add,Picture,xm Icon1,%applicationname%.exe
Gui,99:Font,Bold
Gui,99:Add,Text,x+10 yp+10,%applicationname% v1.4
Gui,99:Font
Gui,99:Add,Text,y+10,Recover closed applications
Gui,99:Add,Text,y+10,- To recover, rightclick the tray icon and choose an application 
Gui,99:Add,Text,y+10,- Doubleclick the tray icon to recover all closed applications
Gui,99:Add,Text,y+10,- If not recovered, it is gone in %timeout% seconds

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
  If ctrl in Static10,Static14,Static18
    DllCall("SetCursor","UInt",hCurs)
  Return
}
Return


EXIT:
Gosub,CLOSEALL
ExitApp


INIREAD:
IniRead,timeout,%applicationname%.ini,Settings,timeout
If timeout=ERROR
  timeout=60
IniRead,kill,%applicationname%.ini,Settings,kill
If kill=ERROR
  kill=0
IniRead,ignore,%applicationname%.ini,Settings,ignore
If ignore=ERROR
  ignore=Notepad.exe
IniRead,system,%applicationname%.ini,Settings,system
If system=ERROR
  system=Shell_TrayWnd,Progman,#32768,Basebar,DV2ControlHost
StringReplace,ignore,ignore,%A_Space%`,,`,,All
StringReplace,ignore,ignore,`,%A_Space%,`,,All
StringReplace,system,system,%A_Space%`,,`,,All
StringReplace,system,system,`,%A_Space%,`,,All
Return


INIWRITE:
StringReplace,ignore,ignore,%A_Space%`,,`,,All
StringReplace,ignore,ignore,`,%A_Space%,`,,All
StringReplace,system,system,%A_Space%`,,`,,All
StringReplace,system,system,`,%A_Space%,`,,All
IniWrite,%timeout%,%applicationname%.ini,Settings,timeout
IniWrite,%kill%,%applicationname%.ini,Settings,kill
IniWrite,%ignore%,%applicationname%.ini,Settings,ignore
IniWrite,%system%,%applicationname%.ini,Settings,system
Return


