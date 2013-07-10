/*  AHKControl by Lexikos
 *    Last updated 2012-06-02
 */

Hotkey, #q, AHKControl
Hotkey, #a, AHKControlActive

/*  HOTKEY LABELS

    AHKControl:
        Lists all running scripts and displays them in a popup menu.
        Each menu item opens a submenu to control that script.

    AHKControlActive:
        If the active window belongs to a script, a menu to control it
        is shown.  If the active window's title matches PathRegEx, all
        matching scripts are listed.  Otherwise, all scripts are listed.
    
    ExitAll:
        Exit all scripts; same as "Exit All" in the AHKControl menu.
    
    ExitSelf:
        Exit AHKControl.
    
    Panic:
        Use the Panic button to terminate runaway scripts (i.e. scripts
        that launch themselves recursively).
        NOTE:
          - taskkill.exe is required (this is not included in XP Home)
          - Affects any process whose name begins with "AutoHotkey"
          - Makes 10 attempts at terminating all matching processes

 */

; A tray icon can be used instead of a hotkey.  If disabled (0), the
; tray icon will still be shown if AHKControl's hotkeys are suspended.
EnableTrayIcon = 0

; Command line to run when a script directory is selected from an Edit menu.
; Supported placeholders:  $SCRIPT_PATH  $SCRIPT_DIR
BrowseAction = explorer.exe /select,$SCRIPT_PATH

; Command line to run when a file is selected from an Edit menu.
EditAction = edit $SCRIPT_PATH

; The following pattern should match the path of a script, within a
; window title.  The default pattern supports SciTE and Notepad++.
; This is used by the AHKControlActive subroutine (default Win+A).
PathRegEx = i)^\*?\K.*\.ahk(?= [-*] )

; If AHKControl is activated and there are more than this many scripts
; running, a "Panic?" message box will be shown.  Click Yes to terminate
; all scripts (by running the Panic subroutine).
PanicCount = 20

; The icon for AHKControl.
IconFile = user32.dll
IconNumber = 7

; Desired icon size. If specified, icons are resized automatically as necessary.
IconSize = 16

/*  END CONFIGURATION SECTION
 */

#SingleInstance force
#NoEnv
#NoTrayIcon

; Detect hidden script windows.
DetectHiddenWindows, On

; Define WM_COMMAND codes used by ScriptCommand.
Cmd_Open    = 65300
;-
Cmd_Reload  = 65400
Cmd_Edit    = 65401
Cmd_Pause   = 65403
Cmd_Suspend = 65404
;-
Cmd_ViewLines      = 65406
Cmd_ViewVariables  = 65407
Cmd_ViewHotkeys    = 65408
Cmd_ViewKeyHistory = 65409
;-
Cmd_Exit    = 65405

Process, Exist
this_pid := ErrorLevel
this_id := WinExist("ahk_class AutoHotkey ahk_pid " this_pid)

; Load standard status icons.
this_exe := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
SuspendedIcon       := MI_ExtractIcon(this_exe, 3, 16)
PausedIcon          := MI_ExtractIcon(this_exe, 4, 16)
PausedSuspendedIcon := MI_ExtractIcon(this_exe, 5, 16)

Menu, Root, Add  ; Dummy item to ensure the menu exists.

OnMessage(0x111, "WM_COMMAND")
OnMessage(0x404, "AHK_NOTIFYICON")

if IconFile
{
    ; Set window icon, which is used in AHKControl's menu whenever this
    ; script's icon can't be retrieved from the tray.
    if this_icon := MI_ExtractIcon(IconFile, IconNumber, IconSize)
        SendMessage 0x80, 0, this_icon,, ahk_id %this_id%  ; WM_SETICON = 0x80
    Menu, Tray, UseErrorLevel
    Menu, Tray, Icon, %IconFile%, %IconNumber%
}
if EnableTrayIcon
    Menu, Tray, Icon

return


