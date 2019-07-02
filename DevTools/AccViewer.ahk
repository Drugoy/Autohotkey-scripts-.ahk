; Accessible Info Viewer
; http://www.autohotkey.com/board/topic/77888-accessible-info-viewer-alpha-release-2012-09-20/
; https://dl.dropbox.com/u/47573473/Accessible%20Info%20Viewer/AccViewer%20Source.ahk

#SingleInstance force

_colTextW := 55
_col2W := 120
_col4W := 51

_margin := 10

_offset1 := _margin
_offset2 := _colTextW + 2*_margin              ; 2 times the margin
_offset3 := _offset2 + _col2W  + _margin
_offset4 := _offset3 + _colTextW + _margin

_fullW := _offset4 + _col4W - (_margin/2)

_guiWidth := _fullW + _fullW/2.5
_guiHeight := 410
_maxHeight := _guiHeight + 80
_minHeight := _guiHeight - 80




{
	WM_ACTIVATE := 0x06
	WM_KILLFOCUS := 0x08
	WM_LBUTTONDOWN := 0x201
	WM_LBUTTONUP := 0x202
	global	Border := new Outline, Stored:={}, Acc, ChildId, TVobj, Win:={}
}
{
	DetectHiddenWindows, On
	OnExit, OnExitCleanup
	OnMessage(0x200,"WM_MOUSEMOVE")
	ComObjError(false)
	Hotkey, ~LButton Up, Off
}
{
	Gui Main: New, HWNDhwnd LabelGui AlwaysOnTop, Accessible Info Viewer
	Gui Main: Default
	Win.Main := hwnd
	Gui, Add, Button, x160 y8 w105 h20 vShowStructure gShowStructure, Show Acc Structure
	{
		Gui, Add, Text, x10 y3 w%_colTextW% h26 Border gCrossHair ReadOnly HWNDh8 Border
		CColor(h8, "White")
		Gui, Add, Text, x10 y3 w%_colTextW% h4 HWNDh9 Border
		CColor(h9, "0046D5")
		Gui, Add, Text, x13 y17 w19 h1 Border vHBar
		Gui, Add, Text, x22 y8 w1 h19 Border vVBar
	}
	{
		Gui, Font, bold
		Gui, Add, GroupBox, x2 y32 w%_fullW% h130 vWinCtrl, Window/Control Info
		Gui, Font
		Gui, Add, Text, x%_offset1% y49 w%_colTextW% h20 Right, WinTitle:
		Gui, Add, Edit, x%_offset2% y47 w%_fullW% h20 vWinTitle ,
    
		Gui, Add, Text, x%_offset1% y71 w%_colTextW% h20 Right, Text:
		Gui, Add, Edit, x%_offset2% y69 w%_fullW% h20 vText ,
    
    ; Row 3
		Gui, Add, Text, x%_offset1% y93 w%_colTextW% h20 Right, Hwnd:
		Gui, Add, Edit, x%_offset2% y91 w%_col2W% h20 vHwnd,    
		Gui, Add, Text, x%_offset3% y93 w%_colTextW% h20 vClassText Right, Class(NN):
		Gui, Add, Edit, x%_offset4% y91 w%_col2W% h20 vClass,
    
    ; Row 4
		Gui, Add, Text, x%_offset1% y115 w%_colTextW% h20 Right, Position:
		Gui, Add, Edit, x%_offset2% y113 w%_col2W% h20 vPosition,    
		Gui, Add, Text, x%_offset3% y115 w%_colTextW% h20 Right, Process:
		Gui, Add, Edit, x%_offset4% y113 w%_col2W% h20 vProcess,
    
    ; Row 5
		Gui, Add, Text, x%_offset1% y137 w%_colTextW% h20 Right, Size:
		Gui, Add, Edit, x%_offset2% y135 w%_col2W% h20 vSize,    
		Gui, Add, Text, x%_offset3% y137 w%_colTextW% h20 Right, Proc ID:
		Gui, Add, Edit, x%_offset4% y135 w%_col2W% h20 vProcID,
	}
	{
		Gui, Font, bold
		Gui, Add, GroupBox, x2 y165 w525 h240 vAcc, Accessible Info
		Gui, Font
    
		Gui, Add, Text, x%_offset1% y182 w%_colTextW% h20 Right, Name:
		Gui, Add, Edit, x%_offset2% y180 w%_fullW% h20 vAccName ,
    
		Gui, Add, Text, x%_offset1% y204 w%_colTextW% h20 Right, Value:
		Gui, Add, Edit, x%_offset2% y202 w%_fullW% h20 vAccValue ,
    
    
    ; Row 3
		Gui, Add, Text, x%_offset1% y226 w%_colTextW% h20 Right, Role:
		Gui, Add, Edit, x%_offset2% y224 w%_col2W% h20 vAccRole,
		Gui, Add, Text, x%_offset3% y226 w%_colTextW% h20 Right, ChildCount:
		Gui, Add, Edit, x%_offset4% y224 w%_col2W% h20 vAccChildCount,
    
    ; Row 4
		Gui, Add, Text, x%_offset1% y248 w%_colTextW% h20 Right, State:
		Gui, Add, Edit, x%_offset2% y246 w%_col2W% h20 vAccState,
		Gui, Add, Text, x%_offset3% y248 w%_colTextW% h20 Right, Selection:
		Gui, Add, Edit, x%_offset4% y246 w%_col2W% h20 vAccSelection,
    
    ; Row 5
		Gui, Add, Text, x%_offset1% y270 w%_colTextW% h20 Right, Action:
		Gui, Add, Edit, x%_offset2% y268 w%_col2W% h20 vAccAction,
		Gui, Add, Text, x%_offset3% y270 w%_colTextW% h20 Right, Focus:
		Gui, Add, Edit, x%_offset4% y268 w%_col2W% h20 vAccFocus,
		{
			Gui, Add, Text, x%_offset1% y292 w%_colTextW% h20 Right vAccLocationText, Location:
			Gui, Add, Edit, x%_offset2% y290 w%_fullW% h20 vAccLocation ,
			Gui, Add, Text, x%_offset1% y314 w%_colTextW% h20 Right, Description:
			Gui, Add, Edit, x%_offset2% y312 w%_fullW% h20 vAccDescription ,
			Gui, Add, Text, x%_offset1% y336 w%_colTextW% h20 Right, Keyboard:
			Gui, Add, Edit, x%_offset2% y334 w%_fullW% h20 vAccKeyboard ,
			Gui, Add, Text, x%_offset1% y358 w%_colTextW% h20 Right, Help:
			Gui, Add, Edit, x%_offset2% y356 w%_fullW% h20 vAccHelp ,
			Gui, Add, Text, x%_offset1% y380 w%_colTextW% h20 Right, HelpTopic:
			Gui, Add, Edit, x%_offset2% y378 w%_fullW% h20 vAccHelpTopic ,
		}
	}
	{
		Gui, Add, StatusBar, gShowMainGui
		SB_SetParts(70,150)
		SB_SetText("`tshow more", 3)
	}
	{
		Gui Acc: New, ToolWindow AlwaysOnTop Resize LabelAcc HWNDhwnd, Acc Structure
		Win.Acc := hwnd
		Gui Acc: Add, TreeView, w200 h300 vTView gTreeView R17 AltSubmit
		Gui Acc: Show, Hide
	}
	GoSub, ShowMainGui
	WinSet, Redraw, , % "ahk_id" Win.Main
	return
}
ShowMainGui:
{
	if A_EventInfo in 1,2
	{
		WM_MOUSEMOVE()
		StatusBarGetText, SB_Text, %A_EventInfo%, % "ahk_id" Win.Main
		if SB_Text
			if (A_EventInfo=2 and SB_Text:=SubStr(SB_Text,7))
			or if RegExMatch(SB_Text, "Id: \K\d+", SB_Text)
			{
				ToolTip % "clipboard = " clipboard:=SB_Text
				SetTimer, RemoveToolTip, -2000
			}
	}
	else {
		Gui Main: Default
		if ShowingLess {
			SB_SetText("`tshow less", 3)
			GuiControl, Move, Acc, x2 y165 w275 h240
			GuiControl, Show, AccDescription
			GuiControl, Show, AccLocation
			GuiControl, Show, AccLocationText
			{
				height := _guiHeight
				while height < _maxHeight {
					height += 10
					Gui, Show, w%_guiWidth% h%height%
					Sleep, 20
				}
			}
			Gui, Show, w%_guiWidth% h%_maxHeight%
			ShowingLess := false
		}
		else {
			if (ShowingLess != "") {
				height := %_maxHeight%
				while height > %_minHeight% {
					height -= 10
					Gui, Show, w%_guiWidth% h%height%
					Sleep, 20
				}
			}
			Gui, Show, w%_guiWidth% h%_minHeight%
			GuiControl, Hide, AccDescription
			GuiControl, Hide, AccLocation
			GuiControl, Hide, AccLocationText
			GuiControl, Move, Acc, x2 y165 w275 h130
			SB_SetText("`tshow more", 3)
			ShowingLess := true
		}
		WinSet, Redraw, , % "ahk_id" Win.Main
	}
return
}

