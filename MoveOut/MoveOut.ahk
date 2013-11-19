; http://www.donationcoder.com/Software/Skrommel/index.html#MoveOut
;MoveOut.ahk
; Moves files from the destop (or any other folder) to another folder
; Make rules for certain file types or file names, to be ignored, replaced or renamed
;Skrommel @ 2006

#Persistent
#SingleInstance,Force

applicationname=MoveOut

open=0
Gosub,TRAYMENU
Gosub,INIREAD
If enabled=1
  enabled=0
Else
  enabled=1
Gosub,TOGGLE
SetTimer,TIMER,%timer%,On
Return


TIMER:
If enabled=0
  Return
SetTimer,TIMER,%timer%,Off
Loop,%rules%
{
  counter:=A_Index
  active:=%counter%active
  If active=0
    Continue
  source:=%counter%source
  target:=%counter%target
  files:=%counter%files
  ignore:=%counter%ignore
  replace:=%counter%replace
  If (source="" Or target="")
    Continue
  Gosub,MOVE
}
SetTimer,TIMER,%timer%,On
Return


MOVE:
FileCreateDir,%target%
Loop,%source%\%files%,1,0
{
  ext:=A_LoopFileExt
  name:=A_LoopFileName
  longpath:=A_LoopFileLongPath
;  If ext In %ignore%
;    Continue
;  If name In %ignore%
;    Continue
  If longpath Contains %ignore%
    Continue
  If status=1
    TrayTip,%applicationname%,%longpath%
  FileGetAttrib,attrib,%longpath%
  IfInString,attrib,D
    Gosub,FOLDER
  Else
    Gosub,FILE
}
Return


