/* SilentScreenshotter v1.5

Last modified: 2014.08.28 23:12

This script takes *.png screenshots of the specified area and uploads them to imgur.com and depending on user's setting - it either stores the URL of the uploaded image into the clipboard or opens it instantly. It also supports image files to be drag'n'dropped onto the script to upload them.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/SilentScreenshotter/
Thanks to: maestrith, GeekDude.

Requirements:
0. Some very basic .ahk knowledge for one-time script configuration.
1. That requirement is optional: 'Optipng' utility: it is boundled along with this script If the script is compiled, or can be downloaded from here: http://optipng.sourceforge.net/
2. AHK_L x32 Unicode. The script may not work with other versions.
How to use:
1. Obtain ClientID here: https://api.imgur.com/oauth2/addclient
2. Configure the settings.
3. Run the script.
4. a. Set cursor at any corner of the area you'd like to take a screenshot of.
	 b. Hit [PrintScreen].
	 c. Set cursor to the opposite corner.
	 d. Either hit [PrintScreen] again or [left click] to lock the area to be screenshotted.
	 e. Hit [PrintScreen] once again to finally take the screenshot.
Before step "4e" - you may cancel screenshotting process by hitting Escape button.
*/
;{ Initialization before settings
#SingleInstance, Off
#NoEnv
SetWorkingDir, %A_ScriptDir%
FileInstall, optipng.exe, optipng.exe
CoordMode, Mouse, Screen
SetBatchLines, -1
OnExit, Exit
;}
;{ Settings
If (A_IsCompiled)
{
	IfNotExist, settings.ini
	{
		IniWrite,
		(
; UNCOMMENT LINES TO MAKE THEM GET READ
; Paste here your imgur's client ID that can be obtained for free (registration is required, but you may use fake email) here: https://api.imgur.com/oauth2/addclient
imgurClientID=
; Specify path and screenshot's name.
;imgPath=`%A_Temp`%\
; Specify locally saved image's name. Default name is the date stamp (with time).
;imgName=`%A_Now`%
; Specify desired file format (most of common formats are supported).
;imgExtension=png
; Use values from 0 to 7 to specify the compression level: 0 = no compression, 7 = max compression. Compression is always lossless, but works only for PNG.
;optimizePNG=7
; Specify path to "optipng.exe" If you would like to use it.
;optipngPath=`%A_ScriptDir`%\optipng.exe
; 0 = the image's URL will be opened in browser; 1 = copy to clipboard; 2 = do both.
;clipURL=1
; 0 = the local screenshot won't get deleted after it got uploaded to the server, 1 = it will be removed as soon as the file got uploaded to the server.
;tempScreenshot=1
; Use values from 0 to 100 to specify quality for screenshots in JPEG (by default PNG is used).
;jpgQuality=100
		), settings.ini, settings
	}
	IniRead, imgurClientID, settings.ini, settings, imgurClientID
	IniRead, imgPath, settings.ini, settings, imgPath, % A_Temp "\"
	IniRead, imgName, settings.ini, settings, imgName, % A_Now
	IniRead, imgExtension, settings.ini, settings, imgExtension, png
	IniRead, optimizePNG, settings.ini, settings, optimizePNG, 7
	IniRead, optipngPath, settings.ini, settings, optipngPath, % A_ScriptDir "\optipng.exe"
	IniRead, clipURL, settings.ini, settings, clipURL, 1
	IniRead, tempScreenshot, settings.ini, settings, tempScreenshot, 1
	IniRead, jpgQuality, settings.ini, settings, jpgQuality, 100
}
Else
{
	imgPath := A_Temp "\"	; Specify path and screenshot's name.
	imgName := A_Now	; Specify locally saved image's name. Default name is the date stamp (with time).
	imgExtension := "png"	; Specify desired file format (most of common formats are supported).
	optimizePNG := 0	; Use values from 0 to 7 to specify the compression level: 0 = no compression, 7 = max compression. Compression is always lossless, but works only for PNG.
	optipngPath := A_ScriptDir "\optipng.exe"	; Specify path to "optipng.exe" If you would like to use it.
	clipURL := 2	; 0 = the image's URL will be opened in browser; 1 = copy to clipboard; 2 = do both.
	tempScreenshot := 0	; 0 = the local screenshot won't get deleted after it got uploaded to the server, 1 = it will be removed as soon as the file got uploaded to the server.
	imgurClientID := ""	; Paste here your imgur's client ID that can be obtained for free (registration is required, but you may use fake email) here: https://api.imgur.com/oauth2/addclient
	jpgQuality := 100	; Use values from 0 to 100 to specify quality for screenshots in JPEG (by default PNG is used).
	; ListLines, Off	; Uncomment this if the script is fully working for you and you'd like to save a bit of RAM by sacrificing script's self-debugging ability.
}
;}
If !(imgurClientID)	; The script can't work without imgurClientID.
{
	Msgbox, 'imgurClientID' is empty`, you should obtain it and paste into the script or .ini file.`nOpening https://api.imgur.com/oauth2/addclient so you can register there and obtain imgurClientID.`nHint: you may use fake email at registration.
	Run, https://api.imgur.com/oauth2/addclient
	ExitApp
}