WM_COMMAND(wParam) ; Handles some menu-item clicks and other events.
{
    global
    if A_Gui
        return
    if (wParam = 65404 || wParam = 65305) ; (File menu || tray menu) -> Suspend Hotkeys
    {
        if !EnableTrayIcon
        {
            if A_IsSuspended ; After the command is processed, it will *not* be suspended.
                Menu, Tray, NoIcon
            else
                Menu, Tray, Icon
        }
    }
    else if (wParam = 65405) ; Exit
    {
        gosub ExitSelf
        return 0
    }
}

AHK_NOTIFYICON(wParam, lParam) ; Handles tray icon events.
{
    global
    if (lParam = 0x202) ; WM_LBUTTONUP
    {   
        if !EnableTrayIcon
        {
            Suspend, Off
            Menu, Tray, NoIcon
        }
        else
            RebuildAndShowMenu()
    }
    else if (lParam = 0x205) ; WM_RBUTTONUP
    {
        RebuildAndShowMenu()
        return 0
    }
}

ExitAll:
    if Script_Count > 1
    {
        if (Script_collective != "these") {
            MsgBox, 0x40014, AHKControl, Are you sure you want to exit %Script_collective% AutoHotkey scripts?
            ifMsgBox, No
                return
        }
        Loop, %Script_Count%
            if (Script_%A_Index% != this_id)
                WinClose, % "ahk_id " Script_%A_Index%
        Sleep 500
        ifWinNotExist, ahk_class AutoHotkey,, %A_ScriptFullPath%
            ExitApp
        else ; Some script(s) other than this one still running, so don't terminate yet.
            return
    }
ExitSelf:
    MsgBox, 0x40034, AHKControl, Are you sure you want to exit AHKControl?
    ifMsgBox, Yes
        ExitApp
    return

AHKControlActive:
    WinGet, pid, PID, A
    ifWinExist ahk_pid %pid% ahk_class AutoHotkey
    {   ; An AutoHotkey script owns the active window. Show its menu.
        KeyWait, LWin
        RebuildAndShowMenu(WinExist())
        return
    }
    WinGetTitle, title, A
    if RegExMatch(title, PathRegEx, path) && WinExist(path " ahk_class AutoHotkey")
    {   ; Probably an editor with a script open. Show any matching scripts.
        KeyWait, LWin
        RebuildAndShowMenu(0, path)
        return
    }
AHKControl:
    KeyWait, LWin
    RebuildAndShowMenu()
    return

ScriptOpen:
    id := %A_ThisMenu%
    WinShow, ahk_id %id%
    WinActivate, ahk_id %id%
return

ScriptEdit:
    id := %A_ThisMenu%
    if GetKeyState("Shift") || !OpenIncludesMenu(id)
        EditScriptFile(GetFileToEdit(id))
return

ScriptKill:
    id := %A_ThisMenu%
    WinGet, id, PID, ahk_id %id%
    Run, taskkill /PID %id% /F,, Hide
return

ScriptCommand:
    ; Get the window ID associated with this menu.
    id := %A_ThisMenu%
    cmd := RegExReplace(A_ThisMenuItem, "[^\w#@$?\[\]]") ; strip invalid chars
    cmd := Cmd_%cmd%
    PostMessage, 0x111, %cmd%, , , ahk_id %id% ; WM_COMMAND
return

ScriptShowTrayMenu:
    ShowScriptTrayMenu(%A_ThisMenu%)
return
ScriptShowTrayMenuDirect:
    ShowScriptTrayMenu(Script_%A_ThisMenuItemPos%)
return

Panic:
    Critical
    Loop 10
        RunWait taskkill.exe /F /FI "IMAGENAME eq AutoHotkey*" /FI "PID ne %this_pid%",, Hide
return

ShowScriptTrayMenu(hWnd)
{
    ifWinNotExist, ahk_id %hWnd% ; set LFW
        return
    PostMessage, 1028, 0, 0x204, , ahk_id %hWnd% ; WM_RBUTTONDOWN
    PostMessage, 1028, 0, 0x205, , ahk_id %hWnd% ; WM_RBUTTONUP
}