#if Not Lbutton_Pressed
^/::
{
	SetBatchLines, -1
	Lbutton_Pressed := true
	Stored.Chwnd := ""
	Gui Acc: Default
	GuiControl, Disable, TView
	while, Lbutton_Pressed
	GetAccInfo()
	SetBatchLines, 10ms
	return
}
#if Lbutton_Pressed
^/::
{
	Lbutton_Pressed := false
	Gui Main: Default
	Sleep, -1
	GuiControl, , WinCtrl, % (DllCall("GetParent", Uint,Acc_WindowFromObject(Acc))? "Control":"Window") " Info"
	if Not DllCall("IsWindowVisible", "Ptr",Win.Acc) {
		Border.Hide()
		SB_SetText("Path: " GetAccPath(Acc).path, 2)
	}
	else {
		Gui Acc: Default
		BuildTreeView()
		GuiControl, Enable, TView
		WinActivate, % "ahk_id" Win.Acc
		PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id" Win.Acc
	}
	return
}
#if
~Lbutton Up::
{
	Hotkey, ~LButton Up, Off
	Lbutton_Pressed := False
	Gui Main: Default
	if Not CH {
		GuiControl, Show, HBar
		GuiControl, Show, VBar
		CrossHair(CH:=true)
	}
	Sleep, -1
	GuiControl, , WinCtrl, % (DllCall("GetParent", Uint,Acc_WindowFromObject(Acc))? "Control":"Window") " Info"
	if Not DllCall("IsWindowVisible", "Ptr",Win.Acc) {
		Border.Hide()
		SB_SetText("Path: " GetAccPath(Acc).path, 2)
	}
	else {
		Gui Acc: Default
		BuildTreeView()
		GuiControl, Enable, TView
		WinActivate, % "ahk_id" Win.Acc
		PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id" Win.Acc
	}
	return
}
CrossHair:
{
	if (A_GuiEvent = "Normal") {
		SetBatchLines, -1
		Hotkey, ~LButton Up, On
		{
			GuiControl, Hide, HBar
			GuiControl, Hide, VBar
			CrossHair(CH:=false)
		}
		Lbutton_Pressed := True
		Stored.Chwnd := ""
		Gui Acc: Default
		GuiControl, Disable, TView
		while, Lbutton_Pressed
			GetAccInfo()
		SetBatchLines, 10ms
	}
	return
}
OnExitCleanup:
{
	CrossHair(true)
	GuiClose:
	ExitApp
}
ShowStructure:
{
	ControlFocus, Static1, % "ahk_id" Win.Main
	if DllCall("IsWindowVisible", "Ptr",Win.Acc) {
		PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id" Win.Acc
		return
	}
	WinGetPos, x, y, w, , % "ahk_id" Win.Main
	WinGetPos, , , AccW, AccH, % "ahk_id" Win.Acc
	WinMove, % "ahk_id" Win.Acc,
		, (x+w+AccW > A_ScreenWidth? x-AccW-10:x+w+10)
		, % y+5, %AccW%, %AccH%
	WinShow, % "ahk_id" Win.Acc
	if ComObjType(Acc, "Name") = "IAccessible"
		BuildTreeView()
	if Lbutton_Pressed
		GuiControl, Disable, TView
	else
		GuiControl, Enable, TView
	PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id" Win.Acc
	return
}
BuildTreeView()
{
	r := GetAccPath(Acc)
	AccObj:=r.AccObj, Child_Path:=r.Path, r:=""
	Gui Acc: Default
	TV_Delete()
	GuiControl, -Redraw, TView
	parent := TV_Add(Acc_Role(AccObj), "", "Bold Expand")
	TVobj := {(parent): {is_obj:true, obj:AccObj, need_children:false, childid:0, Children:[]}}
	Loop Parse, Child_Path, .
	{
		if A_LoopField is not Digit
			TVobj[parent].Obj_Path := Trim(TVobj[parent].Obj_Path "," A_LoopField, ",")
		else {
			StoreParent := parent
			parent := TV_BuildAccChildren(AccObj, parent, "", A_LoopField)
			TVobj[parent].need_children := false
			TV_Expanded(StoreParent)
			TV_Modify(parent,"Expand")
			AccObj := TVobj[parent].obj
		}
	}
	if Not ChildId {
		TV_BuildAccChildren(AccObj, parent)
		TV_Modify(parent, "Select")
	}
	else
		TV_BuildAccChildren(AccObj, parent, ChildId)
	TV_Expanded(parent)
	GuiControl, +Redraw, TView
}
AccClose:
{
	Border.Hide()
	Gui Acc: Hide
	TV_Delete()
	Gui Main: Default
	GuiControl, Enable, ShowStructure
	return
}
AccSize:
{
	Anchor(TView, "wh")
	return
}
TreeView:
{
	Gui, Submit, NoHide
	if (A_GuiEvent = "S")
		UpdateAccInfo(TVobj[A_EventInfo].obj, TVobj[A_EventInfo].childid, TVobj[A_EventInfo].obj_path)
	if (A_GuiEvent = "+") {
		GuiControl, -Redraw, TView
		TV_Expanded(A_EventInfo)
		GuiControl, +Redraw, TView
	}
	return
}
RemoveToolTip:
{
	ToolTip
	return
}
GetAccInfo() {
	global Whwnd
	static ShowButtonEnabled
	MouseGetPos, , , Whwnd
	if (Whwnd!=Win.Main and Whwnd!=Win.Acc) {
		{
			GuiControlGet, SectionLabel, , WinCtrl
			if (SectionLabel != "Window/Control Info")
				GuiControl, , WinCtrl, Window/Control Info
		}
		Acc := Acc_ObjectFromPoint(ChildId)
		Location := GetAccLocation(Acc, ChildId)
		if Stored.Location != Location {
			Hwnd := Acc_WindowFromObject(Acc)
			if Stored.Hwnd != Hwnd {
				if DllCall("GetParent", Uint,hwnd) {
					WinGetTitle, title, ahk_id %parent%
					ControlGetText, text, , ahk_id %Hwnd%
					class := GetClassNN(Hwnd,Whwnd)
					ControlGetPos, posX, posY, posW, posH, , ahk_id %Hwnd%
					WinGet, proc, ProcessName, ahk_id %parent%
					WinGet, procid, PID, ahk_id %parent%
				}
				else {
					WinGetTitle, title, ahk_id %Hwnd%
					WinGetText, text, ahk_id %Hwnd%
					WinGetClass, class, ahk_id %Hwnd%
					WinGetPos, posX, posY, posW, posH, ahk_id %Hwnd%
					WinGet, proc, ProcessName, ahk_id %Hwnd%
					WinGet, procid, PID, ahk_id %Hwnd%
				}
				{
					GuiControl, , WinTitle, %title%
					GuiControl, , Text, %text%
					SetFormat, IntegerFast, H
					GuiControl, , Hwnd, % Hwnd+0
					SetFormat, IntegerFast, D
					GuiControl, , Class, %class%
					GuiControl, , Position, x%posX%  y%posY%
					GuiControl, , Size, w%posW%  h%posH%
					GuiControl, , Process, %proc%
					GuiControl, , ProcId, %procid%
				}
				Stored.Hwnd := Hwnd
			}
			UpdateAccInfo(Acc, ChildId)
		}
	}
}
UpdateAccInfo(Acc, ChildId, Obj_Path="") {
	global Whwnd
	Gui Main: Default
	Location := GetAccLocation(Acc, ChildId, x,y,w,h)
	{
		GuiControl, , AccName, % Acc.accName(ChildId)
		GuiControl, , AccValue, % Acc.accValue(ChildId)
		GuiControl, , AccRole, % Acc_GetRoleText(Acc.accRole(ChildId))
		GuiControl, , AccState, % Acc_GetStateText(Acc.accState(ChildId))
		GuiControl, , AccAction, % Acc.accDefaultAction(ChildId)
		GuiControl, , AccChildCount, % ChildId? "N/A":Acc.accChildCount
		GuiControl, , AccSelection, % ChildId? "N/A":Acc.accSelection
		GuiControl, , AccFocus, % ChildId? "N/A":Acc.accFocus
		GuiControl, , AccLocation, %Location%
		GuiControl, , AccDescription, % Acc.accDescription(ChildId)
		GuiControl, , AccKeyboard, % Acc.accKeyboardShortCut(ChildId)
		Guicontrol, , AccHelp, % Acc.accHelp(ChildId)
		GuiControl, , AccHelpTopic, % Acc.accHelpTopic(ChildId)
		SB_SetText(ChildId? "Child Id: " ChildId:"Object")
		SB_SetText(DllCall("IsWindowVisible", "Ptr",Win.Acc)? "Path: " Obj_Path:"", 2)
	}
	Border.Transparent(true)
	Border.show(x,y,x+w,y+h)
	Border.setabove(Whwnd)
	Border.Transparent(false)
	Stored.Location := Location
}
GetClassNN(Chwnd, Whwnd) {
	global _GetClassNN := {}
	_GetClassNN.Hwnd := Chwnd
	Detect := A_DetectHiddenWindows
	WinGetClass, Class, ahk_id %Chwnd%
	_GetClassNN.Class := Class
	DetectHiddenWindows, On
	EnumAddress := RegisterCallback("GetClassNN_EnumChildProc")
	DllCall("EnumChildWindows", "uint",Whwnd, "uint",EnumAddress)
	DetectHiddenWindows, %Detect%
	return, _GetClassNN.ClassNN, _GetClassNN:=""
}
GetClassNN_EnumChildProc(hwnd, lparam) {
	static Occurrence
	global _GetClassNN
	WinGetClass, Class, ahk_id %hwnd%
	if _GetClassNN.Class == Class
		Occurrence++
	if Not _GetClassNN.Hwnd == hwnd
		return true
	else {
		_GetClassNN.ClassNN := _GetClassNN.Class Occurrence
		Occurrence := 0
		return false
	}
}
TV_Expanded(TVid) {
	For Each, TV_Child_ID in TVobj[TVid].Children
		if TVobj[TV_Child_ID].need_children
			TV_BuildAccChildren(TVobj[TV_Child_ID].obj, TV_Child_ID)
}
TV_BuildAccChildren(AccObj, Parent, Selected_Child="", Flag="") {
	TVobj[Parent].need_children := false
	Parent_Obj_Path := Trim(TVobj[Parent].Obj_Path, ",")
	for wach, child in Acc_Children(AccObj) {
		if Not IsObject(child) {
			added := TV_Add("[" A_Index "] " Acc_GetRoleText(AccObj.accRole(child)), Parent)
			TVobj[added] := {is_obj:false, obj:Acc, childid:child, Obj_Path:Parent_Obj_Path}
			if (child = Selected_Child)
				TV_Modify(added, "Select")
		}
		else {
			added := TV_Add("[" A_Index "] " Acc_Role(child), Parent, "bold")
			TVobj[added] := {is_obj:true, need_children:true, obj:child, childid:0, Children:[], Obj_Path:Trim(Parent_Obj_Path "," A_Index, ",")}
		}
		TVobj[Parent].Children.Insert(added)
		if (A_Index = Flag)
			Flagged_Child := added
	}
	return Flagged_Child
}
GetAccPath(Acc, byref hwnd="") {
	hwnd := Acc_WindowFromObject(Acc)
	WinObj := Acc_ObjectFromWindow(hwnd)
	WinObjPos := Acc_Location(WinObj).pos
	while Acc_WindowFromObject(Parent:=Acc_Parent(Acc)) = hwnd {
		t2 := GetEnumIndex(Acc) "." t2
		if Acc_Location(Parent).pos = WinObjPos
			return {AccObj:Parent, Path:SubStr(t2,1,-1)}
		Acc := Parent
	}
	while Acc_WindowFromObject(Parent:=Acc_Parent(WinObj)) = hwnd
		t1.="P.", WinObj:=Parent
	return {AccObj:Acc, Path:t1 SubStr(t2,1,-1)}
}
GetEnumIndex(Acc, ChildId=0) {
	if Not ChildId {
		ChildPos := Acc_Location(Acc).pos
		For Each, child in Acc_Children(Acc_Parent(Acc))
			if IsObject(child) and Acc_Location(child).pos=ChildPos
				return A_Index
	} 
	else {
		ChildPos := Acc_Location(Acc,ChildId).pos
		For Each, child in Acc_Children(Acc)
			if Not IsObject(child) and Acc_Location(Acc,child).pos=ChildPos
				return A_Index
	}
}
GetAccLocation(AccObj, Child=0, byref x="", byref y="", byref w="", byref h="") {
	AccObj.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), Child)
	return	"x" (x:=NumGet(x,0,"int")) "  "
	.	"y" (y:=NumGet(y,0,"int")) "  "
	.	"w" (w:=NumGet(w,0,"int")) "  "
	.	"h" (h:=NumGet(h,0,"int"))
}
WM_MOUSEMOVE() {
	static hCurs := new Cursor(32649)
	MouseGetPos,,,,ctrl
	if (ctrl = "msctls_statusbar321")
		DllCall("SetCursor","ptr",hCurs.ptr)
}
class Cursor {
	__New(id) {
	this.ptr := DllCall("LoadCursor","UInt",NULL,"Int",id,"UInt")
}
__delete() {
DllCall("DestroyCursor","Uint",this.ptr)
}
}
class Outline {
	__New(color="red") {
		Gui, +HWNDdefault
		Loop, 4 {
			Gui, New, -Caption +ToolWindow HWNDhwnd
			Gui, Color, w%_color%
			this[A_Index] := hwnd
		}
		this.visible := false
		this.color := color
		this.top := this[1]
		this.right := this[2]
		this.bottom := this[3]
		this.left := this[4]
		Gui, %default%: Default
	}
	Show(x1, y1, x2, y2, sides="TRBL") {
		Gui, +HWNDdefault
		if InStr( sides, "T" )
			Gui, % this[1] ":Show", % "NA X" x1-2 " Y" y1-2 " W" x2-x1+4 " H" 2
		Else, Gui, % this[1] ":Hide"
		if InStr( sides, "R" )
			Gui, % this[2] ":Show", % "NA X" x2 " Y" y1 " W" 2 " H" y2-y1
		Else, Gui, % this[2] ":Hide"
		if InStr( sides, "B" )
			Gui, % this[3] ":Show", % "NA X" x1-2 " Y" y2 " W" x2-x1+4 " H" 2
		Else, Gui, % this[3] ":Hide"
		if InStr( sides, "L" )
			Gui, % this[4] ":Show", % "NA X" x1-2 " Y" y1 " W" 2 " H" y2-y1
		Else, Gui, % this[3] ":Hide"
		self.visible := true
		Gui, %default%: Default
	}
	Hide() {
		Gui, +HWNDdefault
		Loop, 4
			Gui, % this[A_Index] ": Hide"
		self.visible := false
		Gui, %default%: Default
	}
	SetAbove(hwnd) {
		ABOVE := DllCall("GetWindow", "uint", hwnd, "uint", 3)
		Loop, 4
			DllCall(	"SetWindowPos", "uint", this[A_Index], "uint", ABOVE
					,	"int", 0, "int", 0, "int", 0, "int", 0
					,	"uint", 0x1|0x2|0x10	)
	}
	Transparent(param) {
		Loop, 4
			WinSet, Transparent, % param=1? 0:255, % "ahk_id" this[A_Index]
		self.visible := !param
	}
	Color(color) {
		Gui, +HWNDdefault
		Loop, 4
			Gui, % this[A_Index] ": Color" , w%_color%
		self.color := color
		Gui, %default%: Default
	}
	Destroy() {
		Loop, 4
			Gui, % this[A_Index] ": Destroy"
	}
}
CColor(Hwnd, Background="", Foreground="") {
	return CColor_(Background, Foreground, "", Hwnd+0)
}
CColor_(Wp, Lp, Msg, Hwnd) {
	static
	static WM_CTLCOLOREDIT=0x0133, WM_CTLCOLORLISTBOX=0x134, WM_CTLCOLORSTATIC=0x0138
	,LVM_SETBKCOLOR=0x1001, LVM_SETTEXTCOLOR=0x1024, LVM_SETTEXTBKCOLOR=0x1026, TVM_SETTEXTCOLOR=0x111E, TVM_SETBKCOLOR=0x111D
	,BS_CHECKBOX=2, BS_RADIOBUTTON=8, ES_READONLY=0x800
	,CLR_NONE=-1, CSILVER=0xC0C0C0, CGRAY=0x808080, CWHITE=0xFFFFFF, CMAROON=0x80, CRED=0x0FF, CPURPLE=0x800080, CFUCHSIA=0xFF00FF,CGREEN=0x8000, CLIME=0xFF00, COLIVE=0x8080, CYELLOW=0xFFFF, CNAVY=0x800000, CBLUE=0xFF0000, CTEAL=0x808000, CAQUA=0xFFFF00
	,CLASSES := "Button,ComboBox,Edit,ListBox,Static,RICHEDIT50W,SysListView32,SysTreeView32"
	If (Msg = "") {
		if !adrSetTextColor
		adrSetTextColor   := DllCall("GetProcAddress", "uint", DllCall("GetModuleHandle", "str", "Gdi32.dll"), "str", "SetTextColor")
		,adrSetBkColor   := DllCall("GetProcAddress", "uint", DllCall("GetModuleHandle", "str", "Gdi32.dll"), "str", "SetBkColor")
		,adrSetBkMode   := DllCall("GetProcAddress", "uint", DllCall("GetModuleHandle", "str", "Gdi32.dll"), "str", "SetBkMode")
		BG := !Wp ? "" : C%Wp% != "" ? C%Wp% : "0x" SubStr(WP,5,2) SubStr(WP,3,2) SubStr(WP,1,2)
		FG := !Lp ? "" : C%Lp% != "" ? C%Lp% : "0x" SubStr(LP,5,2) SubStr(LP,3,2) SubStr(LP,1,2)
		WinGetClass, class, ahk_id %Hwnd%
		If class not in %CLASSES%
			return A_ThisFunc "> Unsupported control class: " class
		ControlGet, style, Style, , , ahk_id %Hwnd%
		if (class = "Edit") && (Style & ES_READONLY)
			class := "Static"
		if (class = "Button")
			if (style & BS_RADIOBUTTON) || (style & BS_CHECKBOX)
				class := "Static"
			else 
				return A_ThisFunc "> Unsupported control class: " class
		if (class = "ComboBox") {
			VarSetCapacity(CBBINFO, 52, 0), NumPut(52, CBBINFO), DllCall("GetComboBoxInfo", "UInt", Hwnd, "UInt", &CBBINFO)
			hwnd := NumGet(CBBINFO, 48)
			%hwnd%BG := BG, %hwnd%FG := FG, %hwnd% := BG ? DllCall("CreateSolidBrush", "UInt", BG) : -1
			IfEqual, CTLCOLORLISTBOX,,SetEnv, CTLCOLORLISTBOX, % OnMessage(WM_CTLCOLORLISTBOX, A_ThisFunc)
			If NumGet(CBBINFO,44)
				Hwnd :=  Numget(CBBINFO,44), class := "Edit"
		}
		if class in SysListView32,SysTreeView32
		{
			m := class="SysListView32" ? "LVM" : "TVM"
			SendMessage, %m%_SETBKCOLOR, ,BG, ,ahk_id %Hwnd%
			SendMessage, %m%_SETTEXTCOLOR, ,FG, ,ahk_id %Hwnd%
			SendMessage, %m%_SETTEXTBKCOLOR, ,CLR_NONE, ,ahk_id %Hwnd%
			return
		}
		if (class = "RICHEDIT50W")
			return f := "RichEdit_SetBgColor", %f%(Hwnd, -BG)
		if (!CTLCOLOR%Class%)
			CTLCOLOR%Class% := OnMessage(WM_CTLCOLOR%Class%, A_ThisFunc)
		return %Hwnd% := BG ? DllCall("CreateSolidBrush", "UInt", BG) : CLR_NONE,  %Hwnd%BG := BG,  %Hwnd%FG := FG
	}
	critical
	Hwnd := Lp + 0, hDC := Wp + 0
	If (%Hwnd%) {
		DllCall(adrSetBkMode, "uint", hDC, "int", 1)
		if (%Hwnd%FG)
			DllCall(adrSetTextColor, "UInt", hDC, "UInt", %Hwnd%FG)
		if (%Hwnd%BG)
			DllCall(adrSetBkColor, "UInt", hDC, "UInt", %Hwnd%BG)
		return (%Hwnd%)
	}
}
CrossHair(OnOff=1) {
	static AndMask, XorMask, $, h_cursor, IDC_CROSS := 32515
	,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13
	, b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13
	, h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13
	if (OnOff = "Init" or OnOff = "I" or $ = "") {
		$ := "h"
		, VarSetCapacity( h_cursor,4444, 1 )
		, VarSetCapacity( AndMask, 32*4, 0xFF )
		, VarSetCapacity( XorMask, 32*4, 0 )
		, system_cursors := "32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650"
		StringSplit c, system_cursors, `,
		Loop, %c0%
			h_cursor   := DllCall( "LoadCursor", "uint",0, "uint",c%A_Index% )
			, h%A_Index% := DllCall( "CopyImage",  "uint",h_cursor, "uint",2, "int",0, "int",0, "uint",0 )
			, b%A_Index% := DllCall("LoadCursor", "Uint", "", "Int", IDC_CROSS, "Uint")
	}
	$ := (OnOff = 0 || OnOff = "Off" || $ = "h" && (OnOff < 0 || OnOff = "Toggle" || OnOff = "T")) ? "b" : "h"
	Loop, %c0%
		h_cursor := DllCall( "CopyImage", "uint",%$%%A_Index%, "uint",2, "int",0, "int",0, "uint",0 )
		, DllCall( "SetSystemCursor", "uint",h_cursor, "uint",c%A_Index% )
}

{ ; Acc Library
	Acc_Init()
	{
		Static	h
		If Not	h
		h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
	}
	Acc_ObjectFromEvent(ByRef _idChild_, hWnd, idObject, idChild)
	{
	Acc_Init()
		If	DllCall("oleacc\AccessibleObjectFromEvent", "Ptr", hWnd, "UInt", idObject, "UInt", idChild, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
		Return	ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
	}
	Acc_ObjectFromPoint(ByRef _idChild_ = "", x = "", y = "")
	{
		Acc_Init()
		If	DllCall("oleacc\AccessibleObjectFromPoint", "Int64", x==""||y==""?0*DllCall("GetCursorPos","Int64*",pt)+pt:x&0xFFFFFFFF|y<<32, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
		Return	ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
	}
	Acc_ObjectFromWindow(hWnd, idObject = 0)
	{
		Acc_Init()
		If	DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x%_offset1%19B3800AA000C81,NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc)=0
		Return	ComObjEnwrap(9,pacc,1)
	}
	Acc_WindowFromObject(pacc)
	{
		If	DllCall("oleacc\WindowFromAccessibleObject", "Ptr", IsObject(pacc)?ComObjValue(pacc):pacc, "Ptr*", hWnd)=0
		Return	hWnd
	}
	Acc_GetRoleText(nRole)
	{
		nSize := DllCall("oleacc\GetRoleText", "Uint", nRole, "Ptr", 0, "Uint", 0)
		VarSetCapacity(sRole, (A_IsUnicode?2:1)*nSize)
		DllCall("oleacc\GetRoleText", "Uint", nRole, "str", sRole, "Uint", nSize+1)
		Return	sRole
	}
	Acc_GetStateText(nState)
	{
		nSize := DllCall("oleacc\GetStateText", "Uint", nState, "Ptr", 0, "Uint", 0)
		VarSetCapacity(sState, (A_IsUnicode?2:1)*nSize)
		DllCall("oleacc\GetStateText", "Uint", nState, "str", sState, "Uint", nSize+1)
		Return	sState
	}
	Acc_Role(Acc, ChildId=0)
	{
		try return ComObjType(Acc,"Name")="IAccessible"?Acc_GetRoleText(Acc.accRole(ChildId)):"invalid object"
	}
	Acc_State(Acc, ChildId=0)
	{
		try return ComObjType(Acc,"Name")="IAccessible"?Acc_GetStateText(Acc.accState(ChildId)):"invalid object"
	}
	Acc_Children(Acc)
	{
		if ComObjType(Acc,"Name")!="IAccessible"
			error_message := "Cause:`tInvalid IAccessible Object`n`n"
		else
		{
			Acc_Init()
			cChildren:=Acc.accChildCount, Children:=[]
			if DllCall("oleacc\AccessibleChildren", "Ptr", ComObjValue(Acc), "Int", 0, "Int", cChildren, "Ptr", VarSetCapacity(varChildren,cChildren*(8+2*A_PtrSize),0)*0+&varChildren, "Int*", cChildren)=0
			{
				Loop %cChildren%
					i:=(A_Index-1)*(A_PtrSize*2+8)+8, child:=NumGet(varChildren,i), Children.Insert(NumGet(varChildren,i-8)=3?child:Acc_Query(child)), ObjRelease(child)
			return Children
			}
		}
		error:=Exception("",-1)
		MsgBox, 262148, Acc_Children Failed, % (error_message?error_message:"") "File:`t" (error.file==A_ScriptFullPath?A_ScriptName:error.file) "`nLine:`t" error.line "`n`nContinue Script?"
		IfMsgBox, No
			ExitApp
	}
	Acc_Location(Acc, ChildId=0)
	{
		try Acc.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId)
		catch
		return
		return	{x:NumGet(x,0,"int"), y:NumGet(y,0,"int"), w:NumGet(w,0,"int"), h:NumGet(h,0,"int")
		,	pos:"x" NumGet(x,0,"int")" y" NumGet(y,0,"int") " w" NumGet(w,0,"int") " h" NumGet(h,0,"int")}
	}
	Acc_Parent(Acc)
	{
		try parent:=Acc.accParent
		return parent?Acc_Query(parent):
	}
	Acc_Child(Acc, ChildId=0)
	{
		try child:=Acc.accChild(ChildId)
		return child?Acc_Query(child):
	}
	Acc_Query(Acc)
	{
		try return ComObj(9, ComObjQuery(Acc,"{618736e0-3c3d-11cf-810c-00aa00389b71}"), 1)
	}
}

