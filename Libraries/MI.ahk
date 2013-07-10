;
;  Menu Icons v2.21
;   by Lexikos
;


; Associates an icon with a menu item.
; NOTE: On versions of Windows other than Vista, the menu MUST be shown with
;       MI_ShowMenu() for the icons to appear.
;
;   MenuNameOrHandle
;       The name or handle of a menu. When setting icons for multiple items,
;       it is more efficient to use a handle returned by MI_GetMenuHandle("menuname").
;   ItemPos
;       The position of the menu item, where 1 is the first item.
;   FilenameOrHICON
;       The filename or handle of an icon.
;       SUPPORTS EXECUTABLE FILES ONLY (EXE/DLL/ICL/CPL/etc.)
;   IconNumber
;       The icon group to use (if omitted, it defaults to 1.)
;       This is not used if FilenameOrHICON specifies an icon handle.
;   IconSize
;       The desired width and height of the icon. If omitted, the system's small icon size is used.
;   h_bitmap
;   h_icon
;       v2.2: These parameters are no longer used as MI now automatically deletes the
;       icon/bitmap if a new icon/bitmap is being set.
;     OBSOLETE:
;       These are set to the bitmap or icon resources which are used.
;       Bitmaps and icons can be deleted as follows:
;           DllCall("DeleteObject", "uint", h_bitmap)
;           DllCall("DestroyIcon", "uint", h_icon)
;       This is only necessary if the menu item displaying these resources
;       is manually removed.
;       Usually only one of h_icon or h_bitmap will be used, and the other will be 0 (NULL).
;
; OPERATING SYSTEM NOTES:
;
; Windows 2000 and above:
;   PrivateExtractIcons() is used to extract the icon.
;
; Older versions of Windows:
;   PrivateExtractIcons() is not available, so ExtractIconEx() is used.
;   As a result, a 16x16 or 32x32 icon will be loaded. If a size is specified,
;   the icon may be stretched to fit. If no size is specified, 16x16 is used.
;
MI_SetMenuItemIcon(MenuNameOrHandle, ItemPos, FilenameOrHICON, IconNumber=1, IconSize=0, ByRef unused1="", ByRef unused2="")
{
    ; Set for compatibility with older scripts:
    unused1=0
    unused2=0
    
    if MenuNameOrHandle is integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)
    
    if !h_menu
        return false
    
    if ItemPos < 1 ; Offset from last item.
        ItemPos += DllCall("GetMenuItemCount","uint",h_menu)
    
    if FilenameOrHICON is integer
    {
        ; May be 0 to remove icon.
        h_icon := FilenameOrHICON
        ; Copy and potentially resize the icon. Since the caller is probably "caching"
        ; icon handles or assigning them to multiple items, we don't want to delete
        ; it if/when a future call to this function re-sets this item's icon.
        if h_icon
            h_icon := DllCall("CopyImage","uint",h_icon,"uint",1
                                ,"int",IconSize,"int",IconSize,"uint",0)
        ; else caller wants to remove and delete existing icon.
    }
    else
    {
        ; Load icon from file. Remember to clean up this icon if we end up using a bitmap.
        ; Resizing is not necessary in this case since MI_ExtractIcon already does that.
        if !(h_icon := MI_ExtractIcon(FilenameOrHICON, IconNumber, IconSize))
            return false
    }
    
    ; Windows Vista supports 32-bit alpha-blended bitmaps in menus. Note that
    ; A_OSVersion does not report WIN_VISTA when running in compatibility mode.
    ; To get nice icons on other versions of Windows, we need to owner-draw.
    ; DON'T TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING:
    ;   use_bitmap MUST have the same value for each use on a given menu item.
    if A_OSVersion in WIN_VISTA,WIN_7
        use_bitmap := true
    
    ; Get the previous bitmap or icon handle.
    VarSetCapacity(mii,48,0), NumPut(48,mii), NumPut(0xA0,mii,4)
    if DllCall("GetMenuItemInfo","uint",h_menu,"uint",ItemPos-1,"uint",1,"uint",&mii)
        h_previous := use_bitmap ? NumGet(mii,44,"int") : NumGet(mii,32,"int")

    if use_bitmap
    {
        if h_icon
        {
            h_bitmap := MI_GetBitmapFromIcon32Bit(h_icon, IconSize, IconSize)
            
            ; The icon we loaded/copy we created is no longer needed.
            DllCall("DestroyIcon","uint",h_icon)
            ; Don't try to destroy the now invalid handle again:
            h_icon := 0
            
            if !h_bitmap
                return false
        }
        else
            ; Caller wants to remove and delete existing icon.
            h_bitmap := 0
        
        NumPut(0x80,mii,4) ; fMask: Set hbmpItem only, not dwItemData.
        , NumPut(h_bitmap,mii,44) ; hbmpItem = h_bitmap
    }
    else
    {
        ; Associate the icon with the menu item. Relies on the probable case that no other
        ; script or dll will use dwItemData. If other scripts need to associate data with
        ; an item, MI should be expanded to allow it.
        NumPut(h_icon,mii,32) ; dwItemData = h_icon
        , NumPut(-1,mii,44) ; hbmpItem = HBMMENU_CALLBACK
    }

    if DllCall("SetMenuItemInfo","uint",h_menu,"uint",ItemPos-1,"uint",1,"uint",&mii)
    {   
        ; Only now that we know it's a success, delete the previous icon or bitmap.
        if use_bitmap
        {   ; Exclude NULL and predefined HBMMENU_ values (-1, 1..11).
            if (h_previous < -1 || h_previous > 11)
                DllCall("DeleteObject","uint",h_previous)
        } else
            DllCall("DestroyIcon","uint",h_previous)
        
        return true
    }
    ; ELSE FAIL
    if h_icon
        DllCall("DestroyIcon","uint",h_icon)
    return false
}

