/* MasterScript.ahk
Version: 1
Last time modified: 17:10 17.07.2014

Description: a script to draw a pseudo-graphical borders to the copied table.

Script author: Drugoy a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/blob/master/pgTable/pgTable.ahkerScript.ahk
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force

;{ Settings
	;{ Available border styles
	borderThin := "─│┌┬┐├┼┤└┴┘"
	borderDouble := "═║╔╦╗╠╬╣╚╩╝"
	border21 := "─║╓╥╖╟╫╢╙╨╜"
	border12 := "═│╒╤╕╞╪╡╘╧╛"
	;}
border := borderThin	; Specify the choice of border style here
useTopBorder := 1	; Choose whether to add a top border to the table
useRowSeparatingBorders := 1	; Choose whether to use horizontal borders betweel rows
useBottomBorder := 1	; Choose whether to add a bottom border to the table
horizontalCellPadding := 1	; Choose the number of spaces to be added as horizontal paddings (to the left and to the right from each cell's value)
textAlign := 1	; Choose how to align text in cells: left/center/right = -1/0/1
	;}
;}

F12::
	;{ Reading table from clipboard
	input := Trim(Clipboard, " `t`r`n")
	;}
	
	;{ Convert the input table into an array
	inputArray := []
	Loop, Parse, input, `n	; Per line parsing of input.
	{
		rows := A_Index	; At the end of loop, variable "rows" will contain the number of rows.
		Loop, Parse, A_LoopField, `t
			inputArray[A_Index, rows] := RTrim(A_LoopField, "`r`n")	; Have to cut away `r`n from the right edge of cells, since every row's last cell has them.
	}
	;}
	
	;{ Transform a table into a text table with pseudo-graphics
	columns := inputArray.MaxIndex()
	topBorder := bottomBorder := output := rowSeparator := ""
	Loop, % rows
	{
		thisRow := A_Index
		Loop, % columns
		{
			thisColMaxWidth := getColMaxWidth(A_Index)
			thisCellWidth := StrLen(inputArray[A_Index, thisRow])
			If (thisRow == 1)	; While parsing first row the script, based on the specified settings decides whether to build table's top border, bottom border and row separating horizontal borders.
			{
				;{ Build the table's top border.
				If (useTopBorder)
				{
					If (A_Index == 1)	; Parsing leftmost cell.
						topBorder := SubStr(border, 3, 1)	; ┌
					Loop, % thisColMaxWidth + 2 * horizontalCellPadding
						topBorder .= SubStr(border, 1, 1)	; ─
					If (A_Index != columns)
						topBorder .= SubStr(border, 4, 1)	; ┬
					Else	; Parsing rightmost cell.
						topBorder .= SubStr(border, 5, 1) "`n"	; ┐
				}
				;}
				;{ Build the table's rows horizontal separator.
				If (useRowSeparatingBorders)
				{
					If (A_Index == 1)
						rowSeparator .= SubStr(border, 6, 1)	; ├
					Loop, % thisColMaxWidth + 2 * horizontalCellPadding
						rowSeparator .= SubStr(border, 1, 1)	; ─
					If (A_Index != columns)
						rowSeparator .= SubStr(border, 7, 1)	; ┼
					Else	; Parsing rightmost cell.
						rowSeparator .= SubStr(border, 8, 1) "`n"	; ┤
				}
				;}
				;{ Build the table's bottommost line.
				If (useBottomBorder)
				{
					If (A_Index == 1)	; Parsing leftmost cell.
						bottomBorder := SubStr(border, 9, 1)	; └
					Loop, % thisColMaxWidth + 2 * horizontalCellPadding
						bottomBorder .= SubStr(border, 1, 1)	; ─
					If (A_Index != columns)
						bottomBorder .= SubStr(border, 10, 1)	; ┴
					Else	; Parsing rightmost cell.
						bottomBorder .= SubStr(border, 11, 1)	; ┘
				}
				;}
			}
			;{ Defining the number of spaces at left and at right from the cell's text value.
			If (A_Index == 1)	; Parsing leftmost cell.
				output .= SubStr(border, 2, 1)	; │
			cellLeftSpacing := cellRightSpacing := horizontalCellPadding	; Counting the number of spaces to add at left from the value.
			If (textAlign == "1")	; Right text alignment
				cellLeftSpacing += thisColMaxWidth - thisCellWidth
			Else If (textAlign == "-1")	; Left text alignment
				cellRightSpacing += thisColMaxWidth - thisCellWidth
			Else If (textAlign == "0") && (thisColMaxWidth - thisCellWidth)	; 
			{
				cellLeftSpacing += Ceil((thisColMaxWidth - thisCellWidth)/2)
				cellRightSpacing += Floor((thisColMaxWidth - thisCellWidth)/2)
			}
			Loop, % cellLeftSpacing
				(A_Index == 1 ? cellLeftSpacing := " " : cellLeftSpacing .= " ")
			Loop, % cellRightSpacing
				(A_Index == 1 ? cellRightSpacing := " " : cellRightSpacing .= " ")
			;}
			output .= (cellLeftSpacing ? cellLeftSpacing : "") inputArray[A_Index, thisRow] (cellRightSpacing ? cellRightSpacing : "") SubStr(border, 2, 1)	; │
		}
		output .= "`n"	; Finish a row.
		If (useRowSeparatingBorders) && (A_Index != rows)	; Concatenate a row separating border to the currently formed row.
			output .= rowSeparator
	}
	output := topBorder output bottomBorder
	;}
	
	;{ Store the pseudo-graphics table into clipboard
	Clipboard := output
	ClipWait
	;}
Return

;{ Functions
getColMaxWidth(colN)
{
	Global
	Local this, local that
	Loop, % rows
	{
		that := StrLen(inputArray[colN, A_Index])
		this < that ? this := that
	}
	Return this
}
;}