Global imgurClientID, Global proxyEnable, Global proxyServer, Global imgExtension, imgURL, clipURL, tempScreenshot
Global ptr := A_PtrSize ? "uPtr" : "uInt"
RegRead, proxyEnable, HKCU, Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxyEnable	; Detect wheter proxy is used or not.
If (proxyEnable)
	RegRead, proxyServer, HKCU, Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxyServer	; Detect address of proxy.
imgPath .= imgName "." imgExtension
pToken := Gdip_Startup()

If (%0% != 0)	; Usually %0% contains the number of command line parameters, but when the user drag'n'drops files onto the script - each of the dropped file gets sent to script as a separate command line parameter, so %0% contains the number of dropped files.
{
	Loop, %0%
	{
		GivenPath := A_Index
		Loop, %GivenPath%, 1
			fileLongPath := A_LoopFileLongPath
		If (A_Index == 1)
			upload(fileLongPath)
		Else
			upload(fileLongPath, 1)
	}
}
multipleInstances := OtherInstance()
If (multipleInstances)
	ExitApp
Return

$Esc::	; Escape hotkey is used in this script to cancel screenshot area selection.
	If (firstHit_EventFired)
	{
		DllCall("gdiplus\GdipDisposeImage", ptr, pBitmap)
		firstHit_EventFired := ""
		Gui, 1: Destroy
	}
	Else
		Send, {Esc}
Return

