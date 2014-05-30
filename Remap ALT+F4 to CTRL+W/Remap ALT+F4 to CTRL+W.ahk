/* Remap ALT+F4 to CTRL+W
Version: 1.3
Last time modified: 2013.05.30 15:20

Makes "Ctrl+W" hotkey work as "Alt+F4" for lots of different programs and system windows. I like Ctrl+W more than Alt+F4, as it's keys are closer to each other.

Warning: console-related hotkeys require this to work:
REG.EXE add HKCU\Console /v QuickEdit /t REG_DWORD /d 1 /f

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/Remap%20ALT+F4%20to%20CTRL+W/Remap%20ALT+F4%20to%20CTRL+W.ahk
*/

#SingleInstance, Force
SetTitleMatchMode, 2	; Testing this. Needed to differentiate Outlook's main window from single email viewers.

;{ [ahk_group altF4] remap "Ctrl + W" to "Alt + F4".
GroupAdd, altF4, ahk_class Miranda ahk_exe Miranda64.exe	; Miranda's contact list window.
GroupAdd, altF4, Upcoming birthdays ahk_class #32770 ahk_exe Miranda64.exe	; Miranda's "Upcoming birthdays" window.
GroupAdd, altF4, Miranda NG Options ahk_class #32770 ahk_exe Miranda64.exe	; Miranda's "Options" window.
GroupAdd, altF4, ahk_exe autoHotkey.exe	; AHK scripts' windows.
GroupAdd, altF4, ahk_exe Skype.exe	; Skype.
;}
;{ [ahk_group closeWin] WinClose by "Ctrl + W".
GroupAdd, closeWin, Find ahk_exe akelpad.exe	; AkelPad's find window.
GroupAdd, closeWin, AkelUpdater ahk_exe AkelUpdater.exe	; AkelPad Updater's window.
GroupAdd, closeWin, ahk_exe HelpPane.exe	; Windows' built-in help tool that gets triggered by F1.
GroupAdd, closeWin, ahk_exe hh.exe	; Windows' built-in .chm files reader.
GroupAdd, closeWin, ahk_class AU3Reveal	; AHK windows' info gatherer.
GroupAdd, closeWin, AutoHotkey Toolkit [W] ahk_class AutoHotkeyGUI	; AutoHotkey Toolkit.
GroupAdd, closeWin, GitHub ahk_exe GitHub.exe	; GitHub.
GroupAdd, closeWin, ahk_exe calc.exe	; Calc.
GroupAdd, closeWin, ahk_exe explorer.exe	; Generally that's not needed for the whole explorer, but some dialogs like "Run" need this.
GroupAdd, closeWin, ahk_exe charmap.exe	; Charmap.
; GroupAdd, closeWin, ahk_class MediaPlayerClassicW	; Media Player Classic - Home Cinema.
GroupAdd, closeWin, ahk_exe mpc-hc.exe	; Media Player Classic - Home Cinema (32-bit process only).
GroupAdd, closeWin, ahk_exe mpc-hc64.exe	; Media Player Classic - Home Cinema (64-bit process only).
GroupAdd, closeWin, ahk_exe uTorrent.exe	; µTorrent.
GroupAdd, closeWin, ahk_exe clipdiary-portable.exe	; Clipdiary.
GroupAdd, closeWin, ahk_exe AnVir.exe	; AnVir TaskManager.
GroupAdd, closeWin, ahk_exe RAVCpl64.exe	; Диспетчер Realtek HD.
GroupAdd, closeWin, ahk_class MozillaDialogClass ahk_exe firefox.exe	; Firefox'es master password prompt and other dialogs.
GroupAdd, closeWin, Edit button: ahk_exe firefox.exe	; Custom Buttons' windows in Firefox.
GroupAdd, closeWin, Textarea Cache Window ahk_exe firefox.exe	; Textarea Cache's windows in Firefox.
GroupAdd, closeWin, Launch Application ahk_exe firefox.exe	; Launch application (protocol handlers) windows in Firefox.
GroupAdd, closeWin, ahk_exe smartgithg.exe	; SmartGit/Hg.
GroupAdd, closeWin, ahk_exe 7zFM.exe	; 7-Zip GUI file manager.
GroupAdd, closeWin, ahk_class Photo_Lightweight_Viewer ahk_exe dllhost.exe	; Windows Photo Viewer.
; GroupAdd, closeWin, ahk_class ConsoleWindowClass	; Windows console (cmd.exe, powershell.exe).
GroupAdd, closeWin, ahk_exe cmd.exe	; Windows console.
GroupAdd, closeWin, ahk_exe powershell.exe	; Powershell.
GroupAdd, closeWin, File Upload ahk_class #32770	; File Upload mini-explorer windows, usually called by browsers prompting to select a file to upload.
GroupAdd, closeWin, ahk_exe taskmgr.exe	; Windows Task Manager.
GroupAdd, closeWin, ahk_exe regedit.exe	; Windows Registry Editor.
GroupAdd, closeWin, ahk_exe notepad.exe	; Windows built-in Notepad.
GroupAdd, closeWin, ahk_class TLister ahk_exe totalcmd.exe	; Total Commander's Lister windows.
GroupAdd, closeWin, ahk_class TLister ahk_exe totalcmd64.exe	; Total Commander's (x64) Lister windows.
GroupAdd, closeWin, Lister ahk_class TSEARCHTEXT ahk_exe totalcmd.exe	; Total Commander's Lister's Search windows.
GroupAdd, closeWin, Lister ahk_class TSEARCHTEXT ahk_exe totalcmd64.exe	; Total Commander's (x64) Lister's Search windows.
GroupAdd, closeWin, ahk_class THistoryFrm ahk_exe miranda64.exe	; History++ windows from Miranda (x64).
GroupAdd, closeWin, Сообщение (HTML) ahk_class rctrl_renwnd32 ahk_exe outlook.exe	; Outlook.	; Outlook's detached window with some particular message.
;}
;{ [ahk_group pasteCMD] console remaps (copy, paste, undo > clear input).
GroupAdd, pasteCMD, ahk_exe cmd.exe	; Windows console.
GroupAdd, pasteCMD, ahk_exe powershell.exe	; Powershell.
;}
;{ [ahk_group minWin] Minimize by "Ctrl + W".
GroupAdd, minWin, Microsoft Outlook ahk_class rctrl_renwnd32 ahk_exe outlook.exe	; Outlook.
;}