GetFileToEdit(id)
{
    WinGetTitle, title, ahk_id %id%
    if ! RegExMatch(title, ".*?(?= - AutoHotkey v)", script_path)
    {   ; Compiled scripts omit " - AutoHotkey vVERSION".
        if SubStr(title,-3) = ".exe"
            script_path := SubStr(title,1,-3) . "ahk"
    }
    ifExist, %script_path%
        return script_path
}

EditScriptFile(script_path)
{
    global EditAction
    if EditAction !=
    {
        StringReplace, action, EditAction, $SCRIPT_PATH, %script_path%
        Run, %action%,, UseErrorLevel
        if ErrorLevel != ERROR
            return
    }
    Run, edit %script_path%,, UseErrorLevel
    if ErrorLevel = ERROR
        Run, notepad.exe "%script_path%"
}

OpenIncludesMenu(id, require_multiple_scripts=true)
{
    global BrowseAction, EditAction
    static action, SCRIPT_DIR, SCRIPT_PATH
    
    SCRIPT_PATH := GetFileToEdit(id)
    if !(includes := ListIncludes(SCRIPT_PATH))
        return false
    
    ; Don't open the menu if only one script file would be in it.
    if (require_multiple_scripts && !InStr(includes, "|"))
        return false
    
    SplitPath, SCRIPT_PATH,, script_dir
    
    Menu, Includes, Add, %script_dir%, OpenScriptDir
    Menu, Includes, Add

    script_dir .= "\"
    
    Loop, Parse, includes, |
    {
        path := A_LoopField
        if (SubStr(path,1,StrLen(script_dir)) = script_dir)
            path := SubStr(path, StrLen(script_dir)+1)
        path := ((A_Index<10) ? "&" : "") A_Index ". " path
        Menu, Includes, Add, %path%, OpenIncludeFile
    }

    Menu, Includes, Show
    Menu, Includes, DeleteAll
    
    return true

OpenScriptDir:
    action := BrowseAction
    StringReplace, action, action, $SCRIPT_PATH, %SCRIPT_PATH%
    StringReplace, action, action, $SCRIPT_DIR, %SCRIPT_DIR%
    Run, %action%
return

OpenIncludeFile:
    SCRIPT_PATH := SubStr(A_ThisMenuItem,InStr(A_ThisMenuItem, ".")+2)
    if (SubStr(SCRIPT_PATH,2,1) != ":")
        SCRIPT_PATH := SCRIPT_DIR . SCRIPT_PATH
    EditScriptFile(SCRIPT_PATH)
return
}


