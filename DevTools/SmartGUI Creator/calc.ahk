
Gui, Add, Edit, x7 y21 w458 h23 Right, 0.
Gui, Add, Checkbox, x73 y86 w51 h16 , Hyp
Gui, Add, Checkbox, x11 y86 w51 h16 , Inv
Gui, Add, GroupBox, x7 y74 w126 h33 , 
Gui, Add, Button, x7 y117 w36 h29 , Sta
Gui, Add, Radio, x11 y53 w45 h16 , Hex
Gui, Add, Radio, x61 y53 w45 h16 , Dec
Gui, Add, Radio, x110 y53 w45 h16 , Oct
Gui, Add, Radio, x160 y53 w45 h16 , Bin
Gui, Add, GroupBox, x7 y42 w212 h33 , 
Gui, Add, GroupBox, x220 y42 w245 h33 , 
Gui, Add, Radio, x224 y53 w62 h16 , Degrees
Gui, Add, Radio, x305 y53 w62 h16 , Radians
Gui, Add, Radio, x386 y53 w62 h16 , Grads
Gui, Add, Button, x7 y149 w36 h29 , Ave
Gui, Add, Button, x7 y182 w36 h29 , Sum
Gui, Add, Button, x7 y214 w36 h29 , s
Gui, Add, Button, x7 y247 w36 h29 , Dat
Gui, Add, Button, x56 y117 w36 h29 , F-E
Gui, Add, Button, x56 y149 w36 h29 , dms
Gui, Add, Button, x56 y182 w36 h29 , sin
Gui, Add, Button, x56 y214 w36 h29 , cos
Gui, Add, Button, x56 y247 w36 h29 , tan
Gui, Add, Button, x95 y117 w36 h29 , (
Gui, Add, Button, x95 y149 w36 h29 , Exp
Gui, Add, Button, x95 y182 w36 h29 , x^y
Gui, Add, Button, x95 y214 w36 h29 , x^3
Gui, Add, Button, x95 y247 w36 h29 , x^2
Gui, Add, Button, x134 y117 w36 h29 , )
Gui, Add, Button, x134 y149 w36 h29 , ln
Gui, Add, Button, x134 y182 w36 h29 , log
Gui, Add, Button, x134 y214 w36 h29 , n!
Gui, Add, Button, x134 y247 w36 h29 , 1/x
Gui, Add, Button, x184 y117 w36 h29 , MC
Gui, Add, Button, x184 y149 w36 h29 , MR
Gui, Add, Button, x184 y182 w36 h29 , MS
Gui, Add, Button, x184 y214 w36 h29 , M+
Gui, Add, Button, x184 y247 w36 h29 , pi
Gui, Add, Button, x233 y117 w36 h29 , 7
Gui, Add, Button, x233 y149 w36 h29 , 4
Gui, Add, Button, x233 y182 w36 h29 , 1
Gui, Add, Button, x233 y214 w36 h29 , 0
Gui, Add, Button, x233 y247 w36 h29 , A
Gui, Add, Button, x272 y117 w36 h29 , 8
Gui, Add, Button, x272 y149 w36 h29 , 5
Gui, Add, Button, x272 y182 w36 h29 , 2
Gui, Add, Button, x272 y214 w36 h29 , +/-
Gui, Add, Button, x272 y247 w36 h29 , B
Gui, Add, Button, x311 y117 w36 h29 , 9
Gui, Add, Button, x311 y149 w36 h29 , 6
Gui, Add, Button, x311 y182 w36 h29 , 3
Gui, Add, Button, x311 y214 w36 h29 , .
Gui, Add, Button, x311 y247 w36 h29 , C
Gui, Add, Button, x350 y117 w36 h29 , /
Gui, Add, Button, x350 y149 w36 h29 , *
Gui, Add, Button, x350 y182 w36 h29 , -
Gui, Add, Button, x350 y214 w36 h29 , +
Gui, Add, Button, x350 y247 w36 h29 , D
Gui, Add, Button, x389 y117 w36 h29 , Mod
Gui, Add, Button, x389 y149 w36 h29 , OR
Gui, Add, Button, x389 y182 w36 h29 , Lsh
Gui, Add, Button, x389 y214 w36 h29 , =
Gui, Add, Button, x389 y247 w36 h29 , E
Gui, Add, Button, x428 y117 w36 h29 , And
Gui, Add, Button, x428 y149 w36 h29 , Xor
Gui, Add, Button, x428 y182 w36 h29 , Not
Gui, Add, Button, x428 y214 w36 h29 , Int
Gui, Add, Button, x428 y247 w36 h29 , F
Gui, Add, Button, x265 y81 w65 h29 , Backspace
Gui, Add, Button, x332 y81 w65 h29 , CE
Gui, Add, Button, x400 y81 w65 h29 , C
Gui, Add, Text, x188 y81 w27 h26 , 
Gui, Add, Text, x139 y81 w27 h26 , 
Gui, Add, Text, x-1 y282 w2 h2 , 
; Generated using SmartGUI Creator 3.6
Gui, Show, x166 y148 h285 w474, My Calculator
Return

GuiClose:
ExitApp

ButtonC:
	msgbox
Return
