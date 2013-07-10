;LabelControl.ahk
; Overlays controls with a Number for direct access via Ctrl-Number
;Skrommel @2006

#SingleInstance,Force
#Persistent
#NoEnv
SetWinDelay,0
SetControlDelay,0
SetBatchLines,-1

applicationname=LabelControl

Gosub,INIREAD
Gosub,TRAYMENU

SysGet,thumbwidth,10 ;SM_CXHTHUMB
thumbwidth+=5
same=8
down=0
;WM_CTLCOLOREDIT:=0x0133
;OnMessage(0x0133,"WM_CTLCOLOREDIT")


ScrollLock::
If down=1
  Return
down=1

;----- Create window for the overlays
WinMove,ahk_id %guiid%,,0,0,0,0
Gui,Destroy
WinGet,winid,ID,A
WinGetPos,winx,winy,winw,winh,ahk_id %winid%
Gui,-Caption +Border +ToolWindow +AlwaysOnTop
Gui,Color,EEEEEE
Gui,Margin,0,0
Gui,Show,x0 y0 w0 h0 NoActivate,%applicationname%Gui
WinGet,guiid,ID,%applicationname%Gui
WinSet,TransColor,EEEEEE,ahk_id %guiid%
WinMove,ahk_id %guiid%,,-%winw%,-%winh%,%winw%,%winh%
WinMove,ahk_id %guiid%,,%winx%,%winy%