;{ Commands
	;{ [ahk_group altF4]: "Ctrl + W" -> "Alt + F4".
#IfWinActive, ahk_group altF4
	^vk57::	; "Ctrl + W"
		Send !{F4}
	Return
	;}
	;{ [ahk_group closeWin]: "Ctrl + W" -> WinClose.
#IfWinActive, ahk_group closeWin
	^vk57::	; "Ctrl + W"
		WinClose
	Return
	;}
	;{ [ahk_group pasteCMD]: normal copy and paste; "Ctrl + A" and "Ctrl+ Z" clean input.
#IfWinActive, ahk_group pasteCMD
	^vk43::	; "Ctrl + C"
	^vk56::	; "Ctrl + V"
		WinGetTitle, title
		If (title ~= "(Выбрать|Select) .*:.*")	; "Selection mode" can be detected by the window's title, which we will check for in order to differentiate two states.
		{
			If (A_ThisHotkey == "^vk56")	; "Ctrl + V"
				Send {Esc}
		}
		Else
		{
			If (A_ThisHotkey == "^vk43")    ; "CTRL + C"
			{
				Hotkey, IfWinActive, ahk_group pasteCMD
				{
					Hotkey, %A_ThisHotkey%, Off
					Send ^c ; Stop execution.
					Hotkey, %A_ThisHotkey%, On
				}
				Hotkey, IfWinActive
					Return
			}
		}
		ControlClick,,,, Right	; Send "Right Click" to paste.
	Return
	
	^vk41::	; "Ctrl + A"
	^vk5a::	; "Ctrl + Z"
		Send {Esc}	; Send "Esc" to clear input.
	Return
	;}
	;{ [ahk_group minWin]: "Ctrl + W" -> WinMinimize.
#IfWinActive, ahk_group minWin
	^vk57::	; "Ctrl + W"
		WinMinimize
	Return
	;}
	;{ Add "Alt + D" and "Ctrl + L" hotkeys to Windows Explorer that will focus the address bar and select the current address.
#IfWinActive, ahk_class CabinetWClass ahk_exe explorer.exe
	!vk44::	; "Alt + D"
	^vk4C::	; "Ctrl + L"
		Send {F4}^a	; F4 is default Windows Explorer hotkey to set focus to address bar and open a drop-down list. Then send "Ctrl + A" to select the address.
	Return
	;}
#IfWinActive
;}