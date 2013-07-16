#SingleInstance force

  ; columns: 1 2 3
table := [	[72,68,14]	; row #1
,			[42,75,96]	; row #2
,			[77,48,59]]	; row #3

Msgbox, % table[3,2]	; That will output 48 which is the value taken from row #3, column #2.

; Here is how to parse it by rows (from left to right, then switching to the next row) with a "for" loop:
For row, subArray in table
{
	For column, value in subArray
	{
		Msgbox, row: %row%`ncolumn: %column%`nvalue: %value%
	}
}