;----- Find menuitems
lines=
hMenu:=DllCall("GetMenu","UInt",winid)
menuitemcount:=DllCall("GetMenuItemCount","UInt",hMenu)
VarSetCapacity( rect, 16, 0 )
Loop,%menuitemcount%
{
  menuitem:=A_Index-1
  DllCall("GetMenuItemRect","UInt",winid,"UInt",hMenu,"UInt",menuitem,"UInt",&rect)
  x1 := DecodeInteger( "int4", &rect, 0 )
  y1 := DecodeInteger( "int4", &rect, 4 )
;  x2 := DecodeInteger( "int4", &rect, 8 )
;  y2 := DecodeInteger( "int4", &rect, 12 )
  line:=100000000+Floor((y1-winy)/same)*10000+x1-winx+4
  lines=%lines%%line%%A_Tab%0%A_Tab%WindowMenu`n
}


/*
;----- Find titlebar buttons
TITLEBARINFO
{
  DWORD cbSize;
  RECT rcTitleBar;
  DWORD rgstate[CCHILDREN_TITLEBAR+1];
}
DllCall("GetTitleBarInfo",UInt,winid,PTITLEBARINFO,pti)
);

Members:
  cbSize
Specifies the size, in bytes, of the structure. The caller must set this to sizeof(TITLEBARINFO).
  rcTitleBar
Pointer to a RECT structure that receives the coordinates of the title bar. These coordinates include all title-bar elements except the window menu.
  rgstate
Pointer to an array that receives a DWORD value for each element of the title bar. The following are the title bar elements represented by the array. Index Title Bar Element
0 The title bar itself.
1 Reserved.
2 Minimize button.
3 Maximize button.
4 Help button.
5 Close button.

Each array element is a combination of one or more of the following values.

Value Meaning
STATE_SYSTEM_FOCUSABLE The element can accept the focus.
STATE_SYSTEM_INVISIBLE The element is invisible.
STATE_SYSTEM_OFFSCREEN The element has no visible representation.
STATE_SYSTEM_UNAVAILABLE The element is unavailable.
STATE_SYSTEM_PRESSED The element is in the pressed state.
*/

;----- Find controls
WinGet,ctrls,ControlList,ahk_id %winid%
Loop,Parse,ctrls,`n
{
  class:=A_LoopField
  If class Not Contains %ignorecontrols%
  If class Contains %allcontrols%
  {
    ControlGet,ctrlid,Hwnd,,%class%,ahk_id %winid%
    ControlGet,style,Style,,,ahk_id %ctrlid%
    ControlGet,enabled,Enabled,,,ahk_id %ctrlid%
    ControlGet,visible,Visible,,,ahk_id %ctrlid%
    text=
    If (InStr(class,"Link"))
      ControlGetText,text,,ahk_id %ctrlid%
    SetFormat,Integer,Hex
    parent:=DllCall("GetParent","uint",ctrlid)
    WinGetClass,parentclass,ahk_id %parent%
    StringRight,style,style,1
    SetFormat,Integer,D

;    If !(InStr(class,"Edit") And InStr(parentclass,"Combo"))
    If !(InStr(class,"Link") And text="")
    If !(InStr(class,"Static"))
    If !(InStr(class,"Button") And style=0x7)
    If visible=1
    If enabled=1
    {
      ControlGetPos,ctrlx,ctrly,ctrlw,ctrlh,%class%,ahk_id %winid%
      If class Contains %toolbarcontrols%
        Gosub,TOOLBARBUTTONS
      Else
      If class Contains %tabcontrols%
        Gosub,TABITEMS
      Else
      If class Contains %headercontrols%
        Gosub,HEADERITEMS
      Else
      If class Contains SysListView
        Gosub,LISTVIEWITEMS
      Else
      If class Contains TreeView
        Gosub,TREEVIEWITEMS
      Else
      If class Contains %searchcontrols%
        Gosub,SEARCHCONTROL         
      Else
      If class Contains Combo
      {
        line:=100000000+Floor(ctrly/same)*10000+ctrlx
        lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
        line:=100000000+Floor(ctrly/same)*10000+ctrlx+ctrlw-thumbwidth
        lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
      }
      Else
      {
        line:=100000000+Floor(ctrly/same)*10000+ctrlx
        lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
      }
    }
  }
}
Sort,lines
StringTrimRight,lines,lines,1

;----- Display numbers
counter=-1
Loop,Parse,lines,`n
{
  StringSplit,part_,A_LoopField,%A_Tab%
  StringMid,ctrly,part_1,2,4
  StringMid,ctrlx,part_1,6,4
  olddispx:=dispx
  olddispy:=dispy
  dispx:=ctrlx-4
  dispy:=ctrly*same-4
  If (olddispx=dispx And olddispy=dispy)
    Continue
  counter+=1
  GUi,Add,Edit,x%dispx% y%dispy%,%counter%
  control%counter%x:=ctrlx+5
  control%counter%y:=ctrly*same+5
  control%counter%class:=part_3
  control%counter%id:=part_2
}

;ToolTip,%lines%

;----- Input the number
number=
Loop
{
  Sleep,0
  digit=
  Loop
  {
    Sleep,0
    Input, key, L1
   If key is number
    {
      number=%digit%%key%
      If (StrLen(number)>StrLen(counter))
        number=
      ToolTip,%number%
      Sleep,200
    }
   If ErrorLevel = NewInput
      break
    digit=%number%
  }
  GetKeyState,state,ScrollLock,P
  If state=U
    Break
}
Return


ScrollLock Up::
If down=0
  Return
Input
Gui,Destroy
ToolTip,
down=0
If number=
  Return

;----- Activate the control
MouseGetPos,mousex,mousey
ctrlx:=control%number%x
ctrly:=control%number%y
class:=control%number%class
ctrlid:=control%number%id

If class Contains %focuscontrols%
  ControlFocus,,ahk_id %ctrlid%
Else
;If class Contains %tabcontrols%
;{
;  ControlFocus,,ahk_id %ctrlid%
;  Send,^{Tab}
;}
;Else
;If class Contains %toolbarcontrols%
  MouseClick,Left,% ctrlx+4,% ctrly+4,1,0
;Else
;  MouseClick,Left,%ctrlx%,%ctrly%,1,0
;  ControlClick,,ahk_id %ctrlid%

If movemouse=1
  MouseMove,% ctrlx+4,% ctrly+4,0
Else
  MouseMove,%mousex%,%mousey%,0
Return


LISTVIEWITEMS:
;SetFormat,Integer,D
hw_target:=winid
x1=
x2=
y1=
LVM_GETITEMCOUNT:=0x1004
LVM_FIRST:=0x1000
LVM_GETSUBITEMRECT:=LVM_FIRST + 56
LVM_GETITEMRECT:=0x1000
LVIR_BOUNDS:=LVM_FIRST + 14
LVIR_ICON:=0x0001
LVIR_LABEL:=0x0002
LVIR_SELECTBOUNDS:=0x0003
LVS_SORTASCENDING:=0x10
LVS_SORTDESCENDING:=0x20
LVM_SCROLL:=LVM_FIRST + 20
LVM_GETITEMRECT:=4110
LVM_GETITEMPOSITION:=4112

LVM_GETITEMCOUNT:=4100
SendMessage,%LVM_GETITEMCOUNT%,0,0,%class%,ahk_id %hw_target%
buttons:=ErrorLevel
VarSetCapacity( rect, 16, 0 )

WinGet, pid_target, PID, ahk_id %hw_target%
hp_explorer := DllCall( "OpenProcess"
                    , "uint", 0x18                           ; PROCESS_VM_OPERATION|PROCESS_VM_READ
                    , "int", false
                    , "uint", pid_target )

Loop,%buttons%
{
  remote_buffer := DllCall( "VirtualAllocEx"
                      , "uint", hp_explorer
                      , "uint", 0
                      , "uint", 0x1000
                      , "uint", 0x1000                        ; MEM_COMMIT
                      , "uint", 0x4 )                           ; PAGE_READWRITE
 
  SendMessage,%LVM_GETITEMRECT%,% A_Index-1,%remote_buffer%,%class%,ahk_id %hw_target%

  result := DllCall( "ReadProcessMemory"
                , "uint", hp_explorer
                , "uint", remote_buffer
                , "uint", &rect
                , "uint", 16
                , "uint", 0 )
  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1 := DecodeInteger( "int4", &rect, 0 )
  x2 := DecodeInteger( "int4", &rect, 8 )
  y1 := DecodeInteger( "int4", &rect, 4 )
;  y2 := DecodeInteger( "int4", &rect, 12 )
;  x1+=0
;  x2+=0
;  lv_row_w := x2-x1
;  lv_row_h := y2-y1
;   MsgBox, lv_row_h: %lv_row_h% y1: %y1% y2: %y2%
;   MsgBox, lv_row_w: %lv_row_h% x1: %x1% x2: %x2%
;
  If (x1=oldx1 And y1=oldy1 And x2=oldx2)
    Continue
  If (x2-x1<10)
    Continue
  If (x1>ctrlw Or y1>ctrlh Or x1<0 Or y1<0)
    Continue

x1:=x1+20
y1:=y1+4
  line:=100000000+Floor((ctrly+y1)/same)*10000+ctrlx+x1 ;+thumbwidth
  lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n

result := DllCall( "VirtualFreeEx"
                 , "uint", hp_explorer
                 , "uint", remote_buffer
                 , "uint", 0
                 , "uint", 0x8000 )                           ; MEM_RELEASE
}
result := DllCall( "CloseHandle", "uint", hp_explorer )
Return



TREEVIEWITEMS:
;SetFormat,Integer,D
hw_target:=winid
x1=
x2=
y1=
LVM_GETITEMCOUNT:=0x1004
LVM_FIRST:=0x1000
LVM_GETSUBITEMRECT:=LVM_FIRST + 56
LVM_GETITEMRECT:=0x1000
LVIR_BOUNDS:=LVM_FIRST + 14
LVIR_ICON:=0x0001
LVIR_LABEL:=0x0002
LVIR_SELECTBOUNDS:=0x0003
LVS_SORTASCENDING:=0x10
LVS_SORTDESCENDING:=0x20
LVM_SCROLL:=LVM_FIRST + 20
LVM_GETITEMRECT:=4110
LVM_GETITEMPOSITION:=4112
TVM_GETITEMRECT:=4356
TVM_GETVISIBLECOUNT:=4368

SendMessage,%TVM_GETVISIBLECOUNT%,0,0,%class%,ahk_id %hw_target%
buttons=%ErrorLevel%


;TVM_GETNEXTITEM TVGN_FIRSTVISIBLE
SendMessage,0x110A,5,0,%class%,ahk_id %hw_target%
item=%ErrorLevel%

TVM_GETITEMHEIGHT := 0x1100 + 28
SendMessage,%TVM_GETITEMHEIGHT%,0,0,%class%,ahk_id %hw_target%
nodeheight=%ErrorLevel%

/*
VarSetCapacity( rect, 16, 0 )

WinGet, pid_target, PID, ahk_id %hw_target%

hp_explorer := DllCall( "OpenProcess"
                    , "uint", 0x18                           ; PROCESS_VM_OPERATION|PROCESS_VM_READ
                    , "int", false
                    , "uint", pid_target )
*/

y1:=-nodeheight+4
Loop,%buttons%
{
  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1:=1
  x2:=11
  y1+=%nodeheight%
;MsgBox,%y1% - %nodeheight%

/*

  remote_buffer := DllCall( "VirtualAllocEx"
                      , "uint", hp_explorer
                      , "uint", 0
                      , "uint", 0x1000
                      , "uint", 0x1000                        ; MEM_COMMIT
                      , "uint", 0x4 )                           ; PAGE_READWRITE
 
  ;get root
  SendMessage,0x110A,0,0,%class%,ahk_id %hw_target%
  root:=ErrorLevel
   
  ;get current selection
  SendMessage,0x110A,9,0,%class%,ahk_id %hw_target%
  item:=ErrorLevel

  InsertInteger(item,rect,0)
  result  := DllCall( "WriteProcessMemory"
                  ,"uint", hp_explorer
                  ,"uint", remote_buffer
                  ,"uint", &rect
                  ,"uint", 16
                  ,"uint", 0 )

  ;get rectangle
  SendMessage,%TVM_GETITEMRECT%,1,%remote_buffer%,%class%,ahk_id %hw_target%

  result := DllCall( "ReadProcessMemory"
                , "uint", hp_explorer
                , "uint", remote_buffer
                , "uint", &rect
                , "uint", 16
                , "uint", 0 )
  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1 := DecodeInteger( "int4", &rect, 0 )
  x2 := DecodeInteger( "int4", &rect, 8 )
  y1 := DecodeInteger( "int4", &rect, 4 )
MsgBox,%item%-%x1%-%x2%-%y1%
;  y2 := DecodeInteger( "int4", &rect, 12 )
;  x1+=0
;  x2+=0
;  lv_row_w := x2-x1
;  lv_row_h := y2-y1
;   MsgBox, lv_row_h: %lv_row_h% y1: %y1% y2: %y2%
;   MsgBox, lv_row_w: %lv_row_h% x1: %x1% x2: %x2%
;

*/
  If (x1=oldx1 And y1=oldy1 And x2=oldx2)
    Continue
  If (x2-x1<10)
    Continue
  If (x1>ctrlw Or y1>ctrlh)
    Continue

x1:=x1+20
  line:=100000000+Floor((ctrly+y1)/same)*10000+ctrlx+x1 ;+thumbwidth
  lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n

/*
result := DllCall( "VirtualFreeEx"
                 , "uint", hp_explorer
                 , "uint", remote_buffer
                 , "uint", 0
                 , "uint", 0x8000 )                           ; MEM_RELEASE
*/
}
;result := DllCall( "CloseHandle", "uint", hp_explorer )
Return




TREEVIEWITEMS_OLD:
;SetFormat,Integer,D
hw_target:=winid
WinGet, pid_target, PID, ahk_id %hw_target%
x1=
x2=
y1=
LVM_FIRST:=0x1000
LVM_GETSUBITEMRECT:=LVM_FIRST + 56
LVM_GETITEMRECT:=0x1000
LVIR_BOUNDS:=LVM_FIRST + 14
LVIR_ICON:=0x0001
LVIR_LABEL:=0x0002
LVIR_SELECTBOUNDS:=0x0003
LVS_SORTASCENDING:=0x10
LVS_SORTDESCENDING:=0x20
LVM_SCROLL:=LVM_FIRST + 20
TVM_GETITEMRECT:=4356

VarSetCapacity(rect,16,1)

hp_explorer := DllCall( "OpenProcess"
                    , "uint", 0x18                           ; PROCESS_VM_OPERATION|PROCESS_VM_READ
                    , "int", false
                    , "uint", pid_target )

Loop,1
{
  remote_buffer := DllCall( "VirtualAllocEx"
                    , "uint", hp_explorer
                    , "uint", 0
                    , "uint", 0x1000
                    , "uint", 0x1000                        ; MEM_COMMIT
                    , "uint", 0x4 )                           ; PAGE_READWRITE

  ;get root
  SendMessage,0x110A,0,0,%class%,ahk_id %hw_target%
  root:=ErrorLevel
   
  ;get current selection
  SendMessage,0x110A,9,0,%class%,ahk_id %hw_target%
  item:=ErrorLevel

  InsertInteger(root,rect,0)
ControlGet,ctrlid,Hwnd,,%class%,ahk_id %hw_target%
;DllCall("SendMessage",UInt,ctrlid,UInt,TVM_GETITEMRECT,UInt,1,UInt,rect)

  SendMessage,%TVM_GETITEMRECT%,1,%rect%,,ahk_id %ctrlid% ;%hw_target%

  result := DllCall( "ReadProcessMemory"
                , "uint", hp_explorer
                , "uint", remote_buffer
                , "uint", &rect
                , "uint", 16
                , "uint", 0 )

  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1 := DecodeInteger( "int4", &rect, 0 )
  x2 := DecodeInteger( "int4", &rect, 8 )
  y1 := DecodeInteger( "int4", &rect, 4 )
MsgBox,%root%;%item%;%x1%;%x2%;%y1%
;  y2 := DecodeInteger( "int4", &rect, 12 )
;  x1+=0
;  x2+=0
;  lv_row_w := x2-x1
;  lv_row_h := y2-y1
;   MsgBox, lv_row_h: %lv_row_h% y1: %y1% y2: %y2%
;   MsgBox, lv_row_w: %lv_row_h% x1: %x1% x2: %x2%
;
;  If (x1=oldx1 And y1=oldy1 And x2=oldx2)
;    Continue
;  If (x2-x1<10)
;    Continue
;  If (x1>ctrlw Or y1>ctrlh)
;    Continue
  line:=100000000+Floor((ctrly+y1)/same)*10000+ctrlx+x1 ;+thumbwidth
  lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n

  result := DllCall( "VirtualFreeEx"
                   , "uint", hp_explorer
                   , "uint", remote_buffer
                   , "uint", 0
                   , "uint", 0x8000 )                           ; MEM_RELEASE
}
result := DllCall( "CloseHandle", "uint", hp_explorer )
Return





TREEVIEWITEMS_NEW:
   GetHandles()   ;get handles of Explorer and TreeView
   MsgBox % GetTVPath()   
return

;------------------------------------------------------------------------------------------------
; Get the text of the root item (usualy My Documents)
GetTVPath()
{
   global
   local bufID, r_tvi, txt, item, epath, root

   ;open remote buffers
   bufID   := RemoteBuf_Open(hwEx, 64)
    bufAdr   := RemoteBuf_GetAdr(bufID)

   r_tvi   := RemoteBuf_Open(hwEx, 40)
   r_adr   := RemoteBuf_GetAdr(r_tvi)

   ;get root
   SendMessage 0x110A,   0, 0, ,ahk_id %hwTV%
   root = %ErrorLevel%
   
   ;get current selection
   SendMessage 0x110A,   9, 0, ,ahk_id %hwTV%
   item = %ErrorLevel%


   VarSetCapacity(sTV,   40, 1)     ;10x4 = 40
   InsertInteger(0x011,   sTV, 0)    ;set mask to TVIF_TEXT | TVIF_HANDLE  = 0x001 | 0x0010
   InsertInteger(bufAdr,  sTV, 16)  ;set txt pointer
   InsertInteger(127,     sTV, 20)  ;set txt size
 
 
  TVM_GETITEMRECT:=4356

TVM_GETITEMCOUNT:=0x1004

   VarSetCapacity(txt, 64, 1)
   loop
   {
      ;set TVITEM item handle
      InsertInteger(item, sTV, 4)   
      RemoteBuf_Write(r_tvi, sTV, 40)

      ;send tv_getitem message
      SendMessage 0x110C, 0, r_adr ,, ahk_id %hwTV%
      hItem:=ErrorLevel
      ;read from remote buffer and append the path
      RemoteBuf_Read(bufID, txt, 64 )

      SendMessage,%TVM_GETITEMRECT%,%hItem%,%r_adr%,,ahk_id %hwTV%
     
  x1 := DecodeInteger( "int4", &r_adr, 0 )
  x2 := DecodeInteger( "int4", &r_adr, 8 )
  y1 := DecodeInteger( "int4", &r_adr, 4 )

      MsgBox,%x1% - %hItem%


      ;check for the drive
      StringGetPos i, txt, :
      if i > 0
      {
         StringMid txt, txt, i, 2
         epath = %txt%\%epath%
         break
      }
      else
         epath = %txt%\%epath%

      ;get parent   TVGN_PARENT = 3
      SendMessage 0x110A,   3, item, ,ahk_id %hwTV%
      item = %ErrorLevel%
      if (item = root)
         break
   }

   RemoteBuf_Close( bufID )
   RemoteBuf_Close( r_tvi )

   StringLeft epath, epath, strlen(epath)-1
   return epath
}

;------------------------------------------------------------------------------------------------
; Get Explorer and its TreeView handle
GetHandles()
{
   global
   ;get tree view handle
   hwEx   := WinExist("ahk_class ExploreWClass")

   hwTV   := FindWindowExId(hwEx, "BaseBar", 0)
   hwTV   := FindWindowExID(hwTV, "ReBarWindow32", 0)
   hwTV   := FindWindowExID(hwTV, "SysTreeView32", 100)
}

;------------------------------------------------------------------------------------------------
; Iterate through controls with the same class, find the one with ctrlID and return its handle
; Used for finding a specific control
;
FindWindowExID(dlg, className, ctrlId)
{
   local ctrl, id

   ctrl = 0
   Loop
   {
      ctrl := DllCall("FindWindowEx", "uint", dlg, "uint", ctrl, "str", className, "uint", 0 )
      if (ctrlId = "0")
      {
         return ctrl
      }

      if (ctrl != "0")
      {
         id := DllCall( "GetDlgCtrlID", "uint", ctrl )
         if (id = ctrlId)
            return ctrl             
      }
      else
         return 0
   }

}


InsertInteger(pInteger, ByRef pDest, pOffset = 0, pSize = 4)
; The caller must ensure that pDest has sufficient capacity.  To preserve any existing contents in pDest,
; only pSize number of bytes starting at pOffset are altered in it.
{
   Loop %pSize%  ; Copy each byte in the integer into the structure as raw binary data.
      DllCall("RtlFillMemory", "UInt", &pDest + pOffset + A_Index-1, "UInt", 1, "UChar", pInteger >> 8*(A_Index-1) & 0xFF)
}

;---------------------------------------------
; Open remote buffer
;
; ARGUMENTS: p_handle   - HWND of buffer host
;          p_size      - Size of the buffer
;
; Returns   buffer handle (>0)
;         -1 if unable to open process
;         -2 if unable to get memory
;--------------------------------------------
RemoteBuf_Open(p_handle, p_size)
{
   global
   local proc_hwnd, bufAdr, pid

   
   WinGet, pid, PID, ahk_id %p_handle%
   proc_hwnd := DllCall( "OpenProcess"
                         , "uint", 0x38            ; PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE (0x0020)
                         , "int", false
                         , "uint", pid )

   if proc_hwnd = 0
      return -1
       
   bufAdr   := DllCall( "VirtualAllocEx"
                        , "uint", proc_hwnd
                        , "uint", 0
                        , "uint", p_size         ; SIZE
                        , "uint", 0x1000            ; MEM_COMMIT
                        , "uint", 0x4 )            ; PAGE_READWRITE
   
   if bufAdr =
      return -2

   RemoteBuf_idx += 1
   RemoteBuf_%RemoteBuf_idx%_handle  := proc_hwnd
   RemoteBuf_%RemoteBuf_idx%_size     := p_size
   RemoteBuf_%RemoteBuf_idx%_adr     := bufAdr

   return RemoteBuf_idx
}

;----------------------------------------------------
; Close remote buffer.
;----------------------------------------------------
RemoteBuf_Close(p_bufHandle)
{
   global
   local handle, adr

   handle   := RemoteBuf_%p_bufHandle%_handle
   adr      := RemoteBuf_%p_bufHandle%_adr

   if handle = 0
      return 0

    result := DllCall( "VirtualFreeEx"
                     , "uint", handle
                     , "uint", adr
                     , "uint", 0
                     , "uint", 0x8000 )            ; MEM_RELEASE
   

   DllCall( "CloseHandle", "uint", handle )

   RemoteBuf_%p_bufHandle%_adr       =
   RemoteBuf_%RemoteBuf_idx%_size    =
   RemoteBuf_%RemoteBuf_idx%_handle =

   return result
}
;----------------------------------------------------
; Read remote buffer and return buffer
;----------------------------------------------------
RemoteBuf_Read(p_bufHandle, byref p_localBuf, p_size, p_offset = 0)
{
   global
   local handle, adr, size, localBuf

   handle   := RemoteBuf_%p_bufHandle%_handle
   adr      := RemoteBuf_%p_bufHandle%_adr
   size   := RemoteBuf_%p_bufHandle%_size


   if (handle = 0) or (adr = 0) or (offset >= size)
      return -1

    result := DllCall( "ReadProcessMemory"
                  , "uint", handle
                  , "uint", adr + p_offset
                  , "uint", &p_localBuf
                  , "uint", p_size
                  , "uint", 0 )
   
   return result
}

;----------------------------------------------------
; Write to remote buffer, local buffer p_local.
;----------------------------------------------------
RemoteBuf_Write(p_bufHandle, byref p_local, p_size, p_offset=0)
{
   global
   local handle, adr, size

   handle   := RemoteBuf_%p_bufHandle%_handle
   adr      := RemoteBuf_%p_bufHandle%_adr
   size   := RemoteBuf_%p_bufHandle%_size
   

   if (handle = 0) or (adr = 0) or (offset >= size)
      return -1

   result  := DllCall( "WriteProcessMemory"
                  ,"uint", handle
                  ,"uint", adr + p_offset
                  ,"uint", &p_local
                  ,"uint", p_size
                  ,"uint", 0 )

   return result
}


RemoteBuf_GetAdr(p_handle)
{
   global
   return    RemoteBuf_%p_handle%_adr
}

RemoteBuf_GetSize(p_handle)
{
   global
   return    RemoteBuf_%p_handle%_size
}



TOOLBARBUTTONS:
;SetFormat,Integer,D
hw_target:=winid
WinGet, pid_target, PID, ahk_id %hw_target%
hp_explorer := DllCall( "OpenProcess"
                    , "uint", 0x18                           ; PROCESS_VM_OPERATION|PROCESS_VM_READ
                    , "int", false
                    , "uint", pid_target )
remote_buffer := DllCall( "VirtualAllocEx"
                    , "uint", hp_explorer
                    , "uint", 0
                    , "uint", 0x1000
                    , "uint", 0x1000                        ; MEM_COMMIT
                    , "uint", 0x4 )                           ; PAGE_READWRITE
x1=
x2=
y1=
WM_USER:=0x400
TB_GETITEMRECT:=WM_USER+29
TB_BUTTONCOUNT:=WM_USER+24
SendMessage,%TB_BUTTONCOUNT%,0,0,%class%,ahk_id %hw_target%
buttons:=ErrorLevel
VarSetCapacity( rect, 16, 0 )

Loop,%buttons%
{
  SendMessage,%TB_GETITEMRECT%,% A_Index-1,remote_buffer,%class%,ahk_id %hw_target%
 
  result := DllCall( "ReadProcessMemory"
                , "uint", hp_explorer
                , "uint", remote_buffer
                , "uint", &rect
                , "uint", 16
                , "uint", 0 )
  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1 := DecodeInteger( "int4", &rect, 0 )
  x2 := DecodeInteger( "int4", &rect, 8 )
  y1 := DecodeInteger( "int4", &rect, 4 )
;  x1+=0
;  x2+=0
;  lv_row_w := x2-x1
;  y2 := DecodeInteger( "int4", &rect, 12 )
;  lv_row_h := y2-y1
;   MsgBox, lv_row_h: %lv_row_h% y1: %y1% y2: %y2%
;   MsgBox, lv_row_w: %lv_row_h% x1: %x1% x2: %x2%

  If (x1=oldx1 And y1=oldy1 And x2=oldx2)
    Continue
  If (x2-x1<10)
    Continue
  If (x1>ctrlw Or y1>ctrlh)
    Continue
  line:=100000000+Floor((ctrly+y1)/same)*10000+ctrlx+x1
  lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
}
result := DllCall( "VirtualFreeEx"
                 , "uint", hp_explorer
                 , "uint", remote_buffer
                 , "uint", 0
                 , "uint", 0x8000 )                           ; MEM_RELEASE
result := DllCall( "CloseHandle", "uint", hp_explorer )
Return


TABITEMS:
;SetFormat,Integer,D
hw_target:=winid
WinGet, pid_target, PID, ahk_id %hw_target%
hp_explorer := DllCall( "OpenProcess"
                    , "uint", 0x18                           ; PROCESS_VM_OPERATION|PROCESS_VM_READ
                    , "int", false
                    , "uint", pid_target )
remote_buffer := DllCall( "VirtualAllocEx"
                    , "uint", hp_explorer
                    , "uint", 0
                    , "uint", 0x1000
                    , "uint", 0x1000                        ; MEM_COMMIT
                    , "uint", 0x4 )                           ; PAGE_READWRITE
x1=
x2=
y1=
WM_USER:=0x400
TCM_GETITEMRECT:=0x130A
TCM_GETITEMCOUNT:=0x1304
SendMessage,%TCM_GETITEMCOUNT%,0,0,%class%,ahk_id %hw_target%
buttons:=ErrorLevel
VarSetCapacity( rect, 16, 0 )

Loop,%buttons%
{
  SendMessage,%TCM_GETITEMRECT%,% A_Index-1,remote_buffer,%class%,ahk_id %hw_target%
 
  result := DllCall( "ReadProcessMemory"
                , "uint", hp_explorer
                , "uint", remote_buffer
                , "uint", &rect
                , "uint", 16
                , "uint", 0 )
  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1 := DecodeInteger( "int4", &rect, 0 )
  x2 := DecodeInteger( "int4", &rect, 8 )
  y1 := DecodeInteger( "int4", &rect, 4 )
;  x1+=0
;  x2+=0
;  lv_row_w := x2-x1
;  y2 := DecodeInteger( "int4", &rect, 12 )
;  lv_row_h := y2-y1
;   MsgBox, lv_row_h: %lv_row_h% y1: %y1% y2: %y2%
;   MsgBox, lv_row_w: %lv_row_h% x1: %x1% x2: %x2%

  If (x1=oldx1 And y1=oldy1 And x2=oldx2)
    Continue
  If (x2-x1<10)
    Continue
  If (x1>ctrlw Or y1>ctrlh)
    Continue
  line:=100000000+Floor((ctrly+y1)/same)*10000+ctrlx+x1
  lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
}
result := DllCall( "VirtualFreeEx"
                 , "uint", hp_explorer
                 , "uint", remote_buffer
                 , "uint", 0
                 , "uint", 0x8000 )                           ; MEM_RELEASE
result := DllCall( "CloseHandle", "uint", hp_explorer )
Return


HEADERITEMS:
;SetFormat,Integer,D
hw_target:=winid
WinGet, pid_target, PID, ahk_id %hw_target%
hp_explorer := DllCall( "OpenProcess"
                    , "uint", 0x18                           ; PROCESS_VM_OPERATION|PROCESS_VM_READ
                    , "int", false
                    , "uint", pid_target )
remote_buffer := DllCall( "VirtualAllocEx"
                    , "uint", hp_explorer
                    , "uint", 0
                    , "uint", 0x1000
                    , "uint", 0x1000                        ; MEM_COMMIT
                    , "uint", 0x4 )                           ; PAGE_READWRITE
x1=
x2=
y1=
WM_USER:=0x400
HDM_FIRST:=0x1200
HDM_GETITEMRECT:=HDM_FIRST+7
HDM_GETITEMCOUNT:=4608
SendMessage,%HDM_GETITEMCOUNT%,0,0,%class%,ahk_id %hw_target%
buttons:=ErrorLevel
;MsgBox,%buttons%
VarSetCapacity( rect, 16, 0 )

Loop,%buttons%
{
  SendMessage,%HDM_GETITEMRECT%,% A_Index-1,remote_buffer,%class%,ahk_id %hw_target%
 
  result := DllCall( "ReadProcessMemory"
                , "uint", hp_explorer
                , "uint", remote_buffer
                , "uint", &rect
                , "uint", 16
                , "uint", 0 )
  oldx1:=x1
  oldx2:=x2
  oldy1:=y1
  x1 := DecodeInteger( "int4", &rect, 0 )
  x2 := DecodeInteger( "int4", &rect, 8 )
  y1 := DecodeInteger( "int4", &rect, 4 )
;  x1+=0
;  x2+=0
;  lv_row_w := x2-x1
;  y2 := DecodeInteger( "int4", &rect, 12 )
;  lv_row_h := y2-y1
;   MsgBox, lv_row_h: %lv_row_h% y1: %y1% y2: %y2%
;   MsgBox, lv_row_w: %lv_row_h% x1: %x1% x2: %x2%

  If (x1=oldx1 And y1=oldy1 And x2=oldx2)
    Continue
  If (x2-x1<10)
    Continue
  If (x1>ctrlw Or y1>ctrlh)
    Continue
  line:=100000000+Floor((ctrly+y1)/same)*10000+ctrlx+x2-thumbwidth
  lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n
}
result := DllCall( "VirtualFreeEx"
                 , "uint", hp_explorer
                 , "uint", remote_buffer
                 , "uint", 0
                 , "uint", 0x8000 )                           ; MEM_RELEASE
result := DllCall( "CloseHandle", "uint", hp_explorer )
Return


DecodeInteger( p_type, p_address, p_offset, p_hex=true ) ;By shimanov at http://www.autohotkey.com/forum/viewtopic.php?t=8840
{
   old_FormatInteger := A_FormatInteger

   if ( p_hex )
      SetFormat, Integer, hex
   else
      SetFormat, Integer, dec
       
   sign := InStr( p_type, "u", false )^1
   
   StringRight, size, p_type, 1
   
   loop, %size%
      value += ( *( ( p_address+p_offset )+( A_Index-1 ) ) << ( 8*( A_Index-1 ) ) )
       
   if ( sign and size <= 4 and *( p_address+p_offset+( size-1 ) ) & 0x80 )
      value := -( ( ~value+1 ) & ( ( 2**( 8*size ) )-1 ) )
       
   SetFormat, Integer, %old_FormatInteger%

   return, value
}


SEARCHCONTROL:
x:=ctrlx
y:=ctrly+ctrlh/2
backcolor:=0xECE9D8
minspacewidth:=2
spacewidth:=minspacewidth
counter:=1
Loop
{
  x+=3
  If (x>ctrlw)
    Break
  PixelGetColor,color,%x%,%y%,RGB
  difference:=COMPARE(color,backcolor)

  If (difference<=10)
  {
    spacewidth+=1
    If spacewidth>49
      Break
  }
 
  If (difference>10 And spacewidth>=minspacewidth)
  {
    right:=x

    line:=100000000+Floor(ctrly/same)*10000+x
    lines=%lines%%line%%A_Tab%%ctrlid%%A_Tab%%class%`n

    counter+=1
    spacewidth:=0
  }
}
Return


