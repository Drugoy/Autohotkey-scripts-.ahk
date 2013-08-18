;{ SilentScreenshotter by Drugoy

; This script takes *.png screenshots of the specified area and uploads them to imgur.com and depending on user's setting - it either stores the URL of the uploaded image into the clipboard or opens it instantly. It also supports image files to be drag'n'dropped onto the script to upload them.

; Script author: Drugoy a.k.a. Drugmix
; Contacts: idrugoy@gmail.com, drug0y@ya.ru
; https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/SilentScreenshotter/

; Requirements:
; 1. GDI+ library (put it to your "../Program files/Autohotkey/Lib" folder) http://www.autohotkey.com/board/topic/29449-gdi-standard-library-145-by-tic/
; 2. That requirement is optional: 'Optipng' utility: it is boundled along with this script if the script is compiled, or can be downloaded from here: http://optipng.sourceforge.net/
; 3. Some very basic .ahk knowledge for one-time script configuration.
; How to use:
; 0. Configure the settings.
; 1. Obtain ClientID here https://api.imgur.com/oauth2/addclient
; 2. Run the script.
; 3. a. Set cursor at any corner of the area you'd like to take a screenshot of.
;	 b. Hit PrintScreen.
;	 c. Set cursor to the opposite corner.
;	 d. Hit PrintScreen again to lock the area to be screenshotted.
;	 e. Hit PrintScreen once again to finally take the screenshot.
; Before step "3e" - you may cancel screenshotting process by hitting Escape button.
;}
;{ Initialization before settings
#Include, Gdip.ahk
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, GDI+ failed to start. Please ensure you have GDI+ on your system. Opening http://www.autohotkey.com/board/topic/29449-gdi-standard-library-145-by-tic/, please manually put that library to the "../Program files/Autohotkey/Lib" folder.
	Run, http://www.autohotkey.com/board/topic/29449-gdi-standard-library-145-by-tic/
	ExitApp
}
#SingleInstance, Off
SetWorkingDir, %A_ScriptDir%
FileInstall, optipng.exe, optipng.exe
CoordMode, Mouse, Screen
SetBatchLines, -1
RegRead, Temp, HKCU, Environment, Temp	; Read registry to get the path to the system environment variable "Temp".
If ErrorLevel	; If there is no env.var. "Temp".
	RegRead, Temp, HKCU, Environment, Tmp	; Look for env.var. "tmp" instead.
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
; Specify path to "optipng.exe" if you would like to use it.
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
	optimizePNG := 7	; Use values from 0 to 7 to specify the compression level: 0 = no compression, 7 = max compression. Compression is always lossless, but works only for PNG.
	optipngPath := A_ScriptDir . "\optipng.exe"	; Specify path to "optipng.exe" if you would like to use it.
	clipURL := 1	; 0 = the image's URL will be opened in browser; 1 = copy to clipboard; 2 = do both.
	tempScreenshot := 1	; 0 = the local screenshot won't get deleted after it got uploaded to the server, 1 = it will be removed as soon as the file got uploaded to the server.
	imgurClientID := "a6f3e91e6977dc8"	; Paste here your imgur's client ID that can be obtained for free (registration is required, but you may use fake email) here: https://api.imgur.com/oauth2/addclient
	; ListLines, Off	; Uncomment this if the script is fully working for you and you'd like to save a bit of RAM by sacrificing script's self-debugging ability.
}
;}
Global imgurClientID, clipURL, tempScreenshot
imgPath .= imgName . imgExtension

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
		Gdip_Shutdown(pToken)
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
	pToken := Gdip_Startup()	; Prepare GDI+.
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
				Gdip_Shutdown(pToken)
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
	Gdip_Shutdown(pToken)
	If optimizePNG	; Run png optimizator if user chose to do so.
		RunWait, %optipngPath% -o%optimizePNG% -i0 -nc -nb -q -clobber %imgPath%,, Hide
	upload(imgPath)
	x1 := x2 := x3 := y1 := y2 := y3 := pPen := pToken := pBitmap := obm := hbm := hdc := hwnd1 := G := ""
}
Return

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
	http.Send(data)
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
	If (%0% == 0) && clipURL
		Return imgURL
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