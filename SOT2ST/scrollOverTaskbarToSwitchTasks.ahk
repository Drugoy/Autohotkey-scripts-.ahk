Count := 0
SetKeyDelay, 20
Return

#If TaskBarHovering()

WheelDown::
Max := Num()
If Count <= 1
    Count := Max
Else
    Count --
If (Count <= Max && Count > 1)
    ControlSend,, % (TaskBarPos() = "Top" || TaskBarPos() = "Bottom") ? "{Right}" : "{Down}", ahk_class TaskListThumbnailWnd
Else
    ControlSend, MSTaskListWClass1, % (TaskBarPos()="Top" || TaskBarPos()="Bottom") ? "{Right}{Up}" : "{Down}{Left}", ahk_class Shell_TrayWnd
SetTimer, Check, 50
Return

WheelUp::
Max := Num()
If Max = 0
    Return
If Count <= 1
    Count := Max
Else
    Count --
If (Count > 1 && Count <= Max)
    ControlSend,, % (TaskBarPos() = "Top" || TaskBarPos() = "Bottom") ? "{Left}" : "{Up}", ahk_class TaskListThumbnailWnd
Else
    ControlSend, MSTaskListWClass1, % (TaskBarPos() = "Top" || TaskBarPos() = "Bottom") ? "{Left}{Up}" : "{Up}{Left}", ahk_class Shell_TrayWnd
SetTimer, Check, 50
Return

#If

Check:
If !TaskBarHovering()
{
    Max := Num()
    If Max = 0
        Return
    If Count <= 1
        Count := Max
    Else
        Count --
    If (Count > 1 && Count <= Max)
        ControlSend,, {Enter}, ahk_class TaskListThumbnailWnd
    Else
        ControlSend, MSTaskListWClass1, {Enter}, ahk_class Shell_TrayWnd
    ;ControlSend, , {Enter}, ahk_class TaskListThumbnailWnd
    SetTimer, Check, Off
}
Return

Num()
{
    static hModule := DllCall("LoadLibrary","Str","oleacc","UPtr")
    hWnd := WinExist("ahk_class TaskListThumbnailWnd")
    If !hWnd
        Return, 0
    VarSetCapacity(IID,16)
    NumPut(0x11CF3C3D618736E0,IID,0,"Int64")
    NumPut(0x719B3800AA000C81,IID,8,"Int64")
    If !DllCall("oleacc\AccessibleObjectFromWindow","UPtr",hWnd
        ,"UInt",0xFFFFFFFC
        ,"UPtr",&IID
        ,"UPtr*",pAcc)
    {
        Stack := ComObjParameter(9,pAcc,1)
        StackSize := Stack.accChildCount // 3
        Return, StackSize
    }
    Return, 0
}

TaskBarHovering()
{
    MouseGetPos,,, hWnd
    Return, hWnd = WinExist("ahk_class Shell_TrayWnd")
}

TaskBarPos() {
    WinGetPos,X,Y,W,H,ahk_class Shell_TrayWnd
    return x=0 ? y=0 ? h<w ? "Top" : "Left" : "Bottom" : "Right"
}