; v2.2: This should be used to remove and delete all icons in a menu before deleting the menu.
MI_RemoveIcons(MenuNameOrHandle)
{
    if MenuNameOrHandle is integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)
    
    if !h_menu
        return
    
    Loop % DllCall("GetMenuItemCount","uint",h_menu)
        MI_SetMenuItemIcon(h_menu, A_Index, 0)
}

; Set a menu item's associated bitmap.
; hBitmap can be a handle to a bitmap, or a HBMMENU value (see below.)
MI_SetMenuItemBitmap(MenuNameOrHandle, ItemPos, hBitmap)
{
    if MenuNameOrHandle is integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)
    
    if !h_menu
        return false
    
    VarSetCapacity(mii,48,0), NumPut(48,mii), NumPut(0x80,mii,4), NumPut(hBitmap,mii,44)
    return DllCall("SetMenuItemInfo","uint",h_menu,"uint",ItemPos-1,"uint",1,"uint",&mii)
}
/*
HBMMENU_SYSTEM              =  1
HBMMENU_MBAR_RESTORE        =  2
HBMMENU_MBAR_MINIMIZE       =  3
HBMMENU_MBAR_CLOSE          =  5
HBMMENU_MBAR_CLOSE_D        =  6
HBMMENU_MBAR_MINIMIZE_D     =  7
HBMMENU_POPUP_CLOSE         =  8
HBMMENU_POPUP_RESTORE       =  9
HBMMENU_POPUP_MAXIMIZE      = 10
HBMMENU_POPUP_MINIMIZE      = 11
*/

;
; General Functions
;

; Gets a menu handle from a menu name.
; Adapted from Shimanov's Menu_AssignBitmap()
;   http://www.autohotkey.com/forum/topic7526.html
MI_GetMenuHandle(menu_name)
{
    static   h_menuDummy
    ; v2.2: Check for !h_menuDummy instead of h_menuDummy="" in case init failed last time.
    If !h_menuDummy
    {
        Menu, menuDummy, Add
        Menu, menuDummy, DeleteAll

        Gui, 99:Menu, menuDummy
        ; v2.2: Use LastFound method instead of window title. [Thanks animeaime.]
        Gui, 99:+LastFound

        h_menuDummy := DllCall("GetMenu", "uint", WinExist())

        Gui, 99:Menu
        Gui, 99:Destroy
        
        ; v2.2: Return only after cleaning up. [Thanks animeaime.]
        if !h_menuDummy
            return 0
    }

    Menu, menuDummy, Add, :%menu_name%
    h_menu := DllCall( "GetSubMenu", "uint", h_menuDummy, "int", 0 )
    DllCall( "RemoveMenu", "uint", h_menuDummy, "uint", 0, "uint", 0x400 )
    Menu, menuDummy, Delete, :%menu_name%
    
    return h_menu
}

