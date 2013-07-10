SetTitleMatchMode 2
MsgBox % Acc_Get("Value", "4.20.2.4.2", 0, "Firefox")
MsgBox % Acc_Get("Value", "application1.property_page1.tool_bar2.combo_box1.editable_text1", 0, "Firefox")
 
 
 
 
 
Acc_Get(Cmd, ChildPath="", ChildID=0, WinTitle="", WinText="", ExcludeTitle="", ExcludeText="") {
static properties := {Action:"DefaultAction", DoAction:"DoDefaultAction", Keyboard:"KeyboardShortcut"}
AccObj := IsObject(WinTitle)? WinTitle
: Acc_ObjectFromWindow( WinExist(WinTitle, WinText, ExcludeTitle, ExcludeText), 0 )
if ComObjType(AccObj, "Name") != "IAccessible"
ErrorLevel := "Could not access an IAccessible Object"
else {
StringReplace, ChildPath, ChildPath, _, %A_Space%, All
AccError:=Acc_Error(), Acc_Error(true)
Loop Parse, ChildPath, ., %A_Space%
try {
if A_LoopField is digit
Children:=Acc_Children(AccObj), m2:=A_LoopField ; mimic "m2" output in else-statement
else
RegExMatch(A_LoopField, "(\D*)(\d*)", m), Children:=Acc_ChildrenByRole(AccObj, m1), m2:=(m2?m2:1)
if Not Children.HasKey(m2)
throw
AccObj := Children[m2]
} catch {
ErrorLevel:="Cannot access ChildPath Item #" A_Index " -> " A_LoopField, Acc_Error(AccError)
if Acc_Error()
throw Exception("Cannot access ChildPath Item", -1, "Item #" A_Index " -> " A_LoopField)
return
}
Acc_Error(AccError)
StringReplace, Cmd, Cmd, %A_Space%, , All
properties.HasKey(Cmd)? Cmd:=properties[Cmd]:
try {
if (Cmd = "Location")
AccObj.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId)
, ret_val := "x" NumGet(x,0,"int") " y" NumGet(y,0,"int") " w" NumGet(w,0,"int") " h" NumGet(h,0,"int")
else if (Cmd = "Object")
ret_val := AccObj
else if Cmd in Role,State
ret_val := Acc_%Cmd%(AccObj, ChildID+0)
else if Cmd in ChildCount,Selection,Focus
ret_val := AccObj["acc" Cmd]
else
ret_val := AccObj["acc" Cmd](ChildID+0)
} catch {
ErrorLevel := """" Cmd """ Cmd Not Implemented"
if Acc_Error()
throw Exception("Cmd Not Implemented", -1, Cmd)
return
}
return ret_val, ErrorLevel:=0
}
if Acc_Error()
throw Exception(ErrorLevel,-1)
}
Acc_Error(p="") {
static setting:=0
return p=""?setting:setting:=p
}
Acc_ChildrenByRole(Acc, Role) {
if ComObjType(Acc,"Name")!="IAccessible"
ErrorLevel := "Invalid IAccessible Object"
else {
Acc_Init(), cChildren:=Acc.accChildCount, Children:=[]
if DllCall("oleacc\AccessibleChildren", "Ptr",ComObjValue(Acc), "Int",0, "Int",cChildren, "Ptr",VarSetCapacity(varChildren,cChildren*(8+2*A_PtrSize),0)*0+&varChildren, "Int*",cChildren)=0 {
Loop %cChildren% {
i:=(A_Index-1)*(A_PtrSize*2+8)+8, child:=NumGet(varChildren,i)
if NumGet(varChildren,i-8)=9
AccChild:=Acc_Query(child), ObjRelease(child), Acc_Role(AccChild)=Role?Children.Insert(AccChild):
else
Acc_Role(Acc, child)=Role?Children.Insert(child):
}
return Children.MaxIndex()?Children:, ErrorLevel:=0
} else
ErrorLevel := "AccessibleChildren DllCall Failed"
}
if Acc_Error()
throw Exception(ErrorLevel,-1)
}