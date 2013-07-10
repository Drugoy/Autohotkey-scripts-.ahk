#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
StringCaseSense, On
#SingleInstance, Force
SetBatchLines, -1
SetKeyDelay, 10

; Transform all text
$>^>+Space::
; Msgbox Transform all text (RCtrl+RShift+Space)
KeyWait RCtrl
KeyWait RShift
KeyWait Space
savedClip := Clipboard
Sleep 1
Send ^{vk41}^{vk43}
Sleep 1
Clipboard := transformTextLayout(Clipboard)
Sleep 1
Send ^{vk56}
Sleep 1
Clipboard := savedClip
savedClip := ""
Return

; Transform only one (full) line
$>+>!Space::
; Msgbox Transform only one (full) line (RShift+RAlt+Space)
KeyWait RShift
KeyWait RAlt
KeyWait Space
savedClip := Clipboard
Sleep 1
Send {End}+{Home}^{vk43}
Sleep 1
Clipboard := transformTextLayout(Clipboard)
Sleep 1
Send ^{vk56}
Sleep 1
Clipboard := savedClip
savedClip := ""
Return

; Transform only (left) part of a line (from the beginning of the line to the caret)
$>^Space::
; Msgbox Transform only (left) part of a line (from the beginning of the line to the caret) (RCtrl+Space)
KeyWait RCtrl
KeyWait Space
savedClip := Clipboard
Sleep 1
Send +{Home}^{vk43}
Sleep 1
Clipboard := transformTextLayout(Clipboard)
Sleep 1
Send ^{vk56}
Sleep 1
Clipboard := savedClip
savedClip := ""
Return

; Transform only (right) part of a line (from the beginning of the line to the caret)
$>^>!Space::
; Msgbox Transform only (right) part of a line (from the beginning of the line to the caret) (RCtrl+RAlt+Space)
KeyWait RCtrl
KeyWait RAlt
KeyWait Space
savedClip := Clipboard
Sleep 1
Send +{End}^{vk43}
Sleep 1
Clipboard := transformTextLayout(Clipboard)
Sleep 1
Send ^{vk56}
Sleep 1
Clipboard := savedClip
savedClip := ""
Return

; Transform only last word
$>!Space::
; Msgbox Transform only last word (RAlt+Space)
KeyWait RAlt
KeyWait Space
savedClip := Clipboard
Sleep 1
Loop
{
	If GetKeyState("Esc", "P")
		Exit
	Send ^+{Left}
	If A_LoopField = 1
		Continue
	Else
		Send ^{vk43}
	Sleep 1
	IfInString, Clipboard, %A_Space%
	{
		Send ^+{Right}^{vk43}
		Sleep 1
		Break
	}
}
Clipboard := transformTextLayout(Clipboard)
Sleep 1
Send ^{vk56}
Clipboard := savedClip
savedClip := ""
Return

transformTextLayout(textContainer)
{
	en := "``qwertyuiop[]asdfghjkl;'zxcvbnm,./~@#$^&QWERTYUIOP{}|ASDFGHJKL:""ZXCVBNM<>?"
	ru := "¸éöóêåíãøùçõúôûâàïğîëäæıÿ÷ñìèòüáş.¨""¹;:?ÉÖÓÊÅÍÃØÙÇÕÚ/ÔÛÂÀÏĞÎËÄÆİß×ÑÌÈÒÜÁŞ,"
	textContainer ~= "i)[a-z]" ? (layoutIn := en, layoutOut := ru) : (layoutIn := ru, layoutOut := en)
	Loop, Parse, textContainer
	{
		IfNotInString, layoutIn, %A_LoopField%
			newChar := A_LoopField
		Else
			StringReplace, newChar, A_LoopField, %A_LoopField%, % SubStr(layoutOut, InStr(layoutIn, A_LoopField, True), 1)
		outputStr .= newChar
	}
	Return outputStr
}