; Valid (and safe to use) styles:
;   MNS_AUTODISMISS  0x10000000
;   MNS_CHECKORBMP   0x04000000  The same space is reserved for the check mark and the bitmap.
;   MNS_NOCHECK      0x80000000  No space is reserved to the left of an item for a check mark.
MI_SetMenuStyle(MenuNameOrHandle, style)
{
    if MenuNameOrHandle is integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)
    
    if !h_menu
        return
        
    VarSetCapacity(mi,28,0), NumPut(28,mi)
    NumPut(0x10,mi,4) ; fMask=MIM_STYLE
    NumPut(style,mi,8)
    DllCall("SetMenuInfo","uint",h_menu,"uint",&mi)
}

; Extract an icon from an executable, DLL or icon file.
MI_ExtractIcon(Filename, IconNumber, IconSize)
{
    static ExtractIconEx
    ; LoadImage is not used..
    ; ..with exe/dll files because:
    ;   it only works with modules loaded by the current process,
    ;   it needs the resource ordinal (which is not the same as an icon index), and
    ; ..with ico files because:
    ;   it can only load the first icon (of size %IconSize%) from an .ico file.
    
    ; If possible, use PrivateExtractIcons, which supports any size of icon.
    if (IconSize != 16 && IconSize != 32)
    {
        if A_OSVersion in WIN_7,WIN_XP,WIN_VISTA,WIN_2003,WIN_2000
        {
            if DllCall("PrivateExtractIcons"
                ,"str",Filename,"int",IconNumber-1,"int",IconSize,"int",IconSize
                ,"uint*",h_icon,"uint*",0,"uint",1,"uint",0,"int")
            {
                return h_icon
            }
        }
    }
    if !ExtractIconEx
        ExtractIconEx := MI_DllProcAorW("shell32","ExtractIconEx")
    ; Use ExtractIconEx, which only returns 16x16 or 32x32 icons.
    if DllCall(ExtractIconEx,"str",Filename,"int",IconNumber-1
                ,"uint*",h_icon,"uint*",h_icon_small,"uint",1)
    {
        SysGet, SmallIconSize, 49
        
        ; Use the best-fit size; delete the other. Defaults to small icon.
        if (IconSize <= SmallIconSize) {
            DllCall("DestroyIcon","uint",h_icon)
            h_icon := h_icon_small
        } else
            DllCall("DestroyIcon","uint",h_icon_small)
        
        ; I think PrivateExtractIcons resizes icons automatically,
        ; so resize icons returned by ExtractIconEx for consistency.
        if (h_icon && IconSize)
            h_icon := DllCall("CopyImage","uint",h_icon,"uint",1,"int",IconSize
                                ,"int",IconSize,"uint",4|8)
    }

    return h_icon ? h_icon : 0
}

;
; Owner-Drawn Menu Functions
;

; Sub-classes a window from THIS process to owner-draw menu icons.
; This allows the menu to be shown by means other than MI_ShowMenu().
MI_EnableOwnerDrawnMenus(hwnd="")
{
    if (hwnd="") {  ; Use the script's main window if hwnd was omitted.
        dhw := A_DetectHiddenWindows
        DetectHiddenWindows, On
        Process, Exist
        hwnd := WinExist("ahk_class AutoHotkey ahk_pid " ErrorLevel)
        DetectHiddenWindows, %dhw%
    }
    if !hwnd
        return
    wndProc := RegisterCallback("MI_OwnerDrawnMenuItemWndProc","",4
        ,DllCall("GetWindowLong","uint",hwnd,"uint",-4))
    return DllCall("SetWindowLong","uint",hwnd,"int",-4,"int",wndProc,"uint")
}