Anchor(i, a = "", r = false)
{
	static c, cs = 12, cx = 255, cl = 0, g, gs = 8, gl = 0, gpi, gw, gh, z = 0, k = 0xffff, ptr
	If z = 0
		VarSetCapacity(g, gs * 99, 0), VarSetCapacity(c, cs * cx, 0), ptr := A_PtrSize ? "Ptr" : "UInt", z := true
	If (!WinExist("ahk_id" . i))
	{
		GuiControlGet, t, Hwnd, %i%
		If ErrorLevel = 0
		i := t
		Else ControlGet, i, Hwnd, , %i%
	}
	VarSetCapacity(gi, 68, 0), DllCall("GetWindowInfo", "UInt", gp := DllCall("GetParent", "UInt", i), ptr, &gi)
	, giw := NumGet(gi, 28, "Int") - NumGet(gi, 20, "Int"), gih := NumGet(gi, 32, "Int") - NumGet(gi, 24, "Int")
	If (gp != gpi)
	{
		gpi := gp
		Loop, %gl%
			If (NumGet(g, cb := gs * (A_Index - 1)) == gp, "UInt")
			{
				gw := NumGet(g, cb + 4, "Short"), gh := NumGet(g, cb + 6, "Short"), gf := 1
				Break
			}
		If (!gf)
			NumPut(gp, g, gl, "UInt"), NumPut(gw := giw, g, gl + 4, "Short"), NumPut(gh := gih, g, gl + 6, "Short"), gl += gs
	}
	ControlGetPos, dx, dy, dw, dh, , ahk_id %i%
	Loop, %cl%
	If (NumGet(c, cb := cs * (A_Index - 1), "UInt") == i)
	{
		If a =
		{
			cf = 1
			Break
		}
		giw -= gw, gih -= gh, as := 1, dx := NumGet(c, cb + 4, "Short"), dy := NumGet(c, cb + 6, "Short")
		, cw := dw, dw := NumGet(c, cb + 8, "Short"), ch := dh, dh := NumGet(c, cb + 10, "Short")
		Loop, Parse, a, xywh
			If A_Index > 1
				av := SubStr(a, as, 1), as += 1 + StrLen(A_LoopField)
				, d%av% += (InStr("yh", av) ? gih : giw) * (A_LoopField + 0 ? A_LoopField : 1)
		DllCall("SetWindowPos", "UInt", i, "UInt", 0, "Int", dx, "Int", dy
		, "Int", InStr(a, "w") ? dw : cw, "Int", InStr(a, "h") ? dh : ch, "Int", 4)
		If r != 0
			DllCall("RedrawWindow", "UInt", i, "UInt", 0, "UInt", 0, "UInt", 0x0101)
		Return
	}
	If cf != 1
		cb := cl, cl += cs
	bx := NumGet(gi, 48, "UInt"), by := NumGet(gi, 16, "Int") - NumGet(gi, 8, "Int") - gih - NumGet(gi, 52, "UInt")
	If cf = 1
		dw -= giw - gw, dh -= gih - gh
	NumPut(i, c, cb, "UInt"), NumPut(dx - bx, c, cb + 4, "Short"), NumPut(dy - by, c, cb + 6, "Short")
	, NumPut(dw, c, cb + 8, "Short"), NumPut(dh, c, cb + 10, "Short")
	Return, true
}
