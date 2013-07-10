#SingleInstance, force

GroupAdd, theGroup, ahk_class Miranda	; Miranda.
GroupAdd, theGroup, Miranda NG Options ahk_class #32770	; Miranda NG's options.
GroupAdd, theGroup, File Transfers ahk_class #32770	; Miranda NG's file transfers.
GroupAdd, theGroup, ahk_class HH Parent	; Windows' built-in .chm files reader.
GroupAdd, theGroup, ahk_class AutoHotkey	; AHK scripts' windows.
GroupAdd, theGroup, ahk_class AU3Reveal	; AHK windows' info gatherer.
GroupAdd, theGroup, AutoHotkey Toolkit [W] ahk_class AutoHotkeyGUI	; AutoHotkey Toolkit.
GroupAdd, theGroup, ahk_class µTorrent4823DF041B09	; µTorrent.
GroupAdd, theGroup, ahk_class wxWindowNR	; Clipdiary.
GroupAdd, theGroup, GitHub ahk_class HwndWrapper[DefaultDomain;;eded501e-2121-4e85-aadb-6dfeafd994a5]	; GitHub.
GroupAdd, theGroup, Калькулятор ahk_class CalcFrame	; Калькулятор.
GroupAdd, theGroup, Выполнить ahk_class #32770	; Выполнить.
GroupAdd, theGroup, AnVir Task Manager ahk_class AnVirMainFrame	; AnVir TaskManager.
GroupAdd, theGroup, Password Required ahk_class MozillaDialogClass	; Firefox'es master password prompt.

#IfWinActive ahk_group theGroup
^vk57::Send !{F4}