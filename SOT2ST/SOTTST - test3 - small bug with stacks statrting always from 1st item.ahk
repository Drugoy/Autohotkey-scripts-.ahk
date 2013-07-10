#NoEnv
#SingleInstance, Force
Count := 0
SetKeyDelay, 20

IsActive()
{
	MouseGetPos, , , id
	Return id=WinExist("ahk_class Shell_TrayWnd") ? 1 : 0
}

TaskBarPos()
{
	WinGetPos,X,Y,W,H,ahk_class Shell_TrayWnd
	Return x=0 ? y=0 ? h<w ? "Top" : "Left" : "Bottom" : "Right"
}

#If IsActive()

~WheelDown::
~WheelUp::
If !(GetKeyState("Xbutton2", "P"))
{
	Max := Num()
	Count := Count <= 1 ? Max : Count -1
	If (Count<=Max&& Count>1)
		ControlSend, , % (A_ThisHotkey="WheelDown" ? TaskBarPos()="Top" || TaskBarPos()="Bottom" ? "{Right}" : "{Down}" : TaskBarPos()="Top" || TaskBarPos()="Bottom" ? "{Left}" : "{Up}" ) ,ahk_class TaskListThumbnailWnd
	Else
		ControlSend, MSTaskListWClass1, % "{PGND}" (A_ThisHotkey="WheelDown" ? TaskBarPos()="Top" || TaskBarPos()="Bottom" ? "{Right}{Up}" : "{Down}{Left}" : TaskBarPos()="Top" || TaskBarPos()="Bottom" ? "{Left}{Up}" : "{Up}{Left}" ) ,ahk_class Shell_TrayWnd
	SetTimer, Check, 50
}
Return

#If

Check:
If !IsActive()
{
	ControlSend, , {Enter}, ahk_class TaskListThumbnailWnd
	SetTimer, Check, Off
}
Return

Num()
{
	Return Acc_ObjectFromWindow(WinExist("ahk_class TaskListThumbnailWnd")).accChildCount//3
}

Acc_ObjectFromWindow(hWnd, idObject = -4)
{
	Static  h
	If Not  h
		h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
	If  DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81,NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc) = 0
		Return  ComObjEnwrap(9,pacc,1)
}