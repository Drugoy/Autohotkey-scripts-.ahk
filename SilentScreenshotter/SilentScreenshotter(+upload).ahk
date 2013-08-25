;{ SilentScreenshotter by Drugoy

; This script takes *.png screenshots of the specified area and uploads them to imgur.com and depending on user's setting - it either stores the URL of the uploaded image into the clipboard or opens it instantly. It also supports image files to be drag'n'dropped onto the script to upload them.

; Script author: Drugoy a.k.a. Drugmix
; Contacts: idrugoy@gmail.com, drug0y@ya.ru
; https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/SilentScreenshotter/

; Requirements:
; 0. Some very basic .ahk knowledge for one-time script configuration.
; 1. That requirement is optional: 'Optipng' utility: it is boundled along with this script If the script is compiled, or can be downloaded from here: http://optipng.sourceforge.net/
; How to use:
; 1. Obtain ClientID here https://api.imgur.com/oauth2/addclient
; 2. Configure the settings.
; 3. Run the script.
; 4. a. Set cursor at any corner of the area you'd like to take a screenshot of.
;	 b. Hit [PrintScreen].
;	 c. Set cursor to the opposite corner.
;	 d. Either hit [PrintScreen] again or [left click] to lock the area to be screenshotted.
;	 e. Hit [PrintScreen] once again to finally take the screenshot.
; Before step "4e" - you may cancel screenshotting process by hitting Escape button.
;}
;{ Initialization before settings
#SingleInstance, Off
SetWorkingDir, %A_ScriptDir%
FileInstall, optipng.exe, optipng.exe
CoordMode, Mouse, Screen
SetBatchLines, -1
If !Temp	; If there is no env.var. "Temp" - use "Tmp" instead.
	Temp := Tmp
;}
;{ Settings
If A_IsCompiled
{
	IfNotExist, settings.ini
	{
		IniWrite,
		(
; UNCOMMENT LINES TO MAKE THEM GET READ
; Paste here your imgur's client ID that can be obtained for free (registration is required, but you may use fake email) here: https://api.imgur.com/oauth2/addclient
imgurClientID=
; Specify path and screenshot's name.
;imgPath=`%Temp`%\
; Specify locally saved image's name.
;imgName=`%A_Now`%
; Specify desired file format (most of common formats are supported).
;imgExtension=.png
; Use values from 0 to 7 to specify the compression level: 0 = no compression, 7 = max compression. Compression is always lossless, but works only for PNG.
;optimizePNG=7
; Specify path to "optipng.exe" If you would like to use it.
;optipngPath=`%A_ScriptDir`%\optipng.exe
; 0 = the image's URL will be opened in browser; 1 = copy to clipboard; 2 = do both.
;clipURL=1
; 0 = the local screenshot won't get deleted after it got uploaded to the server, 1 = it will be removed as soon as the file got uploaded to the server.
;tempScreenshot=1
		), settings.ini, settings
	}
	IniRead, imgPath, settings.ini, settings, imgPath, % Temp . "\"
	IniRead, imgName, settings.ini, settings, imgName, % A_Now
	IniRead, imgExtension, settings.ini, settings, imgExtension, .png
	IniRead, optimizePNG, settings.ini, settings, optimizePNG, 7
	IniRead, optipngPath, settings.ini, settings, optipngPath, % A_ScriptDir . "\optipng.exe"
	IniRead, clipURL, settings.ini, settings, clipURL, 1
	IniRead, tempScreenshot, settings.ini, settings, tempScreenshot, 1
	IniRead, imgurClientID, settings.ini, settings, imgurClientID
}
Else
{
	imgPath := Temp . "\"	; Specify path and screenshot's name.
	imgName := A_Now	; Specify locally saved image's name.
	imgExtension := ".png"	; Specify desired file format (most of common formats are supported).
	optimizePNG := 0	; Use values from 0 to 7 to specify the compression level: 0 = no compression, 7 = max compression. Compression is always lossless, but works only for PNG.
	optipngPath := A_ScriptDir . "\optipng.exe"	; Specify path to "optipng.exe" If you would like to use it.
	clipURL := 1	; 0 = the image's URL will be opened in browser; 1 = copy to clipboard; 2 = do both.
	tempScreenshot := 1	; 0 = the local screenshot won't get deleted after it got uploaded to the server, 1 = it will be removed as soon as the file got uploaded to the server.
	imgurClientID := ""	; Paste here your imgur's client ID that can be obtained for free (registration is required, but you may use fake email) here: https://api.imgur.com/oauth2/addclient
	; ListLines, Off	; Uncomment this If the script is fully working for you and you'd like to save a bit of RAM by sacrificing script's self-debugging ability.
}
;}
If !imgurClientID	; The script can't work without imgurClientID
{
	Msgbox, 'imgurClientID' is empty`, you should obtain it and paste into the script or .ini file.`nOpening https://api.imgur.com/oauth2/addclient so you can register there and obtain imgurClientID.`nHint: you may use fake email at registration.
	Run https://api.imgur.com/oauth2/addclient
	ExitApp
}