FOLDER:
MsgBox,%target%`n%longpath%
If replace=0
{
  FileMoveDir,%longpath%,%target%,R
  If ErrorLevel=1
    FileMoveDir,%longpath%,%target%,0
}
Else
If replace=1
{
  FileMoveDir,%longpath%,%target%,R
  If ErrorLevel=1
    FileMoveDir,%longpath%,%target%,2
}
Else
If replace=2
{
  IfExist,%target%\%name%
  {
    MsgBox,3,%applicationname%,Replace folder %target%\%name% ?
    IfMsgBox,Yes
    { 
      FileMoveDir,%longpath%,%target%,1
    }
    IfMsgBox,No
    {
      ignore=%ignore%,%longpath%
      %counter%ignore=%ignore%
    }
    IfMsgBox,Cancel
      Gosub,TOGGLE
  }
  Else
  {
    FileMoveDir,%longpath%,%target%,R    ;Doesn't work !?
    If ErrorLevel=1
      FileMoveDir,%longpath%,%target%,1  ;Should really be 0 !?
  }
}
Else
If replace=3
{
  IfExist,%target%\%name%
  {
    FileMoveDir,%longpath%,%target%\%name%-%A_Now%.%ext%,R
    If ErrorLevel=1
      FileMoveDir,%longpath%,%target%\%name%-%A_Now%.%ext%,0
  }
  Else
  {
    FileMoveDir,%longpath%,%target%,R
    If ErrorLevel=1
      FileMoveDir,%longpath%,%target%,0
  }
}
Return


FILE:
If replace=No
  FileMove,%longpath%,%target%,%replace%
Else
If replace=Yes
  FileMove,%longpath%,%target%,%replace%
Else
If replace=Ask
{
  IfExist,%target%\%name%
  {
    MsgBox,3,%applicationname%,Replace file %target%\%name% ?
    IfMsgBox,Yes
      FileMove,%longpath%,%target%,1
    IfMsgBox,No
    {
      ignore=%ignore%,%longpath%
      %counter%ignore=%ignore%
    }
    IfMsgBox,Cancel
      Gosub,TOGGLE
  }
  Else
    FileMove,%longpath%,%target%,0
}
Else
If replace=Rename
{
  IfExist,%target%\%name%
    FileMove,%longpath%,%target%\%name%-%A_Now%.%ext%,0
  Else
    FileMove,%longpath%,%target%,0
}
Return


INIREAD:
IfNotExist,%applicationname%.ini
{
  start=0                            ;0=No 1=Yes Run rules on program start
  enabled=0
  timer=3000                         ;How often to check for new files in ms
  status=0                           ;0=Hide 1=Show Traytip of files being moved

  1active=1                          ;0=Disabled 1=Active
  1source=%A_Desktop%                ;Use variables like %A_Desktop%, %A_ScriptDir%, %A_MyDocuments%, %A_StartMenu%
  1target=%A_Desktop%\Desktop        ;  %A_AppData%, %A_ProgramFiles%, %A_WinDir%
  1files=*                           ;Files to move, supports wildcards * and ?
  1ignore=jpg,jpeg,Desktop           ;Filenames and extensions to ignore, separated by comma. No wildcards!
  1replace=Ask                       ;use No, Yes, Ask or Rename

  2active=1
  2source=%A_DesktopCommon%          ;%A_DesktopCommon%, %A_StartMenuCommon%, %A_ProgramsCommon%
  2target=%A_DesktopCommon%\Desktop  
  2files=*                           
  2ignore=                           
  2replace=Ask                       

  3active=1
  3source=%A_Desktop%                
  3target=%A_Desktop%\Desktop        
  3files=*.jp*g                      ;Only jpg and jpeg images
  3ignore=                           
  3replace=Rename                    ;Rename if same name
  
  rules=3
  Gosub,INIWRITE
}
Else
{
  IniRead,start,%applicationname%.ini,Settings,start
  If start=1
    enabled=1
  Else
    enabled=0
  IniRead,timer,%applicationname%.ini,Settings,timer
  IniRead,status,%applicationname%.ini,Settings,status
  rules=1
  info=
  Loop
  {
    IniRead,active,%applicationname%.ini,%A_Index%,active
    IniRead,source,%applicationname%.ini,%A_Index%,source
    IniRead,target,%applicationname%.ini,%A_Index%,target
    IniRead,files,%applicationname%.ini,%A_Index%,files
    IniRead,ignore,%applicationname%.ini,%A_Index%,ignore
    IniRead,replace,%applicationname%.ini,%A_Index%,replace
    If (source="ERROR" And target="ERROR" And files="ERROR")
      Break
    If (source="" And target="" And files="")
      Break
    %rules%active:=active
    %rules%source:=source
    %rules%target:=target
    %rules%files:=files
    %rules%ignore:=ignore
    %rules%replace:=replace
    If active=1
      info=%info%Rule %rules%%A_Tab%Replace?%A_Tab%%replace%%A_Tab%Ignore:%A_Tab%%ignore%%A_Tab%`n Move:%A_Tab%%source%\%files% `n To:%A_Tab%%target% `n ;`n`n
    rules+=1
  }
  If enabled=1
  If info<>
  {
    MsgBox,4,MoveOut Confirmation,MoveOut is set to Enabled.`n`nDo you want to run the following rules now?`n`n%info%
    IfMsgBox,No
      enabled=0
  }
  info=
}
Return


INIWRITE:
Iniwrite,%start%,%applicationname%.ini,Settings,start
Iniwrite,%timer%,%applicationname%.ini,Settings,timer
Iniwrite,%status%,%applicationname%.ini,Settings,status
counter=1
Loop,%rules%
{
  If (%A_Index%source="" And %A_Index%target="" And %A_Index%files="" And %A_Index%ignore="" And %A_Index%replace="")
  {
    IniDelete,%applicationname%.ini,%A_Index%,
    Continue
  }
  active:=%A_Index%active
  source:=%A_Index%source
  target:=%A_Index%target
  files:=%A_Index%files
  ignore:=%A_Index%ignore
  replace:=%A_Index%replace
  Iniwrite,%active%,%applicationname%.ini,%A_Index%,active
  Iniwrite,%source%,%applicationname%.ini,%A_Index%,source
  Iniwrite,%target%,%applicationname%.ini,%A_Index%,target
  Iniwrite,%files%,%applicationname%.ini,%A_Index%,files
  Iniwrite,%ignore%,%applicationname%.ini,%A_Index%,ignore
  Iniwrite,%replace%,%applicationname%.ini,%A_Index%,replace
  counter+=1
}
Gosub,INIREAD
Return