RebuildAndShowMenu(script_id_to_show=0, script_path_to_show="")
{
    local h_menu, i, id, pid, title, pos, hasTrayIcon, filename
        , h_icon, h_bitmap, width, height, new_bitmap, ext, _, menu_item_text
        , mainMenu, fileMenu, isPaused, isSuspended, ahk_list, script_is_hung
        , script, script_id, script_title, script_path, script_ahk_version
        , script_pid, can_command_script
    
    Loop, Parse, BitmapsToCleanUp, `,
        DllCall("DeleteObject", "uint", A_LoopField)
    Loop, Parse, IconsToCleanUp, `,
        DllCall("DestroyIcon", "uint", A_LoopField)
    BitmapsToCleanUp =
    IconsToCleanUp =
    
    MI_RemoveIcons("Root")
    Menu, Root, DeleteAll
    
    ; Get handle to menu, for use with SetMenuItemBitmap().
    h_menu := MI_GetMenuHandle("Root")
    
    ; List all AutoHotkey main windows.
    WinGet, ahk_list, List, ahk_class AutoHotkey
    
    if (ahk_list > PanicCount)
    {
        MsgBox 4,, Panic?
        ifMsgBox Yes
        {
            gosub Panic
            return
        }
    }
    
    i = 1
    Loop, %ahk_list%
    {
        script_id := ahk_list%A_Index%
        
        if (script_id_to_show && script_id_to_show != script_id)
            continue
        
        ; Set LFW for convenience; also filter by script path if specified.
        if !WinExist(script_path_to_show " ahk_id " script_id)
            continue

        ; Delete previous script sub-menu.
        if Script_%i% && Script_%i%_HasMenu
            Menu, Script_%i%, DeleteAll

        Script_%i% = %script_id%
    
        WinGetTitle, script_title
        
        ; Get filename and ahk version from title of window (if it is not a compiled script).
        if !RegExMatch(script_title, "s)(?<_path>.*?)(?: - AutoHotkey (?<_ahk_version>v\d.\S+))?$", script)
        {
            ; This is probably a compiled script, where only the script's path is shown in the title
            ; and version info can be retrieved from the script file itself.
            script_path := script_title
            FileGetVersion, script_ahk_version, %script_path%
            script_ahk_version = v%script_ahk_version%
        }

        WinGet, script_pid, PID
        
        ; Get the tray icon of the script, if present.  This fails on Windows 7.
        hasTrayIcon := GetTrayIconInfo(script_pid
            , _  ; not needed
            , _  ;
            , _  ;
            , h_icon
            , menu_item_text := "")
        
        ; There are at least two cases where our commands will fail:
        ;   1) The target window isn't responding to messages.
        ;   2) UAC is enabled and the target process is running at a
        ;      higher integrity level than AHKControl.
        ; Both conditions can be detected by sending a message with a
        ; short timeout (which fails completely in the second case).
        ; However, if the window hasn't checked for messages in the last
        ; 5 seconds, IsHungAppWindow() returns true and we can avoid the
        ; delay caused by SendMessageTimeout().
        if DllCall("IsHungAppWindow", "uint", script_id)
        {
            script_is_hung := true
            can_command_script := true  ; Assume we can.
        }
        else
        {
            DllCall("SendMessageTimeout", "uint", script_id, "uint", 1029  ; AHK_RETURN_PID = 1029
                    , "uint", 0, "uint", 0, "uint", 2, "uint", 500, "uint*", 0)
            script_is_hung := A_LastError = 1460 ; ERROR_TIMEOUT
            ; If it failed with ERROR_ACCESS_DENIED, we won't be able to
            ; command the script, but we can still trigger the tray menu.
            can_command_script := A_LastError != 5
        }
        
        if !(h_icon || script_is_hung)
        {
            ; Since we couldn't get an icon from the tray, try to get one
            ; from the window.  This will only work if the script has set
            ; an icon using WM_SETICON or if it handles WM_GETICON.
            SendMessage, 0x7F, 0,,, ahk_id %script_id% ; WM_GETICON, ICON_SMALL
            if ErrorLevel
                h_icon := ErrorLevel
        }
        
        if menu_item_text =
            ; Since we couldn't get anything meaningful from the system tray, show the script's filename.
            SplitPath, script_path, menu_item_text
        
        ; Escape '&' characters (these have special meaning in menu items).
        StringReplace, menu_item_text, menu_item_text, &, &&, All
        
        if script_is_hung
            menu_item_text .= " (not responding)"
        
        ; Get script status for Pause/Suspend checkmarks and default icons.
        else {
            ; Force the script to update its Pause/Suspend checkmarks.
            SendMessage, 0x211,,,, ahk_id %script_id%  ; WM_ENTERMENULOOP
            SendMessage, 0x212,,,, ahk_id %script_id%  ; WM_EXITMENULOOP
        }
        mainMenu := DllCall("GetMenu", "uint", script_id)
        fileMenu := DllCall("GetSubMenu", "uint", mainMenu, "int", 0)
        isPaused := DllCall("GetMenuState", "uint", fileMenu, "uint", 4, "uint", 0x400) >> 3 & 1
        isSuspended := DllCall("GetMenuState", "uint", fileMenu, "uint", 5, "uint", 0x400) >> 3 & 1
        DllCall("CloseHandle", "uint", fileMenu)
        DllCall("CloseHandle", "uint", mainMenu)
        
        if Script_%i%_HasMenu := can_command_script
        {
            ;
            ; Build sub-menu
            ;
            
            if (script_id_to_show || script_path_to_show)
            {
                ; script_id_to_show: Caller requested only this script's menu be shown.
                ;   Since the root menu won't be shown, include the script's name.
                ; For simplicity, do the same for script_path_to_show even though the
                ; root menu will be shown if multiple instances of the script are running.
                script_ahk_version := menu_item_text " - " script_ahk_version
            }
            
            if script_ahk_version !=
            {
                Menu, Script_%i%, Add, %script_ahk_version%, ScriptOpen
                Menu, Script_%i%, Disable, %script_ahk_version%
                Menu, Script_%i%, Add
            }
    
            if !script_is_hung
            {
                Menu, Script_%i%, Add, Tray& Menu       , ScriptShowTrayMenu
                Menu, Script_%i%, Add
                
                Menu, Script_%i%, Add, &Open                , ScriptOpen
                Menu, Script_%i%, Add, &Reload              , ScriptCommand   
            }
            
            SplitPath, script_path,,, ext
            if (ext != "exe") || FileExist(SubStr(script_path,1,-4) ".ahk")
                Menu, Script_%i%, Add, &Edit            , ScriptEdit
            
            if !script_is_hung
            {
                Menu, Script_%i%, Add, &Pause               , ScriptCommand
                if isPaused
                    Menu, Script_%i%, Check, &Pause
                else if (script_id = this_id)
                    Menu, Script_%i%, Disable, &Pause
                Menu, Script_%i%, Add, &Suspend             , ScriptCommand
                if isSuspended
                    Menu, Script_%i%, Check, &Suspend
                if (ext != "exe") {
                    Menu, Script_%i%, Add
                    Menu, Script_%i%, Add, View &Lines      , ScriptCommand
                    Menu, Script_%i%, Add, View &Variables  , ScriptCommand
                    Menu, Script_%i%, Add, View &Hotkeys    , ScriptCommand
                    Menu, Script_%i%, Add, View Key &History, ScriptCommand
                }
                Menu, Script_%i%, Add
                Menu, Script_%i%, Add, E&xit                , ScriptCommand
            }
            
            Menu, Script_%i%, Add, K&ill                , ScriptKill
            
            ; Add sub-menu to root menu.
            Menu, Root, Add, &%i%  %menu_item_text%, :Script_%i%
        }
        else ; ErrorLevel = FAIL
        {
            ; AHKControl will be unable to command this script, so hook the
            ; menu item directly to the script's tray menu if it has one.
            Menu, Root, Add, &%i%  %menu_item_text%, ScriptShowTrayMenuDirect
        }
        
        if !h_icon
        {
            if (ext = "exe" && h_icon := MI_ExtractIcon(script_path, 1, 16))
                IconsToCleanUp .= (IconsToCleanUp ? "," : "") . h_icon
            
            ; Show standard Paused, Suspended, or Paused/Suspended icon where applicable.
            if isPaused && isSuspended
                h_icon := PausedSuspendedIcon
            else if isPaused
                h_icon := PausedIcon
            else if isSuspended
                h_icon := SuspendedIcon
        }
        ; Set menu item icon
        if h_icon
        {
            MI_SetMenuItemIcon(h_menu, i, h_icon, 1, IconSize, h_bitmap, h_usedicon)
            if (h_usedicon && h_usedicon != h_icon)
                IconsToCleanUp .= (IconsToCleanUp ? "," : "") . h_usedicon
            if (h_bitmap)
                BitmapsToCleanUp .= (BitmapsToCleanUp ? "," : "") . h_bitmap
        }
        i += 1
    }
    
    Script_Count := i-1

    Script_collective := (script_id_to_show || script_path_to_show) ? "these" : "all"
    if (script_id_to_show || (script_path_to_show && Script_Count = 1))  ; Caller requested only this script's menu be shown.
    {
        if (Script_1_HasMenu)
            MI_ShowMenu("Script_1")
        else
            ShowScriptTrayMenu(Script_1)
        return
    }

    Menu, Root, Add
    Menu, Root, Add, E&xit All, ExitAll

    ; Give E&xit an appropriate icon.
    VarSetCapacity(mii,48,0), NumPut(48,mii), NumPut(0x80,mii,4), NumPut(8,mii,44)
    DllCall("SetMenuItemInfo","uint",h_menu,"uint",i,"uint",1,"uint",&mii)
    
    MI_SetMenuStyle(h_menu, 0x04000000) ; MNS_CHECKORBMP
    MI_ShowMenu(h_menu)
}