; Shows a menu, allowing owner-drawn icons to be drawn.
MI_ShowMenu(MenuNameOrHandle, x="", y="")
{
    static hInstance, hwnd, ClassName := "OwnerDrawnMenuMsgWin"
        , CreateWindowEx

    if MenuNameOrHandle is integer
        h_menu := MenuNameOrHandle
    else
        h_menu := MI_GetMenuHandle(MenuNameOrHandle)
    
    if !h_menu
        return false
    
    if !hwnd
    {   ; Create a message window to receive owner-draw messages from the menu.
        ; Only one window is created per instance of the script.
    
        if !hInstance
            hInstance := DllCall("GetModuleHandle", "UInt", 0)

        ; Register a window class to associate OwnerDrawnMenuItemWndProc()
        ; with the window we will create.
        wndProc := RegisterCallback("MI_OwnerDrawnMenuItemWndProc","",4,0)
        if !wndProc {
            ErrorLevel = RegisterCallback
            return false
        }
    
        ; Create a new window class.
        VarSetCapacity(wc, 40, 0)   ; WNDCLASS wc
        NumPut(wndProc,   wc, 4)   ; lpfnWndProc
        NumPut(hInstance, wc,16)   ; hInstance
        NumPut(&ClassName,wc,36)   ; lpszClassname

        ; Register the class.        
        if !DllCall("RegisterClass","uint",&wc)
        {   ; failed, free the callback.
            DllCall("GlobalFree","uint",wndProc)
            ErrorLevel = RegisterClass
            return false
        }
        
        ;
        ; Create the message window.
        ;
        if A_OSVersion in WIN_XP,WIN_7,WIN_VISTA,WIN_2003
            hwndParent = -3 ; HWND_MESSAGE (message-only window)
        else
            hwndParent = 0  ; un-owned
        
        hwnd := DllCall("CreateWindowEx","uint",0,"str",ClassName,"str",ClassName
                        ,"uint",0,"int",0,"int",0,"int",0,"int",0,"uint",hwndParent
                        ,"uint",0,"uint",hInstance,"uint",0)
        if !hwnd {
            ErrorLevel = CreateWindowEx
            return false
        }
    }

    prev_hwnd := DllCall("GetForegroundWindow")

    ; Required for the menu to initially have focus.
    ;DllCall("SetForegroundWindow","uint",hwnd)
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On
    WinActivate, ahk_id %hwnd%
    DetectHiddenWindows, %dhw%
    
    if (x="" or y="") {
        CoordMode, Mouse, Screen
        MouseGetPos, x, y
    }

    ; returns non-zero on success.
    ret := DllCall("TrackPopupMenu","uint",h_menu,"uint",0,"int",x,"int",y
                    ,"int",0,"uint",hwnd,"uint",0)
    
    if WinExist("ahk_id " prev_hwnd)
        DllCall("SetForegroundWindow","uint",prev_hwnd)
    
    ; Required to let AutoHotkey process WM_COMMAND messages we may have
    ; sent as a result of clicking a menu item. (Without this, the item-click
    ; won't register if there is an 'ExitApp' after ShowOwnerDrawnMenu returns.)
    Sleep, 1
    
    return ret
}
MI_OwnerDrawnMenuItemWndProc(hwnd, Msg, wParam, lParam)
{
    static WM_DRAWITEM = 0x002B, WM_MEASUREITEM = 0x002C, WM_COMMAND = 0x111
    static ScriptHwnd
    Critical 500

    if (Msg = WM_MEASUREITEM && wParam = 0)
    {   ; MSDN: wParam - If the value is zero, the message was sent by a menu.
        h_icon := NumGet(lParam+20)
        if !h_icon
            return false
        
        ; Measure icon and put results into lParam.
        VarSetCapacity(buf,24)
        if DllCall("GetIconInfo","uint",h_icon,"uint",&buf)
        {
            hbmColor := NumGet(buf,16)
            hbmMask  := NumGet(buf,12)
            x := DllCall("GetObject","uint",hbmColor,"int",24,"uint",&buf)
            DllCall("DeleteObject","uint",hbmColor)
            DllCall("DeleteObject","uint",hbmMask)
            if !x
                return false
            NumPut(NumGet(buf,4,"int")+2, lParam+12) ; width
            NumPut(NumGet(buf,8,"int")  , lParam+16) ; height
            return true
        }
        return false
    }
    else if (Msg = WM_DRAWITEM && wParam = 0)
    {
        hdcDest := NumGet(lParam+24)
        x       := NumGet(lParam+28)
        y       := NumGet(lParam+32)
        h_icon  := NumGet(lParam+44)
        if !(h_icon && hdcDest)
            return false

        return DllCall("DrawIconEx","uint",hdcDest,"int",x,"int",y,"uint",h_icon
                        ,"uint",0,"uint",0,"uint",0,"uint",0,"uint",3)
    }
    else if (Msg = WM_COMMAND && !(wParam>>16)) ; (clicked a menu item)
    {
        DetectHiddenWindows, On
        WinGetClass, class, ahk_id %hwnd%
        if (class != "AutoHotkeyGUI" && class != "AutoHotkey") {
            if !ScriptHwnd {
                Process, Exist
                ScriptHwnd := WinExist("ahk_class AutoHotkey ahk_pid " ErrorLevel)
            }
            ; Forward this message to the AutoHotkey main window.
            PostMessage, Msg, wParam, lParam,, ahk_id %ScriptHwnd%
            return ErrorLevel
        }
    }
    if A_EventInfo  ; Let the "super-class" window procedure handle all other messages.
        return DllCall("CallWindowProc","uint",A_EventInfo,"uint",hwnd,"uint",Msg,"uint",wParam,"uint",lParam)
    else            ; Let the default window procedure handle all other messages.
        return DllCall("DefWindowProc","uint",hwnd,"uint",Msg,"uint",wParam,"uint",lParam)
}

;
; Windows Vista Menu Icons
;

; Note: 32-bit alpha-blended menu item bitmaps are supported only on Windows Vista.
; Article on menu icons in Vista:
; http://shellrevealed.com/blogs/shellblog/archive/2007/02/06/Vista-Style-Menus_2C00_-Part-1-_2D00_-Adding-icons-to-standard-menus.aspx
MI_GetBitmapFromIcon32Bit(h_icon, width=0, height=0)
{
    VarSetCapacity(buf,40) ; used as ICONINFO (20), BITMAP (24), BITMAPINFO (40)
    if DllCall("GetIconInfo","uint",h_icon,"uint",&buf) {
        hbmColor := NumGet(buf,16)  ; used to measure the icon
        hbmMask  := NumGet(buf,12)  ; used to generate alpha data (if necessary)
    }

    if !(width && height) {
        if !hbmColor or !DllCall("GetObject","uint",hbmColor,"int",24,"uint",&buf)
            return 0
        width := NumGet(buf,4,"int"),  height := NumGet(buf,8,"int")
    }

    ; Create a device context compatible with the screen.        
    if (hdcDest := DllCall("CreateCompatibleDC","uint",0))
    {
        ; Create a 32-bit bitmap to draw the icon onto.
        VarSetCapacity(buf,40,0), NumPut(40,buf), NumPut(1,buf,12,"ushort")
        NumPut(width,buf,4), NumPut(height,buf,8), NumPut(32,buf,14,"ushort")
        
        if (bm := DllCall("CreateDIBSection","uint",hdcDest,"uint",&buf,"uint",0
                            ,"uint*",pBits,"uint",0,"uint",0))
        {
            ; SelectObject -- use hdcDest to draw onto bm
            if (bmOld := DllCall("SelectObject","uint",hdcDest,"uint",bm))
            {
                ; Draw the icon onto the 32-bit bitmap.
                DllCall("DrawIconEx","uint",hdcDest,"int",0,"int",0,"uint",h_icon
                        ,"uint",width,"uint",height,"uint",0,"uint",0,"uint",3)

                DllCall("SelectObject","uint",hdcDest,"uint",bmOld)
            }
        
            ; Check for alpha data.
            has_alpha_data := false
            Loop, % height*width
                if NumGet(pBits+0,(A_Index-1)*4) & 0xFF000000 {
                    has_alpha_data := true
                    break
                }
            if !has_alpha_data
            {
                ; Ensure the mask is the right size.
                hbmMask := DllCall("CopyImage","uint",hbmMask,"uint",0
                                    ,"int",width,"int",height,"uint",4|8)
                
                VarSetCapacity(mask_bits, width*height*4, 0)
                if DllCall("GetDIBits","uint",hdcDest,"uint",hbmMask,"uint",0
                            ,"uint",height,"uint",&mask_bits,"uint",&buf,"uint",0)
                {   ; Use icon mask to generate alpha data.
                    Loop, % height*width
                        if (NumGet(mask_bits, (A_Index-1)*4))
                            NumPut(0, pBits+(A_Index-1)*4)
                        else
                            NumPut(NumGet(pBits+(A_Index-1)*4) | 0xFF000000, pBits+(A_Index-1)*4)
                } else {   ; Make the bitmap entirely opaque.
                    Loop, % height*width
                        NumPut(NumGet(pBits+(A_Index-1)*4) | 0xFF000000, pBits+(A_Index-1)*4)
                }
            }
        }
    
        ; Done using the device context.
        DllCall("DeleteDC","uint",hdcDest)
    }

    if hbmColor
        DllCall("DeleteObject","uint",hbmColor)
    if hbmMask
        DllCall("DeleteObject","uint",hbmMask)
    return bm
}

;
; Utils
;

MI_DllProcAorW(dll, func) {
    ; In AutoHotkey_L/AutoHotkeyU we can just use "dll\func" and "A" or "W"
    ; will be appended as appropriate if func is not found, but since that
    ; won't work in regular AutoHotkey (for some dlls), resolve it manually:
    return DllCall("GetProcAddress"
                ,"uint", DllCall("GetModuleHandle","str",dll)
                , A_IsUnicode ? "astr":"str"  ; Always an ANSI string.
                , func . (A_IsUnicode ? "W":"A"))
}