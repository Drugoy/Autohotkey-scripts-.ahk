;{ SilentScreenshotter by Drugoy
; This script makes *.png screenshots of the specified area and uploads it to itmages.ru and stores the URL to the uploaded image into the clipboard.
; Requirements:
; 1. Download and install ITmages util for Windows from https://itmages.ru/info/tools
; 2. Download optipng.exe from http://optipng.sourceforge.net/
; How to use:
; 0. Edit the paths used by the script (at the top of the code), 'original.itmages.exe' should point at 'itmage.exe' not 'original.itmages.exe'.
; 1. Run the script.
; 2. Set cursor at any corner of the area you'd like to take a screenshot of, hit PrintScreen, set cursor to the opposite corner and hit PrintScreen again
; The area between those two points will get into a screenshot, then saved to a temporary file as a *.png image, then it will get optimized (lossless reduction of file's size), then will get uploaded to itmages.ru, then the direct URL to the image will get stored into your clipboard and then the file will get deleted from your disk.
;}
;{ Settings
RegRead, Temp, HKCU,  Environment, Temp	; Read registry to get the path to the system environment variable "Temp".
If ErrorLevel	; If there is no env.var. "Temp".
	RegRead, Temp, HKCU,  Environment, Tmp	; Look for env.var. "tmp" instead.
imgTempPath := Temp "\quickScreenshot.png"	; Path to temporary save screenshot to.
ITmagesUtilPath := "C:\Program Files (x86)\ITmages\original.itmages.exe"	; Path to ITmages.exe.
optipngPath := A_ScriptDir . "\optipng.exe"	; Path to optipng.exe.
outputAs := 1	; 1 = copy to clipboard, 2 = open in browser.
#SingleInstance force
CoordMode, Mouse, Screen
SetBatchLines, -1
; ListLines, Off
;}

$Esc::	; Escape hotkey is used in this script to cancel screenshot area selection.
	If firstHit_EventFired
	{
		Gdip_DisposeImage(pBitmap)
		Gdip_Shutdown(pToken)
		firstHit_EventFired :=
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
		If GetKeyState("PrintScreen","P") || GetKeyState("LButton", "P") || (cancel := GetKeyState("Escape", "P"))	; User can hit Esc to cancel the selection at any time. User might want to finish the area selection with Left Mouse Button click or with hitting PrintScreen again. This is a second step: here we finish drawing the rectangular.
		{
			KeyWait, PrintScreen
			If cancel
			{
				Gdip_DisposeImage(pBitmap)
				Gdip_Shutdown(pToken)
				Gui 1: Destroy
				cancel := firstHit_EventFired :=
			}
			Break
		}
	}
	Return
}
Else	; User has to hit PrintScreen once again (for the 3rd time) to take a screenshot. I inteionally made not 2, but 3 steps required to take a screenshot: so you can take a screenshot of some event happening, for example, only when you hover something special.
{
	Gui 1: Destroy	; Hide the rectangular before screenshotting the area
	Gosub, x1x2y1y2	; Make x1 < x2 and y1 < y2.
	; Save a screenshot to a file.
	pBitmap := Gdip_BitmapFromScreen(x1 "|" y1 "|" x2-x1 "|" y2-y1)
	Gdip_SaveBitmapToFile(pBitmap, imgTempPath, 100)
	While !FileExist(imgTempPath)	; Wait until the file gets actually created (otherwise the script will execute the next part too fast).
		Sleep 25
	Gdip_DisposeImage(pBitmap)	; Clean after self.
	Gdip_Shutdown(pToken)
	RunWait, % optipngPath " -o7 -i0 -nc -nb -q -clobber " imgTempPath,, Hide	; Run png optimizator.
	Run, %ITmagesUtilPath% %imgTempPath%,, Min	; Run ITMages util to upload the screenshot
	WinWait, ahk_class ITmagesLogin,, 3
	If ErrorLevel
	{
		Msgbox failed to run the %ITmagesUtilPath%. Firewall? Antivirus? Not enough rights?
		Process, close, original.itmages.exe
	}
	ControlClick, Button7, ahk_class ITmagesLogin
	WinWait, ahk_class ITmagesReady,, 3
	If ErrorLevel
	{
		Msgbox failed to upload the screenshot. Check your internet connection and firewall.
		Process, close, original.itmages.exe
	}
	ControlClick, % "Button" outputAs, ahk_class ITmagesReady
	WinClose, ahk_class ITmagesReady
	WinWaitClose, ahk_class ITmagesReady,, 3
	FileDelete, %imgTempPath%	; Delete the file. Remove that line if you'd like to keep the screenshot (but be aware, that it will get overwritten if you'll screenshot another area.
	x1 := x2 := x3 := y1 := y2 := y3 := firstHit_EventFired :=
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