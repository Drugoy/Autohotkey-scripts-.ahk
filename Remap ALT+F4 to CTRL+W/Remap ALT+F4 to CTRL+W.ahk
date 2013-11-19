#SingleInstance, Force
CoordMode, Mouse, Window
SetMouseDelay, 0
SetDefaultMouseSpeed, 0

; Group for remapping "Ctrl + W" to "Alt + F4".
GroupAdd, altF4, ahk_class Miranda ahk_exe Miranda64.exe	; Miranda.
GroupAdd, altF4, Miranda NG Options ahk_exe Miranda64.exe	; Miranda NG's options.
GroupAdd, altF4, File Transfers ahk_exe Miranda64.exe	; Miranda NG's file transfers.
GroupAdd, altF4, Upcoming birthdays ahk_exe Miranda64.exe	; Miranda NG's birthday reminder.
GroupAdd, altF4, ahk_class THistoryFrm ahk_exe Miranda64.exe	; History++ window in Miranda.
GroupAdd, altF4, ahk_exe autoHotkey.exe	; AHK scripts' windows.
GroupAdd, altF4, ahk_class Ghost ahk_exe autoHotkey.exe	; AHK's WindowSpy windows.

; Group for WinClose by "Ctrl + W".
GroupAdd, closeWin, Find ahk_exe akelpad.exe	; AkelPad's find window.
GroupAdd, closeWin, AkelUpdater ahk_exe AkelUpdater.exe	; AkelPad Updater's window.
GroupAdd, closeWin, Справка и поддержка ahk_exe HelpPane.exe	; Windows' built-in help tha gets triggered by F1.
GroupAdd, closeWin, ahk_exe hh.exe	; Windows' built-in .chm files reader.
GroupAdd, closeWin, ahk_class AU3Reveal	; AHK windows' info gatherer.
GroupAdd, closeWin, AutoHotkey Toolkit [W] ahk_class AutoHotkeyGUI	; AutoHotkey Toolkit.
GroupAdd, closeWin, GitHub ahk_exe GitHub.exe	; GitHub.
GroupAdd, closeWin, ahk_exe calc.exe	; Calc.
GroupAdd, closeWin, Выполнить ahk_exe explorer.exe	; Run.
GroupAdd, closeWin, ahk_exe charmap.exe	; Charmap.
; GroupAdd, closeWin, ahk_class MediaPlayerClassicW	; Media Player Classic - Home Cinema.
GroupAdd, closeWin, ahk_exe mpc-hc64.exe	; Media Player Classic - Home Cinema (64bit process only).
GroupAdd, closeWin, ahk_exe uTorrent.exe	; µTorrent.
GroupAdd, closeWin, ahk_exe clipdiary-portable.exe	; Clipdiary.
GroupAdd, closeWin, ahk_exe AnVir.exe	; AnVir TaskManager.
GroupAdd, closeWin, ahk_exe teamviewer.exe	; TeamViewer.
GroupAdd, closeWin, Password Required ahk_class MozillaDialogClass ahk_exe firefox.exe	; Firefox'es master password prompt.
GroupAdd, closeWin, Edit button: ahk_class MozillaWindowClass ahk_exe firefox.exe	; Custom Buttons' windows in Firefox.
GroupAdd, closeWin, Textarea Cache Window ahk_class MozillaWindowClass ahk_exe firefox.exe	; Textarea Cache's windows in Firefox.
GroupAdd, closeWin, Launch Application ahk_class MozillaDialogClass ahk_exe firefox.exe	; Launch application (protocol handlers) windows in Firefox.
GroupAdd, closeWin, ahk_exe smartgithg.exe	; SmartGit/Hg.
GroupAdd, closeWin, ahk_exe 7zFM.exe	; 7-Zip GUI file manager.
GroupAdd, closeWin, ahk_class TConversationForm	; Skype chat window.
GroupAdd, closeWin, ahk_class Photo_Lightweight_Viewer	; Windows Photo Viewer.
; GroupAdd, closeWin, ahk_class tSkMainForm	; Skype contact list.
GroupAdd, closeWin, ahk_exe Skype.exe	; Skype contact list.
; GroupAdd, closeWin, ahk_class ConsoleWindowClass	; Windows console (cmd.exe, powershell.exe).
GroupAdd, closeWin, ahk_exe cmd.exe	; Windows console (cmd.exe, powershell.exe).
GroupAdd, closeWin, ahk_exe powershell.exe	; Windows console (cmd.exe, powershell.exe).

; Console remaps (paste).
GroupAdd, pasteCMD, ahk_exe cmd.exe	; Windows console (cmd.exe, powershell.exe).
GroupAdd, pasteCMD, ahk_exe powershell.exe	; Windows console (cmd.exe, powershell.exe).

#IfWinActive ahk_group altF4
^vk57::Send !{F4}	; "Ctrl + W" -> "Alt + F4".

#IfWinActive ahk_group closeWin
^vk57::WinClose, A	; "Ctrl + W" -> close.

#IfWinActive ahk_group pasteCMD
^vk0x56sc0x2f::ControlSend,, {RButton}, A
; MouseGetPos, x, y
; Click, Right 15, 35	; "Ctrl + V" -> "Right click" (paste)
; MouseMove, x, y
; Return
^vk0x41sc0x1e::Send {Esc}	; "Ctrl + A" -> "Esc" (clear input).
^vk0x5asc0x2c::Send {Esc}	; "Ctrl + Z" -> "Esc" (clear input).