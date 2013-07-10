#singleinstance force
#noenv
Settitlematchmode 2
SetKeyDelay, 10,10
CoordMode, Mouse, Screen     ; used to get more accurate mouse coords

names =
(join
Alpha|Bravo|Charlie|Delta|Echo|Foxtrot|Golf|Hotel|
India|Juliett|Kilo|Lima|Mike|November|Oscar|Papa|Quebec|
Romeo|Sierra|Tango|Uniform|Victor|Whiskey|X-Ray|Yankee|Zulu
)
StringReplace, names, names, | , |, UseErrorLevel
namesLength := (ErrorLevel +1 > 15) ? 15 : (ErrorLevel +1)      ; added an upper limit for how many names get displayed
;change the number "15" to whatever you want your limit to be
Gui, Margin, 0,0
Gui, -caption +alwaysontop +toolwindow
Gui, Add, listbox, vChoice gLabel r%namesLength%, %names%
return

Label:
	Gui, Submit
	If (control = "" )
		WinActivate, %title%
	SendInput %Choice%
	Return

MButton::
	MouseGetPos, xPos , yPos, id, control     ; now gets the mouse coords also
	WinGetTitle, title, ahk_id %id%
	Gui, show, x%xPos% y%yPos%             ; and shows the gui at that spot
	Return

GuiEscape:
	Gui, Hide
	Return

^Esc::
GuiClose:
	ExitApp