Global imgurClientID, imgURL, clipURL, tempScreenshot
imgPath .= imgName . imgExtension
pToken := Gdip_Startup()

If %0% != 0	; Usually %0% contains the number of command line parameters, but when the user drag'n'drops files onto the script - each of the dropped file gets sent to script as a separate command line parameter, so %0% contains the number of dropped files.
{
	Loop, %0%
	{
		GivenPath := %A_Index%
		Loop %GivenPath%, 1
			fileLongPath := A_LoopFileLongPath
		If (A_Index == 1)
			upload(fileLongPath)
		Else
			upload(fileLongPath, 1)
	}
}
multipleInstances := OtherInstance()
If multipleInstances
	ExitApp
Return

$Esc::	; Escape hotkey is used in this script to cancel screenshot area selection.
	If firstHit_EventFired
	{
		Gdip_DisposeImage(pBitmap)
		firstHit_EventFired := ""
		Gui 1: Destroy
	}
	Else
		Send {Esc}
Return

PrintScreen:: ; Since we use the same hotkey trice, we have to distinguish the calls.
KeyWait, PrintScreen
If !firstHit_EventFired	; The user hit PrintScreen - this is a first step.
{
	firstHit_EventFired := 1
	MouseGetPos, x1, y1
	Gui, 1: -Caption +E0x80000 +HWNDhwnd1 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs ; Create a GUI to use it as a canvas for GDI+ drawing.
	Gui, 1: Show, NA
	Loop
	{
		; Draw a rectangular following the cursor.
		MouseGetPos, x2, y2
		If !(x1 == x2 || y1 == y2) ; Draw a rectangular to indicate the area to get screenshoted.
		{
			hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
			hdc := CreateCompatibleDC()
			obm := SelectObject(hdc, hbm)
			G := Gdip_GraphicsFromHDC(hdc)
			Gdip_SetSmoothingMode(G, 4)
			pPen := Gdip_CreatePen(0xffff0000, 1)
			Gdip_DrawLines(G, pPen, x1 "," y1 "|" x2 "," y1 "|" x2 "," y2 "|" x1 "," y2 "|" x1 "," y1)
			Gdip_DeleteBrush(pPen)
			UpdateLayeredWindow(hwnd1, hdc, 0, 0, A_ScreenWidth, A_ScreenHeight)
			SelectObject(hdc, obm)
			DeleteObject(hbm)
			DeleteDC(hdc)
			Gdip_DeleteGraphics(G)
		}
		Sleep 20	; This pause is used to redraw the rectangular less frequently in order to consume less CPU resources. You may adjust the value (it's in miliseconds).
		If GetKeyState("PrintScreen", "P") || GetKeyState("LButton", "P") || (cancel := GetKeyState("Escape", "P"))	; User can hit Esc to cancel the selection at any time. User might want to finish the area selection with Left Mouse Button click or with hitting PrintScreen again. This is a second step: here we finish drawing the rectangular.
		{
			KeyWait, PrintScreen
			If cancel
			{
				Gdip_DisposeImage(pBitmap)
				Gui 1: Destroy
				cancel := firstHit_EventFired := ""
			}
			Break
		}
	}
	Return
}
Else	; User has to hit PrintScreen once again (for the 3rd time) to take a screenshot. I inteionally made not 2, but 3 steps required to take a screenshot: so you can take a screenshot of some event happening, for example, only when you hover something special.
{
	firstHit_EventFired := ""
	Gui 1: Destroy	; Hide the rectangular before screenshotting the area
	Gosub, x1x2y1y2	; Make x1 < x2 and y1 < y2.
	; Save a screenshot to a file.
	pBitmap := Gdip_BitmapFromScreen(x1 "|" y1 "|" x2-x1 "|" y2-y1)
	Gdip_SaveBitmapToFile(pBitmap, imgPath, 100)
	While !FileExist(imgPath)	; Wait until the file gets actually created (otherwise the script will execute the next part too fast).
		Sleep 25
	Gdip_DisposeImage(pBitmap)	; Clean after self.
	If optimizePNG	; Run png optimizator If user chose to do so.
		IfExist, %optipngPath%	; Run it only if it exists.
			RunWait, %optipngPath% -o%optimizePNG% -i0 -nc -nb -q -clobber %imgPath%,, Hide
	upload(imgPath)
	TrayTip, Complete, The image has been successfully uploaded:`n%imgURL%, 1, 1
	x1 := x2 := x3 := y1 := y2 := y3 := pPen := pBitmap := obm := hbm := hdc := hwnd1 := G := ""
}
Return

OnExit, Exit

Exit:
	Gdip_Shutdown(pToken)
ExitApp

x1x2y1y2:
	If (x1 > x2)	; We have to keep x1 < x2 and y1 < y2 or GDI+ function will fail.
		Swap(x1, x2)
	If (y1 > y2)	; We have to keep y1 < y2 and y1 < y2 or GDI+ function will fail.
		Swap(y1, y2)
Return

Swap(ByRef a, ByRef b)	; A function to exchange values of two variables without the need to create 3rd temporary one.
{
	a ^= b
	b ^= a
	a ^= b
}

upload(input, inputtedMultipleFiles = 0)	; Thanks to: maestrith http://www.autohotkey.com/board/user/910-maestrith/
{	; Upload to Imgur using it's API.
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	img := ComObjCreate("WIA.ImageFile")
	img.LoadFile(input)
	ip := ComObjCreate("WIA.ImageProcess")
	data := img.filedata.binarydata
	http.Open("POST", "https://api.imgur.com/3/upload")
	http.SetRequestHeader("Authorization", "Client-ID " imgurClientID)
	Try
		http.Send(data)
	Catch, e
		Msgbox Please, try again, because the script failed to upload your screenshot due to a server-issue:`n%e%
	imgURL := http.ResponseText
	If RegExMatch(imgURL, "i)""link"":""http:\\/\\/(.*?(jpg|jpeg|png|gif|apng|tiff|tif|bmp|pdf|xcf))""}", Match)
    	imgURL := "https://" RegExReplace(Match1, "\\/", "/")
	If clipURL	; If user configured the script to save the image's URL and he screenshotted something (not drag'n'dropped multiple files)
	{
		If !inputtedMultipleFiles	; Only 1 file to be uploaded.
			ClipBoard := imgURL
		Else	; Multiple files got drag'n'dropped, so links should be separated with a space.
			Clipboard .= A_Space . imgURL
	}
	Else	; Otherwise - open it in the browser.
		Run, %imgURL%
	If tempScreenshot && (%0% == 0)	; User specified to delete the local screenshot's file after uploading it.
		FileDelete, %input%
	http := img := ip := data := input := inputtedMultipleFiles := ""
}

OtherInstance()	; Thanks to: GeekDude http://www.autohotkey.com/board/user/10132-geekdude/
{
	DetectHiddenWindows, On
	WinGet, wins, List, ahk_class AutoHotkey
	Loop, %wins%
	{
		WinGetTitle, win, % "ahk_id " wins%A_Index%
		If (RegExReplace(win, "^(.*) - AutoHotkey v[0-9\.]+$", "$1") == A_ScriptFullPath)
		{
			WinGet, wpid, PID, % "ahk_id " wins%A_Index%
			If (wpid != DllCall("GetCurrentProcessId"))
				Return wpid
		}
	}
	DetectHiddenWindows, Off
	Return 0
}

;{ GDI+ functions

Gdip_Startup()
{
	If !DllCall("GetModuleHandle", "str", "gdiplus")
		DllCall("LoadLibrary", "str", "gdiplus")
	VarSetCapacity(si, 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", "uint*", pToken, "uint", &si, "uint", 0)
	Return pToken
}

Gdip_Shutdown(pToken)
{
	DllCall("gdiplus\GdiplusShutdown", "uint", pToken)
	If hModule := DllCall("GetModuleHandle", "str", "gdiplus")
		DllCall("FreeLibrary", "uint", hModule)
	Return 0
}

CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
{
	hdc2 := hdc ? hdc : GetDC()
	VarSetCapacity(bi, 40, 0)
	NumPut(w, bi, 4), NumPut(h, bi, 8), NumPut(40, bi, 0), NumPut(1, bi, 12, "ushort"), NumPut(0, bi, 16), NumPut(bpp, bi, 14, "ushort")
	hbm := DllCall("CreateDIBSection", "uint" , hdc2, "uint" , &bi, "uint" , 0, "uint*", ppvBits, "uint" , 0, "uint" , 0)
	If !hdc
		ReleaseDC(hdc2)
	Return hbm
}

CreateCompatibleDC(hdc=0)
{
   Return DllCall("CreateCompatibleDC", "uint", hdc)
}

SelectObject(hdc, hgdiobj)
{
   Return DllCall("SelectObject", "uint", hdc, "uint", hgdiobj)
}

Gdip_GraphicsFromHDC(hdc)
{
    DllCall("gdiplus\GdipCreateFromHDC", "uint", hdc, "uint*", pGraphics)
    Return pGraphics
}

Gdip_SetSmoothingMode(pGraphics, SmoothingMode)	; Default = 0 HighSpeed = 1 HighQuality = 2 None = 3 AntiAlias = 4
{
   Return DllCall("gdiplus\GdipSetSmoothingMode", "uint", pGraphics, "int", SmoothingMode)
}

Gdip_CreatePen(ARGB, w)
{
   DllCall("gdiplus\GdipCreatePen1", "int", ARGB, "float", w, "int", 2, "uint*", pPen)
   Return pPen
}

Gdip_DrawLines(pGraphics, pPen, Points)
{
   StringSplit, Points, Points, |
   VarSetCapacity(PointF, 8*Points0)   
   Loop, %Points0%
   {
      StringSplit, Coord, Points%A_Index%, `,
      NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
   }
   Return DllCall("gdiplus\GdipDrawLines", "uint", pGraphics, "uint", pPen, "uint", &PointF, "int", Points0)
}

Gdip_DeleteBrush(pBrush)
{
   Return DllCall("gdiplus\GdipDeleteBrush", "uint", pBrush)
}

UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
{
	If ((x != "") && (y != ""))
		VarSetCapacity(pt, 8), NumPut(x, pt, 0), NumPut(y, pt, 4)

	If (w = "") ||(h = "")
		WinGetPos,,, w, h, ahk_id %hwnd%
   
	Return DllCall("UpdateLayeredWindow", "uint", hwnd, "uint", 0, "uint", ((x = "") && (y = "")) ? 0 : &pt
	, "int64*", w|h<<32, "uint", hdc, "int64*", 0, "uint", 0, "uint*", Alpha<<16|1<<24, "uint", 2)
}

DeleteObject(hObject)
{
   Return DllCall("DeleteObject", "uint", hObject)
}

DeleteDC(hdc)
{
   Return DllCall("DeleteDC", "uint", hdc)
}

Gdip_DeleteGraphics(pGraphics)
{
   Return DllCall("gdiplus\GdipDeleteGraphics", "uint", pGraphics)
}

Gdip_DisposeImage(pBitmap)
{
   Return DllCall("gdiplus\GdipDisposeImage", "uint", pBitmap)
}

Gdip_BitmapFromScreen(Screen=0, Raster="")
{
	If (Screen = 0)
	{
		Sysget, x, 76
		Sysget, y, 77	
		Sysget, w, 78
		Sysget, h, 79
	}
	Else If (SubStr(Screen, 1, 5) = "hwnd:")
	{
		Screen := SubStr(Screen, 6)
		If !WinExist( "ahk_id " Screen)
			Return -2
		WinGetPos,,, w, h, ahk_id %Screen%
		x := y := 0
		hhdc := GetDCEx(Screen, 3)
	}
	Else If (Screen&1 != "")
	{
		Sysget, M, Monitor, %Screen%
		x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
	}
	Else
	{
		StringSplit, S, Screen, |
		x := S1, y := S2, w := S3, h := S4
	}

	If (x = "") || (y = "") || (w = "") || (h = "")
		Return -1

	chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
	BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
	ReleaseDC(hhdc)
	
	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
	SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
	Return pBitmap
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75)
{
	SplitPath, sOutput,,, Extension
	If Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
		Return -1
	Extension := "." Extension

	DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
	VarSetCapacity(ci, nSize)
	DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "uint", &ci)
	If !(nCount && nSize)
		Return -2
   
	Loop, %nCount%
	{
		Location := NumGet(ci, 76*(A_Index-1)+44)
		If !A_IsUnicode
		{
			nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
			VarSetCapacity(sString, nSize)
			DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
			If !InStr(sString, "*" Extension)
				continue
		}
		Else
		{
			nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
			sString := ""
			Loop, %nSize%
				sString .= Chr(NumGet(Location+0, 2*(A_Index-1), "char"))
			If !InStr(sString, "*" Extension)
				continue
		}
		pCodec := &ci+76*(A_Index-1)
		break
	}
	If !pCodec
		Return -3

	If (Quality != 75)
	{
		Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
		If Extension in .JPG,.JPEG,.JPE,.JFIF
		{
			DllCall("gdiplus\GdipGetEncoderParameterListSize", "uint", pBitmap, "uint", pCodec, "uint*", nSize)
			VarSetCapacity(EncoderParameters, nSize, 0)
			DllCall("gdiplus\GdipGetEncoderParameterList", "uint", pBitmap, "uint", pCodec, "uint", nSize, "uint", &EncoderParameters)
			Loop, % NumGet(EncoderParameters)      ;%
			{
				If (NumGet(EncoderParameters, (28*(A_Index-1))+20) = 1) && (NumGet(EncoderParameters, (28*(A_Index-1))+24) = 6)
				{
				   p := (28*(A_Index-1))+&EncoderParameters
				   NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20)))
				   break
				}
			}      
	  }
	}
	If !A_IsUnicode
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sOutput, "int", -1, "uint", 0, "int", 0)
		VarSetCapacity(wOutput, nSize*2)
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "uint", &sOutput, "int", -1, "uint", &wOutput, "int", nSize)
		VarSetCapacity(wOutput, -1)
		If !VarSetCapacity(wOutput)
			Return -4
		E := DllCall("gdiplus\GdipSaveImageToFile", "uint", pBitmap, "uint", &wOutput, "uint", pCodec, "uint", p ? p : 0)
	}
	Else
		E := DllCall("gdiplus\GdipSaveImageToFile", "uint", pBitmap, "uint", &sOutput, "uint", pCodec, "uint", p ? p : 0)
	Return E ? -5 : 0
}

GetDC(hwnd=0)
{
	Return DllCall("GetDC", "uint", hwnd)
}

ReleaseDC(hdc, hwnd=0)
{
   Return DllCall("ReleaseDC", "uint", hwnd, "uint", hdc)
}

GetDCEx(hwnd, flags=0, hrgnClip=0)
{
    Return DllCall("GetDCEx", "uint", hwnd, "uint", hrgnClip, "int", flags)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
{
	Return DllCall("gdi32\BitBlt", "uint", dDC, "int", dx, "int", dy, "int", dw, "int", dh
	, "uint", sDC, "int", sx, "int", sy, "uint", Raster ? Raster : 0x00CC0020)
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0)
{
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "uint", hBitmap, "uint", Palette, "uint*", pBitmap)
	Return pBitmap
}
;}