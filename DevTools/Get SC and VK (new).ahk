   Menu, Tray, Icon, Shell32.dll, 45

; клавиши дополнительной клавиатуры и Pause, sc которых ф-ция MapVirtualKey не определяет
   ScVk := "45,13|11D,A3|135,6F|136,A1|137,2C|138,A5|145,90|147,24|148,26|149,21|"
         . "14B,25|14D,27|14F,23|150,28|151,22|152,2D|153,2E|15B,5B|15C,5C|15D,5D"

; клавиши мыши и их vk, а также Ctrl+Break и Clear
   KeysVK := "LButton,1|RButton,2|Ctrl+Break,3|MButton,4|XButton1,5|XButton2,6|"
           . "Clear,c|Shift,10|Ctrl,11|Alt,12"

   Height := 165  ; высота клиентской области, не включая заголовки вкладок

   Gui, Color, DAD6CA
   Gui, Add, Tab2, vTab gTab x0 y0 w200 h185 AltSubmit hwndhTab, Получить код|Клавиша по коду
   Tab = 2
   VarSetCapacity(RECT, 16)
   SendMessage, TCM_GETITEMRECT := 0x130A, 1, &RECT,, ahk_id %hTab%
   TabH := NumGet(RECT, 12)
   GuiControl, Move, Tab, % "x0 y0 w200 h" TabH + Height
   Gui, Add, Text, % "x8 y" TabH + 8 " w183 +" SS_GRAYFRAME := 0x8 " h" Height - 16

   Gui, Font, q5 s12, Verdana
   Gui, Add, Text, vAction x15 yp+7 w170 Center c0033BB, Нажмите клавишу
   Gui, Add, Text, vKey xp yp+35 wp Center Hidden

   Gui, Font, q5 c333333
   Gui, Add, Text, vTextVK xp+8 yp+37 Hidden, vk =
   Gui, Add, Text, vVK xp+35 yp w62 h23 Center Hidden
   Gui, Add, Text, vTextSC xp-35 yp+35 Hidden, sc =
   Gui, Add, Text, vSC xp+35 yp w62 h23 Center Hidden

   Gui, Font, s8
   Gui, Add, Button, vCopyVK gCopy xp+70 yp-35 w50 h22 Hidden, Copy
   Gui, Add, Button, vCopySC gCopy xp yp+33 wp hp Hidden, Copy

   Gui, Tab, 2
   Gui, Add, Text, % "x8 y" TabH + 8 " w183 +" SS_GRAYFRAME " h" Height - 16
   Gui, Add, Text, x15 yp+7 w170 c0033BB
      , Введите код`nв шестнадцатеричном формате без префикса "0x"

   Gui, Font, q5 s11
   Gui, Add, Text, xp yp+58, vk
   Gui, Add, Edit, vEditVK gGetKey xp+25 yp-2 w45 h23 Limit3 Uppercase Center
   Gui, Add, Text, vKeyVK xp+45 yp+2 w105 Center

   Gui, Add, Text, x15 yp+43, sc
   Gui, Add, Edit, vEditSC gGetKey xp+25 yp-2 w45 h23 Limit3 Uppercase Center
   Gui, Add, Text, vKeySC xp+45 yp+2 w105 Center
   Gui, Show, % "w199 h" TabH + Height - 1, Коды клавиш

   hHookKeybd := SetWindowsHookEx()
   OnExit, Exit
   OnMessage(0x6, "WM_ACTIVATE")
   OnMessage(0x102, "WM_CHAR")
   Return

Tab:                            ; whenever the user switches to a new tab, the output variable will
   If (Tab = 2 && !hHookKeybd)  ; be set to the previously selected tab number in the case of AltSubmit.
      hHookKeybd := SetWindowsHookEx()
   Else if (Tab = 1 && hHookKeybd)
      DllCall("UnhookWindowsHookEx", UInt, hHookKeybd), hHookKeybd := ""
   Return

Copy:
   GuiControlGet, Code,, % SubStr(A_GuiControl, -1)
   StringLower, GuiControl, A_GuiControl
   Clipboard := SubStr(GuiControl, -1) . SubStr(Code, 3)
   Return

GetKey:
   GuiControlGet, Code,, % A_GuiControl
   Code := RegExReplace(Code, "^0+")
   Code := "0x" . Code
   SetFormat, IntegerFast, H
   if A_GuiControl = EditVK
   {
      if (Code > 0xA5 && Code < 0xBA)
         Key := "", IsKey := 1

      Loop, parse, KeysVK, |
      {
         if (Substr(Code, 3) = RegExReplace(A_LoopField, ".*,(.*)", "$1"))
         {
            Key := RegExReplace(A_LoopField, "(.*),.*", "$1")
            IsKey = 1
            Break
         }
      }

      if !IsKey
      {
         Loop, parse, ScVk, |
         {
            if (Code = "0x" . RegExReplace(A_LoopField, ".*,(.*)", "$1"))
            {
               Code := RegExReplace(A_LoopField, "(.*),.*", "0x$1")
               IsCode = 1
               Break
            }
         }
         if !IsCode
            Code := DllCall("MapVirtualKey", UInt, Code, UInt, MAPVK_VK_TO_VSC := 0)
      }
   }
   else if (Code = 0x56 || Code > 0x1FF)
      Key := "", IsKey := 1

   if !IsKey
      Key := GetKeyNameText(Code)

   Key := RegExReplace(Key, "(.*)Windows", "$1Win")
   GuiControl,, % "Key" SubStr(A_GuiControl, -1), % Key
   Key := IsKey := IsCode := ""
   Return

GuiClose:
   ExitApp

Exit:
   if hHookKeybd
      DllCall("UnhookWindowsHookEx", UInt, hHookKeybd)
   ExitApp

WM_ACTIVATE(wp)
{
   global
   if (wp & 0xFFFF = 0 && hHookKeybd)
      DllCall("UnhookWindowsHookEx", UInt, hHookKeybd), hHookKeybd := ""
   if (wp & 0xFFFF && Tab = 2 && !hHookKeybd)
      hHookKeybd := SetWindowsHookEx()
   GuiControl,, Action, % wp & 0xFFFF = 0 ? "Активируйте окно" : "Нажмите клавишу"
}

SetWindowsHookEx()
{
   Return DllCall("SetWindowsHookEx"
            , Int, WH_KEYBOARD_LL := 13
            , UInt, RegisterCallback("LowLevelKeyboardProc", "Fast")
            , UInt, DllCall("GetModuleHandle", UInt, 0)
            , UInt, 0)
}

LowLevelKeyboardProc(nCode, wParam, lParam)
{
   static once, WM_KEYDOWN = 0x100, WM_SYSKEYDOWN = 0x104

   Critical
   SetFormat, IntegerFast, H
   vk := NumGet(lParam+0)
   Extended := NumGet(lParam+0, 8) & 1
   sc := (Extended<<8)|NumGet(lParam+0, 4)
   sc := sc = 0x136 ? 0x36 : sc
   Key := GetKeyNameText(sc)

   if (wParam = WM_SYSKEYDOWN || wParam = WM_KEYDOWN)
   {
      GuiControl,, Key, % Key
      GuiControl,, VK, % vk
      GuiControl,, SC, % sc
   }

   if !once
   {
      Controls := "Key|TextVK|VK|TextSC|SC|CopyVK|CopySC"
      Loop, parse, Controls, |
         GuiControl, Show, % A_LoopField
      once = 1
   }

   if Key Contains Ctrl,Alt,Shift,Tab
      Return CallNextHookEx(nCode, wParam, lParam)

   if (Key = "F4" && GetKeyState("Alt", "P"))  ; закрытие окна и выход по Alt + F4
      Return CallNextHookEx(nCode, wParam, lParam)

   Return nCode < 0 ? CallNextHookEx(nCode, wParam, lParam) : 1
}

CallNextHookEx(nCode, wp, lp)
{
   Return DllCall("CallNextHookEx", UInt, 0, Int, nCode, UInt, wp, UInt, lp)
}

GetKeyNameText(sc)
{
   VarSetCapacity(Key, A_IsUnicode ? 32 : 16)
   DllCall("GetKeyNameText", UInt, sc<<16, Str, Key, UInt, 16)
   if Key in Shift,Ctrl,Alt
      Key := "Left " . Key
   Return Key
}

WM_CHAR(wp, lp)
{
   global hBall
   SetWinDelay, 0
   CoordMode, Caret
   WinClose, ahk_id %hBall%
   GuiControlGet, Focus, Focus
   if !InStr(Focus, "Edit")
      Return

   if wp in 3,8,24,26   ; обработка Ctrl + C, BackSpace, Ctrl + X, Ctrl + Z
      Return

   if wp = 22   ; обработка Ctrl + V
   {
      GuiControlGet, Content,, % Focus
      if !StrLen(String := SubStr(Clipboard, 1, 3 - StrLen(Content)))
      {
         ShowBall("Буфер обмена не содержит текста.", "Ошибка!")
         Return 0
      }
      Loop, parse, String
      {
         Text .= A_LoopField
         if A_LoopField not in 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,A,B,C,D,E,F
         {
            ShowBall("Буфер обмена содержит недопустимые символы."
               . "`nДопустимые символы:`n0123456789ABCDEF", "Ошибка!")
            Return 0
         }
      }
      Control, EditPaste, % Text, % Focus, Коды клавиш
      Return 0
   }

   Char := Chr(wp)
   if Char not in 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,A,B,C,D,E,F
   {
      ShowBall("Допустимые символы:`n0123456789ABCDEF", Char " — недопустимый символ")
      Return 0
   }
   Return
}

