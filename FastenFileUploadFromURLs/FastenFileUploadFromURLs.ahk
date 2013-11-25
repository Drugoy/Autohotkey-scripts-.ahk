/* FasternFileUploadFromURLs
Version: 0.5
Last time modified: 18:25 25.11.2013

Description: Not many people know that when uploading a file (say, setting an avatar to your profile on a forum), it is allowed to use URLs pointing to some files that you don't have locally saved. All you need is to paste the URL into the "file name" input field - in that case, the file will be downloaded to a %temp% folder on your computer and the local path to that file will get used.
However, Windows OSes are quite buggy and sometimes the downloading of a sinngle tiny image may take up to 1 minute, which is too long.
This script just fastens this process to the minimum time required to download the file. All you need is to have this script running, whenever you paste an URL into the "File Upload" window.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/FastenFileUploadFromURLs/FastenFileUploadFromURLs.ahk
*/

#SingleInstance, Force
SetWorkingDir, %temp%

z1 =
(
DUIViewWndClassName
DirectUIHWND
CtrlNotifySink
NamespaceTreeControl
Static
SysTreeView32
CtrlNotifySink
Shell Preview Extension Host
CtrlNotifySink
SHELLDLL_DefView
DirectUIHWND
CtrlNotifySink
ScrollBar
CtrlNotifySink
ScrollBar
Static
ComboBoxEx32
ComboBox
Edit
Static
ComboBox
Button
Button
ScrollBar
Static
Static
Static
ListBox
Static
Button
WorkerW
ReBarWindow32
TravelBand
ToolbarWindow32
Address Band Root
msctls_progress32
Breadcrumb Parent
ToolbarWindow32
ToolbarWindow32
)

z2 =
(
ComboBoxEx32
ComboBox
Edit
)

z3 =
(
UniversalSearchBand
Search Box
SearchEditBoxWrapperClass
DirectUIHWND
)

#IfWinActive, File Upload ahk_class #32770
$^vk0x56::	; Ctrl + V.
	x := y := thisLine := localFileName := ""
	Winget, ctrlList, ControlList
	Loop, Parse, ctrlList, `n
	{
		StringTrimRight, thisLine, A_LoopField, 1
		y .= "`n" thisLine
	}
	StringTrimLeft, y, y, 1
	If (y ~= "m)^(Button\n)*" z1 "(`n" z2 ")?`n" z3 "$")
	{
		SplitPath, Clipboard, localFileName
		UrlDownloadToFile, %Clipboard%, %localFileName%
		If !ErrorLevel
			SendInput, %temp%\%localFileName%
		Else
			SendInput, ^v
	}
Return