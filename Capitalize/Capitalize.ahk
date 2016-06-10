/* Capitalize
Last time modified: 2016.06.05 00:00

Summary: automatically capitalizes letters after hitting Enter or typing dot, exclamation mark or question mark or triple dots.

Note: this script is built so that it supports russian keyboard layout.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/blob/master/Capitalize/Capitalize.ahk
*/
#NoEnv
#SingleInstance, Force
StringCaseSense, Locale	; Without this the 'If var Is Lower/Upper' checks will fail for Cyrillic.

; Menu Tray, Icon, imageRes.dll, 118
SetKeyDelay, -1
endChars := "?!.…{Enter}"	; List of keys to trigger capitalizing after them.
GroupAdd, ExcludedWindows, ahk_exe explorer.exe

SetFormat, Integer, Hex

Global capNextChar
Global scanCodesCharMap := {0x10: "й", 0x11: "ц", 0x12: "у", 0x13: "к", 0x14: "е", 0x15: "н", 0x16: "г", 0x17: "ш", 0x18: "щ", 0x19: "з", 0x1A: "х", 0x1B: "ъ", 0x1E: "ф", 0x1F: "ы", 0x20: "в", 0x21: "а", 0x22: "п", 0x23: "р", 0x24: "о", 0x25: "л", 0x26: "д", 0x27: "ж", 0x28: "э", 0x29: "ё", 0x2C: "я", 0x2D: "ч", 0x2E: "с", 0x2F: "м", 0x30: "и", 0x31: "т", 0x32: "ь", 0x33: "б", 0x34: "ю"}

Hotkey, IfWinNotActive, ahk_group ExcludedWindows

For k In scanCodesCharMap	; Register hotkeys for each mentioned scan code.
{
	funcObj%k% := Func("capitalize").Bind(k)
	Hotkey, % "sc" k, % funcObj%k%
}

; Hook to 'Space' key.
funcObjSpace := Func("capitalize")	;.Bind(" ")
Hotkey, Space, % funcObjSpace

SendLevel, 2
Loop	; Listen to input keys, look for 'endChars' to be sent, to set a token 'capNextChar' to capitalize next char.
{
	Input, key, C E L1 V, % endChars
	capNextChar := (key == " " ? capNextChar : InStr(ErrorLevel, "EndKey:"))
}

capitalize(input = "")	; The function that decides whether to and how to transform the input keys.
; input - scan code of an input key.
{
	If !(input)
	{
		capNextChar *= 2	; Mark spaces being sent after the end chars by doubling the variable's value.
		Send, {Space}
		Return
	}
	isCurrLayoutRu := (DllCall("GetKeyboardLayout", Ptr, DllCall("GetWindowThreadProcessId", Ptr, WinExist("A"), UInt, 0, Ptr), Ptr) & 0xFFFF == 0x409 ? 0 : 1)	; Get current keyboard layout. https://msdn.microsoft.com/en-us/goglobal/bb896001 0x0409 - en-US English (United States), so we just assume that if current layout is not this one - then it's probably ru.
	sendMe := (isCurrLayoutRu ? scanCodesCharMap[input] : GetKeyName("sc" input))	; Transform the key's scan code into a char to send (either english or russian, depending on the check on the previous line).
	If (capNextChar > 1)	; Means that an end char has fired and there was at least one space after it.
		StringUpper, sendMe, sendMe	; Capitalize the key.
	Send, % sendMe
}

isCurrLayoutRu()
{
	Return (DllCall("GetKeyboardLayout", Ptr, DllCall("GetWindowThreadProcessId", Ptr, WinExist("A"), UInt, 0, Ptr), Ptr) & 0xFFFF == 0x409 ? 0 : 1)	
}