COMPARE(color1,color2)
{
  Loop,2
  {
    param:=A_Index
    StringTrimLeft,color%param%,color%param%,2
    Loop,3
    {
      StringLeft,c%param%%A_Index%,color%param%,2
      value:=c%param%%A_Index%
      c%param%%A_Index%=0x%value%
      StringTrimLeft,color%param%,color%param%,2
    }
  }
  difference:=(Abs(c11-c21)+Abs(c12-c22)+Abs(c13-c23))/3
  Return difference
}


INIREAD:
IfNotExist,%applicationname%.ini
{
  movemouse=0
  focuscontrols=Edit,Internet Explorer_Server,CalWndMain,TextViewer,CmboBx,TrackBar,DirectUI
  clickcontrols=Button,UpDown,ScrollBar,Link,Control,BitBtn,CheckBox,QWidget,List,Combo,Tree
  tabcontrols=Tab,PageControl
  headercontrols=Header
  toolbarcontrols=Toolbar,SysPager
  searchcontrols=
  ignorecontrols=ComboBoxEx
  listviews=ListView,LBox
  treeviews=TreeView
  Gosub,INIWRITE
}
IniRead,movemouse,%applicationname%.ini,Settings,movemouse
IniRead,focuscontrols,%applicationname%.ini,Settings,focuscontrols
IniRead,clickcontrols,%applicationname%.ini,Settings,clickcontrols
IniRead,tabcontrols,%applicationname%.ini,Settings,tabcontrols
IniRead,headercontrols,%applicationname%.ini,Settings,headercontrols
IniRead,toolbarcontrols,%applicationname%.ini,Settings,toolbarcontrols
IniRead,searchcontrols,%applicationname%.ini,Settings,searchcontrols
IniRead,ignorecontrols,%applicationname%.ini,Settings,ignorecontrols
IniRead,listviews,%applicationname%.ini,Settings,listviews
IniRead,treeviews,%applicationname%.ini,Settings,treeviews
allcontrols=%focuscontrols%,%clickcontrols%,%tabcontrols%,%headercontrols%,%toolbarcontrols%,%searchcontrols%,%listviews%,%treeviews%
Return

