#SingleInstance,Force
#Persistent

ScriptName = VDesktops
ScriptVersion = 1.003

grupoactual = 0
changer = False
gosub Hide_Groups
SetTitleMatchMode 2
menu,Tray,add,Program Reload,ProgramReload
menu,Tray,add,Program Exit,ProgramExit
menu,tray,nostandard
menu,tray,tip,%ScriptName% V%scriptVersion%
return

ProgramReload:
GoSub Exiting
reload

ProgramExit:
GoSub Exiting
exitapp

#0::
Button0:
gosub MostraGrupos
grupoactual = 0
return

LWin & Right::
result:=mod(grupoactual+1,4)
gosub Button%result%
return

LWin & left::
result:=mod(grupoactual-1,4)
if(result=-1)
  result=3
gosub Button%result%
return

#c::
if changer = false
  {
  changer = true
  Gosub ShowChanger
  return
  }
changer = false
GoSub HideChanger
return

#1::
Button1:
GoSub,Hide_Groups
GrupoActual = 1
WinShow,ahk_group Grupo1
GroupActivate,Grupo1
return

+#1::
WinIdent:=WinExist("A")
GroupAdd,Grupo1,ahk_id %WinIdent%
WinGetTitle,WinTitle,ahk_id %WinIdent%
ToolTip =%WinTitle% -> Group 1
if GrupoActual != 1
  gosub,Button%GrupoActual%
Gosub ToolTip
return

#2::
Button2:
GoSub,Hide_Groups
GrupoActual = 2
WinShow,ahk_group Grupo2
GroupActivate,Grupo2
return

+#2::
WinIdent:=WinExist("A")
GroupAdd,Grupo2,ahk_id %WinIdent%
WinGetTitle,WinTitle,ahk_id %WinIdent%
ToolTip =%WinTitle% -> Group 2
if GrupoActual != 2
  gosub,Button%GrupoActual%
Gosub ToolTip
return

#3::
Button3:
GoSub,Hide_Groups
GrupoActual = 3
WinShow,ahk_group Grupo3
GroupActivate,Grupo3
return

+#3::
WinIdent:=WinExist("A")
GroupAdd,Grupo3,ahk_id %WinIdent%
WinGetTitle,WinTitle,ahk_id %WinIdent%
ToolTip =%WinTitle% -> Group 3
if GrupoActual != 3
  gosub,Button%GrupoActual%
Gosub ToolTip
return


Hide_Groups:
  loop 9
  {
  WinHide,ahk_group Grupo%A_Index%
  }
return 

MostraGrupos:
  loop 9
  {
  WinShow,ahk_group Grupo%A_Index%
  }
return 

TOOLTIP:
  ToolTip,%ToolTip%
  SetTimer,ToolTipOFF,1000
Return

TOOLTIPOFF:
  ToolTip,
  SetTimer,ToolTipOFF,Off
Return

ShowChanger:
Gui,+ToolWindow +AlwaysOnTop -Disabled -SysMenu -Caption
Gui, Add, Button, x0 y0 w30 h30,1      
Gui, Add, Button, x30 y0 w30 h30,2 
Gui, Add, Button, x60 y0 w30 h30,3 
Gui, Add, Button, x90 y0 w30 h30,0
Gui, Color, EEAAEE
Gui, +Lastfound ; Make the GUI window the last found window. 
WinSet, TransColor, EEAAEE
SysGet,Monitor,MonitorWorkArea,1
MonitorBottom := MonitorBottom - 30
Gui, Show, x%MonitorLeft% y%MonitorBottom% h30 w120, JGPaiva
Return

HideChanger:
Gui,Destroy
return

GuiClose:
return

OnExit,Exiting

Exiting:
  loop 9
  {
  WinShow,ahk_group Grupo%A_Index%
  }
return
