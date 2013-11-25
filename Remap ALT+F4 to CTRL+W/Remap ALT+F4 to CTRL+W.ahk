/* Remap ALT+F4 to CTRL+W
Version: 1
Last time modified: 18:40 25.11.2013

Makes "Ctrl+W" hotkey work as "Alt+F4" for lots of different programs and system windows. I like Ctrl+W more than Alt+F4, as it's keys are closer to each other.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/Remap ALT+F4 to CTRL+W/Remap ALT+F4 to CTRL+W.ahk
*/

#SingleInstance, Force

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
GroupAdd, closeWin, File Upload ahk_class #32770	; File Upload mini-explorer windows, usually called by browsers prompting to select a file to upload.

; Console remaps (paste).
GroupAdd, pasteCMD, ahk_exe cmd.exe	; Windows console (cmd.exe, powershell.exe).
GroupAdd, pasteCMD, ahk_exe powershell.exe	; Windows console (cmd.exe, powershell.exe).

#IfWinActive ahk_group altF4
^vk57::Send !{F4}	; "Ctrl + W" -> "Alt + F4".

#IfWinActive ahk_group closeWin
^vk57::WinClose, A	; "Ctrl + W" -> close.

#IfWinActive ahk_group pasteCMD
^vk0x56::ControlClick,,,, Right	; "Ctrl + V" -> "Right mouse click" (paste text from clipboard).
^vk0x41::Send {Esc}	; "Ctrl + A" -> "Esc" (clear input).
^vk0x5a::Send {Esc}	; "Ctrl + Z" -> "Esc" (clear input).