INIWRITE:
IniWrite,%movemouse%,%applicationname%.ini,Settings,movemouse
IniWrite,%focuscontrols%,%applicationname%.ini,Settings,focuscontrols
IniWrite,%clickcontrols%,%applicationname%.ini,Settings,clickcontrols
IniWrite,%tabcontrols%,%applicationname%.ini,Settings,tabcontrols
IniWrite,%headercontrols%,%applicationname%.ini,Settings,headercontrols
IniWrite,%toolbarcontrols%,%applicationname%.ini,Settings,toolbarcontrols
IniWrite,%searchcontrols%,%applicationname%.ini,Settings,searchcontrols
IniWrite,%ignorecontrols%,%applicationname%.ini,Settings,ignorecontrols
IniWrite,%listviews%,%applicationname%.ini,Settings,listviews
IniWrite,%treeviews%,%applicationname%.ini,Settings,treeviews
Return


TRAYMENU:
Menu,Tray,NoStandard
Menu,Tray,DeleteAll
Menu,Tray,Add,%applicationname%,SWAP
Menu,Tray,Add,
Menu,Tray,Add,&Enabled,SWAP
Menu,Tray,Add,
Menu,Tray,Add,&Settings...,SETTINGS
Menu,Tray,Add,&About...,ABOUT
Menu,Tray,Add,E&xit,EXIT
Menu,Tray,Check,&Enabled
Menu,Tray,Default,%applicationname%
Menu,Tray,Tip,%applicationname%
Return


