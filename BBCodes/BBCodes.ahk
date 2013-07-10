; Script for BBCode text formatting.
; Note: this script only works in browsers (Fx, Chrome, IE and Opera).
; 1. Select some text.
; 2. Hit ALT+B/U/I/P/Q/H/S/X/Up/Down to put selection into the corresponding bbcode tags.

SetBatchLines -1
GroupAdd, Browsers, ahk_class MozillaWindowClass
GroupAdd, Browsers, ahk_class Chrome_WidgetWin_0
GroupAdd, Browsers, ahk_class IEFrame
GroupAdd, Browsers, ahk_class OperaWindowClass

#IfWinActive ahk_group browsers
!sc030::Wrap("b")       ; Alt+B
!sc016::Wrap("u")       ; Alt+U
!sc017::Wrap("i")       ; Alt+I
!sc019::Wrap("img")     ; Alt+P
!sc010::Wrap("quote")   ; Alt+Q
!sc023::Wrap("h")       ; Alt+h
!sc01F::Wrap("s")       ; Alt+s
!sc02D::Wrap("spoiler") ; Alt+x
!Up::Wrap("sup")        ; Alt+Up
!Down::Wrap("sub")      ; Alt+Down

Wrap(tag)
{
	OldClipboard := Clipboard
	open := "[" tag "]"
	close := "[/" tag "]"
	Clipboard :=
	Send, ^{vk43}
	If (Clipboard = "")
	{
		Return False
		Clipboard := OldClipboard
	}
	Clipboard := open . Clipboard . close
	Send, ^{vk56}
	crlf := RegExReplace(Clipboard, "`r`n", "", count) +""+ count
	Send % "{LEFT " StrLen(close) "}{SHIFT DOWN}{LEFT " StrLen(Clipboard) - StrLen(open) - StrLen(close) - crlf "}{SHIFT UP}"
	Return True
	Clipboard := OldClipboard
}