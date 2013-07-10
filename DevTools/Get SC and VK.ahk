/******************************************************************************************************************

Name        ... GenerateVirtualKeyCode
ver         ... 0.3

coded by    ... IsNull (rcb-hook by sean)
__________________________________________________________________________________________________________________
Grundkonzept des rcb-Hooks basiert auf Seans post hier:
http://www.autohotkey.com/forum/post-127490.html#127490
*******************************************************************************************************************
*/

#NoEnv 
#Persistent
OnExit, CleanUP
SendMode Input 
SetBatchLines, -1
SetWorkingDir %A_ScriptDir% 
;_________________________________________________________________________________________________________________

GlobalLogBuffer := ""

;Erstellt einen Hook, der auf eine Callback Funktion in diesem Skript zeigt
hHookKeybd := SetWindowsHookEx(WH_KEYBOARD_LL := 13, RegisterCallback("KeyboardHook", "Fast"))


;*********************      MINIMALES GUI     *******************************************************************
Gui, add, Edit, w100 +readonly vCatchCtrl, [Press your Key]
Gui, add, ListView, w500 h300 gLV_SELECTION_CHANGED +AltSubmit, Virtual Key|Scan Code

Gui, add, TAB2, w450 h200, Hotkey| Send

Gui, Tab, 1
    Gui, add, Text,, Working AHK Code to catch the Key:
    Gui, Font, s12, Lucida Console
    Gui, add, Edit,+ReadOnly cblue w400 h100 vCodeToCatch
    Gui, Font

Gui, Tab, 2
    Gui, add, Text,, Working AHK Code to Send the Key:
    Gui, Font, s12, Lucida Console
    Gui, add, Edit,+ReadOnly cblue w400 h100 vCodeToSend
    Gui, Font

gui, show,, GenerateVirtualKeyCode Helper
return
/*
************************************END OF AUTOEXECUTION**********************************************************
*/

LV_SELECTION_CHANGED:
    if(A_GuiEvent == "I"){
        LV_GetText(outVK, A_EventInfo, 1)
        LV_GetText(outSC, A_EventInfo, 2)
       
        GuiControl,, CodeToSend, % GenerateAHKSend(outVK, outSC)
        GuiControl,, CodeToCatch, % GenerateAHKHotkey(outVK, outSC)
    }
return


GenerateAHKSend(vk, sc){
    code =
    (
    Send, {vk%vk%sc%sc%}
    )
    return code
}
GenerateAHKHotkey(vk, sc){
    code =
    (Ltrim
    vk%vk%sc%sc%::
        ; Here goes your Code
    return
    )
    return code
}


GuiClose:
ExitApp

CleanUP:
    UnhookWindowsHookEx(hHookKeybd)
    ExitApp


/*****************************************************************************************************************
CallBack Funktion; (f?r Keyboard hook)
******************************************************************************************************************
*/
KeyboardHook(nCode, wParam, lParam)
{
   global
   Critical
   res := CallNextHookEx(nCode, wParam, lParam)
   
   If (!nCode){
      vkCode := NumGet(lParam+0, 0)
      scCode := NumGet(lParam+0, 4)
      SetFormat, integer, hex ;set Format to hex
      vkCode += 0
      scCode += 0
      GotKey(vkCode, scCode)
   }
   return res
}

GotKey(vkCode, scCode){
    GuiControlGet, OutputVar, FocusV
    if("CatchCtrl" == OutputVar){
        lastRow := LV_GetCount()
        LV_GetText(outVK, lastRow, 1)
        LV_GetText(outSC, lastRow, 2)
       
        if(!(outVK == vkCode && outSC == scCode)){ ;omit duplicates
            LV_Add("", vkCode, scCode)
        }
    }
}



SetWindowsHookEx(idHook, pfn)
{
   Return DllCall("SetWindowsHookEx", "int", idHook, "Uint", pfn, "Uint", DllCall("GetModuleHandle", "Uint", 0), "Uint", 0)
}

UnhookWindowsHookEx(hHook)
{
   Return DllCall("UnhookWindowsHookEx", "Uint", hHook)
}

CallNextHookEx(nCode, wParam, lParam, hHook = 0)
{
   Return DllCall("CallNextHookEx", "Uint", hHook, "int", nCode, "Uint", wParam, "Uint", lParam)
}