SWAP:
Menu,Tray,ToggleCheck,&Enabled
Suspend,Toggle
Return


SETTINGS:
Gui,Destroy
Gui,Margin,30,40
Gui,Add,Tab,x10 y10 w520 h370,Settings|Focus|Click|Tab|Toolbar|Header|Search|Listview|Treeview|Ignore
Gui,Tab,Settings,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h50,&Mouse &action
Gui,Add,CheckBox,xm yp+20 Checked%movemouse% vvmovemouse,Move the mouse to the control

Gui,Tab,Focus,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,Controls to &Focus
Gui,Add,Edit,xm yp+20 w480 h290 vvfocuscontrols,%focuscontrols%

Gui,Tab,Click,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,Controls to &Click
Gui,Add,Edit,xm yp+20 w480 h290 vvclickcontrols,%clickcontrols%

Gui,Tab,Tab,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,&Tab controls
Gui,Add,Edit,xm yp+20 w480 h290 vvtabcontrols,%tabcontrols%

Gui,Tab,Toolbar,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,Tool&bar controls
Gui,Add,Edit,xm yp+20 w480 h290 vvtoolbarcontrols,%toolbarcontrols%

Gui,Tab,Header,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,&Header controls
Gui,Add,Edit,xm yp+20 w480 h290 vvheadercontrols,%headercontrols%