ShowBall(Text, Title="")
{
   global
   WinClose, ahk_id %hBall%
   hBall := BalloonTip(A_CaretX+1, A_CaretY+15, Text, Title)
   SetTimer, BallDestroy, -2000
   Return

BallDestroy:
   WinClose, ahk_id %hBall%
   Return
}

BalloonTip(x, y, sText, sTitle = "", h_icon = 0)
{
   ; BalloonTip — это ToolTip с хвостиком
   ; h_icon — 1:Info, 2: Warning, 3: Error, n > 3: предполагается hIcon.

   TTS_NOPREFIX := 2, TTS_ALWAYSTIP := 1, TTS_BALLOON := 0x40, TTS_CLOSE := 0x80

   hWnd := DllCall("CreateWindowEx", UInt, WS_EX_TOPMOST := 8
                                   , Str, "tooltips_class32", Str, ""
                                   , UInt, TTS_NOPREFIX|TTS_ALWAYSTIP|TTS_BALLOON|TTS_CLOSE
                                   , Int, 0, Int, 0, Int, 0, Int, 0
                                   , UInt, 0, UInt, 0, UInt, 0, UInt, 0)
   VarSetCapacity(TOOLINFO, 40)
   NumPut(40, TOOLINFO)
   NumPut(0x20, TOOLINFO, 4)       ; TTF_TRACK = 0x20
   NumPut(&sText, TOOLINFO, 36)

   A_DHW := A_DetectHiddenWindows
   DetectHiddenWindows, On
   WinWait, ahk_id %hWnd%

   SendMessage, 1048,, 500         ; TTM_SETMAXTIPWIDTH
   SendMessage, 1028,, &TOOLINFO   ; TTM_ADDTOOL
   SendMessage, 1042,, x|(y<<16)   ; TTM_TRACKPOSITION
   SendMessage, 1041, 1, &TOOLINFO ; TTM_TRACKACTIVATE
   SendMessage, 1056 + (A_IsUnicode ? 1 : 0), h_icon, &sTitle      ; TTM_SETTITLEA и TTM_SETTITLEW
   SendMessage, 1036 + (A_IsUnicode ? 45 : 0),, &TOOLINFO     ; TTM_UPDATETIPTEXTA и TTM_UPDATETIPTEXTW

   DetectHiddenWindows, % A_DHW
   Return hWnd
}