SETTINGS:
oldenabled:=enabled
enabled=0
insert=0
Gui,99:Destroy
Gui,99:Add,Tab,w580 h370,Rules|Options
Gui,99:Tab,1
Gui,99:Add,ListView,w560 h300 GLISTVIEW NoSort -Multi Checked,Active|Source|Target|Files|Ignore|Replace?
Gui,99:Default
Loop,%rules%
{
  If (%A_Index%source="" And %A_Index%target="" And %A_Index%files="" And %A_Index%ignore="" And %A_Index%replace="")
    Continue
  LV_ADD("","",%A_Index%source,%A_Index%target,%A_Index%files,%A_Index%ignore,%A_Index%replace)
  If %A_Index%active=1
    LV_Modify(LV_GetCount(),"Check")
}
LV_ADD("","","","","","","")

Gui,99:Tab,1
Gui,99:Add,Button,w75 x20 y340 GSETTINGSEDIT,&Edit
Gui,99:Add,Button,w75 x+5 GSETTINGSINSERT,&Insert
Gui,99:Add,Button,w75 x+5 GSETTINGSDELETE,&Delete

Gui,99:Add,Button,w75 x+5 GSETTINGSMOVEUP,Move &Up
Gui,99:Add,Button,w75 x+5 GSETTINGSMOVEDOWN,Move &Down

Gui,99:Tab,2
Gui,99:Add,GroupBox,x20 y50 w300,How often to check for new files?
Gui,99:Add,Edit,x30 yp+20 w75 votimer,% Floor(timer/1000)
Gui,99:Add,Text,x+5 yp+5,seconds

Gui,99:Add,GroupBox,x20 y+30 w300,Status
If status=1
  Gui,99:Add,CheckBox,xp+10 yp+20 vostatus Checked,Show status in the tray
Else
  Gui,99:Add,CheckBox,xp+10 yp+20 vostatus,Show status in the tray
Gui,99:Add,GroupBox,x20 y+30 w300,Startup
If start=1
  Gui,99:Add,CheckBox,xp+10 yp+20 vostart Checked,Start enabled
Else
  Gui,99:Add,CheckBox,xp+10 yp+20 vostart,Start enabled
Gui,99:Tab
Gui,99:Add,Button,x425 y340 w75 Default GSETTINGSOK,&OK
Gui,99:Add,Button,x+5 w75 GSETTINGSCANCEL,&Cancel

Gui,99:Show,w600 h390,%Applicationname% Settings
Return


LISTVIEW:
If A_GuiEvent=DoubleClick
  Gosub,SETTINGSEDIT
Return


SETTINGSINSERT:
row:=LV_GetNext(0,"Focused") 
insert=1
Gosub,SETTINGSEDIT
Return


SETTINGSDELETE:
row:=LV_GetNext(0,"Focused") 
If (row=LV_GetCount())
  Return
LV_Delete(row)
LV_Modify(row,"Select")
LV_Modify(row,"Focus")
Return


SETTINGSEDIT:
row:=LV_GetNext(0,"Focused")
If row=0
  Return
LV_GetText(source,row,2)
LV_GetText(target,row,3)
LV_GetText(files,row,4)
LV_GetText(ignore,row,5)
LV_GetText(replace,row,6)

Gui,98:Destroy
Gui,98:+ToolWindow

Gui,98:Add,GroupBox,x10 w560 h50,&Source - Where to move files from
Gui,98:Add,Edit,xp+10 yp+20 w460 vosource,%source%
Gui,98:Add,Button,x+5 yp w75 GBROWSESOURCE,Browse...