Gui,Tab,Search,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,&Search controls
Gui,Add,Edit,xm yp+20 w480 h290 vvsearchcontrols,%searchcontrols%

Gui,Tab,Listview,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,&Listviews
Gui,Add,Edit,xm yp+20 w480 h290 vvlistviews,%listviews%

Gui,Tab,Treeview,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,&Treeviews
Gui,Add,Edit,xm yp+20 w480 h290 vvtreeviews,%treeviews%

Gui,Tab,Ignore,,Exact
Gui,Add,GroupBox,xm-10 y+20 w500 h320,Controls to &ignore
Gui,Add,Edit,xm yp+20 w480 h290 vvignorecontrols,%ignorecontrols%

Gui,Tab
Gui,Add,Button,xm y+30 w75 GSETTINGSOK,&OK
Gui,Add,Button,x+5 w75 GSETTINGSCANCEL,&Cancel
Gui,Show,,%applicationname% Settings
Return

SETTINGSOK:
Gui,Submit
movemouse:=vmovemouse
focuscontrols:=vfocuscontrols
clickcontrols:=vclickcontrols
tabcontrols:=vtabcontrols
toolbarcontrols:=vtoolbarcontrols
searchcontrols:=vsearchcontrols
ignorecontrols:=vignorecontrols
Gosub,INIWRITE
Return