PrintScreen:: ; Since we use the same hotkey trice, we have to distinguish the calls.
KeyWait, PrintScreen
If !(firstHit_EventFired)	; The user hit PrintScreen - this is a first step.
{
	SysGet, x0, 76
	SysGet, y0, 77
	SysGet, w0, 78
	SysGet, h0, 79
	firstHit_EventFired := 1
	MouseGetPos, x1, y1
	Gui, 1: -Caption +E0x80000 +HWNDhwnd1 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs ; Create a GUI to use it as a canvas for GDI+ drawing.
	Gui, 1: Show, NA
	Loop
	{
		; Draw a rectangular following the cursor.
		MouseGetPos, x2, y2
		hbm := CreateDIBSection(w0, h0)
		hdc := DllCall("CreateCompatibleDC", ptr, 0)
		obm := DllCall("SelectObject", Ptr, hdc, Ptr, hbm)
		DllCall("gdiplus\GdipCreateFromHDC", ptr, hdc, ptr "*", G)
		DllCall("gdiplus\GdipSetSmoothingMode", ptr, G, "Int", 4)
		DllCall("gdiplus\GdipCreatePen1", "uInt", 0xffff0000, "float", 1, "Int", 2, ptr "*", pPen)
		Gdip_DrawLines(G, pPen, x1-x0 "," y1-y0 "|" x2-x0 "," y1-y0 "|" x2-x0 "," y2-y0 "|" x1-x0 "," y2-y0 "|" x1-x0 "," y1-y0)
		DllCall("gdiplus\GdipDeleteBrush", ptr, pPen)
		UpdateLayeredWindow(hwnd1, hdc, x0, y0, w0, h0)
		DllCall("SelectObject", Ptr, hdc, Ptr, obm)
		DllCall("DeleteObject", ptr, hbm)
		DllCall("DeleteDC", ptr, hdc)
		DllCall("gdiplus\GdipDeleteGraphics", ptr, G)
		Sleep, 20	; This pause is used to redraw the rectangular less frequently in order to consume less CPU resources. You may adjust the value (it's in miliseconds).
		If (GetKeyState("PrintScreen", "P") || GetKeyState("LButton", "P") || (cancel := GetKeyState("Escape", "P")))	; User can hit Esc to cancel the selection at any time. User might want to finish the area selection with Left Mouse Button click or with hitting PrintScreen again. This is a second step: here we finish drawing the rectangular.
		{
			KeyWait, PrintScreen
			If (cancel)
			{
				DllCall("gdiplus\GdipDisposeImage", ptr, pBitmap)
				Gui, 1: Destroy
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
	Gui, 1: Destroy	; Hide the rectangular before screenshotting the area
	; Save a screenshot to a file.
	pBitmap := Gdip_BitmapFromScreen((x1 < x2 ? x1 : x2) "|" (y1 < y2 ? y1 : y2) "|" (x1 < x2 ? x2-x1 : x1-x2) "|" (y1 < y2 ? y2-y1 : y1-y2))
	Gdip_SaveBitmapToFile(pBitmap, imgPath, jpgQuality)
	While !(FileExist(imgPath))	; Wait until the file gets actually created (otherwise the script will execute the next part too fast).
		Sleep, 25
	DllCall("gdiplus\GdipDisposeImage", ptr, pBitmap)	; Clean after self.
	If (optimizePNG)	; Run png optimizator If user chose to do so.
		IfExist, %optipngPath%	; Run it only if it exists.
			RunWait, %optipngPath% -o%optimizePNG% -i0 -nc -nb -q -clobber %imgPath%,, Hide
		Else
			TrayTip, Error, Optipng not found`, thus can't optimize the image.
	upload(imgPath)
	TrayTip, Complete, The image has been successfully uploaded:`n%imgURL%, 1, 1
}
Return

Exit:
	DllCall("gdiplus\GdiplusShutdown", Ptr, pToken)
	If (hModule := DllCall("GetModuleHandle", "Str", "gdiplus", Ptr))
		DllCall("FreeLibrary", Ptr, hModule)
ExitApp

upload(input, inputtedMultipleFiles = 0)	; Thanks to: maestrith http://www.autohotkey.com/board/user/910-maestrith/ and GeekDude https://github.com/G33kDude
{	; Upload to Imgur using it's API.
	http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	img := ComObjCreate("WIA.ImageFile")
	img.LoadFile(input)
	; ip := ComObjCreate("WIA.ImageProcess")
	; ip.filters.add(IP.FilterInfos("Convert").FilterID)
	; ip.filters(1).properties("FormatID").value := "{B96B3CAF-0728-11D3-9D7B-0000F81EF32E}"	; = png, {B96B3CAE-0728-11D3-9D7B-0000F81EF32E} = jpg
	; ip.filters(1).properties("Quality").value := 100
	; img := ip.apply(img)
	data := img.filedata.binarydata
	http.Open("POST", "https://api.imgur.com/3/upload")
	If (proxyEnable)
	; {
		http.SetProxy(2, proxyServer)
	; 	http.SetCredentials(proxyUser, proxyPass, 1) ; HTTPREQUEST_SETCREDENTIALS_FOR_PROXY = 1
	; }
	http.SetRequestHeader("Authorization", "Client-ID " imgurClientID)
	http.SetRequestHeader("Content-Length", size)
	Try
		http.Send(data)
	Catch, e
		Msgbox, Please, try again, because the script failed to upload your screenshot due to a server-issue:`n%e%
	imgURL := http.ResponseText
	If (RegExMatch(imgURL, "i)""link"":""http:\\/\\/(.*?(jpg|jpeg|png|gif|apng|tiff|tif|bmp|pdf|xcf))""}", Match))
    	imgURL := "https://" RegExReplace(Match1, "\\/", "/")
	If (clipURL)	; If user configured the script to save the image's URL and he screenshotted something (not drag'n'dropped multiple files)
	{
		If !(inputtedMultipleFiles)	; Only 1 file to be uploaded.
			Clipboard := imgURL
		Else	; Multiple files got drag'n'dropped, so links should be separated with a space.
			Clipboard .= A_Space imgURL
	}
	If (clipURL != 1)	; Otherwise - open it in the browser.
		Run, % imgURL
	If tempScreenshot && (%0% == 0)	; User specified to delete the local screenshot's file after uploading it.
		FileDelete, % input
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
	If !(DllCall("GetModuleHandle", "Str", "gdiplus", Ptr))
		DllCall("LoadLibrary", "Str", "gdiplus")
	VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", ptr "*", pToken, Ptr, &si, Ptr, 0)
	Return pToken
}

CreateDIBSection(w, h, hdc="")
{
	hdc2 := hdc ? hdc : DllCall("GetDC", ptr, 0)
	VarSetCapacity(bi, 40, 0)
	NumPut(w, bi, 4, "uInt"), NumPut(h, bi, 8, "uInt"), NumPut(40, bi, 0, "uInt"), NumPut(1, bi, 12, "ushort"), NumPut(0, bi, 16, "uInt"), NumPut(32, bi, 14, "ushort")
	hbm := DllCall("CreateDIBSection", Ptr, hdc2, Ptr, &bi, "uInt", 0, ptr "*", 0, Ptr, 0, "uInt", 0, Ptr)
	If !(hdc)
		DllCall("ReleaseDC", Ptr, 0, Ptr, hdc2)
	Return hbm
}

Gdip_DrawLines(pGraphics, pPen, Points)
{
	StringSplit, Points, Points, |
	VarSetCapacity(PointF, 8*Points0)   
	Loop, % Points0
	{
		StringSplit, Coord, Points%A_Index%, `,
		NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
	}
	Return DllCall("gdiplus\GdipDrawLines", Ptr, pGraphics, Ptr, pPen, Ptr, &PointF, "Int", Points0)
}

UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
{
	If ((x != "") && (y != ""))
		VarSetCapacity(pt, 8), NumPut(x, pt, 0, "uInt"), NumPut(y, pt, 4, "uInt")
	If ((w = "") || (h = ""))
		WinGetPos,,, w, h, ahk_id %hwnd%
	Return DllCall("UpdateLayeredWindow", Ptr, hwnd, Ptr, 0, Ptr, ((x = "") && (y = "")) ? 0 : &pt, "int64*", w|h<<32, Ptr, hdc, "int64*", 0, "uInt", 0, "uInt*", Alpha<<16|1<<24, "uInt", 2)
}

Gdip_BitmapFromScreen(Screen)
{
	If (SubStr(Screen, 1, 5) = "hwnd:")
	{
		Screen := SubStr(Screen, 6)
		If !WinExist( "ahk_id " Screen)
			Return -2
		WinGetPos,,, w, h, ahk_id %Screen%
		x := y := 0
		hhdc := DllCall("GetDCEx", Ptr, Screen, Ptr, 0, "Int", 3)
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
	If ((x = "") || (y = "") || (w = "") || (h = ""))
		Return -1
	chdc := DllCall("CreateCompatibleDC", ptr, 0), hbm := CreateDIBSection(w, h, chdc), obm := DllCall("SelectObject", Ptr, chdc, Ptr, hbm), hhdc := hhdc ? hhdc : DllCall("GetDC", ptr, 0)
	DllCall("gdi32\BitBlt", Ptr, chdc, "Int", 0, "Int", 0, "Int", w, "Int", h, Ptr, hhdc, "Int", x, "Int", y, "uInt", 0x00CC0020)
	DllCall("ReleaseDC", Ptr, 0, Ptr, hhdc)
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hbm, Ptr, 0, ptr "*", pBitmap)
	DllCall("SelectObject", Ptr, chdc, Ptr, obm), DllCall("DeleteObject", ptr, hbm), DllCall("DeleteDC", ptr, hhdc), DllCall("DeleteDC", ptr, chdc)
	Return pBitmap
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=100)
{
	SplitPath, sOutput,,, Extension
	If Extension Not In BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
		Return -1
	DllCall("gdiplus\GdipGetImageEncodersSize", "uInt*", nCount, "uInt*", nSize)
	VarSetCapacity(ci, nSize)
	DllCall("gdiplus\GdipGetImageEncoders", "uInt", nCount, "uInt", nSize, Ptr, &ci)
	If !(nCount && nSize)
		Return -2
	If (A_IsUnicode)
	{
		StrGet_Name := "StrGet"
		Loop, % nCount
		{
			sString := %StrGet_Name%(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
			If !(InStr(sString, "*." Extension))
				Continue
			pCodec := &ci+idx
			Break
		}
	}
	Else
	{
		Loop, % nCount
		{
			Location := NumGet(ci, 76*(A_Index-1)+44)
			nSize := DllCall("WideCharToMultiByte", "uInt", 0, "uInt", 0, "uInt", Location, "Int", -1, "uInt", 0, "Int",  0, "uInt", 0, "uInt", 0)
			VarSetCapacity(sString, nSize)
			DllCall("WideCharToMultiByte", "uInt", 0, "uInt", 0, "uInt", Location, "Int", -1, "Str", sString, "Int", nSize, "uInt", 0, "uInt", 0)
			If !(InStr(sString, "*." Extension))
				Continue
			pCodec := &ci+76*(A_Index-1)
			Break
		}
	}
	If !(pCodec)
		Return -3
	If Extension in JPG,JPEG,JPE,JFIF
	{
		If (Quality != 75)
			Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
		DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uInt*", nSize)
		VarSetCapacity(EncoderParameters, nSize, 0)
		DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uInt", nSize, Ptr, &EncoderParameters)
		Loop, % NumGet(EncoderParameters, "uInt")      ;%
		{
			elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
			If ((NumGet(EncoderParameters, elem+16, "uInt") = 1) && (NumGet(EncoderParameters, elem+20, "uInt") = 6))
			{
				p := elem+&EncoderParameters-pad-4
				NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "uInt")), "uInt")
				Break
			}
		}
	}
	If !(A_IsUnicode)
	{
		nSize := DllCall("MultiByteToWideChar", "uInt", 0, "uInt", 0, Ptr, &sOutput, "Int", -1, Ptr, 0, "Int", 0)
		VarSetCapacity(wOutput, nSize*2)
		DllCall("MultiByteToWideChar", "uInt", 0, "uInt", 0, Ptr, &sOutput, "Int", -1, Ptr, &wOutput, "Int", nSize)
		VarSetCapacity(wOutput, -1)
		If !(VarSetCapacity(wOutput))
			Return -4
		E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &wOutput, Ptr, pCodec, "uInt", p ? p : 0)
	}
	Else
		E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &sOutput, Ptr, pCodec, "uInt", p ? p : 0)
	Return E ? -5 : 0
}
;}