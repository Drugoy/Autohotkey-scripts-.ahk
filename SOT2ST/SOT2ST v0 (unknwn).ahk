; http://www.autohotkey.com/board/topic/75243-is-it-possible-to-switch-windows-by-scrolling-over-taskbar/

#SingleInstance, Force

#If OverTaskBar()
WheelUp:: ControlSend MSTaskListWClass1, {Up}{Enter}, ahk_class Shell_TrayWnd
WheelDown:: ControlSend MSTaskListWClass1, {Down}{Enter}, ahk_class Shell_TrayWnd

OverTaskBar() {
   CoordMode mouse
   MouseGetPos,x
   return (x > A_ScreenWidth - 20)
}