SETTINGSCANCEL:
Gui,Destroy
Return


ABOUT:
Gui,99:Destroy
Gui,99:Margin,20,20
Gui,99:Add,Picture,xm Icon1,%applicationname%.exe
Gui,99:Font,Bold
Gui,99:Add,Text,x+10 yp+10,%applicationname% v1.6
Gui,99:Font
Gui,99:Add,Text,y+10,Overlays controls with a Number for direct access via Ctrl-Number
Gui,99:Add,Text,y+10,- Hold Ctrl, write the number, release Ctrl.
Gui,99:Add,Text,y+10,- Change the settings using Settings in the tray menu.
Gui,99:Add,Text,y+10,- To add more controls, use Window Spy included with AutoHotkey
Gui,99:Add,Text,y+5,to find the class of the control, and add it to the proper tab.

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
  If ctrl in Static11,Static15,Static19
    DllCall("SetCursor","UInt",hCurs)
  Return
}
Return


EXIT:
ExitApp


WM_CTLCOLOREDIT1(wParam,lParam)
{
  ToolTip,Black
  BLACK_BRUSH:=3
  brush:=DllCall("Gdi32\GetStockObject","UInt",BLACK_BRUSH,"UInt")
  Return &brush
}

WM_CTLCOLOREDIT(wParam,lParam)
{
  SetFormat,Integer,Hex
    hdc:=wParam
    ut:=DllCall("SetTextColor","UInt",hdc,"UInt",0xFF0000)
    ut:=DllCall("SetBkColor","UInt",hdc,"UInt",0xFFFF00)
    COLOR_3DHILIGHT:=20
    brush:=DllCall("GetSysColorBrush","UInt",COLOR_3DHILIGHT)
  ToolTip,COLOR-%brush%-%ut%
    Return brush
}