; Adapted from Sean's TrayIcons()
;   http://www.autohotkey.com/forum/topic17314.html
GetTrayIconInfo(TargetPID, ByRef hWnd, ByRef uID, ByRef nMsg, ByRef hIcon, ByRef sTooltip)
{
    IconFound = 0
    uID = 0
    nMsg = 0
    hIcon = 0
    sTooltip =
    
    if A_OSVersion in WIN_7,WIN_8
        return false

    TBWnd := GetTrayBarHwnd()
    WinGet, pidTaskbar, PID, ahk_id %TBWnd%

    hProc := DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
    pRB := DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 20, "Uint", 0x1000, "Uint", 0x4)

    VarSetCapacity(btn, 20)
    VarSetCapacity(nfo, 24)
    VarSetCapacity(sTooltip, 128)
	VarSetCapacity(wTooltip, 128 * 2)

    SendMessage, 0x418, 0, 0,, ahk_id %TBWnd%  ; TB_BUTTONCOUNT

    Loop, %ErrorLevel%
    {
        SendMessage, 0x417, A_Index - 1, pRB,, ahk_id %TBWnd% ; TB_GETBUTTON

        DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pRB, "Uint", &btn, "Uint", 20, "Uint", 0)

        dwData    := NumGet(btn, 12)
        iString   := NumGet(btn, 16)

        DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "Uint", &nfo, "Uint", 24, "Uint", 0)

        hWnd  := NumGet(nfo, 0)

        WinGet, pid, PID, ahk_id %hWnd%

        If TargetPID = %pid%
        {
            uID   := NumGet(nfo, 4)
            nMsg  := NumGet(nfo, 8)
            hIcon := NumGet(nfo, 20)
            
            DllCall("ReadProcessMemory", "Uint", hProc, "Uint", iString, "str", wTooltip, "Uint", 128 * 2, "Uint", 0)
            if A_IsUnicode
                sTooltip := wTooltip
            else
                DllCall("WideCharToMultiByte", "Uint", 0, "Uint", 0, "str", wTooltip, "int", -1, "str", sTooltip, "int", 128, "Uint", 0, "Uint", 0)
			
            IconFound = 1
            break
        }
    }

    DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pRB, "Uint", 0, "Uint", 0x8000)
    DllCall("CloseHandle", "Uint", hProc)

    If IconFound = 0
        hWnd = 0

    return IconFound
}
; Based on Sean's GetTrayBar()
;   http://www.autohotkey.com/forum/topic17314.html
GetTrayBarHwnd()
{
    WinGet, ControlList, ControlList, ahk_class Shell_TrayWnd
    RegExMatch(ControlList, "(?<=ToolbarWindow32)\d+(?!.*ToolbarWindow32)", nTB)

    Loop, %nTB%
    {
        ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
        hParent := DllCall("GetParent", "Uint", hWnd)
        WinGetClass, sClass, ahk_id %hParent%
        If sClass != SysPager
            Continue
        return hWnd
    }

    return 0
}