Gui,98:Add,GroupBox,x10 y+20 w560 h50,&Target - Where to move files to
Gui,98:Add,Edit,xp+10 yp+20 w460 votarget,%target%
Gui,98:Add,Button,x+5 yp w75 GBROWSETARGET,Browse...

Gui,98:Add,GroupBox,x10 y+20 w480 h70,&Files - What files to move
Gui,98:Add,Edit,xp+10 yp+20 w460 vofiles,%files%
Gui,98:Add,Text,y+5 300,Supports wildcards * ?. Example: *.jp*g

Gui,98:Add,GroupBox,x10 y+20 w480 h70,&Ignore - What (parts of) filenames to ignore
Gui,98:Add,Edit,xp+10 yp+20 w460 voignore,%ignore%
Gui,98:Add,Text,y+5 300,No wildcards. Example: jpg,jpeg,C:\Boot.ini

options=No|Yes|Ask|Rename|
StringReplace,options,options,%replace%,%replace%|
Gui,98:Add,GroupBox,x10 y+20 w300 h70,&Replace? - How to handle exsisting files
Gui,98:Add,DropDownList,xp+10 yp+20 w150 voreplace,%options%
Gui,98:Add,Text,y+5 300,No, Yes, Ask, Rename

Gui,98:Add,Button,x420 y340 w75 Default GEDITOK,&OK
Gui,98:Add,Button,x+5 w75 GEDITCANCEL,&Cancel

Gui,98:Show,w580 h370,%applicationname% Edit
Return


BROWSESOURCE:
Gui,+OwnDialogs
FileSelectFolder,folder,,3,Select a source folder:
If Not folder
  Return
ControlSetText,Edit1,%folder%,MoveOut Edit
Return


BROWSETARGET:
Gui,+OwnDialogs
FileSelectFolder,folder,,3,Select a target folder:
If Not folder
  Return
ControlSetText,Edit2,%folder%,MoveOut Edit
Return


EDITOK:
Gui,98:Submit,NoHide
If (osource="" Or otarget="" Or ofiles="")
  MsgBox,0,%applicationname% - Error,Please fill inn Source, Target and Files
Else
{
  Gui,99:Default
  If insert=1
    LV_Insert(row,"Focus","",osource,otarget,ofiles,oignore,oreplace)
  Else
  {    
    LV_Modify(row,"Focus","",osource,otarget,ofiles,oignore,oreplace)
    If (row=LV_GetCount())
      LV_ADD("","","","","","","")
  }
  Gosub,EDITCANCEL
}
Return


EDITCANCEL:
Gui,98:Destroy
insert=0
Return


SETTINGSMOVEUP:
row:=LV_GetNext(0,"Focused")
If row=1
  Return
If (row=LV_GetCount())
  Return
LV_GetText(source2,row,2)
LV_GetText(target2,row,3)
LV_GetText(files2,row,4)
LV_GetText(ignore2,row,5)
LV_GetText(replace2,row,6)

row-=1
LV_GetText(source1,row,2)
LV_GetText(target1,row,3)
LV_GetText(files1,row,4)
LV_GetText(ignore1,row,5)
LV_GetText(replace1,row,6)

LV_Modify(row,"Select","",source2,target2,files2,ignore2,replace2)
LV_Modify(row,"Focus")

row+=1
LV_Modify(row,"","",source1,target1,files1,ignore1,replace1)
Return


SETTINGSMOVEDOWN:
row:=LV_GetNext(0,"Focused") 
If (row>=LV_GetCount()-1)
  Return
LV_GetText(source2,row,2)
LV_GetText(target2,row,3)
LV_GetText(files2,row,4)
LV_GetText(ignore2,row,5)
LV_GetText(replace2,row,6)

row+=1
LV_GetText(source1,row,2)
LV_GetText(target1,row,3)
LV_GetText(files1,row,4)
LV_GetText(ignore1,row,5)
LV_GetText(replace1,row,6)

LV_Modify(row,"Select","",source2,target2,files2,ignore2,replace2)
LV_Modify(row,"Focus")

row-=1
LV_Modify(row,"","",source1,target1,files1,ignore1,replace1)
Return


SETTINGSOK:
Gui,99:Submit,NoHide
If otimer>0
  timer:=otimer*1000
status:=ostatus
start:=ostart
counter=1
Loop % LV_GetCount()
{
  checked:=LV_GetNext(counter-1,"Checked")
  If (checked=counter)
    %counter%active=1
  Else
    %counter%active=0
  LV_GetText(%counter%source,A_Index,2)
  LV_GetText(%counter%target,A_Index,3)
  LV_GetText(%counter%files,A_Index,4)
  LV_GetText(%counter%ignore,A_Index,5)
  LV_GetText(%counter%replace,A_Index,6)
  If (%counter%source="" And %counter%target="" And %counter%files="" And %counter%ignore="" And %counter%replace="")
    Continue
  counter+=1
}
rules:=counter
Gosub,INIWRITE
Gosub,SETTINGSCANCEL
Return


SETTINGSCANCEL:
Gui,98:Destroy
Gui,99:Destroy
enabled:=oldenabled
Return


TRAYMENU:
Menu,Tray,NoStandard
Menu,Tray,DeleteAll
Menu,Tray,Add,%applicationname%,SETTINGS
Menu,Tray,Add
Menu,Tray,Add,&Enabled,TOGGLE
Menu,Tray,Add
Menu,Tray,Add,&Settings...,SETTINGS
Menu,Tray,Add,&About...,ABOUT
Menu,Tray,Add,E&xit,EXIT
Menu,Tray,Default,%applicationname%
Menu,Tray,Tip,%applicationname%
Return


TOGGLE:
If enabled=1
{
  enabled=0
  Menu,Tray,UnCheck,&Enabled
  ;Menu,Tray,Icon,%applicationname%.exe,3
}
Else
{
  enabled=1
  Menu,Tray,Check,&Enabled
  ;Menu,Tray,Icon,%applicationname%.exe,1
}  
Return


ABOUT:
Gui,97:Destroy
Gui,97:Margin,20,20
Gui,97:Add,Picture,xm Icon1,%applicationname%.exe
Gui,97:Font,Bold
Gui,97:Add,Text,x+10 yp+10,%applicationname% v1.3
Gui,97:Font
Gui,97:Add,Text,y+10,Make rules to move files automatically.
Gui,97:Add,Text,y+10,- Rightclick the tray icon to configure
Gui,97:Add,Text,y+10,- Choose Settings to change rules and options
Gui,97:Add,Text,y+10,- Choose Enable to Start or Stop all the rules

Gui,97:Add,Picture,xm y+20 Icon5,%applicationname%.exe
Gui,97:Font,Bold
Gui,97:Add,Text,x+10 yp+10,1 Hour Software by Skrommel
Gui,97:Font
Gui,97:Add,Text,y+10,For more tools, information and donations, please visit 
Gui,97:Font,CBlue Underline
Gui,97:Add,Text,y+5 G1HOURSOFTWARE,www.1HourSoftware.com
Gui,97:Font

Gui,97:Add,Picture,xm y+20 Icon7,%applicationname%.exe
Gui,97:Font,Bold
Gui,97:Add,Text,x+10 yp+10,DonationCoder
Gui,97:Font
Gui,97:Add,Text,y+10,Please support the contributors at
Gui,97:Font,CBlue Underline
Gui,97:Add,Text,y+5 GDONATIONCODER,www.DonationCoder.com
Gui,97:Font

Gui,97:Add,Picture,xm y+20 Icon6,%applicationname%.exe
Gui,97:Font,Bold
Gui,97:Add,Text,x+10 yp+10,AutoHotkey
Gui,97:Font
Gui,97:Add,Text,y+10,This tool was made using the powerful
Gui,97:Font,CBlue Underline
Gui,97:Add,Text,y+5 GAUTOHOTKEY,www.AutoHotkey.com
Gui,97:Font

Gui,97:Show,,%applicationname% About
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

97GuiClose:
  Gui,97:Destroy
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
ExitApp
